// The guided install of the iOS bridge (3.12.2), the page's IosBridgeInstall.tsx: under «What is
// missing» of a Mac with Xcode, a screen shows what will be downloaded (serve-sim, its licence,
// the folder, the size), then the person's yes and the install as a job with its bar. Nothing is
// downloaded before the person presses the button; Xcode is only explained and the keyboard is
// never repaired from here.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/chat/file_download.dart' show byteWords;
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'system_kit.dart';

String _k(String prefix, String code) => '$prefix${code.replaceAll('-', '_')}';

/// Why the bridge cannot be installed, in words (the page's `iosBlockText`).
String iosBlockText(AppLocalizations l, String blocked) => sw(l, _k('ibBlock_', blocked));

/// The plan, the yes, then the job.
class IosBridgeScreen extends StatefulWidget {
  const IosBridgeScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<IosBridgeScreen> createState() => _IosBridgeScreenState();
}

class _IosBridgeScreenState extends State<IosBridgeScreen> {
  IosBridgePlan? _plan;
  String? _error;
  String? _jobId;
  String? _jobState;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final p = await c.iosBridgePlan();
      if (mounted) setState(() => _plan = p);
    } catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  Future<void> _start() async {
    final c = sysClient(context);
    final id = _plan?.planId;
    if (c == null || id == null) return;
    try {
      final job = await c.startIosBridgeInstall(id);
      if (mounted) setState(() => _jobId = job);
    } catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = _plan;
    final lang = Localizations.localeOf(context).languageCode;
    return SettingsScaffold(
      title: l.syIbTitle,
      backKey: const Key('ib-back'),
      backLabel: l.back,
      listKey: const Key('ib-list'),
      children: [
        if (_error != null) NoticeBanner(text: _error!, error: true),
        if (_jobId != null)
          SysBox(
            children: [
              SysJob(
                id: _jobId!,
                title: l.syIbTitle,
                stepName: (id) => sw(l, id == 'ios-download' ? 'ibStepDownload' : 'ibStepInstall'),
                showDone: false,
                onUpdate: (j, _) {
                  if (mounted && j.state != _jobState) setState(() => _jobState = j.state);
                },
                onEnd: (state, _) {
                  if (mounted) setState(() => _jobState = state);
                  widget.onDone();
                },
              ),
              if (_jobState == 'done') SysNote(text: l.syIbDone, icon: RgIcons.check, tone: 'ok'),
              if (_jobState == 'failed')
                SysNote(text: l.syEiFailed, icon: RgIcons.alert, tone: 'warn'),
              if (_jobState == 'cancelled') SysText(l.syEiCancelled),
              SysActs(
                start: true,
                children: [
                  if (_jobState == null || _jobState == 'running')
                    OutlinedButton(
                      key: const Key('ib-stop'),
                      onPressed: () =>
                          unawaited(sysClient(context)?.cancelEmulatorInstall(_jobId!)),
                      child: Text(l.syEiStopNow),
                    )
                  else
                    FilledButton(
                      key: const Key('ib-close'),
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(l.syEiClose),
                    ),
                ],
              ),
            ],
          )
        else if (p == null && _error == null)
          SysBox(
            children: [
              SysText(l.syEiReading, dim: true),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: RgSpinner(size: 18)),
              ),
            ],
          )
        else if (p != null) ...[
          SysBox(
            key: const Key('ib-plan'),
            children: [
              SysText(l.syIbLead),
              if (p.blocked != null)
                SysNote(
                  key: const Key('ib-blocked'),
                  text: iosBlockText(l, p.blocked!),
                  icon: p.blocked == 'nothing' ? RgIcons.check : RgIcons.alert,
                  tone: p.blocked == 'nothing' ? 'ok' : 'warn',
                )
              else ...[
                SysFacts([
                  (l.syIbFolder, p.folder),
                  (l.syIbVersion, 'serve-sim ${p.version}'),
                  (l.syIbLicence, p.licence),
                  if (p.bytes > 0) (l.syIbSize, byteWords(p.bytes, lang)),
                ]),
                SysText(l.syIbKeyboard, dim: true),
              ],
            ],
          ),
          SysActs(
            start: true,
            children: [
              if (p.planId != null)
                FilledButton.icon(
                  key: const Key('ib-start'),
                  onPressed: () => unawaited(_start()),
                  icon: const RgIcon(RgIcons.download, size: 14),
                  label: Text(l.syIbStart),
                ),
              OutlinedButton(
                key: const Key('ib-cancel'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l.syCancel),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
