// The guided install of the Android SDK pieces (3.11 phase 5), the page's EmulatorInstall.tsx:
// under «What is missing» of this machine, «Install what is missing» and «Update the emulator»
// open a screen with what will be done (steps, folder, sizes), the full licence text to read and
// accept, then the install as a job with its bar (bytes, speed, time left) and its result; the
// report is read again at the end. Nothing is downloaded before the person presses Install; Xcode
// is only explained (the iOS bridge has its own screen, ios_bridge_install.dart).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../theme/colors.dart';
import '../../ui/chat/file_download.dart' show byteWords;
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'ios_bridge_install.dart';
import 'system_kit.dart';

const _installable = {'sdk', 'emulator', 'platform-tools', 'cmdline-tools', 'system-image', 'avd'};

/// Which buttons this machine gets (the page's `installOffer`); `ios`: the bridge of iOS
/// simulators on a Mac that misses it (3.12.2).
({bool install, bool update, bool ios}) installOffer(EmulatorReport r) {
  final ios = r.os == 'macos' && r.missing.contains('ios-bridge');
  return r.container
      ? (install: false, update: false, ios: ios)
      : (
          install: r.missing.any(_installable.contains),
          update: r.missing.contains('emulator-old'),
          ios: ios,
        );
}

String _k(String prefix, String code) => '$prefix${code.replaceAll('-', '_')}';

/// A step in words (the page's `stepText`).
String installStepText(AppLocalizations l, Map<String, dynamic> s) => sw(
  l,
  _k('eiStep_', '${s['id']}'),
  {'version': '${s['version'] ?? ''}', 'name': '${s['avd'] ?? ''}'},
);

/// The buttons under «What is missing» of this machine.
class EmulatorInstall extends StatelessWidget {
  const EmulatorInstall({super.key, required this.r, required this.onDone});

  final EmulatorReport r;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final offer = installOffer(r);
    if (!offer.install && !offer.update && !offer.ios) return const SizedBox.shrink();
    Future<void> open(String mode) async {
      await openSystemScreen(context, EmulatorInstallScreen(mode: mode, onDone: onDone));
    }

    return SysActs(
      start: true,
      children: [
        if (offer.install)
          FilledButton.icon(
            key: const Key('ei-install'),
            onPressed: () => unawaited(open('install')),
            icon: const RgIcon(RgIcons.download, size: 14),
            label: Text(l.syEiInstall),
          ),
        if (offer.ios)
          FilledButton.icon(
            key: const Key('ib-install'),
            onPressed: () => unawaited(openSystemScreen(context, IosBridgeScreen(onDone: onDone))),
            icon: const RgIcon(RgIcons.download, size: 14),
            label: Text(l.syIbInstall),
          ),
        if (offer.update)
          OutlinedButton.icon(
            key: const Key('ei-update'),
            onPressed: () => unawaited(open('emulator-update')),
            icon: const RgIcon(RgIcons.refresh, size: 14),
            label: Text(l.syEiUpdate),
          ),
      ],
    );
  }
}

/// The plan, the licences, the yes, then the job (the page's InstallWindow).
class EmulatorInstallScreen extends StatefulWidget {
  const EmulatorInstallScreen({super.key, required this.mode, required this.onDone});

  /// install | emulator-update.
  final String mode;
  final VoidCallback onDone;

  @override
  State<EmulatorInstallScreen> createState() => _EmulatorInstallScreenState();
}

class _EmulatorInstallScreenState extends State<EmulatorInstallScreen> {
  EmuInstallPlan? _plan;
  String? _error;
  bool _accepted = false;
  String? _jobId;
  String? _jobState;
  final _folder = TextEditingController();
  final _avd = TextEditingController();

  bool get _update => widget.mode == 'emulator-update';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _folder.dispose();
    _avd.dispose();
    super.dispose();
  }

  Future<void> _load({String? target, String? avdName}) async {
    final c = sysClient(context);
    if (c == null) return;
    setState(() {
      _plan = null;
      _error = null;
      _accepted = false;
    });
    try {
      final p = await c.emulatorInstallPlan(
        target: target,
        avdName: avdName,
        only: _update ? 'emulator-update' : null,
      );
      if (!mounted) return;
      setState(() {
        _plan = p;
        _folder.text = p.target;
        final avd = p.steps.where((s) => s['id'] == 'avd').firstOrNull?['avd'];
        if (avd is String && avdName == null) _avd.text = avd;
      });
    } catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  Future<void> _start() async {
    final c = sysClient(context);
    final id = _plan?.planId;
    if (c == null || id == null) return;
    try {
      final job = await c.startEmulatorInstall(id, licenceAccepted: _accepted);
      if (mounted) setState(() => _jobId = job);
    } catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = _plan;
    final lang = Localizations.localeOf(context).languageCode;
    final head = TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14);
    final needsLicences = (p?.licences.isNotEmpty ?? false);
    final canStart = p?.planId != null && (!needsLicences || _accepted) && _jobId == null;
    final hasAvd = p?.steps.any((s) => s['id'] == 'avd') ?? false;
    return SettingsScaffold(
      title: _update ? l.syEiTitleUpdate : l.syEiTitle,
      backKey: const Key('ei-back'),
      backLabel: l.back,
      listKey: const Key('ei-list'),
      children: [
        if (_error != null) NoticeBanner(text: _error!, error: true),
        if (_jobId != null)
          SysBox(
            children: [
              SysJob(
                id: _jobId!,
                title: _update ? l.syEiTitleUpdate : l.syEiTitle,
                stepName: (id) => installStepText(l, {
                  ...?p?.steps.where((s) => s['id'] == id).firstOrNull,
                  'id': id,
                }),
                showDone: false,
                onUpdate: (j, _) {
                  if (mounted && j.state != _jobState) setState(() => _jobState = j.state);
                },
                onEnd: (state, _) {
                  if (mounted) setState(() => _jobState = state);
                  widget.onDone();
                },
              ),
              if (_jobState == 'done') SysNote(text: l.syEiDone, icon: RgIcons.check, tone: 'ok'),
              if (_jobState == 'failed')
                SysNote(text: l.syEiFailed, icon: RgIcons.alert, tone: 'warn'),
              if (_jobState == 'cancelled') SysText(l.syEiCancelled),
              SysActs(
                start: true,
                children: [
                  if (_jobState == null || _jobState == 'running')
                    OutlinedButton(
                      key: const Key('ei-stop'),
                      onPressed: () =>
                          unawaited(sysClient(context)?.cancelEmulatorInstall(_jobId!)),
                      child: Text(l.syEiStopNow),
                    )
                  else
                    FilledButton(
                      key: const Key('ei-close'),
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
            key: const Key('ei-plan'),
            children: [
              SysText(l.syEiLead),
              if (p.blocked != null)
                SysNote(
                  key: const Key('ei-blocked'),
                  text: sw(l, _k('eiBlock_', p.blocked!), {'major': '${p.java?['major'] ?? ''}'}),
                  icon: p.blocked == 'nothing' ? RgIcons.check : RgIcons.alert,
                  tone: p.blocked == 'nothing' ? 'ok' : 'warn',
                ),
              for (final n in p.notes) SysText(sw(l, _k('eiNote_', n)), dim: true),
              if (p.steps.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(l.syEiFolder, style: head),
                SysMono(p.target),
                if (p.targetStandard) SysText(l.syEiFolderStandard, dim: true),
                if (!_update)
                  SysFold(
                    label: l.syEiFolderOther,
                    children: [
                      SysField(
                        label: l.syEiFolder,
                        help: l.syEiFolderHelp,
                        controller: _folder,
                        fieldKey: const Key('ei-folder'),
                      ),
                      if (hasAvd)
                        SysField(
                          label: l.syEiAvdName,
                          help: l.syEiAvdNameHelp,
                          controller: _avd,
                          fieldKey: const Key('ei-avd'),
                        ),
                      SysActs(
                        start: true,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('ei-replan'),
                            onPressed: () => unawaited(
                              _load(
                                target: _folder.text.trim().isEmpty ? null : _folder.text.trim(),
                                avdName: _avd.text.trim().isEmpty ? null : _avd.text.trim(),
                              ),
                            ),
                            icon: const RgIcon(RgIcons.refresh, size: 14),
                            label: Text(l.syEiFolderApply),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Text(l.syEiSteps, style: head),
                for (final (i, s) in p.steps.indexed)
                  Padding(
                    key: Key('ei-step-${s['id']}'),
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        '${i + 1}. ${installStepText(l, s)}',
                        if (s['bytes'] is num && (s['bytes'] as num) > 0)
                          byteWords((s['bytes'] as num).toInt(), lang),
                      ].join(' · '),
                      style: TextStyle(color: c.text),
                    ),
                  ),
                if (p.bytes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(sw(l, 'eiTotal', {'size': byteWords(p.bytes, lang)}), style: head),
                  ),
                if (p.java != null)
                  SysText(
                    '${sw(l, 'eiJava', {'major': '${p.java!['major']}'})} ${p.java!['path']}',
                    dim: true,
                  ),
              ],
            ],
          ),
          if (p.blocked == null && p.licences.isNotEmpty)
            SysBox(
              key: const Key('ei-licences'),
              children: [
                Text(l.syEiLicences, style: head),
                SysText(l.syEiLicencesLead, dim: true),
                for (final lic in p.licences) ...[
                  const SizedBox(height: 8),
                  Text('${lic['id']}', style: head),
                  Container(
                    key: Key('ei-licence-${lic['id']}'),
                    constraints: const BoxConstraints(maxHeight: 220),
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.panel2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.line),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        '${lic['text']}',
                        style: TextStyle(color: c.text, fontSize: 12.5, height: 1.35),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                InkWell(
                  key: const Key('ei-accept'),
                  onTap: () => setState(() => _accepted = !_accepted),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                l.syEiLicenceAccept,
                                style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                l.syEiLicenceHelp,
                                style: TextStyle(color: c.dim, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        RgSwitch(on: _accepted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          SysActs(
            start: true,
            children: [
              if (p.blocked == null)
                FilledButton.icon(
                  key: const Key('ei-start'),
                  onPressed: canStart ? () => unawaited(_start()) : null,
                  icon: const RgIcon(RgIcons.download, size: 14),
                  label: Text(_update ? l.syEiStartUpdate : l.syEiStart),
                ),
              OutlinedButton(
                key: const Key('ei-cancel'),
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
