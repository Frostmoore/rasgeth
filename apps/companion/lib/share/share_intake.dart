// «Share to RedGiant» (G40.10): what the system hands the app from another app's Share sheet
// (Android's ACTION_SEND and SEND_MULTIPLE: text, links, photos, files; iOS's Share Extension,
// prepared). The app shows its Share screen: the Chat or an agent, a note, Send.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

enum SharedKind { text, url, image, file }

class SharedItem {
  const SharedItem({required this.kind, this.text, this.path, this.mimeType});

  final SharedKind kind;

  /// The text or the link (text and url).
  final String? text;

  /// The file's copy in the app's cache (image and file).
  final String? path;
  final String? mimeType;

  /// The file's own name, whatever its path's separator (Windows: a backslash or a slash).
  String get name => path == null ? (text ?? '') : path!.split(RegExp(r'[\\/]')).last;

  bool get isFile => kind == SharedKind.image || kind == SharedKind.file;
}

/// Turns the plugin's items into ours: a text that is only a link is a link.
List<SharedItem> sharedItemsOf(List<SharedMediaFile> files) => [
  for (final f in files)
    switch (f.type) {
      SharedMediaType.text || SharedMediaType.url => SharedItem(
        kind: f.type == SharedMediaType.url || RegExp(r'^https?://\S+$').hasMatch(f.path.trim())
            ? SharedKind.url
            : SharedKind.text,
        text: f.path,
      ),
      SharedMediaType.image => SharedItem(
        kind: SharedKind.image,
        path: f.path,
        mimeType: f.mimeType,
      ),
      SharedMediaType.video ||
      SharedMediaType.file => SharedItem(kind: SharedKind.file, path: f.path, mimeType: f.mimeType),
    },
];

abstract class ShareIntake {
  /// What was shared while the app was closed (it started for it).
  Future<List<SharedItem>> initial();

  /// What is shared while the app runs.
  Stream<List<SharedItem>> get incoming;

  /// The share was handled (sent or put aside): the system forgets it.
  Future<void> done();
}

class NoShareIntake implements ShareIntake {
  final _c = StreamController<List<SharedItem>>.broadcast();

  /// A test shares something.
  void share(List<SharedItem> items) => _c.add(items);

  @override
  Future<List<SharedItem>> initial() async => const [];

  @override
  Stream<List<SharedItem>> get incoming => _c.stream;

  @override
  Future<void> done() async {}
}

class SystemShareIntake implements ShareIntake {
  /// Android and iOS have a Share sheet; the computers do not (files are dropped or picked).
  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<List<SharedItem>> initial() async =>
      sharedItemsOf(await ReceiveSharingIntent.instance.getInitialMedia());

  @override
  Stream<List<SharedItem>> get incoming =>
      ReceiveSharingIntent.instance.getMediaStream().map(sharedItemsOf);

  @override
  Future<void> done() => ReceiveSharingIntent.instance.reset();
}
