// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RGCompanion';

  @override
  String get tabTeam => 'Team';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabInbox => 'For you';

  @override
  String get tabActivity => 'Activity';

  @override
  String get tabYou => 'You';

  @override
  String get composerHint => 'Write to Chat…';

  @override
  String get composerSend => 'Send';

  @override
  String get noServer => 'No RedGiant connected';

  @override
  String get connectFromYou => 'Connect one from You.';

  @override
  String get statusConnected => 'connected';

  @override
  String get statusUnreachable => 'unreachable';

  @override
  String get pillInbox => 'For you';

  @override
  String get pillRunning => 'In progress';

  @override
  String get stateIdle => 'idle';

  @override
  String get stateThink => 'thinking';

  @override
  String get stateWork => 'working';

  @override
  String get stateWait => 'waiting for you';

  @override
  String get stateError => 'blocked';

  @override
  String mascotLabel(String name, String state) {
    return 'Mascot of $name, $state';
  }

  @override
  String get teamEmpty => 'No agents yet.';

  @override
  String get chatNew => 'New conversation';

  @override
  String get chatEmpty => 'Your conversations with Chat, day by day, show here.';

  @override
  String get inboxEmpty => 'Nothing to decide: when an agent asks you something, it shows here.';

  @override
  String get activityEmpty => 'Tasks in progress and done, grouped by agent, show here.';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get reduceMotionHint => 'The mascots stay still; their state shows by its sign.';

  @override
  String get sectionServer => 'RedGiant';

  @override
  String get serverAddress => 'Address';

  @override
  String get serverAddressHint => 'redgiant.local, https://…, 10.42.0.1';

  @override
  String get serverPassword => 'Password';

  @override
  String get serverCode => 'Authenticator code';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting…';

  @override
  String get disconnect => 'Disconnect';

  @override
  String connectedTo(String machine) {
    return 'Connected to $machine';
  }

  @override
  String get errUnreachable => 'RedGiant does not answer at this address.';

  @override
  String get errWrong => 'Wrong password or code.';

  @override
  String get errCodeNeeded => 'The authenticator app\'s code is needed too.';

  @override
  String get errTooMany => 'Too many tries: try again in a few minutes.';

  @override
  String get errNoPassword => 'This RedGiant has no password yet: complete its first start.';

  @override
  String get errServerTooOld => 'This RedGiant is too old for the app: update it.';

  @override
  String get errServerTooNew => 'This app is too old for this RedGiant: update the app.';

  @override
  String errGeneric(String message) {
    return 'It did not work: $message';
  }

  @override
  String get appVersion => 'App version';

  @override
  String get attachmentOnly => '(images)';

  @override
  String get sendFailed => 'The message did not leave: try again.';

  @override
  String attachmentTooBig(String name) {
    return '$name is over 5 MB.';
  }

  @override
  String get notLive =>
      'No live connection here: answers show when you open the conversation again.';

  @override
  String get conversationEmpty => 'Nothing yet: write the first message.';

  @override
  String get loading => 'Loading…';

  @override
  String get attachmentRemove => 'Remove';

  @override
  String get back => 'Back';

  @override
  String get stop => 'Stop';

  @override
  String get attach => 'Attach images';

  @override
  String get composerAgentHint => 'Write a message…';

  @override
  String fromSomeone(String from) {
    return 'from $from';
  }

  @override
  String imagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String get reasoning => 'Reasoning';

  @override
  String get reasoningNow => 'Reasoning…';

  @override
  String get writing => 'writing…';

  @override
  String get toolRunning => 'running';

  @override
  String get toolOk => 'done';

  @override
  String get toolFailed => 'failed';

  @override
  String get open => 'Open';

  @override
  String get linkOpenTitle => 'Open this link outside the app?';

  @override
  String get linkOpen => 'Open';

  @override
  String get cancel => 'Cancel';

  @override
  String canvasFailed(String error) {
    return 'It cannot be shown: $error';
  }

  @override
  String get openWithSystem => 'Open with the system\'s viewer';

  @override
  String get artifactSourceOnly =>
      'On this system the app shows the artifact\'s source; its isolated preview comes with the desktop version.';

  @override
  String get statusReconnecting => 'reconnecting…';

  @override
  String get openFailed => 'It did not open: check the connection.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get untitled => 'Conversation';

  @override
  String requestFrom(String agent) {
    return '$agent asks you';
  }

  @override
  String requestCritical(String agent) {
    return 'Truly dangerous, from $agent';
  }

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get requestLook => 'Look at it';

  @override
  String get criticalTitle => 'A truly dangerous request';

  @override
  String criticalBody(String agent) {
    return '$agent asks to do something that cannot be undone or that touches what protects you. Read it all before answering.';
  }

  @override
  String requestClosed(String via) {
    return 'Already answered ($via).';
  }

  @override
  String get criticalNo => 'No, do not do it';

  @override
  String get criticalYes => 'Yes, do it';

  @override
  String get criticalConfirmTitle => 'Are you sure?';

  @override
  String get criticalConfirmBody => 'This cannot be taken back.';

  @override
  String get criticalSystem => 'System files';

  @override
  String get criticalDelete => 'Deleting for good';

  @override
  String get criticalSecret => 'A secret leaving';

  @override
  String get criticalPayment => 'A real payment';

  @override
  String get criticalProtections => 'RedGiant\'s own protections';

  @override
  String questionFrom(String agent) {
    return '$agent asks you a question';
  }

  @override
  String get answer => 'Answer';

  @override
  String get refresh => 'Refresh';

  @override
  String get taskRunning => 'in progress';

  @override
  String get taskOpen => 'open';

  @override
  String get taskVerified => 'verified';

  @override
  String get taskNotTestable => 'not testable';

  @override
  String get taskAbandoned => 'abandoned';

  @override
  String taskSteps(int done, int total) {
    return '$done of $total steps';
  }

  @override
  String get verifiers => 'Verifier';

  @override
  String get noVerifier => 'No verifier has run yet.';

  @override
  String get openConversation => 'Open the conversation';

  @override
  String get reachPinned => 'https, only with its own certificate (local CA)';

  @override
  String get reachPublic => 'public https (proxy, Tailscale)';

  @override
  String get reachLoopback => 'this computer';

  @override
  String get reachChannel => 'encrypted setup channel';

  @override
  String get noServers => 'No RedGiant yet.';

  @override
  String get useServer => 'Use';

  @override
  String pinnedKey(String fingerprint) {
    return 'Key: $fingerprint';
  }

  @override
  String get renameServer => 'Name of this RedGiant';

  @override
  String get save => 'Save';

  @override
  String get rename => 'Rename';

  @override
  String get forgetServer => 'Disconnect this RedGiant?';

  @override
  String forgetServerBody(String name) {
    return 'The app forgets $name and its device token. To come back, the password again.';
  }

  @override
  String errKeyChanged(String fingerprint) {
    return 'DANGER: this RedGiant answered with another key ($fingerprint). Another computer may be in its place: nothing was sent.';
  }

  @override
  String get errCertificate => 'The certificate is not this RedGiant\'s: the app did not go on.';

  @override
  String get errBusy => 'Another device is setting this RedGiant up: one at a time.';

  @override
  String get errSignInAgain => 'Sign in again with the password.';

  @override
  String get addServerFirst => 'Connect a RedGiant';

  @override
  String get addServer => 'Add another RedGiant';

  @override
  String get foundOnNetwork => 'Found on this network';

  @override
  String get pairingNote =>
      'The password is used once: the app keeps only a device token, revocable from Settings › Devices.';
}
