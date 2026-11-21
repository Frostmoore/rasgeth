// G42.11: the generation (G25.3), as the page's Media.tsx `KindRow`: who makes pictures, videos,
// speech, music and sound effects, with which model and key, one kind per window. Step 1 who makes
// it, step 2 its key (with where to get it), then the model (and the voice for speech). The
// providers and models are the protocol's own (MEDIA_PROVIDERS, ext_catalog.dart).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../api/extensions_api.dart';
import '../automations/automation_kit.dart';
import 'ext_catalog.dart';
import 'ext_kit.dart';

RgIcons mediaKindIcon(String k) => switch (k) {
  'image' => RgIcons.canvas,
  'video' => RgIcons.play,
  'speech' => RgIcons.mic,
  'music' => RgIcons.spark,
  _ => RgIcons.bell,
};

String mediaKindLabel(AppLocalizations l, String k) => switch (k) {
  'image' => l.xtMedia_image,
  'video' => l.xtMedia_video,
  'speech' => l.xtMedia_speech,
  'music' => l.xtMedia_music,
  _ => l.xtMedia_sound,
};

String mediaKindHelp(AppLocalizations l, String k) => switch (k) {
  'image' => l.xtMedia_image_help,
  'video' => l.xtMedia_video_help,
  'speech' => l.xtMedia_speech_help,
  'music' => l.xtMedia_music_help,
  _ => l.xtMedia_sound_help,
};

bool mediaReady(MediaSetup s, String kind) {
  final saved = s.choice(kind);
  return saved != null && s.hasKey('${saved['provider']}');
}

/// The provider and model in use, «Needs its key», or nothing.
String? mediaKindState(AppLocalizations l, MediaSetup s, String kind) {
  final saved = s.choice(kind);
  if (saved == null) return null;
  final id = '${saved['provider']}';
  final p = mediaProvider(id);
  if (!s.hasKey(id)) return l.xtMediaNeedsKey;
  final model =
      p?.models(kind).where((m) => m.id == saved['model']).firstOrNull?.label ??
      '${saved['model']}';
  return '${p?.name ?? id} · $model';
}

class MediaKindView extends StatefulWidget {
  const MediaKindView({
    super.key,
    required this.kind,
    required this.onChanged,
    required this.close,
  });

  final String kind;
  final Future<void> Function() onChanged;
  final void Function([void]) close;

  @override
  State<MediaKindView> createState() => _MediaKindViewState();
}

class _MediaKindViewState extends State<MediaKindView> {
  MediaSetup? _s;
  bool _changing = false;
  bool _changingKey = false;
  String _key = '';
  List<(String, String)>? _voices;
  String? _error;

  String get kind => widget.kind;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final s = await c.mediaSetup();
      if (!mounted) return;
      setState(() => _s = s);
      final saved = s.choice(kind);
      if (kind == 'speech' && saved != null && s.hasKey('${saved['provider']}')) {
        final v = await c
            .mediaVoices('${saved['provider']}')
            .catchError((_) => <(String, String)>[]);
        if (mounted) setState(() => _voices = v);
      } else if (mounted) {
        setState(() => _voices = null);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<void> Function(RedGiantClient c) f) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _error = null);
    try {
      await f(c);
      await _load();
      await widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _save(Json? choice) => _run((c) async {
    await c.setMedia(kind, choice);
    if (mounted) setState(() => _changing = false);
  });

  Future<void> _pick(MediaProvider p) async {
    final first = p.models(kind).firstOrNull;
    if (first == null) return;
    await _save({
      'provider': p.id,
      'model': first.id,
      if (p.voices.isNotEmpty) 'voice': p.voices.first.id,
    });
  }

  Future<void> _saveKey(String provider) => _run((c) async {
    await c.setMediaKey(provider, _key.trim());
    if (mounted) {
      setState(() {
        _key = '';
        _changingKey = false;
      });
    }
  });

  Widget _keyField(AppLocalizations l, MediaProvider p, {required bool linked}) {
    final c = RgColors.of(context);
    if (linked && !_changingKey) {
      return Row(
        key: const Key('xt-media-key-linked'),
        children: [
          RgIcon(RgIcons.check, size: 16, color: c.ok),
          const SizedBox(width: 6),
          Expanded(
            child: Text(l.xtMediaKeyLinked(p.name), style: TextStyle(color: c.text)),
          ),
          TextButton(
            onPressed: () => setState(() => _changingKey = true),
            child: Text(l.xtRemotePasswordChange),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SecretField(
          label: l.xtMediaKey(p.name),
          hint: p.keyExample,
          fieldKey: const Key('xt-media-key'),
          onChanged: (v) => setState(() => _key = v),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              key: const Key('xt-media-key-save'),
              onPressed: _key.trim().length < 8 ? null : () => _saveKey(p.id),
              child: Text(l.xtSave),
            ),
            OutlinedButton.icon(
              onPressed: () => openOutside(p.keyUrl),
              icon: const RgIcon(RgIcons.external, size: 15),
              label: Text(l.xtMediaGetKey),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = _s;
    if (s == null) {
      return Column(
        children: [
          if (_error != null) AutoNotice(_error!, error: true) else const LinearProgressIndicator(),
        ],
      );
    }
    final saved = s.choice(kind);
    final provider = saved == null ? null : mediaProvider('${saved['provider']}');
    final able = [
      for (final p in mediaProviders)
        if (p.models(kind).isNotEmpty) p,
    ];
    final ready = saved != null && s.hasKey('${saved['provider']}');
    final step = saved == null || _changing ? 1 : (!ready ? 2 : 3);
    final models = provider?.models(kind) ?? const <MediaModel>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(mediaKindHelp(l, kind), style: TextStyle(color: c.dim, height: 1.45)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: const Key('xt-media-chip'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ready ? c.ok.withValues(alpha: .12) : c.panel2,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              ready
                  ? mediaKindState(l, s, kind) ?? ''
                  : saved != null
                  ? l.xtMediaNeedsKey
                  : l.xtMediaOff,
              style: TextStyle(color: ready ? c.ok : c.dim, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (step == 1) ...[
          AutoLb(l.xtMediaStep1),
          for (final p in able)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: saved?['provider'] == p.id ? c.accentSoft : c.panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: saved?['provider'] == p.id ? c.accent : c.line),
                ),
                child: InkWell(
                  key: Key('xt-media-provider-${p.id}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _pick(p),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.models(kind).map((m) => m.label).join(' · '),
                                style: TextStyle(color: c.dim, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        if (s.hasKey(p.id))
                          Text(
                            l.xtMediaHasKey,
                            style: TextStyle(
                              color: c.ok,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (saved != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _changing = false),
                child: Text(l.xtCancel),
              ),
            ),
        ],
        if (step == 2 && provider != null) ...[
          AutoLb(l.xtMediaStep2(provider.name)),
          Text('1. ${l.xtMediaKeyStep1(provider.name)}', style: TextStyle(color: c.text)),
          OutsideLink(label: l.xtMediaGetKey, url: provider.keyUrl),
          Text('2. ${l.xtMediaKeyStep2}', style: TextStyle(color: c.text)),
          const SizedBox(height: 6),
          Text('3. ${l.xtMediaKeyStep3}', style: TextStyle(color: c.text)),
          const SizedBox(height: 8),
          _keyField(l, provider, linked: false),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('xt-media-other'),
              onPressed: () => setState(() => _changing = true),
              child: Text(l.xtMediaOtherProvider),
            ),
          ),
        ],
        if (step == 3 && saved != null && provider != null) ...[
          PickBox<String>(
            label: l.xtModel,
            boxKey: const Key('xt-media-model'),
            options: [for (final m in models) (m.id, m.label)],
            value: '${saved['model']}',
            onChanged: (v) => _save({...saved, 'model': v}),
          ),
          if (kind == 'speech' && (_voices?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            PickBox<String>(
              label: l.xtMediaVoice,
              boxKey: const Key('xt-media-voice'),
              options: [if (saved['voice'] == null) ('', l.xtMediaVoiceFirst), ..._voices!],
              value: '${saved['voice'] ?? ''}',
              onChanged: (v) => _save({...saved, 'voice': v}),
            ),
          ],
          const SizedBox(height: 12),
          _keyField(l, provider, linked: true),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                key: const Key('xt-media-other'),
                onPressed: () => setState(() => _changing = true),
                child: Text(l.xtMediaOtherProvider),
              ),
              TextButton(
                key: const Key('xt-media-off'),
                onPressed: () => _save(null),
                child: Text(l.xtMediaTurnOff),
              ),
            ],
          ),
        ],
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [FilledButton(onPressed: () => widget.close(), child: Text(l.xtWzDoneBtn))],
        ),
      ],
    );
  }
}
