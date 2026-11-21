// 3.10.2: one copy of the app per person on a computer. A later copy finds the running one and
// asks it to come to the front, then ends; a wrong token is refused; the installers' «quit» makes
// the app end for real even with its window hidden in the tray (never «hide»); the file lock holds
// across processes and goes with the process that held it.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/single_instance.dart';
import 'package:rgcompanion/desktop/tray.dart';

import 'g42_17_tray_test.dart' show FakeWindow;

class MemoryLock implements InstanceLock {
  MemoryLock(this.free);
  final bool free;
  @override
  Future<bool> acquire() async => free;
}

/// What the installers send (packaging/windows: AppWindow.cs, RasgethApp.iss).
Future<String> installerSays(Directory dir, String Function(String token) line) async {
  final j = jsonDecode(File('${dir.path}/instance.json').readAsStringSync()) as Map;
  final s = await Socket.connect(InternetAddress.loopbackIPv4, j['port'] as int);
  s.write(line(j['token'] as String));
  await s.flush();
  final answer = await utf8.decoder.bind(s).transform(const LineSplitter()).first;
  s.destroy();
  return answer;
}

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('instance'));
  tearDown(() => dir.delete(recursive: true));

  test('a second copy brings the first to the front and ends', () async {
    final first = SingleInstance(dir, lock: MemoryLock(true));
    expect(await first.claim(), isTrue);
    final info = jsonDecode(first.infoFile.readAsStringSync()) as Map;
    expect(info['pid'], pid);
    expect((info['token'] as String).length, 32);
    // Asked before the window is up: kept until the app listens.
    final second = SingleInstance(dir, lock: MemoryLock(false));
    expect(await second.claim(), isFalse);
    final got = <String>[];
    first.onCommand = got.add;
    expect(got, ['show']);
    expect(await SingleInstance(dir, lock: MemoryLock(false)).claim(), isFalse);
    expect(got, ['show', 'show']);
    await first.close();
  });

  test('without the token nothing is done', () async {
    final first = SingleInstance(dir, lock: MemoryLock(true));
    await first.claim();
    final got = <String>[];
    first.onCommand = got.add;
    expect(await installerSays(dir, (_) => 'rasgeth 0000 quit\n'), 'no');
    expect(await installerSays(dir, (t) => 'POST / HTTP/1.1 $t\n'), 'no');
    expect(await installerSays(dir, (t) => 'rasgeth $t format\n'), 'no');
    expect(got, isEmpty);
    await first.close();
  });

  test('the installers\' quit ends the app for real, even hidden in the tray', () async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.windows,
      liveEnabled: false,
    );
    final w = FakeWindow();
    final tray = TrayKeeper(app, w);
    await tray.start();
    final first = SingleInstance(dir, lock: MemoryLock(true));
    await first.claim();
    first.onCommand = (c) => unawaited(c == 'quit' ? tray.quit() : tray.open());
    // Hidden in the tray first.
    w.clickClose();
    await Future<void>.delayed(Duration.zero);
    expect(w.visible, isFalse);
    expect(w.ended, isFalse);
    // Another copy: the hidden window comes back.
    expect(await SingleInstance(dir, lock: MemoryLock(false)).claim(), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(w.visible, isTrue);
    w.clickClose();
    await Future<void>.delayed(Duration.zero);
    expect(w.visible, isFalse);
    // The update: quit, not hide.
    final hides = w.log.where((x) => x == 'hide').length;
    expect(await installerSays(dir, (t) => 'rasgeth $t quit\n'), 'ok');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(w.ended, isTrue);
    expect(w.log.last, 'quit');
    expect(w.kept, isFalse);
    expect(w.log.where((x) => x == 'hide').length, hides);
    await first.close();
  });

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  test(
    'the file lock: held by another process, free once it ends',
    () async {
      final lockFile = File('${dir.path}/instance.lock');
      final script = File('${dir.path}/hold.dart')
        ..writeAsStringSync('''
import 'dart:io';
Future<void> main() async {
  final f = await File(r'${lockFile.path}').open(mode: FileMode.append);
  await f.lock(FileLock.exclusive);
  print('held');
  await stdin.first;
}
''');
      final holder = await Process.start('$flutterRoot/bin/dart', ['run', script.path]);
      final lines = holder.stdout.transform(utf8.decoder).transform(const LineSplitter());
      expect(await lines.first.timeout(const Duration(seconds: 60)), 'held');
      expect(await FileInstanceLock(lockFile).acquire(), isFalse);
      holder.kill(ProcessSignal.sigkill);
      await holder.exitCode;
      expect(await FileInstanceLock(lockFile).acquire(), isTrue);
    },
    skip: flutterRoot == null || Platform.isWindows ? 'needs FLUTTER_ROOT (POSIX)' : null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
