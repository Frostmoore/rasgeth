// Tu › Notifiche (G40.10): how this device hears from the RedGiant in use when the app is closed.
// Android: UnifiedPush through the distributor the person chooses (ntfy, their own ntfy, Sunup…),
// and, without one, plainly what that means and how to get one. iPhone: APNs is prepared and
// switched off until the app is published. Computers: the system's notifications while the app
// is open behind other windows.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/settings_types.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../push/apns.dart';
import '../push/distributors.dart';
import '../push/notice.dart';
import '../push/registrar.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import 'new_agent_screen.dart' show RgSwitch;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final AppController app;
  StreamSubscription<DistributorEvent>? _sub;
  List<String>? _installed;
  String? _current;
  String? _picked;
  PushChannelState? _state;
  DeviceRow? _me;
  String? _said;
  bool _saidError = false;
  bool _busy = false;
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    app = AppScope.read(context);
    _sub = app.distributors.events.listen(_onEvent);
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _load() async {
    final d = app.distributors;
    List<String>? installed;
    String? current;
    if (d.supported) {
      try {
        installed = await d.list();
        current = await d.current();
      } on Object {
        installed = const [];
      }
    }
    final state = await app.pushState();
    DeviceRow? me;
    try {
      me = (await app.client?.devices())?.where((x) => x.current).firstOrNull;
    } on ApiException {
      me = null;
    }
    if (!mounted) return;
    setState(() {
      _installed = installed;
      _current = current;
      _picked ??= current ?? installed?.firstOrNull;
      _state = state;
      _me = me;
    });
  }

  void _say(String text, {bool error = false}) => setState(() {
    _said = text;
    _saidError = error;
  });

  void _onEvent(DistributorEvent e) {
    if (e.serverId != app.server?.id || !mounted) return;
    final l = AppLocalizations.of(context);
    switch (e) {
      case EndpointReady(:final sent):
        _waiting = false;
        sent ? _say(l.pushNowOn) : _say(l.pushEndpointNotSent, error: true);
      case RegistrationFailed(:final reason):
        _waiting = false;
        _say(switch (reason) {
          'network' => l.pushFailedNetwork,
          'vapidRequired' => l.pushFailedVapid,
          'actionRequired' => l.pushFailedAction,
          _ => l.pushFailedOther,
        }, error: true);
      case Unregistered():
        _waiting = false;
        _say(l.pushDistributorDropped, error: true);
    }
    unawaited(_load());
  }

  Future<void> _enable() async {
    final l = AppLocalizations.of(context);
    final d = _picked;
    if (d == null) return;
    setState(() => _busy = true);
    try {
      final ok = await app.enablePush(d);
      if (!mounted) return;
      if (ok) {
        _waiting = true;
        _say(l.pushWaitingEndpoint(distributorLabel(d)));
      } else {
        _say(l.pushFailedOther, error: true);
      }
    } on Object {
      if (mounted) _say(l.pushFailedOther, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    await app.disablePush();
    if (!mounted) return;
    setState(() => _busy = false);
    _say(l.pushNowOff);
    await _load();
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    final id = _me?.id ?? app.hello?.deviceId;
    final c = app.client;
    if (id == null || c == null) return;
    try {
      final r = await c.pushTest(id);
      if (mounted) r == null ? _say(l.pushTestSent) : _say(l.pushTestFailed(r), error: true);
    } on ApiException catch (e) {
      if (mounted) _say(l.pushTestFailed(e.message), error: true);
    }
  }

  Future<void> _desktopTest() async {
    final l = AppLocalizations.of(context);
    final sid = app.server?.id ?? '-';
    try {
      await app.notifier.apply(
        ShowNotification(
          notificationIdOf(sid, 'test:desktop'),
          title: l.notifyTestTitle,
          body: l.notifyTestBody(app.displayName),
          server: app.displayName,
          channel: NoticeChannel.updates,
          answers: const [],
          payload: NoticeTap(
            serverId: sid,
            noticeId: 'test:desktop',
            kind: NoticeKind.test,
          ).toPayload(),
        ),
        l,
      );
    } on Object {
      if (mounted) _say(l.notifyTestFailed, error: true);
      return;
    }
    if (mounted) _say(l.notifyTestShown);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => SettingsScaffold(
        title: l.notificationsTitle,
        backKey: const Key('notifications-back'),
        backLabel: l.back,
        listKey: const Key('notifications-list'),
        children: [
          if (_said != null)
            NoticeBanner(key: const Key('push-said'), text: _said!, error: _saidError),
          ...switch (app.platform) {
            DevicePlatform.android => _android(l),
            DevicePlatform.ios => _ios(l),
            DevicePlatform.windows || DevicePlatform.macos || DevicePlatform.linux => _desktop(l),
            DevicePlatform.other => [NoteLine(icon: RgIcons.bellOff, text: l.pushNotHere)],
          },
          SectionHead(l.pushAboutHead),
          SettingsCard(
            children: [
              if (app.mobile) NoteLine(icon: RgIcons.lock, text: l.pushAboutSealed),
              NoteLine(icon: RgIcons.shield, text: l.pushAboutCritical),
              NoteLine(icon: RgIcons.check, text: l.pushAboutWithdrawn),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _serverSide(AppLocalizations l, RgColors c) {
    final p = _me?.push;
    if (p == null) return const [];
    return [
      if (p['blocked'] != null)
        NoteLine(icon: RgIcons.alert, color: c.warnText, text: l.pushBlocked),
      if (p['lastError'] is String)
        NoteLine(icon: RgIcons.alert, color: c.err, text: l.pushLastError('${p['lastError']}')),
    ];
  }

  List<Widget> _android(AppLocalizations l) {
    final c = RgColors.of(context);
    final on = _state?.kind == 'webpush';
    final installed = _installed;
    return [
      SectionHead(l.pushStateHead),
      SettingsCard(
        key: const Key('push-state'),
        children: [
          if (on) ...[
            NoteLine(
              icon: RgIcons.bell,
              color: c.ok,
              strong: true,
              text: l.pushOnVia(
                _current == null
                    ? Uri.tryParse(_state!.target)?.host ?? ''
                    : distributorLabel(_current!),
              ),
            ),
            ..._serverSide(l, c),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    key: const Key('push-test-here'),
                    onPressed: _busy ? null : _test,
                    child: Text(l.pushTest),
                  ),
                  TextButton(
                    key: const Key('push-off'),
                    onPressed: _busy ? null : _disable,
                    child: Text(l.pushTurnOff, style: TextStyle(color: c.err)),
                  ),
                ],
              ),
            ),
          ] else
            NoteLine(
              icon: RgIcons.bellOff,
              strong: true,
              text: _waiting ? l.pushWaiting : l.pushOffHere,
            ),
        ],
      ),
      SectionHead(l.pushDistributorHead),
      if (installed == null)
        NoteLine(icon: RgIcons.spinner, text: l.loading)
      else if (installed.isEmpty)
        SettingsCard(
          key: const Key('push-no-distributor'),
          children: [
            NoteLine(
              icon: RgIcons.alert,
              color: c.warnText,
              strong: true,
              text: l.pushNoDistributor,
            ),
            NoteLine(icon: RgIcons.bellOff, text: l.pushNoDistributorMeans),
            NoteLine(icon: RgIcons.download, text: l.pushNoDistributorHow),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('push-look-again'),
                  onPressed: _load,
                  child: Text(l.pushLookAgain),
                ),
              ),
            ),
          ],
        )
      else ...[
        SettingsCard(
          key: const Key('push-distributors'),
          children: [
            for (final d in installed)
              PickRow(
                key: Key('distributor-$d'),
                title: distributorLabel(d),
                subtitle: d,
                selected: _picked == d,
                onTap: _busy ? null : () => setState(() => _picked = d),
              ),
          ],
        ),
        if (!on || _picked != _current)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton.icon(
              key: const Key('push-on'),
              onPressed: _busy || _picked == null ? null : _enable,
              icon: const RgIcon(RgIcons.bell, size: 18, color: Colors.white),
              label: Text(l.pushTurnOn(distributorLabel(_picked ?? ''))),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(l.pushDistributorHint, style: TextStyle(color: c.dim, fontSize: 12.5)),
        ),
      ],
    ];
  }

  List<Widget> _ios(AppLocalizations l) {
    final c = RgColors.of(context);
    return [
      SectionHead(l.pushStateHead),
      SettingsCard(
        key: const Key('push-ios'),
        children: [
          NoteLine(
            icon: RgIcons.bellOff,
            strong: true,
            text: ApnsRegistration.available ? l.pushOffHere : l.pushIosLater,
          ),
          NoteLine(icon: RgIcons.chat, color: c.dim, text: l.pushIosMeanwhile),
        ],
      ),
    ];
  }

  List<Widget> _desktop(AppLocalizations l) {
    final c = RgColors.of(context);
    return [
      SectionHead(l.pushStateHead),
      SettingsCard(
        key: const Key('push-desktop'),
        children: [
          NoteLine(icon: RgIcons.monitor, text: l.pushDesktopWhat),
          PickRow(
            key: const Key('desktop-notify-on'),
            title: l.pushDesktopOn,
            selected: app.desktopNotify,
            onTap: () => app.setDesktopNotify(true),
          ),
          PickRow(
            key: const Key('desktop-notify-off'),
            title: l.pushDesktopOff,
            selected: !app.desktopNotify,
            onTap: () => app.setDesktopNotify(false),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('desktop-test'),
                onPressed: _desktopTest,
                child: Text(l.pushTest),
              ),
            ),
          ),
        ],
      ),
      // G42.17: with the window closed the app may stay in the system tray.
      SettingsCard(
        key: const Key('stay-in-tray'),
        children: [
          InkWell(
            onTap: app.trayAvailable ? () => app.setStayInTray(!app.stayInTray) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          l.trayStay,
                          style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          app.trayAvailable ? l.trayStayHelp : l.trayNone,
                          style: TextStyle(color: c.dim, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  RgSwitch(
                    key: const Key('stay-in-tray-switch'),
                    on: app.trayAvailable && app.stayInTray,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          app.trayAvailable && app.stayInTray ? l.pushDesktopInTray : l.pushDesktopClosed,
          key: const Key('desktop-closed-note'),
          style: TextStyle(color: c.dim, fontSize: 12.5),
        ),
      ),
    ];
  }
}
