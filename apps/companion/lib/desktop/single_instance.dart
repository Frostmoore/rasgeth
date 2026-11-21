// One app per person on a computer (3.10.2): with the window closed into the tray, starting the
// app again must bring the running one to the front, never open a second copy (two copies notify
// twice and write the keystore twice, which is how its file broke on Windows).
//
// The first copy holds an exclusive lock on `instance.lock` in the app's own folder for as long as
// it runs (the system drops it when the process ends, even when it is killed) and listens on a
// loopback port written to `instance.json` with a random token. A later copy that cannot take the
// lock asks the running one, on that port with the token, to show itself, and ends. The same line
// with `quit` makes the app end for real (never into the tray): the installers and the launcher
// use it before they replace the app's files (packaging/windows).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// The lock held while this copy runs.
abstract class InstanceLock {
  /// True when this copy holds it now (no other copy runs).
  Future<bool> acquire();
}

/// An exclusive lock on a file (LockFileEx on Windows, fcntl elsewhere), kept open while it runs.
class FileInstanceLock implements InstanceLock {
  FileInstanceLock(this.file);

  final File file;
  RandomAccessFile? _held;

  /// The lock is held (by this copy).
  bool get held => _held != null;

  @override
  Future<bool> acquire() async {
    try {
      await file.parent.create(recursive: true);
      final f = await file.open(mode: FileMode.append);
      try {
        await f.lock(FileLock.exclusive);
      } on FileSystemException {
        await f.close();
        return false;
      }
      _held = f;
      return true;
    } on FileSystemException {
      // The folder cannot be written: nothing to coordinate with, this copy runs.
      return true;
    }
  }
}

/// What the running copy is asked (`show`: in front; `quit`: end for real).
typedef InstanceCommand = void Function(String command);

class SingleInstance {
  SingleInstance(this.dir, {InstanceLock? lock, Random? random})
    : lock = lock ?? FileInstanceLock(File('${dir.path}${Platform.pathSeparator}instance.lock')),
      _random = random ?? Random.secure();

  final Directory dir;
  final InstanceLock lock;
  final Random _random;
  ServerSocket? _server;

  /// What the running copy does when asked (set by the app once its window is up; until then
  /// a request waits for it).
  InstanceCommand? _onCommand;
  final _waiting = <String>[];

  File get infoFile => File('${dir.path}${Platform.pathSeparator}instance.json');

  set onCommand(InstanceCommand? f) {
    _onCommand = f;
    if (f != null) {
      for (final c in [..._waiting]) {
        f(c);
      }
      _waiting.clear();
    }
  }

  /// True: this is the only copy (it now answers the later ones). False: another copy runs and was
  /// asked to come to the front; this one should end.
  Future<bool> claim() async {
    if (await lock.acquire()) {
      await _listen();
      return true;
    }
    // Another copy runs: it may be starting, so its port is asked for a few seconds.
    for (var i = 0; i < 20; i++) {
      if (await send('show')) return false;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    // It holds the lock but does not answer: still never a second copy.
    return false;
  }

  Future<void> _listen() async {
    final token = List.generate(
      16,
      (_) => _random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    try {
      final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _server = s;
      s.listen((c) => _serve(c, token), onError: (_) {});
      final tmp = File('${infoFile.path}.tmp');
      await tmp.writeAsString(
        jsonEncode({'port': s.port, 'token': token, 'pid': pid}),
        flush: true,
      );
      await tmp.rename(infoFile.path);
    } on Object {
      // Without the port a later copy still sees the lock and ends; only «show» is lost.
    }
  }

  void _serve(Socket c, String token) {
    final timer = Timer(const Duration(seconds: 5), c.destroy);
    utf8.decoder
        .bind(c)
        .transform(const LineSplitter())
        .take(1)
        .listen(
          (line) {
            final parts = line.trim().split(' ');
            final ok =
                parts.length == 3 &&
                parts[0] == 'rasgeth' &&
                parts[1] == token &&
                (parts[2] == 'show' || parts[2] == 'quit');
            c.write(ok ? 'ok\n' : 'no\n');
            unawaited(c.flush().then((_) => c.close()).catchError((_) => c));
            timer.cancel();
            if (!ok) return;
            final f = _onCommand;
            if (f != null) {
              f(parts[2]);
            } else {
              _waiting.add(parts[2]);
            }
          },
          onError: (_) => c.destroy(),
          cancelOnError: true,
        );
  }

  /// Asks the running copy ([command]: `show` or `quit`); true when it answered yes.
  Future<bool> send(String command) async {
    try {
      final j = jsonDecode(await infoFile.readAsString());
      if (j is! Map || j['port'] is! int || j['token'] is! String) return false;
      final s = await Socket.connect(
        InternetAddress.loopbackIPv4,
        j['port'] as int,
        timeout: const Duration(seconds: 2),
      );
      try {
        s.write('rasgeth ${j['token']} $command\n');
        await s.flush();
        final answer = await utf8.decoder
            .bind(s)
            .transform(const LineSplitter())
            .first
            .timeout(const Duration(seconds: 3));
        return answer == 'ok';
      } finally {
        s.destroy();
      }
    } on Object {
      return false;
    }
  }

  Future<void> close() async {
    await _server?.close();
    _server = null;
  }
}
