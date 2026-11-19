// A picture in the chat (2026-11-19, the page's `ChatImage`; the person: «le immagini si devono
// vedere nella chat quando sono state generate o quando sono state prese da qualche parte»): every
// picture an agent sends shows in place, its shape kept, fetched only when the list builds it; a
// frame that shimmers while it loads, and a plain «cannot be opened» when it cannot (never an
// empty card). A tap opens it big in the Canvas.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../icons.dart';

/// The last pictures fetched, so scrolling back does not fetch them again.
final _cache = <String, Uint8List>{};
const _cacheSize = 40;

class ChatImagePreview extends StatefulWidget {
  const ChatImagePreview({
    super.key,
    required this.scope,
    required this.path,
    required this.alt,
    this.onOpen,
    this.load,
  });

  final String scope;
  final String path;
  final String alt;
  final VoidCallback? onOpen;

  /// Where the bytes come from; default the server's `GET /api/files/raw` (tests pass their own).
  final Future<Uint8List> Function()? load;

  @override
  State<ChatImagePreview> createState() => _ChatImagePreviewState();
}

class _ChatImagePreviewState extends State<ChatImagePreview> with SingleTickerProviderStateMixin {
  late final _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  Future<Uint8List>? _bytes;
  bool _bad = false;

  String get _key => '${widget.scope}\u0000${widget.path}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bytes ??= _fetch();
    if (!MediaQuery.disableAnimationsOf(context) && !_shimmer.isAnimating) {
      unawaited(_shimmer.repeat());
    }
  }

  Future<Uint8List> _fetch() async {
    final kept = _cache[_key];
    if (kept != null) return kept;
    final load =
        widget.load ?? () => AppScope.read(context).client!.fileRaw(widget.scope, widget.path);
    final b = await load();
    _cache[_key] = b;
    if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first);
    return b;
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Widget _broken(RgColors c, AppLocalizations l) => Container(
    key: const Key('chat-image-bad'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: c.panel2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: c.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        RgIcon(RgIcons.alert, size: 15, color: c.dim),
        Flexible(
          child: Text(l.cvImageUnreadable, style: TextStyle(color: c.dim, fontSize: 13)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (context, snap) {
          if (snap.hasError || _bad) return _broken(c, l);
          final bytes = snap.data;
          if (bytes == null) {
            return SizedBox(
              key: const Key('chat-image-wait'),
              width: 320,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedBuilder(
                    animation: _shimmer,
                    builder: (context, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1 - 2 * _shimmer.value + 1, -.3),
                          end: Alignment(1 - 2 * _shimmer.value + 1, .3),
                          colors: [c.panel2, c.line, c.panel2],
                          stops: const [.4, .5, .6],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          if (_shimmer.isAnimating) _shimmer.stop();
          return Semantics(
            button: widget.onOpen != null,
            image: true,
            label: widget.alt,
            child: MouseRegion(
              cursor: widget.onOpen == null ? MouseCursor.defer : SystemMouseCursors.zoomIn,
              child: GestureDetector(
                key: Key('chat-image-${widget.path}'),
                onTap: widget.onOpen,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480, maxHeight: 360),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (context, _, _) {
                        _bad = true;
                        return _broken(c, l);
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
