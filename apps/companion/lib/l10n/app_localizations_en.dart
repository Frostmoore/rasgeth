// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rasgeth';

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
  String get noServer => 'No Rasgeth connected';

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
  String get accentLabel => 'Accent colour';

  @override
  String get accentHint => 'The colour of buttons, links and the headings\' bar, in both themes.';

  @override
  String get accentRed => 'Rasgeth red';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentViolet => 'Violet';

  @override
  String get newText => 'New text';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get reduceMotionHint => 'The mascots stay still; their state shows by its sign.';

  @override
  String get sectionServer => 'Rasgeth';

  @override
  String get serverAddress => 'Address';

  @override
  String get serverAddressHint => 'rasgeth.local, https://…, 10.42.0.1';

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
  String get errUnreachable => 'Rasgeth does not answer at this address.';

  @override
  String get errWrong => 'Wrong password or code.';

  @override
  String get errCodeNeeded => 'The authenticator app\'s code is needed too.';

  @override
  String get errTooMany => 'Too many tries: try again in a few minutes.';

  @override
  String get errNoPassword => 'This Rasgeth has no password yet: complete its first start.';

  @override
  String get errServerTooOld => 'This Rasgeth is too old for the app: update it.';

  @override
  String get errServerTooNew => 'This app is too old for this Rasgeth: update the app.';

  @override
  String errGeneric(String message) {
    return 'It did not work: $message';
  }

  @override
  String get appVersion => 'App version';

  @override
  String get attachmentOnly => '(attachments)';

  @override
  String get sendFailed => 'The message did not leave: try again.';

  @override
  String attachmentTooBig(String name) {
    return '$name is too big to send (over 25 MB).';
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
  String get criticalProtections => 'Rasgeth\'s own protections';

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
  String get noServers => 'No Rasgeth yet.';

  @override
  String get useServer => 'Use';

  @override
  String pinnedKey(String fingerprint) {
    return 'Key: $fingerprint';
  }

  @override
  String get renameServer => 'Name of this Rasgeth';

  @override
  String get save => 'Save';

  @override
  String get rename => 'Rename';

  @override
  String get forgetServer => 'Disconnect this Rasgeth?';

  @override
  String forgetServerBody(String name) {
    return 'The app forgets $name and its device token. To come back, the password again.';
  }

  @override
  String errKeyChanged(String fingerprint) {
    return 'DANGER: this Rasgeth answered with another key ($fingerprint). Another computer may be in its place: nothing was sent.';
  }

  @override
  String get errCertificate => 'The certificate is not this Rasgeth\'s: the app did not go on.';

  @override
  String get errBusy => 'Another device is setting this Rasgeth up: one at a time.';

  @override
  String get errSignInAgain => 'Sign in again with the password.';

  @override
  String get addServerFirst => 'Connect a Rasgeth';

  @override
  String get addServer => 'Add another Rasgeth';

  @override
  String get foundOnNetwork => 'Found on this network';

  @override
  String get pairingNote =>
      'The password is used once: the app keeps only a device token, revocable from Settings › Devices.';

  @override
  String get allSettings => 'All settings';

  @override
  String get allSettingsHint =>
      'Rasgeth\'s whole Settings page, inside the app, signed in with this device.';

  @override
  String get allSettingsBrowser => 'Opens Rasgeth\'s page in the browser: sign in there as usual.';

  @override
  String get allSettingsNoHttps =>
      'The full settings need HTTPS: from here the page would travel in clear. Switch on HTTPS in the home network from the computer.';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get connectExisting => 'Connect a Rasgeth that runs already';

  @override
  String get firstStepsTitle => 'No Rasgeth yet';

  @override
  String get firstStepsLead =>
      'Set up a new one from here (Rasgeth OS opens its own Wi-Fi network at the first start), or connect one you already use.';

  @override
  String get setupNew => 'Set up a new Rasgeth';

  @override
  String get setupNewHint =>
      'A Rasgeth OS machine turned on for the first time: the app joins its temporary network and does the whole first start.';

  @override
  String get defaultModel => 'Default model';

  @override
  String get setModel => 'The model agents use when nobody chose another';

  @override
  String get modelNone => 'None yet: connect a way of thinking';

  @override
  String devLastUsed(String when) {
    return 'last used $when';
  }

  @override
  String get devNeverUsed => 'never used';

  @override
  String get devNone => 'No device with its own access.';

  @override
  String get devRevoke => 'Sign out';

  @override
  String get devRevokeTitle => 'Sign this device out?';

  @override
  String devRevokeBody(String name) {
    return '«$name» is signed out at once and needs the password to come back.';
  }

  @override
  String get devThis => 'this device';

  @override
  String get fsTitle => 'First start';

  @override
  String get fsLeave => 'Leave';

  @override
  String get fsLeaveTitle => 'Leave the first start?';

  @override
  String get fsLeaveBody =>
      'What is done stays done; you can come back here, or finish from the browser, while the temporary network is open (30 minutes from when Rasgeth was turned on).';

  @override
  String get fsIntroTitle => 'Set up a new Rasgeth';

  @override
  String get fsIntroLead =>
      'Turn your Rasgeth on: for 30 minutes it opens the Wi-Fi network Rasgeth-Setup-XXXX. The app joins it, you create the access and choose your home network, then Rasgeth moves there and the app finds it again.';

  @override
  String get fsIntroSafe =>
      'Everything you type travels encrypted, with Rasgeth\'s own key checked by the app: nobody on the temporary network reads it.';

  @override
  String get fsSeen => 'Temporary networks around';

  @override
  String get fsNoScan =>
      'The system does not show the networks around: type the four characters after Rasgeth-Setup- (you see them in the computer\'s Wi-Fi list).';

  @override
  String get fsLetters => 'The last four characters';

  @override
  String get fsScanAgain => 'Look again';

  @override
  String get fsJoin => 'Join the network';

  @override
  String get fsByHand => 'I join by hand';

  @override
  String get fsJoining => 'Joining the temporary network…';

  @override
  String get fsJoiningSheet => 'Choose Rasgeth-Setup in the window the system shows.';

  @override
  String get fsConnecting => 'Looking for Rasgeth on the network…';

  @override
  String get fsManualTitle => 'Join by hand';

  @override
  String fsManualLead(String ssid, String password) {
    return 'Join the network $ssid (password $password) from the Wi-Fi settings, then come back here.';
  }

  @override
  String get fsNetworkName => 'Network';

  @override
  String get fsNetworkPassword => 'Password';

  @override
  String get fsWhereAndroid => 'Settings › Network › Wi-Fi: tap Rasgeth-Setup-…';

  @override
  String get fsWhereIos => 'Settings › Wi-Fi: tap Rasgeth-Setup-…';

  @override
  String get fsWhereMac => 'The Wi-Fi menu at the top right of the screen: choose Rasgeth-Setup-…';

  @override
  String get fsWhereWindows => 'The Wi-Fi icon at the bottom right: choose Rasgeth-Setup-…';

  @override
  String get fsWhereOther => 'The system\'s Wi-Fi list: choose Rasgeth-Setup-…';

  @override
  String get fsManualNoInternet =>
      'The system may say the network has no internet: that is right, stay on it.';

  @override
  String get fsJoinedContinue => 'Done, go on';

  @override
  String get fsErrNotFound =>
      'Rasgeth does not answer: are you on the Rasgeth-Setup network? It stays open for 30 minutes after Rasgeth is turned on.';

  @override
  String get fsErrNotHere =>
      'This Rasgeth does not let a new access be created from here: finish from its page.';

  @override
  String get fsErrCancelled => 'The network was not joined. Try again, or join by hand.';

  @override
  String get fsErrDenied =>
      'The app needs the permission for nearby devices to join the network: allow it, or join by hand.';

  @override
  String get fsErrJoinFailed => 'The system could not join the network: join by hand.';

  @override
  String get fsErrNoName => 'Choose the network, or type its four last characters.';

  @override
  String get fsAccessTitle => 'Create your access';

  @override
  String get fsAccessLead =>
      'The password that opens Rasgeth from every device. Keep it: it is also what opens its keychain.';

  @override
  String get fsPassword => 'Password';

  @override
  String get fsPasswordAgain => 'The password again';

  @override
  String get fsPasswordNeeded => 'A password is needed.';

  @override
  String get fsPasswordWeak => 'At least 10 characters, not all the same.';

  @override
  String get fsPasswordDiffer => 'The two passwords are different.';

  @override
  String get fsAccessSafe =>
      'It travels encrypted to Rasgeth and stays only there; this device gets its own access, which you can sign out from Settings › Devices.';

  @override
  String get fsAccessGo => 'Create the access';

  @override
  String get fsSignInTitle => 'Sign in';

  @override
  String get fsSignInLead => 'This Rasgeth has its password already: type it to go on.';

  @override
  String get fsMaintenanceTitle => 'Rasgeth lost its network';

  @override
  String get fsMaintenanceLead =>
      'It opened the temporary network to be given a new one. Its owner\'s password, and nothing else changes.';

  @override
  String get fsHomeTitle => 'Your home network';

  @override
  String get fsHomeLead =>
      'Which network should Rasgeth use at home? These are the ones it saw around it.';

  @override
  String get fsHomeNone =>
      'No network was seen around: use the cable, or type the name of a hidden network.';

  @override
  String get fsHomeUnusable => 'Rasgeth cannot join this kind of network';

  @override
  String get fsHomeHidden => 'A hidden network';

  @override
  String get fsHomeHiddenName => 'Network name';

  @override
  String fsHomePassword(String name) {
    return 'Password of «$name»';
  }

  @override
  String get fsHomeSafe => 'The Wi-Fi password stays only in Rasgeth.';

  @override
  String fsHomeJoin(String name) {
    return 'Use «$name»';
  }

  @override
  String get fsHomeCable => 'I use the cable';

  @override
  String fsHomeWaitWifi(String name) {
    return 'Rasgeth is joining «$name»…';
  }

  @override
  String get fsHomeWaitCable => 'Rasgeth moves to the home network…';

  @override
  String get fsHomeWaitSub =>
      'The device goes back to its own network and finds Rasgeth there (up to two minutes). If it does not work, Rasgeth opens the temporary network again and says why.';

  @override
  String get fsLostTitle => 'Rasgeth is not found';

  @override
  String fsLostLead(String ssid) {
    return 'Neither at home nor on $ssid. Check that this device is back on the home network, then look again; or join the temporary network by hand to see what happened.';
  }

  @override
  String get fsLookAgain => 'Look again';

  @override
  String get fsLanguageTitle => 'Languages';

  @override
  String get fsLanguageLead =>
      'The language of the app and of the page, and the one the agents speak to you.';

  @override
  String get fsLanguageUi => 'App and page';

  @override
  String get fsLanguageAgents => 'The agents speak';

  @override
  String get fsNext => 'Next';

  @override
  String get fsLater => 'Later';

  @override
  String get fsBrainTitle => 'How should Rasgeth think?';

  @override
  String get fsBrainLead =>
      'A subscription you have already, or a key of a provider. Any of them, or none for now.';

  @override
  String get fsClaude => 'Claude Pro or Max';

  @override
  String get fsClaudeText => 'Anthropic\'s page in the browser, then the code it shows';

  @override
  String get fsClaudeOpen => 'Open Anthropic\'s page';

  @override
  String get fsClaudeCode => 'The code the page shows';

  @override
  String get fsChatgpt => 'ChatGPT Plus or Pro';

  @override
  String get fsChatgptText => 'A code to type on OpenAI\'s page';

  @override
  String get fsChatgptOpen => 'Open OpenAI\'s page';

  @override
  String get fsChatgptCode => 'Type this code on the page; the app notices when it is done.';

  @override
  String get fsChatgptOpenAgain => 'Open the page again';

  @override
  String get fsKey => 'A key of a provider';

  @override
  String get fsKeyText => 'Anthropic, OpenAI, Gemini, OpenRouter…: paid per use';

  @override
  String fsKeyOf(String name) {
    return 'Key of $name';
  }

  @override
  String fsKeySaved(String name) {
    return '$name: the key works.';
  }

  @override
  String get fsTerms =>
      'I read the provider\'s terms: a subscription is used by me, on my own Rasgeth.';

  @override
  String get fsBrainLater =>
      'Models on this machine, your own server and the rest are in Settings › Models and subscriptions, whenever you want.';

  @override
  String get fsNamesTitle => 'The names';

  @override
  String get fsNamesLead =>
      'Who runs your Rasgeth, and who speaks for it in the chats. You can change them later.';

  @override
  String get fsGodName => 'The chief';

  @override
  String get fsGodHelp => 'It organises the work and hands it to the agents';

  @override
  String get fsDemigodName => 'The spokesperson';

  @override
  String get fsDemigodHelp => 'It answers you on Telegram and the other chats';

  @override
  String get fsFinish => 'Finish';

  @override
  String get fsFinishing => 'Completing the first start…';

  @override
  String get fsDoneTitle => 'Rasgeth is ready';

  @override
  String get fsDoneLead =>
      'The temporary network is closed: Rasgeth is on your home network, and this device is connected to it.';

  @override
  String get fsDoneMaintenance =>
      'Rasgeth is on its new network again, and this device is connected to it.';

  @override
  String get fsDoneMore =>
      'The rest of the first start (backups, chats, access from outside…) is in the page, whenever you want: «Settings of Rasgeth» › «All settings».';

  @override
  String get fsDoneGo => 'Open the team';

  @override
  String get homeErrConnectFailed =>
      'The network refused to connect: check the password and try again.';

  @override
  String get homeErrNotFound => 'That network is not in reach now.';

  @override
  String get homeErrBadPassword => 'A Wi-Fi password has 8 to 63 characters.';

  @override
  String get homeErrBadSsid => 'A network\'s name has 1 to 32 characters.';

  @override
  String get homeErrBusy => 'Rasgeth is already joining a network: wait a moment.';

  @override
  String get homeErrWifiOff => 'Wi-Fi is not running on Rasgeth.';

  @override
  String get homeErrNoCable =>
      'No cable with an address: connect it to the router, or choose a Wi-Fi network.';

  @override
  String get homeErrFailed => 'That did not work. Try again in a moment.';

  @override
  String get outsideNone =>
      'Only from the home network. Tailscale, Cloudflare or a name of your own: in «Access from outside home».';

  @override
  String get outsideOwn => 'Your own way in';

  @override
  String get outsideOwnName => 'Your own name (Caddy)';

  @override
  String get pushOff => 'Not on yet for this device: turn them on in You, Notifications.';

  @override
  String pushOn(String target) {
    return 'On, through $target';
  }

  @override
  String get pushBlocked =>
      'Nothing can be sent now (the keychain is locked, or the relay is off).';

  @override
  String get pushTest => 'Send a test';

  @override
  String get pushTestSent => 'Test notification sent.';

  @override
  String pushTestFailed(String why) {
    return 'The test did not go: $why';
  }

  @override
  String get sectionUpdates => 'UPDATES';

  @override
  String get sectionDevices => 'DEVICES CONNECTED';

  @override
  String get sectionNotifications => 'THIS DEVICE\'S NOTIFICATIONS';

  @override
  String get sectionModel => 'MODEL AND VOICE';

  @override
  String get sectionOutside => 'FROM OUTSIDE HOME';

  @override
  String serverSettingsTitle(String name) {
    return 'Settings of $name';
  }

  @override
  String get serverSettingsSub => 'Name, updates, devices, model, voice';

  @override
  String versionOf(String version) {
    return 'version $version';
  }

  @override
  String get updLatest => 'Up to date';

  @override
  String updAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String updApplying(String version) {
    return 'Updating to $version…';
  }

  @override
  String updInstalled(String version) {
    return 'installed $version';
  }

  @override
  String updChecked(String when) {
    return 'checked $when';
  }

  @override
  String get updLook => 'Look for updates';

  @override
  String get updLooking => 'Looking…';

  @override
  String get updNow => 'Update';

  @override
  String get updNowTitle => 'Update Rasgeth?';

  @override
  String updNowBody(String version) {
    return 'Rasgeth downloads $version, then restarts: for a minute or two it does not answer. You see every step, and the app reconnects by itself as soon as Rasgeth is back.';
  }

  @override
  String get updStarted => 'The update started.';

  @override
  String get updBreaking =>
      'This version needs a clean install (with a backup first): from the computer.';

  @override
  String get updDockerHint =>
      'In Docker the new version comes with these commands, on the computer that runs it:';

  @override
  String get updReboot => 'A security update asks for a restart.';

  @override
  String updBytes(String done, String total) {
    return '$done MB of $total MB';
  }

  @override
  String updSpeed(String mb) {
    return '$mb MB/s';
  }

  @override
  String updEtaMin(String n) {
    return '$n min left';
  }

  @override
  String updEtaSec(String n) {
    return '$n s left';
  }

  @override
  String get updStepCheck => 'Checking the release';

  @override
  String get updStepDownload => 'Downloading';

  @override
  String get updStepFiles => 'The system\'s files';

  @override
  String get updStepInstall => 'Installing';

  @override
  String get updStepRestart => 'Restarting';

  @override
  String get updStepWait => 'Waiting for Rasgeth to answer';

  @override
  String get updStepRollback => 'Going back to the version before';

  @override
  String get updStepScan => 'Comparing the files';

  @override
  String get updStepBuild => 'Preparing';

  @override
  String get updStepFailed => 'It stopped';

  @override
  String get voice => 'Voice';

  @override
  String voiceHear(String what) {
    return 'Hears with: $what';
  }

  @override
  String voiceRead(String what) {
    return 'Reads with: $what';
  }

  @override
  String get voiceNone => 'nothing set yet';

  @override
  String get voiceBrowser => 'the device\'s own voice';

  @override
  String get teamAll => 'All';

  @override
  String get teamFavourites => 'Favourites';

  @override
  String get teamFilterLabel => 'Show';

  @override
  String get teamNoFavourites => 'No favourites yet: press and hold an agent to add it.';

  @override
  String get teamNoneInProject => 'No agent has worked in this project.';

  @override
  String get favouriteMark => 'favourite';

  @override
  String get agentDoing => 'What it is doing';

  @override
  String get agentIdleNow => 'Idle right now.';

  @override
  String get agentWaitsYou => 'It is waiting for your answer in «For you».';

  @override
  String agentTask(String title) {
    return 'Task: $title';
  }

  @override
  String agentLastAt(String when) {
    return 'Last activity: $when';
  }

  @override
  String get agentStop => 'Stop';

  @override
  String agentStopped(String name) {
    return 'Interrupted: $name';
  }

  @override
  String get agentStopFailed => 'It did not stop: check the connection.';

  @override
  String get agentOpenTask => 'Open the task';

  @override
  String get agentOpenChat => 'Open the conversation';

  @override
  String get favouriteAdd => 'Add to favourites';

  @override
  String get favouriteRemove => 'Remove from favourites';

  @override
  String inboxPosition(String n, String total) {
    return '$n of $total';
  }

  @override
  String get inboxSwipeHint => 'Swipe right to say yes, left to say no.';

  @override
  String get inboxCriticalHint => 'Truly dangerous: no swiping, it opens full screen.';

  @override
  String inboxSaidYes(String name) {
    return 'Yes to $name';
  }

  @override
  String inboxSaidNo(String name) {
    return 'No to $name';
  }

  @override
  String get inboxNext => 'Later';

  @override
  String get modelWay => 'How it goes';

  @override
  String get modelWaySubscription => 'Subscription';

  @override
  String get modelWayKey => 'API key';

  @override
  String modelWayNode(String node) {
    return 'Via $node';
  }

  @override
  String get modelWayLocal => 'Local';

  @override
  String get modelWayOr => 'or';

  @override
  String get modelHintSubscription => 'Within your plan\'s limits: nothing is paid per use.';

  @override
  String get modelHintKey => 'Paid per use with your API key: it counts toward the spending cap.';

  @override
  String modelHintNode(String node) {
    return 'Goes through the computer $node.';
  }

  @override
  String get modelHintLocal => 'Runs on a computer of yours: nothing is paid per use.';

  @override
  String get modelHintOther => 'Through a connected provider.';

  @override
  String get stateActive => 'active';

  @override
  String get teamAgents => 'Agents';

  @override
  String get teamNewAgent => 'New agent';

  @override
  String get teamNoAgents => 'No other agents yet: make one with «New agent».';

  @override
  String get teamChatLead => 'Your everyday conversations';

  @override
  String get agentJustAnswered => 'It has just answered you.';

  @override
  String get agentBlockedNow => 'It is blocked: open the conversation to see why.';

  @override
  String get effortLow => 'Low';

  @override
  String get effortMedium => 'Medium';

  @override
  String get effortHigh => 'High';

  @override
  String get effortMax => 'Max';

  @override
  String get effortTitle => 'Reasoning effort';

  @override
  String get agentModel => 'Model';

  @override
  String get agentModelInherit => 'The same as the one above it';

  @override
  String get agentModelDefault => 'The default model';

  @override
  String get agentModelSaved => 'Saved: its next messages use it.';

  @override
  String get agentModelFailed => 'I could not change the model.';

  @override
  String agentModelTitle(String name) {
    return 'Model of $name';
  }

  @override
  String modelNow(String model) {
    return 'Now: $model';
  }

  @override
  String modelUse(String model) {
    return 'Use $model';
  }

  @override
  String modelInheritOf(String label, String model) {
    return '$label ($model)';
  }

  @override
  String get noModels => 'No model connected: connect one in the settings.';

  @override
  String get more => 'More commands';

  @override
  String get moreChanged => 'More commands (something is not as it starts)';

  @override
  String moreMode(String mode) {
    return 'Mode: $mode';
  }

  @override
  String moreModeHint(String name) {
    return 'It holds for all of $name\'s conversations.';
  }

  @override
  String moreModel(String model) {
    return 'Model: $model';
  }

  @override
  String get moreModelHint =>
      'The model of this conversation (agents\' models: long press the agent in Team)';

  @override
  String get moreModelBusy => 'It changes once it has finished working.';

  @override
  String get moreOpen => 'open';

  @override
  String get moreClosed => 'closed';

  @override
  String get moreSectionHow => 'How it works';

  @override
  String get moreSectionMore => 'More';

  @override
  String get mode_manual => 'Ask';

  @override
  String get mode_auto => 'Automatic';

  @override
  String get mode_plan => 'Plan';

  @override
  String get mode_readonly => 'Read only';

  @override
  String get modeFailed => 'I could not change the mode.';

  @override
  String get agentsModel => 'Agent\'s model';

  @override
  String get modelPick => 'Choose a model';

  @override
  String get sessionModelTitle => 'Model of this conversation';

  @override
  String get sessionModelBusy => 'It is working: the model changes once it has finished.';

  @override
  String get asideChip => 'Meanwhile';

  @override
  String get asideHint =>
      'A quick question on the side, also while the agent works: it knows the conversation, but nothing of it enters the chat';

  @override
  String get asideTitle => 'Meanwhile';

  @override
  String get asideSub => 'Not part of the conversation';

  @override
  String get asideEmpty =>
      'Ask anything about this conversation. The answer stays here: it does not enter the chat nor the agent\'s memory.';

  @override
  String get asidePlaceholder => 'A quick question…';

  @override
  String get asidePlaceholderBusy => 'A quick question, while the agent works…';

  @override
  String get asideAsk => 'Ask';

  @override
  String get asideThinking => 'Thinking…';

  @override
  String asideFailed(String why) {
    return 'No answer: $why';
  }

  @override
  String get asideToChat => 'Bring into the chat';

  @override
  String get asideBrought => 'Brought into the chat.';

  @override
  String get compactNow => 'Summarise';

  @override
  String get compactNowHint =>
      'Summarise the older part of this conversation now: the agent keeps the recent turns and can still read everything';

  @override
  String get compactNowAsk =>
      'Summarise the conversation now. Anything to keep in particular? (optional)';

  @override
  String get compactNowYes => 'Summarise';

  @override
  String get compactNowSent => 'Summarising the conversation.';

  @override
  String get roomFromChat => 'Add an agent';

  @override
  String get roomFromChatHint =>
      'Turn this conversation into a group chat: add other agents, inspectors included';

  @override
  String get roomPickTitle => 'Who joins the group chat?';

  @override
  String roomAdded(String name) {
    return '$name is in the group chat: you find it in the page, among the conversations.';
  }

  @override
  String get roomFailed => 'I could not make the group chat.';

  @override
  String get whileRunning => 'Not while it works.';

  @override
  String get newAgentTitle => 'New agent';

  @override
  String newAgentStep(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get newAgentKindQ => 'What kind of agent do you need?';

  @override
  String get newAgentKindAgent => 'A project\'s agent';

  @override
  String get newAgentKindAgentText =>
      'Works in a project under its orchestrator: writes code, reviews, researches, tests.';

  @override
  String get newAgentKindOrch => 'A project\'s orchestrator';

  @override
  String get newAgentKindOrchText =>
      'Leads a project: splits the work and hands it to its agents. One per project.';

  @override
  String get newAgentKindAsst => 'Personal assistant';

  @override
  String get newAgentKindAsstText =>
      'Helps you outside the projects: mail, calendar, research, accounts.';

  @override
  String get newAgentProjectQ => 'In which project?';

  @override
  String get newAgentNoOrch => 'It has no orchestrator yet: make one first.';

  @override
  String get newAgentHasOrch => 'It already has an orchestrator.';

  @override
  String get newAgentNoProjects => 'No projects: make one from the page.';

  @override
  String get newAgentNameQ => 'What is its name and what does it do?';

  @override
  String get newAgentName => 'Name';

  @override
  String get newAgentRole => 'Its job, in your own words';

  @override
  String get newAgentRoleHint => 'For example: writes the tests and checks they pass';

  @override
  String get newAgentMascotPreview => 'Its mascot';

  @override
  String get newAgentMascotLater =>
      'Rasgeth picks the face from the name; once it is made you can change it.';

  @override
  String get newAgentModelQ => 'Which model does it use? (optional)';

  @override
  String get newAgentModelLead => 'By default it uses the one above it.';

  @override
  String get newAgentModelGod => 'The same as God';

  @override
  String get newAgentToolsQ => 'Tools to switch off (optional)';

  @override
  String get newAgentToolsLead =>
      'By default it has every tool. The essential ones never switch off.';

  @override
  String newAgentToolsOff(int n) {
    return '$n off';
  }

  @override
  String get newAgentReview => 'Here is the new agent';

  @override
  String get newAgentBack => 'Back';

  @override
  String get newAgentNext => 'Next';

  @override
  String get newAgentCreate => 'Create';

  @override
  String get newAgentCreating => 'Making it…';

  @override
  String newAgentFailed(String why) {
    return 'I could not make it: $why';
  }

  @override
  String newAgentMade(String name) {
    return '$name is in the team.';
  }

  @override
  String newAgentOpen(String name) {
    return 'Open the conversation with $name';
  }

  @override
  String get newAgentNeedsGod => 'God is needed to make agents: finish the first start first.';

  @override
  String get mascotChange => 'Change mascot';

  @override
  String mascotChangeAsk(String name) {
    return 'Give $name a new face? The current one does not come back.';
  }

  @override
  String get mascotChangeYes => 'New face';

  @override
  String mascotChanged(String name) {
    return 'A new face for $name.';
  }

  @override
  String get reviewKind => 'Kind';

  @override
  String get reviewProject => 'Project';

  @override
  String get reviewTools => 'Tools';

  @override
  String get reviewAllTools => 'All';

  @override
  String get agentInstructions => 'Instructions';

  @override
  String agentInstructionsOf(String name) {
    return 'Instructions of $name';
  }

  @override
  String get chatInstructions => 'The Chat\'s instructions';

  @override
  String get agentInstructionsRow => 'Its system prompt: read and change it';

  @override
  String get promptDefault => 'Built-in instructions';

  @override
  String get promptOwn => 'Your instructions';

  @override
  String get promptNewChats =>
      'New instructions apply to new conversations: the open ones keep theirs. The agents\' names stay right if you rename them later.';

  @override
  String get promptSave => 'Save';

  @override
  String get promptSaved => 'Saved.';

  @override
  String promptSaveFailed(String why) {
    return 'I could not save them: $why';
  }

  @override
  String get promptReset => 'Restore the built-in ones';

  @override
  String get promptResetConfirm => 'Go back to the built-in instructions? Your text will be lost.';

  @override
  String get promptUndo => 'Undo the changes';

  @override
  String get refineOpen => 'Improve the instructions';

  @override
  String get refineLead =>
      'A model reads them again and proposes a clearer version. You see what changes before using it; nothing is saved until you save.';

  @override
  String get refineWish => 'What do you want to change? (you can leave it empty)';

  @override
  String get refineWishPlaceholder =>
      'For example: more concise; always answer with lists; specialise it in invoices. Empty: a general improvement.';

  @override
  String refineEstimate(String what) {
    return 'Estimate: $what.';
  }

  @override
  String get refineNoEstimate => 'No estimate: check that the model is still connected.';

  @override
  String refineSpent(String what) {
    return 'Spent: $what.';
  }

  @override
  String refineCostLine(String tokens, String cost) {
    return 'about $tokens tokens, $cost';
  }

  @override
  String get refineFree => 'no money (a local model or a subscription)';

  @override
  String refineCost(String usd) {
    return 'about $usd';
  }

  @override
  String get refineCostTiny => 'less than a cent';

  @override
  String get refineGo => 'Improve';

  @override
  String get refineWorking => 'Rewriting the instructions...';

  @override
  String get refineChanges => 'What changed';

  @override
  String get refineUse => 'Use this version';

  @override
  String get refineRetry => 'Try again';

  @override
  String get refineUsed => 'The new version is in the field: save to keep it.';

  @override
  String get refineSame => 'The model left them as they were.';

  @override
  String get refineErr_budget => 'The budget is used up: raise it in Settings, Budget.';

  @override
  String get refineErr_no_model => 'No model is connected: connect one in Settings, Models.';

  @override
  String get refineErr_no_answer =>
      'The model gave no usable text. Try again or choose another model.';

  @override
  String get refineErr_removed_parts =>
      'The model left out parts that must stay (tools, names). Nothing changed: try again or choose another model.';

  @override
  String get attachmentNotSent => 'not sent';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSub => 'How this device hears from Rasgeth when the app is closed';

  @override
  String get voiceTitle => 'Voice';

  @override
  String get voiceSub => 'Who reads the answers aloud, and how loud';

  @override
  String get notifyAllow => 'Yes';

  @override
  String get notifyDeny => 'No';

  @override
  String get notifyOpen => 'Open';

  @override
  String get notifyChannelRequests => 'Requests for you';

  @override
  String get notifyChannelUpdates => 'Messages and tasks';

  @override
  String get notifyAnswerFailedTitle => 'The answer did not go';

  @override
  String get notifyAnswerFailedBody => 'Open the app to answer: the request is still waiting.';

  @override
  String notifyAsksPermission(String name) {
    return '$name asks for permission';
  }

  @override
  String notifyAsksYou(String name) {
    return '$name asks you';
  }

  @override
  String get notifyCriticalTitle => 'A truly dangerous request: open it to decide';

  @override
  String get notifyTestTitle => 'Notification test';

  @override
  String notifyTestBody(String server) {
    return 'Notifications from $server reach this computer.';
  }

  @override
  String get notifyTestShown => 'A test notification is on the screen.';

  @override
  String get pushStateHead => 'On this device';

  @override
  String pushOnVia(String via) {
    return 'On, through $via';
  }

  @override
  String get pushOffHere =>
      'Off on this device: Rasgeth cannot tell you anything while the app is closed.';

  @override
  String get pushWaiting => 'Waiting for the distributor\'s address…';

  @override
  String pushWaitingEndpoint(String name) {
    return '$name is preparing this phone\'s address: it takes a few seconds.';
  }

  @override
  String get pushNowOn => 'Notifications are on: send a test to see one.';

  @override
  String get pushNowOff => 'Notifications are off on this device.';

  @override
  String get pushEndpointNotSent =>
      'The distributor gave an address, but Rasgeth could not be reached: the app tries again at the next start.';

  @override
  String get pushFailedNetwork => 'The distributor has no network now: try again in a moment.';

  @override
  String get pushFailedVapid =>
      'The distributor wants Rasgeth\'s VAPID key, which is in the keychain: open the keychain on Rasgeth and try again.';

  @override
  String get pushFailedAction =>
      'The distributor needs something from you: open it (for example ntfy) and follow what it says.';

  @override
  String get pushFailedOther =>
      'Notifications could not be turned on: try again, or choose another distributor.';

  @override
  String get pushDistributorDropped =>
      'The distributor stopped this registration: turn notifications on again.';

  @override
  String pushTurnOn(String name) {
    return 'Turn on through $name';
  }

  @override
  String get pushTurnOff => 'Turn off';

  @override
  String pushLastError(String error) {
    return 'The last notification did not go: $error';
  }

  @override
  String get pushDistributorHead => 'Distributor (UnifiedPush)';

  @override
  String get pushDistributorHint =>
      'The distributor brings Rasgeth\'s notifications to this phone, encrypted: you choose it (ntfy, your own ntfy, Sunup…), no Google or Rasgeth cloud in between.';

  @override
  String get pushNoDistributor => 'There is no UnifiedPush distributor on this phone.';

  @override
  String get pushNoDistributorMeans =>
      'Without one, Rasgeth cannot reach you while the app is closed: you see requests and answers only by opening the app (or in a linked chat, like Telegram).';

  @override
  String get pushNoDistributorHow =>
      'To have them: install ntfy (from F-Droid or the Play Store) or another UnifiedPush distributor, then come back here and press «Look again».';

  @override
  String get pushLookAgain => 'Look again';

  @override
  String get pushIosLater =>
      'On iPhone, notifications come with the published app (Apple\'s push service, prepared and switched off until then).';

  @override
  String get pushIosMeanwhile =>
      'Meanwhile you see requests with the app open, or in a linked chat (Telegram…).';

  @override
  String get pushDesktopWhat =>
      'While the app is open, even behind other windows, requests and questions show as the system\'s notifications, with Yes and No for ordinary requests.';

  @override
  String get pushDesktopOn => 'System notifications on';

  @override
  String get pushDesktopOff => 'System notifications off';

  @override
  String get pushDesktopClosed =>
      'With the app closed this computer gets nothing: Rasgeth\'s page and the linked chats still do.';

  @override
  String get pushNotHere => 'This system has no notifications for the app.';

  @override
  String get pushAboutHead => 'How they work';

  @override
  String get pushAboutSealed =>
      'Each notification is encrypted for this device with keys made here: the distributor only carries it.';

  @override
  String get pushAboutCritical =>
      'A truly dangerous request never has the quick Yes: the notification opens it in the app, on its own screen.';

  @override
  String get pushAboutWithdrawn =>
      'A request answered somewhere else (the page, a chat) disappears from here too.';

  @override
  String get shareTitle => 'Share to Rasgeth';

  @override
  String get shareWhat => 'What you are sharing';

  @override
  String get shareTo => 'To whom';

  @override
  String get shareToChatHint => 'A new conversation';

  @override
  String get shareNoteHint => 'Add a note…';

  @override
  String get voiceReaderHead => 'Who reads the answers';

  @override
  String get voiceModelHead => 'Model';

  @override
  String get voiceVoiceHead => 'Voice';

  @override
  String get voiceAccountVoice => 'The voice is the one of the account with the key.';

  @override
  String get voiceVolumeHead => 'Volume';

  @override
  String get voiceVolumeHint =>
      'Up to the system\'s full volume: the phone\'s own buttons make it louder.';

  @override
  String get voiceTry => 'Try the voice';

  @override
  String get voiceStop => 'Stop';

  @override
  String get voiceReadAloud => 'Read aloud';

  @override
  String get voiceTrySentence => 'Hello, this is how I read the answers.';

  @override
  String get voiceNoReader => 'Rasgeth has no voice to read with yet.';

  @override
  String get voiceNoReaderHow =>
      'Add a key for OpenAI, ElevenLabs or Google Gemini in Rasgeth\'s Settings, Voice: then choose it here.';

  @override
  String get voiceTalkHead => 'Press and talk';

  @override
  String get voiceTalkWhat =>
      'In a conversation, hold the microphone down while you speak: let go and what you said is written in the field, to read before sending.';

  @override
  String get voiceTalkWhere =>
      'It is written down by Rasgeth\'s transcription (Settings, Voice, Transcription), the same as the page\'s.';

  @override
  String get voiceHoldToTalk => 'Hold down to talk';

  @override
  String get voiceListening => 'Listening… let go to finish';

  @override
  String get voiceWriting => 'Writing down what you said…';

  @override
  String get voiceTooShort => 'Too short: hold the microphone down while you speak.';

  @override
  String get voiceHeardNothing => 'I did not hear any words: try again closer to the phone.';

  @override
  String get voiceMicDenied =>
      'The microphone is not allowed: allow it in the system\'s settings for Rasgeth.';

  @override
  String get voiceMicFailed => 'The microphone did not start: is another app using it?';

  @override
  String get voiceErrNoService =>
      'Rasgeth has no transcription service: choose one in Settings, Voice, Transcription.';

  @override
  String voiceErrNoKey(String name) {
    return '$name has no key yet: add it in Settings, Voice.';
  }

  @override
  String get voiceErrEmpty => 'The recording is empty.';

  @override
  String get voiceErrTooLong => 'The recording is too long.';

  @override
  String get voiceErrConvert =>
      'The recording could not be converted for whisper on Rasgeth\'s computer.';

  @override
  String voiceErrTimeout(String name) {
    return '$name took too long to answer.';
  }

  @override
  String voiceErrUnreachable(String name) {
    return '$name cannot be reached: check that it is on and its address.';
  }

  @override
  String voiceErrKeyRefused(String name) {
    return '$name refused the key: check it in Settings, Voice.';
  }

  @override
  String voiceErrRateLimited(String name) {
    return '$name says too many requests or no credit left.';
  }

  @override
  String voiceErrServiceError(String name, String status) {
    return '$name answered with an error ($status).';
  }

  @override
  String get voiceErrProvider => 'This provider cannot do it: choose another one.';

  @override
  String get voiceErrServer => 'Rasgeth cannot be reached: check the connection.';

  @override
  String get voiceErrOther => 'The voice did not work: try again.';

  @override
  String get notifyTestFailed =>
      'The system did not show it: are notifications on for Rasgeth in its settings?';

  @override
  String get tabProjects => 'Projects';

  @override
  String get sectionCoders => 'For those who code';

  @override
  String get sectionMascots => 'Mascots';

  @override
  String get advancedTitle => 'Advanced interface';

  @override
  String get advancedNew => 'new';

  @override
  String get advancedHint =>
      'Adds Projects to the bar and, in every agent\'s sheet, Files, Diff and Terminal.';

  @override
  String get advancedTerminals => 'My agents\' terminals';

  @override
  String get advancedTerminalsHint => 'Read only; my own terminal has the row of extra keys.';

  @override
  String get codeTabTasks => 'Tasks';

  @override
  String get codeTabFiles => 'Files';

  @override
  String get codeTabDiff => 'Diff';

  @override
  String get codeTabTerminal => 'Terminal';

  @override
  String get codeTabLog => 'Log';

  @override
  String get codeTabGit => 'Git';

  @override
  String get codeArchived => 'Archived project: read only until you restore it.';

  @override
  String get codeArchivedShort => 'archived';

  @override
  String get codeChangedMeanwhile => 'The file changed since you opened it: open it again.';

  @override
  String get codeUnreachable => 'Rasgeth cannot be reached: check the connection.';

  @override
  String get codeLoadFailed => 'It did not load: pull down to try again.';

  @override
  String get codeNoRepo => 'no repository';

  @override
  String get codeDetached => 'no branch';

  @override
  String get codeClean => 'clean';

  @override
  String codeChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String codeAheadBehind(int ahead, int behind) {
    return '$ahead ahead, $behind behind';
  }

  @override
  String get codeNoProjects => 'No projects yet.';

  @override
  String codeOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks in progress',
      one: '1 task in progress',
    );
    return '$_temp0';
  }

  @override
  String get codeNoOpenTasks => 'no task in progress';

  @override
  String get codeNoTasks => 'No tasks in this project.';

  @override
  String get codeColRunning => 'In progress';

  @override
  String get codeColToVerify => 'To verify';

  @override
  String get codeColDone => 'Done';

  @override
  String get codeTaskVerified => 'verified · exit 0';

  @override
  String codeTaskNotTestable(String why) {
    return '«not testable»: $why';
  }

  @override
  String codeTaskAbandoned(String why) {
    return 'given up: $why';
  }

  @override
  String get codeTaskNoVerifier => 'verifier not run yet';

  @override
  String codeTaskVerifier(String command, String result) {
    return 'verifier: $command · $result';
  }

  @override
  String get codeTaskPassed => 'passed';

  @override
  String get codeTaskFailed => 'not passed';

  @override
  String get codeTaskDiff => 'The task\'s diff';

  @override
  String get codeSearchHint => 'Search names and text';

  @override
  String get codeNoHits => 'Nothing found.';

  @override
  String get codeEmptyFolder => 'Empty folder.';

  @override
  String get codePickFile => 'Choose a file on the left.';

  @override
  String get codeSmallEdit => 'Small edit';

  @override
  String get codeSave => 'Save';

  @override
  String get codeSaving => 'Saving…';

  @override
  String get codeSaved => 'Saved.';

  @override
  String get codeAsk => 'Ask…';

  @override
  String get codeAskWho => 'Ask which agent?';

  @override
  String codeAskDraft(String path) {
    return 'About the file `$path`: ';
  }

  @override
  String get codeSeeDiff => 'See the diff';

  @override
  String get codeCopyPath => 'Copy the path';

  @override
  String get codePathCopied => 'Path copied.';

  @override
  String get codeNotText => 'Not a text file: open it from the page.';

  @override
  String codeModifiedAt(String when) {
    return 'changed $when';
  }

  @override
  String get codeDiffWorking => 'Uncommitted changes';

  @override
  String codeDiffTask(String title) {
    return 'Task «$title»';
  }

  @override
  String codeDiffCommit(String hash, String subject) {
    return 'Commit $hash $subject';
  }

  @override
  String codeDiffAgent(String name) {
    return '$name\'s work';
  }

  @override
  String get codeDiffWhich => 'Which diff?';

  @override
  String get codeDiffEmpty => 'No differences.';

  @override
  String get codeDiffTruncated => 'Too long: only the first part is shown.';

  @override
  String get codeDiffBinary => 'A binary file: nothing to read here.';

  @override
  String get codeDiffNoHunks => 'Renamed or mode changed only.';

  @override
  String codeFileOf(int n, int total) {
    return '$n of $total';
  }

  @override
  String get codePrevFile => 'Previous file';

  @override
  String get codeNextFile => 'Next file';

  @override
  String get codeKeep => 'Keep';

  @override
  String get codeKept => 'Kept';

  @override
  String get codeDiscard => 'Discard';

  @override
  String get codeDiscarded => 'Discarded';

  @override
  String get codeDiscardTitle => 'Discard this change?';

  @override
  String codeDiscardBody(String path) {
    return 'The change to $path is removed from the files. A copy stays in the project\'s trash (.trash/diffs) to put back.';
  }

  @override
  String codeDiscardCommitBody(String path) {
    return 'This change of the commit is undone in $path (as a new uncommitted change). A copy stays in the project\'s trash (.trash/diffs).';
  }

  @override
  String get codeComment => 'Comment';

  @override
  String codeCommentHint(String name) {
    return 'A note for $name';
  }

  @override
  String codeCommentIntro(String path, String hunk) {
    return 'A comment on `$path`, at $hunk:';
  }

  @override
  String codeCommentSent(String name) {
    return 'Sent to $name.';
  }

  @override
  String get codeCommentFailed => 'Not sent: try again.';

  @override
  String get codeNoChat => 'No conversation with this agent yet.';

  @override
  String get codeTermMine => 'Mine';

  @override
  String get codeTextSmaller => 'Smaller text';

  @override
  String get codeTextBigger => 'Bigger text';

  @override
  String get codeTermReadOnly => 'Read only: the commands the agent ran and what they printed.';

  @override
  String get codeTermNoCommands => 'No commands yet.';

  @override
  String get codeReload => 'Load again';

  @override
  String get codeTermIntro => 'A shell in the project\'s sandbox, like the page\'s terminal.';

  @override
  String get codeTermOpen => 'Open the terminal';

  @override
  String get codeTermHint => 'A command';

  @override
  String get codeTermClosed => 'The terminal closed.';

  @override
  String get codeLogAgent => 'Which agent?';

  @override
  String get codeLogAllAgents => 'Every agent';

  @override
  String get codeLogType => 'Which type?';

  @override
  String get codeLogAllTypes => 'Every type';

  @override
  String get codeLogErrors => 'Errors only';

  @override
  String get codeLogEmpty => 'Nothing in the log.';

  @override
  String get codeLogOpenChat => 'Open the conversation';

  @override
  String get codeBranches => 'Branches';

  @override
  String get codeCommits => 'Commits';

  @override
  String codeUpstream(String name) {
    return 'follows $name';
  }

  @override
  String get codeNoUpstream => 'not sent anywhere yet';

  @override
  String get codeCommitHint => 'What changed (the commit\'s message)';

  @override
  String get codeCommit => 'Commit';

  @override
  String codeCommitted(String hash) {
    return 'Commit $hash made.';
  }

  @override
  String get codeNothingToCommit => 'Nothing to commit.';

  @override
  String get codePush => 'Push';

  @override
  String get codePushAsked =>
      'Push asked: answer it from «For you» (it is a request to you, like an agent\'s).';

  @override
  String get codePushDone => 'Pushed.';

  @override
  String get codePushDenied => 'Not pushed: the answer was no.';

  @override
  String codePushFailed(String error) {
    return 'The push did not work: $error';
  }

  @override
  String get codeNoRemote => 'The project has no remote repository to push to.';

  @override
  String get savedSave => 'Save';

  @override
  String get savedSaveTitle => 'Save this passage';

  @override
  String get savedSaveMessageTitle => 'Save this message';

  @override
  String get savedNote => 'Note (optional)';

  @override
  String get savedNotePlaceholder => 'Why you keep it, what to do with it…';

  @override
  String get savedTags => 'Tags (optional)';

  @override
  String get savedTagsPlaceholder => 'New tags, separated by commas';

  @override
  String get savedDone => 'Saved: it is in your saved items, with the conversation it comes from.';

  @override
  String get savedOpenArchive => 'Open';

  @override
  String savedFailed(String error) {
    return 'Not saved: $error';
  }

  @override
  String get savedTitle => 'Saved';

  @override
  String get savedHint =>
      'Passages and messages you kept from your conversations: only you see them. Select a part of an answer and pick «Save», or use «Save» in a message\'s menu.';

  @override
  String get savedSearch => 'Search in the saved items';

  @override
  String get savedAllTags => 'All tags';

  @override
  String get savedAllAgents => 'All agents';

  @override
  String get savedEmpty => 'Nothing saved yet.';

  @override
  String get savedNoMatch => 'Nothing saved matches.';

  @override
  String get savedMore => 'Show older';

  @override
  String get savedWhole => 'Whole message';

  @override
  String savedOn(String when) {
    return 'Saved $when';
  }

  @override
  String get savedOpen => 'Open in the conversation';

  @override
  String get savedEdit => 'Edit note and tags';

  @override
  String get savedDelete => 'Delete';

  @override
  String get savedDeleteTitle => 'Delete this saved item?';

  @override
  String get savedDeleteText =>
      'The passage leaves your saved items; the conversation stays as it is.';

  @override
  String get savedUnknownOrigin => 'A conversation';

  @override
  String get savedFromDailyChat => 'It comes from the daily chat of the page: open it there.';

  @override
  String get savedNotThere => 'The message is not in the conversation any more.';

  @override
  String get savedExport => 'Export as Markdown';

  @override
  String get savedExportFile => 'Save the file';

  @override
  String get savedExportCopy => 'Copy the Markdown';

  @override
  String get savedExportSaved => 'File saved.';

  @override
  String get savedExportCopied => 'Markdown copied: paste it where you like.';

  @override
  String savedExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get savedFileName => 'saved.md';

  @override
  String get quoteReply => 'Reply to this';

  @override
  String get quoteReplyingTo => 'You are replying to this passage';

  @override
  String get quoteRemove => 'Remove this passage';

  @override
  String get quoteJump => 'Go to the passage in the conversation';

  @override
  String quoteTooMany(int n) {
    return 'At most $n passages in one message.';
  }

  @override
  String get messageMenu => 'Message options';

  @override
  String get messageCopied => 'Copied.';

  @override
  String get messageSaveHint => 'Keep this whole message in your saved items';

  @override
  String get productOpen => 'Open';

  @override
  String productSource(int n) {
    return 'Source $n of the answer';
  }

  @override
  String get productNoPicture => 'No picture';

  @override
  String get productPrevious => 'Previous products';

  @override
  String get productNext => 'Next products';

  @override
  String get quoteReplyShort => 'Reply';

  @override
  String get savedSearchClear => 'Clear the search';

  @override
  String get metricsInput => 'in';

  @override
  String get metricsCache => 'cache';

  @override
  String get metricsOutput => 'out';

  @override
  String get metricsContext => 'context';

  @override
  String get metricsPrefill => 'prefill';

  @override
  String get metricsGeneration => 'generation';

  @override
  String get metricsTimedByClient => 'timed by the client';

  @override
  String get metricsServerTimings => 'server timings';

  @override
  String get metricsStart => 'start';

  @override
  String get metricsFirstToken => 'first token';

  @override
  String get metricsEnd => 'end';

  @override
  String get metricsRestoredFromDisk =>
      'Persistar: this conversation\'s context came back from the disk before this request';

  @override
  String get metricsCostUnknown => 'cost not known';

  @override
  String get metricsCostUnknownHint =>
      'This model is not in the models catalog yet: its prices are not known, so its cost is not counted.';

  @override
  String get metricsShowAll => 'Show all the message\'s figures';

  @override
  String updNowBodyLocal(String version) {
    return 'On this computer Rasgeth does the update to $version in its own window: it downloads, closes and starts again as the new version. Here you see the steps it reports.';
  }

  @override
  String get updFollow => 'Follow the update';

  @override
  String upd2Title(String from, String to) {
    return 'Updating Rasgeth from $from to $to';
  }

  @override
  String upd2TitleTo(String to) {
    return 'Updating Rasgeth to $to';
  }

  @override
  String get upd2Starting => 'Starting the update…';

  @override
  String upd2Left(String time) {
    return 'about $time left';
  }

  @override
  String upd2Total(String time) {
    return 'about $time in all';
  }

  @override
  String get upd2LeftUnknown => 'working out how long it takes…';

  @override
  String upd2Elapsed(String time) {
    return 'running for $time';
  }

  @override
  String upd2ToDownload(String size) {
    return '$size to download';
  }

  @override
  String get upd2Steps => 'The update\'s steps';

  @override
  String get upd2Restarting => 'Rasgeth is restarting, reconnecting…';

  @override
  String upd2Attempt(String n, String time) {
    return 'Attempt $n · no answer for $time';
  }

  @override
  String get upd2Back => 'Rasgeth answers: checking it is the new version…';

  @override
  String get upd2Keeps =>
      'Rasgeth keeps working while it downloads: it stops only for the restart, a minute or two.';

  @override
  String get upd2ComesBack =>
      'Keep the app open: it reconnects by itself as soon as Rasgeth answers as the new version.';

  @override
  String get upd2Local =>
      'On this computer Rasgeth does the update in its own window, with the bar and the time: here you see the steps it reports, and if this window stays open it reconnects by itself when Rasgeth is back.';

  @override
  String get upd2Older =>
      'This Rasgeth does not report each step\'s details yet (they come with 3.8.1): you see where it is and for how long.';

  @override
  String upd2Done(String version) {
    return 'Updated to $version';
  }

  @override
  String upd2DoneText(String from, String time) {
    return 'From $from, in $time. Conversations, agents and settings are as before.';
  }

  @override
  String upd2DoneFrom(String from) {
    return 'From $from. Conversations, agents and settings are as before.';
  }

  @override
  String get upd2Reconnected => 'The app reconnected by itself.';

  @override
  String get upd2Reconnecting => 'Reconnecting to the new version…';

  @override
  String upd2News(String version) {
    return 'What\'s new in $version';
  }

  @override
  String get upd2Notes => 'The version\'s notes on GitHub';

  @override
  String get upd2BackHome => 'Back to Rasgeth';

  @override
  String get upd2Hide => 'Hide: the update goes on';

  @override
  String get upd2Retry => 'Try again';

  @override
  String get upd2Close => 'Go back';

  @override
  String get upd2TookLess => 'less than a minute';

  @override
  String upd2TookMin(String min) {
    return '$min min';
  }

  @override
  String upd2TookHours(String h, String min) {
    return '$h h $min min';
  }

  @override
  String get upd2ImgHere => 'already here';

  @override
  String get upd2ImgDone => 'downloaded';

  @override
  String get upd2ImgDatabase => 'The database (Postgres)';

  @override
  String get upd2StepDone => 'done';

  @override
  String get upd2StepNow => 'in progress';

  @override
  String get upd2StepTodo => 'to do';

  @override
  String get upd2StepFailed => 'stopped here';

  @override
  String get upd2Step_check => 'Check the new version\'s signature';

  @override
  String get upd2Step_download => 'Download the new version';

  @override
  String get upd2Step_files => 'Download the system\'s files';

  @override
  String get upd2Step_install => 'Install the system\'s files';

  @override
  String get upd2Step_restart => 'Restart Rasgeth as the new version';

  @override
  String get upd2Step_wait => 'Check that Rasgeth answers';

  @override
  String get upd2Step_rollback => 'Put the previous version back';

  @override
  String get upd2Step_scan => 'Compare the installed files';

  @override
  String get upd2Step_build => 'Put the new version together';

  @override
  String get upd2Step_installer => 'Download the installer';

  @override
  String get upd2StepText_check => 'Only a version signed by Rasgeth is installed.';

  @override
  String get upd2StepText_download => 'Rasgeth keeps working while it downloads.';

  @override
  String get upd2StepText_files => 'The programs of the system around Rasgeth.';

  @override
  String get upd2StepText_install =>
      'A copy of every file replaced is kept: if something goes wrong, it goes back as it was.';

  @override
  String get upd2StepText_restart =>
      'For a minute or two Rasgeth does not answer: the app reconnects by itself.';

  @override
  String get upd2StepText_wait =>
      'If the new version does not answer within ten minutes, the previous one comes back by itself.';

  @override
  String get upd2StepText_rollback =>
      'The new version did not start: the previous one is coming back, nothing is lost.';

  @override
  String get upd2StepText_scan => 'So only what changed is downloaded.';

  @override
  String get upd2StepText_build => 'The new version is prepared beside the current one.';

  @override
  String get upd2StepText_installer => 'The whole program: it installs over the current one.';

  @override
  String get upd2Why_download => 'The new version could not be downloaded.';

  @override
  String upd2WhyText_download(String from) {
    return 'Nothing changed: Rasgeth $from keeps working. Check that the machine reaches the internet, then press «Try again»: what came down already is not downloaded twice.';
  }

  @override
  String get upd2Why_files => 'The system\'s new files could not be installed.';

  @override
  String upd2WhyText_files(String from) {
    return 'Every file went back as it was and Rasgeth $from keeps working. Try again in a while; if it happens again, download the diagnostics from the page (Settings › General › Diagnostics) and send them.';
  }

  @override
  String get upd2Why_not_up => 'The new version did not start.';

  @override
  String upd2WhyText_not_up(String from) {
    return 'Rasgeth went back to $from by itself: nothing is lost. Try again in a while; if it happens again, download the diagnostics from the page (Settings › General › Diagnostics) and send them.';
  }

  @override
  String get upd2Why_no_images => 'This version has nothing for this machine\'s processor.';

  @override
  String upd2WhyText_no_images(String from) {
    return 'Nothing changed: Rasgeth $from keeps working. Wait for the next version.';
  }

  @override
  String get upd2Why_breaking => 'This version cannot be installed over the current one.';

  @override
  String upd2WhyText_breaking(String from) {
    return 'Nothing changed: Rasgeth $from keeps working. Open Rasgeth\'s page from the computer: it guides you through the clean install.';
  }

  @override
  String get upd2Why_unsigned => 'The new version is not signed.';

  @override
  String get upd2WhyText_unsigned =>
      'For safety it was not installed: nothing changed. Look again later.';

  @override
  String get upd2Why_unreachable => 'GitHub did not answer.';

  @override
  String get upd2WhyText_unreachable =>
      'Nothing changed. Check that the machine reaches the internet and press «Try again».';

  @override
  String get upd2Why_other => 'The update did not finish.';

  @override
  String upd2WhyText_other(String from) {
    return 'The previous version ($from) is running: nothing is lost. Try again in a while.';
  }

  @override
  String get upd2Why_gone => 'Rasgeth does not answer any more.';

  @override
  String get upd2WhyText_gone =>
      'It did not come back after the restart. Check that the machine is on and in the network, then press «Try again»: the app looks for it again.';

  @override
  String get upd2Why_start => 'The update did not start.';

  @override
  String upd2WhyText_start(String from) {
    return 'Nothing changed: Rasgeth $from keeps working. Try again in a while.';
  }

  @override
  String upd2WhySaid(String error) {
    return 'Rasgeth said: $error';
  }

  @override
  String get upd2ScreenTitle => 'Rasgeth\'s update';

  @override
  String get deskAbout => 'About Rasgeth';

  @override
  String get deskAdvancedOff => 'Turn off the advanced interface';

  @override
  String get deskAdvancedOn => 'Turn on the advanced interface';

  @override
  String get deskAdvancedShort => 'advanced';

  @override
  String deskAgeDays(int n) {
    return '$n d';
  }

  @override
  String deskAgeHours(int n) {
    return '$n h';
  }

  @override
  String deskAgeMinutes(int n) {
    return '$n min';
  }

  @override
  String get deskAgeNow => 'now';

  @override
  String get deskAgeYesterday => 'yesterday';

  @override
  String deskAgentAsks(String name, String what) {
    return '$name asks: $what';
  }

  @override
  String deskAgentsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get deskAgentsHead => 'Agents';

  @override
  String get deskAgentsTerminals => 'Agents\'';

  @override
  String get deskAllProjects => 'All projects';

  @override
  String get deskAllProjectsLower => 'all projects';

  @override
  String get deskAskChat => 'Ask the Chat';

  @override
  String get deskAskGod => 'Ask God';

  @override
  String deskAskHint(String name) {
    return 'Ask $name without opening the conversation…';
  }

  @override
  String get deskAskInConversation => 'Ask in its conversation';

  @override
  String deskAskTag(String name) {
    return 'To $name';
  }

  @override
  String deskAsked(String name) {
    return 'Sent to $name';
  }

  @override
  String deskAsks(String what) {
    return 'Asks: $what';
  }

  @override
  String get deskByProject => 'By project';

  @override
  String get deskByState => 'By state';

  @override
  String get deskChanges => 'Changes';

  @override
  String get deskChatHint => 'Ask me anything…';

  @override
  String get deskChatSub => 'for every day';

  @override
  String get deskChosenCommit => 'Chosen commit';

  @override
  String get deskClose => 'Close';

  @override
  String get deskCloseFloating => 'Close the floating panels';

  @override
  String get deskColAgent => 'Agent';

  @override
  String get deskColDuration => 'Duration';

  @override
  String get deskColSummary => 'Summary';

  @override
  String get deskColTime => 'Time';

  @override
  String get deskColType => 'Type';

  @override
  String get deskCopy => 'Copy';

  @override
  String get deskCopyJson => 'Copy JSON';

  @override
  String deskCriticalCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n critical',
      one: '1 critical',
    );
    return '$_temp0';
  }

  @override
  String get deskCriticalTitle => 'Critical request';

  @override
  String get deskCut => 'Cut';

  @override
  String get deskDiffWord => 'diff';

  @override
  String get deskDockAll => 'Put the floating panels back';

  @override
  String get deskDropHere => 'Drop to attach';

  @override
  String deskEventN(int n) {
    return 'Event $n';
  }

  @override
  String get deskEventStream => 'Stream of events';

  @override
  String get deskFiles => 'Files';

  @override
  String deskFilesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n files', one: '1 file');
    return '$_temp0';
  }

  @override
  String get deskFilterAll => 'All';

  @override
  String get deskFilterBlocked => 'Blocked';

  @override
  String get deskFilterWaiting => 'Waiting for you';

  @override
  String get deskFilterWorking => 'Working';

  @override
  String get deskFindAgent => 'Find an agent…';

  @override
  String deskFloatingCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n floating panels',
      one: '1 floating panel',
    );
    return '$_temp0';
  }

  @override
  String deskForYouCount(int n) {
    return '$n for you';
  }

  @override
  String get deskForYouPush => 'For you: a push';

  @override
  String get deskForYouShort => 'for you';

  @override
  String get deskFrozen => 'paused';

  @override
  String get deskGitCommit => 'Make a commit…';

  @override
  String get deskGitCommitTitle => 'Commit everything in the working tree';

  @override
  String get deskGitHistory => 'Show the history';

  @override
  String get deskGitPush => 'Send…';

  @override
  String get deskGoToFile => 'Go to file…';

  @override
  String get deskGodHint => 'Ask God to organise something…';

  @override
  String get deskGrid => 'Grid';

  @override
  String get deskHintAsk => 'ask now';

  @override
  String get deskHintChoose => 'choose';

  @override
  String get deskHintFloat => 'in a floating panel';

  @override
  String get deskHintOpen => 'open';

  @override
  String get deskHintPrefixes => 'type @ for agents, / for commands';

  @override
  String get deskHintPrefixesAdvanced => 'no prefix searches everything';

  @override
  String get deskInContainer => 'in the project\'s container';

  @override
  String get deskInConversation => 'In the conversation';

  @override
  String get deskInline => 'Inline';

  @override
  String get deskKeyDown => 'Down';

  @override
  String get deskKeyEnter => 'Enter';

  @override
  String get deskKeyEsc => 'Esc';

  @override
  String get deskKeyOption => 'Opt';

  @override
  String get deskKeyShift => 'Shift';

  @override
  String get deskKeySpace => 'Space';

  @override
  String get deskKeyTab => 'Tab';

  @override
  String get deskKeyUp => 'Up';

  @override
  String get deskLayoutAlways => 'Always';

  @override
  String deskLayoutFrom(int n) {
    return 'From $n px';
  }

  @override
  String get deskLayoutHint =>
      'The control room when the window is at least this wide; narrower, the phone\'s screens.';

  @override
  String get deskLayoutNever => 'Never';

  @override
  String get deskLayoutTitle => 'Computer\'s layout';

  @override
  String get deskList => 'List';

  @override
  String get deskLive => 'live';

  @override
  String get deskLogSearchHint => 'agente:\"Coder Web\" tipo:tool.* text';

  @override
  String get deskMenuAgents => 'Agents';

  @override
  String get deskMenuConversation => 'Conversation';

  @override
  String get deskMenuEdit => 'Edit';

  @override
  String get deskMenuFile => 'File';

  @override
  String get deskMenuHelp => 'Help';

  @override
  String get deskMenuView => 'View';

  @override
  String get deskMenuWindow => 'Window';

  @override
  String deskNewAgentNamed(String name) {
    return 'New agent «$name»…';
  }

  @override
  String get deskNewConversation => 'New conversation with the open agent';

  @override
  String get deskNewTerminal => 'New terminal';

  @override
  String get deskNoActions => 'No recent actions';

  @override
  String get deskNoAgents => 'No agents';

  @override
  String get deskNoChanges => 'none, everything is committed';

  @override
  String get deskNoGit => 'no repository: files only';

  @override
  String get deskNoGitShort => 'no git';

  @override
  String get deskNoKeysHere => 'No keys here: credentials stay on the egress routes';

  @override
  String get deskNoProject => 'Without a project';

  @override
  String get deskNoProjects => 'No projects yet';

  @override
  String get deskNoTask => 'no open task';

  @override
  String get deskNoTerminals => 'Choose a terminal on the left';

  @override
  String get deskNoneHere => 'No agent in this filter';

  @override
  String get deskNothingForYou => 'nothing to answer';

  @override
  String deskOfTotal(int n, int total) {
    return '$n of $total';
  }

  @override
  String get deskOnly => 'Only';

  @override
  String get deskOnlyErrors => 'errors and failures';

  @override
  String get deskOnlyRequests => 'requests to you';

  @override
  String get deskOpenDetail => 'Open the detail';

  @override
  String get deskOpenInPanel => 'Open in the side panel';

  @override
  String get deskOpenTasks => 'Open tasks';

  @override
  String get deskPaletteAgents => 'Agents';

  @override
  String deskPaletteAnswer(String what) {
    return 'Answer: $what';
  }

  @override
  String get deskPaletteCommands => 'Commands';

  @override
  String get deskPaletteConversations => 'Conversations';

  @override
  String get deskPaletteEvents => 'Log events';

  @override
  String get deskPaletteFiles => 'Files';

  @override
  String get deskPaletteHint => 'Agents, conversations, commands, files…';

  @override
  String get deskPaletteLines => 'Lines';

  @override
  String get deskPaletteNothing => 'Nothing found';

  @override
  String deskPaletteOpenFile(String path) {
    return 'Open $path';
  }

  @override
  String get deskPaletteRequests => 'For you';

  @override
  String get deskPaletteTerminal => 'Terminal';

  @override
  String get deskPaletteTitle => 'Command palette';

  @override
  String get deskPanelClose => 'Close the panel';

  @override
  String get deskPanelDetach => 'Take out of the panel';

  @override
  String get deskPanelDock => 'Back into the side panel';

  @override
  String get deskPanelResize => 'Panel width';

  @override
  String get deskPaste => 'Paste';

  @override
  String get deskPickEvent => 'Choose an event to see it whole';

  @override
  String get deskProject => 'Project';

  @override
  String deskProjectWorking(String name, String state, int n) {
    return '$name $state · $n working';
  }

  @override
  String get deskPushAsked => 'Asked in «For you»: the push goes once you say yes';

  @override
  String get deskQuickChat => 'Quick Chat';

  @override
  String get deskQuickChatExpand => 'Open in the side panel';

  @override
  String deskQuickChatHint(String keys) {
    return '$keys calls it inside the app';
  }

  @override
  String get deskReadOnly => 'read only';

  @override
  String get deskRedo => 'Redo';

  @override
  String get deskRemotes => 'Remotes';

  @override
  String deskRequestsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n requests',
      one: '1 request',
    );
    return '$_temp0';
  }

  @override
  String deskRunInTerminal(String cmd, String project) {
    return 'Run «$cmd» in your terminal of $project';
  }

  @override
  String get deskRunInTerminalDetail =>
      'In a terminal of yours, in the project\'s container. Your commands ask no permission: it is you.';

  @override
  String get deskSameTurn => 'In the same turn';

  @override
  String get deskSearchCommits => 'Search the commits';

  @override
  String deskSearchEvents(String q) {
    return 'Events with «$q» in the Log';
  }

  @override
  String get deskSearchShort => 'Search';

  @override
  String get deskSelectAll => 'Select all';

  @override
  String get deskSettings => 'Settings';

  @override
  String get deskShortcuts => 'Keyboard shortcuts';

  @override
  String get deskSideBySide => 'Side by side';

  @override
  String deskStatusPalette(String keys) {
    return '$keys palette';
  }

  @override
  String get deskStill => 'Still';

  @override
  String deskStopAgent(String name) {
    return 'Stop $name';
  }

  @override
  String get deskStopOpen => 'Stop the open agent';

  @override
  String get deskStreamHint => 'Paused under the pointer · a click opens the Log';

  @override
  String deskSubagents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n subagents',
      one: '1 subagent',
    );
    return '$_temp0';
  }

  @override
  String get deskTabs => 'Tabs';

  @override
  String get deskTags => 'Tags';

  @override
  String get deskTaskChanges => 'The task\'s changes';

  @override
  String get deskTaskFailed => 'failing';

  @override
  String get deskTaskPassed => 'passing';

  @override
  String get deskTaskRunning => 'in progress';

  @override
  String get deskTasksRule => 'they close only with a verifier that exits 0';

  @override
  String get deskTermAskHint => 'To ask it something write in its conversation';

  @override
  String deskTerminalsShown(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n terminals',
      one: '1 terminal',
    );
    return '$_temp0';
  }

  @override
  String deskTheme(String name) {
    return 'Theme: $name';
  }

  @override
  String get deskTiles => 'Tiles';

  @override
  String deskToSend(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n commits to send',
      one: '1 commit to send',
      zero: 'nothing to send',
    );
    return '$_temp0';
  }

  @override
  String get deskTogglePanel => 'Side panel';

  @override
  String get deskTypeHead => 'Type';

  @override
  String get deskUndo => 'Undo';

  @override
  String get deskVerifier => 'Verifier';

  @override
  String get deskViewCode => 'Code';

  @override
  String get deskViewTerminals => 'Terminals';

  @override
  String get deskWhen => 'When';

  @override
  String get deskWhenAll => 'all';

  @override
  String get deskWhenHour => '1 hour';

  @override
  String get deskWhenToday => 'today';

  @override
  String get deskWhenWeek => '7 days';

  @override
  String get deskWithChanges => 'With changes';

  @override
  String deskWorkingCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n agents working',
      one: '1 agent working',
    );
    return '$_temp0';
  }

  @override
  String get deskYouWrite => 'you can write';

  @override
  String get deskYourTerminal => 'Your terminal';

  @override
  String get deskYourTerminals => 'Yours';

  @override
  String get deskNewProject => 'New project';

  @override
  String get deskProjectName => 'Project name';

  @override
  String get deskProjectCreate => 'Create';

  @override
  String deskProjectMade(String name) {
    return 'Project «$name» created, with its orchestrator.';
  }

  @override
  String deskProjectFailed(String why) {
    return 'I could not make the project: $why';
  }

  @override
  String deskProjectNoGit(String name, String why) {
    return 'Project «$name» created, but without a git repository: $why. Create it from Settings › Projects («Initialise git») once git works.';
  }

  @override
  String get deskGitMissing => 'git is not installed on this computer yet';

  @override
  String get limitsTotal => 'Total';

  @override
  String get limitsSpent => 'Spent';

  @override
  String get limitsContext => 'Context';

  @override
  String get limitsWeekShort => '7d';

  @override
  String get deskSendMessage => 'Send the message (in the conversations\' fields)';

  @override
  String get deskFullWindow => 'Full window';

  @override
  String get deskFullWindowOff => 'Back to the panel';

  @override
  String get deskBackToRoom => 'Back to the room';

  @override
  String get deskRailLabel => 'Agents';

  @override
  String deskRailWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests for you',
      one: '1 request for you',
    );
    return '$_temp0';
  }

  @override
  String get tpReading => 'Reading the context';

  @override
  String tpTokens(String done, String total) {
    return '$done of $total tokens';
  }

  @override
  String tpRate(String n) {
    return '$n tokens/s';
  }

  @override
  String tpCache(String pct) {
    return '$pct from the cache';
  }

  @override
  String get tpWaitingFirst =>
      'The provider does not say how far it is: waiting for the first token';

  @override
  String get tpThinking => 'Reasoning';

  @override
  String get tpWriting => 'Writing';

  @override
  String tpWritten(String n) {
    return 'about $n tokens';
  }

  @override
  String tpGenRate(String n) {
    return 'about $n tokens/s';
  }

  @override
  String tpReadIn(String total, String time, String pct) {
    return 'context of $total read in $time, $pct from the cache';
  }

  @override
  String tpFirstAfter(String time) {
    return 'first token after $time';
  }

  @override
  String get compactingNow => 'Summarising the conversation…';

  @override
  String get asOpen => 'Agent settings…';

  @override
  String asTitle(String name) {
    return 'Settings of $name';
  }

  @override
  String get asClose => 'Close';

  @override
  String get asGroupGeneral => 'General';

  @override
  String get asGroupWork => 'Model and way';

  @override
  String get asGroupMemory => 'Memory';

  @override
  String get asGroupLimits => 'Spending';

  @override
  String get asGroupTools => 'Tools';

  @override
  String get asGroupKnowledge => 'Knowledge';

  @override
  String get asKind_god => 'God, leads everything';

  @override
  String get asKind_demigod => 'Demi-God, the Telegram messenger';

  @override
  String get asKind_orchestrator => 'Project lead';

  @override
  String get asKind_agent => 'Agent';

  @override
  String get asKind_subagent => 'Helper';

  @override
  String get asKind_inspector => 'Inspector, reads only';

  @override
  String get asKind_assistant => 'Personal assistant';

  @override
  String get asKindChat => 'The everyday Chat';

  @override
  String get asStopped => 'Stopped';

  @override
  String get asMascot => 'Mascot';

  @override
  String get asMascotHelp => 'Renaming it never changes its face: only you change it, here.';

  @override
  String get asMascotGod =>
      'God\'s mascot is drawn by hand: the crowned giant star, with three little stars going round it.';

  @override
  String get asName => 'Name';

  @override
  String get asRole => 'What it does';

  @override
  String get asRoleHelp =>
      'One or two lines: God and the orchestrators read it to decide what to hand over.';

  @override
  String get asProjects => 'Also works for';

  @override
  String asProjectsHelp(String name) {
    return 'Choose the projects $name also works for: there it sits under the project\'s orchestrator, which gives it tasks.';
  }

  @override
  String get asSaved => 'Saved.';

  @override
  String get asSavedNew => 'Saved: it applies from new conversations.';

  @override
  String asRefused(String why) {
    return 'The server did not accept it: $why';
  }

  @override
  String get asNoName => 'A name is needed.';

  @override
  String get asModelHelp =>
      'Without a model of its own it uses the one of the agent above it. It applies from new conversations: you change an open conversation\'s model from its composer.';

  @override
  String get asModelGodHelp =>
      'The model God uses; without one, the default model chosen in the setup. You change an open conversation\'s model from its composer.';

  @override
  String get asModelChatHelp =>
      'The Chat\'s model, as in its header on the page. You change an open conversation\'s model from its composer.';

  @override
  String get asMode => 'How freely it works';

  @override
  String get asModeHelp => 'Whatever sends, publishes, deletes or pays always waits for you.';

  @override
  String get asMode_auto => 'On its own';

  @override
  String get asMode_manual => 'Asks permission';

  @override
  String get asMode_plan => 'Plan first';

  @override
  String get asMode_readonly => 'Read only';

  @override
  String get asModeExplain_auto => 'Works on its own and asks only for what is dangerous.';

  @override
  String get asModeExplain_manual => 'Asks you before every change to files or commands.';

  @override
  String get asModeExplain_plan => 'Writes a plan first and starts once you approve it.';

  @override
  String get asModeExplain_readonly => 'Reads and answers, changes nothing.';

  @override
  String get asInstructionsHelp =>
      'Its system prompt, its own or the built-in one: open conversations keep theirs.';

  @override
  String asMemOwn(String name) {
    return 'Memory of $name: only for this agent';
  }

  @override
  String asMemOwnHelp(String name) {
    return 'Only $name reads it, at the start of every conversation. $name can also note here what it needs.';
  }

  @override
  String asMemProject(String name) {
    return 'Memory of the project «$name»';
  }

  @override
  String get asMemProjectHelp => 'Every agent working on this project reads it.';

  @override
  String get asMemNone => 'This agent keeps no memory of its own.';

  @override
  String get asCompact => 'Summaries of long conversations';

  @override
  String get asCompactHelp =>
      'When the conversation gets long, the agent writes a summary of the old parts, like someone taking notes. Here you choose when it does it, and how much of the latest part it keeps as it is.';

  @override
  String get asCompactAt => 'When to write the summary';

  @override
  String asCompactAtValue(String n) {
    return 'when $n% full';
  }

  @override
  String get asCompactKeep => 'How much of the latest part to keep as it is';

  @override
  String asCompactKeepValue(String n) {
    return 'the last $n%';
  }

  @override
  String get asCompactKeepNone => 'nothing';

  @override
  String asCompactDefaultIs(String at, String keep) {
    return 'Default for this agent\'s model: at $at%, keeping $keep%.';
  }

  @override
  String get asCompactDefaults => 'Back to the defaults';

  @override
  String get asLimitsHelp =>
      'When it reaches the limit it stops and asks you. The limit counts everything spent since it was set.';

  @override
  String get asSpent => 'Spent so far';

  @override
  String get asLimit => 'Limit in dollars';

  @override
  String get asNoLimit => 'No limit';

  @override
  String asLimitTokens(String n) {
    return 'Limit: $n tokens';
  }

  @override
  String get asRemoveLimit => 'Remove the limit';

  @override
  String get asLimitBad => 'Write an amount above zero.';

  @override
  String get asToolsHelp =>
      'For each tool: as for every agent (Settings, Tools), always on for this agent, or off. The essential ones never switch off.';

  @override
  String get asToolsNewOnly =>
      'Changes apply from new conversations: the ones already open keep their tools.';

  @override
  String asToolsTotal(String name, String n) {
    return '$name: about $n tokens in every message';
  }

  @override
  String get asToolDefaultOn => 'As for everyone (on)';

  @override
  String get asToolDefaultOff => 'As for everyone (off)';

  @override
  String get asToolAlways => 'Always on';

  @override
  String get asToolOff => 'Off';

  @override
  String get asToolLocked => 'Essential: always on';

  @override
  String get asEditRule => 'Edits in open files';

  @override
  String get asEditRuleHelp =>
      'When it edits a file open in the Canvas: right away (highlighted, undoable) or as proposals you accept. A file\'s own choice wins.';

  @override
  String get asEditNow => 'Right away';

  @override
  String get asEditPropose => 'As proposals';

  @override
  String asKbHelp(String name) {
    return 'Which collections $name can search. Each one says who may read it; here you can make an exception for this agent. It applies from its next conversation.';
  }

  @override
  String get asKbNone => 'No collections yet.';

  @override
  String asKbByScope(String on) {
    return 'By where it belongs ($on)';
  }

  @override
  String get asKbOn => 'Yes';

  @override
  String get asKbOff => 'No';

  @override
  String get asKbScope_global => 'Every agent';

  @override
  String get asKbScope_agent => 'One agent';

  @override
  String get asKbScope_project => 'A project\'s agents';

  @override
  String get asDanger => 'Stopping it';

  @override
  String get asStopHelp =>
      'A pause: its turns stop now, with those under it, and its open tasks wait. «Resume» brings it back and the tasks go on in the same conversation. To take it out of the team, use «Remove…».';

  @override
  String asStopAsk(String name) {
    return 'Stop $name? It is a pause: its turns stop now and its open tasks wait; «Resume» brings it back and they go on where they were.';
  }

  @override
  String asStopYes(String name) {
    return 'Stop $name';
  }

  @override
  String asStoppedNow(String name) {
    return '$name is stopped.';
  }

  @override
  String asLoadFailed(String why) {
    return 'I could not read it from the server: $why';
  }

  @override
  String get asMenuNew => 'New conversation';

  @override
  String get asMenuModel => 'Model and effort…';

  @override
  String get asMenuInstructions => 'Instructions…';

  @override
  String get asMenuStopTurn => 'Stop what it is doing';

  @override
  String cvPermAsks(String agent) {
    return '$agent asks for your yes';
  }

  @override
  String get cvPermWhy => 'Why it asks';

  @override
  String get cvPermDetails => 'Details';

  @override
  String get cvPermTool => 'Tool';

  @override
  String get cvPermRawReasons => 'Reasons in the log';

  @override
  String get cvShowLess => 'Show fewer';

  @override
  String get cvShowAllInput => 'Show the whole input';

  @override
  String get cvAllow => 'Allow';

  @override
  String get cvThisChat => 'In this conversation';

  @override
  String cvThisChatHint(String tool) {
    return 'Allow $tool without asking again, in this conversation only';
  }

  @override
  String get cvAlways => 'Always';

  @override
  String cvAlwaysHint(String tool) {
    return 'Allow $tool from now on without asking (a rule you can undo in Settings, Platform)';
  }

  @override
  String get cvDeny => 'Deny';

  @override
  String get cvDenyWhy => 'Deny and say why';

  @override
  String get cvDenyWhyPlaceholder => 'What to do instead (the agent reads it)';

  @override
  String get cvCriticalTitle => 'Danger: an action that cannot be undone';

  @override
  String get cvCriticalWhat => 'What happens if you allow it';

  @override
  String cvToolReqTitle(String name, String tool) {
    return '$name asks to switch on «$tool»';
  }

  @override
  String cvToolReqWhy(String why) {
    return 'Why: $why';
  }

  @override
  String cvToolReqHint(String name) {
    return 'Without your yes it stays off. «Always» changes $name\'s tools (you can undo it in the history).';
  }

  @override
  String get cvToolReqSession => 'Switch on for this conversation';

  @override
  String cvToolReqAlways(String name) {
    return 'Always for $name';
  }

  @override
  String get cvToolReqNo => 'No';

  @override
  String get cvAgTitle => 'An artifact asks for a permission';

  @override
  String get cvAgCap => 'Spending cap for this artifact:';

  @override
  String get cvAgCapHint =>
      'Its questions stop when the cap is reached; you can change it in Settings › Artifacts.';

  @override
  String get cvAgHint =>
      'It lasts until you take it back in Settings › Artifacts. A new version of the artifact keeps it; an imported copy starts with nothing.';

  @override
  String cvAgAllowCap(String cap) {
    return 'Allow, up to $cap';
  }

  @override
  String get cvAgAllow => 'Allow';

  @override
  String get cvAgDeny => 'No';

  @override
  String get cvManyAnswers => 'one or more';

  @override
  String get cvOtherAnswer => 'Other: write your answer';

  @override
  String get cvProposedPlan => 'Proposed plan';

  @override
  String get cvWaitingAnswer => 'waiting for an answer';

  @override
  String get cvNotAnswered => 'not answered';

  @override
  String get cvPlanFeedback => 'What should change? (optional)';

  @override
  String get cvPlanApprove => 'Approve and carry on';

  @override
  String get cvPlanRevise => 'Keep planning';

  @override
  String get cvSendFeedback => 'Send the feedback';

  @override
  String get cvAnswer => 'Answer';

  @override
  String cvTodosTitle(String done, String all) {
    return 'Steps: $done of $all done';
  }

  @override
  String get cvEditMessage => 'Edit';

  @override
  String get cvEditForks =>
      'The edited message starts a copy of this conversation from here; this one stays as it is.';

  @override
  String get cvEditSend => 'Send';

  @override
  String get cvCancel => 'Cancel';

  @override
  String get cvForkHere => 'Continue from here';

  @override
  String get cvForkHereHint =>
      'A new conversation with everything up to this message; this one stays as it is';

  @override
  String get cvForkStartsHere => 'The new conversation goes on from here.';

  @override
  String get cvForkEdited => 'The edited message goes on from here.';

  @override
  String cvForkBack(String title) {
    return 'Back to «$title»';
  }

  @override
  String get cvForkOrigin => 'the original conversation';

  @override
  String get cvCompactionAuto =>
      'The conversation was summarised here (the earlier part, made ahead of time)';

  @override
  String get cvCompactionManual => 'The conversation was summarised here, as you asked';

  @override
  String get cvCompactionEmergency => 'The conversation was summarised here: the window was full';

  @override
  String get cvCompactionEngine =>
      'The subscription\'s engine summarised its conversation here (by itself)';

  @override
  String get cvCompactionUndone => 'Summary undone: the whole conversation is back';

  @override
  String get cvUndo => 'Undo';

  @override
  String get cvStepLimitContinue => 'Continue';

  @override
  String get cvStepLimitContinueHint =>
      'The agent reached the limit of steps: let it go on from where it stopped';

  @override
  String get cvStepLimitGoOn => 'Go on';

  @override
  String cvCacheMissed(String cached, String expected) {
    return 'This answer read only $cached tokens from the cache instead of about $expected: something changed the beginning of the conversation, so it was computed again (slower and, online, more expensive).';
  }

  @override
  String get cvToolNoResult =>
      'No result: the call ended without one (the turn was cancelled or stopped).';

  @override
  String cvToolOnMachine(String name) {
    return 'on $name';
  }

  @override
  String cvToolOnNode(String name) {
    return 'on the node $name';
  }

  @override
  String get cvViaScript => 'from a script';

  @override
  String get cvToolSeen => 'What the agent saw';

  @override
  String cvOpenSubagentChat(String name) {
    return 'Open the conversation of $name';
  }

  @override
  String get cvKindSubagent => 'Helper';

  @override
  String cvElsewhereAsks(String name, String title) {
    return '$name is asking you something in another conversation: «$title»';
  }

  @override
  String cvElsewhereWorking(String name, String title) {
    return '$name is working in another conversation: «$title»';
  }

  @override
  String get cvElsewhereUntitled => 'untitled';

  @override
  String get cvElsewhereAnswerHere => 'Answer here';

  @override
  String get cvOpen => 'open';

  @override
  String get cvUnqueue => 'Take it back (if the agent has not read it yet)';

  @override
  String get cvSentWhileWorking => 'Sent while the agent works: it reads it as soon as it can';

  @override
  String cvWriteWhileWorking(String name) {
    return '$name is working: write anyway, it reads it right after…';
  }

  @override
  String cvWriteTo(String name) {
    return 'Write to $name…';
  }

  @override
  String get cvStopWhenBack => 'The connection is lost: «Stop» goes as soon as it is back.';

  @override
  String get cvSendQueued => 'Send: it is read as soon as the current work allows';

  @override
  String get cvInterrupt => 'Stop';

  @override
  String get cvPaBadge => 'Archived · read only';

  @override
  String cvPaChatReadOnly(String name) {
    return 'The project «$name» is archived: this conversation is read only.';
  }

  @override
  String get cvPaRestore => 'Restore';

  @override
  String cvImpChatNotice(String source, String date) {
    return 'Conversation brought in from $source$date. You can go on with it here.';
  }

  @override
  String get cvViaVoice => 'said by voice';

  @override
  String get cvViaVoiceHint => 'Said hands-free; the agent was asked for an answer to read aloud';

  @override
  String get cvViaArtifact => 'from a widget';

  @override
  String get cvViaArtifactHint => 'Sent by a button you clicked in an artifact or a widget';

  @override
  String cvCanvasOpened(String name) {
    return 'Opened $name in the canvas';
  }

  @override
  String get cvCanvasShown => 'In the canvas: press to open it again';

  @override
  String get cvBoardOpen => 'Open the board';

  @override
  String cvBoardWaiting(String n) {
    return 'A board with $n variants: open it to choose or comment';
  }

  @override
  String cvBoardDone(String n) {
    return 'Board: you chose variant $n';
  }

  @override
  String get cvFileSave => 'Save';

  @override
  String get cvCanvasOpen => 'Open it in the canvas';

  @override
  String get cvChSecretTitle => 'This message holds a secret';

  @override
  String get cvChSecretText =>
      'It looks like a key, a password or a card number. Secrets never go in a chat: the model and the log would keep it. Put it in the keychain instead, and agents will use it by name without seeing it.';

  @override
  String cvChSecretFound(String list) {
    return 'Found: $list';
  }

  @override
  String get cvChSecretKindKey => 'a key';

  @override
  String get cvChSecretKindPassword => 'a password';

  @override
  String get cvChSecretKindCode => 'a PIN or code';

  @override
  String get cvChSecretKindCard => 'a card number';

  @override
  String get cvChSecretKindIban => 'an IBAN';

  @override
  String get cvChSecretBack => 'Back to writing';

  @override
  String get cvChSecretSend => 'Send without it';

  @override
  String get cvChSecretVault => 'Put it in the keychain';

  @override
  String get cvAttachmentOpen => 'Open in the canvas';

  @override
  String get cvToBottom => 'Go to the bottom';

  @override
  String get cvThinking => 'Reasoning';

  @override
  String get cvSeeAttachments => '(see the attachments)';

  @override
  String get cvPastedOpen => 'See the whole pasted text';

  @override
  String get cvPastedAsText => 'Paste as text';

  @override
  String get cvRemove => 'Remove';

  @override
  String get cvClose => 'Close';

  @override
  String get cvCopied => 'Copied';

  @override
  String cvStartConversation(String name) {
    return 'Write to $name to start.';
  }

  @override
  String cvSubAsks(String name) {
    return 'The sub-agent «$name» asks for your permission.';
  }

  @override
  String cvPastedSize(String lines, String chars) {
    return '$lines lines · $chars characters';
  }

  @override
  String get cvCopy => 'Copy';

  @override
  String get mailCardNone => 'No message found';

  @override
  String mailCardMore(int n) {
    return '$n more';
  }

  @override
  String mailCardAttachments(int n) {
    return '$n attachments';
  }

  @override
  String get mailCardAttachment => '1 attachment';

  @override
  String get mailCardSaved => 'saved';

  @override
  String get mailCardShowAll => 'Show all';

  @override
  String get mailCardShowLess => 'Show less';

  @override
  String mailCardFolder(String mailbox, String folder) {
    return '$mailbox, $folder';
  }

  @override
  String get mailCardDraft => 'Draft';

  @override
  String get mailCardTo => 'To';

  @override
  String get mailCardSubject => 'Subject';

  @override
  String get mailCardUnread => 'unread';

  @override
  String get mailCardPermTitle => 'The email, as it would leave';

  @override
  String get mailCardDraftSaved => 'Draft saved';

  @override
  String get mailCardDraftChanged => 'Draft changed';

  @override
  String mailCardSentFrom(String mailbox) {
    return 'Sent from $mailbox';
  }

  @override
  String get mailCardNobody => 'nobody yet';

  @override
  String get cvAcpKindRead => 'read';

  @override
  String get cvAcpKindEdit => 'edit';

  @override
  String get cvAcpKindDelete => 'delete';

  @override
  String get cvAcpKindMove => 'move';

  @override
  String get cvAcpKindSearch => 'search';

  @override
  String get cvAcpKindExecute => 'command';

  @override
  String get cvAcpKindThink => 'think';

  @override
  String get cvAcpKindFetch => 'fetch';

  @override
  String get cvAcpKindSwitchMode => 'mode';

  @override
  String get cvAcpKindOther => 'action';

  @override
  String get cvFindViaEverything => 'Everything\'s index';

  @override
  String get cvFindViaSpotlight => 'Spotlight\'s index';

  @override
  String get cvFindViaLocate => 'the locate database';

  @override
  String get cvFindViaWalk => 'searched the folders';

  @override
  String get cvFindViaPath => 'programs on the PATH';

  @override
  String get cvFindViaContainer => 'searched in the container';

  @override
  String cvFindTook(String via, String seconds) {
    return '$via, $seconds s';
  }

  @override
  String cvFindTookCut(String via, String seconds, String limit) {
    return '$via, $seconds s (stopped at $limit s)';
  }

  @override
  String cvFindTookInterrupted(String via, String seconds) {
    return '$via, $seconds s (interrupted)';
  }

  @override
  String cvTooMany(String n) {
    return '$n attachments at most';
  }

  @override
  String get widgetTitle => 'Widget';

  @override
  String get widgetPreparing => 'Preparing a widget…';

  @override
  String get widgetOpenCanvas => 'Open in the Canvas';

  @override
  String get widgetKeep => 'Keep it';

  @override
  String get widgetKeepHint => 'Saved as an artifact in artefatti/, and opened in the Canvas';

  @override
  String get widgetKeptShort => 'Kept';

  @override
  String widgetKept(String path) {
    return 'Kept as $path';
  }

  @override
  String get widgetAsks => 'It wants to send to the chat:';

  @override
  String get widgetNoChat => 'It wants to send to the chat (open a conversation first):';

  @override
  String get widgetSend => 'Send';

  @override
  String get widgetDismiss => 'Leave it';

  @override
  String get widgetLoading => 'Loading…';

  @override
  String get widgetOpenInPage => 'Open in the page';

  @override
  String get widgetNoFrameHere =>
      'This system cannot run widgets and artifacts inside the app: open it in the page, in your browser.';

  @override
  String get artError1 => '1 error';

  @override
  String artErrors(int n) {
    return '$n errors';
  }

  @override
  String get previewLinkTitle => 'The page wants to open a link';

  @override
  String get previewLinkOpen => 'Open';

  @override
  String get embedCopied => 'Copied';

  @override
  String get embedShareCopied => 'Copied: paste it where you want to share it';

  @override
  String embedSaved(String name) {
    return 'Saved: $name';
  }

  @override
  String get embedOpenInBrowser => 'Open in the browser';

  @override
  String get embedProbeTitle => 'Web view test';

  @override
  String get embedSaving => 'Saving…';

  @override
  String get embedSavedState => 'Saved';

  @override
  String get embedProbeOpen => 'Web view test';

  @override
  String get requestAnswerAllowed => 'allowed';

  @override
  String get requestAnswerDenied => 'denied';

  @override
  String requestDoneHere(String answer) {
    return 'You already answered from the page or another window: $answer.';
  }

  @override
  String requestDoneChat(String chat, String answer) {
    return 'You already answered from $chat: $answer.';
  }

  @override
  String requestDoneTimeout(String answer) {
    return 'Nobody answered in time: $answer.';
  }

  @override
  String requestDoneElsewhere(String answer) {
    return 'Already decided elsewhere: $answer.';
  }

  @override
  String get requestDoneClosing => 'This screen closes by itself in a few seconds.';

  @override
  String get requestCloseHint => 'Close (Esc)';

  @override
  String get requestTechDetails => 'Technical details';

  @override
  String get cmOpen => 'Open';

  @override
  String get cmPin => 'Pin';

  @override
  String get cmUnpin => 'Unpin';

  @override
  String get cmFolder => 'Move to a folder';

  @override
  String get cmFolderNew => 'New folder…';

  @override
  String get cmFolderNewTitle => 'New folder';

  @override
  String get cmFolderNewYes => 'Move';

  @override
  String get cmFolderOut => 'Take it out of the folder';

  @override
  String get cmArchive => 'Archive';

  @override
  String get cmUnarchive => 'Bring back';

  @override
  String get cmExport => 'Export as Markdown';

  @override
  String get cmArchived => 'Conversation archived.';

  @override
  String get cmUnarchived => 'Conversation brought back.';

  @override
  String get cmFailed => 'It did not work: try again.';

  @override
  String get cmExported => 'File saved.';

  @override
  String cmForkOf(String title) {
    return 'branch of «$title»';
  }

  @override
  String cmArchivedN(int n) {
    return 'Archived ($n)';
  }

  @override
  String get cmBack => 'Back to the conversations';

  @override
  String get cmNew => 'New conversation';

  @override
  String get cmEmpty => 'No conversations yet: start one.';

  @override
  String get cmEmptyArchived => 'No archived conversations.';

  @override
  String get cmPinned => 'Pinned';

  @override
  String cmConversationsOf(String name) {
    return 'Conversations with $name';
  }

  @override
  String cmTask(String title) {
    return 'Task: $title';
  }

  @override
  String get cmShared => 'Shared conversation';

  @override
  String get pmOpen => 'Open';

  @override
  String get pmTasks => 'Tasks and files';

  @override
  String get pmCode => 'Code';

  @override
  String pmAgents(String project) {
    return 'Agents of $project';
  }

  @override
  String get pmArchive => 'Archive the project';

  @override
  String get pmRestore => 'Restore';

  @override
  String get pmInitGit => 'Initialise git';

  @override
  String pmInitGitDone(String name) {
    return 'Git repository created for «$name» (branch main).';
  }

  @override
  String pmAskTitle(String name) {
    return 'Archive «$name»?';
  }

  @override
  String get pmAskLead =>
      'The project leaves the lists and stays readable under «Archived». Nothing is deleted: restore it whenever you like and it comes back as it was.';

  @override
  String pmWorking(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n agents are working: they will be stopped',
      one: '1 agent is working: it will be stopped',
    );
    return '$_temp0';
  }

  @override
  String get pmNobody => 'No agent is working in it now.';

  @override
  String pmAutos(int n, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n automations will be paused ($names); they run again when you restore the project.',
      one: '1 automation will be paused ($names); it runs again when you restore the project.',
    );
    return '$_temp0';
  }

  @override
  String get pmFactTasks => 'Open tasks stay open.';

  @override
  String get pmFactSandbox => 'Its sandbox stops, and starts again on restore.';

  @override
  String get pmFactNobody =>
      'Until then no agent works in it or changes its files, and your linked chats do not use it.';

  @override
  String get pmFactRestore => 'God can archive and restore it too, always with your yes.';

  @override
  String get pmStopAndArchive => 'Stop and archive';

  @override
  String get pmArchiveYes => 'Archive';

  @override
  String pmArchived(String name) {
    return '«$name» archived.';
  }

  @override
  String pmRestored(String name) {
    return '«$name» restored.';
  }

  @override
  String pmArchivedN(int n) {
    return 'Archived ($n)';
  }

  @override
  String pmArchivedOn(String day) {
    return 'archived on $day';
  }

  @override
  String get pmBadge => 'Archived · read only';

  @override
  String get pmViewLead =>
      'Archived: you can read its conversations, tasks and files. Restore it to work in it again.';

  @override
  String get pmConversations => 'Conversations';

  @override
  String get pmTeam => 'The team\'s conversations';

  @override
  String get pmNoConversations => 'No conversations.';

  @override
  String get pmTasksTitle => 'Tasks';

  @override
  String get pmNoTasks => 'No tasks.';

  @override
  String get pmNoLead => 'This project has no lead agent.';

  @override
  String get pmNoGit => 'No git repository';

  @override
  String get bellTitle => 'Waiting for you';

  @override
  String get bellTooltip => 'Requests and notifications';

  @override
  String bellPermissions(int n) {
    return 'Permissions ($n)';
  }

  @override
  String bellQuestions(int n) {
    return 'Questions ($n)';
  }

  @override
  String bellWorking(int n) {
    return 'Working now ($n)';
  }

  @override
  String get bellNoApprovals => 'Nothing waiting for you.';

  @override
  String get bellNoQuestions => 'No questions.';

  @override
  String get bellNothingRunning => 'Nothing is running.';

  @override
  String get bellAllow => 'Allow';

  @override
  String get bellDeny => 'Deny';

  @override
  String get bellLook => 'Look and decide';

  @override
  String get bellAnswer => 'Answer';

  @override
  String get bellSeeAll => 'See all';

  @override
  String pmConversationsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversations',
      one: '1 conversation',
      zero: 'no conversations',
    );
    return '$_temp0';
  }

  @override
  String get raMenu => 'Remove…';

  @override
  String raTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String raBody(String name) {
    return '$name leaves the team: its turns stop and nobody gives it work any more. Nothing is deleted: its conversations and its history stay, readable in «Removed agents», where you can restore it.';
  }

  @override
  String raWith(String names) {
    return 'Removed with it: $names';
  }

  @override
  String raKept(int commits, int files) {
    return 'Work not merged: $commits commit(s), $files changed file(s)';
  }

  @override
  String get raKeptError => 'Work kept as it is: it could not be checked';

  @override
  String raKeptHow(String branch) {
    return 'It stays on the branch $branch: restore the agent to pick it up.';
  }

  @override
  String raTasks(int count) {
    return 'Open tasks that close («agent removed»): $count';
  }

  @override
  String raRunning(int count) {
    return 'Conversations at work that stop now: $count';
  }

  @override
  String raYes(String name) {
    return 'Remove $name';
  }

  @override
  String raDone(String name) {
    return '$name removed: «Removed agents» brings it back.';
  }

  @override
  String raFailed(String why) {
    return 'Not removed: $why';
  }

  @override
  String raProtected(String name) {
    return '$name cannot be removed.';
  }

  @override
  String get raHelp =>
      'It leaves the team with the agents below it; its history stays and you can restore it from «Removed agents».';

  @override
  String get raListTitle => 'Removed agents';

  @override
  String get raListRow => 'Read their conversations, bring them back';

  @override
  String get raListHelp =>
      'Agents removed from the team, by you or by God. Nothing was deleted: their conversations stay readable, and «Restore» brings each back with those removed with it.';

  @override
  String get raNone => 'No removed agents.';

  @override
  String raWhen(String when, String by) {
    return 'Removed $when by $by';
  }

  @override
  String get raByYou => 'you';

  @override
  String raReason(String reason) {
    return 'Why: $reason';
  }

  @override
  String get raRestore => 'Restore';

  @override
  String raRestored(String name) {
    return '$name is back in the team.';
  }

  @override
  String raRestoreFailed(String why) {
    return 'Not restored: $why';
  }

  @override
  String raConversations(int count) {
    return 'Conversations ($count)';
  }

  @override
  String get raNoConversations => 'No conversations.';

  @override
  String raReadOnly(String name) {
    return '$name was removed: this conversation is read only.';
  }

  @override
  String get raBadge => 'Removed';

  @override
  String get paMenu => 'Stop…';

  @override
  String paTitle(String name) {
    return 'Stop $name?';
  }

  @override
  String paYes(String name) {
    return 'Stop $name';
  }

  @override
  String paDone(String name) {
    return '$name is paused: «Resume» brings it back.';
  }

  @override
  String get paResume => 'Resume';

  @override
  String paResumeHelp(String name) {
    return '$name is stopped (paused). «Resume» brings it back with those stopped under it, and its open tasks go on in the same conversation.';
  }

  @override
  String paResumed(String name) {
    return '$name works again.';
  }

  @override
  String paResumedTasks(String name) {
    return '$name works again: its open tasks go on.';
  }

  @override
  String paResumeFailed(String why) {
    return 'Not resumed: $why';
  }

  @override
  String paReadOnly(String name) {
    return '$name is stopped (paused): resume it to write to it.';
  }

  @override
  String get paBadge => 'Paused';

  @override
  String get atWorkTitle => 'Agents at work together';

  @override
  String get atWorkAtMost => 'Agents at work together, at most';

  @override
  String get atWorkHelp =>
      'How many agents can work at the same moment. The others wait in the queue and start by themselves, in order, as soon as a place is free. Your own messages never wait; a sub-agent takes the place of the one waiting for it. Lowering it stops nobody: it holds for the turns that come next.';

  @override
  String get atWorkNoLimit => 'No limit';

  @override
  String atWorkSummary(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'At most $n agents at a time',
      one: 'At most 1 agent at a time',
    );
    return '$_temp0';
  }

  @override
  String get atWorkNoLimitHint => 'Every agent with work starts at once.';

  @override
  String get atWorkSaved => 'Saved: it holds for the turns that start from now.';

  @override
  String get atWorkNow => 'Now';

  @override
  String atWorkPlaces(int working, int limit) {
    return '$working of $limit places taken';
  }

  @override
  String atWorkPlacesNoLimit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n at work, no limit',
      one: '1 at work, no limit',
      zero: 'Nobody at work',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'Agents\' queue';

  @override
  String get queueEmpty => 'Nobody is waiting: every agent with work is working.';

  @override
  String queuedNth(String nth, int of) {
    return 'queued ($nth of $of)';
  }

  @override
  String queuedBanner(String nth, int of) {
    return 'Queued ($nth of $of): waiting for a free place';
  }

  @override
  String get queueWaitingDoing => 'Waiting for a free place';

  @override
  String get queueMoveFirst => 'Move ahead';

  @override
  String get queueSee => 'See the queue';

  @override
  String get queueNext => 'Next';

  @override
  String get queueStop => 'Stop';

  @override
  String queueWaited(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'waiting for $n min',
      one: 'waiting for 1 min',
      zero: 'waiting since just now',
    );
    return '$_temp0';
  }

  @override
  String get queueChild => 'asked by an agent waiting for it';

  @override
  String get queueMoved => 'moved ahead by you';

  @override
  String get queueMoveFailed => 'It no longer waits: it may have just started.';

  @override
  String statusAtWork(int working, int limit) {
    return 'At work $working/$limit';
  }

  @override
  String statusAtWorkNoLimit(int n) {
    return 'At work $n';
  }

  @override
  String statusQueued(int n) {
    return 'queued $n';
  }

  @override
  String get queueOpenSettings => 'Change the limit';

  @override
  String get fxOpenFiles => 'Project files';

  @override
  String get fxSubtitle => 'Files and folders';

  @override
  String get fxPlatform => 'Platform';

  @override
  String get fxAssistants => 'Personal agents';

  @override
  String get fxNewFile => 'New file';

  @override
  String get fxNewFolder => 'New folder';

  @override
  String get fxMake => 'Make';

  @override
  String get fxPathHint => 'Name, with its folder if you want one (docs/note.md)';

  @override
  String get fxUpload => 'Upload';

  @override
  String fxUploaded(int count) {
    return 'Files uploaded: $count.';
  }

  @override
  String get fxShowHidden => 'Show hidden files';

  @override
  String get fxHideHidden => 'Hide hidden files';

  @override
  String get fxRefresh => 'Refresh';

  @override
  String get fxTerminal => 'Terminal';

  @override
  String get fxFull => 'Full window';

  @override
  String get fxFullOff => 'Beside the conversation';

  @override
  String get fxClose => 'Close the files';

  @override
  String get fxSearchHint => 'Search the files';

  @override
  String get fxClearSearch => 'Clear the search';

  @override
  String get fxFolder => 'Folder';

  @override
  String get fxReadOnly => 'Read only: the project is archived';

  @override
  String get fxEmpty => 'Empty folder.';

  @override
  String get fxDropHere => 'Drop the files to upload them here';

  @override
  String fxExists(String name) {
    return '$name already exists here.';
  }

  @override
  String get fxKeepBoth => 'Keep both';

  @override
  String get fxReplace => 'Replace';

  @override
  String get fxOpen => 'Open in the Canvas';

  @override
  String get fxAsk => 'Ask the agent';

  @override
  String get fxRename => 'Rename';

  @override
  String get fxDownload => 'Download';

  @override
  String fxDownloaded(String name) {
    return '$name saved.';
  }

  @override
  String get fxDelete => 'Delete';

  @override
  String fxConfirmDelete(String path) {
    return 'Move $path to the trash (.trash)?';
  }

  @override
  String fxConfirmDeleteForGood(String path) {
    return 'Delete $path for good?';
  }

  @override
  String get fxMore => 'More actions';

  @override
  String get fxResize => 'Resize the files panel';

  @override
  String fxAttachFailed(String name) {
    return '$name could not be attached.';
  }

  @override
  String get cvBoardChoose => 'I choose this';

  @override
  String get cvBoardChosen => 'Chosen';

  @override
  String get cvBoardChoiceWord => 'chosen';

  @override
  String get cvBoardCommentWord => 'comment';

  @override
  String get cvBoardWriteComment => 'Write a comment';

  @override
  String get cvBoardSending => 'Sending…';

  @override
  String get cvBoardSent => 'Sent to the agent';

  @override
  String get cvBoardOneVariant => '1 variant';

  @override
  String cvBoardVariants(String n) {
    return '$n variants';
  }

  @override
  String get cvBoardScreens => 'Width of the previews';

  @override
  String get cvBoardScreenComputer => 'Computer';

  @override
  String get cvBoardScreenTablet => 'Tablet';

  @override
  String get cvBoardScreenPhone => 'Phone';

  @override
  String get cvBoardFull => 'Full screen';

  @override
  String get cvBoardCommentHere => 'A comment on this variant (optional with «I choose this»)';

  @override
  String get cvBoardSendComment => 'Send comment';

  @override
  String get cvBoardWhole => 'A comment on the whole board';

  @override
  String get cvBoardWholeHint => 'For example: I like the colour of 2 with the layout of 3';

  @override
  String get cvBoardSendToAgent => 'Send to the agent';

  @override
  String get cvBoardTab => 'Board';

  @override
  String get cvBoardNotFound => 'This board is no longer here';

  @override
  String get cvCanvasReload => 'Reload';

  @override
  String cvEmbedPort(String port) {
    return 'Port $port';
  }

  @override
  String cvDrawing(String percent) {
    return 'Drawing… $percent%';
  }

  @override
  String get cvArSection => 'Artifacts';

  @override
  String get cvArLead =>
      'The small apps in a single file your agents make for you. They open in the Canvas, next to the chat.';

  @override
  String get cvArImport => 'Import';

  @override
  String get cvArEmptyTitle => 'No artifacts yet';

  @override
  String get cvArEmpty1 =>
      'An artifact is an HTML app in a single file that an agent makes in one turn: a calculator, a tournament board, a game, a viewer for a CSV. It runs in the Canvas, in an isolated frame, without installing anything and without going online.';

  @override
  String get cvArEmpty2 =>
      'It lives as a file in the artefatti/ folder of a project (or of God and the assistants), so you also find it among the files on the right. To get one, ask an agent for a tool you want to keep and use again; or import a .rgartifact from another Rasgeth.';

  @override
  String get cvArPlacePlatform => 'God\'s folder';

  @override
  String get cvArPlaceAssistants => 'The assistants\' desk';

  @override
  String get cvArOpen => 'Open';

  @override
  String get cvArExport => 'Export';

  @override
  String get cvArDelete => 'Delete';

  @override
  String cvArVersion(String n) {
    return 'version $n';
  }

  @override
  String get cvArNoHeader => 'no header';

  @override
  String cvArLibs(String libs) {
    return 'libraries: $libs';
  }

  @override
  String cvArFrom(String who) {
    return 'by $who';
  }

  @override
  String get cvArPending => 'Imported · not run yet';

  @override
  String get cvArReadOnly => 'read only: the project is archived';

  @override
  String cvArDeleteQ(String name) {
    return 'Delete «$name»?';
  }

  @override
  String get cvArDeleteText =>
      'The file goes to the trash of its folder, as from the file explorer.';

  @override
  String cvArExportTitle(String name) {
    return 'Export «$name»';
  }

  @override
  String get cvArExportZip => 'A .rgartifact file';

  @override
  String get cvArExportZipText =>
      'To import it into another Rasgeth: the app, its manifest and the fingerprint that checks it arrived intact. It carries no permissions.';

  @override
  String get cvArExportHtml => 'Download as HTML';

  @override
  String get cvArExportHtmlText =>
      'To open it elsewhere. Careful: outside Rasgeth it runs without the isolated frame, with the rights of the page you open it in.';

  @override
  String get cvArWhereQ => 'Where should it go?';

  @override
  String get cvArWhereLead =>
      'It goes into the artefatti/ folder of the place you choose. It starts with no permissions, and the first time it opens on its source with «Run».';

  @override
  String cvArImported(String name, String place) {
    return '«$name» imported into $place: the first time it opens on its source, with «Run».';
  }

  @override
  String get cvArDataIgnored => 'The saved data it carries was not imported.';

  @override
  String get cvArDataImported => 'Its saved data came along too.';

  @override
  String get cvArHasData => 'keeps saved data';

  @override
  String get cvArExportData => 'Include its saved data';

  @override
  String get cvArExportDataHint =>
      'What the app kept on Rasgeth (storage). Leave it off for a clean copy without your data.';

  @override
  String get cvArPerms => 'Permissions';

  @override
  String cvArWants(String what) {
    return 'It asks to $what';
  }

  @override
  String get cvArPermGranted => 'granted';

  @override
  String get cvArPermNot => 'not granted';

  @override
  String get cvArGrant => 'Allow';

  @override
  String get cvArRevoke => 'Take back';

  @override
  String cvArSpent(String spent, String cap) {
    return '$spent spent of $cap';
  }

  @override
  String get sectionArtifacts => 'ARTIFACTS';

  @override
  String get artifactsRowHint =>
      'The apps the agents made: open, export, import, delete and their permissions';

  @override
  String get cvVwToChat => 'Chat';

  @override
  String get sideTabFiles => 'Files';

  @override
  String get sideTabCanvas => 'Nebula';

  @override
  String get sideTabsLabel => 'What the right column shows';

  @override
  String get chatFileDownload => 'Download';

  @override
  String get chatAttachmentDownload => 'Download the attachment';

  @override
  String chatFileDownloading(String name) {
    return 'Downloading $name';
  }

  @override
  String chatFileDownloadOf(String done, String total, String speed, String left) {
    return '$done of $total · $speed/s · $left left';
  }

  @override
  String chatFileDownloadSoFar(String done, String speed) {
    return '$done · $speed/s';
  }

  @override
  String chatFileSaved(String name) {
    return 'Saved: $name';
  }

  @override
  String chatFileDownloadFailed(String name) {
    return 'Could not download $name';
  }

  @override
  String get cvSubMain => 'Main agent';

  @override
  String get cvSubPath => 'Where you are';

  @override
  String get cvSubRow => 'Sub-agents';

  @override
  String get cvSubOpenTab => 'Open its tab';

  @override
  String get cvSubStatusRunning => 'Working';

  @override
  String get cvSubStatusDone => 'Finished';

  @override
  String get cvSubStatusFailed => 'Failed';

  @override
  String get cvSubStatusStopped => 'Stopped';

  @override
  String get cvSubFresh => 'Something new';

  @override
  String get cvSubWaits => 'Waits for your yes';

  @override
  String get cvSubClose => 'Close the tab';

  @override
  String get cvSubTask => 'Task received';

  @override
  String cvSubTaskFrom(String name) {
    return 'Task from «$name»';
  }

  @override
  String get cvSubEndedDone => 'It finished: its report went back to the agent that started it.';

  @override
  String get cvSubEndedFailed => 'It did not finish its task.';

  @override
  String get cvSubEndedStopped => 'It was stopped.';

  @override
  String get cvSubInterrupted => 'Interrupted: the server stopped while it worked.';

  @override
  String cvSubTime(String time) {
    return '$time';
  }

  @override
  String cvSubTools(String n) {
    return '$n tools';
  }

  @override
  String cvSubTokens(String n) {
    return '$n tokens';
  }

  @override
  String get cvSubNoWrite => 'It takes orders only from the agent that started it';

  @override
  String get cvSubStop => 'Stop';

  @override
  String get cvCmdStrip => 'Background commands';

  @override
  String cvCmdRunningN(String n) {
    return '$n running';
  }

  @override
  String cvCmdDoneN(String n) {
    return '$n finished';
  }

  @override
  String get cvCmdOpenStrip => 'Show the background commands';

  @override
  String get cvCmdShrinkStrip => 'Reduce to one line';

  @override
  String cvCmdStartedAt(String at) {
    return 'Started at $at';
  }

  @override
  String get cvCmdOutput => 'Output';

  @override
  String get cvCmdStop => 'Stop';

  @override
  String cvCmdFinishedN(String n) {
    return '$n finished commands';
  }

  @override
  String get cvCmdRemoveFinished => 'Remove all finished';

  @override
  String get cvCmdRemove => 'Remove';

  @override
  String get cvCmdStatusRunning => 'running';

  @override
  String cvCmdStatusDone(String code) {
    return 'exit code $code';
  }

  @override
  String cvCmdStatusFailed(String code) {
    return 'failed, exit code $code';
  }

  @override
  String get cvCmdStatusStopped => 'stopped';

  @override
  String get cvCmdStatusInterrupted => 'interrupted (Rasgeth had stopped)';

  @override
  String get cvCmdOutputTitle => 'Background command';

  @override
  String get cvCmdStarted => 'Started';

  @override
  String get cvCmdEnded => 'Ended';

  @override
  String get cvCmdFolder => 'Folder';

  @override
  String get cvCmdBy => 'Started by';

  @override
  String get cvCmdShowTimes => 'Times of every line';

  @override
  String cvCmdLines(String n) {
    return '$n lines';
  }

  @override
  String get cvCmdNoLog => 'Its log is not there any more.';

  @override
  String get cvRoomAdd => 'Add an agent';

  @override
  String cvRoomAnswering(String names) {
    return '$names is answering…';
  }

  @override
  String get cvRoomEmpty =>
      'Write to everyone: the first one answers, or call someone with @name. Adding an agent gives it no new access: what the others write reaches it as information.';

  @override
  String get cvRoomFirst => 'answers first';

  @override
  String get cvRoomGone => 'This group chat no longer exists.';

  @override
  String get cvRoomGroupPersonal => 'Yours';

  @override
  String cvRoomInspector(String project) {
    return 'Inspector of $project';
  }

  @override
  String cvRoomLead(String project) {
    return 'Lead of $project';
  }

  @override
  String get cvRoomPick => 'Who?';

  @override
  String cvRoomRemove(String name) {
    return 'Remove $name from the chat';
  }

  @override
  String get cvRoomUsageHint => 'What its answers here cost, and how full its context is';

  @override
  String get cvRoomWrite => 'Write to the group (@ to call someone)';

  @override
  String cvRoomJoined(String name) {
    return '$name joined the chat';
  }

  @override
  String cvRoomLeft(String name) {
    return '$name left the chat';
  }

  @override
  String get cvGroups => 'Groups';

  @override
  String get cvGroupsEmpty => 'Several agents in one chat: «Add an agent» in any conversation.';

  @override
  String get cvGroupNew => 'New group';

  @override
  String cvChatsArchived(String n) {
    return 'Archived ($n)';
  }

  @override
  String get cvChatsBefore => 'Earlier chats';

  @override
  String get cvArchive => 'Archive';

  @override
  String get cvUnarchive => 'Bring back';

  @override
  String get cvChatHint =>
      'Ask anything: the Chat searches the web and cites its sources, makes files, pages and pictures and shows them to you, and proposes variants to choose from.';

  @override
  String get cvNewChat => 'New chat';

  @override
  String get cvDailyChat => 'Chat';

  @override
  String get cvDelete => 'Delete';

  @override
  String get cvDeleteChatConfirm => 'Delete this chat for good?';

  @override
  String get cvChatToGroup => 'Go on as a group: add an agent, which gets this chat as context';

  @override
  String get cvAgentModelDefault => 'The default model';

  @override
  String get cvInspector => 'Inspector';

  @override
  String get cvInspectorHint =>
      'Ask the inspector about this project: it reads files, git, the activity log, tasks, the board and the budget, and changes nothing.';

  @override
  String get cvInspectorAlerts =>
      'Tell me on Telegram when something goes wrong (abandoned task, budget exceeded, blocker, failed automation)';

  @override
  String get cvInspectorSummary => 'Daily summary at';

  @override
  String get cvFolderMove => 'Move to a folder';

  @override
  String get cvFolderNew => 'New folder…';

  @override
  String get cvFolderName => 'Folder name';

  @override
  String get cvFolderOut => 'Take it out of the folder';

  @override
  String get cvExportMd => 'Export as Markdown';

  @override
  String get cvBoard => 'Board';

  @override
  String get cvNewThread => 'New thread';

  @override
  String get cvTitle => 'Title';

  @override
  String get cvReply => 'Reply';

  @override
  String get cvSearch => 'Search';

  @override
  String get cvSummary => 'Summary';

  @override
  String get cvResolve => 'Resolve';

  @override
  String get cvBlock => 'Block';

  @override
  String get cvReopen => 'Reopen';

  @override
  String get cvPostKinds => 'task,result,question,decision,blocker,note';

  @override
  String get cvPostKindLabels => 'task,result,question,decision,blocker,note';

  @override
  String get cvStatusOpen => 'open';

  @override
  String get cvStatusResolved => 'resolved';

  @override
  String get cvStatusBlocked => 'blocked';

  @override
  String get cvEmptyBoard => 'No threads yet.';

  @override
  String get cvNoResults => 'No results.';

  @override
  String get cvAgentWholeProject => 'The whole project';

  @override
  String get cvBoardSub => 'Subproject';

  @override
  String get cvYou => 'You';

  @override
  String get cvScreenTitle => 'Agents\' browser';

  @override
  String get cvScreenOpen => 'Screen';

  @override
  String get cvScreenTake => 'Take control';

  @override
  String get cvScreenGiveBack => 'Give it back to the agents';

  @override
  String get cvScreenAddress => 'Web address';

  @override
  String get cvScreenShared =>
      'The browser your personal agents share: sign in once and every one of them can use that site. Take control to sign in: what you type goes to the page only, never to an agent.';

  @override
  String get cvScreenYours =>
      'You have control: the agents wait. Click and type on the screen; give it back when you are done.';

  @override
  String get cvScreenStarting => 'Starting the browser…';

  @override
  String get cvScreenUnavailable => 'The agents\' browser needs Rasgeth\'s Docker installation.';

  @override
  String get cvTeachStart => 'Teach a task';

  @override
  String get cvTeachHint =>
      'Do the task once yourself: every page, click and text is written down (never passwords), then the agent turns it into a skill you approve in Extensions';

  @override
  String get cvTeachWho => 'Which agent learns it';

  @override
  String cvTeachRecording(String name) {
    return 'Recording for $name: do the task, then press Done. Passwords are never written down.';
  }

  @override
  String get cvTeachDone => 'Done';

  @override
  String get cvTeachTitle => 'What is this task called? (optional)';

  @override
  String get cvChatPlaceholder => 'Write a message (Enter to send, Shift+Enter for a new line)';

  @override
  String get cvConversations => 'Conversations';

  @override
  String get cvChatInstructions => 'The Chat\'s instructions';

  @override
  String get termOpenAgain => 'Open again';

  @override
  String get termKeyLeft => 'Left arrow';

  @override
  String get termKeyUp => 'Up arrow';

  @override
  String get termKeyDown => 'Down arrow';

  @override
  String get termKeyRight => 'Right arrow';

  @override
  String get termPaste => 'Paste';

  @override
  String get termShowKeyboard => 'Show the keyboard';

  @override
  String get termHideKeyboard => 'Hide the keyboard';

  @override
  String get spTitle => 'Subprojects';

  @override
  String get spNew => 'New subproject';

  @override
  String spNewTitle(String name) {
    return 'New subproject in «$name»';
  }

  @override
  String get spNoTeam => 'no agents';

  @override
  String spTeam(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get spNoAgents => 'No agents yet: create them from the project\'s agents.';

  @override
  String get spFiles => 'The subproject\'s files';

  @override
  String get spFrom => 'New or existing';

  @override
  String get spNewOne => 'A new subproject';

  @override
  String spBringInName(String name) {
    return 'Bring in the project $name';
  }

  @override
  String get spBringInTitle => 'Bring the project in?';

  @override
  String get spBringIn => 'Bring in';

  @override
  String get spAdoptConfirm =>
      'The project goes into this one as a subproject: its code (with its history) into the folder, its agents under this project\'s lead, its board and conversations too. Its old folder stays as a copy. Go on?';

  @override
  String get spName => 'Subproject name';

  @override
  String get spDir => 'Folder (optional)';

  @override
  String get spDirHelp =>
      'Inside the project, for example apps/shop. Empty: a new folder with the name. An existing folder works too.';

  @override
  String get spImage => 'Its own sandbox image (optional)';

  @override
  String get spImageHelp =>
      'For tools the project\'s sandbox does not have, like ghcr.io/cirruslabs/flutter:stable. The image needs bash.';

  @override
  String get spCreate => 'Create';

  @override
  String get psTitle => 'Projects';

  @override
  String get psRowHint => 'Archive, restore, initialise git';

  @override
  String get psNewProject => 'New';

  @override
  String get psLead =>
      'Archive a project you are not working on: it leaves the lists, nothing is deleted, and it comes back as it was.';

  @override
  String get psInUse => 'In use';

  @override
  String get psNone => 'No projects yet.';

  @override
  String get psArchived => 'Archived';

  @override
  String get psArchivedLead =>
      'Read only. «Restore» puts the project back as it was, with its automations.';

  @override
  String get psNoneArchived => 'No archived projects.';

  @override
  String get csEyebrow => 'Code';

  @override
  String get csTitle => 'Where the code lives';

  @override
  String get csRowHint => 'GitHub, Gitea and the projects\' repositories';

  @override
  String get csQuestion => 'Where does the code live?';

  @override
  String get csPurpose =>
      'Every project gets a private repository, ready for the agents to push to. Choose GitHub, a Gitea of your own on this computer, or both. Optional.';

  @override
  String get csGithubTile =>
      'The repositories stay on your GitHub account. It needs a token allowed to make them.';

  @override
  String get csGiteaTitle => 'A Gitea of your own';

  @override
  String get csGiteaTile =>
      'A small private GitHub on this computer, installed and started by Rasgeth, or the Gitea you already have.';

  @override
  String get csLinked => 'connected';

  @override
  String get csBoth =>
      'With both: the code lives on Gitea, and every change is copied to GitHub by itself.';

  @override
  String get csProjects => 'Projects you already have';

  @override
  String get csProjectsHint =>
      'New projects get their repository by themselves. For the ones made before:';

  @override
  String get csSync => 'Create the repositories now';

  @override
  String get csSynced => 'repository ready';

  @override
  String get csDone => 'Done';

  @override
  String get csDisconnect => 'Disconnect';

  @override
  String get csTryAndSave => 'Try and save';

  @override
  String get csGithubHint =>
      'With a token you make on GitHub: Rasgeth creates the repositories and the agents push to them. The token stays with Rasgeth, never in the agents\' boxes.';

  @override
  String csGithubLinked(String login) {
    return 'Connected as @$login';
  }

  @override
  String get csGithubStep1 => 'Open GitHub\'s page for a new token (sign in if asked):';

  @override
  String get csGithubOpen => 'New token on GitHub';

  @override
  String get csGithubStep2 => 'Fill it in like this:';

  @override
  String get csPermName => 'Token name: Rasgeth';

  @override
  String get csPermExpiry => 'Expiration: one year (Rasgeth reminds you before it ends)';

  @override
  String get csPermRepos => 'Repository access: All repositories';

  @override
  String get csPermList =>
      'Permissions, Repositories: Administration, Contents, Issues and Pull requests set to Read and write';

  @override
  String get csGithubStep3 => 'Press Generate token at the bottom, copy it and paste it here';

  @override
  String get csGithubTokenHelp => 'It starts with github_pat_. GitHub shows it only once.';

  @override
  String get csGiteaHint =>
      'A Git server of your own, on this computer: the repositories stay here, and you look at them in the browser like on GitHub. Rasgeth starts it and keeps it updated. Or connect a Gitea you already have.';

  @override
  String get csGiteaKind => 'Which Gitea';

  @override
  String get csGiteaKindOwn => 'Start one here';

  @override
  String get csGiteaKindExisting => 'A Gitea you already have';

  @override
  String get csGiteaUrl => 'Your Gitea\'s address';

  @override
  String get csGiteaUrlHelp =>
      'As you open it in the browser, for example https://git.example.org.';

  @override
  String get csGiteaExtUser => 'Your user name on it';

  @override
  String get csGiteaToken => 'An access token';

  @override
  String get csGiteaTokenHelp =>
      'On Gitea: Settings › Applications › Generate token, with read and write on repository and user. It stays in the keychain, never in a file.';

  @override
  String get csGiteaConnect => 'Try and connect';

  @override
  String csGiteaLinked(String url, String user) {
    return 'Connected to $url, user $user';
  }

  @override
  String get csGiteaUser => 'Your Gitea user name';

  @override
  String get csGiteaUserHelp => 'Letters, digits, dots, dashes; for example mario.';

  @override
  String get csGiteaPassword => 'A password for Gitea';

  @override
  String get csGiteaPasswordHelp =>
      'At least 10 characters. You use it to open Gitea in the browser.';

  @override
  String get csGiteaAgain => 'The same password again';

  @override
  String get csGiteaMismatch => 'The two passwords are different.';

  @override
  String get csGiteaCreate => 'Create my Gitea';

  @override
  String csGiteaReady(String user) {
    return 'Gitea is ready, user $user';
  }

  @override
  String get csGiteaOpen => 'Open Gitea';

  @override
  String get csGiteaStop => 'Switch off';

  @override
  String csGiteaNameNotFound(String host) {
    return 'Rasgeth cannot find $host: the DNS it uses does not know that name. The guide «Your home services» in Settings › Access from outside home says what to add, and lets you try the name.';
  }

  @override
  String csGiteaHostUnreachable(String host) {
    return 'Rasgeth finds $host, but its address does not answer from here (a Tailscale address, another network?). The guide «Your home services» in Settings › Access from outside home says how to fix it.';
  }

  @override
  String get csJobGitea => 'Starting Gitea';

  @override
  String get csJobGiteaImage => 'Downloading Gitea (only once)';

  @override
  String get csJobGiteaStart => 'Starting Gitea';

  @override
  String get csJobAccount => 'Creating your account';

  @override
  String get csNotNeeded => 'not needed';

  @override
  String get csJobDone => 'Done.';

  @override
  String get csJobFailed =>
      'Something went wrong. Try again; if it happens again, the details below help whoever helps you.';

  @override
  String get g4SfSkillsAsk => 'Show them to me first';

  @override
  String get g4SfSkillsAskText =>
      'A tested skill waits in Settings › Extensions until you approve it.';

  @override
  String get g4SfSkillsAuto => 'Install them once tested';

  @override
  String get g4SfSkillsAutoText =>
      'A skill whose tests pass is ready at once; you can remove it from Extensions.';

  @override
  String get g4SfGuardianTitle => 'The guardian';

  @override
  String get g4SfGuardianAskText =>
      'A file in your home, a system folder, another project: the agent stops and asks you, on the web or on Telegram. Reading is always free.';

  @override
  String get g4SfGuardianAutoText =>
      'Agents write wherever they need without asking. The other dangers you choose below still ask.';

  @override
  String get g4SfCareful => 'Careful';

  @override
  String get g4SfCarefulText =>
      'Every risky action waits for you. The safest choice, also the slowest.';

  @override
  String get g4SfBalanced => 'Balanced';

  @override
  String get g4SfBalancedText =>
      'You approve what cannot be undone (publishing, history, disks, passwords, changes to Rasgeth); the agents in charge approve the rest.';

  @override
  String get g4SfFree => 'Free';

  @override
  String get g4SfFreeText =>
      'The agents in charge approve almost everything; you are asked only for passwords and changes to Rasgeth itself.';

  @override
  String get g4SfPersonalize => 'Customize';

  @override
  String get g4SfNoLimit => 'no limit';

  @override
  String get g4SfNothingPaid =>
      'You use only subscriptions or local models: nothing is paid per use, so there is no spending limit to set. With subscriptions the plan\'s own limits count (shown at the top).';

  @override
  String get g4SfKeepForever => 'always';

  @override
  String get g4SfKeep365 => 'one year';

  @override
  String get g4SfKeep90 => 'three months';

  @override
  String get g4SfKeep30 => 'one month';

  @override
  String get g4SfDoneBtn => 'Done';

  @override
  String get g4SfLead =>
      'Four decisions, each on one card. You change everything whenever you like from Settings.';

  @override
  String get g4SfGuardQ => 'An agent wants to write outside its project. What happens?';

  @override
  String get g4SfGuardAsk => 'It asks me';

  @override
  String get g4SfGuardAuto => 'I let it';

  @override
  String get g4SfApprTitle => 'The approvals';

  @override
  String get g4SfApprQ => 'Who says yes before a risky action, like deleting or publishing?';

  @override
  String g4SfApprCustom(int n, String of) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'A choice of your own: $n things out of $of only you approve.',
      one: 'A choice of your own: 1 thing out of $of only you approve.',
    );
    return '$_temp0';
  }

  @override
  String get g4SfCustomTitle => 'What only you approve';

  @override
  String g4SfCustomLead(String god) {
    return 'Before these actions an agent asks. On: only you can approve it. Off: the agent guiding it can say yes too ($god or the head of the project).';
  }

  @override
  String g4SfBackTo(String preset) {
    return 'Back to $preset';
  }

  @override
  String get g4SfBudgetTitle => 'The spending limit';

  @override
  String get g4SfBudgetQ => 'How much can Rasgeth spend at most with your API keys?';

  @override
  String get g4SfBudgetQFree =>
      'With API keys a limit stops the agents before they spend too much.';

  @override
  String get g4SfBudgetOther => 'other';

  @override
  String g4SfBudgetSay(String usd) {
    return 'At \$$usd the agents stop and tell you; you raise it whenever you like.';
  }

  @override
  String get g4SfBudgetNone => 'No limit: mind the pay-per-use keys.';

  @override
  String get g4SfSkillsTitle => 'The agents\' skills';

  @override
  String get g4SfSkillsQ =>
      'After a hard problem an agent can save how it solved it, for everybody. Do I install them by myself?';

  @override
  String get g4SfSkillsTools => 'The tools that run code always wait for you.';

  @override
  String get g4SfWhereAgents =>
      'The agents work right on this computer, in the project\'s folder: the guardian checks every command that goes outside it.';

  @override
  String get g4SfKeepFor => 'Keep the conversations for';

  @override
  String get g4TlSection => 'Tools';

  @override
  String get g4TlQ => 'Which tools do the agents get?';

  @override
  String get g4TlLead =>
      'Every tool is described to the model in every message, and that costs tokens. Switch off the ones you do not need: for every agent here, or for one agent from its window, tab Tools.';

  @override
  String get g4TlNewOnly =>
      'Changes apply from new conversations: the ones already open keep their tools.';

  @override
  String g4TlTotal(String n) {
    return 'About $n tokens in every message';
  }

  @override
  String g4TlSaved(String n) {
    return 'Switched off: $n tokens saved in every message';
  }

  @override
  String get g4TlNoneSaved => 'Nothing switched off';

  @override
  String g4TlWeight(String n) {
    return 'about $n tokens in every message';
  }

  @override
  String g4TlNeeded(String why) {
    return 'Always needed: $why';
  }

  @override
  String get g4TlLoading => 'Weighing the tools…';

  @override
  String get g4TlSearch => 'Find a tool: name, command or what it does';

  @override
  String g4TlNoMatch(String q) {
    return 'No tool for «$q».';
  }

  @override
  String g4TlError(String error) {
    return 'The tools could not be read: $error';
  }

  @override
  String g4TlHowMany(String all, String on) {
    return '$on of $all on';
  }

  @override
  String g4TlExceptOn(String names) {
    return 'Still on for: $names (their own choice)';
  }

  @override
  String g4TlExceptOff(String names) {
    return 'Off for: $names (their own choice)';
  }

  @override
  String get g4TlExceptReset => 'As for every agent';

  @override
  String get g4CmSection => 'Commands';

  @override
  String get g4CmOneDay => '1 day';

  @override
  String g4CmDays(String n) {
    return '$n days';
  }

  @override
  String g4CmHours(String n) {
    return '$n h';
  }

  @override
  String get g4CmOneHour => '1 h';

  @override
  String g4CmMinutes(String n) {
    return '$n min';
  }

  @override
  String get g4CmNoLimit => 'No limit';

  @override
  String get g4CmPageQ => 'How long can the agents\' commands run?';

  @override
  String get g4CmPageLead =>
      'The agents run commands on this computer: some end at once, others (a development server, a watcher, a long build) keep going in the background while the agent does other things.';

  @override
  String get g4CmBgTitle => 'Commands in the background';

  @override
  String get g4CmBgLead =>
      'Servers, watchers and long builds. You see them in the strip above the message box and can stop them there.';

  @override
  String get g4CmAtOnce => 'At once in one conversation';

  @override
  String get g4CmAtOnceHelp =>
      'When the limit is reached, the agent has to stop one before starting another.';

  @override
  String get g4CmAtOnceWarn =>
      'No limit: an agent can start as many as it likes. Each one uses processor and memory; if the computer slows down, stop some from the strip.';

  @override
  String get g4CmLong => 'How long one can run';

  @override
  String get g4CmLongHelp => 'Past this time the command is stopped by itself.';

  @override
  String get g4CmLongWarn =>
      'No limit: a command runs until you or the agent stop it, even for days. Good for a development server; remember to stop what you no longer need.';

  @override
  String get g4CmLog => 'How big its log can grow';

  @override
  String get g4CmLogHelp =>
      'Every line is kept with its time. Past this size the oldest half goes.';

  @override
  String get g4CmLogWarn =>
      'No limit: a command that writes a lot can fill the disk over time. The logs are in the project\'s .redgiant/commands folder.';

  @override
  String get g4CmBashTitle => 'Ordinary commands';

  @override
  String get g4CmBashLead =>
      'Those the agent waits for before going on (tests, an install, a conversion).';

  @override
  String get g4CmBash => 'Longest wait';

  @override
  String get g4CmBashHelp =>
      'The agent can ask for less; never for more. For longer work it uses the background.';

  @override
  String get g4CmStepsTitle => 'Steps in one turn';

  @override
  String get g4CmStepsLead =>
      'In one turn an agent thinks, uses a tool, reads the result and goes on. Past the limit it stops and tells you where it got to; a «Continue» button under its message lets it go on.';

  @override
  String get g4CmSteps => 'Steps at most';

  @override
  String g4CmStepsHelp(String n) {
    return 'One step is one call to the model. Default: no limit in your conversations with the agents; $n for automations and tasks, which nobody watches. A number or «No limit» counts for every turn.';
  }

  @override
  String get g4CmStepsDefault => 'Default';

  @override
  String get g4CmStepsWarn =>
      'No limit, automations and tasks included: an agent can work for hours in one turn. Only the budgets stop it, so keep one set (Settings, Budgets) if the model costs money.';

  @override
  String get g4CmDefaults => 'Back to the defaults';

  @override
  String get g4CmSaved => 'Saved: it counts from the next command and the next message.';

  @override
  String get g4CmUndo => 'Undo';

  @override
  String get g4CmUndone => 'Undone: the previous values are back.';

  @override
  String get g4RqSection => 'Requests to you';

  @override
  String get g4RqPageQ => 'When an agent needs you';

  @override
  String get g4RqPageLead =>
      'Agents ask before risky actions, ask you questions, propose plans, ask for a tool or a key. Choose whether they ask you, and how long they wait for you.';

  @override
  String get g4RqModeTitle => 'Ask me or not';

  @override
  String get g4RqModeQ => 'Do you want to answer the agents\' requests yourself?';

  @override
  String get g4RqModeAsk => 'Ask me';

  @override
  String get g4RqModeClassifier => 'Don\'t ask me anything';

  @override
  String get g4RqAlwaysYou =>
      'Even with «Don\'t ask me anything», the truly dangerous requests always reach you, everywhere: deletions for good, system files, secrets leaving, real payments and Rasgeth\'s own protections.';

  @override
  String get g4RqModeAskText =>
      'Requests reach you everywhere: here and on the chats you connected. Answer where it suits you: the first answer counts, and the other copies close by themselves.';

  @override
  String get g4RqModeClassifierText =>
      'Nothing reaches you: the classifier decides, a model you choose. It reads each request with the conversation and writes why it decided so. Only the truly dangerous things (listed below) still reach you, everywhere.';

  @override
  String get g4RqModeClassifierWarn =>
      'The classifier can be wrong, and each decision costs a small request to its model.';

  @override
  String get g4RqTimeTitle => 'Time to answer';

  @override
  String get g4RqTimeQ => 'How long should an agent wait for your answer?';

  @override
  String get g4RqTimeQSpecial => 'How long do the truly dangerous things wait for your answer?';

  @override
  String g4RqAfterSpecialText(String time) {
    return 'If you do not answer within $time, it is a no.';
  }

  @override
  String get g4RqTimeNoneSpecial =>
      'They wait as long as it takes: the agent stays still until you answer.';

  @override
  String get g4RqSpecialTitle => 'The truly dangerous things';

  @override
  String get g4RqSpecialQ => 'What always reaches you, wherever you are?';

  @override
  String get g4RqSpecialText =>
      'Only these. When an agent is about to do one of them it stops and waits for you: the request reaches you here and on the chats you connected, also with «Don\'t ask me anything», and the classifier never decides it.';

  @override
  String get g4RqSpecialNot =>
      'Everyday work is not on this list: sending code with git push, an ordinary message or email, putting a site online, changing the project\'s files, using a key from the keychain for its own site. Those follow your choice above.';

  @override
  String get g4RqCriticalExamples => 'For example:';

  @override
  String get g4RqTimeNone =>
      'The agent waits as long as it takes. Requests to switch on a tool or use a key still end after 15 and 10 minutes.';

  @override
  String g4RqAfterQ(String time) {
    return 'If you do not answer within $time:';
  }

  @override
  String get g4RqAfterNo => 'It is a no';

  @override
  String get g4RqAfterClassifier => 'The classifier decides';

  @override
  String get g4RqAfterNoText =>
      'An approval nobody gives is always a no. To a question the agent goes on with its best guess and tells you which.';

  @override
  String get g4RqAfterClassifierText =>
      'When the time runs out the classifier decides in your place, as with «Don\'t ask me anything». The truly dangerous things are a no instead.';

  @override
  String get g4RqClassifierTitle => 'The classifier';

  @override
  String get g4RqClassifierQ => 'Which model decides for you?';

  @override
  String get g4RqClassifierModel => 'Model';

  @override
  String g4RqClassifierDefault(String model) {
    return 'The light model ($model)';
  }

  @override
  String get g4RqClassifierHow =>
      'It reads what the agent asks, its job and the last messages of the conversation; it answers yes or no with a reason, or picks an answer to a question. When in doubt it says no; if it fails, it is a no.';

  @override
  String get g4RqNoModel => 'none connected';

  @override
  String get g4RqSaved => 'Saved: it counts from the next request.';

  @override
  String get g4RqDoneTitle => 'Decided without you';

  @override
  String get g4RqDoneLead =>
      'Every request the classifier decided, or that ended because nobody answered in time, newest first.';

  @override
  String get g4RqDoneEmpty => 'No decision taken without you yet.';

  @override
  String get g4RqOpenChat => 'Open the conversation';

  @override
  String g4RqByModel(String model) {
    return 'Classifier ($model):';
  }

  @override
  String get g4RqByClassifier => 'Classifier:';

  @override
  String get g4RqByTimeout => 'Time ran out:';

  @override
  String get g4RqDecisionAllow => 'Yes';

  @override
  String get g4RqDecisionDeny => 'No';

  @override
  String get g4RqDecisionAnswered => 'Answered';

  @override
  String get g4RqDecisionBlocked => 'Blocked';

  @override
  String get g4RqKindApproval => 'action';

  @override
  String get g4RqKindQuestion => 'question';

  @override
  String get g4RqKindPlan => 'plan';

  @override
  String get g4RqKindTool => 'tool';

  @override
  String get g4RqKindCredential => 'key';

  @override
  String get g4RqKindAutomation => 'automation';

  @override
  String get g4SfSaved => 'Saved: it counts from the next action of the agents.';

  @override
  String get g4SfCustomOn => 'Only you approve it';

  @override
  String get g4CmAtWorkLead => 'Saved at once, for the turns that start from now.';

  @override
  String get g4RulesHub => 'Rules';

  @override
  String get g4TlExtLead =>
      'Installed from Extensions (magic integrations, agents\' proposals, your own): every agent has them. Change or remove them there.';

  @override
  String get g4TlExtTitle => 'Tools of the extensions';

  @override
  String get g4SfTitle => 'Safety and costs';

  @override
  String get g4GenAccount => 'Account';

  @override
  String get g4GenAgentInstructions => 'Its instructions';

  @override
  String get g4GenAgentLangAll => 'All languages';

  @override
  String get g4GenAgentLangChange => 'change';

  @override
  String get g4GenAgentLangCommon => 'Most common';

  @override
  String get g4GenAgentLangHelp =>
      'What every agent, the Chat and the shared memory write in. New conversations use it; open ones keep theirs.';

  @override
  String g4GenAgentLangNone(String q) {
    return 'No language matches «$q».';
  }

  @override
  String get g4GenAgentLangSearch => 'Search a language';

  @override
  String get g4GenAgentLangSub => 'The agents reply in it from the next conversation.';

  @override
  String get g4GenAgentLangTitle => 'Agents\' language';

  @override
  String get g4GenAgents => 'For every agent';

  @override
  String get g4GenAgentsLead =>
      'What every agent reads, and who tries again a task an agent gives up on.';

  @override
  String get g4GenAlreadySet => 'already set';

  @override
  String get g4GenBackupNone => 'None: a task given up on stays so';

  @override
  String get g4GenBackupText =>
      'A task an agent gives up on is tried once more by this model, in a new conversation.';

  @override
  String get g4GenBackupTitle => 'Backup model for tasks';

  @override
  String get g4GenCare => 'Updates and diagnostics';

  @override
  String get g4GenCareLead =>
      'Whether a newer Rasgeth is out, and a log to send when something goes wrong.';

  @override
  String g4GenCloudPrivacy(String name) {
    return 'With $name, what you say after the wake word goes to $name through Rasgeth\'s server; the wake word itself is still heard only in this page.';
  }

  @override
  String get g4GenDebugClear => 'Delete the logs';

  @override
  String get g4GenDebugClearConfirm => 'Delete every log kept?';

  @override
  String get g4GenDebugDownload => 'Download the logs';

  @override
  String get g4GenDebugForced => 'Turned on by the server\'s settings (REDGIANT_DEBUG=1).';

  @override
  String get g4GenDebugHelp =>
      'Debug mode keeps a detailed log of everything Rasgeth does: each step of starting a model with its times, the local engine\'s own messages, the requests, what the Windows program does. Turn it on when something is slow or goes wrong, repeat it, then download the logs and send them. It writes a lot (at most 300 MB, the oldest go first) and never writes passwords or keys.';

  @override
  String g4GenDebugSize(String size, String files) {
    return 'Logs kept: $size in $files files.';
  }

  @override
  String get g4GenDebugSwitch => 'Debug mode';

  @override
  String get g4GenDebugText =>
      'Everything Rasgeth does, written in a log you can download and send.';

  @override
  String get g4GenDebugTitle => 'Diagnostics';

  @override
  String get g4GenDraftDefaultUsed =>
      'These are the built-in instructions, with what you wrote. Every tool stays as for the other agents.';

  @override
  String g4GenDraftFailed(String god, String why) {
    return '$god could not write them ($why). Here are the built-in ones, with what you wrote.';
  }

  @override
  String g4GenDraftLead(String god) {
    return '$god writes them from the built-in ones, fitted to what you wrote and to its settings, and chooses the tools it needs. Read, change what you like, then create it.';
  }

  @override
  String get g4GenDraftRegenerate => 'Write them again';

  @override
  String get g4GenDraftToolOnDefault => 'useful for its job';

  @override
  String get g4GenDraftToolsAllOn => 'Every tool on, as for the other agents.';

  @override
  String get g4GenDraftToolsLikeOthers => 'All as for the other agents';

  @override
  String g4GenDraftToolsSaved(String n, String tokens) {
    return '$n switched off, saving about $tokens tokens on every message. If it needs one later, it asks you.';
  }

  @override
  String get g4GenDraftToolsTitle => 'Its tools';

  @override
  String g4GenDraftToolTokens(String tokens) {
    return '$tokens tokens';
  }

  @override
  String get g4GenDraftUseDefault => 'Use the built-in ones';

  @override
  String g4GenDraftWorking(String god) {
    return '$god is writing its instructions...';
  }

  @override
  String get g4GenHasKey => 'Key ready';

  @override
  String get g4GenImagesHelp =>
      'An OpenAI key lets agents draw pictures; it costs money for each picture.';

  @override
  String get g4GenImagesKey => 'OpenAI key for pictures (generate_image)';

  @override
  String get g4GenImagesModel => 'Picture model';

  @override
  String get g4GenImagesTitle => 'Pictures';

  @override
  String get g4GenInstrText =>
      'What every agent should know or do: how you like answers, your conventions, what to avoid.';

  @override
  String get g4GenInstructionsHint =>
      'What every agent should know or do, whoever it is: how you like answers, your conventions, things to avoid. They are added to each agent\'s own instructions (those are in each agent\'s card under Agents).';

  @override
  String get g4GenInstructionsPlaceholder =>
      'For example: answer in Italian; code and comments in English; never push without asking.';

  @override
  String get g4GenInstructionsSaved => 'Saved: conversations started from now on follow them.';

  @override
  String get g4GenInstructionsTitle => 'Instructions for every agent';

  @override
  String get g4GenInUse => 'in use';

  @override
  String get g4GenKeyChange => 'Use another key';

  @override
  String g4GenKeyGet(String name) {
    return 'Get a $name key';
  }

  @override
  String get g4GenKeyHelp => 'Kept in the keychain, encrypted; it never reaches this page again.';

  @override
  String g4GenKeyLabel(String name) {
    return '$name key';
  }

  @override
  String g4GenKeyLinked(String name) {
    return 'Uses the $name key you already gave (chat, extensions or voice).';
  }

  @override
  String get g4GenLead =>
      'Its look and language, then what every agent shares and the extra services. Each square opens its window; the lit ones are set.';

  @override
  String get g4GenLocked => 'set by the environment';

  @override
  String get g4GenLogout => 'Sign out';

  @override
  String g4GenModelCloses(String date) {
    return 'The provider closes this model on $date: choose another one before then.';
  }

  @override
  String get g4GenNews => 'What\'s new';

  @override
  String get g4GenNewsText =>
      'Everything each release brought, newest first: also what you missed.';

  @override
  String g4GenNewsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get g4GenOn => 'on';

  @override
  String get g4GenOwnSearchHint =>
      'Rasgeth can run its own search engine (SearXNG): free, no keys, and every model can search the web with it, local ones too.';

  @override
  String get g4GenOwnSearchOn =>
      'Rasgeth\'s search engine is on: every agent and the Chat search the web with it.';

  @override
  String get g4GenOwnSearchStart => 'Start Rasgeth\'s search engine';

  @override
  String get g4GenOwnSearchStop => 'Switch it off';

  @override
  String g4GenPriceKchars(String usd) {
    return '$usd per 1000 characters';
  }

  @override
  String g4GenPriceMinute(String usd) {
    return 'about $usd a minute';
  }

  @override
  String g4GenPriceMtokens(String usd) {
    return '$usd per million audio tokens';
  }

  @override
  String get g4GenQ => 'How do you want Rasgeth?';

  @override
  String get g4GenRefineAfter => 'After';

  @override
  String get g4GenRefineBefore => 'Before';

  @override
  String g4GenRefineCount(String del, String add) {
    return '$del words out, $add words in';
  }

  @override
  String g4GenRefineGodModel(String god) {
    return '$god\'s model';
  }

  @override
  String get g4GenRefineLegendAdd => 'what is new';

  @override
  String get g4GenRefineLegendDel => 'what goes away';

  @override
  String get g4GenRefineModel => 'The model that writes';

  @override
  String get g4GenRewriteGo => 'Rewrite';

  @override
  String g4GenRewriteLead(String god) {
    return '$god starts from the instructions in the field and fits them to what the agent does now. You see the changes first.';
  }

  @override
  String get g4GenRewriteTitle => 'Rewrite for the new job';

  @override
  String get g4GenRewriteYes => 'Yes, rewrite them';

  @override
  String get g4GenSaved => 'Saved';

  @override
  String get g4GenSearchDocs => 'How to install SearXNG yourself';

  @override
  String g4GenSearchHowTitle(String name) {
    return 'How to set up $name';
  }

  @override
  String get g4GenSearchKey => 'Key';

  @override
  String get g4GenSearchKeyKept => 'A key is saved: leave empty to keep it.';

  @override
  String g4GenSearchKeyPage(String name) {
    return 'Open the page of $name\'s keys';
  }

  @override
  String g4GenSearchSaved(String name) {
    return 'From now on the models that cannot search by themselves use $name.';
  }

  @override
  String get g4GenSearchText => 'Lets every agent and the Chat look things up on the web.';

  @override
  String get g4GenSearchTitle => 'Web search';

  @override
  String g4GenSearchTried(String n, String first) {
    return 'It works: $n results, the first «$first».';
  }

  @override
  String get g4GenSearchTriedEmpty => 'It answered, but with no results for the test search.';

  @override
  String get g4GenSearchTry => 'Try it';

  @override
  String get g4GenSearchUrl => 'Address of the SearXNG server';

  @override
  String get g4GenSearchUrlHelp => 'The address where your SearXNG answers.';

  @override
  String get g4GenSearchUse => 'Use this';

  @override
  String get g4GenSearchWho =>
      'Claude and the subscriptions search by themselves. The others (local models, OpenAI-compatible keys) use the service chosen here.';

  @override
  String get g4GenServices => 'Services';

  @override
  String get g4GenServicesHint =>
      'Extras the agents can use. Each one works only if you set it; leaving a field empty switches it off.';

  @override
  String g4GenSttCloudHelp(String models, String price) {
    return 'In the cloud: $models. From $price.';
  }

  @override
  String get g4GenSttCompatible => 'Another compatible service';

  @override
  String get g4GenSttCompatibleHelp =>
      'Any service with the OpenAI transcription API (speaches, whisper.cpp\'s server…), at its address.';

  @override
  String get g4GenSttLocal => 'On this computer';

  @override
  String get g4GenSttLocalHelp =>
      'whisper.cpp, started by Rasgeth: free, nothing leaves the house.';

  @override
  String get g4GenSttRemote => 'whisper on another computer';

  @override
  String get g4GenSttRemoteHelp =>
      'whisper-asr-webservice at its address, for a computer with a graphics card.';

  @override
  String get g4GenTitle => 'General';

  @override
  String get g4GenTrying => 'Trying the model…';

  @override
  String get g4GenUiLangHelp => 'The pages, the menus and the setup.';

  @override
  String get g4GenUiLangTitle => 'Interface language';

  @override
  String get g4GenUpdHelp =>
      'Rasgeth looks for a new version by itself at the first start of each day. Here you can look now.';

  @override
  String get g4GenVoiceHelp => 'Turns voice messages (from Telegram or the microphone) into text.';

  @override
  String get g4GenVoiceKey => 'Transcription service key';

  @override
  String get g4GenVoiceLocalHint =>
      'No account and nothing leaves this computer. Rasgeth downloads whisper.cpp and a multilingual model once (about 560 MB, with its bar in the corner) and runs them itself.';

  @override
  String get g4GenVoiceModel => 'Transcription model';

  @override
  String get g4GenVoiceModelHead => 'Model';

  @override
  String g4GenVoiceNeedsKey(String name) {
    return 'Paste the $name key first.';
  }

  @override
  String get g4GenVoiceNeedsUrl => 'Write the service\'s address first.';

  @override
  String get g4GenVoiceTitle => 'Voice messages';

  @override
  String get g4GenVoiceUrl => 'Address of the transcription service';

  @override
  String get g4GenWritten => 'written';

  @override
  String get g4GenLook => 'Look and language';

  @override
  String get g4GenBackupSaved => 'Saved: it applies to tasks given up on from now on.';

  @override
  String g4GenDebugSaved(String name) {
    return 'Saved: $name';
  }

  @override
  String g4GenNewsTitle(String version) {
    return 'What is new in Rasgeth $version';
  }

  @override
  String get g4GenNewsOk => 'Got it';

  @override
  String get g4AgTreeTitle => 'Your team';

  @override
  String g4AgTreeOf(String project) {
    return 'The agents of $project';
  }

  @override
  String get g4AgTreeLead =>
      'Who works for you. God leads everything; each project has its lead, who hands work to the project\'s agents. An agent sees only its own project; the inspector only reads.';

  @override
  String get g4AgTreeProjectLead =>
      'The project\'s lead, the agents it hands work to, and those of other places assigned to it.';

  @override
  String get g4AgAllProjects => 'All projects';

  @override
  String get g4AgShowStopped => 'Also the stopped ones';

  @override
  String get g4AgNoLead => 'This project has no orchestrator yet.';

  @override
  String get g4AgNear => 'Demi-God and personal agents';

  @override
  String get g4AgAssigned => 'assigned';

  @override
  String get g4AgArchived => 'archived';

  @override
  String get g4AgOpen => 'Open';

  @override
  String get g4AgClose => 'Close';

  @override
  String get g4AgAddShort => 'Agent under it';

  @override
  String g4AgAddUnder(String name) {
    return 'Add an agent under $name';
  }

  @override
  String get g4AgKind => 'Kind';

  @override
  String get g4AgWhatItDoes => 'What it does';

  @override
  String get g4AgModelDefault => 'The default model';

  @override
  String get g4AgOpenChat => 'Open its conversation';

  @override
  String get g4AgReadOnly =>
      'Its project is archived: you can read its settings, nothing changes until the project is restored.';

  @override
  String get g4AgGroupAssistant => 'Services and routines';

  @override
  String g4AgRewriteOffer(String name, String god) {
    return 'You changed what $name does. Do you want $god to rewrite its instructions for the new job? You will see them before anything changes.';
  }

  @override
  String get g4AgRewriteNo => 'No, keep them';

  @override
  String get g4AgRewriteYes => 'Yes, rewrite them';

  @override
  String get g4AgServices => 'Services';

  @override
  String get g4AgServicesHelp => 'The services it may use. Changes apply to its new conversations.';

  @override
  String get g4AgNoServices => 'No services added yet.';

  @override
  String get g4AgAddServiceHint =>
      'You add services (Notion, Linear, GitHub…) in Settings, Extensions.';

  @override
  String get g4AgSvcChecking => 'Checking…';

  @override
  String g4AgSvcWorks(int n) {
    return 'Works · $n tools';
  }

  @override
  String get g4AgSvcLogin => 'Needs you to sign in';

  @override
  String get g4AgSvcBroken => 'Not working';

  @override
  String get g4AgSavedNewChats => 'Saved: it applies to its new conversations.';

  @override
  String get g4AgRoutines => 'Routines';

  @override
  String get g4AgRoutinesHelp => 'Work it does by itself at a set time or when something happens.';

  @override
  String get g4AgNoRoutines => 'No routines yet.';

  @override
  String get g4AgNewRoutine => 'New routine';

  @override
  String g4AgNewRoutineOf(String name) {
    return 'A new routine for $name';
  }

  @override
  String get g4AgOn => 'On';

  @override
  String get g4AgOff => 'Off';

  @override
  String get g4AgRoutineWhat => 'What should it do?';

  @override
  String get g4AgRoutineWhatHint =>
      'For example: look at today\'s appointments and send me a summary.';

  @override
  String get g4AgRoutineTitle => 'Its title (optional)';

  @override
  String get g4AgRoutineWhen => 'When';

  @override
  String get g4AgEvery_daily => 'Every day';

  @override
  String get g4AgEvery_weekdays => 'Monday to Friday';

  @override
  String get g4AgEvery_weekly => 'Every Monday';

  @override
  String get g4AgEvery_hourly => 'Every hour';

  @override
  String get g4AgRoutineTime => 'At what time (HH:MM)';

  @override
  String get g4AgRoutineTimeBad => 'A time like 09:00';

  @override
  String get g4AgRoutineSave => 'Save the routine';

  @override
  String g4AgRoutineOnce(String at) {
    return 'Once, $at';
  }

  @override
  String g4AgWhenDaily(String time) {
    return 'Every day at $time';
  }

  @override
  String g4AgWhenWeekdays(String time) {
    return 'Monday to Friday at $time';
  }

  @override
  String g4AgWhenWeekly(String time) {
    return 'Every Monday at $time';
  }

  @override
  String get g4AgSkills => 'Skills';

  @override
  String get g4AgSkillsHelp =>
      'After a job that went well, tell it «save this as a skill»: it writes the steps down and, once you approve them in Extensions, every agent can use them.';

  @override
  String get g4AgShared => 'What every agent knows about you';

  @override
  String get g4AgSharedHelp =>
      'Who you are, your work, your tools: shared by all your personal agents.';

  @override
  String get g4AgStep1 => 'What should it do?';

  @override
  String get g4AgStep2Help => 'It works there, under the project\'s lead.';

  @override
  String get g4AgStep3 => 'Its name';

  @override
  String get g4AgStep4Help =>
      'Usually the same as the project\'s lead; choose another for a cheaper or stronger one.';

  @override
  String get g4AgStep5 => 'How much it may do alone';

  @override
  String get g4AgStep2Asst => 'Which services may it use?';

  @override
  String get g4AgStep2AsstHelp =>
      'It sees only the services you switch on here. Anything that sends, publishes, deletes or pays always asks you first.';

  @override
  String get g4AgStep3Asst => 'How much may it do alone?';

  @override
  String get g4AgWhere => 'Where it works';

  @override
  String get g4AgWhereHelp =>
      'In a subproject it writes only in its folder; the rest of the project it can read, and changes there go through the lead.';

  @override
  String get g4AgWholeProject => 'The whole project';

  @override
  String get g4AgOwnWords => 'Describe the job in your own words';

  @override
  String get g4AgOwnWordsHelp =>
      'For example: keeps the website\'s texts in Italian and English and checks the links.';

  @override
  String get g4AgRecommended => 'recommended';

  @override
  String get g4AgModeText_auto =>
      'Works by itself; asks only for risky actions (as set in Safety).';

  @override
  String get g4AgModeText_manual => 'Asks before every change to files or commands.';

  @override
  String get g4AgModeText_plan => 'First proposes a plan; works only once it is approved.';

  @override
  String get g4AgModeText_readonly => 'Reads and answers, changes nothing.';

  @override
  String get g4AgAsstMode_auto => 'On its own';

  @override
  String get g4AgAsstMode_manual => 'Asks first';

  @override
  String get g4AgAsstModeText_auto =>
      'Works by itself; asks you only before what leaves (sending, publishing, paying) or is risky.';

  @override
  String get g4AgAsstModeText_manual => 'Asks you before every change.';

  @override
  String get g4AgAsstPurpose =>
      'A personal agent does one job for you, outside the projects. God hands it the work that is its own; you can also talk to it directly.';

  @override
  String get g4AgAsstRole => 'Its job';

  @override
  String get g4AgAsstRoleHelp =>
      'One or two sentences: God reads them to decide what to hand to it, so keep it narrow.';

  @override
  String get g4AgOrAskGod => 'Not sure which agents you need?';

  @override
  String g4AgAskGod(String god) {
    return 'Ask $god';
  }

  @override
  String get g4AgAskGodMessage =>
      'Which personal agents would be useful to me? Look at what I do with you and suggest two or three, each with a narrow job and the services it needs. Create them only after I say yes.';

  @override
  String g4AgDraftNext(String god) {
    return 'Next: $god writes its instructions';
  }

  @override
  String g4AgDraftNextHint(String god) {
    return '$god will write its instructions and choose its tools; you see them before it is created.';
  }

  @override
  String get g4AgDraftTitle => 'Its instructions and tools';

  @override
  String get g4AgReviewWritten => 'written for it';

  @override
  String get g4AgReviewBuiltIn => 'the built-in ones';

  @override
  String get g4AgNoneChosen => 'none';

  @override
  String get g4AgRole_coder => 'Programmer';

  @override
  String get g4AgRoleText_coder => 'Writes and changes the code, runs the tests.';

  @override
  String get g4AgRole_reviewer => 'Reviewer';

  @override
  String get g4AgRoleText_reviewer =>
      'Checks changes for bugs and unclear code, says where and why.';

  @override
  String get g4AgRole_researcher => 'Researcher';

  @override
  String get g4AgRoleText_researcher =>
      'Looks things up on the web and in the files, with sources.';

  @override
  String get g4AgRole_writer => 'Writer';

  @override
  String get g4AgRoleText_writer => 'Documentation, READMEs and texts, clear and up to date.';

  @override
  String get g4AgRole_tester => 'Tester';

  @override
  String get g4AgRoleText_tester => 'Writes and runs tests, reproduces bugs.';

  @override
  String get g4AgRole_custom => 'Something else';

  @override
  String get g4AgRoleText_custom => 'You describe the job in your own words.';

  @override
  String get g4AgJob_secretary => 'Secretary';

  @override
  String get g4AgJobHint_secretary =>
      'Your diary, your tasks and messages; a summary every morning.';

  @override
  String get g4AgJobText_secretary =>
      'Keep my tasks and appointments in order, remind me of deadlines and give me a short summary of the day when I ask. Never send anything in my name without asking.';

  @override
  String get g4AgJob_researcher => 'Researcher';

  @override
  String get g4AgJobHint_researcher => 'Looks things up on the web and reports with sources.';

  @override
  String get g4AgJobText_researcher =>
      'Look things up on the web when I ask, compare the sources and report what you found with the links, saying what you could not confirm.';

  @override
  String get g4AgJob_social => 'Social media';

  @override
  String get g4AgJobHint_social => 'Prepares posts and keeps an eye on your pages.';

  @override
  String get g4AgJobText_social =>
      'Prepare posts for my pages in my style, propose them to me before publishing and tell me how the last ones went.';

  @override
  String get g4AgJob_accounts => 'Accounts';

  @override
  String get g4AgJobHint_accounts => 'Invoices, payments and expenses, in order.';

  @override
  String get g4AgJobText_accounts =>
      'Keep invoices, payments and expenses in order, tell me what is due and what is missing. Never pay or refund without my approval.';

  @override
  String get g4AgJob_tech => 'Tech helper';

  @override
  String get g4AgJobHint_tech => 'Answers technical questions and fixes small things.';

  @override
  String get g4AgJobText_tech =>
      'Answer my technical questions simply, with the steps to follow, and fix small problems when I ask.';

  @override
  String get g4AgJob_custom => 'In my own words';

  @override
  String get g4AgJobHint_custom => 'Describe the job yourself.';

  @override
  String get g4BuTitle => 'Budgets';

  @override
  String g4BuThisMonth(String month) {
    return 'Spent in $month';
  }

  @override
  String get g4BuLead => 'What projects and agents spend, and how far they may go.';

  @override
  String get g4BuChart => 'Spending day by day this month';

  @override
  String get g4BuHowLink => 'How limits work';

  @override
  String get g4BuHow =>
      'Limits count everything spent since you set them, not month by month. When a row reaches its limit, its agents stop before their next request and Telegram warns you as it gets close. Raise or remove the limit to let them go on. Subscriptions (Claude, ChatGPT) and models on your computer cost nothing here.';

  @override
  String get g4BuUnderstood => 'Got it';

  @override
  String get g4BuTotal => 'Total';

  @override
  String get g4BuEverything => 'Everything';

  @override
  String get g4BuNothingYet => 'Nothing spent yet.';

  @override
  String get g4BuProjects => 'Projects';

  @override
  String get g4BuAgents => 'Agents';

  @override
  String g4BuLimitFor(String name) {
    return 'Limit for $name';
  }

  @override
  String g4BuLimitNow(String limit) {
    return 'Now: $limit';
  }

  @override
  String g4BuLimitSay(String usd) {
    return 'At \$$usd its agents stop and tell you; you raise it whenever you like.';
  }

  @override
  String get g4BuLimitPick => 'Choose an amount, or write another one.';

  @override
  String get g4BuRemoveLimit => 'No limit';

  @override
  String g4BuMonth(String usd) {
    return '$usd this month';
  }

  @override
  String g4BuEver(String usd) {
    return '$usd since the start';
  }

  @override
  String get g4BuStopped => 'Limit reached: stopped';

  @override
  String get g4BuChange => 'Change';

  @override
  String g4BuLimitIs(String limit) {
    return 'Limit $limit';
  }

  @override
  String get g4BuNoLimit => 'no limit';

  @override
  String get g4BuOther => 'other';

  @override
  String get g4BuLimitLabel => 'Limit';

  @override
  String g4BuTokens(String n) {
    return '$n tokens';
  }

  @override
  String get g4BuRowHint => 'This month, every project and agent, with their limits';

  @override
  String g4DvRenameQ(String name) {
    return 'A new name for «$name»';
  }

  @override
  String g4DvRenamed(String name) {
    return 'Renamed: $name';
  }

  @override
  String get g4HubTitle => 'Settings';

  @override
  String get g4HubGeneral => 'Language, agents\' instructions, search, images, what\'s new';

  @override
  String get g4HubAgents => 'The tree of agents, new agents, assistants';

  @override
  String get g4HubTools => 'What every agent may use';

  @override
  String get g4HubCommands => 'Background commands, agents at work together';

  @override
  String get g4HubRequests => 'Where requests reach you, how long they wait';

  @override
  String get g4HubSafety => 'Guardian, who approves, spending, skills, retention';

  @override
  String get cvCanvasFullscreen => 'Full screen';

  @override
  String get cvCanvasFullscreenExit => 'Exit full screen';

  @override
  String get cvSideMaximize => 'Maximize';

  @override
  String get cvSideBackToChat => 'Back to chat';

  @override
  String get cvVwDownload => 'Download';

  @override
  String cvVwCanvasBack(String n) {
    return 'Nebula ($n)';
  }

  @override
  String get cvKbTitle => 'Keyboard shortcuts';

  @override
  String get cvSideTabsLabel => 'Open files and terminals';

  @override
  String get cvCanvasAgentOpened => 'Opened by the agent';

  @override
  String get cvVwKindArchive => 'Archive';

  @override
  String get cvVwKindAudio => 'Audio';

  @override
  String get cvVwKindCode => 'Code';

  @override
  String get cvVwKindDocument => 'Document';

  @override
  String get cvVwKindFont => 'Font';

  @override
  String get cvVwKindImage => 'Picture';

  @override
  String get cvVwKindLayers => 'Layers (OpenRaster)';

  @override
  String get cvVwKindMarkdown => 'Markdown';

  @override
  String get cvVwKindModel => '3D model';

  @override
  String get cvVwKindPdf => 'PDF';

  @override
  String get cvVwKindSheet => 'Spreadsheet';

  @override
  String get cvVwKindSite => 'Page';

  @override
  String get cvVwKindSlides => 'Slides';

  @override
  String get cvVwKindTable => 'Table';

  @override
  String get cvVwKindText => 'Text';

  @override
  String get cvVwKindTree => 'Data';

  @override
  String get cvVwKindUnknown => 'File';

  @override
  String get cvVwKindVideo => 'Video';

  @override
  String get embedFallbackNote => 'The page is not answering: this is the app\'s simple view.';

  @override
  String get palTitle => 'Agents at most in this project';

  @override
  String get palZero => 'Orchestrator only';

  @override
  String get palHelp =>
      'Besides the orchestrator; sub-agents at work count too. At 0 the orchestrator works alone.';

  @override
  String palNow(String n) {
    return 'Now: $n.';
  }

  @override
  String get palNone => 'none';

  @override
  String get palOne => '1 agent';

  @override
  String palN(String n) {
    return '$n agents';
  }

  @override
  String palOver(String n, String max) {
    return 'It has $n, more than $max: nobody is removed, but no new agent until the team is under the limit.';
  }

  @override
  String get palSaved => 'Saved. It is in the history of changes, where you can undo it.';

  @override
  String pmAgentLimit(String n) {
    return 'Agents at most: $n';
  }

  @override
  String errAgentLimit(String project, String max, String count) {
    return 'The project «$project» can have at most $max agents besides its orchestrator: it has $count. Raise the limit in the project\'s menu or remove one.';
  }

  @override
  String appUpdTitle(String app) {
    return '$app update';
  }

  @override
  String appUpdCheck(String app) {
    return 'Check for $app updates…';
  }

  @override
  String get appUpdChecking => 'Looking for a new version…';

  @override
  String appUpdUpToDate(String app, String current) {
    return '$app $current is the newest version.';
  }

  @override
  String appUpdAvailable(String version, String current) {
    return 'Version $version is out: you have $current.';
  }

  @override
  String get appUpdFromServer =>
      'GitHub does not answer: this is the version of the Rasgeth you are connected to.';

  @override
  String get appUpdDownload => 'Download';

  @override
  String appUpdDownloading(String version) {
    return 'Downloading $version';
  }

  @override
  String get appUpdHide => 'Hide';

  @override
  String get appUpdLater => 'Later';

  @override
  String get appUpdSkip => 'Skip this version';

  @override
  String appUpdReady(String version, String app) {
    return '$version is ready. $app closes, updates and opens again where you are.';
  }

  @override
  String get appUpdVerified => 'Signature and checksum checked with Rasgeth\'s update key.';

  @override
  String get appUpdRestart => 'Update and restart';

  @override
  String appUpdApplying(String app) {
    return 'Closing $app to update it…';
  }

  @override
  String get appUpdRetry => 'Try again';

  @override
  String get appUpdClose => 'Close';

  @override
  String get appUpdErrNetwork => 'GitHub cannot be reached now. Try again later.';

  @override
  String get appUpdErrSignature =>
      'The signature of this version\'s file list is missing or not valid: nothing of it is used.';

  @override
  String appUpdErrNotListed(String app) {
    return 'This version has no $app package for this system.';
  }

  @override
  String get appUpdErrChecksum => 'The downloaded file is not the signed one: it was deleted.';

  @override
  String get appUpdErrDisk => 'The downloaded file could not be kept or opened.';

  @override
  String get appUpdErrSwap => 'The replacement could not start: nothing changed.';

  @override
  String appUpdDone(String app, String version, String from) {
    return '$app is now $version (it was $from).';
  }

  @override
  String appUpdWentBack(String version, String app, String current) {
    return '$version did not start: $app went back to $current. It is not offered again until a newer one comes out.';
  }

  @override
  String appUpdCarried(String app) {
    return 'This copy of $app comes with Rasgeth: it is updated with Rasgeth.';
  }

  @override
  String get appUpdDev => 'A build from the sources: it does not update itself.';

  @override
  String get knAsstSavedNewChats => 'Saved: it applies to its new conversations.';

  @override
  String get knCompactAtHint =>
      'An agent can keep only so much text in mind at once, like a notebook with a fixed number of pages. Further right: the summary comes later. Further left: it comes sooner and the conversation stays lighter.';

  @override
  String get knCompactAtTitle => 'When to write the summary';

  @override
  String knCompactAtValue(String n) {
    return 'when $n% full';
  }

  @override
  String knCompactDefaultIs(String at, String keep) {
    return 'Default for this agent\'s model: at $at%, keeping $keep%.';
  }

  @override
  String get knCompactDefaults => 'Back to the defaults';

  @override
  String knCompactExample(String at, String keep) {
    return 'if the agent can keep 100 pages in mind, when it reaches $at it writes the summary: the last $keep stay exactly as they were, the ones before become a few pages of notes.';
  }

  @override
  String knCompactExampleNone(String at) {
    return 'if the agent can keep 100 pages in mind, when it reaches $at it turns all of them into a few pages of notes.';
  }

  @override
  String get knCompactExampleTitle => 'For example:';

  @override
  String get knCompactExplain =>
      'When the conversation gets long, the agent writes a summary of the old parts, like someone taking notes. Here you choose when it does it, and how much of the latest part it keeps as it is.';

  @override
  String get knCompactKeepHint =>
      'The most recent part stays word for word, everything before it becomes notes. More kept means the agent remembers the latest details better; on a model on your computer each kept word costs a little time once (12% is fine there).';

  @override
  String get knCompactKeepNone => 'nothing';

  @override
  String get knCompactKeepTitle => 'How much of the latest part to keep as it is';

  @override
  String knCompactKeepValue(String n) {
    return 'the last $n%';
  }

  @override
  String get knErr_memory_empty => 'Write something to remember.';

  @override
  String get knErr_memory_forgotten => 'A memory forgotten for good cannot come back.';

  @override
  String get knErr_memory_full => 'The memory is full: delete or merge some old memories first.';

  @override
  String get knErr_memory_gone => 'That memory is not there any more.';

  @override
  String get knErr_memory_long => 'A memory is at most 400 characters: write it shorter.';

  @override
  String get knErr_memory_moved => 'The memory changed again since: undo the newer change first.';

  @override
  String get knErr_memory_same => 'Another memory already says the same.';

  @override
  String get knErr_memory_secret =>
      'That looks like a password, a code or a card number: secrets are never kept in memory.';

  @override
  String get knErr_memory_undone => 'That change was already undone.';

  @override
  String knJob_download_knowledge_model(String model, String size) {
    return 'Downloading $model ($size) for the knowledge, to search your files on this computer (only once)';
  }

  @override
  String knJob_download_ocr(String languages, String size) {
    return 'Downloading the reading of text in pictures ($languages, $size), only once';
  }

  @override
  String get knJob_download_pgvector =>
      'Downloading pgvector, the search by meaning in Rasgeth\'s database (only once)';

  @override
  String get knJob_error_checksum =>
      'The download arrived damaged (its fingerprint does not match): try again.';

  @override
  String get knJob_error_pgvector_unavailable =>
      'pgvector is not published for this computer yet: the knowledge searches by words only.';

  @override
  String get knJob_step_model_download => 'The model';

  @override
  String get knJob_step_ocr_languages => 'The languages';

  @override
  String get knJob_step_ocr_program => 'The program';

  @override
  String get knJob_step_tool_download => 'Downloading';

  @override
  String get knKbAdd => 'Add';

  @override
  String get knKbAddSource => 'Add a source';

  @override
  String knKbAddSourceTo(String name) {
    return 'Add a source to $name';
  }

  @override
  String get knKbAgentAlways => 'Always';

  @override
  String get knKbAgentByScopeNo => 'As the collection says (no)';

  @override
  String get knKbAgentByScopeYes => 'As the collection says (yes)';

  @override
  String knKbAgentLead(String name) {
    return 'Which collections $name can search. Each one says who may read it; here you can make an exception for this agent.';
  }

  @override
  String get knKbAgentNever => 'Never';

  @override
  String get knKbAgentNewOnly => 'It changes from the agent\'s next conversation.';

  @override
  String knKbAgentNone(String name) {
    return '$name reads no collection';
  }

  @override
  String get knKbAgentOpenAll => 'All the collections';

  @override
  String knKbAgentPieces(String n) {
    return '$n pieces';
  }

  @override
  String knKbAgentReads(String n, String name) {
    return '$name reads $n collections';
  }

  @override
  String get knKbAgentTool =>
      'It searches them with «Search the documents», and cites where each answer comes from.';

  @override
  String get knKbAllChats => 'None chosen: the conversations with every agent.';

  @override
  String get knKbBackupVectors => 'Put the knowledge in the backup too';

  @override
  String get knKbBackupVectorsHelp =>
      'A bigger backup, but on another computer the search is ready at once, without reading everything again.';

  @override
  String get knKbChat => 'conversation';

  @override
  String get knKbCiteFallback => 'document';

  @override
  String get knKbCloudKey => 'Keychain entry with the key';

  @override
  String get knKbCloudKeyExample => 'voyage_key';

  @override
  String get knKbCloudKeyHelp =>
      'Empty: the key given in the setup, for OpenAI, Gemini and Mistral.';

  @override
  String get knKbCloudLead =>
      'The pieces of your documents are sent to the service to be read. Its key stays in the keychain.';

  @override
  String get knKbCloudModel => 'Suggested models';

  @override
  String get knKbCloudModelName => 'Model';

  @override
  String get knKbCloudText => 'OpenAI, Voyage, Cohere, Gemini, Mistral, Jina or your own';

  @override
  String get knKbCloudTitle => 'An online service';

  @override
  String get knKbCloudTrying => 'Trying the key…';

  @override
  String get knKbCloudUrl => 'Address of the service';

  @override
  String get knKbCloudUrlHelp => 'One that speaks like OpenAI, ending in /v1.';

  @override
  String get knKbCloudUse => 'Use it';

  @override
  String get knKbCloudWho => 'Which service';

  @override
  String knKbColLine(String docs, String pieces) {
    return '$docs documents · $pieces pieces';
  }

  @override
  String get knKbColName => 'Name';

  @override
  String get knKbColNameExample => 'Manuals, Contracts, Recipes…';

  @override
  String get knKbColNameHelp => 'What it holds, in a few words.';

  @override
  String get knKbColsLead =>
      'A collection groups the sources of one subject, and says which agents may read it.';

  @override
  String get knKbColsTitle => 'Collections';

  @override
  String get knKbConsentChats =>
      'The agents that may read this collection will be able to find and quote what you wrote in your conversations and what the agents answered.';

  @override
  String get knKbConsentChatsYes => 'Yes, the agents may read these conversations';

  @override
  String get knKbConsentMail =>
      'The agents that may read this collection will be able to find and quote your mail. Rasgeth only reads the inbox: it never marks, moves or deletes a message.';

  @override
  String get knKbConsentMailYes => 'Yes, the agents may read this mail';

  @override
  String knKbDays(String n) {
    return '$n days';
  }

  @override
  String get knKbDiskLead => 'What the knowledge takes, and whether the backup carries it.';

  @override
  String get knKbDiskModels => 'Models';

  @override
  String get knKbDiskOcr => 'Reading pictures';

  @override
  String get knKbDiskTexts => 'Pieces of text';

  @override
  String get knKbDiskTitle => 'Space on the disk';

  @override
  String get knKbDiskTotal => 'In all';

  @override
  String get knKbDiskVectors => 'Index by meaning';

  @override
  String knKbDocsWaiting(String n) {
    return '$n documents still to read.';
  }

  @override
  String get knKbDownloading => 'Downloading…';

  @override
  String get knKbDropHere => 'Drop to add them to the knowledge';

  @override
  String get knKbDropOnCard => 'Drop files on a collection to add them.';

  @override
  String get knKbDropSay => 'You can also drop files on this window.';

  @override
  String get knKbErr_bad_choice => 'That choice is not possible.';

  @override
  String get knKbErr_bad_source => 'That source cannot be read: check the path or the address.';

  @override
  String get knKbErr_embedding_failed => 'The model did not answer: check the key and try again.';

  @override
  String get knKbErr_no_vector => 'Searching by meaning is not ready on this computer yet.';

  @override
  String get knKbErr_not_found => 'It is not there any more.';

  @override
  String get knKbEtaSoon => 'The time left shows after the first minutes.';

  @override
  String get knKbFileExample => '/home/me/manual.pdf';

  @override
  String get knKbFileHelp => 'Its full path on the computer where Rasgeth runs.';

  @override
  String get knKbFilePath => 'The file';

  @override
  String get knKbFolderExample => '/home/me/Documents or C:\\Users\\me\\Documents';

  @override
  String get knKbFolderHelp => 'Its full path on the computer where Rasgeth runs.';

  @override
  String get knKbFolderPath => 'The folder';

  @override
  String knKbForAgent(String name) {
    return 'For $name';
  }

  @override
  String get knKbForAll => 'For every agent';

  @override
  String knKbForProject(String name) {
    return 'For the project $name';
  }

  @override
  String get knKbForWhom => 'Who may read it';

  @override
  String get knKbHere => 'Downloaded';

  @override
  String get knKbHowFarBack => 'How far back';

  @override
  String get knKbKindText_chats => 'What you said with the agents';

  @override
  String get knKbKindText_file => 'One document';

  @override
  String get knKbKindText_folder => 'Everything inside, kept up to date';

  @override
  String get knKbKindText_mail => 'Only if you want it';

  @override
  String get knKbKindText_url => 'Read once, again when you ask';

  @override
  String get knKbKindText_workspace => 'The files of one of your projects';

  @override
  String get knKbKind_chats => 'Conversations';

  @override
  String get knKbKind_file => 'A file';

  @override
  String get knKbKind_folder => 'A folder';

  @override
  String get knKbKind_mail => 'A mailbox';

  @override
  String get knKbKind_url => 'A web page';

  @override
  String get knKbKind_workspace => 'A project';

  @override
  String get knKbLead =>
      'Choose folders, files and pages: Rasgeth reads them, cuts them into pieces and finds them by what they mean. The agents say where each answer comes from, and one click opens the file at that point.';

  @override
  String knKbLeftOut(String n) {
    return 'Left out ($n)';
  }

  @override
  String knKbLine(String n) {
    return 'line $n';
  }

  @override
  String knKbLines(String a, String b) {
    return 'lines $a–$b';
  }

  @override
  String get knKbLoading => 'Loading…';

  @override
  String knKbLocalText(String dims, String size) {
    return 'On this computer · $size MB · $dims numbers per piece';
  }

  @override
  String get knKbMail => 'mail';

  @override
  String get knKbMake => 'Make it';

  @override
  String knKbMeaningBest(String name, String size) {
    return 'The recommended one is $name: $size MB, downloaded once, only now that you say so.';
  }

  @override
  String knKbMeaningDownload(String name, String size) {
    return 'Download $name ($size MB) and turn it on';
  }

  @override
  String get knKbMeaningOffTitle => 'Searching by meaning is off: only by words';

  @override
  String get knKbMeaningOff_downloading =>
      'The model you chose is not on this computer yet: until it arrives the search goes by words.';

  @override
  String get knKbMeaningOff_failed =>
      'The model for the meaning does not answer: the search goes by words. Choose it again or another one.';

  @override
  String get knKbMeaningOff_no_model =>
      'No model reads your documents by meaning yet, so the agents find a piece only when it has the same words they ask with.';

  @override
  String get knKbMeaningOff_no_vector =>
      'The part of the database that searches by meaning is missing on this computer: the search goes by words.';

  @override
  String get knKbMeaningOther => 'Choose another model';

  @override
  String get knKbMeaningTurnOn => 'Turn on searching by meaning';

  @override
  String knKbMeaningUse(String name) {
    return 'Use $name';
  }

  @override
  String get knKbMeaningWhy =>
      'With a model that reads by meaning, «when does the warehouse open» also finds «it opens at 7:30». It runs on this computer: your documents do not leave it.';

  @override
  String get knKbModelLead =>
      'On this computer (downloaded once, nothing leaves the house) or an online service with your key. Changing it makes a new index in the background.';

  @override
  String get knKbModelTitle => 'The model that reads by meaning';

  @override
  String get knKbNewCollection => 'New collection';

  @override
  String knKbNewIndex(String model) {
    return 'A new index for $model is being made; the searches use the old one until it is ready.';
  }

  @override
  String get knKbNoCols => 'No collection yet.';

  @override
  String get knKbNoMailboxes => 'No mailbox is connected yet: add one in Automations.';

  @override
  String get knKbNoProjects => 'There is no project yet.';

  @override
  String get knKbNoSources => 'No source yet: add a folder, a file or a page.';

  @override
  String get knKbOcrDownload => 'Download now';

  @override
  String get knKbOcrLanguages => 'Languages of your documents';

  @override
  String get knKbOcrLead =>
      'Reads photos of documents and scanned PDFs on this computer (Tesseract). Its program and languages come down the first time, a few MB.';

  @override
  String get knKbOcrOn => 'Read the text in pictures and scans';

  @override
  String get knKbOcrOnHelp => 'Slower than text: about a second a page.';

  @override
  String get knKbOcrReady => 'Ready on this computer.';

  @override
  String get knKbOcrTitle => 'Text in pictures and scans';

  @override
  String knKbOcrToDownload(String size) {
    return 'To download: about $size MB.';
  }

  @override
  String knKbOcrWaiting(String n) {
    return '$n pictures and scans are waiting for it.';
  }

  @override
  String knKbOpenCollection(String name) {
    return 'Open the collection $name';
  }

  @override
  String knKbPage(String n) {
    return 'page $n';
  }

  @override
  String get knKbPause => 'Pause the reading';

  @override
  String get knKbPauseHelp =>
      'The searches keep working; nothing new is read until you turn this off.';

  @override
  String knKbPickEmpty(String name) {
    return 'Nothing here in $name.';
  }

  @override
  String get knKbPickFile => 'Choose a file in Rasgeth';

  @override
  String get knKbPickFolder => 'Choose a folder in Rasgeth';

  @override
  String get knKbPickOther => 'Choose another';

  @override
  String get knKbPickPlaces => 'Back to the projects';

  @override
  String get knKbPickThis => 'Choose this folder';

  @override
  String get knKbPickUp => 'Up one folder';

  @override
  String get knKbPickWhere => 'Your projects and Rasgeth\'s folders';

  @override
  String get knKbPlaceAssistants => 'The assistants\' desk';

  @override
  String get knKbPlacePlatform => 'God\'s folder';

  @override
  String get knKbProv_cohere => 'Cohere';

  @override
  String get knKbProv_compatible => 'Another (like OpenAI)';

  @override
  String get knKbProv_gemini => 'Gemini';

  @override
  String get knKbProv_jina => 'Jina';

  @override
  String get knKbProv_mistral => 'Mistral';

  @override
  String get knKbProv_openai => 'OpenAI';

  @override
  String get knKbProv_voyage => 'Voyage';

  @override
  String get knKbQ => 'Your documents, for the agents to look up';

  @override
  String knKbQueueError(String error) {
    return 'Stopped for a problem: $error';
  }

  @override
  String get knKbRebuild => 'Rebuild';

  @override
  String get knKbRebuildHelp => 'Reads everything again with the same model, from the start.';

  @override
  String get knKbRebuildQ => 'Rebuild the index?';

  @override
  String get knKbRebuildText =>
      'Every piece is read again. The searches keep using the index of now until the new one is ready.';

  @override
  String get knKbRecommended => 'recommended';

  @override
  String get knKbRemove => 'Delete the collection';

  @override
  String knKbRemoveQ(String name) {
    return 'Delete $name?';
  }

  @override
  String get knKbRemoveSource => 'Remove this source';

  @override
  String get knKbRemoveText =>
      'Its pieces leave the knowledge. Your files stay where they are: nothing on the disk is touched.';

  @override
  String get knKbRerankLead =>
      'Reads the question with each piece found and reorders them: better answers, a little slower.';

  @override
  String get knKbRerankNone => 'None';

  @override
  String get knKbRerankNoneText => 'The order of the search itself';

  @override
  String knKbRerankText(String size) {
    return 'On this computer · $size MB';
  }

  @override
  String get knKbRerankTitle => 'The one that puts the best first';

  @override
  String get knKbRescan => 'Look again now';

  @override
  String get knKbSaveScope => 'Save who may read it';

  @override
  String get knKbScopeAgent => 'One agent';

  @override
  String get knKbScopeAll => 'Every agent';

  @override
  String get knKbScopeProject => 'The agents of one project';

  @override
  String get knKbSection => 'Knowledge';

  @override
  String get knKbSources => 'Sources';

  @override
  String knKbSrcChatsAll(String days) {
    return 'Your conversations, last $days days';
  }

  @override
  String knKbSrcChatsOf(String days, String names) {
    return 'The conversations with $names, last $days days';
  }

  @override
  String knKbSrcDocs(String n) {
    return '$n documents';
  }

  @override
  String knKbSrcMailOf(String days) {
    return 'The mail of the last $days days';
  }

  @override
  String knKbSrcProjectOf(String name) {
    return 'The files of $name';
  }

  @override
  String get knKbSrcState_failed => 'Could not read it';

  @override
  String get knKbSrcState_ready => 'Up to date';

  @override
  String get knKbSrcState_scanning => 'Looking';

  @override
  String get knKbSrcState_waiting => 'Waiting';

  @override
  String get knKbStateEmpty => 'Nothing to search yet: make a collection and add a folder.';

  @override
  String get knKbStateNoModel =>
      'Choose a model below to search by meaning; until then it searches by words.';

  @override
  String get knKbStateNoVector =>
      'Searching by meaning is not ready on this computer yet: for now it searches by words.';

  @override
  String get knKbStatePaused => 'Paused: the searches work, nothing new is read.';

  @override
  String knKbStateReady(String n) {
    return 'Ready: $n pieces can be searched';
  }

  @override
  String get knKbStateWorking => 'Reading your documents…';

  @override
  String knKbStatusLine(String cols, String pieces) {
    return '$cols collections · $pieces pieces';
  }

  @override
  String get knKbThreads => 'Processor threads';

  @override
  String get knKbThreadsAuto => 'automatic';

  @override
  String get knKbThreadsHelp => 'Automatic leaves most of the processor to you.';

  @override
  String get knKbThreadsTitle => 'How much of the processor';

  @override
  String knKbToDownload(String size) {
    return 'To download: $size MB';
  }

  @override
  String get knKbTryExample => 'When does the warranty end?';

  @override
  String knKbTryHow(String ms, String n) {
    return '$n pieces in $ms ms, by meaning and by words.';
  }

  @override
  String get knKbTryLead =>
      'What the agents would find for a question, best first. Click one to open it.';

  @override
  String get knKbTryNothing => 'Nothing found. Try other words.';

  @override
  String get knKbTrySearch => 'Search';

  @override
  String get knKbTryTitle => 'Try a search';

  @override
  String get knKbTryWordsOnly => 'Searched by words only (no model for the meaning yet).';

  @override
  String get knKbUploadFiles => 'Send files from this computer';

  @override
  String get knKbUploadFolder => 'Send a folder from this computer';

  @override
  String get knKbUploadSay =>
      'Or drop files here. Sent files are kept in God\'s folder, under knowledge.';

  @override
  String get knKbUploading => 'Sending the files…';

  @override
  String get knKbUrl => 'The address';

  @override
  String get knKbUrlHelp => 'Read without your logins: only public pages.';

  @override
  String get knKbWhichChats => 'Whose conversations';

  @override
  String get knKbWhichMailbox => 'Which mailbox';

  @override
  String get knKbWhichProject => 'Which project';

  @override
  String knKbWhyFailed(String error) {
    return 'It failed: $error';
  }

  @override
  String get knKbWhy_binary => 'Not a document (a program, an archive…)';

  @override
  String get knKbWhy_empty => 'There is no text in it';

  @override
  String get knKbWhy_encrypted => 'Protected by a password';

  @override
  String get knKbWhy_needs_libreoffice => 'An old Office file: it needs LibreOffice.';

  @override
  String get knKbWhy_needs_ocr =>
      'A picture or a scan: turn on reading the text in pictures, below.';

  @override
  String get knKbWhy_too_big => 'Too big to read';

  @override
  String get knKbWhy_unsupported => 'A kind of file it cannot read';

  @override
  String get knMemAdd => 'Add';

  @override
  String get knMemAddPlaceholder => 'Something to remember, e.g. I prefer short answers';

  @override
  String get knMemAlready => 'Already remembered.';

  @override
  String get knMemAutoOff =>
      'Off: Rasgeth learns nothing by itself. You can still add memories here, or ask an agent to remember something.';

  @override
  String get knMemAutoOn =>
      'After you write, Rasgeth notes what stays true about you: tastes, work, how you like answers. It reads only your own messages, never emails, web pages or automations, and never notes passwords.';

  @override
  String get knMemAutoTitle => 'Learn by itself from the conversations';

  @override
  String knMemByAgent(String name) {
    return 'Saved by $name';
  }

  @override
  String get knMemByAgentUnknown => 'Saved by an agent';

  @override
  String get knMemByAuto => 'Learned by itself';

  @override
  String get knMemByHuman => 'Written by you';

  @override
  String get knMemByImport => 'From your old notes';

  @override
  String knMemCount(String n) {
    return '$n memories';
  }

  @override
  String get knMemCountOne => '1 memory';

  @override
  String get knMemDid_added => 'Added';

  @override
  String get knMemDid_edited => 'Changed';

  @override
  String get knMemDid_forgotten => 'Forgotten for good';

  @override
  String get knMemDid_removed => 'Deleted';

  @override
  String get knMemEdit => 'Change';

  @override
  String get knMemEditTitle => 'Change the memory';

  @override
  String get knMemEmpty =>
      'Rasgeth knows nothing about you yet. Talk with an agent, or write here something to remember.';

  @override
  String get knMemEyebrow => 'Shared memory';

  @override
  String get knMemForget => 'Forget for good';

  @override
  String get knMemForgetText =>
      'Rasgeth deletes it, and its words go from the list of changes too. It can never be brought back.';

  @override
  String get knMemForgetTitle => 'Forget it for good?';

  @override
  String get knMemForgottenText => 'Its words are gone for good.';

  @override
  String knMemFrom(String title) {
    return 'from «$title»';
  }

  @override
  String get knMemFromUntitled => 'from a conversation';

  @override
  String get knMemGoShared => 'Shared memory: what Rasgeth knows about you';

  @override
  String get knMemGoSharedOpen => 'Open';

  @override
  String get knMemGoSharedText => 'Used by every agent and updated by itself while you talk.';

  @override
  String get knMemHistory => 'Recent changes';

  @override
  String get knMemHistoryLead =>
      'Every change is kept and you can take it back, except forgetting for good.';

  @override
  String get knMemHistoryLess => 'Show fewer';

  @override
  String get knMemHistoryMore => 'Show all changes';

  @override
  String get knMemLead =>
      'Every agent uses this memory, and it updates by itself while you talk. Each agent also has a memory of its own, in the agent\'s Memory tab.';

  @override
  String get knMemListLead =>
      'Changes count from the next conversation: the ones already open go on as they were.';

  @override
  String get knMemListTitle => 'What it remembers';

  @override
  String get knMemNoOwn => 'This agent keeps no memory of its own.';

  @override
  String get knMemOwnCard => 'An agent\'s own memory';

  @override
  String get knMemOwnCardQ => 'In each agent\'s Memory tab';

  @override
  String get knMemOwnCardText =>
      'Only that agent reads it. You write it, or the agent notes what it needs for its work.';

  @override
  String knMemOwnHelp(String name) {
    return 'Only $name reads it, at the start of every conversation. $name can also note here what it needs.';
  }

  @override
  String get knMemOwnPlaceholder => 'e.g. Always answer with a short list';

  @override
  String knMemOwnTitle(String name) {
    return 'Memory of $name: only for this agent';
  }

  @override
  String get knMemProjectHelp => 'Every agent working on this project reads it.';

  @override
  String knMemProjectTitle(String name) {
    return 'Memory of the project «$name»';
  }

  @override
  String get knMemRemove => 'Delete';

  @override
  String get knMemRemoved => 'Memory deleted.';

  @override
  String get knMemSaved => 'Saved';

  @override
  String get knMemSharedCard => 'Shared memory';

  @override
  String get knMemSharedCardQ => 'This page';

  @override
  String get knMemSharedCardText =>
      'Every agent reads it. It fills up by itself from your conversations, and you can change it here.';

  @override
  String get knMemSummaryTitle => 'Summaries of long conversations';

  @override
  String get knMemTitle => 'What Rasgeth knows about you';

  @override
  String get knMemUndid_added => 'Brought back';

  @override
  String get knMemUndid_edited => 'Back as it was';

  @override
  String get knMemUndid_removed => 'Taken away again';

  @override
  String get knMemUndo => 'Undo';

  @override
  String get knMemUndone => 'Undone';

  @override
  String knMemUsed(String limit, String used) {
    return 'Space used: $used of $limit characters';
  }

  @override
  String knMemWith(String name) {
    return 'with $name';
  }

  @override
  String get knSettings => 'Settings';

  @override
  String knUiAboutHours(String h, String min) {
    return 'about $h h $min min left';
  }

  @override
  String knUiAboutMinutes(String min) {
    return 'about $min min left';
  }

  @override
  String get knUiLessThanMinute => 'less than a minute left';

  @override
  String knUiOf(String done, String total) {
    return '$done of $total';
  }

  @override
  String get knUiDetails => 'Details for whoever helps you';

  @override
  String get knWzDoneBtn => 'Done';

  @override
  String get knHubKnowledge => 'Your documents the agents can search: collections, sources, models';

  @override
  String get knHubMemory => 'What every agent knows about you, with every change undoable';

  @override
  String get cvSaveFailedShort => 'Not saved';

  @override
  String get cvSaveRetry => 'Try saving again';

  @override
  String get cvReadOnly => 'Read only';

  @override
  String get cvPastePicture => 'Paste a picture';

  @override
  String get cvPasteNone => 'There is no picture on the clipboard';

  @override
  String get cvAskedAgent => 'Put in the conversation\'s message';

  @override
  String get renameNoticeTitle => 'RedGiant is now called Rasgeth.';

  @override
  String get renameNoticeText =>
      'Only the name changes: your projects, conversations, agents and keys stay as they are. Say it «RAHS-get», with a hard g.';

  @override
  String get renameNoticeOk => 'Got it';

  @override
  String noInternetNotice(String parts) {
    return 'No internet. Waiting for the network: $parts (the connection starts again by itself once it is back). Everything else works, local models included.';
  }

  @override
  String get cvGeneratingImage => 'Generating a picture…';

  @override
  String get cvGeneratingVideo => 'Making a video…';

  @override
  String get cvGeneratingAudio => 'Making a sound…';

  @override
  String get cvImageUnreadable => 'This picture cannot be opened';

  @override
  String cvImageUnreachable(String name) {
    return 'Picture not available here: $name';
  }

  @override
  String get cvMediaNativeTitle => 'Use the model\'s own tool when it has one';

  @override
  String get cvMediaNativeHelp =>
      'Some models make pictures by themselves (ChatGPT through Codex): then theirs is used, and the picture reaches you in the chat as with ours. Off: always the provider chosen here. Asking for «your tool» in a conversation always uses ours. New conversations follow this.';

  @override
  String get ptrSection => 'Portrait';

  @override
  String get ptrHub => 'How the agents see you, built from your conversations';

  @override
  String get ptrTitle => 'How the agents see you';

  @override
  String get ptrLead =>
      'This portrait builds itself from your conversations: your tastes, how you like to be spoken to, your habits, what you are working on, what to avoid. The agents you choose read it when a conversation starts. Correct it whenever you like: your word always wins.';

  @override
  String get ptrOnTitle => 'Build the portrait from the conversations';

  @override
  String get ptrOnOn =>
      'After a conversation goes quiet, a light model reads only your own messages and updates the portrait. It never notes passwords, keys, email addresses, phone numbers or things about other people. It spends a little from your budget.';

  @override
  String get ptrOnOff =>
      'Off: the portrait does not change and no agent reads it. What is here stays until you delete it.';

  @override
  String get ptrWhoTitle => 'Who reads it';

  @override
  String get ptrWhoLead =>
      'Changes count from the next conversation: the ones already open go on as they were.';

  @override
  String get ptrWho_god => 'God';

  @override
  String get ptrWho_orchestrators => 'The projects\' orchestrators';

  @override
  String get ptrWho_chat => 'The Chat';

  @override
  String get ptrWho_others => 'Every other agent';

  @override
  String get ptrListTitle => 'Traits';

  @override
  String get ptrListLead =>
      'Each trait says how sure it is and where it comes from. A trait no conversation says again fades with time.';

  @override
  String ptrCount(String n) {
    return '$n traits';
  }

  @override
  String get ptrCountOne => '1 trait';

  @override
  String get ptrEmpty => 'No traits yet: the portrait fills in as you talk with the agents.';

  @override
  String get ptrEmptyOff => 'The portrait is off and empty.';

  @override
  String get ptrAddPlaceholder => 'Add a trait yourself, e.g. I like answers with examples';

  @override
  String get ptrAdd => 'Add';

  @override
  String get ptrCat_preference => 'Preferences';

  @override
  String get ptrCat_style => 'How to talk to you';

  @override
  String get ptrCat_habit => 'Habits';

  @override
  String get ptrCat_project => 'Current projects';

  @override
  String get ptrCat_avoid => 'To avoid';

  @override
  String get ptrCat_about => 'About you';

  @override
  String get ptrSure => 'Sure';

  @override
  String get ptrLikely => 'Likely';

  @override
  String get ptrUnsure => 'Not sure yet';

  @override
  String get ptrByYou => 'Written by you';

  @override
  String ptrSeen(String n) {
    return 'seen $n times';
  }

  @override
  String get ptrSeenOnce => 'seen once';

  @override
  String get ptrWhere => 'Where it comes from';

  @override
  String get ptrUntitled => 'A conversation';

  @override
  String ptrWith(String name) {
    return 'with $name';
  }

  @override
  String get ptrEdit => 'Change';

  @override
  String get ptrRemove => 'Remove';

  @override
  String get ptrDeny => 'Not true';

  @override
  String get ptrEditTitle => 'Change the trait';

  @override
  String get ptrEditNote =>
      'Once you change it, the trait is yours: it never fades and nothing changes it by itself.';

  @override
  String ptrDenied(String n) {
    return '$n traits you said are not true: they will not be proposed again.';
  }

  @override
  String get ptrDeniedOne => '1 trait you said is not true: it will not be proposed again.';

  @override
  String get ptrTextTitle => 'What the agents read';

  @override
  String get ptrTextLead =>
      'The portrait exactly as it goes into a new conversation, short and always the same until it changes.';

  @override
  String get ptrTextShow => 'Show the text';

  @override
  String get ptrTextHide => 'Hide the text';

  @override
  String get ptrForgetTitle => 'Forget everything';

  @override
  String get ptrForgetLead =>
      'Every trait goes, and its words go from the history too. It cannot be undone.';

  @override
  String get ptrForgetText =>
      'Every trait of the portrait is deleted and its words erased from the history, the «not true» ones too. The portrait starts again empty.';

  @override
  String get ptrForget => 'Forget everything';

  @override
  String get ptrErr_empty => 'Write the trait.';

  @override
  String get ptrErr_long => 'A trait is at most 200 characters: write it shorter.';

  @override
  String get ptrErr_secret =>
      'That looks like a password, a code or a card number: secrets never go into the portrait.';

  @override
  String get ptrErr_private => 'Email addresses and phone numbers never go into the portrait.';

  @override
  String get ptrErr_gone => 'That trait is not there any more.';

  @override
  String get tkTitle => 'Tool groups';

  @override
  String get tkLead =>
      'Agents start with few tools, to keep every message light. The other groups are off by default: an agent switches one on by itself when the work needs it, for that conversation. Always on: the agent has it from the start. Off by you: the agent has to ask you.';

  @override
  String tkAgentLead(String name) {
    return 'The groups for $name: as for every agent, or a choice of its own.';
  }

  @override
  String get tkAuto => 'Off by default';

  @override
  String get tkOn => 'Always on';

  @override
  String get tkOff => 'Off by you';

  @override
  String tkAsAll(String state) {
    return 'As for everyone: $state';
  }

  @override
  String get tkIsDefault => 'default';

  @override
  String get tkRole => 'on for its role';

  @override
  String tkWeight(String n) {
    return 'about $n tokens when on';
  }

  @override
  String tkEssential(String n) {
    return 'Essential tools, always on: about $n tokens';
  }

  @override
  String tkStartTotal(String n) {
    return 'At the start: about $n tokens in every message';
  }

  @override
  String tkRest(String n) {
    return 'Off at the start: $n tokens that weigh only if a group is switched on';
  }

  @override
  String tkTools(String list) {
    return 'Tools: $list';
  }

  @override
  String get tkStateAuto => 'off by default';

  @override
  String get asMascotSub =>
      'A sub-agent has no mascot of its own: it lives for one task, and shows a ring in its parent\'s colour.';

  @override
  String get auAsstNewRoutine => 'New routine';

  @override
  String get auAutoOff => 'Switched off: it does not run until you switch it on.';

  @override
  String get auAutoOn => 'Switched on';

  @override
  String get auAutoStart => 'Start from';

  @override
  String get auAutoTitle => 'What it is called';

  @override
  String get auAutoTitleHelp => 'A short name, for you.';

  @override
  String get auAutoWhat => 'What to ask';

  @override
  String get auAutoWhatHelp =>
      'As you would write it in a chat. The answer reaches you on Telegram.';

  @override
  String get auAutoWho => 'Who does it';

  @override
  String get auAutoWhoHelp => 'God sees every project; a project\'s lead and agents only theirs.';

  @override
  String get auAutoYaml => 'The recipe (for experts)';

  @override
  String get auAutoYamlHint => 'What the form writes. Changed here, it is saved as it is.';

  @override
  String get auAutomationNotices => 'Automation messages';

  @override
  String get auAutomations => 'Automations';

  @override
  String get auAwChange => 'Change';

  @override
  String get auAwLastRun => 'Last run';

  @override
  String get auAwLead =>
      'An automation asks an agent to do something at a time or when something happens; a reminder sends you a message on a day. The lit squares are switched on.';

  @override
  String get auAwListLead =>
      'Open one to switch it on or off, run it now, change it or read how it went.';

  @override
  String get auAwListTitle => 'Your automations';

  @override
  String get auAwNewText =>
      'An agent does something for you: every morning, every week, on an email or a push.';

  @override
  String get auAwQ => 'What should Rasgeth do on its own?';

  @override
  String get auAwReminderText =>
      'A message for you on the day and at the time you choose, as you wrote it.';

  @override
  String get auAwSourcesLead => 'What automations can listen to besides the clock.';

  @override
  String get auAwSourcesTitle => 'Connections';

  @override
  String get auAwStarted => 'Started: its run appears below in a moment.';

  @override
  String get auAxAdvanced => 'Advanced';

  @override
  String get auAxAfterWhich => 'Which automation';

  @override
  String get auAxAfter_failed => 'When it failed';

  @override
  String get auAxAfter_ok => 'When it went well';

  @override
  String get auAxAfter_timeout => 'When it took too long';

  @override
  String get auAxAgentOwn => 'The agent\'s own';

  @override
  String get auAxAnyChat => 'any chat';

  @override
  String get auAxAnyProject => 'Any project';

  @override
  String get auAxApprove => 'Ask me before acting';

  @override
  String get auAxApproveHelp =>
      'You get a question here and on your chats; without your yes it does not start.';

  @override
  String get auAxBudget => 'A spending limit each time';

  @override
  String get auAxBudgetHelp => 'Past it, the agent stops.';

  @override
  String get auAxBudgetUsd => 'Dollars at most';

  @override
  String get auAxCat_other => 'Other';

  @override
  String get auAxCat_personal => 'Personal';

  @override
  String get auAxCat_social => 'Social';

  @override
  String get auAxCat_work => 'Work';

  @override
  String get auAxCondCooldown => 'A pause between one time and the next';

  @override
  String get auAxCondDates => 'Only in a period';

  @override
  String get auAxCondDays => 'Only on certain days';

  @override
  String get auAxCondFrom => 'Only from certain senders';

  @override
  String get auAxCondFromHelp => 'For emails and chat messages.';

  @override
  String get auAxCondHours => 'Only at certain hours';

  @override
  String get auAxCondMax => 'Not too many times a day';

  @override
  String get auAxCondWithout => 'Never with certain words';

  @override
  String get auAxCondWords => 'Only with certain words';

  @override
  String get auAxCooldown => 'Minutes of pause';

  @override
  String get auAxCron => 'Cron expression';

  @override
  String get auAxCronHelp =>
      'Minute, hour, day of the month, month, day of the week: 0 9 * * 1-5 is 9:00 on working days.';

  @override
  String get auAxDoes => 'What it does';

  @override
  String get auAxDoesAgent => 'An agent works';

  @override
  String get auAxDoesHelp => 'An agent does some work, or a plain message reaches you as written.';

  @override
  String get auAxDoesReminder => 'Just a message';

  @override
  String get auAxEffort => 'Effort';

  @override
  String get auAxEmailAll => 'All';

  @override
  String get auAxEmailByBox => 'Some mailboxes';

  @override
  String get auAxEmailByCategory => 'A category';

  @override
  String get auAxEmailText => 'The text contains';

  @override
  String get auAxEmailTextPlaceholder => 'A word in the email (optional)';

  @override
  String get auAxEmailWhich => 'Which mailboxes';

  @override
  String get auAxEveryMinutes => 'Every how many minutes';

  @override
  String get auAxFallback => 'Then start';

  @override
  String get auAxFilesPath => 'Folder';

  @override
  String get auAxFilesPathHelp => 'Inside the project; a dot is the whole project.';

  @override
  String get auAxFilesPattern => 'Only these files';

  @override
  String get auAxFilesPatternHelp => 'For example *.pdf; empty: every file.';

  @override
  String get auAxFilesProjectHelp => 'Make a project first: the folder is inside one.';

  @override
  String get auAxFiles_added => 'New files';

  @override
  String get auAxFiles_changed => 'Changed files';

  @override
  String get auAxFiles_removed => 'Deleted files';

  @override
  String get auAxFirstBox => 'The first mailbox';

  @override
  String get auAxFrom => 'From';

  @override
  String get auAxFromDay => 'From the day';

  @override
  String get auAxIfFails => 'If it fails';

  @override
  String get auAxKind_custom => 'Written by hand (cron)';

  @override
  String get auAxKind_minutes => 'Every few minutes';

  @override
  String get auAxKind_once => 'Once, on a day';

  @override
  String get auAxMagic => 'Magic automation';

  @override
  String get auAxMagicAllSet => 'Everything it needs is there.';

  @override
  String get auAxMagicApprove => 'Approve and create';

  @override
  String get auAxMagicAsk => 'What should happen?';

  @override
  String get auAxMagicBuilding =>
      'God is building it with you: answer its questions in the conversation.';

  @override
  String get auAxMagicDismiss => 'Put it away';

  @override
  String get auAxMagicDone => 'Approved: it is among your automations now.';

  @override
  String get auAxMagicEdit => 'Change it first';

  @override
  String get auAxMagicEx1 =>
      'Every day at 3 check my Revolut account and tell me on WhatsApp if I received or paid money';

  @override
  String get auAxMagicEx2 =>
      'When an invoice arrives in my work mailbox, save it in the project and tell me the amount';

  @override
  String get auAxMagicEx3 =>
      'When I write «shopping:» on Telegram, add it to the shopping list and send me the list on Saturday';

  @override
  String get auAxMagicExamples => 'Or start from an example';

  @override
  String get auAxMagicGo => 'Ask God';

  @override
  String get auAxMagicLead =>
      'Write what should happen, as you would say it to a person. God answers in a conversation of its own and builds the automation with you.';

  @override
  String get auAxMagicListLead => 'Built with God: open one to go on with the conversation.';

  @override
  String get auAxMagicListTitle => 'Magic automations';

  @override
  String get auAxMagicMissing => 'Before you can approve, set up what is missing:';

  @override
  String get auAxMagicNeeds => 'Still needed';

  @override
  String get auAxMagicPlaceholder =>
      'Every day at 3 check my bank account and tell me on WhatsApp what came in and what went out';

  @override
  String get auAxMagicPromise1 => 'Nothing starts without your yes.';

  @override
  String get auAxMagicPromise2 => 'New tools and skills are tried apart and wait for you.';

  @override
  String get auAxMagicPromise3 =>
      'Keys and passwords never go in the chat: God tells you where to put them.';

  @override
  String get auAxMagicProposal => 'God\'s proposal';

  @override
  String get auAxMagicReadyBadge => 'To approve';

  @override
  String get auAxMagicReject => 'Not like this';

  @override
  String get auAxMagicSendNo => 'Send to God';

  @override
  String get auAxMagicStarting => 'Calling God…';

  @override
  String get auAxMagicState_building => 'Being built';

  @override
  String get auAxMagicState_dismissed => 'Put away';

  @override
  String get auAxMagicState_done => 'Approved and created';

  @override
  String get auAxMagicState_ready => 'Ready: God waits for your yes';

  @override
  String get auAxMagicStep1 => 'You say what you want';

  @override
  String get auAxMagicStep2 => 'God proposes it';

  @override
  String get auAxMagicStep3 => 'You approve it';

  @override
  String get auAxMagicTile =>
      'Tell God what you want, in your words: it asks what it needs, builds what is missing and shows it to you before anything starts.';

  @override
  String get auAxMagicWhy => 'What is wrong? God reads it and tries again';

  @override
  String auAxMailboxesWatching(String n, String names) {
    return '$n mailboxes connected: $names.';
  }

  @override
  String get auAxMatchAll => 'All of them';

  @override
  String get auAxMatchAny => 'At least one';

  @override
  String get auAxMaxPerDay => 'At most, times a day';

  @override
  String get auAxMessageChat => 'Only in this chat';

  @override
  String get auAxMessageChatHelp => 'The chat\'s number, for a group; empty: any chat.';

  @override
  String get auAxMessageFrom => 'From whom';

  @override
  String get auAxMessageFromHelp => 'Part of the name or the number; empty: anyone linked.';

  @override
  String get auAxMessageHandle => 'The message is for the automation only';

  @override
  String get auAxMessageHandleHelp => 'Demi-God does not answer it: the automation does.';

  @override
  String get auAxMessageWhere => 'On which chats (none chosen: all of them)';

  @override
  String get auAxMessageWords => 'With which words';

  @override
  String get auAxMessageWordsPlaceholder => 'shopping, /expense';

  @override
  String get auAxMissed => 'If Rasgeth was off at its time';

  @override
  String get auAxMissedRun => 'Do it as soon as it is on';

  @override
  String get auAxMissedSkip => 'Skip it';

  @override
  String get auAxModel => 'Model';

  @override
  String get auAxModelHelp => 'Empty: the agent\'s own.';

  @override
  String get auAxNeedMissing => 'Missing';

  @override
  String get auAxNeedOpen => 'Set it up';

  @override
  String get auAxNeedReady => 'Ready';

  @override
  String get auAxNeedVault => 'Add to the keychain';

  @override
  String auAxNeed_chat(String what) {
    return 'The chat $what';
  }

  @override
  String auAxNeed_credential(String what) {
    return 'The key for $what';
  }

  @override
  String get auAxNeed_email => 'A mailbox';

  @override
  String auAxNeed_extension(String what) {
    return 'The extension $what';
  }

  @override
  String auAxNeed_other(String what) {
    return '$what';
  }

  @override
  String get auAxNextNone =>
      'With these conditions it never starts at its times: check the hours and the days.';

  @override
  String get auAxNextTimes => 'Next times';

  @override
  String get auAxNightHours => 'At night';

  @override
  String get auAxNone => 'Nothing';

  @override
  String get auAxOnceAt => 'Day and time';

  @override
  String get auAxOnly => 'Only if';

  @override
  String get auAxOnlyHelp =>
      'Conditions it must meet to start; all the ones you switch on, together. Starting it by hand ignores them.';

  @override
  String get auAxOr => 'or';

  @override
  String get auAxOverlap => 'If it is still working when it should start again';

  @override
  String get auAxOverlapQueue => 'Wait, then start';

  @override
  String get auAxOverlapSkip => 'Skip that time';

  @override
  String get auAxPick => 'Choose…';

  @override
  String get auAxRetries => 'Try again, how many times';

  @override
  String get auAxRetryMinutes => 'Minutes between tries';

  @override
  String get auAxRunQueued => 'waiting';

  @override
  String get auAxRunTriggers => 'email,chat message,files,another automation,task,startup,new try';

  @override
  String auAxSayAfter(String name) {
    return 'After «$name»';
  }

  @override
  String get auAxSayApprove => 'First it asks for your yes.';

  @override
  String auAxSayBudget(String usd) {
    return 'It spends at most \$$usd each time.';
  }

  @override
  String auAxSayCooldown(String n) {
    return 'at least $n minutes apart';
  }

  @override
  String auAxSayDates(String from, String to) {
    return 'from $from to $to';
  }

  @override
  String auAxSayDays(String days) {
    return 'on $days';
  }

  @override
  String auAxSayDoes(String who, String what) {
    return '$who does: «$what».';
  }

  @override
  String auAxSayEmail(String filter) {
    return 'When an email arrives ($filter)';
  }

  @override
  String auAxSayFiles(String path) {
    return 'When files change in $path';
  }

  @override
  String get auAxSayFilesAll => 'When files change in the project';

  @override
  String auAxSayFrom(String from) {
    return 'from $from';
  }

  @override
  String auAxSayHours(String from, String to) {
    return 'between $from and $to';
  }

  @override
  String auAxSayMax(String n) {
    return 'at most $n times a day';
  }

  @override
  String auAxSayMessage(String where) {
    return 'When you get a message on $where';
  }

  @override
  String get auAxSayNever => 'Choose when it starts.';

  @override
  String get auAxSayOnly => 'Only';

  @override
  String get auAxSayQuiet => 'It does not tell you.';

  @override
  String auAxSayReminder(String text) {
    return 'You get the message: «$text».';
  }

  @override
  String get auAxSayStartup => 'When Rasgeth starts';

  @override
  String get auAxSayTask => 'When a task ends';

  @override
  String auAxSayTell(String where) {
    return 'It tells you on $where.';
  }

  @override
  String auAxSayTellFailure(String where) {
    return 'It tells you on $where, only if something goes wrong.';
  }

  @override
  String auAxSayWith(String words) {
    return 'with «$words»';
  }

  @override
  String auAxSayWithout(String words) {
    return 'never with «$words»';
  }

  @override
  String auAxSayWordsAll(String words) {
    return 'with all of «$words»';
  }

  @override
  String auAxSayWordsAny(String words) {
    return 'with one of «$words»';
  }

  @override
  String get auAxSenders => 'Senders';

  @override
  String get auAxSendersPlaceholder => 'bank, anna@example.com, +39 333';

  @override
  String get auAxServerSays => 'Not right yet:';

  @override
  String get auAxSession => 'Each time';

  @override
  String get auAxSessionContinue => 'The same one, remembering';

  @override
  String get auAxSessionNew => 'A new conversation';

  @override
  String get auAxStart_after => 'After another automation';

  @override
  String get auAxStart_files => 'Files that change';

  @override
  String get auAxStart_message => 'A message in a chat';

  @override
  String get auAxStart_startup => 'When Rasgeth starts';

  @override
  String get auAxStart_task => 'When a task ends';

  @override
  String get auAxStart_time => 'At set times';

  @override
  String get auAxStartupHelp => 'It starts every time Rasgeth is switched on.';

  @override
  String get auAxTask_abandoned => 'Given up';

  @override
  String get auAxTask_not_testable => 'Done, not testable';

  @override
  String get auAxTask_verified => 'Done and checked';

  @override
  String get auAxTell => 'Where it tells you';

  @override
  String get auAxTellAllHelp => 'None chosen: on every chat you linked.';

  @override
  String get auAxTellAlways => 'Every time';

  @override
  String get auAxTellEmailFrom => 'Sent from';

  @override
  String get auAxTellEmailTo => 'Email to';

  @override
  String get auAxTellEmailToHelp => 'Empty: to the mailbox itself.';

  @override
  String get auAxTellFailure => 'Only if something goes wrong';

  @override
  String get auAxTellHelp => 'When it is done, where the answer goes.';

  @override
  String get auAxTellNever => 'Never';

  @override
  String get auAxTellReplyHelp => 'A run started by a chat message answers in that chat too.';

  @override
  String get auAxTellSomeHelp => 'Only where you chose.';

  @override
  String get auAxTellWhere => 'Where';

  @override
  String get auAxTimeout => 'Longest time, in minutes';

  @override
  String get auAxTo => 'To';

  @override
  String get auAxToAllChats => 'all your chats';

  @override
  String get auAxToDay => 'To the day';

  @override
  String get auAxToEmail => 'Email';

  @override
  String get auAxToWeb => 'A notice here';

  @override
  String get auAxWhen => 'When';

  @override
  String get auAxWhenHelp =>
      'What starts it. You can pick more than one: it starts on each of them.';

  @override
  String auAxWhenMinutes(String n) {
    return 'Every $n minutes';
  }

  @override
  String get auAxWithout => 'Words that stop it';

  @override
  String get auAxWithoutPlaceholder => 'newsletter, advertising';

  @override
  String get auAxWords => 'Words';

  @override
  String get auAxWordsHelp => 'Separated by commas.';

  @override
  String get auAxWordsPlaceholder => 'urgent, invoice';

  @override
  String get auAxWorkHours => 'Office hours';

  @override
  String get auAxYamlBack => 'Go back to the choices above';

  @override
  String get auCancel => 'Cancel';

  @override
  String get auCreate => 'Create';

  @override
  String get auDay_0 => 'Sunday';

  @override
  String get auDay_1 => 'Monday';

  @override
  String get auDay_2 => 'Tuesday';

  @override
  String get auDay_3 => 'Wednesday';

  @override
  String get auDay_4 => 'Thursday';

  @override
  String get auDay_5 => 'Friday';

  @override
  String get auDay_6 => 'Saturday';

  @override
  String get auDelete => 'Delete';

  @override
  String get auDeleteAutomationConfirm => 'Delete this automation and its history?';

  @override
  String get auDeliveryDelivered => 'delivered';

  @override
  String auDeliveryDeliveredTo(String to) {
    return 'delivered: $to';
  }

  @override
  String auDeliveryFailed(String reason) {
    return 'not delivered: $reason';
  }

  @override
  String get auDeliveryNoChat => 'not delivered: no chat linked';

  @override
  String get auDisabled => 'Off';

  @override
  String get auDismiss => 'Dismiss';

  @override
  String get auEmailAny => 'any';

  @override
  String get auEmailFrom => 'from';

  @override
  String get auEmailFromPlaceholder => 'From (part of the address, optional)';

  @override
  String get auEmailNeedFirst =>
      'Connect the mailbox first: until then this automation never starts.';

  @override
  String get auEmailSubject => 'Subject contains';

  @override
  String get auEmailSubjectPlaceholder => 'The subject contains (optional)';

  @override
  String auEmailWatching(String user, String host) {
    return 'Watching $user on $host.';
  }

  @override
  String get auEnabled => 'On';

  @override
  String get auNewAutomation => 'New automation';

  @override
  String get auNewReminder => 'New reminder';

  @override
  String get auNewSecret => 'New secret';

  @override
  String get auNextRun => 'next';

  @override
  String get auNoAutomations =>
      'No automations yet. Write a recipe: when it runs, which agent works, what it is asked.';

  @override
  String get auNoRuns => 'No runs yet.';

  @override
  String get auOpen => 'open';

  @override
  String get auOpenSession => 'Open the session';

  @override
  String get auProjects => 'Projects';

  @override
  String get auRecipeBroken => 'The recipe no longer reads: open it to fix it';

  @override
  String get auReminderDay => 'Day';

  @override
  String get auReminderPurpose =>
      'Rasgeth sends you this text on Telegram at the time you choose, once. No agent, no cost.';

  @override
  String get auReminderSave => 'Save the reminder';

  @override
  String get auReminderWhat => 'What to remind you of';

  @override
  String get auRepoEvent_issue_comment => 'Comments';

  @override
  String get auRepoEvent_issues => 'Issues';

  @override
  String get auRepoEvent_pull_request => 'Pull requests';

  @override
  String get auRepoEvent_push => 'New commits';

  @override
  String get auRepoEvent_release => 'Releases';

  @override
  String get auRunNow => 'Run now';

  @override
  String get auRunStatus => 'running,done,failed,timeout,skipped';

  @override
  String get auRunTriggers => 'schedule,webhook,by hand,missed run';

  @override
  String get auRuns => 'Runs';

  @override
  String get auSave => 'Save';

  @override
  String get auSettings => 'Settings';

  @override
  String get auTplDesc_blank => 'You choose when, who and what.';

  @override
  String get auTplDesc_morning => 'Every working day at 8: what happened on every project.';

  @override
  String get auTplDesc_spending => 'On the 1st of the month: what was spent and where.';

  @override
  String get auTplDesc_weekly => 'Fridays at 17: the week in one message.';

  @override
  String get auTplText_morning =>
      'Tell me in a few lines what happened yesterday on every project: work finished, problems still open, decisions to take.';

  @override
  String get auTplText_spending =>
      'Tell me how much was spent last month, per project and per agent, and whether anything looks out of the ordinary.';

  @override
  String get auTplText_weekly =>
      'Summarise this week on every project: what was finished, what is late, what is planned for next week.';

  @override
  String get auTplTitle_blank => 'From scratch';

  @override
  String get auTplTitle_morning => 'Morning briefing';

  @override
  String get auTplTitle_spending => 'Monthly spending';

  @override
  String get auTplTitle_weekly => 'The week\'s news';

  @override
  String get auWebhookSecretOnce =>
      'Secret (shown only now; send it in the x-redgiant-secret header):';

  @override
  String get auWebhookUrl => 'Webhook';

  @override
  String auWhenAt(String at) {
    return 'Once, on $at';
  }

  @override
  String get auWhenAtTime => 'at';

  @override
  String auWhenCustom(String cron) {
    return 'On a schedule of its own ($cron)';
  }

  @override
  String auWhenDaily(String time) {
    return 'Every day at $time';
  }

  @override
  String get auWhenDayOfMonth => 'on day';

  @override
  String auWhenEmail(String filter) {
    return 'When an email arrives ($filter)';
  }

  @override
  String get auWhenEmailHelp =>
      'The mailbox is set once, here or in Settings › Automations › Mailbox. The email reaches the agent as information, never as instructions.';

  @override
  String get auWhenEveryHours => 'every (hours)';

  @override
  String auWhenHours(String n) {
    return 'Every $n hours';
  }

  @override
  String get auWhenKind_daily => 'Every day';

  @override
  String get auWhenKind_email => 'On an email';

  @override
  String get auWhenKind_hours => 'Every few hours';

  @override
  String get auWhenKind_monthly => 'Once a month';

  @override
  String get auWhenKind_repo => 'On the repository';

  @override
  String get auWhenKind_webhook => 'On a web call';

  @override
  String get auWhenKind_weekdays => 'Working days';

  @override
  String get auWhenKind_weekly => 'Some days of the week';

  @override
  String auWhenMonthly(String day, String time) {
    return 'Every month on day $day at $time';
  }

  @override
  String auWhenRepo(String events) {
    return 'When something happens in the repository ($events)';
  }

  @override
  String get auWhenRepoHelp =>
      'Rasgeth adds the webhook to the project\'s repository by itself: on Gitea at once, on GitHub once access from outside home is on.';

  @override
  String get auWhenWebhook => 'When a web call arrives (webhook)';

  @override
  String get auWhenWebhookHelp =>
      'Another program (a site, a form, GitHub…) calls Rasgeth\'s address; the address and its secret appear after saving.';

  @override
  String auWhenWeekdays(String time) {
    return 'Monday to Friday at $time';
  }

  @override
  String auWhenWeekly(String days, String time) {
    return 'Every week on $days at $time';
  }

  @override
  String auWhoLead(String project) {
    return 'Lead of $project';
  }

  @override
  String get auOwnHubHint =>
      'When things happen by themselves: schedules, emails, chats, files, reminders';

  @override
  String get auOwnOpenChat => 'Open the conversation';

  @override
  String get auOwnTalkGod => 'Talk with God';

  @override
  String get auOwnMailboxesElsewhere =>
      'Mailboxes are added and changed in Settings › Channels and mailboxes.';

  @override
  String get auOwnNoMailboxes => 'No mailbox connected yet.';

  @override
  String get auOwnCopied => 'Copied';

  @override
  String get auOwnCopy => 'Copy';

  @override
  String get auOwnYamlLabel => 'The recipe in YAML';

  @override
  String get auOwnRoutineOpen => 'Open the routine';

  @override
  String get auOwnNoticeOpen => 'Open';

  @override
  String auOwnNoticeFailed(String name) {
    return '$name: not done';
  }

  @override
  String get auOwnPickTitle => 'Choose';

  @override
  String auOwnNeedOpenWhere(String where) {
    return 'Open it in Settings › $where';
  }

  @override
  String get auOwnWhereChats => 'Channels and mailboxes';

  @override
  String get auOwnWhereExtensions => 'Extensions';

  @override
  String get auOwnWhereKeychain => 'Keychain';

  @override
  String auOwnLoadFailed(String why) {
    return 'Could not read: $why';
  }

  @override
  String get auOwnReadOnly =>
      'Automations can be changed only by the person (not from a project\'s device).';

  @override
  String get cvChSecretAnyway => 'Send anyway';

  @override
  String get cvChSecretAnywayNote =>
      'Not a secret (a link, an order code)? «Send anyway» sends it as you wrote it.';

  @override
  String get echoSearch => 'Search past conversations';

  @override
  String get echoClear => 'Clear the search';

  @override
  String get echoNone => 'No past conversation has these words.';

  @override
  String get echoArchived => 'archived';

  @override
  String echoMatches(String n) {
    return '$n messages';
  }

  @override
  String get echoMatch => '1 message';

  @override
  String get echoYou => 'You';

  @override
  String get echoHint =>
      'Type at least two letters: every word is looked for in what you and the agents wrote.';

  @override
  String get skSection => 'Skills';

  @override
  String get skHub => 'The agents\' skills, their versions and the way back';

  @override
  String get skQuestion => 'What the agents learned';

  @override
  String get skLead =>
      'Skills are instructions the agents write after a job that went well, or that you give them. Each one keeps its versions: who wrote it, why and when, and you can go back to any of them.';

  @override
  String get skWaitingTitle => 'Waiting for you';

  @override
  String get skWaitingLead =>
      'New skills and new versions of installed ones, tested apart. Nothing changes until you say yes.';

  @override
  String get skNoneWaiting => 'Nothing waits for you.';

  @override
  String get skNew => 'New skill';

  @override
  String get skUpdate => 'New version of an installed skill';

  @override
  String skBy(String who) {
    return 'by $who';
  }

  @override
  String get skWhy => 'Why';

  @override
  String get skTestsOk => 'Its tests passed.';

  @override
  String skScripts(String files) {
    return 'It has scripts ($files): code never installs by itself.';
  }

  @override
  String get skApprove => 'Approve';

  @override
  String get skReject => 'Reject';

  @override
  String get skNextSession =>
      'Once installed, agents use it from their next conversation; the ones already talking keep the version they started with.';

  @override
  String get skInstalledTitle => 'Installed';

  @override
  String get skInstalledLead => 'Open one to see its versions.';

  @override
  String get skNoneInstalled => 'No skills yet.';

  @override
  String get skEverywhere => 'for every project';

  @override
  String skProject(String name) {
    return 'project $name';
  }

  @override
  String get skVersionsTitle => 'Versions';

  @override
  String get skVersionsLead => 'Agents use the newest from their next conversation.';

  @override
  String skVersion(String n) {
    return 'Version $n';
  }

  @override
  String get skCurrent => 'in use';

  @override
  String get skHow_baseline => 'As it was before the history began';

  @override
  String get skHow_edited => 'Changed by hand';

  @override
  String get skHow_install => 'First version';

  @override
  String get skHow_update => 'New version';

  @override
  String get skHow_import => 'Imported';

  @override
  String skHow_rollback(String n) {
    return 'Back to version $n';
  }

  @override
  String get skUnknown => 'author unknown';

  @override
  String get skYou => 'you';

  @override
  String get skApprovedYou => 'approved by you';

  @override
  String get skApprovedAuto => 'installed by itself (your choice in Safety)';

  @override
  String get skCompare => 'Compare with the one in use';

  @override
  String get skHideCompare => 'Hide the comparison';

  @override
  String skRollback(String n) {
    return 'Go back to version $n';
  }

  @override
  String skRollbackTitle(String n) {
    return 'Go back to version $n?';
  }

  @override
  String skRollbackText(String name) {
    return 'Its files replace those of «$name» in use, as a new version: nothing is lost and you can come back here. Agents get it from their next conversation.';
  }

  @override
  String skRolledBack(String n, String v) {
    return 'Back to version $n: it is version $v now.';
  }

  @override
  String get skNotRestorable => 'Too large to keep: it cannot come back.';

  @override
  String get skNoVersions => 'No versions yet.';

  @override
  String get skLineTitle => 'What changed and why';

  @override
  String get skCompareFull => 'Compare: every difference';

  @override
  String get cvVwKindTimeline => 'Video timeline';

  @override
  String get jobNoticeStarting => 'Starting…';

  @override
  String jobNoticePercent(int percent) {
    return '$percent% done';
  }

  @override
  String jobNoticePercentLeft(int percent, int min) {
    return '$percent% done, about $min min left';
  }

  @override
  String get jobNoticeDone => 'Done: open it in the Canvas.';

  @override
  String get jobNoticeFailed => 'It did not work.';

  @override
  String jobNoticeFailedWhy(String why) {
    return 'It did not work: $why';
  }

  @override
  String get jobNoticeCancelled => 'Stopped.';

  @override
  String saveCancelled(String name) {
    return 'Saving $name stopped';
  }

  @override
  String saveTooBigPhone(String name, String size) {
    return '$name is too big to save from the phone ($size): save it from a computer';
  }

  @override
  String get cvAllowWork => 'Always allow for this job';

  @override
  String get cvAllowWorkHint =>
      'Allow the same kind of command on the same machine without asking again, for the rest of this conversation\'s work';

  @override
  String get cvChSecretKindExport => 'a password export';

  @override
  String get cvPwOne => '1 password';

  @override
  String cvPwMany(String n) {
    return '$n passwords';
  }

  @override
  String get cvPwExportTitle => 'This is a password export';

  @override
  String cvPwExportText(String what) {
    return 'The message holds $what exported from a password manager. They do not belong in a conversation: the model, the log, the search and the engine\'s transcript would keep them.';
  }

  @override
  String get cvPwExportVault => 'Put them in the keychain';

  @override
  String get cvPwExportWithout => 'Send without';

  @override
  String get cvPwExportWithoutNote => '«Send without» sends your words with the export taken out.';

  @override
  String get cvPwExportAnyway => 'Send anyway';

  @override
  String cvPwExportAnywayTitle(String what) {
    return 'Send $what to the agent?';
  }

  @override
  String cvPwExportAnywayText(String what) {
    return '$what will reach the model and stay in the conversation\'s log, in the search and in the engine\'s transcript. Only do it if you are sure.';
  }

  @override
  String cvPwExportAnywayYes(String what) {
    return 'Send $what';
  }

  @override
  String cvPwImported(String added, String skipped) {
    return 'In the keychain: $added new, $skipped already there.';
  }

  @override
  String get cvPwImportClosed =>
      'The keychain is closed: nothing was imported. Open it in Settings › Keychain and try again.';

  @override
  String cvPwImportFailed(String error) {
    return 'Nothing was imported: $error';
  }

  @override
  String cvPwProposal(String file) {
    return 'Proposes to put the passwords of $file in your keychain.';
  }

  @override
  String get cvPwProposalButton => 'Put them in the keychain';

  @override
  String cvPwProposalAsk(String file) {
    return 'Put the passwords of $file in the keychain?';
  }

  @override
  String get cvPwProposalText =>
      'They go into your keychain without the agent seeing them; then the file is destroyed.';

  @override
  String get cvPwProposalYes => 'Import and destroy the file';

  @override
  String cvPwProposalDone(String added, String file) {
    return '$added passwords of $file are in the keychain; the file is destroyed.';
  }

  @override
  String get cvEraseForever => 'Erase for good';

  @override
  String get cvEraseTitle => 'Erase this message for good?';

  @override
  String get cvEraseText =>
      'It goes from the conversation\'s log, the search, the portrait and what the agent remembers of it. It cannot be undone.';

  @override
  String get cvEraseTextEngine =>
      'It goes from the conversation\'s log, the search, the portrait, what the agent remembers of it and the engine\'s own transcript. It cannot be undone.';

  @override
  String cvEraseQuotes(String n) {
    return 'Also erase $n of the agent\'s replies and results that quote it';
  }

  @override
  String get cvEraseYes => 'Erase for good';

  @override
  String cvEraseDone(String n) {
    return 'Erased for good ($n).';
  }

  @override
  String get cvEraseBusy =>
      'The agent is working: stop it or wait for it to finish, then try again.';

  @override
  String get pairAgain => 'Pair again';

  @override
  String get statusPairAgain => 'needs pairing again';

  @override
  String pairAgainTitle(String name) {
    return 'Pair $name again';
  }

  @override
  String pairAgainBody(String name) {
    return 'This device no longer has its key for $name. Type the password: the server stays in the list with its settings and works again.';
  }

  @override
  String get pairAgainNote =>
      'This device no longer has its key for this server: pair it again with the password, without removing it.';

  @override
  String get errKeystore =>
      'This computer could not save the access key in its keystore, so the pairing was undone and no extra device is left on the server. Try again. If it happens again, restart the computer and sign in with your password, not the PIN.';

  @override
  String get errKeystoreDetails => 'Details';

  @override
  String get devForgetUnused => 'Remove the ones never used';

  @override
  String get devForgetUnusedTitle => 'Remove the devices never used?';

  @override
  String get devForgetUnusedBody =>
      'Every device that never signed in once goes (an app that could not keep its key, for example). The ones paired in the last ten minutes stay: they may be connecting right now.';

  @override
  String devForgetUnusedDone(int count) {
    return 'Devices removed: $count.';
  }

  @override
  String get chAxCat_other => 'Other';

  @override
  String get chAxCat_personal => 'Personal';

  @override
  String get chAxCat_social => 'Social';

  @override
  String get chAxCat_work => 'Work';

  @override
  String get chAxMailboxAdd => 'Add a mailbox';

  @override
  String get chAxMailboxAddText => 'As many as you like, each in its category.';

  @override
  String get chAxMailboxAgents => 'Agents may use it';

  @override
  String get chAxMailboxAgentsHelp =>
      'They search, read and write drafts here; every email they send asks you first and shows it whole.';

  @override
  String get chAxMailboxCategory => 'Category';

  @override
  String get chAxMailboxName => 'Its name';

  @override
  String get chAxMailboxNameHelp => 'For example Work or Gmail; empty: the address.';

  @override
  String get chAxMailboxNew => 'New mailbox';

  @override
  String get chAxMailboxNewCategory => 'Or a new category';

  @override
  String get chAxMailboxNewCategoryPlaceholder => 'Family, Club, Shop…';

  @override
  String get chAxMailboxPasswordKept => 'Leave it empty to keep the one you gave.';

  @override
  String get chAxMailboxPurpose =>
      'A mailbox for the automations: only new mail is read, nothing is marked or moved.';

  @override
  String chAxMailboxesWatching(String n, String names) {
    return '$n mailboxes connected: $names.';
  }

  @override
  String get chAxSmtpHost => 'Sending server (SMTP)';

  @override
  String get chAxSmtpHostHelp => 'Only to get messages by email; empty: the usual one.';

  @override
  String get chAxSmtpPort => 'Sending port';

  @override
  String get chChatChange => 'Change the settings';

  @override
  String get chChatDiscordHow =>
      'In the Discord Developer Portal create an application, add a bot, turn on Message Content Intent, copy its token, and invite the bot to a server of yours (or write to it directly).';

  @override
  String get chChatDiscordToken => 'Bot token';

  @override
  String get chChatImHow =>
      'Apple has no iMessage service for programs: it takes a Mac that stays on, signed in to Messages, with the free BlueBubbles server. The Mac answers with its Apple ID: use one made for Rasgeth, not your own.';

  @override
  String get chChatImLimits =>
      'Without the Private API answers cannot be edited and nobody shows as typing; approvals and questions are answered with numbers. While the Mac sleeps or is off, messages wait and arrive when it wakes.';

  @override
  String get chChatImPassword => 'BlueBubbles server password';

  @override
  String get chChatImPrivate => 'BlueBubbles\' Private API is set up (edits and “typing...”)';

  @override
  String get chChatImStep1 =>
      'On the Mac make (or use) an Apple ID just for Rasgeth and sign in with it in Messages.';

  @override
  String get chChatImStep2 =>
      'Download BlueBubbles Server from bluebubbles.app, open it and choose a server password.';

  @override
  String get chChatImStep3 =>
      'When it asks, allow Full Disk Access and Accessibility in System Settings, Privacy & Security: it needs them to read and send messages.';

  @override
  String get chChatImStep4 =>
      'In BlueBubbles keep the Mac from sleeping and note its address: http://<the Mac\'s address>:1234 at home, or the address of its own tunnel from outside.';

  @override
  String get chChatImStep5 =>
      'Write the address and the password here and press Connect. From your iPhone write to the Apple ID of step 1 and send the code.';

  @override
  String get chChatImUrl => 'Address of the BlueBubbles server (http://...:1234)';

  @override
  String chChatLinked(String who) {
    return 'Linked: $who';
  }

  @override
  String get chChatMatrixE2ee =>
      'Encrypted chats: direct chats in Element are encrypted and the bot cannot read them. To keep encryption, run Pantalaimon (Matrix\'s free encryption helper) next to Rasgeth and write its address instead of the server\'s.';

  @override
  String get chChatMatrixHomeserver => 'Server address (for example https://matrix.org)';

  @override
  String get chChatMatrixHow =>
      'Rasgeth needs a Matrix account of its own, not yours: it is the one you will write to.';

  @override
  String get chChatMatrixStep1 =>
      'Make a new account for the bot, for example at app.element.io (or on your own server).';

  @override
  String get chChatMatrixStep2 =>
      'Signed in as the bot, open Settings, Help & About, Advanced, Access token, and copy it. Then close that tab without signing out: signing out cancels the token.';

  @override
  String get chChatMatrixStep3 =>
      'Write the server address and paste the token here, then press Connect.';

  @override
  String get chChatMatrixStep4 =>
      'From your own account make a new room without encryption (switch off “Enable end-to-end encryption”), invite the bot (it joins by itself) and send the code that appears.';

  @override
  String get chChatMatrixToken => 'The bot account\'s access token';

  @override
  String get chChatSendCode => 'Send this from the chat to link it:';

  @override
  String get chChatSignalHow =>
      'Signal needs signal-cli-rest-api running with a number of its own linked (a second SIM or a linked device); write its address and the number here.';

  @override
  String get chChatSignalNumber => 'The bot\'s number (+39...)';

  @override
  String get chChatSignalUrl => 'Address of signal-cli-rest-api';

  @override
  String get chChatSlackApp => 'App-level token (xapp-..., connections:write)';

  @override
  String get chChatSlackBot => 'Bot token (xoxb-...)';

  @override
  String get chChatSlackHow =>
      'At api.slack.com/apps create an app, turn on Socket Mode (no public address needed), add the scopes chat:write, im:history, app_mentions:read, files:read, files:write, subscribe to message.im and app_mention, install it and copy the two tokens.';

  @override
  String get chChatSteps => 'Step by step';

  @override
  String get chChatTeamsAppId => 'Microsoft App ID';

  @override
  String get chChatTeamsDownload => 'Download the app for Teams';

  @override
  String chChatTeamsEndpoint(String url) {
    return 'Messaging endpoint for Azure: $url';
  }

  @override
  String get chChatTeamsFiles =>
      'Files from Rasgeth arrive as a card to accept: once accepted they are saved in your OneDrive. Voice messages cannot be sent to a bot in Teams.';

  @override
  String get chChatTeamsHow =>
      'Teams talks to bots only through Microsoft Azure. You need a Microsoft 365 work or school account that may add custom apps (the free personal Teams does not allow bots), and Rasgeth reachable from outside (Settings, Remote access).';

  @override
  String get chChatTeamsSecret => 'Client secret (its Value)';

  @override
  String get chChatTeamsStep1 =>
      'Open portal.azure.com (a free account is enough), choose Create a resource, search for Azure Bot and press Create.';

  @override
  String get chChatTeamsStep2 =>
      'Give it a name, choose the Free plan (F0), Type of App: Single Tenant, Creation type: Create new Microsoft App ID. Press Create, then Go to resource.';

  @override
  String chChatTeamsStep3(String url) {
    return 'In Configuration write this Messaging endpoint and Save: $url. Copy the Microsoft App ID and the App Tenant ID.';
  }

  @override
  String get chChatTeamsStep4 =>
      'Next to Microsoft App ID press Manage Password, then New client secret, Add, and copy its Value (it is shown only once).';

  @override
  String get chChatTeamsStep5 =>
      'In Channels add Microsoft Teams, accept the terms and press Apply.';

  @override
  String get chChatTeamsStep6 =>
      'Paste the three values here and press Connect. Then download the app for Teams with the button that appears.';

  @override
  String get chChatTeamsTenant => 'App Tenant ID';

  @override
  String get chChatTeamsUpload =>
      'In Teams open Apps, Manage your apps, Upload an app, Upload a custom app, choose the file you downloaded and press Add. Then open the chat with Rasgeth and send the code.';

  @override
  String get chChatTurnOff => 'Turn off';

  @override
  String get chChatWaHow =>
      'In Meta for Developers create a WhatsApp app, copy the access token, the phone number ID and the app secret, and choose a verify token. WhatsApp sends messages to a public address: Rasgeth must be reachable from outside (Settings, Remote access).';

  @override
  String get chChatWaPhoneId => 'Phone number ID';

  @override
  String get chChatWaSecret => 'App secret';

  @override
  String get chChatWaToken => 'Access token';

  @override
  String get chChatWaVerify => 'Verify token (choose one)';

  @override
  String chChatWaWebhook(String url) {
    return 'Webhook for Meta: $url with the verify token you chose; subscribe to messages.';
  }

  @override
  String get chChats => 'Other chats';

  @override
  String get chChatsHint =>
      'Talk to Demi-God from Discord, Slack, Signal, WhatsApp, Matrix, Teams or iMessage too. It is one conversation: begun on Telegram or here, it goes on wherever you write. Approvals and questions arrive with buttons (on Signal, Matrix and iMessage, with numbers to reply).';

  @override
  String get chEmailChange => 'Change';

  @override
  String get chEmailConnect => 'Connect the mailbox';

  @override
  String chEmailConnected(String host, String user) {
    return 'Reading $user on $host.';
  }

  @override
  String get chEmailHost => 'Mail server (IMAP)';

  @override
  String get chEmailHostHelp =>
      'For example imap.gmail.com, outlook.office365.com, imap.mail.me.com.';

  @override
  String get chEmailNeedFirst =>
      'Connect the mailbox first: until then this automation never starts.';

  @override
  String get chEmailNotConnected => 'Not connected';

  @override
  String get chEmailPassword => 'Password for apps';

  @override
  String get chEmailPasswordHelp =>
      'Better an app password (Gmail, Outlook and iCloud make one in the account\'s security settings) than your own: you can revoke it at any time. It stays in a private file on your server.';

  @override
  String get chEmailPort => 'Port';

  @override
  String get chEmailPurpose =>
      'A routine can start when an email arrives (an invoice, an alert). Rasgeth looks only at new mail, every two minutes, and changes nothing in your mailbox; the email reaches the agent as information, never as instructions.';

  @override
  String get chEmailSave => 'Connect the mailbox';

  @override
  String get chEmailSecure => 'Encrypted from the start (port 993)';

  @override
  String get chEmailTesting => 'Trying the mailbox…';

  @override
  String get chEmailTileText => 'For the automations that start when an email arrives.';

  @override
  String get chEmailTitle => 'Mailbox';

  @override
  String get chEmailUser => 'Address or username';

  @override
  String chEmailWatching(String host, String user) {
    return 'Watching $user on $host.';
  }

  @override
  String get chInput => 'in';

  @override
  String get chRemove => 'Remove';

  @override
  String get chSbChatAccounts => 'Linked accounts';

  @override
  String get chSbChatDiscordText =>
      'A bot in your Discord server, in private messages or in a channel.';

  @override
  String get chSbChatImText =>
      'Through a Mac that stays on, with BlueBubbles: the Mac\'s Messages app answers.';

  @override
  String get chSbChatMatrixText =>
      'A bot account on any Matrix server (matrix.org or your own), in a chat or a room.';

  @override
  String get chSbChatNoAccount => 'No account linked yet: send the code below from the chat.';

  @override
  String get chSbChatOnWaiting => 'On: send the code from the chat';

  @override
  String get chSbChatSignalText => 'A Signal number of its own, through signal-cli-rest-api.';

  @override
  String get chSbChatSlackText =>
      'An app in your Slack workspace, in Socket Mode: no public address needed.';

  @override
  String get chSbChatTeamsText =>
      'A bot in Microsoft Teams, for work or school accounts, through a free Azure Bot.';

  @override
  String get chSbChatWaText => 'Your WhatsApp Business number, through Meta\'s Cloud API.';

  @override
  String get chSbChatWaiting => 'Waiting for the code… this window notices by itself.';

  @override
  String get chSbChatsQ => 'Talk to Demi-God from other apps too';

  @override
  String get chStTgAccounts => 'Linked accounts';

  @override
  String get chTelegram => 'Telegram';

  @override
  String get chTgChangeBot => 'Use another bot';

  @override
  String chTgLinked(String who) {
    return 'Linked to $who';
  }

  @override
  String get chTgLinkedHint =>
      'Write to your bot whenever you like: Demi-God passes it on to God and brings back the answer.';

  @override
  String chTgOpenBot(String bot) {
    return 'Open @$bot';
  }

  @override
  String get chTgQr => 'Scan with your phone\'s camera';

  @override
  String get chTgWaiting => 'Waiting for you to press Start… this page notices by itself.';

  @override
  String get chUnlink => 'Unlink';

  @override
  String get chWzConnect => 'Connect';

  @override
  String get chWzDoneBtn => 'Done';

  @override
  String get chWzLocked => 'set by the environment';

  @override
  String get chWzTgAsks => 'Here I also tell you when a yes of yours is needed.';

  @override
  String get chWzTgBf1 => 'Alright. What shall we call it?';

  @override
  String get chWzTgBf2 => 'Now a username, ending in «bot».';

  @override
  String get chWzTgBf3 => 'Done! Here is the token: 123456789:AAH…';

  @override
  String get chWzTgBfName => 'My Rasgeth';

  @override
  String get chWzTgCheck => 'Check';

  @override
  String get chWzTgChecking => 'Checking…';

  @override
  String get chWzTgDone => 'done';

  @override
  String get chWzTgExampleBot => 'my_rasgeth_bot';

  @override
  String get chWzTgHaveToken => 'I already have a token';

  @override
  String chWzTgHello(String demigod, String god) {
    return 'Hi, I\'m $demigod. Write to me whenever you like: I pass everything to $god and bring you the answer.';
  }

  @override
  String get chWzTgLater => 'later';

  @override
  String chWzTgLead(String demigod) {
    return 'With Telegram you write to $demigod from wherever you are and get the notices there: approvals, questions, long jobs, budget. Three steps, a couple of minutes.';
  }

  @override
  String chWzTgLinked(String demigod, String who) {
    return 'Linked to $who. Write to $demigod whenever you like.';
  }

  @override
  String get chWzTgLinkedShort => 'Linked. Write to your bot whenever you like.';

  @override
  String get chWzTgMessage => 'Message';

  @override
  String get chWzTgNow => 'now';

  @override
  String get chWzTgOfficial => 'Telegram\'s official bot';

  @override
  String get chWzTgOnline => 'bot · online';

  @override
  String get chWzTgOpenBf => 'Open BotFather';

  @override
  String get chWzTgPressStart => 'Press Start to begin talking with this bot.';

  @override
  String get chWzTgQ => 'Rasgeth on your phone';

  @override
  String get chWzTgStart => 'START';

  @override
  String get chWzTgStep1 => 'Make the bot with @BotFather';

  @override
  String get chWzTgStep1Text =>
      'BotFather is Telegram\'s official bot that makes bots. Write /newbot to it, give it a name and a username that ends in «bot».';

  @override
  String get chWzTgStep2 => 'Paste the token';

  @override
  String get chWzTgStep2Text =>
      'BotFather answers with a long line, like 123456789:AAH… It is the bot\'s key: keep it to yourself.';

  @override
  String get chWzTgStep3 => 'Pair the phone';

  @override
  String chWzTgStep3Text(String bot) {
    return 'Open $bot and press Start: Telegram sends it this code by itself, nothing to type.';
  }

  @override
  String get chWzTgToken => 'The bot\'s token';

  @override
  String get chWzTgYouWillSee => 'What you will see in Telegram';

  @override
  String get chWzTgYourBot => 'Your bot';

  @override
  String get chWzTgYourBotName => 'your bot';

  @override
  String get chWzTrying => 'Trying the model…';

  @override
  String get moActive => 'active';

  @override
  String get moAgentModelDefault => 'The default model';

  @override
  String get moAgents => 'Agents';

  @override
  String get moAgentsModel => 'Agent\'s model';

  @override
  String get moBackup => 'Backup';

  @override
  String get moBackupModelNone => 'None: a task given up on stays so';

  @override
  String get moBackupModelTitle => 'Backup model for tasks';

  @override
  String get moBrainChatgpt => 'ChatGPT subscription';

  @override
  String get moBrainChatgptDevice =>
      'If OpenAI says sign-in with a device code is not allowed: on chatgpt.com open Settings, Security, and turn on device code authorization, then try again.';

  @override
  String get moBrainChatgptHint =>
      'Rasgeth uses ChatGPT through OpenAI\'s official Codex program, signed in with your account. What you use counts against your plan\'s limits.';

  @override
  String get moBrainChatgptStart => 'Connect ChatGPT';

  @override
  String get moBrainChatgptStep1 => 'Open this page and sign in:';

  @override
  String get moBrainChatgptStep2 => 'Type this code there:';

  @override
  String get moBrainClaude => 'Claude subscription';

  @override
  String get moBrainClaudeCode => 'Paste the code here';

  @override
  String get moBrainClaudeHint =>
      'Rasgeth uses Claude through Anthropic\'s official program, signed in with your account. What you use counts against your plan\'s limits, not money.';

  @override
  String get moBrainClaudeOpen => 'Open Anthropic\'s sign-in page';

  @override
  String get moBrainClaudeStep2 =>
      'Sign in with your Claude account. At the end Anthropic shows a code: copy it.';

  @override
  String get moBrainConnect => 'Connect';

  @override
  String get moBrainDefault => 'The model agents use';

  @override
  String get moBrainDefaultHint =>
      'Agents use this model unless you choose another one for them. It is tried with a real question before it is saved.';

  @override
  String get moBrainDefaultSaved => 'Saved: agents will use it.';

  @override
  String get moBrainDefaultTry => 'Try and use this one';

  @override
  String get moBrainDisconnect => 'Disconnect';

  @override
  String get moBrainEffortHelp =>
      'How much it reasons before answering: low is quick and cheap, high is slower but more careful.';

  @override
  String moBrainKeyExample(String example) {
    return 'It looks like this: $example';
  }

  @override
  String moBrainKeyMake(String name) {
    return 'Create a key on $name\'s page';
  }

  @override
  String get moBrainKeyTry => 'Try and save';

  @override
  String moBrainKeyWorks(String n) {
    return 'It works: $n models available.';
  }

  @override
  String get moBrainLocal => 'A model on this computer';

  @override
  String get moBrainNoModel =>
      'No model is connected yet, so agents cannot answer. Connect one above (a subscription, a key or a local model in the next step), or later in Settings, Models and subscriptions.';

  @override
  String get moBrainNotOpened => 'Did nothing open?';

  @override
  String get moBrainOpenHere => 'Open it here';

  @override
  String get moBrainServer => 'A server of yours';

  @override
  String get moBrainServerHint =>
      'If you already run models with Ollama, LM Studio or vLLM, give Rasgeth its address.';

  @override
  String get moBrainServerKey => 'Its key';

  @override
  String get moBrainServerKeyHelp => 'Only if the server asks for one; most do not.';

  @override
  String get moBrainServerUrl => 'Server address';

  @override
  String get moBrainServerUrlHelp =>
      'With /v1 at the end. Ollama: http://localhost:11434/v1, LM Studio: http://localhost:1234/v1.';

  @override
  String get moBrainWhyText =>
      'If you already pay for Claude or ChatGPT, start with that: nothing more to pay. With a key you pay for what you use, and you can pick among many providers. A model on this computer costs nothing and keeps everything private, but it is slower and less capable than the big online ones. You can combine them: for example a subscription for hard work and a local model for small jobs.';

  @override
  String get moCatalogBuiltin => 'the one built into Rasgeth';

  @override
  String moCatalogChecked(String when) {
    return 'checked $when';
  }

  @override
  String get moCatalogDownloaded => 'downloaded and signed';

  @override
  String get moCatalogRefresh => 'Update now';

  @override
  String get moCatalogRefreshing => 'Updating…';

  @override
  String moCatalogRow(String date) {
    return 'Models catalog: updated on $date';
  }

  @override
  String get moCatalogUnreachable => 'GitHub did not answer: the catalog in use stays.';

  @override
  String get moCatalogUnsigned => 'The downloaded catalog has no valid signature: it was not used.';

  @override
  String moCatalogVersion(String n) {
    return 'version $n';
  }

  @override
  String get moChat => 'Chat';

  @override
  String get moDownloaded => 'downloaded';

  @override
  String get moDownloads => 'downloads';

  @override
  String get moEffort => 'Effort';

  @override
  String get moEffortHint =>
      'Reasoning effort: higher thinks more, is slower and costs more. From the next message.';

  @override
  String get moEffort_high => 'High';

  @override
  String get moEffort_low => 'Low';

  @override
  String get moEffort_max => 'Max';

  @override
  String get moEffort_medium => 'Medium';

  @override
  String get moError => 'Error';

  @override
  String get moFailed => 'failed';

  @override
  String get moJob_step_model_download => 'The model';

  @override
  String get moLmBeyondMemory =>
      'bigger than RAM and card together: part of it is read from the SSD at each token, slower';

  @override
  String get moLmBigChunks => 'Big chunks';

  @override
  String get moLmBigChunksHelp =>
      'Reads long messages in passes of 8,192 or 16,384 tokens instead of 4,096, when the graphics card has room for them, and loads the model in RAM when it fits with a margin: the experts go through the card once a pass, so fewer passes read faster. The first start measures them on a long message (a few minutes more) and keeps the fastest. Only for mixture-of-experts models.';

  @override
  String moLmCardDownloading(String pct) {
    return 'downloading, $pct%';
  }

  @override
  String moLmCardGet(String size) {
    return 'to download, $size';
  }

  @override
  String get moLmCardOff => 'chosen, turned off';

  @override
  String get moLmCardPaused => 'download paused';

  @override
  String get moLmCardReady => 'downloaded';

  @override
  String get moLmCardTooBig => 'too big for this computer';

  @override
  String get moLmContextTokens => 'tokens of context';

  @override
  String get moLmDelete => 'Delete';

  @override
  String get moLmDeleteActiveConfirm =>
      'This model is in use: the engine stops and the file is deleted. Go on?';

  @override
  String get moLmDiscard => 'Throw away the download';

  @override
  String moLmDownload(String size) {
    return 'Download · $size';
  }

  @override
  String get moLmDownloadedBusy => 'downloading';

  @override
  String moLmDownloadedConfirm(String name, String size) {
    return 'Delete $name? It frees $size.';
  }

  @override
  String moLmDownloadedConfirmActive(String name, String size) {
    return '$name is the model in use: the engine stops and the file is deleted ($size). Go on?';
  }

  @override
  String get moLmDownloadedEmpty => 'No model downloaded yet.';

  @override
  String moLmDownloadedHelp(String size) {
    return 'Every model file in the folder ($size in all), the biggest first. Deleting one frees its room at once; the suggested ones can be downloaded again.';
  }

  @override
  String moLmDownloadedNote(String n, String size) {
    return '$n on the disk · $size';
  }

  @override
  String get moLmDownloadedPartial => 'incomplete';

  @override
  String get moLmDownloadedTitle => 'Downloaded models';

  @override
  String get moLmEngine => 'Engine';

  @override
  String get moLmEngineHelp =>
      'Rasgeth picks the one that suits this computer. Change it only if starting fails.';

  @override
  String get moLmEngine_cpu => 'Processor';

  @override
  String get moLmEngine_cuda => 'NVIDIA graphics card (CUDA)';

  @override
  String get moLmEngine_mac => 'The Mac\'s graphics chip (Metal), next to Rasgeth';

  @override
  String get moLmEngine_vulkan => 'AMD, Intel or built-in graphics (Vulkan)';

  @override
  String get moLmEngine_windows => 'Graphics card, with Windows\' own engine (Vulkan)';

  @override
  String get moLmExperimental => 'experimental';

  @override
  String get moLmFactCache => 'Experts\' cache in the card';

  @override
  String get moLmFactRam => 'Free RAM counted';

  @override
  String get moLmFactSsd => 'From the SSD at each token';

  @override
  String moLmFactSsdGb(String gb) {
    return 'about $gb GB';
  }

  @override
  String get moLmFactSsdNone => 'nothing: it fits in RAM';

  @override
  String moLmGbPerSec(String n) {
    return '$n GB/s';
  }

  @override
  String moLmHwCpu(String max) {
    return 'No graphics card to use: models run on the processor, slower; small ones, up to about $max GB.';
  }

  @override
  String moLmHwGpu(String max, String name, String vram) {
    return '$name with $vram GB of video memory: models up to about $max GB run on it, fast.';
  }

  @override
  String get moLmHwGpuUnknown =>
      'An NVIDIA graphics card is available, but its memory is unknown: start with a small model.';

  @override
  String moLmHwIgpu(String max) {
    return 'A graphics chip built into the processor: a little faster than the processor alone; models up to about $max GB.';
  }

  @override
  String moLmHwUnreachable(String max) {
    return 'The engine cannot reach the graphics card here: models run on the processor, slower; up to about $max GB.';
  }

  @override
  String get moLmInUse => 'in use';

  @override
  String get moLmLoading => 'Looking up the models…';

  @override
  String get moLmMoePrefetch => 'Next layer ahead';

  @override
  String get moLmOff => 'Off';

  @override
  String get moLmOn => 'On';

  @override
  String get moLmOther => 'Other models in the folder';

  @override
  String moLmOtherHelp(String size) {
    return 'A model file in the folder, not among the suggested ones ($size).';
  }

  @override
  String moLmPartRamSub(String free) {
    return '$free free now';
  }

  @override
  String get moLmPartSsd => 'Models\' SSD';

  @override
  String moLmPartSsdSub(String free) {
    return '$free free';
  }

  @override
  String get moLmPause => 'Pause';

  @override
  String moLmPaused(String done, String total) {
    return 'Paused: $done of $total';
  }

  @override
  String moLmPausedAt(String done) {
    return 'Paused at $done';
  }

  @override
  String get moLmPreloadSpeed => 'Model read from the disk';

  @override
  String get moLmRecommended => 'recommended';

  @override
  String get moLmResume => 'Go on';

  @override
  String get moLmRoom => 'Room';

  @override
  String get moLmScoresHint =>
      'The bars compare these models with each other (five is the best of them). Speed is an estimate for this computer.';

  @override
  String get moLmSearch => 'Other models from Hugging Face';

  @override
  String get moLmSearchHint =>
      'Search by name, choose a repository and a file. Files that are not models are hidden.';

  @override
  String get moLmSearchPlaceholder => 'e.g. gemma, qwen, mistral';

  @override
  String get moLmShowActivation => 'Show the activation';

  @override
  String get moLmSpecDraft => 'With a small model of the family';

  @override
  String moLmSpecDraftGet(String size) {
    return 'Download the small model · $size';
  }

  @override
  String moLmSpecDraftHelp(String name, String size) {
    return '$name ($size) proposes up to 8 tokens; it stays all in the card with its own context, so the big model gets a little less room there. It only works with a model of the same family (same vocabulary): Rasgeth picks it.';
  }

  @override
  String get moLmSpecDraftReady => 'small model ready';

  @override
  String get moLmSpecHelp =>
      'Writes faster without changing the answers: something cheap proposes the next tokens and the model checks them all in one pass, reading its weights once for several tokens. It helps most where the text is predictable (code being rewritten, long dense models outside the card); on new prose it gains little. Measured on an RTX 4080 Super: Llama 3.3 70B (mostly in RAM) from 1.1 to 2.6 tokens/s on new prose and to 7.4 on code rewritten; Qwen3 14B (in the card) from 59 to 155 on code, about even on prose. The speed is shown under each answer.';

  @override
  String get moLmSpecNgram => 'From the text already written';

  @override
  String get moLmSpecNgramHelp =>
      'The proposals come from pieces of the conversation that repeat (code being edited, documents quoted back): no second model, no memory used. It helps only there: on new prose nothing, and on a large dense model little even on code (measured: Llama 3.3 70B 1.1 -> 1.3). Prefer the small model when the family has one.';

  @override
  String get moLmSpecNone => 'Off';

  @override
  String get moLmSpecTitle => 'Speculative decoding (for experts)';

  @override
  String get moLmSpeedEstimate => 'tokens/s, estimate';

  @override
  String get moLmSpeedMeasured => 'tokens/s, measured';

  @override
  String get moLmSpeedTest => 'Measure the gain';

  @override
  String get moLmSpeedTestCode => 'Code rewritten (tokens/s)';

  @override
  String get moLmSpeedTestCost =>
      'It takes a good while and a lot of compute: the model is loaded several times, minutes for a large one. Meanwhile the local model does not answer the agents.';

  @override
  String get moLmSpeedTestDone =>
      'The engine is back as it was. Choose the way above and start the model again to use it.';

  @override
  String get moLmSpeedTestIntro =>
      'Rasgeth starts this model once for each way of writing (alone, with the small model, with the n-grams), has it write a short new text and rewrite a piece of code, and shows the tokens a second of each. In the end the engine goes back to how it was.';

  @override
  String get moLmSpeedTestMode => 'Way';

  @override
  String get moLmSpeedTestProse => 'New text (tokens/s)';

  @override
  String get moLmSpeedTestStart => 'Start the test';

  @override
  String get moLmSpeedTestTitle => 'How much faster here';

  @override
  String get moLmStart => 'Start';

  @override
  String get moLmStarting => 'Starting…';

  @override
  String get moLmStream => 'SSD stream';

  @override
  String moLmStreamCache(String gb) {
    return ', $gb of the card for the experts';
  }

  @override
  String get moLmStreamFromCard => 'the model fits in the card';

  @override
  String get moLmStreamFromRam => 'the model fits in RAM: the SSD is only read at the start';

  @override
  String moLmStreamFromSsd(String gb) {
    return 'about $gb GB read from the SSD at each token';
  }

  @override
  String moLmStreamHdd(String disk) {
    return 'Not available: $disk is a spinning disk, too slow to read a model from at each token.';
  }

  @override
  String moLmStreamMaybeSsd(String disk) {
    return 'Windows does not say whether $disk is an SSD: use it only if it is.';
  }

  @override
  String moLmStreamNoRoom(String disk, String free) {
    return 'Not available: $disk has only $free free; it needs at least 20 GB.';
  }

  @override
  String moLmStreamPlan(String cache, String ctx, String ram, String source) {
    return 'In use: context up to $ctx tokens$cache, $source (counting $ram of free RAM).';
  }

  @override
  String get moLmStreamThisDisk => 'the models\' disk';

  @override
  String get moLmStreamUnknownDisk =>
      'Rasgeth does not know yet which disk holds the models (it learns at the next start of Rasgeth): use it only if it is an SSD.';

  @override
  String get moLmSysmemClose => 'Got it';

  @override
  String get moLmSysmemStep1 => 'Open the NVIDIA Control Panel (right click on the desktop).';

  @override
  String get moLmSysmemStep2 =>
      'Manage 3D settings, then Global Settings (or Program Settings with llama-server.exe, for the engine only).';

  @override
  String get moLmSysmemStep3 =>
      'CUDA - Sysmem Fallback Policy: choose «Prefer No Sysmem Fallback» and Apply.';

  @override
  String get moLmSysmemStep4 =>
      'Start the model again: the engine reads the setting when it starts.';

  @override
  String get moLmSysmemText =>
      'When the card\'s memory runs out, NVIDIA\'s driver on Windows uses the computer\'s RAM instead of failing: reading messages becomes 2 to 3.5 times slower. Rasgeth cannot read this setting, so check it once:';

  @override
  String get moLmSysmemTitle => 'NVIDIA card: turn off «CUDA Sysmem Fallback»';

  @override
  String get moLmThisPc => 'This computer';

  @override
  String moLmTokensPerSec(String n) {
    return '$n tokens/s';
  }

  @override
  String get moLmTokensUnit => 'tokens/s';

  @override
  String moLmTooBig(String max, String need) {
    return 'It needs at least $need: this computer has room for $max.';
  }

  @override
  String moLmTuneBatch(String n) {
    return 'passes of $n tokens';
  }

  @override
  String get moLmTuneCache => 'Card for the experts';

  @override
  String get moLmTuneChosen => 'kept';

  @override
  String get moLmTuneCtx => 'Context';

  @override
  String get moLmTuneFailed => 'did not start';

  @override
  String get moLmTuneHelp =>
      'Each row is a real try: the model reads a context of about 2,000 tokens and writes 64. A typical turn is an agent reading 1,500 tokens of tool results and writing 300: the fastest one is kept for this model, and you can pick another.';

  @override
  String moLmTuneLongRead(String n) {
    return 'a message of $n tokens';
  }

  @override
  String get moLmTuneNoCopy => 'experts computed on the processor when reading';

  @override
  String get moLmTuneRead => 'Reading (tok/s)';

  @override
  String get moLmTuneRunning => 'measuring…';

  @override
  String get moLmTuneTitle => 'Tuning on this computer';

  @override
  String get moLmTuneTurn => 'Typical turn (s)';

  @override
  String get moLmTuneUse => 'Use';

  @override
  String get moLmTuneWrite => 'Writing (tok/s)';

  @override
  String get moLmUnavailable => 'Hugging Face does not answer: try again later.';

  @override
  String get moLmUseForAgents => 'Use it for the agents';

  @override
  String get moLmUsedForAgents => 'The agents will use this model.';

  @override
  String get moLmVersionSuggested => 'suggested';

  @override
  String get moLmVersions => 'Version of the file';

  @override
  String get moLmWarmHelp =>
      'The model reads its first context and writes a few words. The first time on a new graphics card this takes minutes: the card prepares its programs once, and then it is fast.';

  @override
  String get moLmWarmSpeed => 'Context read (as a first message)';

  @override
  String get moLmWhere => 'Where the model goes';

  @override
  String get moLoading => 'Loading…';

  @override
  String get moModelHint => 'The model of this conversation (agents\' models: Settings, Agents)';

  @override
  String get moModelNew => 'new';

  @override
  String get moModelPick => 'Choose a model';

  @override
  String get moModelSearch => 'Search a model';

  @override
  String get moModelUnconfirmed => 'data to be confirmed';

  @override
  String get moModelWay => 'How it goes';

  @override
  String get moMpChange => 'Change';

  @override
  String get moMpLead =>
      'Pick one or more ways: combine them as you like. Each square opens its window; the lit ones are connected.';

  @override
  String get moMpLocalLead =>
      'Free, and nothing leaves here: the computer, where the models are, the models to download and the ones already on the disk.';

  @override
  String get moMpNoDefault => 'No model chosen';

  @override
  String get moMpNoDefaultText => 'Connect a way above, then choose the one agents use.';

  @override
  String get moMpSearchLead =>
      'How agents look things up on the internet. One provider at a time: the lit one is in use.';

  @override
  String get moMpSearchTitle => 'Web search';

  @override
  String get moSearch => 'Search';

  @override
  String get moSearchInUse => 'in use';

  @override
  String get moSubsDeviceWait => 'This page notices by itself when you are done.';

  @override
  String moSubsLoggedAs(String plan, String who) {
    return 'Signed in: $who $plan';
  }

  @override
  String moSubsProgramDownload(String name) {
    return '$name is downloaded when you switch this on (once, a few hundred MB, with its bar in the corner).';
  }

  @override
  String moSubsProgramSystem(String name) {
    return '$name is already installed on this computer: Rasgeth uses it.';
  }

  @override
  String moSubsSharedLogin(String name) {
    return '$name is already signed in on this computer: Rasgeth uses that sign-in as it is, no need to sign in again.';
  }

  @override
  String get moSubsUseShared => 'Use the sign-in already here';

  @override
  String get moSubscriptions => 'Models and subscriptions';

  @override
  String moTermsOf(String name) {
    return '$name\'s terms';
  }

  @override
  String moUiAboutHours(String h, String min) {
    return 'about $h h $min min left';
  }

  @override
  String moUiAboutMinutes(String min) {
    return 'about $min min left';
  }

  @override
  String get moUiDropNone => 'Nothing matches.';

  @override
  String get moUiLessThanMinute => 'less than a minute left';

  @override
  String get moUiNotNeeded => 'not needed';

  @override
  String moUiOf(String done, String total) {
    return '$done of $total';
  }

  @override
  String get moViaLocal => 'local';

  @override
  String get moViaSubscription => 'subscription';

  @override
  String get moWzAgents => 'Agents';

  @override
  String get moWzAgentsSub => 'they do the work';

  @override
  String get moWzAgentsText =>
      'They get their tasks from the orchestrators: they write code, test, search.';

  @override
  String get moWzAlreadySet => 'already set';

  @override
  String get moWzAssign => 'Who uses which model';

  @override
  String get moWzAssignChat => 'The everyday chat, with web search: questions, texts, ideas.';

  @override
  String get moWzAssignConnect => 'Connect a model';

  @override
  String get moWzAssignDemigod2 =>
      'Answers you on Telegram and in the chats, and passes the work on: a fast model is enough.';

  @override
  String get moWzAssignEmpty =>
      'You have not connected any model yet, so there is nothing to choose here. Connect one in «How should Rasgeth think?» or start a local model.';

  @override
  String get moWzAssignGod =>
      'The one who runs everything: plans, projects, other agents. The strongest model pays off here.';

  @override
  String get moWzAssignLead =>
      'Each one works with its own model: the strongest for who decides, a fast one for who answers. Touch a model to change it.';

  @override
  String get moWzAssignLocal => 'Choose a local model';

  @override
  String get moWzAssignOthers => 'The agents you create later';

  @override
  String get moWzAssignOthersHelp =>
      'And the board\'s summaries, unless you choose one for them. It is tried with a real question before it is saved.';

  @override
  String get moWzAssistants => 'Personal assistants';

  @override
  String get moWzAssistantsSub => 'they work for you';

  @override
  String get moWzBackupText =>
      'If an agent gives up on a task (an error, the budget, no check passed), this model tries it once more, knowing what the first one did. Best from another provider.';

  @override
  String get moWzBackupWindow => 'Tries the tasks given up on once more, in a new conversation.';

  @override
  String get moWzBrain => 'How should Rasgeth think?';

  @override
  String get moWzBrainChatgpt =>
      'Your ChatGPT Plus or Pro plan. You type a short code on OpenAI\'s page.';

  @override
  String get moWzBrainClaude => 'Your Claude Pro or Max plan. You sign in on Anthropic\'s page.';

  @override
  String get moWzBrainKeys =>
      'Anthropic, OpenAI, Gemini, Mistral, DeepSeek, Grok and more. You pay for what you use.';

  @override
  String get moWzBrainKeysTitle => 'An API key';

  @override
  String get moWzBrainLocal =>
      'Free and private: nothing leaves this computer. You choose it in the next step.';

  @override
  String get moWzBrainQ => 'How should Rasgeth think?';

  @override
  String get moWzBrainServer =>
      'Ollama, LM Studio, vLLM or another server that speaks OpenAI\'s language.';

  @override
  String get moWzChosen => 'chosen';

  @override
  String get moWzDefaultModel => 'Default model';

  @override
  String get moWzDemiRole => 'The spokesperson';

  @override
  String moWzDense(String b) {
    return '$b billion · dense';
  }

  @override
  String get moWzDiskHdd => 'A spinning disk: too slow for the models.';

  @override
  String get moWzDisksLead =>
      'A model takes from 3 to 80 GB. A fast SSD is best: Deep Field reads from there.';

  @override
  String get moWzDisksNoMove =>
      'The models can be moved to another disk only in Rasgeth\'s Windows installation.';

  @override
  String get moWzDisksOne =>
      'Here the models stay in Rasgeth\'s data folder. In Rasgeth\'s Windows installation you can move them to another SSD.';

  @override
  String get moWzDisksTitle => 'Where the models stay';

  @override
  String get moWzDoneBtn => 'Done';

  @override
  String get moWzEffortHelp =>
      'A little is fast and cheap, deeply is slower but more careful. It stays fixed for each conversation.';

  @override
  String get moWzEffortTitle => 'How much it thinks before answering';

  @override
  String get moWzEffort_high => 'Deeply';

  @override
  String get moWzEffort_low => 'A little';

  @override
  String get moWzEffort_max => 'The most';

  @override
  String get moWzEffort_medium => 'Just right';

  @override
  String get moWzFitNone => 'None runs fast enough here: the ones below work, slowly.';

  @override
  String get moWzFitTab => 'Suited';

  @override
  String get moWzFitTitle => 'Suited to this computer';

  @override
  String moWzFitsUpTo(String max) {
    return 'Models up to about $max run fast here; bigger ones use the RAM too.';
  }

  @override
  String get moWzFolder => 'Folder';

  @override
  String get moWzFolderHelp => 'A folder of this disk; it is created if it is not there.';

  @override
  String get moWzFolderLead =>
      'Where Rasgeth keeps the models\' files on this disk. The ones already downloaded are copied there.';

  @override
  String moWzFolderTitle(String disk) {
    return 'The models\' folder on $disk';
  }

  @override
  String get moWzFree => 'free';

  @override
  String moWzFreeOf(String total) {
    return 'free of $total GB';
  }

  @override
  String get moWzGodRole => 'The boss';

  @override
  String get moWzHereNow => 'here now';

  @override
  String get moWzHowItWorks => 'How it works';

  @override
  String moWzKeyOf(String name) {
    return 'The key of $name';
  }

  @override
  String get moWzKeysLead =>
      'A key is like a password that lets Rasgeth use the provider\'s models on your account. You pay the provider for what you use. Add as many as you like: each one is tried at once.';

  @override
  String moWzLegend(String n) {
    return 'Green outline: it runs on this computer between the graphics card and the RAM, at least $n tokens a second. The others work, but slowly.';
  }

  @override
  String moWzLikeAbove(String who) {
    return 'The same as $who';
  }

  @override
  String get moWzLocal => 'Local model';

  @override
  String get moWzLocalQ => 'A model on this computer';

  @override
  String get moWzLocked => 'set by the environment';

  @override
  String moWzMoe(String b) {
    return '$b billion · mixture of experts';
  }

  @override
  String get moWzMoreModels => 'Other files and searches';

  @override
  String get moWzMoveHere => 'Move them here';

  @override
  String moWzMoveLead(String folder, String free, String kind) {
    return '$kind, $free free. The models already downloaded are copied to $folder; the model in use starts again afterwards.';
  }

  @override
  String moWzMoveTitle(String disk) {
    return 'Move the models to $disk?';
  }

  @override
  String moWzNModels(String n) {
    return '$n models';
  }

  @override
  String get moWzNone => 'None';

  @override
  String get moWzOfRamLong => 'of RAM';

  @override
  String get moWzOrchestrators => 'Orchestrators';

  @override
  String get moWzOrchestratorsSub => 'the heads of the projects';

  @override
  String get moWzOrchestratorsText =>
      'One per project: splits the work and hands it to the agents.';

  @override
  String get moWzPickFolder => 'Choose folder';

  @override
  String get moWzPickModel => 'Choose the model';

  @override
  String get moWzPickRepo => 'Choose a repository';

  @override
  String get moWzProvider => 'Provider';

  @override
  String get moWzRemove => 'Remove';

  @override
  String get moWzSlowTab => 'Slow here';

  @override
  String get moWzSlowTitle => 'They work, but slowly';

  @override
  String moWzStateKey(String name) {
    return '$name: connected';
  }

  @override
  String moWzStateKeys(String n) {
    return '$n keys connected';
  }

  @override
  String get moWzStateLinked => 'connected';

  @override
  String moWzStateLocal(String model) {
    return '$model, in use';
  }

  @override
  String get moWzStateLocalNext => 'you choose it in the next step';

  @override
  String moWzStateServer(String url) {
    return 'connected: $url';
  }

  @override
  String get moWzStreamInfo1 =>
      'For models bigger than the graphics card, and for a much longer context.';

  @override
  String get moWzStreamInfo2 =>
      'The parts of the model used most stay in the card and in RAM; the rest is read from the SSD when needed. It works best with mixture-of-experts models; dense ones work, but slower.';

  @override
  String get moWzStreamInfo3 =>
      'At the first start Rasgeth measures this computer and keeps the fastest tuning. It needs an SSD with at least 20 GB free: a spinning disk is too slow.';

  @override
  String get moWzStreamOff => 'Off: only the models that fit in the card and the RAM run.';

  @override
  String moWzStreamOn(String disk) {
    return 'On: models bigger than the card and the RAM read the rest from the SSD ($disk) when needed. Slower, but they run.';
  }

  @override
  String get moWzSubscription =>
      'I know that using a personal subscription (instead of an API key) in a third-party tool may not be allowed by the provider\'s terms.';

  @override
  String get moWzTrying => 'Trying the model…';

  @override
  String get moWzUnderstood => 'Got it';

  @override
  String get moWzUseFolder => 'Use this folder';

  @override
  String moWzVram(String gb) {
    return '$gb of video memory';
  }

  @override
  String get moWzWhich => 'Which one should I pick?';

  @override
  String get chUiAdvanced => 'Advanced';

  @override
  String moJob_engine(String model) {
    return 'Starting $model';
  }

  @override
  String moJob_engine_load(String model) {
    return 'Loading $model';
  }

  @override
  String get moJob_error_bad_file => 'This is not a model file of Hugging Face.';

  @override
  String get moJob_error_checksum =>
      'The download arrived damaged (its fingerprint does not match): try again.';

  @override
  String get moJob_error_engine_stopped =>
      'The engine stopped by itself. The details below say why.';

  @override
  String get moJob_error_incomplete =>
      'The download stopped before the end: press Go on to continue from where it stopped.';

  @override
  String get moJob_error_load_timeout =>
      'The model did not load within 15 minutes. Try a smaller one.';

  @override
  String get moJob_error_model_missing =>
      'The model file is not in the folder any more. Download it again.';

  @override
  String get moJob_error_no_gpu =>
      'The engine cannot see the graphics card. Update the card\'s drivers and restart the computer, or choose the processor under Advanced.';

  @override
  String get moJob_error_out_of_memory =>
      'There is not enough memory for this model. Choose a smaller model, or the same one in a lower quality.';

  @override
  String moJob_model_download(String model) {
    return 'Downloading $model';
  }

  @override
  String moJob_speed_test(String model) {
    return 'Measuring $model';
  }

  @override
  String get moJob_step_draft => 'With the small model';

  @override
  String get moJob_step_image => 'Downloading the engine (only once)';

  @override
  String get moJob_step_load => 'Loading the model into memory';

  @override
  String get moJob_step_ngram => 'With the n-grams';

  @override
  String get moJob_step_none => 'The model alone';

  @override
  String get moJob_step_preload =>
      'Reading the model once, so the first message does not wait for the disk';

  @override
  String get moJob_step_start => 'Starting the engine';

  @override
  String get moJob_step_try => 'Trying an answer';

  @override
  String get moJob_step_tune => 'Measuring this computer to pick the fastest setting';

  @override
  String get moLmQuality_good => 'good quality';

  @override
  String get moLmQuality_high => 'high quality';

  @override
  String get moLmQuality_reduced => 'reduced quality, to fit';

  @override
  String get moLmScore_code => 'Programming';

  @override
  String get moLmScore_languages => 'Other languages';

  @override
  String get moLmScore_smart => 'Intelligence';

  @override
  String get moLmScore_speed => 'Speed here';

  @override
  String get moLmScore_tools => 'Tools';

  @override
  String get moLmSpeedMode_draft => 'With the small model';

  @override
  String get moLmSpeedMode_ngram => 'N-grams';

  @override
  String get moLmSpeedMode_none => 'Model alone';

  @override
  String get chHubTelegram =>
      'Demi-God on Telegram: the bot, its token and the accounts that talk to it';

  @override
  String get chHubChats =>
      'Demi-God on Discord, Slack, Signal, WhatsApp, Matrix, Teams and iMessage';

  @override
  String get moHubModels =>
      'Subscriptions, API keys, your own server, the model on this computer and who uses which';

  @override
  String get xtAddServer => 'Add server';

  @override
  String get xtApprove => 'Approve';

  @override
  String get xtArgs => 'Arguments';

  @override
  String get xtAxMagicDismiss => 'Put it away';

  @override
  String get xtAxMagicExamples => 'Or start from an example';

  @override
  String get xtAxMagicGo => 'Ask God';

  @override
  String get xtAxMagicReject => 'Not like this';

  @override
  String get xtAxMagicSendNo => 'Send to God';

  @override
  String get xtAxMagicStarting => 'Calling God…';

  @override
  String get xtAxMagicWhy => 'What is wrong? God reads it and tries again';

  @override
  String get xtAxNeedMissing => 'Missing';

  @override
  String get xtAxNeedReady => 'Ready';

  @override
  String get xtAxNeedVault => 'Add to the keychain';

  @override
  String get xtBy => 'by';

  @override
  String get xtCancel => 'Cancel';

  @override
  String get xtCommand => 'Command';

  @override
  String get xtCopied => 'Copied';

  @override
  String get xtCopy => 'Copy';

  @override
  String get xtCreate => 'Create';

  @override
  String get xtDescription => 'Description';

  @override
  String get xtExtAdd => 'Add';

  @override
  String get xtExtAddAndConnect => 'Add and connect';

  @override
  String get xtExtAdded => 'Added';

  @override
  String xtExtAppConsole(String name) {
    return 'Open $name\'s developer page';
  }

  @override
  String xtExtAppGuide(String name) {
    return 'Create your own app on $name (once, about ten minutes)';
  }

  @override
  String get xtExtAskHelp =>
      'Ask God with a magic integration or extension, in your own words: God looks for a ready service in the catalog, or writes a new ability, tests it and asks you before installing anything.';

  @override
  String get xtExtAskTitle => 'What should your agents be able to do?';

  @override
  String get xtExtAuth_app => 'Your own app, with a guide';

  @override
  String get xtExtAuth_header => 'Needs a key';

  @override
  String get xtExtAuth_none => 'Nothing to sign in to';

  @override
  String get xtExtAuth_oauth => 'Sign in on its page';

  @override
  String get xtExtBroken => 'Not working';

  @override
  String get xtExtBrokenHelp =>
      'A service that does not work: check the key, or remove it and add it again. Hover over the label to see the error.';

  @override
  String get xtExtCatAll => 'All';

  @override
  String get xtExtCat_cloud => 'Cloud';

  @override
  String get xtExtCat_code => 'Code';

  @override
  String get xtExtCat_data => 'Data';

  @override
  String get xtExtCat_design => 'Design';

  @override
  String get xtExtCat_docs => 'Documentation';

  @override
  String get xtExtCat_home => 'Home';

  @override
  String get xtExtCat_web => 'Web';

  @override
  String get xtExtCat_work => 'Work';

  @override
  String get xtExtCatalog => 'Services you can add';

  @override
  String get xtExtCatalogHelp =>
      'Each one gives your agents new tools. The services\' own ones come first; the community ones are made by others.';

  @override
  String get xtExtChecking => 'Checking…';

  @override
  String get xtExtClientId => 'Client ID of your app';

  @override
  String get xtExtClientSecret => 'Client secret of your app';

  @override
  String get xtExtClientSecretOptional => 'Client secret of your app (if it has one)';

  @override
  String get xtExtCommunity => 'Community';

  @override
  String get xtExtConnect => 'Connect';

  @override
  String get xtExtConnected => 'Your services';

  @override
  String get xtExtEverywhere => 'Everywhere';

  @override
  String xtExtGuide(String name) {
    return 'How to set up $name';
  }

  @override
  String xtExtKey(String name) {
    return '$name key';
  }

  @override
  String get xtExtKeyHelp =>
      'It is kept in a private file on your server and never shown again, not even to the agents.';

  @override
  String xtExtKeyWhere(String name) {
    return 'Where do I find the $name key?';
  }

  @override
  String get xtExtKindSkill => 'Skill';

  @override
  String get xtExtKindTool => 'Tool';

  @override
  String get xtExtManualOauth => 'It signs in on its own page (OAuth)';

  @override
  String get xtExtManualToken => 'Key (optional, sent as Bearer)';

  @override
  String get xtExtMore => 'More about it';

  @override
  String get xtExtNeedsLogin => 'Needs you to sign in';

  @override
  String get xtExtNothingFound =>
      'Nothing found. Ask God with the magic extension above: it can write what is missing.';

  @override
  String xtExtOauthHelp(String name) {
    return 'A new tab opens on $name\'s page: sign in there and allow Rasgeth. Then come back here.';
  }

  @override
  String get xtExtOfficial => 'Official';

  @override
  String xtExtOnlyProject(String name) {
    return 'Only in $name';
  }

  @override
  String get xtExtProposals => 'Waiting for you';

  @override
  String get xtExtProposalsHelp =>
      'Abilities written by the agents and already tested: nothing is installed until you approve it.';

  @override
  String get xtExtSearch => 'Search a service';

  @override
  String xtExtServerUrl(String name) {
    return '$name\'s address';
  }

  @override
  String get xtExtServerUrlHelp =>
      'As Rasgeth\'s server reaches it, for example on your home network.';

  @override
  String get xtExtSkills => 'Skills and tools';

  @override
  String get xtExtSkillsHelp =>
      'Abilities installed for your agents. Click one to read or change it.';

  @override
  String get xtExtTransport => 'How it runs';

  @override
  String get xtExtTransportHttp => 'Online (address)';

  @override
  String get xtExtTransportStdio => 'On this server (command)';

  @override
  String get xtExtUnverified =>
      'Not confirmed on the service\'s own pages: if something does not match, its documentation is right.';

  @override
  String get xtExtUnverifiedShort => 'to be checked';

  @override
  String get xtExtWhere => 'Where it works';

  @override
  String get xtExtWhereHelp => 'Everywhere, or only for the agents of one project.';

  @override
  String xtExtWorks(String n) {
    return 'Works · $n tools';
  }

  @override
  String get xtExtensions => 'Extensions';

  @override
  String get xtFailedTests => 'Failed its tests';

  @override
  String get xtInstructions => 'Instructions';

  @override
  String get xtMediaGetKey => 'Get a key';

  @override
  String get xtMediaHasKey => 'key already there';

  @override
  String xtMediaKey(String name) {
    return '$name key';
  }

  @override
  String xtMediaKeyLinked(String name) {
    return '$name key linked';
  }

  @override
  String xtMediaKeyStep1(String name) {
    return 'Open the $name page where keys are made and sign in (or create an account).';
  }

  @override
  String get xtMediaKeyStep2 => 'Create a new key and copy it.';

  @override
  String get xtMediaKeyStep3 => 'Paste it here and save:';

  @override
  String get xtMediaNativeHelp =>
      'Some models make pictures by themselves (ChatGPT through Codex): then theirs is used, and the picture reaches you in the chat as with ours. Off: always the provider chosen here. Asking for «your tool» in a conversation always uses ours. New conversations follow this.';

  @override
  String get xtMediaNativeTitle => 'Use the model\'s own tool when it has one';

  @override
  String get xtMediaNeedsKey => 'Needs its key';

  @override
  String get xtMediaOff => 'Off';

  @override
  String get xtMediaOtherProvider => 'Choose another provider';

  @override
  String get xtMediaPurpose =>
      'Who makes pictures, videos, voices, music and sound effects when an agent is asked for one (the tools image_generation, video_generation and audio_generation). Choose a provider and a model for each, and paste its key: a key you already gave for the chat (OpenAI, Gemini, xAI) works here too. They are paid by the provider for what you make.';

  @override
  String get xtMediaStep1 => '1. Who makes it';

  @override
  String xtMediaStep2(String name) {
    return '2. The $name key';
  }

  @override
  String get xtMediaTitle => 'Default extensions';

  @override
  String get xtMediaTurnOff => 'Turn off';

  @override
  String get xtMediaVoice => 'Voice';

  @override
  String get xtMediaVoiceFirst => 'The account\'s first one';

  @override
  String get xtMedia_image => 'Pictures';

  @override
  String get xtMedia_image_help =>
      'Drawings, photos, illustrations, logos from a description (or from a picture).';

  @override
  String get xtMedia_music => 'Music';

  @override
  String get xtMedia_music_help => 'Songs and pieces from a description, with or without singing.';

  @override
  String get xtMedia_sound => 'Sound effects';

  @override
  String get xtMedia_sound_help =>
      'Short sounds from a description: a door, rain, a crowd, an engine.';

  @override
  String get xtMedia_speech => 'Voice';

  @override
  String get xtMedia_speech_help => 'A text read aloud, with the voice you choose.';

  @override
  String get xtMedia_video => 'Videos';

  @override
  String get xtMedia_video_help =>
      'Short clips from a description or from a first frame. They take minutes and cost more. (OpenAI closed Sora in September 2026.)';

  @override
  String get xtModel => 'Model';

  @override
  String get xtMxApprove => 'Approve and install';

  @override
  String get xtMxArgs => 'Arguments:';

  @override
  String get xtMxBadgeApprove => 'To install';

  @override
  String get xtMxBadgeInstalled => 'Installed';

  @override
  String get xtMxBadgeMissing => 'Something missing';

  @override
  String get xtMxBuilding =>
      'God is building it with you: answer its questions in the conversation.';

  @override
  String get xtMxChange => 'Change it';

  @override
  String get xtMxChangeGo => 'Ask God';

  @override
  String get xtMxChangeLabel =>
      'What should change? God proposes it again and you install it as before.';

  @override
  String get xtMxChanging =>
      'God is changing it with you; what is installed keeps working until you approve the new version.';

  @override
  String xtMxCheckHost(String what) {
    return 'The address $what';
  }

  @override
  String xtMxCheckKey(String what) {
    return 'The key for $what';
  }

  @override
  String xtMxCheckKeyUndeclared(String what) {
    return 'The key $what, used by the code but not declared';
  }

  @override
  String xtMxCheckTest(String what) {
    return 'The test of $what';
  }

  @override
  String get xtMxCode => 'Read the code';

  @override
  String get xtMxDone => 'Installed: every agent has these tools from its next conversation.';

  @override
  String get xtMxExtension => 'Magic extension';

  @override
  String get xtMxExtensionAsk => 'What should the agents be able to do?';

  @override
  String get xtMxExtensionEx1 => 'Turn a CSV into a chart and tell me the totals';

  @override
  String get xtMxExtensionEx2 => 'Check that an Italian VAT number and tax code are valid';

  @override
  String get xtMxExtensionEx3 => 'A skill for writing my weekly report the way I like it';

  @override
  String get xtMxExtensionLead =>
      'Tell God what the agents should be able to do. God asks, writes tools and skills with their tests and tries them in a closed sandbox: you see the result and install it with one button.';

  @override
  String get xtMxExtensionPlaceholder =>
      'For example: turn a CSV into a chart and tell me the totals';

  @override
  String get xtMxExtensionTile =>
      'New abilities for the agents, of any kind: God writes the tools and skills, tests them apart and you install them.';

  @override
  String get xtMxGiveKey => 'Give it to these tools';

  @override
  String xtMxGiveKeyText(String hosts, String tools) {
    return 'Only these tools will receive it, through the proxy, and only towards $hosts: $tools.';
  }

  @override
  String xtMxGiveKeyTitle(String what) {
    return 'Give $what to this package?';
  }

  @override
  String get xtMxIntegration => 'Magic integration';

  @override
  String get xtMxIntegrationAsk => 'Which service, and what for?';

  @override
  String get xtMxIntegrationEx1 => 'Connect me to Notion: search my pages and create new ones';

  @override
  String get xtMxIntegrationEx2 =>
      'Connect me to my management software\'s API (invoices and customers)';

  @override
  String get xtMxIntegrationEx3 => 'Read my Todoist tasks and mark them done';

  @override
  String get xtMxIntegrationLead =>
      'Tell God which service and what the agents should do with it. God asks what it needs, writes the connector with its tests and tries it in a closed sandbox: you see the result and install it with one button.';

  @override
  String get xtMxIntegrationPlaceholder =>
      'For example: connect me to Notion so the agents can search my pages and add notes';

  @override
  String get xtMxIntegrationTile =>
      'Connect Rasgeth to a service through its API (Notion, your management software, a bank…): God writes the connector, tests it apart and you install it.';

  @override
  String get xtMxKeyHosts => 'It may go only to:';

  @override
  String get xtMxKeyLead =>
      'Paste the key here: it goes straight into your keychain, encrypted. Nobody reads it, God included; the tools receive it only through the proxy.';

  @override
  String get xtMxKeyName => 'Name in the keychain:';

  @override
  String get xtMxKeyOnly =>
      'Used only by this package\'s tools; you can change it in Settings > Keychain.';

  @override
  String get xtMxKeySave => 'Save in the keychain';

  @override
  String xtMxKeyTitle(String service) {
    return 'Key for $service';
  }

  @override
  String get xtMxKeyValue => 'The key';

  @override
  String get xtMxKeys => 'Keys';

  @override
  String get xtMxListLead =>
      'Built with God: open one to go on with the conversation, install it, change it or remove it.';

  @override
  String get xtMxListTitle => 'Magic integrations and extensions';

  @override
  String get xtMxMissing => 'Before you can install it, this is missing:';

  @override
  String get xtMxParts => 'What it adds';

  @override
  String get xtMxPromise1 => 'Nothing is installed without your yes.';

  @override
  String get xtMxPromise2 =>
      'Every part is tested in a closed sandbox that reaches only the services it declares.';

  @override
  String get xtMxPromise3 => 'Keys go into your keychain from the window, never in the chat.';

  @override
  String get xtMxProposal => 'God\'s package';

  @override
  String get xtMxReaches => 'It reaches only';

  @override
  String get xtMxReachesNothing => 'Nothing: it works without the network.';

  @override
  String get xtMxRetest => 'Test again';

  @override
  String get xtMxState_building => 'Being built';

  @override
  String get xtMxState_dismissed => 'Put away';

  @override
  String get xtMxState_done => 'Installed';

  @override
  String get xtMxState_ready => 'Ready: it waits for you';

  @override
  String get xtMxState_testing => 'Tests running';

  @override
  String get xtMxStep1 => 'You say what you want';

  @override
  String get xtMxStep2 => 'God writes and tests it';

  @override
  String get xtMxStep3 => 'You install it';

  @override
  String get xtMxTesting => 'The tests are running again in the sandbox…';

  @override
  String get xtMxUninstall => 'Uninstall';

  @override
  String xtMxUninstallText(String what) {
    return 'These go away: $what. The keys added for it leave the keychain too.';
  }

  @override
  String xtMxUninstallTitle(String what) {
    return 'Uninstall $what?';
  }

  @override
  String get xtMxWhyGod => 'God has to fix it: tell it in the conversation if it does not.';

  @override
  String get xtMxWhyHost =>
      'The code reaches it but does not declare it: God has to declare it or remove it.';

  @override
  String get xtMxWhyMissing =>
      'Not in your keychain yet: add it here, it goes to these tools only.';

  @override
  String get xtMxWhyNotGiven =>
      'It is in your keychain, but not given to these tools (or not towards these addresses).';

  @override
  String get xtMxWhyTest =>
      'It failed in the sandbox: God reads why and fixes it; with a key added, the tests run again.';

  @override
  String get xtName => 'Name';

  @override
  String get xtNewSkill => 'New skill';

  @override
  String get xtNoProposals => 'No proposals.';

  @override
  String get xtOpen => 'open';

  @override
  String get xtProposals => 'Proposals waiting for you';

  @override
  String get xtReject => 'Reject';

  @override
  String get xtRemotePasswordChange => 'Change it';

  @override
  String get xtRemove => 'Remove';

  @override
  String get xtSave => 'Save';

  @override
  String get xtScope => 'Scope';

  @override
  String get xtScopePlatform => 'platform';

  @override
  String get xtSkillDownload => 'Download';

  @override
  String get xtSkillDownloadHelp => 'Download this skill as a .zip, to share it';

  @override
  String get xtSkillImport => 'Import a skill';

  @override
  String get xtSkillImportFile => 'Choose a .zip file';

  @override
  String get xtSkillImportHelp =>
      'A skill\'s folder as a .zip (the agentskills.io format), from another Rasgeth or another tool.';

  @override
  String get xtSkillImportWhere => 'Install in';

  @override
  String xtSkillImported(String name) {
    return 'Skill \"$name\" imported.';
  }

  @override
  String get xtSkillReplaceConfirm => 'A skill with this name already exists there. Replace it?';

  @override
  String get xtSvApprovedAuto => 'installed by itself (your choice in Safety)';

  @override
  String get xtSvApprovedYou => 'approved by you';

  @override
  String xtSvBy(String who) {
    return 'by $who';
  }

  @override
  String get xtSvCompare => 'Compare with the one in use';

  @override
  String get xtSvCompareFull => 'Compare: every difference';

  @override
  String get xtSvCurrent => 'in use';

  @override
  String get xtSvHideCompare => 'Hide the comparison';

  @override
  String get xtSvHow_baseline => 'As it was before the history began';

  @override
  String get xtSvHow_edited => 'Changed by hand';

  @override
  String get xtSvHow_import => 'Imported';

  @override
  String get xtSvHow_install => 'First version';

  @override
  String xtSvHow_rollback(String n) {
    return 'Back to version $n';
  }

  @override
  String get xtSvHow_update => 'New version';

  @override
  String get xtSvLead =>
      'Every change of this skill is kept: who wrote it, why and when. Agents use the newest from their next conversation.';

  @override
  String get xtSvLineTitle => 'What changed and why';

  @override
  String get xtSvNextSession =>
      'Once installed, agents use it from their next conversation; the ones already talking keep the version they started with.';

  @override
  String get xtSvNone => 'No versions yet.';

  @override
  String get xtSvNotRestorable => 'Too large to keep: it cannot come back.';

  @override
  String xtSvRollback(String n) {
    return 'Go back to version $n';
  }

  @override
  String xtSvRollbackConfirm(String name) {
    return 'Its files replace those of «$name» in use, as a new version: nothing is lost and you can come back here. Agents get it from their next conversation.';
  }

  @override
  String xtSvRollbackTitle(String n) {
    return 'Go back to version $n?';
  }

  @override
  String xtSvRolledBack(String n, String v) {
    return 'Back to version $n: it is version $v now.';
  }

  @override
  String get xtSvTitle => 'Versions';

  @override
  String get xtSvUnknown => 'author unknown';

  @override
  String xtSvVersion(String n) {
    return 'Version $n';
  }

  @override
  String get xtSvWhy => 'Why';

  @override
  String get xtSvYou => 'you';

  @override
  String get xtUrl => 'URL';

  @override
  String get xtWzDoneBtn => 'Done';

  @override
  String get xtXwAddress => 'Address';

  @override
  String get xtXwAuthor => 'Proposed by';

  @override
  String get xtXwConnectedLead => 'The lit ones work. Open one to sign in again or remove it.';

  @override
  String get xtXwFailedLead =>
      'Proposals of the agents whose tests did not pass: they were never installed.';

  @override
  String get xtXwFile => 'File';

  @override
  String get xtXwImportText => 'A .zip someone shared, into everything or one project.';

  @override
  String xtXwKeptFiles(String files) {
    return 'Files of the skill it keeps: $files';
  }

  @override
  String get xtXwKind => 'Kind';

  @override
  String get xtXwNewSkillText => 'Instructions you write for your agents; it installs right away.';

  @override
  String get xtXwOpenFile => 'Open the file';

  @override
  String get xtXwOwnLead =>
      'For experts: a skill someone shared with you, one you write, a server not in the catalog.';

  @override
  String get xtXwOwnTitle => 'Made by hand';

  @override
  String get xtXwPrevious => 'Now installed';

  @override
  String xtXwScripts(String files) {
    return 'It has scripts ($files): approve only if you trust what they do.';
  }

  @override
  String get xtXwServerText =>
      'An MCP server by address or by command, with its key if it needs one.';

  @override
  String get xtXwSignIn => 'Sign-in';

  @override
  String get xtXwSkillNameHelp => 'Lowercase letters, digits and dashes, such as weekly-report.';

  @override
  String get xtXwSource => 'Made by';

  @override
  String get xtXwState => 'State';

  @override
  String get xtXwSummary => 'Why it came';

  @override
  String get xtXwTests => 'Tests in a throwaway sandbox';

  @override
  String get xtXwTestsFailed => 'tests failed';

  @override
  String get xtXwUpdates => 'Update of an installed skill';

  @override
  String get xtXwWaitsYou => 'waits for your yes';

  @override
  String get xtYou => 'You';

  @override
  String get vkCancel => 'Cancel';

  @override
  String get vkClose => 'Close';

  @override
  String get vkDvSection => 'Devices';

  @override
  String get vkKcAdd => 'Add';

  @override
  String get vkKcAddSub => 'Its value is sealed as soon as you save';

  @override
  String get vkKcAddTitle => 'A new credential';

  @override
  String get vkKcAgentsHow =>
      'Agents use a credential with use_credential, or through the tools you bind to it below each credential.';

  @override
  String get vkKcAgentsHowNoProxy => 'Agents use a credential with use_credential.';

  @override
  String get vkKcAll => 'All';

  @override
  String get vkKcAllAgents => 'Every agent';

  @override
  String get vkKcAllAgentsHelp => 'Off: only the agents you choose.';

  @override
  String get vkKcAllCats => 'All';

  @override
  String get vkKcAsk => 'Ask me before it is used';

  @override
  String get vkKcAsk_always => 'Every time';

  @override
  String get vkKcAsk_never => 'Never: I trust the rules above';

  @override
  String get vkKcAsk_session => 'The first time in each conversation';

  @override
  String get vkKcAutos => 'Automations that may use it';

  @override
  String get vkKcBrAddress => 'Rasgeth\'s address';

  @override
  String get vkKcBrCode => 'Code';

  @override
  String get vkKcBrCodeLead =>
      'In the extension (the key in the browser\'s bar) write this address and this code. The code works for ten minutes and for one browser.';

  @override
  String get vkKcBrCopied => 'Copied';

  @override
  String get vkKcBrCopy => 'Copy';

  @override
  String vkKcBrDone(String name) {
    return 'Linked: «$name». You can close this window.';
  }

  @override
  String get vkKcBrDownload => 'Download the extension';

  @override
  String get vkKcBrDownloadFirefox => 'Download the version for Firefox';

  @override
  String get vkKcBrExpired => 'That code expired: make a new one.';

  @override
  String vkKcBrExpires(String time) {
    return 'Valid until $time';
  }

  @override
  String vkKcBrHowChromium(String page) {
    return 'Unzip it into a folder you will keep. Open $page, switch on «Developer mode», press «Load unpacked» and choose the folder. You can also drag the zip onto that page.';
  }

  @override
  String get vkKcBrHowFirefox =>
      'Open about:debugging#/runtime/this-firefox, press «Load Temporary Add-on…» and choose the zip. Firefox keeps it until it closes: to keep it for good it must be signed by Mozilla.';

  @override
  String get vkKcBrHowOpera =>
      'Unzip it into a folder you will keep. Open opera://extensions, switch on «Developer mode» at the top right, press «Load unpacked» and choose the folder. You can also drag the zip onto that page.';

  @override
  String get vkKcBrHttpNote =>
      'This address starts with http: the extension accepts it only at home (this computer or the local network). From outside use remote access, with https.';

  @override
  String get vkKcBrLead =>
      'The keychain\'s extension fills sign-ins in Opera, Chrome, Edge, Brave and Firefox, only on the site each password belongs to, and saves the new ones here. Every use shows in the list above.';

  @override
  String get vkKcBrLink => 'Link a browser';

  @override
  String vkKcBrLinked(String when) {
    return 'linked $when';
  }

  @override
  String get vkKcBrMakeCode => 'Make a code';

  @override
  String get vkKcBrNever => 'not used yet';

  @override
  String get vkKcBrNone => 'No browser linked yet.';

  @override
  String vkKcBrSeen(String when) {
    return 'last seen $when';
  }

  @override
  String get vkKcBrStep1 => '1. Install the extension';

  @override
  String get vkKcBrStep2 => '2. Link it with a code';

  @override
  String get vkKcBrStore =>
      'Later also in the Chrome Web Store: one click to install, and it updates itself.';

  @override
  String get vkKcBrTitle => 'In your browser';

  @override
  String get vkKcBrUnlink => 'Unlink';

  @override
  String vkKcBrUnlinkQ(String name) {
    return 'Unlink $name?';
  }

  @override
  String get vkKcBrUnlinkText =>
      'The browser stops reaching the keychain at once. The passwords stay here; to use it again, link it with a new code.';

  @override
  String get vkKcBrWhich => 'Your browser';

  @override
  String get vkKcBrWinLead =>
      'The keychain\'s extension fills sign-ins in Opera, Chrome, Edge, Brave and Firefox, only on the site each password belongs to, and saves the new ones here.';

  @override
  String get vkKcBrWinTitle => 'Link a browser';

  @override
  String get vkKcCat_api => 'API keys';

  @override
  String get vkKcCat_bank => 'Bank';

  @override
  String get vkKcCat_email => 'Email';

  @override
  String get vkKcCat_login => 'Logins';

  @override
  String get vkKcCat_other => 'Other';

  @override
  String get vkKcCat_server => 'Servers';

  @override
  String get vkKcCategory => 'Kind';

  @override
  String get vkKcChange => 'Change';

  @override
  String get vkKcClosed => 'The keychain is closed';

  @override
  String get vkKcClosedKeys =>
      'Until it opens, the keys you gave Rasgeth stay where they were (secrets.json and the private files), and nothing is deleted.';

  @override
  String get vkKcCopied => 'Copied';

  @override
  String get vkKcCopiedNote => 'Copied: it leaves the clipboard in 30 seconds.';

  @override
  String get vkKcCopy => 'Copy';

  @override
  String get vkKcEmpty =>
      'Nothing here yet. Add the key of a service an agent should use, or import your passwords from another manager.';

  @override
  String get vkKcExpired => 'Expired';

  @override
  String get vkKcExpires => 'Expires on';

  @override
  String get vkKcExpiresHelp => 'Rasgeth reminds you a month before.';

  @override
  String vkKcExpiresIn(String n) {
    return 'Expires in $n days';
  }

  @override
  String get vkKcExpiresToday => 'Expires today';

  @override
  String get vkKcExpiringLead => 'To renew soon:';

  @override
  String get vkKcExport => 'Export sealed';

  @override
  String get vkKcExportGo => 'Download';

  @override
  String get vkKcExportLead =>
      'A file with every credential, sealed with a passphrase of yours: without it nobody can open it, Rasgeth included.';

  @override
  String get vkKcExportTitle => 'Export the keychain';

  @override
  String get vkKcExported => 'Downloaded. Keep the file and its passphrase apart.';

  @override
  String get vkKcEyebrow => 'Keychain';

  @override
  String get vkKcFormat => 'Value of the header';

  @override
  String get vkKcFormat_1password => '1Password';

  @override
  String get vkKcFormat_bitwarden => 'Bitwarden';

  @override
  String get vkKcFormat_chrome => 'Chrome or Edge';

  @override
  String get vkKcFormat_firefox => 'Firefox';

  @override
  String get vkKcFormat_generic => 'CSV';

  @override
  String get vkKcGenAgain => 'Another one';

  @override
  String vkKcGenChars(String n) {
    return '$n characters';
  }

  @override
  String get vkKcGenDigits => 'Digits only (PIN)';

  @override
  String get vkKcGenKind => 'What it is made of';

  @override
  String get vkKcGenLength => 'Length';

  @override
  String get vkKcGenLetters => 'Letters and digits';

  @override
  String get vkKcGenSymbols => 'Letters, digits, symbols';

  @override
  String get vkKcGenUse => 'Use this';

  @override
  String get vkKcGenerate => 'Make one';

  @override
  String get vkKcHeader => 'Header';

  @override
  String get vkKcHide => 'Hide';

  @override
  String get vkKcHosts => 'Allowed addresses';

  @override
  String get vkKcHostsHelp =>
      'Host names separated by commas; *.example.com for all its subdomains.';

  @override
  String get vkKcHow => 'How it goes on a request';

  @override
  String vkKcHowHelp(String ref, String value) {
    return 'When an agent does not write $ref itself, the value goes in this header. $value stands for the secret.';
  }

  @override
  String get vkKcImport => 'Import';

  @override
  String get vkKcImport1password => '1Password: File > Export > CSV';

  @override
  String get vkKcImportBitwarden => 'Bitwarden: Tools > Export vault > .csv';

  @override
  String get vkKcImportChrome => 'Chrome and Edge: Settings > Passwords > Export passwords';

  @override
  String get vkKcImportFirefox => 'Firefox: Passwords > menu > Export passwords';

  @override
  String vkKcImportFound(String from, String n) {
    return '$n passwords found in the $from file. Choose the ones to keep:';
  }

  @override
  String vkKcImportGo(String n) {
    return 'Import $n';
  }

  @override
  String get vkKcImportLead =>
      'Export your passwords from the other manager as a CSV file, then choose it here. A keychain file exported by Rasgeth works too.';

  @override
  String get vkKcImportLogins =>
      'Imported logins are for you only: no agent may use them until you allow it.';

  @override
  String get vkKcImportPick => 'Choose the file';

  @override
  String get vkKcImportSafe => 'Delete the CSV file afterwards: it holds your passwords in clear.';

  @override
  String get vkKcImportSealedGo => 'Open and import';

  @override
  String get vkKcImportSealedHelp => 'The passphrase chosen when the file was exported.';

  @override
  String vkKcImportSkipped(String n) {
    return '$n without a password were left out.';
  }

  @override
  String get vkKcImportTitle => 'Import passwords';

  @override
  String vkKcImported(String n) {
    return '$n credentials added to the keychain.';
  }

  @override
  String get vkKcLead =>
      'Sealed on this computer. Agents use them by name and never see them; you choose where each one may go and who may use it.';

  @override
  String get vkKcLockedAdmin => 'Set by the administrator';

  @override
  String get vkKcManage => 'Manage';

  @override
  String get vkKcMore => 'More';

  @override
  String get vkKcMoveLead =>
      'From Bitwarden, 1Password, Chrome, Edge or Firefox; out in a file sealed with a passphrase of yours.';

  @override
  String get vkKcMoveTitle => 'Bring them in, take them with you';

  @override
  String get vkKcName => 'Name for the agents';

  @override
  String get vkKcNameBad => 'Only lower-case letters, digits, - and _ (at least two)';

  @override
  String get vkKcNameHelp => 'Lower case, no spaces: agents write it to use the credential.';

  @override
  String get vkKcNeverUsed => 'Never used';

  @override
  String get vkKcNoHosts => 'Without an address no agent can use it: it stays for you only.';

  @override
  String get vkKcNoMatch => 'Nothing matches the search.';

  @override
  String get vkKcNoUses => 'No agent has used a credential yet.';

  @override
  String get vkKcNone => 'None';

  @override
  String get vkKcNotes => 'Notes';

  @override
  String get vkKcPassphrase => 'Passphrase';

  @override
  String get vkKcPassphraseAgain => 'The passphrase again';

  @override
  String get vkKcPassphraseDiffer => 'The two are different';

  @override
  String get vkKcPassphraseHelp =>
      'At least 8 characters. Keep it somewhere safe: it cannot be recovered.';

  @override
  String get vkKcProt_dpapi => 'Protected by Windows';

  @override
  String get vkKcProt_env => 'Sealed with the server\'s own key';

  @override
  String get vkKcProt_file => 'Sealed with a key kept on this computer';

  @override
  String get vkKcProt_keychain => 'Protected by the Mac\'s Keychain';

  @override
  String get vkKcQ => 'Your keys and passwords, safe in one place';

  @override
  String get vkKcRemove => 'Delete';

  @override
  String vkKcRemoveQ(String name) {
    return 'Delete $name?';
  }

  @override
  String get vkKcRemoveText =>
      'The credential goes from the keychain for good: agents and tools can no longer use it.';

  @override
  String get vkKcSafeText =>
      'Encrypted (AES-256), never in a project or in git, never written in a chat or a log.';

  @override
  String get vkKcSearch => 'Search by name, service, user or label';

  @override
  String get vkKcSecret => 'The secret';

  @override
  String get vkKcSecretLead =>
      'The key, token or password. Once saved it is never shown again unless you ask.';

  @override
  String get vkKcSecretPlaceholder => 'Paste or type it here';

  @override
  String get vkKcService => 'Service';

  @override
  String get vkKcServiceExample => 'Revolut Business';

  @override
  String get vkKcServiceHelp => 'The name you know it by: Revolut, Gmail, the office server.';

  @override
  String get vkKcShow => 'Show';

  @override
  String get vkKcShowQ => 'Show the secret?';

  @override
  String get vkKcShowText =>
      'It will be on the screen until you hide it or close the window. Make sure nobody is looking.';

  @override
  String get vkKcUnlockShow => 'Unlock to show this secret';

  @override
  String get vkKcUnlockCopy => 'Unlock to copy this secret';

  @override
  String get vkKcUnlockRefused => 'Not unlocked: the secret stays hidden.';

  @override
  String get vkKcNoLockQ => 'This device has no lock';

  @override
  String get vkKcNoLockText =>
      'Nothing on this device checks that it is you: no PIN, fingerprint or face is set in the system\'s settings. Anyone holding it could see your keys, so set a screen lock there. Go on anyway?';

  @override
  String get vkKcSomeAgents => 'The agents that may use it';

  @override
  String get vkKcSomeone => 'Someone';

  @override
  String vkKcSys_chat(String what) {
    return 'Chat: $what';
  }

  @override
  String vkKcSys_email(String what) {
    return 'Mailbox: $what';
  }

  @override
  String vkKcSys_git(String what) {
    return 'Code hosting: $what';
  }

  @override
  String vkKcSys_mcp(String what) {
    return 'Extension: $what';
  }

  @override
  String vkKcSys_other(String what) {
    return '$what';
  }

  @override
  String vkKcSys_provider(String what) {
    return 'Model provider: $what';
  }

  @override
  String vkKcSys_search(String what) {
    return 'Web search: $what';
  }

  @override
  String vkKcSys_ssh(String what) {
    return 'Machine (SSH): $what';
  }

  @override
  String get vkKcSystem => 'Kept by Rasgeth';

  @override
  String get vkKcSystemLead =>
      'Keys set by whoever installed this server (in its environment): Rasgeth uses them, they cannot be changed here.';

  @override
  String get vkKcSystemTitle => 'Set by the administrator';

  @override
  String get vkKcTags => 'Labels';

  @override
  String get vkKcTagsHelp => 'Separated by commas: work, home…';

  @override
  String get vkKcTools => 'Extensions\' tools that receive it';

  @override
  String get vkKcToolsHelp =>
      'A tool chosen here gets the address to reach the service with this credential, never the value.';

  @override
  String get vkKcUrl => 'Address (if any)';

  @override
  String vkKcUseAs(String name) {
    return 'Agents call it $name';
  }

  @override
  String vkKcUseBrowser(String name) {
    return '$name (browser)';
  }

  @override
  String vkKcUse_denied(String host, String name) {
    return 'asked for $name towards $host: you said no';
  }

  @override
  String vkKcUse_moved(String host, String name) {
    return 'moved $name here from $host';
  }

  @override
  String vkKcUse_refused(String host, String name) {
    return 'could not use $name towards $host';
  }

  @override
  String vkKcUse_used(String host, String name) {
    return 'used $name towards $host';
  }

  @override
  String get vkKcUsedBy => 'Used by:';

  @override
  String get vkKcUsedByText =>
      'Rasgeth uses this key by itself. Here you can change it, choose whether agents may use it too and see every use; you remove it from its page.';

  @override
  String vkKcUsedTimes(String n, String when) {
    return 'Used $n times, last $when';
  }

  @override
  String get vkKcUser => 'User or email (if any)';

  @override
  String get vkKcUsesLead =>
      'Every time an agent asked for a credential: when, where to, and how it went.';

  @override
  String get vkKcUsesOne => 'Its last uses';

  @override
  String get vkKcUsesTitle => 'Who used them';

  @override
  String get vkKcWhere => 'Where it may go';

  @override
  String get vkKcWhereLead =>
      'The value is put on a request only towards these addresses: anywhere else it is refused.';

  @override
  String get vkKcWho => 'Who may use it';

  @override
  String get vkKcWhoLead =>
      'Agents never see the value: they ask for it by name, and Rasgeth puts it on the request.';

  @override
  String get vkMcSection => 'Machines';

  @override
  String get vkSave => 'Save';

  @override
  String get vkSettings => 'Settings';

  @override
  String get vkWzCode => 'Where the code lives';

  @override
  String get vkWzRemote => 'Access from outside home';

  @override
  String get vkAutomations => 'Automations';

  @override
  String get vkChats => 'Other chats';

  @override
  String get vkExtensions => 'Extensions';

  @override
  String get vkSubscriptions => 'Models and subscriptions';

  @override
  String get vkTelegram => 'Telegram';

  @override
  String get g4211Hub => 'Services, skills, generation and the agents\' proposals';

  @override
  String get g4212Hub => 'Keys and passwords, safe in one place';

  @override
  String get g4211SignInOpened =>
      'The service\'s page opened in the browser: sign in there, then come back here.';

  @override
  String get g4211OpenExtensions => 'Open Extensions';

  @override
  String get g4212OpenKeychain => 'Open the keychain';

  @override
  String get syBackup => 'Backup';

  @override
  String get syBackupAddsHint =>
      'A project whose name is taken here comes in beside it, with a number after the name.';

  @override
  String get syBackupAlreadyHere => 'already here, left as it is';

  @override
  String get syBackupAnother => 'Import another backup';

  @override
  String get syBackupChoose => 'Choose the backup file';

  @override
  String syBackupCounts(String agents, String conversations, String size) {
    return '$agents agents · $conversations conversations · $size of files';
  }

  @override
  String syBackupDownload(String file) {
    return 'Download $file';
  }

  @override
  String get syBackupExport => 'Make a backup';

  @override
  String get syBackupExportHint =>
      'Projects with their files, agents, conversations, chats and the board. Keys and sign-ins to services are not in it: they stay on this computer. node_modules folders are left out (they are rebuilt).';

  @override
  String syBackupFrom(String when) {
    return 'Backup of $when';
  }

  @override
  String get syBackupImport => 'Import a backup';

  @override
  String get syBackupImportHint =>
      'From another Rasgeth or from this one. Nothing here is deleted or replaced: what is in the backup is added, and what is already here stays as it is.';

  @override
  String get syBackupImportNow => 'Import';

  @override
  String syBackupImported(String agents, String conversations, String projects) {
    return 'Done: $projects projects, $agents agents and $conversations conversations added.';
  }

  @override
  String syBackupKeepName(String name) {
    return 'Keep $name';
  }

  @override
  String get syBackupKeys => 'Include the keychain';

  @override
  String get syBackupKeysHelp =>
      'Sealed with a passphrase of yours, with the keys of the models, chats and mailboxes: without it the backup\'s credentials cannot be opened.';

  @override
  String get syBackupKeysIn => 'The backup carries a keychain: its passphrase';

  @override
  String get syBackupKeysInHelp =>
      'Leave it empty to import everything else without the credentials.';

  @override
  String get syBackupKeysWrong =>
      'The keychain was not imported: wrong passphrase. Everything else was.';

  @override
  String get syBackupMake => 'Prepare the backup';

  @override
  String get syBackupMakeAgain => 'Prepare it again';

  @override
  String syBackupNameQuestion(String backup, String here, String who) {
    return '$who is called $here here and $backup in the backup. Which name does it keep?';
  }

  @override
  String get syBackupNothingNew =>
      'Every project in this backup is here already: only what is missing is added.';

  @override
  String get syBackupPurpose =>
      'Every project with its files, the agents and the conversations in one file: keep it safe, or carry it to another Rasgeth.';

  @override
  String get syBackupSaved => 'Saved in your Downloads folder.';

  @override
  String get syBackupSending => 'Sending the file to Rasgeth';

  @override
  String syBackupTakeName(String name) {
    return 'Use $name';
  }

  @override
  String get syBrainDisconnect => 'Disconnect';

  @override
  String get syCaddyDomain => 'The address';

  @override
  String get syCaddyDomainHelp =>
      'Rasgeth gets its HTTPS certificate from Let\'s Encrypt by itself.';

  @override
  String get syCaddyPihole =>
      'Inside home some routers cannot reach their own public address: then open Rasgeth at home with its usual link, or turn on Pi-hole in Settings, Access from outside home (it is optional).';

  @override
  String get syCaddyStep1 =>
      'At your domain\'s provider, make a DNS record of type A for the address you want (for example rasgeth.yourdomain.com) pointing at your home\'s public address. If it changes, use a dynamic DNS service.';

  @override
  String get syCaddyStep2 => 'On your router, forward ports 80 and 443 to this computer.';

  @override
  String get syCaddyWarning =>
      'With this way Rasgeth\'s sign-in page is on the internet: keep the password strong and the second check on.';

  @override
  String get syCancel => 'Cancel';

  @override
  String get syCfAccess =>
      'Safer still: in Cloudflare Zero Trust, Access, add an application for this address, so Cloudflare asks who you are before the page even appears.';

  @override
  String get syCfBuy => 'Buy a domain on Cloudflare';

  @override
  String get syCfHost => 'The address you chose';

  @override
  String get syCfHostHelp =>
      'For example rasgeth.yourdomain.com: the subdomain and domain of the Public hostname.';

  @override
  String get syCfStep1 =>
      'If you have no domain yet, buy one (Cloudflare sells them at cost, about 10 euros a year):';

  @override
  String get syCfStep2 =>
      'Open Tunnels in Cloudflare Zero Trust, press Create a tunnel, choose Cloudflared and give it a name (for example rasgeth):';

  @override
  String get syCfStep3 =>
      'In the step Public hostname: subdomain rasgeth, your domain, Service type HTTP, URL redgiant:7600. Save.';

  @override
  String get syCfStep4 =>
      'Cloudflare shows a command with a long token after --token: copy only the token and write the address here.';

  @override
  String get syCfToken => 'The tunnel\'s token';

  @override
  String get syCfTokenHelp =>
      'The long string after --token in the command Cloudflare shows (it starts with eyJ).';

  @override
  String get syCfTunnels => 'Cloudflare tunnels';

  @override
  String get syConnecting => 'connecting…';

  @override
  String get syConversations => 'Conversations';

  @override
  String syErr_agent_limit(String count, String max, String project) {
    return 'The project «$project» can have at most $max agents besides its orchestrator: it has $count. Raise the limit in Settings › Projects or remove one.';
  }

  @override
  String get syErr_agent_removed =>
      'The agent was removed from the team: restore it to work with it.';

  @override
  String get syErr_agent_stopped => 'The agent is stopped (paused): resume it to go on.';

  @override
  String get syErr_bad_name => 'That is not a name (for instance git.home.example.com).';

  @override
  String get syErr_code_rejected =>
      'Anthropic did not accept this code: it may be incomplete or old. Open the sign-in page again to get a new one.';

  @override
  String get syErr_email_failed =>
      'The mailbox did not let Rasgeth in: check the server, the address and the app password.';

  @override
  String get syErr_failed => 'The sign-in did not finish. Try again from the start.';

  @override
  String get syErr_host_unreachable =>
      'The server\'s name is known, but its address does not answer from Rasgeth. See Settings › Access from outside home › Your home services.';

  @override
  String get syErr_key_rejected =>
      'The provider refused this key. Check that you copied all of it and that it is still active.';

  @override
  String get syErr_memory_empty => 'Write something to remember.';

  @override
  String get syErr_memory_forgotten => 'A memory forgotten for good cannot come back.';

  @override
  String get syErr_memory_full => 'The memory is full: delete or merge some old memories first.';

  @override
  String get syErr_memory_gone => 'That memory is not there any more.';

  @override
  String get syErr_memory_long => 'A memory is at most 400 characters: write it shorter.';

  @override
  String get syErr_memory_moved => 'The memory changed again since: undo the newer change first.';

  @override
  String get syErr_memory_same => 'Another memory already says the same.';

  @override
  String get syErr_memory_secret =>
      'That looks like a password, a code or a card number: secrets are never kept in memory.';

  @override
  String get syErr_memory_undone => 'That change was already undone.';

  @override
  String get syErr_missing_permission =>
      'GitHub did not let the token create repositories. Make a new one with Administration set to Read and write.';

  @override
  String get syErr_name_not_found =>
      'Rasgeth cannot find the server\'s name in the DNS it uses. See Settings › Access from outside home › Your home services.';

  @override
  String get syErr_no_login => 'Open Anthropic\'s sign-in page first.';

  @override
  String get syErr_no_model =>
      'No model is chosen yet: open Settings, Models and subscriptions, connect one (a subscription, a key or a local model) and choose it in \"The model agents use\".';

  @override
  String get syErr_no_page =>
      'Anthropic\'s sign-in page could not be prepared. Try again in a moment.';

  @override
  String get syErr_no_password => 'Set a password first.';

  @override
  String get syErr_portrait_empty => 'Write the trait.';

  @override
  String get syErr_portrait_gone => 'That trait is not there any more.';

  @override
  String get syErr_portrait_long => 'A trait is at most 200 characters: write it shorter.';

  @override
  String get syErr_portrait_private =>
      'Email addresses and phone numbers never go into the portrait.';

  @override
  String get syErr_portrait_secret =>
      'That looks like a password, a code or a card number: secrets never go into the portrait.';

  @override
  String get syErr_project_archived => 'The project is archived: restore it to work in it.';

  @override
  String syErr_provider_stalled(String minutes, String retries) {
    return 'The provider has not answered for $minutes minutes: I tried again $retries times. Try again in a while, or choose another model.';
  }

  @override
  String get syErr_terms => 'First tick the box about the providers\' terms.';

  @override
  String get syErr_token_rejected =>
      'Telegram refused this token. Copy it again from BotFather\'s message, all of it.';

  @override
  String get syErr_too_many => 'Too many wrong tries: wait 15 minutes, then try again.';

  @override
  String get syErr_unreachable =>
      'The provider did not answer. Check the address and the internet connection, then try again.';

  @override
  String get syErr_vault_bad_file => 'This file is not a password export Rasgeth can read.';

  @override
  String get syErr_vault_bad_passphrase => 'Wrong passphrase, or a damaged file.';

  @override
  String get syErr_vault_closed => 'The keychain is closed on this computer.';

  @override
  String get syErr_vault_in_git =>
      'The keychain\'s folder is inside a git repository: it must never be committed. Move Rasgeth\'s data folder outside it.';

  @override
  String get syErr_vault_name_taken =>
      'Another credential has that name for the agents: choose another one.';

  @override
  String get syErr_vault_no_value => 'Write the secret.';

  @override
  String get syErr_vault_not_found => 'That credential is no longer in the keychain.';

  @override
  String get syErr_vault_system => 'Rasgeth uses this key: remove it from its page in Settings.';

  @override
  String get syErr_voice_convert =>
      'The recording could not be converted for whisper on this computer.';

  @override
  String get syErr_voice_empty => 'The recording is empty.';

  @override
  String syErr_voice_key_refused(String name) {
    return '$name refused the key: check it in Settings, Voice.';
  }

  @override
  String syErr_voice_no_key(String name) {
    return '$name has no key yet: add it in Settings, Voice.';
  }

  @override
  String get syErr_voice_no_service =>
      'Rasgeth has no transcription service: choose one in Settings, Voice, Transcription.';

  @override
  String get syErr_voice_provider => 'This provider cannot do it: choose another one.';

  @override
  String syErr_voice_rate_limited(String name) {
    return '$name says too many requests or no credit left.';
  }

  @override
  String syErr_voice_service_error(String name, String status) {
    return '$name answered with an error ($status).';
  }

  @override
  String syErr_voice_timeout(String name) {
    return '$name took too long to answer.';
  }

  @override
  String get syErr_voice_too_long => 'The recording is too long.';

  @override
  String syErr_voice_unreachable(String name) {
    return '$name cannot be reached: check that it is on and its address.';
  }

  @override
  String get syErr_weak => 'The password needs at least 10 characters.';

  @override
  String get syErr_wrong => 'Wrong password or code.';

  @override
  String get syError => 'Error';

  @override
  String get syFailed => 'failed';

  @override
  String get syFbArch => 'Architecture';

  @override
  String get syFbBackupBusy => 'A backup is already running.';

  @override
  String get syFbBackupNow => 'Make a backup now';

  @override
  String get syFbBackupQ => 'Best on another disk: if this one breaks, the copy is still there.';

  @override
  String get syFbBackupStarted => 'Backup started: it shows in Downloads and jobs.';

  @override
  String get syFbBackupTitle => 'Backups';

  @override
  String get syFbCannotMount => 'Cannot be mounted here';

  @override
  String syFbContainerDisks(String name) {
    return 'Rasgeth OS runs in a container ($name): the disks it sees are those of the machine hosting it and cannot be used from here.';
  }

  @override
  String get syFbDaily => 'Every day';

  @override
  String get syFbDataDir => 'Folder';

  @override
  String get syFbDataQ => 'Projects, conversations and settings are here.';

  @override
  String get syFbDataTitle => 'The data';

  @override
  String get syFbDay => 'Day';

  @override
  String syFbDestDisk(String label, String path) {
    return 'Backups go to the disk $label ($path).';
  }

  @override
  String syFbDestFolder(String path) {
    return 'Backups go to the folder $path.';
  }

  @override
  String syFbDestNode(String name) {
    return 'Backups go to the node $name, in the storage it lends.';
  }

  @override
  String syFbDestSftp(String machine, String path) {
    return 'Backups go to $machine, in $path (SFTP).';
  }

  @override
  String syFbDestSmb(String path, String user) {
    return 'Backups go to the shared folder $path, as $user.';
  }

  @override
  String get syFbDisks => 'Disks';

  @override
  String get syFbDisksTitle => 'Removable disks';

  @override
  String get syFbErr_already => 'The container already has a folder with that name.';

  @override
  String get syFbErr_auth =>
      'The destination refused the sign-in: check the user and the password (or the machine\'s key).';

  @override
  String get syFbErr_bad_path =>
      'Write a full folder path (/volume1/Rasgeth) or one from the home (~/backups).';

  @override
  String get syFbErr_denied => 'The destination does not let this user write there.';

  @override
  String get syFbErr_disk_missing =>
      'The backup disk is not connected: plug it in. Nothing was written elsewhere.';

  @override
  String get syFbErr_has_filesystem =>
      'That disk is formatted already: it is never formatted again from here.';

  @override
  String get syFbErr_keychain_closed => 'Open the keychain first: the password is kept there.';

  @override
  String get syFbErr_mismatch =>
      'The copy arrived different from the original: it was not kept. Try again.';

  @override
  String get syFbErr_needs_format => 'That disk is not formatted.';

  @override
  String get syFbErr_no_container => 'There is no container with that id on the host.';

  @override
  String get syFbErr_no_destination => 'Choose where backups go first.';

  @override
  String get syFbErr_no_disk => 'That disk is not a removable disk of the host (any more).';

  @override
  String get syFbErr_not_found => 'The folder or the destination is not there (any more).';

  @override
  String get syFbErr_not_proxmox => 'That machine is not a Proxmox host.';

  @override
  String get syFbErr_not_trusted =>
      'Test this machine once in Settings › Machines and trust its key first.';

  @override
  String get syFbErr_place_missing =>
      'The folder from the host is not mounted now: nothing was written on the system disk.';

  @override
  String get syFbErr_smb_address =>
      'Write the shared folder as \\\\host\\share\\folder (letters, digits, spaces, dots and dashes).';

  @override
  String get syFbErr_smb_bad_domain => 'The domain is letters, digits, dots and dashes.';

  @override
  String get syFbErr_smb_bad_password => 'This password cannot be used (no line breaks).';

  @override
  String get syFbErr_smb_bad_user => 'This user name cannot be used.';

  @override
  String get syFbErr_smb_missing =>
      'Shared folders need smbclient, which this installation does not have.';

  @override
  String get syFbErr_unreachable =>
      'The destination does not answer: is it on and on the network? Nothing was written elsewhere.';

  @override
  String get syFbFolderLead =>
      'A folder this machine can write to: a network share, a disk mounted by you. Not inside the data folder.';

  @override
  String get syFbFolderPath => 'Folder';

  @override
  String get syFbFolderTitle => 'Or a folder';

  @override
  String syFbFreeOf(String free) {
    return '$free free';
  }

  @override
  String syFbFreeOfTotal(String free, String total) {
    return '$free GB free of $total GB';
  }

  @override
  String get syFbFri => 'Fri';

  @override
  String get syFbHostBad_bad_device => 'This disk\'s device cannot be used.';

  @override
  String get syFbHostBad_bad_id => 'The container id is a number, like 105.';

  @override
  String get syFbHostBad_bad_mp => 'No free mount point.';

  @override
  String get syFbHostBad_bad_name => 'This disk\'s name cannot be used for a folder.';

  @override
  String get syFbHostId => 'Container id on Proxmox';

  @override
  String syFbHostIdHelp(String hostname) {
    return 'The number in Proxmox\'s list (this container is called $hostname).';
  }

  @override
  String get syFbHostKind => 'The host';

  @override
  String get syFbHostLead =>
      'From a container Rasgeth sees the host\'s disks but cannot mount them: the host mounts the disk and passes a folder in. Rasgeth notices it by itself.';

  @override
  String syFbHostMany(String n) {
    return 'On this machine there are $n removable disks: pick the one for backups.';
  }

  @override
  String get syFbHostNone =>
      'No removable disk of the host is in sight: plug it into the host, or use a folder on the network below.';

  @override
  String syFbHostOne(String how, String size, String title) {
    return 'On this machine there is the disk $title, $how, $size.';
  }

  @override
  String get syFbHostOther => 'Other';

  @override
  String get syFbHostSteps => 'To run on the host, as root';

  @override
  String get syFbHostTitle => 'A disk of the host';

  @override
  String syFbHostWatching(String target) {
    return 'Looking every few seconds: when $target arrives it shows above, ready to use.';
  }

  @override
  String get syFbHour => 'Hour';

  @override
  String get syFbKeep => 'Backups kept';

  @override
  String syFbKeepN(String n) {
    return 'keep $n';
  }

  @override
  String syFbLastFailed(String when, String why) {
    return 'The backup of $when did not work: $why';
  }

  @override
  String syFbLastOk(String when) {
    return 'Last backup: $when, read back and complete.';
  }

  @override
  String get syFbListAgain => 'Look again';

  @override
  String syFbListEmpty(String where) {
    return 'No backup yet in $where.';
  }

  @override
  String get syFbListLead =>
      'Each one can be brought back: what is new is added, nothing here is deleted.';

  @override
  String get syFbListShow => 'Show the backups';

  @override
  String get syFbListTitle => 'The backups there';

  @override
  String get syFbMachineTitle => 'The machine';

  @override
  String get syFbMethod_helper =>
      'Pick one: Rasgeth mounts it only for backups. System disks are never offered.';

  @override
  String get syFbMethod_none =>
      'This installation cannot mount disks (for example plain Docker without privileges): use a disk already mounted, or a folder below.';

  @override
  String get syFbMethod_udisks =>
      'Pick one: the system mounts it (udisks2). System disks are never offered.';

  @override
  String get syFbMissing_not_installed => 'unknown: the program that tells is not installed';

  @override
  String get syFbMissing_unreadable => 'could not be read';

  @override
  String get syFbMissing_unsupported => 'not available on this system';

  @override
  String get syFbMon => 'Mon';

  @override
  String get syFbNetAProxy => 'a reverse proxy';

  @override
  String syFbNetDns(String ip) {
    return 'A DNS server on your network ($ip): a name like rasgeth.home can point here.';
  }

  @override
  String get syFbNetFolder => 'Folder there';

  @override
  String get syFbNetFolderHelp =>
      'A full path (/volume1/Rasgeth, E:\\Backup) or one from the home (~/RedGiant-backups). It is made if missing.';

  @override
  String get syFbNetLanOnly => 'Local network only is a fine choice: skip this step.';

  @override
  String get syFbNetLead =>
      'Nothing to mount: it works also in a container or in Docker. Each backup arrives under a temporary name and gets its real name only once complete and checked.';

  @override
  String syFbNetName(String name) {
    return 'You reached Rasgeth by name: $name.';
  }

  @override
  String get syFbNetNoMachines =>
      'No machine yet: add your NAS or another computer in Settings › Machines (SSH), test it once, then come back here.';

  @override
  String get syFbNetNoNodes =>
      'No paired Rasgeth yet: pair one in Settings › Nodes (it must lend its storage).';

  @override
  String get syFbNetNode => 'Another Rasgeth';

  @override
  String get syFbNetNotTrusted => 'Test it in Settings › Machines first';

  @override
  String get syFbNetNothing => 'Nothing found that already reaches this machine from outside.';

  @override
  String get syFbNetPick => 'Use for backups';

  @override
  String syFbNetProxies(String names) {
    return 'Running on this machine: $names.';
  }

  @override
  String syFbNetProxyFront(String name) {
    return 'There is already $name in front of Rasgeth.';
  }

  @override
  String get syFbNetSftp => 'One of your machines';

  @override
  String get syFbNetSmb => 'Shared folder (SMB)';

  @override
  String syFbNetTailscale(String name) {
    return 'Tailscale is already running here ($name): you can use it.';
  }

  @override
  String get syFbNetTailscaleOff => 'Tailscale is installed here but not connected.';

  @override
  String get syFbNetTitle => 'Or a folder on the network';

  @override
  String get syFbNoDisks =>
      'No removable disk found. Plug one in and open this page again, or use a folder.';

  @override
  String get syFbNodeOffline => 'Offline now';

  @override
  String get syFbNodeOnline => 'Online';

  @override
  String get syFbOff => 'Only when I ask';

  @override
  String get syFbOfferCloud => 'Cloud models: always available.';

  @override
  String syFbOfferLocalCpu(String max) {
    return 'Local models: yes, small ones on the processor, up to about $max GB (slower than a card).';
  }

  @override
  String syFbOfferLocalGpu(String max) {
    return 'Local models: yes, on the graphics card, up to about $max GB.';
  }

  @override
  String get syFbOfferNoLocal =>
      'Local models: not offered, too little memory here. You can still add one from Settings › Models.';

  @override
  String get syFbPairLater =>
      'Write the main Rasgeth\'s address and the code it shows in Settings › Nodes › «Add a node». You can also do it later, from Settings.';

  @override
  String get syFbPassword => 'Password';

  @override
  String get syFbPasswordAgain => 'The same password again';

  @override
  String get syFbPasswordHelp => 'At least 10 characters.';

  @override
  String syFbPlaceFree(String free, String total) {
    return '$free GB free of $total';
  }

  @override
  String get syFbPlaceNotWritable => 'Rasgeth cannot write here';

  @override
  String get syFbPlacesLead =>
      'Folders the machine hosting Rasgeth mounted under /var/lib/redgiant/backups (a Proxmox mount point, a network share).';

  @override
  String get syFbPlacesTitle => 'Folders mounted for backups';

  @override
  String get syFbPveDo => 'Pass it to Rasgeth';

  @override
  String syFbPveDone(String target) {
    return 'Done: the folder $target has arrived.';
  }

  @override
  String get syFbPveFormat => 'Not formatted: format and pass it';

  @override
  String syFbPveFormatLabel(String title) {
    return 'Everything on it is erased. To go on, type its name: $title';
  }

  @override
  String syFbPveFormatQ(String title) {
    return 'Format the disk $title?';
  }

  @override
  String get syFbPveFormatYes => 'Format and pass it';

  @override
  String syFbPveGuess(String id) {
    return 'This container is $id.';
  }

  @override
  String syFbPveHost(String name, String version) {
    return '$name: Proxmox $version.';
  }

  @override
  String get syFbPveLead =>
      'If the Proxmox host is among your machines (Settings › Machines), Rasgeth can run these steps there itself. It asks you first, with every command in the request.';

  @override
  String get syFbPveLook => 'Look for the Proxmox host';

  @override
  String get syFbPveNeedId => 'Write the container id first.';

  @override
  String get syFbPveNoDisks => 'No removable disk on that host.';

  @override
  String syFbPveNone(String n) {
    return 'None of your $n machines is a Proxmox host. Add the host in Settings › Machines (as root, with Rasgeth\'s key), test it, then look again.';
  }

  @override
  String syFbPveQ(String host, String id, String title) {
    return 'Pass the disk $title of $host to container $id?';
  }

  @override
  String syFbPveRestart(String target) {
    return 'Done on the host. If $target does not appear in a minute, restart the container from Proxmox.';
  }

  @override
  String get syFbPveText =>
      'Rasgeth asks you again in your requests, with the exact commands, before running anything on the host.';

  @override
  String get syFbPveTitle => 'Do it for me';

  @override
  String get syFbPveYes => 'Ask me with the commands';

  @override
  String syFbRamFree(String gb) {
    return '$gb GB free now';
  }

  @override
  String syFbRamTotal(String gb) {
    return '$gb GB in all';
  }

  @override
  String get syFbRemovable => 'removable';

  @override
  String get syFbRestore => 'Restore';

  @override
  String syFbRestoreQ(String when) {
    return 'Restore the backup of $when?';
  }

  @override
  String get syFbRestoreText =>
      'It is read back first, then projects, agents and conversations that are not here are added. Nothing here is deleted.';

  @override
  String get syFbRestoreYes => 'Restore';

  @override
  String get syFbRoleFull => 'Complete Rasgeth';

  @override
  String get syFbRoleFullText => 'Agents, projects, chats and everything else, on this machine.';

  @override
  String get syFbRoleNode => 'Node of another Rasgeth';

  @override
  String get syFbRoleNodeText => 'This machine works for a Rasgeth you already have.';

  @override
  String get syFbRoleSettingsLead =>
      'You can change it at any time: it asks first and says what changes.';

  @override
  String get syFbRoleTitle => 'Role';

  @override
  String get syFbSat => 'Sat';

  @override
  String get syFbSmbAddress => 'Shared folder';

  @override
  String get syFbSmbAddressHelp =>
      'As Windows writes it (\\\\nas\\backup\\Rasgeth) or smb://nas/backup/Rasgeth.';

  @override
  String get syFbSmbDomain => 'Domain or workgroup';

  @override
  String get syFbSmbDomainHelp => 'Only if your network needs one (often empty).';

  @override
  String get syFbSmbMissing =>
      'Shared folders need smbclient, which this installation does not have (the Docker image and Rasgeth OS have it). On Windows use the folder field above with \\\\host\\share.';

  @override
  String get syFbSmbPassword => 'Password';

  @override
  String get syFbSmbPasswordHelp => 'It goes into the keychain only, never into a file or a log.';

  @override
  String get syFbSmbPasswordKept => 'Kept in the keychain: leave it empty to keep it.';

  @override
  String get syFbSmbUser => 'User';

  @override
  String get syFbSshAddKey => 'Add this key';

  @override
  String syFbSshContainer(String name) {
    return 'In a container ($name) SSH reaches the container itself, at its own address, as the user redgiant.';
  }

  @override
  String get syFbSshKey => 'Public key';

  @override
  String get syFbSshKeyHelp =>
      'One line starting with ssh-ed25519, ssh-rsa or ecdsa-sha2 (the .pub file).';

  @override
  String get syFbSshKeyPlaceholder => 'ssh-ed25519 AAAA… me@laptop';

  @override
  String syFbSshKeys(String n) {
    return '$n key(s) allowed';
  }

  @override
  String get syFbSshNeedKey => 'Paste a public key first, then switch it on.';

  @override
  String get syFbSshOffHelp => 'Paste a public key below, then switch it on.';

  @override
  String get syFbSshOn => 'SSH on';

  @override
  String get syFbSshQ =>
      'To work on the machine itself from a terminal. Off unless you switch it on; keys only, never passwords.';

  @override
  String get syFbSshTitle => 'SSH';

  @override
  String get syFbSshWhy_no_helper =>
      'This installation has no Rasgeth OS system helper: SSH is managed by the system hosting it.';

  @override
  String get syFbSshWhy_not_installed => 'SSH (openssh-server) is not installed on this system.';

  @override
  String syFbSshWhy_other(String why) {
    return 'SSH cannot be read here: the system helper answered «$why».';
  }

  @override
  String get syFbSshWhy_timeout =>
      'Rasgeth OS\'s system helper took too long to answer: try again in a moment.';

  @override
  String get syFbSshWhy_unreachable =>
      'Rasgeth OS\'s system helper does not answer (redgiant-helper.socket): SSH cannot be read or changed now. Restarting the machine usually brings it back.';

  @override
  String get syFbSun => 'Sun';

  @override
  String get syFbSystemLead =>
      'The machine Rasgeth runs on, its role, where its data and backups live, and SSH.';

  @override
  String get syFbSystemQ => 'System';

  @override
  String get syFbSystemSection => 'System';

  @override
  String get syFbThu => 'Thu';

  @override
  String get syFbToFullQ => 'Make this a complete Rasgeth again?';

  @override
  String get syFbToFullText =>
      'It stops working for the other Rasgeth; its own agents, projects and conversations come back as they were.';

  @override
  String get syFbToFullYes => 'Make it complete';

  @override
  String get syFbToNodeQ => 'Make this Rasgeth a node?';

  @override
  String get syFbToNodeText =>
      'It will stop being a Rasgeth of its own once paired: its agents, projects and conversations stay saved, untouched, but they rest until you make it complete again.';

  @override
  String get syFbToNodeYes => 'Make it a node';

  @override
  String get syFbTue => 'Tue';

  @override
  String get syFbUseDisk => 'Use for backups';

  @override
  String get syFbUseFolder => 'Use this folder';

  @override
  String get syFbUsePlace => 'Use for backups';

  @override
  String get syFbUseShare => 'Use this shared folder';

  @override
  String get syFbVirt => 'Runs on';

  @override
  String syFbVirtContainer(String name) {
    return 'a container ($name)';
  }

  @override
  String get syFbVirtNone => 'a physical machine';

  @override
  String syFbVirtVm(String name) {
    return 'a virtual machine ($name)';
  }

  @override
  String get syFbWed => 'Wed';

  @override
  String get syFbWeekly => 'Every week';

  @override
  String get syFbWhenTitle => 'When';

  @override
  String get syFbWhyFs => 'Format not supported';

  @override
  String get syFbWhyNoFs => 'Not formatted';

  @override
  String get syFbWhyNoUuid => 'Without an id';

  @override
  String get syFbWhyNotDisk => 'Not a disk';

  @override
  String get syFbWhyNotRemovable => 'Not removable';

  @override
  String get syFbWhySystem => 'Holds the system';

  @override
  String get syFolder => 'Folder';

  @override
  String get syGitGiteaAgain => 'The same password again';

  @override
  String get syGitGiteaGuide => 'Open «Your home services»';

  @override
  String get syGitGiteaMismatch => 'The two passwords are different.';

  @override
  String get syInspector => 'Inspector';

  @override
  String get syJob_pihole => 'Starting Pi-hole';

  @override
  String get syJob_remote => 'Opening access from outside';

  @override
  String get syJob_step_account => 'Creating your account';

  @override
  String get syJob_step_arrive => 'Waiting for the folder';

  @override
  String get syJob_step_ask => 'Waiting for your yes';

  @override
  String get syJob_step_conversations => 'Conversations';

  @override
  String get syJob_step_convert => 'Converting';

  @override
  String get syJob_step_copy => 'Copying the models';

  @override
  String get syJob_step_data => 'Projects, agents and settings';

  @override
  String get syJob_step_download => 'Downloading the model';

  @override
  String get syJob_step_draft => 'With the small model';

  @override
  String get syJob_step_fetch => 'Bringing the backup here';

  @override
  String get syJob_step_files => 'The projects\' files';

  @override
  String get syJob_step_gitea_image => 'Downloading Gitea (only once)';

  @override
  String get syJob_step_gitea_start => 'Starting Gitea';

  @override
  String get syJob_step_image => 'Downloading the engine (only once)';

  @override
  String get syJob_step_image_download => 'Downloading';

  @override
  String get syJob_step_load => 'Loading the model into memory';

  @override
  String get syJob_step_look => 'Looking at the host';

  @override
  String get syJob_step_model_download => 'The model';

  @override
  String get syJob_step_model_prepare => 'Preparing it for the page';

  @override
  String get syJob_step_move => 'Copying to the new disk';

  @override
  String get syJob_step_ngram => 'With the n-grams';

  @override
  String get syJob_step_node_check => 'Checking the video (SHA-256)';

  @override
  String syJob_step_node_copy(String node) {
    return 'Copying the files to $node';
  }

  @override
  String syJob_step_node_fetch(String node) {
    return 'Bringing the video back from $node';
  }

  @override
  String syJob_step_node_ffmpeg(String node) {
    return 'Getting ffmpeg ready on $node';
  }

  @override
  String get syJob_step_none => 'The model alone';

  @override
  String get syJob_step_ocr_languages => 'The languages';

  @override
  String get syJob_step_ocr_program => 'The program';

  @override
  String get syJob_step_pihole_check => 'Checking that it answers';

  @override
  String get syJob_step_pihole_image => 'Downloading Pi-hole (only once)';

  @override
  String get syJob_step_pihole_start => 'Starting Pi-hole';

  @override
  String get syJob_step_preload =>
      'Reading the model once, so the first message does not wait for the disk';

  @override
  String get syJob_step_remote_cert => 'Getting the certificate from Let\'s Encrypt';

  @override
  String get syJob_step_remote_connect => 'Connecting to Cloudflare';

  @override
  String get syJob_step_remote_https => 'Getting the safe address (HTTPS)';

  @override
  String get syJob_step_remote_image => 'Downloading what is needed (only once)';

  @override
  String get syJob_step_remote_login => 'Waiting for you to sign in to Tailscale';

  @override
  String get syJob_step_remote_start => 'Starting it';

  @override
  String get syJob_step_restore => 'Putting the engine back as it was';

  @override
  String get syJob_step_run => 'Running the steps on the host';

  @override
  String get syJob_step_searxng_check => 'Checking that it answers';

  @override
  String get syJob_step_searxng_image => 'Downloading SearXNG (only once)';

  @override
  String get syJob_step_searxng_start => 'Starting it';

  @override
  String get syJob_step_start => 'Starting the engine';

  @override
  String get syJob_step_switch => 'Starting the model on Windows';

  @override
  String get syJob_step_tool_download => 'Downloading';

  @override
  String get syJob_step_tool_unpack => 'Unpacking';

  @override
  String get syJob_step_try => 'Trying an answer';

  @override
  String get syJob_step_tune => 'Measuring this computer to pick the fastest setting';

  @override
  String get syJob_step_verify => 'Reading the backup back';

  @override
  String get syJob_step_video_derive => 'Making the file';

  @override
  String get syJob_step_video_probe => 'Reading the file';

  @override
  String get syJob_step_video_render => 'Rendering with ffmpeg';

  @override
  String get syJob_step_video_save => 'Saving it in the project';

  @override
  String get syJob_step_video_silences => 'Finding the silences';

  @override
  String get syJob_step_video_sound => 'Taking the sound';

  @override
  String get syJob_step_video_transcribe => 'Writing down the words';

  @override
  String get syJob_step_video_wait => 'Waiting for the render before it';

  @override
  String syKcImported(String n) {
    return '$n credentials added to the keychain.';
  }

  @override
  String get syKcPassphrase => 'Passphrase';

  @override
  String get syKcPassphraseHelp =>
      'At least 8 characters. Keep it somewhere safe: it cannot be recovered.';

  @override
  String get syLmRecommended => 'recommended';

  @override
  String get syLoginCode => 'Code from the app (6 digits)';

  @override
  String get syMcAdd => 'Add';

  @override
  String get syMcAuthKey => 'Key';

  @override
  String get syMcAuthPassword => 'Password';

  @override
  String get syMcChangedNow => 'Now';

  @override
  String syMcChangedText(String name) {
    return 'Another computer may be in the place of «$name». Nothing was sent and the connection was refused. Trust the new key only if you know why it changed (the system was reinstalled, the machine was replaced).';
  }

  @override
  String get syMcChangedTitle => 'Danger: the machine answered with another key';

  @override
  String get syMcChangedWas => 'Trusted';

  @override
  String get syMcCopied => 'Copied';

  @override
  String get syMcCopy => 'Copy';

  @override
  String get syMcCopyKey => 'Copy the public key';

  @override
  String get syMcEdit => 'Change';

  @override
  String get syMcEditorLead =>
      'Where the machine is and who logs in. The key or the password goes straight into the keychain.';

  @override
  String get syMcEmpty =>
      'No machine yet. Add one: Rasgeth makes a key for it, you copy its public half onto the machine.';

  @override
  String get syMcFolder => 'Working folder';

  @override
  String get syMcFolderHelp =>
      'Where commands start; deleting outside it always asks you. A full path (/srv/app, ~/app, or on Windows E:\\coding\\site). Leave empty for the home.';

  @override
  String get syMcFolderNone => 'the home (every deletion asks you)';

  @override
  String get syMcHost => 'Address';

  @override
  String get syMcHostHelp => 'Its name or IP address on the network.';

  @override
  String get syMcHostKey => 'Machine\'s key';

  @override
  String get syMcKeyGenerate => 'Make a new key';

  @override
  String get syMcKeyGenerateHelp =>
      'Rasgeth makes an ed25519 key: you will copy its public half into ~/.ssh/authorized_keys on the machine.';

  @override
  String get syMcKeyKeep => 'Keep the key';

  @override
  String get syMcKeyKeepHelp => 'The key kept in the keychain stays as it is.';

  @override
  String get syMcKeyPaste => 'Paste a private key';

  @override
  String get syMcLead =>
      'Other computers your agents reach over SSH: a server, a Raspberry Pi, a computer at the office. Keys and passwords stay in the keychain; the agents choose a machine by its name and never see them.';

  @override
  String get syMcLogin => 'Login';

  @override
  String get syMcLoginGenerated => 'key made by Rasgeth, in the keychain';

  @override
  String get syMcLoginImported => 'your key, in the keychain';

  @override
  String get syMcLoginPassword => 'password in the keychain';

  @override
  String get syMcName => 'Name';

  @override
  String get syMcNameHelp =>
      'How agents call it: letters, digits, dot, dash, no spaces (web, pi, office).';

  @override
  String get syMcNew => 'Add a machine';

  @override
  String get syMcNewKey => 'Make a new key';

  @override
  String get syMcNewKeyQ => 'Make a new key for this machine?';

  @override
  String get syMcNewKeyText =>
      'The old key stops working here: copy the new public key onto the machine and remove the old one.';

  @override
  String get syMcPassphrase => 'Its passphrase (if it has one)';

  @override
  String get syMcPassword => 'Password';

  @override
  String get syMcPasswordHelp =>
      'Kept in the keychain. A key is safer: a password travels at every login.';

  @override
  String get syMcPasswordKept => 'The password in the keychain stays unless you write a new one.';

  @override
  String get syMcPort => 'Port';

  @override
  String get syMcPrivateKey => 'Private key';

  @override
  String get syMcPrivateKeyHelp =>
      'OpenSSH or PEM. It goes into the keychain and is never shown again.';

  @override
  String get syMcPrivateKeyPlaceholder => '-----BEGIN OPENSSH PRIVATE KEY-----';

  @override
  String get syMcProject => 'project';

  @override
  String get syMcPublicKey => 'Public key';

  @override
  String get syMcPublicKeyHelp =>
      'Copy it into ~/.ssh/authorized_keys of the user on the machine (one line), then test the connection.';

  @override
  String syMcRemoveQ(String name) {
    return 'Remove «$name»?';
  }

  @override
  String get syMcRemoveText =>
      'Its key or password leaves the keychain; agents can no longer use it. Remove the public key from the machine too.';

  @override
  String syMcReplaceQ(String name) {
    return 'Trust the new key of «$name»?';
  }

  @override
  String get syMcReplaceText =>
      'Do it only if you know why the machine\'s key changed: otherwise someone could be reading what Rasgeth sends.';

  @override
  String get syMcReplaceYes => 'Trust the new key';

  @override
  String get syMcSafety =>
      'What happens there follows the same rules as here: sudo, switching the machine off, installing system programs, changing its system files and deleting outside its working folder always ask you, also with «Don\'t ask me anything».';

  @override
  String get syMcSave => 'Save';

  @override
  String get syMcSection => 'Machines';

  @override
  String get syMcStateFailed => 'Last test failed';

  @override
  String get syMcStateNew => 'Not checked yet';

  @override
  String get syMcStateTrusted => 'Key trusted';

  @override
  String get syMcTest => 'Test the connection';

  @override
  String get syMcTestAuth =>
      'The machine refused the login: is the public key in ~/.ssh/authorized_keys (or the password right)?';

  @override
  String syMcTestError(String message) {
    return 'It did not work: $message';
  }

  @override
  String get syMcTestNoSecret =>
      'There is no key or password in the keychain for this machine: change it and set one.';

  @override
  String syMcTestOk(String system) {
    return 'Connected: $system';
  }

  @override
  String get syMcTestTimeout => 'The machine did not answer in time.';

  @override
  String get syMcTestUnreachable =>
      'The machine cannot be reached: check the address and that it is on.';

  @override
  String get syMcTesting => 'Connecting…';

  @override
  String get syMcTitle => 'Your machines';

  @override
  String get syMcTofuHow =>
      'To see it on the machine: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub';

  @override
  String get syMcTofuText =>
      'Nothing was sent yet. If the fingerprint is the machine\'s, trust it: from now on Rasgeth connects only to a machine with this key.';

  @override
  String get syMcTofuTitle => 'First connection: is this the machine\'s key?';

  @override
  String get syMcTrust => 'Trust this key';

  @override
  String get syMcUser => 'User';

  @override
  String get syMcWho => 'Who may use it';

  @override
  String get syMcWhoAgents => 'Agents';

  @override
  String get syMcWhoEveryone => 'Every agent';

  @override
  String get syMcWhoEveryoneHelp => 'God, the assistants and every project\'s agents.';

  @override
  String get syMcWhoLead => 'The agents not chosen do not even see it.';

  @override
  String get syMcWhoNoAgents => 'There are no agents yet.';

  @override
  String get syMcWhoNobody => 'nobody yet';

  @override
  String get syMcWhoProjects => 'Every agent of these projects';

  @override
  String get syNdAddButton => 'Show a pairing code';

  @override
  String get syNdAddLead =>
      'On the other machine, in its first start (role «Node of another Rasgeth») or in its Settings › Nodes, write this machine\'s address and the code below.';

  @override
  String get syNdAddTitle => 'Add a node';

  @override
  String get syNdAddress => 'The other Rasgeth\'s address';

  @override
  String get syNdAddressPh => 'https://rasgeth.local or 192.168.1.10:3000';

  @override
  String get syNdAdmin => 'uses and manages';

  @override
  String syNdBackupDone(String name) {
    return 'Copied to the node: $name';
  }

  @override
  String get syNdBackupNow => 'Copy now';

  @override
  String get syNdBackupsOn => 'Backups';

  @override
  String get syNdCode => 'Pairing code';

  @override
  String syNdCodeAddress(String address) {
    return 'This machine\'s address, as the other one reaches it (in the local network, through Tailscale or a proxy): $address';
  }

  @override
  String syNdCodeExpires(String min) {
    return 'Valid once, for $min more minutes.';
  }

  @override
  String get syNdCodeField => 'Its code';

  @override
  String get syNdCodePh => 'ABCD-EFGH';

  @override
  String get syNdCodeStop => 'Stop showing it';

  @override
  String get syNdCommandsOn => 'Commands';

  @override
  String get syNdConfirm => 'They match: confirm';

  @override
  String get syNdConnecting => 'Connecting';

  @override
  String get syNdControl => 'Control';

  @override
  String get syNdControlLead =>
      'Never implicit: a machine commands another only with this grant, which the commanded machine keeps and can take away.';

  @override
  String syNdControlTitle(String name) {
    return 'Who may command $name';
  }

  @override
  String get syNdController => 'Which machine';

  @override
  String syNdCpu(String n) {
    return '$n CPU';
  }

  @override
  String get syNdFingerprint => 'Its key\'s fingerprint';

  @override
  String syNdFree(String n) {
    return '$n GB free';
  }

  @override
  String get syNdGive => 'Give';

  @override
  String get syNdGrantsHere => 'Who may command this machine';

  @override
  String get syNdGrantsLead =>
      'Only these machines may use this one, each with what the person gave it. Taking it away works at once.';

  @override
  String get syNdHere => 'Here';

  @override
  String get syNdJoinLead =>
      'Pair this machine as a node of another Rasgeth: on that one, Settings › Nodes › «Add a node» shows its address and a code.';

  @override
  String get syNdJoinTitle => 'Work for another Rasgeth';

  @override
  String syNdLastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String get syNdLead =>
      'Other Rasgeth machines that work with this one: they lend commands, local models and room for projects and backups. Who may command whom is decided here, machine by machine.';

  @override
  String syNdLoad(String n) {
    return 'load $n%';
  }

  @override
  String syNdModels(String n) {
    return '$n models';
  }

  @override
  String get syNdName => 'Name';

  @override
  String get syNdNameHelp => 'How the other machines and the agents call it.';

  @override
  String get syNdNoContainer => 'commands only for who manages it';

  @override
  String get syNdNoContainerHelp =>
      'There is no container there (no Docker): it runs commands only for a machine that manages it, on the machine itself. With «use» alone, files, storage and models only.';

  @override
  String get syNdNoNodes => 'No node yet.';

  @override
  String get syNdNoProjects => 'No project yet.';

  @override
  String get syNdNoRights => 'No permissions';

  @override
  String get syNdNoSandbox => 'no commands';

  @override
  String get syNdNodeName => 'Name of the node';

  @override
  String get syNdNodeNameHelp =>
      'How you, the agents and the requests call it here. Empty: the name it gives itself.';

  @override
  String get syNdNotReady =>
      'Nodes need the keychain: this machine\'s key lives only there. Open it in Settings › Keychain.';

  @override
  String get syNdOffline => 'Offline';

  @override
  String get syNdOnline => 'Online';

  @override
  String get syNdPair => 'Pair';

  @override
  String get syNdPairing => 'Pairing…';

  @override
  String get syNdParent => 'Works for';

  @override
  String get syNdPending => 'Waiting for the yes on the other machine';

  @override
  String syNdPendingFromNode(String name) {
    return '$name wants to be a node of this machine';
  }

  @override
  String syNdPendingFromPrincipal(String name) {
    return 'This machine will work for $name';
  }

  @override
  String get syNdPendingLead =>
      'Both machines show the same six digits and each other\'s fingerprint. If they match on both screens, confirm on both: nothing is used before.';

  @override
  String get syNdPendingTitle => 'Compare and confirm';

  @override
  String get syNdPlaces => 'Where things run';

  @override
  String get syNdPlacesLead =>
      'For each project: by default everything stays here. A node pinned for commands is where its agents\' node_run goes; one for backups keeps copies of its files.';

  @override
  String get syNdQ => 'Nodes';

  @override
  String syNdRam(String n) {
    return '$n GB RAM';
  }

  @override
  String get syNdReason => 'Why';

  @override
  String get syNdRefused => 'Refused: its key changed';

  @override
  String get syNdReject => 'They do not match';

  @override
  String get syNdRename => 'Rename';

  @override
  String syNdRenameQ(String name) {
    return 'A name for $name';
  }

  @override
  String get syNdRenderOn => 'Videos';

  @override
  String get syNdRevoke => 'Take away';

  @override
  String syNdRevokeQ(String name) {
    return 'Take away what $name may do here?';
  }

  @override
  String get syNdRightAdmin => 'Manage it';

  @override
  String get syNdRightAdminHelp =>
      'Give and take away the control of this machine to other machines, and write outside the sandbox.';

  @override
  String get syNdRightUse => 'Use it';

  @override
  String get syNdRightUseHelp =>
      'Run its agents\' commands in a sandbox here, use its models and keep files here.';

  @override
  String get syNdRights => 'What it may do';

  @override
  String syNdRightsTitle(String name) {
    return 'What $name may do on this machine';
  }

  @override
  String get syNdSas => 'The six digits';

  @override
  String get syNdSection => 'Nodes';

  @override
  String get syNdTheirFp => 'The other machine\'s fingerprint';

  @override
  String get syNdThis => 'This machine';

  @override
  String get syNdTree => 'The tree';

  @override
  String get syNdTreeLead =>
      'This machine, its nodes and theirs. Control is separate: it is shown under each machine.';

  @override
  String get syNdUnpair => 'Unpair';

  @override
  String syNdUnpairQ(String name) {
    return 'Unpair $name?';
  }

  @override
  String get syNdUnpairText =>
      'The two machines forget each other: links, grants and placements with it go. Its files stay where they are. To pair again, a new code.';

  @override
  String get syNdUse => 'uses';

  @override
  String get syNdWho => 'Who may command it';

  @override
  String get syNdWhoNobody => 'Nobody but itself';

  @override
  String get syOiAddress => 'Rasgeth\'s address in the network';

  @override
  String syOiAddressHelp(String port) {
    return 'Where the proxy or the VPN finds Rasgeth; its port is $port.';
  }

  @override
  String get syOiAuthCaddy =>
      'Caddyfile with forward auth (Authelia), leaving out the app\'s paths';

  @override
  String get syOiAuthIf =>
      'If you want it anyway, leave /api/ and /ws out of it: forward auth then guards the page, and Rasgeth\'s password everything else.';

  @override
  String get syOiAuthTitle => 'Authelia, Authentik or another forward auth in front?';

  @override
  String get syOiAuthWhy =>
      'Better not: Rasgeth has its own password, with limited tries and the optional code from an authenticator app, and a sign-in in front of it blocks the app, the command line, ACP agents, the browser extension and the webhooks (Telegram, WhatsApp, automations), which come in with their own tokens.';

  @override
  String get syOiCaddy => 'Caddyfile: a site of its own';

  @override
  String get syOiCaddyReload => 'Then reload Caddy (caddy reload, or restart its container).';

  @override
  String syOiCaddyWildcard(String domain) {
    return 'Caddyfile: inside a wildcard site you already have (*.$domain)';
  }

  @override
  String get syOiCheck => 'Check that it answers';

  @override
  String get syOiCheckAnswers =>
      'Something answers at this address (the browser does not let the page read who): open it to see Rasgeth.';

  @override
  String syOiCheckGo(String url) {
    return 'Check $url from here';
  }

  @override
  String syOiCheckLead(String lb, String rb) {
    return 'From any computer: Rasgeth answers $lb\"ok\":true,…$rb.';
  }

  @override
  String get syOiCheckNo =>
      'No answer from this browser: check the name in the DNS, the proxy\'s block and, from outside, the VPN.';

  @override
  String get syOiCheckRedgiant => 'Rasgeth answers at this address.';

  @override
  String get syOiClose => 'Hide the guide';

  @override
  String get syOiCopied => 'Copied';

  @override
  String get syOiCopy => 'Copy';

  @override
  String syOiDnsAdguard(String address, String domain) {
    return 'AdGuard Home: Filters › DNS rewrites: *.$domain or the single name → $address.';
  }

  @override
  String get syOiDnsLead =>
      'A name instead of an address: point it to the proxy when there is one, otherwise to Rasgeth\'s address.';

  @override
  String syOiDnsPihole(String address, String name) {
    return 'Pi-hole: Settings › Local DNS › DNS Records: $name → $address.';
  }

  @override
  String get syOiDnsRouter =>
      'The router: its «static DNS», «local names» or DHCP reservation page (the name varies by router).';

  @override
  String get syOiDnsTs =>
      'Away from home with Tailscale: add the home DNS in Tailscale\'s DNS › Nameservers, restricted to your domain, so the same names work outside too.';

  @override
  String syOiDnsWildcard(String domain) {
    return 'Pi-hole or dnsmasq, every name of *.$domain at once (a file in /etc/dnsmasq.d/)';
  }

  @override
  String syOiHomeAdguard(String address, String name) {
    return 'AdGuard Home: Filters › DNS rewrites: $name → $address.';
  }

  @override
  String get syOiHomeDnsmasq => 'dnsmasq (or a file in Pi-hole\'s /etc/dnsmasq.d/)';

  @override
  String get syOiHomeHosts => 'Pi-hole\'s records or /etc/hosts, by hand';

  @override
  String get syOiHomeLookup => 'On Rasgeth OS, what its DNS answers for the name';

  @override
  String syOiHomePihole(String address, String name) {
    return 'Pi-hole: Settings › Local DNS › DNS Records: $name → $address.';
  }

  @override
  String syOiHomeRouter(String address, String name) {
    return 'The router: its «static DNS» or «local names» page: $name → $address.';
  }

  @override
  String syOiHomeSeen(String dns) {
    return 'Rasgeth asks the name server $dns.';
  }

  @override
  String get syOiHomeTitle => 'Your home services (Gitea, NAS…) seen by Rasgeth';

  @override
  String get syOiHomeTs =>
      'If your Pi-hole answers with Tailscale addresses (100.…), those work only for devices in Tailscale: add a local record with the address in your network as above, or let Rasgeth\'s machine use the router as DNS with the name there.';

  @override
  String get syOiHomeV6 =>
      'A router that answers «does not exist» to the IPv6 (AAAA) question for names added by hand: Rasgeth OS handles it already; on other systems with systemd-resolved, put Cache=no-negative in a file of /etc/systemd/resolved.conf.d/, or the name seems missing for a while.';

  @override
  String get syOiHomeWhat => 'In the DNS Rasgeth uses, give the name that local address:';

  @override
  String get syOiHomeWhich =>
      'Which DNS Rasgeth uses: on Rasgeth OS the console (or SSH) shows it with the command below, under «Current DNS Server»; on another computer it is that computer\'s DNS (its network settings, /etc/resolv.conf on Linux). «Try a name» asks the very DNS Rasgeth uses.';

  @override
  String get syOiHomeWhichCmd => 'On Rasgeth OS, which DNS it uses';

  @override
  String get syOiHomeWhy =>
      'Rasgeth reaches your Gitea, NAS or other services by name, through the DNS of the machine it runs on (often the router). A name your phone opens may be unknown there, or point to an address Rasgeth cannot reach: then «A Gitea you already have» fails even though the service works.';

  @override
  String get syOiLead =>
      'A reverse proxy, a VPN, a home DNS: if you already reach your machines that way, Rasgeth goes behind them like any other service. Here are the blocks to copy.';

  @override
  String get syOiName => 'Rasgeth\'s name';

  @override
  String get syOiNameHelp => 'The name you will open, e.g. rasgeth.home.example.com.';

  @override
  String syOiNpm1(String name) {
    return 'Hosts › Proxy Hosts › Add Proxy Host; Domain Names: $name.';
  }

  @override
  String syOiNpm2(String address, String port) {
    return 'Scheme http, Forward Hostname / IP $address, Forward Port $port.';
  }

  @override
  String get syOiNpm3 =>
      'Switch on «Websockets Support» (Rasgeth\'s page lives on a WebSocket) and «Block Common Exploits».';

  @override
  String get syOiNpm4 =>
      'SSL: «Request a new SSL Certificate», «Force SSL», «HTTP/2 Support». Save.';

  @override
  String get syOiOpen => 'Show the guide';

  @override
  String get syOiOtherVpn => 'WireGuard, ZeroTier and the others';

  @override
  String syOiOtherVpnLead(String subnet) {
    return 'The same idea: with the home network $subnet in the peer\'s AllowedIPs (WireGuard) or as a managed route (ZeroTier), Rasgeth opens at its home address.';
  }

  @override
  String get syOiPart => 'What you have';

  @override
  String get syOiPartDns => 'Home DNS';

  @override
  String get syOiPartHome => 'Your home services';

  @override
  String get syOiPartProxy => 'Reverse proxy';

  @override
  String get syOiPartVpn => 'Tailscale or another VPN';

  @override
  String get syOiProbe => 'Try a name';

  @override
  String get syOiProbeBad => 'That is not a name (for instance git.home.example.com).';

  @override
  String syOiProbeDnsFailed(String name) {
    return 'The DNS Rasgeth uses did not answer for $name. Check that it works, then try again.';
  }

  @override
  String syOiProbeGo(String name) {
    return 'Try $name';
  }

  @override
  String syOiProbeLead(String name) {
    return 'Rasgeth looks the name up and opens https://$name from where it runs, as it does for your Gitea. Nothing of the answer is kept or shown but its code.';
  }

  @override
  String syOiProbeNotFound(String name) {
    return 'The DNS Rasgeth uses does not know $name. Add the name there (router, Pi-hole or AdGuard) with the proxy\'s local address, then try again.';
  }

  @override
  String syOiProbeOk(String address, String name, String status) {
    return 'Fine: here $name is $address, and https://$name answered (HTTP $status).';
  }

  @override
  String syOiProbeTailscale(String address, String name) {
    return 'Here $name is $address: a Tailscale address, which Rasgeth cannot reach. In the DNS Rasgeth uses, give the name the proxy\'s local address.';
  }

  @override
  String syOiProbeTimeout(String address, String name) {
    return 'Here $name is $address, but it did not answer in time: probably an address Rasgeth cannot reach (another network, a VPN).';
  }

  @override
  String syOiProbeTls(String address, String name) {
    return 'Here $name is $address and answers, but with a certificate Rasgeth does not trust (made by hand?). Give the proxy a certificate from a public authority (Let\'s Encrypt).';
  }

  @override
  String syOiProbeUnreachable(String address, String name) {
    return 'Here $name is $address, but nothing answers on https from Rasgeth. Check that it is the proxy\'s local address and that the proxy is running.';
  }

  @override
  String get syOiProxyAddr => 'The proxy\'s local address';

  @override
  String get syOiProxyAddrHelp =>
      'The address in your network (192.168.…) of the proxy in front of the service, or of the service itself. Not a Tailscale address (100.…): Rasgeth reaches it only if it is in Tailscale too.';

  @override
  String get syOiProxyLead =>
      'The proxy can be on another machine: it only needs to reach Rasgeth\'s address. It gets the certificate (HTTPS) and sends everything on, the WebSocket included.';

  @override
  String syOiReachedAs(String host) {
    return 'You are reachable already as $host.';
  }

  @override
  String get syOiReachedName =>
      'This page came with a name of your network: at home it works already; from outside one of the ways below is needed (Tailscale, for instance).';

  @override
  String get syOiReachedProxy =>
      'This page came through a reverse proxy of your network: the guide below is filled with what Rasgeth saw.';

  @override
  String get syOiSaid =>
      'You said Rasgeth is reachable already your own way: it does not ask again to set up its ways.';

  @override
  String get syOiSaidUndo => 'Ask again';

  @override
  String syOiSaidUrl(String url) {
    return 'You said Rasgeth is reachable already at $url: it does not ask again to set up its ways, and its links (Telegram…) use that address.';
  }

  @override
  String get syOiService => 'The service\'s name';

  @override
  String get syOiServiceHelp => 'As you open it, e.g. git.home.example.com.';

  @override
  String get syOiSkip => 'Skip: I am reachable already';

  @override
  String get syOiSkipNote =>
      'Rasgeth stops asking to set up its own ways out (Tailscale, Cloudflare, its own domain); they stay here if you want one later.';

  @override
  String get syOiTitle => 'Already have your own infrastructure';

  @override
  String get syOiTraefik => 'Traefik: file provider (dynamic configuration)';

  @override
  String get syOiTraefikNote =>
      'With Docker labels instead: the same rule and the URL as a service with loadbalancer.server.url. Use your entry point and certificate resolver names.';

  @override
  String get syOiTsHere => 'Tailscale on Rasgeth\'s machine';

  @override
  String get syOiTsHereLead =>
      'Install Tailscale on the machine and sign in (tailscale up): from your devices in the tailnet Rasgeth opens at http://<machine>:7600. For HTTPS with a real certificate:';

  @override
  String syOiTsRunning(String name) {
    return 'Tailscale runs here already as $name: from your devices in the tailnet Rasgeth opens with that name. For HTTPS with a real certificate:';
  }

  @override
  String get syOiTsServe => 'On the machine';

  @override
  String get syOiTsSubnet => 'Tailscale as a subnet router';

  @override
  String syOiTsSubnetLead(String subnet) {
    return 'Tailscale on another device of the house (the router, a Pi, the proxy\'s machine) that shares the network $subnet:';
  }

  @override
  String syOiTsSubnetThen(String address, String port) {
    return 'Approve the route in Tailscale\'s admin console (Machines › Edit route settings). Your phone then opens http://$address:$port from anywhere, and the names of your home DNS too if you add it in DNS › Nameservers (restricted to your domain).';
  }

  @override
  String get syOiWs =>
      'Rasgeth keeps the page live through a WebSocket at /ws: Caddy and Traefik pass it on by themselves; Nginx needs the Upgrade headers (Websockets Support in Nginx Proxy Manager).';

  @override
  String get syOnline => 'connected';

  @override
  String get syOpen => 'open';

  @override
  String get syOsErr_bad_password => 'A Wi-Fi password has 8 to 63 characters.';

  @override
  String get syOsErr_bad_ssid => 'A network\'s name has 1 to 32 characters.';

  @override
  String get syOsErr_busy => 'The machine is already joining a network: wait a moment.';

  @override
  String get syOsErr_cannot_https => 'HTTPS is not managed by this installation.';

  @override
  String get syOsErr_cannot_reboot => 'Restarts are not managed by this installation.';

  @override
  String get syOsErr_cannot_update => 'Updates are not managed by this installation.';

  @override
  String get syOsErr_cannot_wifi => 'Wi-Fi is not managed by this installation.';

  @override
  String get syOsErr_clean_install => 'This version needs a clean install.';

  @override
  String get syOsErr_connect_failed =>
      'The network refused to connect: check the password and try again.';

  @override
  String get syOsErr_failed => 'That did not work. Try again in a moment.';

  @override
  String get syOsErr_https_failed => 'Local HTTPS did not start.';

  @override
  String get syOsErr_https_off => 'Local HTTPS is off: switch it on first.';

  @override
  String get syOsErr_manual => 'This installation cannot update by itself.';

  @override
  String get syOsErr_no_wifi => 'This machine has no Wi-Fi card.';

  @override
  String get syOsErr_not_found => 'That network is not in reach now.';

  @override
  String get syOsErr_not_installed => 'This system cannot do that.';

  @override
  String get syOsErr_not_trusted => 'This device does not trust the certificate yet.';

  @override
  String get syOsErr_reboot_failed => 'The restart could not be scheduled.';

  @override
  String get syOsErr_start_failed => 'The update could not start.';

  @override
  String get syOsErr_timeout => 'The machine took too long to answer.';

  @override
  String get syOsErr_tls_failed => 'The certificate could not be made.';

  @override
  String get syOsErr_unreachable => 'The machine\'s helper did not answer.';

  @override
  String get syOsErr_wifi_off => 'Wi-Fi is not running on this machine.';

  @override
  String get syOsHttpsAddress => 'Address';

  @override
  String get syOsHttpsCheck => 'Check this device';

  @override
  String get syOsHttpsDevice => 'Your device';

  @override
  String get syOsHttpsDownload => 'Download the certificate';

  @override
  String get syOsHttpsFingerprint => 'Certificate\'s fingerprint (SHA-256)';

  @override
  String get syOsHttpsFirefox =>
      'Firefox on any system: Settings › Privacy & Security › Certificates › View Certificates › Authorities › Import, tick «Trust this CA to identify websites».';

  @override
  String get syOsHttpsHow_android =>
      'Settings › Security (or Security & privacy) › More › Encryption & credentials › Install a certificate › CA certificate: «Install anyway», choose Rasgeth-CA.crt.';

  @override
  String get syOsHttpsHow_iphone =>
      'Open the download in Safari, «Allow». Settings › General › VPN & Device Management: install the profile. Then Settings › General › About › Certificate Trust Settings: switch on «Rasgeth on …».';

  @override
  String get syOsHttpsHow_linux =>
      'Debian/Ubuntu: sudo cp Rasgeth-CA.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates. Chrome and Firefox keep their own list: add it under the browser\'s certificate settings (Authorities, «Import»).';

  @override
  String get syOsHttpsHow_mac =>
      'Open Rasgeth-CA.crt: Keychain Access adds it. Double-click «Rasgeth on …» in the login keychain, open «Trust», set «When using this certificate» to «Always Trust», close and type your password.';

  @override
  String get syOsHttpsHow_windows =>
      'Open Rasgeth-CA.crt, «Install certificate…», «Current user», «Place all certificates in the following store», «Trusted Root Certification Authorities», Finish, Yes. Restart the browser.';

  @override
  String syOsHttpsInFront(String name) {
    return 'You already reach Rasgeth over HTTPS through $name: the local certificate is not needed for that address.';
  }

  @override
  String get syOsHttpsLocal => 'HTTPS in the local network';

  @override
  String get syOsHttpsLocalOff =>
      'Off: Rasgeth answers on http only (or through the HTTPS you set up yourself).';

  @override
  String syOsHttpsLocalOn(String name) {
    return 'https://$name and the machine\'s addresses answer with a certificate of this machine. http keeps working until you say it is trusted.';
  }

  @override
  String get syOsHttpsNotYet =>
      'This device does not trust the certificate yet (or https://… does not answer): nothing has changed, http keeps working.';

  @override
  String get syOsHttpsNowOnly =>
      'This device trusts it. From now on http goes to https for the machine\'s local name and addresses.';

  @override
  String get syOsHttpsOffQ => 'Switch local HTTPS off?';

  @override
  String get syOsHttpsOffText =>
      'Browsers that already went to https://rasgeth.local keep asking for https for up to 30 days: in those, open the machine by its address (http://192.168…:7600) until then.';

  @override
  String get syOsHttpsOffYes => 'Switch off';

  @override
  String get syOsHttpsQ => 'Should the browser show the padlock on your home network?';

  @override
  String get syOsHttpsQr => 'QR code to download the certificate';

  @override
  String get syOsHttpsQrHelp => 'On a phone on the same network, scan the code to download it.';

  @override
  String get syOsHttpsRedirect => 'Always send to HTTPS';

  @override
  String get syOsHttpsRedirectOn =>
      'http requests in your network go to https; browsers remember it (HSTS, 30 days). Devices without the certificate show a warning: install it there too.';

  @override
  String get syOsHttpsTitle => 'HTTPS in your network';

  @override
  String get syOsHttpsTrustLead =>
      'Download it on the device (phone: scan the code), install it as below, then press «Check this device». The certificate works only for this machine\'s local names and addresses, never for any website.';

  @override
  String get syOsHttpsTrustTitle => 'Trust the certificate on each device';

  @override
  String get syOsHttpsUntil => 'The machine\'s certificate renews itself before';

  @override
  String get syOsNetSub => 'Network';

  @override
  String get syOsNetSubLead =>
      'How the machine joins the network, and HTTPS for the pages of your home network.';

  @override
  String get syOsRebootNow => 'Restart now';

  @override
  String get syOsRebootQ => 'Restart the machine now?';

  @override
  String get syOsRebootText =>
      'Rasgeth stops for two or three minutes while the machine restarts; agents working now are interrupted and pick up again from what was saved. This page comes back by itself.';

  @override
  String get syOsRebootYes => 'Restart';

  @override
  String get syOsRebooting =>
      'The machine restarts in a few seconds. This page comes back by itself.';

  @override
  String get syOsSecLast => 'Last time';

  @override
  String syOsSecLastAt(String when) {
    return '$when';
  }

  @override
  String syOsSecLastN(String n, String when) {
    return '$when, $n packages';
  }

  @override
  String get syOsSecNever => 'Not yet (it runs once a day)';

  @override
  String get syOsSecNoReboot => 'Nothing waits for a restart.';

  @override
  String get syOsSecQ => 'The system installs Debian\'s security updates by itself, every day.';

  @override
  String get syOsSecReboot => 'An update asks for a restart to finish';

  @override
  String get syOsSecTitle => 'System security updates';

  @override
  String syOsUpdApply(String version) {
    return 'Update to $version';
  }

  @override
  String syOsUpdApplyQ(String version) {
    return 'Update Rasgeth to $version?';
  }

  @override
  String get syOsUpdApplyText =>
      'The machine downloads the new version while this one keeps working, then restarts Rasgeth: the page stops for a few minutes and comes back by itself. Nothing is lost, and if the new version does not start the previous one comes back.';

  @override
  String get syOsUpdApplyYes => 'Update now';

  @override
  String get syOsUpdBreaking =>
      'This version cannot be installed over the current one: Rasgeth guides you (backup on a USB disk, reinstall Rasgeth OS, restore).';

  @override
  String get syOsUpdChecked => 'Last look';

  @override
  String get syOsUpdInstalled => 'Installed';

  @override
  String get syOsUpdQ => 'Is Rasgeth up to date on this machine?';

  @override
  String get syOsUpdState => 'State';

  @override
  String get syOsUpdSub => 'Updates';

  @override
  String get syOsUpdSubLead => 'Rasgeth and the system it runs on, kept up to date.';

  @override
  String get syOsUpdTitle => 'Rasgeth';

  @override
  String syOsUpd_applying(String version) {
    return 'Updating to $version';
  }

  @override
  String syOsUpd_available(String version) {
    return 'Rasgeth $version is ready to install';
  }

  @override
  String syOsUpd_breaking(String version) {
    return 'Rasgeth $version needs a clean install';
  }

  @override
  String get syOsUpd_error => 'The last update did not finish (the previous version is running)';

  @override
  String get syOsUpd_latest => 'Up to date';

  @override
  String get syOsUpd_unknown => 'Not looked yet';

  @override
  String get syOsUpd_unreachable => 'Could not reach GitHub to look';

  @override
  String syOsUpd_unsigned(String version) {
    return 'Rasgeth $version is out, but without a signed package for Rasgeth OS yet: it comes with a later release';
  }

  @override
  String get syOsWifi8021x => 'company network (not from here)';

  @override
  String syOsWifiConnectedTo(String ip, String name) {
    return 'Connected to «$name» ($ip)';
  }

  @override
  String get syOsWifiForget => 'Forget';

  @override
  String syOsWifiForgetQ(String name) {
    return 'Forget «$name»?';
  }

  @override
  String get syOsWifiForgetText =>
      'The machine stops joining this network and its password is erased. If it is the network in use and there is no cable, the page stops answering until the machine has another network.';

  @override
  String get syOsWifiGood => 'good signal';

  @override
  String get syOsWifiHidden => 'Hidden network…';

  @override
  String get syOsWifiHiddenName => 'The network\'s name';

  @override
  String get syOsWifiInReach => 'Networks in reach';

  @override
  String get syOsWifiInUse => 'in use';

  @override
  String get syOsWifiJoin => 'Join';

  @override
  String syOsWifiJoined(String name) {
    return 'Connected to «$name». If you are using this page over that network, it keeps working.';
  }

  @override
  String get syOsWifiJoining => 'Joining…';

  @override
  String get syOsWifiKnown => 'saved';

  @override
  String syOsWifiKnownAway(String names) {
    return 'Saved, not in reach now: $names';
  }

  @override
  String get syOsWifiLooking => 'Looking…';

  @override
  String get syOsWifiNone => 'No network found. Look again, or join a hidden network by its name.';

  @override
  String get syOsWifiNotConnected => 'Not connected to a Wi-Fi network';

  @override
  String get syOsWifiNow => 'Now';

  @override
  String syOsWifiPassword(String name) {
    return 'Password of «$name»';
  }

  @override
  String get syOsWifiPasswordHelp =>
      '8 to 63 characters. It is kept only on the machine, readable by the system alone; Rasgeth never stores or shows it.';

  @override
  String get syOsWifiQ => 'Which wireless network does the machine join?';

  @override
  String syOsWifiSaved(String name) {
    return '«$name» is saved: the machine joins it as soon as it is in reach.';
  }

  @override
  String get syOsWifiScan => 'Look again';

  @override
  String get syOsWifiStrong => 'strong signal';

  @override
  String get syOsWifiTitle => 'Wi-Fi';

  @override
  String get syOsWifiWeak => 'weak signal';

  @override
  String get syOsWifiWhy_failed => 'Wi-Fi could not be read now. Try again in a moment.';

  @override
  String get syOsWifiWhy_no_helper => 'Wi-Fi is managed by the system of this machine.';

  @override
  String get syOsWifiWhy_no_wifi =>
      'This machine has no Wi-Fi card (or the system does not recognise it).';

  @override
  String get syOsWifiWhy_not_installed => 'This system has no Wi-Fi tools.';

  @override
  String get syOsWifiWhy_wifi_off =>
      'Wi-Fi is not running on this machine. Restart it, or connect a cable.';

  @override
  String get syOsWifiWired =>
      'A cable is connected: the machine uses the cable, Wi-Fi stays as a spare.';

  @override
  String get syPiholeAdmin => 'Pi-hole\'s own page, to see what it blocks and allow a site:';

  @override
  String get syPiholeAds => 'About blocking ads';

  @override
  String get syPiholeAdsText =>
      'Pi-hole blocks the names of well-known advertising and tracking services, for every device that uses it, phones and TVs included. Now and then a site or an app needs one of those names to work (some shop links, some streaming apps): it then looks broken.';

  @override
  String get syPiholeAllow =>
      'If a site stops working: open the Pi-hole page, Query Log, find the blocked name and press Allow. To pause all blocking for a few minutes, use Disable blocking in the same page.';

  @override
  String syPiholeAnswers(String domain, String ip) {
    return 'At home, $domain now leads to $ip.';
  }

  @override
  String get syPiholeChanges => 'What changes at home, and how to go back';

  @override
  String get syPiholeDevice =>
      'If your router does not let you change the DNS (some providers\' routers do not), set it on each device instead: in the Wi-Fi network\'s details on phones, in the network adapter\'s settings on computers.';

  @override
  String get syPiholeDomain => 'Your domain (optional)';

  @override
  String get syPiholeDomainHelp =>
      'The address you use from outside, like rasgeth.yourdomain.com: Pi-hole answers for it with the address above. Leave it empty to use Pi-hole only to block ads.';

  @override
  String get syPiholeDomainWrong => 'It must be a name like rasgeth.yourdomain.com.';

  @override
  String get syPiholeIp => 'This computer\'s address at home';

  @override
  String get syPiholeIpHelp =>
      'Four numbers like 192.168.1.50. Find it on the router\'s page among the connected devices, or on this computer: \"ip a\" on Linux, \"ipconfig\" on Windows, System Settings, Network on Mac. Better if the router always gives this computer the same address (address reservation).';

  @override
  String get syPiholeIpWrong =>
      'It must be four numbers from 0 to 255 separated by dots, like 192.168.1.50.';

  @override
  String get syPiholeNeed =>
      'you reach Rasgeth from outside with your own domain, and at home the same link does not open. Many routers cannot send you back to your own house through the internet (the feature is called NAT loopback or hairpin, and theirs lacks it).';

  @override
  String get syPiholeNeedTitle => 'You need it if';

  @override
  String get syPiholeNoNeed =>
      'you use Tailscale or Cloudflare Tunnel: those links work the same at home and outside. You can still turn it on just to block ads, if you like.';

  @override
  String get syPiholeNoNeedTitle => 'You do not need it if';

  @override
  String syPiholeNowRouter(String ip) {
    return 'Last step, yours: on your router (or on each device) set the DNS server to $ip. Until then nothing at home uses Pi-hole.';
  }

  @override
  String get syPiholeOff =>
      'To go back: put the router\'s DNS back as it was (often \"automatic\") and turn Pi-hole off here. Nothing else on your computers changes.';

  @override
  String syPiholeOn(String ip) {
    return 'Pi-hole is on, at $ip.';
  }

  @override
  String get syPiholeOpenAdmin => 'Open Pi-hole';

  @override
  String get syPiholePort => 'Technical details: port 53';

  @override
  String get syPiholePortText =>
      'Pi-hole answers on port 53 (the DNS port) of this computer\'s home address only, not on the internet, and its own page on port 8053. If something on this computer already answers on port 53 (another DNS, or the system\'s own on some Linux systems), Pi-hole cannot start: Rasgeth says so and nothing changes.';

  @override
  String get syPiholeRouter =>
      'For every device at once: open your router\'s page (its address is usually written under the router, like 192.168.1.1), find the DHCP or LAN settings and set the DNS server to this computer\'s home address. Devices pick it up the next time they connect (or restart them).';

  @override
  String get syPiholeSecond =>
      'A second DNS: if this computer is off, devices that only know Pi-hole cannot open any site. As a second DNS you can put your router\'s address or a public one (1.1.1.1): everything keeps working when this computer is off, but devices may sometimes ask the second one and then see ads, or not find your domain at home.';

  @override
  String get syPiholeShowPassword => 'Show its password';

  @override
  String get syPiholeStart => 'Turn on Pi-hole';

  @override
  String get syPiholeStop => 'Turn off Pi-hole';

  @override
  String get syPiholeTest =>
      'How to check: connect your phone to the home Wi-Fi and open your Rasgeth link. If it opens, you do not need Pi-hole for this (you may still want it to block ads). If it does not, but works on mobile data, Pi-hole fixes it.';

  @override
  String get syPiholeTitle => 'The home\'s own DNS, with Pi-hole (optional)';

  @override
  String get syPiholeWhat =>
      'Every device at home asks a DNS server which number is behind a name (for example rasgeth.yourdomain.com). Usually your router or your internet provider answers. Pi-hole is a small DNS that Rasgeth can run on this computer: it answers for your domain with this computer\'s home address, so the link works at home too, and it also blocks advertising and tracking for every device that uses it.';

  @override
  String get syPwSignOutOthersQ => 'Sign out your other devices too?';

  @override
  String get syPwSignOutOthersText =>
      'The other browsers and the apps signed in with the old password stay in if you keep them. Sign them out if you changed it because someone else might know it.';

  @override
  String get syPwSignOutOthersYes => 'Sign them out';

  @override
  String get syRemoteCaddy =>
      'For experts: your domain pointing at home, ports 80 and 443 opened on the router. Anyone on the internet can reach the sign-in page.';

  @override
  String get syRemoteCloudflare =>
      'An address on your own domain (about 10 euros a year), nothing opened on the router. A few more steps on Cloudflare\'s site.';

  @override
  String get syRemoteCode => 'Second check (recommended)';

  @override
  String get syRemoteCodeConfirm => 'Confirm';

  @override
  String get syRemoteCodeHint =>
      'Besides the password, a 6-digit code from an app on your phone (Google Authenticator, Microsoft Authenticator, 2FAS…): someone who learns the password still cannot get in.';

  @override
  String get syRemoteCodeOff => 'Second check off.';

  @override
  String get syRemoteCodeOn => 'Second check on';

  @override
  String get syRemoteCodeQr => 'Scan with the authenticator app';

  @override
  String get syRemoteCodeScan =>
      'Scan the code with the app (or type the key below in it), then write here the 6 digits it shows.';

  @override
  String get syRemoteCodeStart => 'Switch on the second check';

  @override
  String get syRemoteConnect => 'Connect';

  @override
  String get syRemoteHow => 'How to reach it';

  @override
  String get syRemoteNeedsPassword => 'Set the password above first.';

  @override
  String get syRemoteNewPassword => 'New password';

  @override
  String get syRemoteOff => 'Switch off access from outside';

  @override
  String get syRemoteOn => 'Rasgeth can be reached from outside at this address:';

  @override
  String get syRemoteOwnDomain => 'Your domain, open router';

  @override
  String get syRemotePassword => 'Your password';

  @override
  String get syRemotePasswordChange => 'Change it';

  @override
  String get syRemotePasswordHint =>
      'From outside, Rasgeth asks for this password (the link with the token stays for this computer). Choose one you use nowhere else.';

  @override
  String get syRemotePasswordRule =>
      'At least 10 characters. A short sentence is easy to remember and hard to guess.';

  @override
  String get syRemotePasswordSaved => 'Password saved.';

  @override
  String get syRemotePasswordSet => 'A password is set';

  @override
  String get syRemotePurpose =>
      'Use Rasgeth from your phone or another computer when you are away. First a password, then one of three ways; nothing is reachable from outside until you finish. Optional.';

  @override
  String get syRemoteSessions => 'Signed-in browsers';

  @override
  String get syRemoteSessionsHint =>
      'Each sign-in lasts 30 days. If you lost a phone, or think someone else got in (the Rasgeth apps are signed out too):';

  @override
  String get syRemoteSignOutAll => 'Sign out everywhere';

  @override
  String get syRemoteSignedOut => 'Signed out everywhere.';

  @override
  String get syRemoteTailscale =>
      'A private network between your own devices: nothing opened on the router, free for personal use. You install Tailscale on your phone too.';

  @override
  String get syRemoteWaysFolded => 'Rasgeth\'s own ways out';

  @override
  String get syRemove => 'Remove';

  @override
  String get sySave => 'Save';

  @override
  String get sySaved => 'Saved';

  @override
  String get sySbBackupQ => 'All of Rasgeth in one file';

  @override
  String get sySettings => 'Settings';

  @override
  String get sySnCable => 'I use the cable';

  @override
  String sySnCableDone(String address) {
    return 'The cable works: Rasgeth is at $address. Join your home network with this device and open http://$address:7600 (or http://rasgeth.local:7600).';
  }

  @override
  String sySnFailed(String name, String why) {
    return 'Rasgeth could not join «$name»: $why';
  }

  @override
  String get sySnHidden => 'A hidden network';

  @override
  String get sySnHiddenName => 'Network name';

  @override
  String get sySnJoin => 'Use this network';

  @override
  String sySnMaintQ(String ssid) {
    return 'Rasgeth could not find your home network, so it opened $ssid again: choose the network it should use.';
  }

  @override
  String get sySnNone =>
      'No network was seen around: use the cable, or type the name of a hidden network.';

  @override
  String sySnPassword(String name) {
    return 'Password of «$name»';
  }

  @override
  String sySnQ(String ssid) {
    return 'You are on $ssid, Rasgeth\'s temporary network: which network should Rasgeth use at home?';
  }

  @override
  String get sySnTitle => 'Your home network';

  @override
  String sySnTrying(String name, String ssid) {
    return 'Rasgeth is joining «$name»: this temporary network closes now. Join your home network with this device and open http://rasgeth.local:7600. If it does not work, $ssid comes back in a minute with the reason.';
  }

  @override
  String get syStRemoteQ => 'Rasgeth away from home';

  @override
  String get syStopped => 'stopped';

  @override
  String get syTgQr => 'Scan with your phone\'s camera';

  @override
  String get syTsApps => 'Tailscale apps';

  @override
  String get syTsDns => 'Tailscale DNS settings';

  @override
  String get syTsOpenSignIn => 'Open Tailscale\'s sign-in page';

  @override
  String get syTsSignIn => 'Tailscale wants you to sign in, to add Rasgeth to your network:';

  @override
  String get syTsSignUp => 'Sign up on Tailscale';

  @override
  String get syTsStep1 =>
      'Make a free Tailscale account (with Google, Microsoft or GitHub is fine):';

  @override
  String get syTsStep2 =>
      'In Tailscale\'s DNS page switch on MagicDNS and HTTPS Certificates (they give Rasgeth a safe address):';

  @override
  String get syTsStep3 => 'Then here:';

  @override
  String get syTsStep4 =>
      'Install Tailscale on your phone and the other computers, signed in with the same account:';

  @override
  String get syUiAdvanced => 'Advanced';

  @override
  String get syUiDone => 'Done.';

  @override
  String get syUiNotNeeded => 'not needed';

  @override
  String syUpdBrkChecked(String conversations, String file, String projects, String size) {
    return '$file · $size · $projects projects, $conversations conversations, memories and settings';
  }

  @override
  String get syUpdBrkDockerCopy =>
      'The folder is inside Rasgeth\'s data volume, which a clean install removes: copy the file out first, from Rasgeth\'s folder:';

  @override
  String get syUpdBrkDone => 'Got it';

  @override
  String syUpdBrkKeys(String n) {
    return 'Your keychain ($n keys, the models\', chats\' and mailboxes\' ones too) is not in the backup: it goes in only protected by a passphrase of yours.';
  }

  @override
  String get syUpdBrkKeysAdd => 'Add the keychain too';

  @override
  String get syUpdBrkKeysAgain => 'Make the backup again with the keychain';

  @override
  String get syUpdBrkKeysIn => 'The keychain is in the backup too, protected by your passphrase.';

  @override
  String syUpdBrkLead(String version) {
    return 'Rasgeth $version changed too much inside to update the usual way: installed over the old one it could break.';
  }

  @override
  String get syUpdBrkNext => 'Go on';

  @override
  String get syUpdBrkRetry => 'Try the backup again';

  @override
  String get syUpdBrkSaved => 'Backup made and read back: it is in this folder';

  @override
  String get syUpdBrkStep1 => 'Remove the old Rasgeth';

  @override
  String get syUpdBrkStep1Docker => 'In Rasgeth\'s folder remove the containers and their volumes:';

  @override
  String get syUpdBrkStep1Mac =>
      'From the menu bar icon choose «Uninstall…» (or drag Rasgeth from Applications to the Bin).';

  @override
  String get syUpdBrkStep1Os =>
      'Copy the backup to a USB disk (Settings › System › Backups): reinstalling Rasgeth OS erases this machine\'s disk.';

  @override
  String get syUpdBrkStep1Source => 'Stop Rasgeth and move its data folder away.';

  @override
  String get syUpdBrkStep1Win =>
      'Uninstall Rasgeth. When it asks whether to keep the data, you can answer No: everything is in the backup.';

  @override
  String syUpdBrkStep2(String version) {
    return 'Install Rasgeth $version';
  }

  @override
  String get syUpdBrkStep3 => 'Restore';

  @override
  String get syUpdBrkStep3Docker =>
      'Open Rasgeth, finish the setup and import the copied file in Settings › Backup › Import a backup.';

  @override
  String get syUpdBrkStep3Os =>
      'Write the new Rasgeth OS (USB stick or image) and start the machine: the first start offers «Restore from the backup» and finds it on the USB disk.';

  @override
  String get syUpdBrkStep3Text =>
      'At its first start the new Rasgeth offers «Restore from the backup»: it finds it in that folder by itself.';

  @override
  String syUpdBrkSub(String installed, String version) {
    return 'Rasgeth $version cannot be installed over the $installed';
  }

  @override
  String syUpdBrkSure(String folder) {
    return 'Rasgeth closes and its uninstaller starts. The backup stays in $folder.';
  }

  @override
  String get syUpdBrkTitle => 'This version needs a clean install';

  @override
  String get syUpdBrkUninstall => 'Uninstall Rasgeth';

  @override
  String get syUpdBrkUninstallYes => 'Yes, uninstall';

  @override
  String get syUpdBrkUninstalling => 'The uninstaller is starting on your desktop.';

  @override
  String get syUpdBrkWhy =>
      'So it goes in three short steps: first a backup of everything (I am making it now, by myself), then you remove the old Rasgeth and install the new one, which puts everything back from the backup.';

  @override
  String get syUpdCopied => 'Copied';

  @override
  String get syUpdCopy => 'Copy';

  @override
  String get syUpdDownloadNew => 'Download the new version';

  @override
  String get syUpdFoundDone =>
      'Everything is back. Go on with the next steps to set up the models.';

  @override
  String get syUpdFoundKeys =>
      'The passphrase you chose for the keychain. Without it everything else is restored, and the keys of models and chats are put in again from their pages.';

  @override
  String syUpdFoundLead(String conversations, String date, String projects, String version) {
    return 'There is a backup of $date (Rasgeth $version): $projects projects and $conversations conversations. Put everything back now?';
  }

  @override
  String get syUpdFoundRestore => 'Restore from the backup';

  @override
  String get syUpdFoundTitle => 'Restore from the backup';

  @override
  String get syUpdLater => 'Later';

  @override
  String get syUpdLook => 'Look for updates';

  @override
  String get syUpdLooking => 'Looking…';

  @override
  String get syUpdReqAgain => 'Look again';

  @override
  String get syUpdReqClose => 'Close Rasgeth';

  @override
  String get syUpdReqClosing => 'Rasgeth is closing. You can close this page.';

  @override
  String get syUpdReqDocker => 'On the computer where Rasgeth runs, in its folder, run:';

  @override
  String get syUpdReqInstaller => 'If the update does not start, the whole installer is here:';

  @override
  String get syUpdReqInstallerLink => 'Rasgeth-Setup.exe';

  @override
  String syUpdReqLead(String installed, String version) {
    return 'This update cannot wait: Rasgeth $version fixes something that the $installed cannot keep doing safely.';
  }

  @override
  String get syUpdReqMac =>
      'Open the downloaded file and drag Rasgeth into Applications, replacing the old one; then open it again.';

  @override
  String get syUpdReqNow => 'Update now';

  @override
  String get syUpdReqSafe =>
      'Until you update, agents and automations wait. Your conversations, projects and settings are safe: nothing is lost.';

  @override
  String get syUpdReqSource =>
      'Bring the code up to date (git pull), build it and start Rasgeth again.';

  @override
  String syUpdReqSub(String installed, String version) {
    return 'Version $version is needed (you have $installed)';
  }

  @override
  String get syUpdReqTitle => 'Rasgeth must be updated';

  @override
  String get syUpdReqUpdating =>
      'Rasgeth is downloading the update: follow the window on your desktop. It restarts by itself.';

  @override
  String get syUpdReqUpdatingOs =>
      'Rasgeth OS is updating Rasgeth: the page stops for a few minutes and comes back by itself.';

  @override
  String get syWzBack => 'Back';

  @override
  String get syWzCpu => 'Processor';

  @override
  String get syWzFree => 'free';

  @override
  String get syWzGpu => 'Graphics card';

  @override
  String get syWzMemory => 'Memory';

  @override
  String get syWzNoGpu => 'None';

  @override
  String get syWzRecommended => 'recommended';

  @override
  String get syWzRemote => 'Access from outside home';

  @override
  String get syWzStorage => 'Data and backups';

  @override
  String syWzThreads(String n) {
    return '$n threads';
  }

  @override
  String get syHubTitle => 'System and access';

  @override
  String get syHubRemote =>
      'Password, second check, Tailscale, Cloudflare, your own domain, Pi-hole';

  @override
  String get syHubSystem => 'The machine, its role, data and backups, Wi-Fi, HTTPS, SSH, updates';

  @override
  String get syHubMachines => 'Your computers the agents reach over SSH';

  @override
  String get syHubNodes => 'Other machines working with this one';

  @override
  String get syHubBackup => 'Everything in one file, and a file brought back';

  @override
  String get syGateOpen => 'What to do';

  @override
  String get hfServiceTitle => 'Hands-free voice is on';

  @override
  String get hfServiceBody => 'The microphone stays open for the conversation by voice.';

  @override
  String get hfServiceChannel => 'Hands-free voice';

  @override
  String get hfServiceChannelText => 'Shown while the microphone is open for hands-free voice.';

  @override
  String get hfPaused => 'Paused: the app is not in front';

  @override
  String get hfWakeNotHere =>
      'On Mac, iPhone and iPad the wake word is not heard yet: tap the indicator, then «Talk now».';

  @override
  String get hfWakeHelp =>
      'Your wake word is kept for this device and checked with the speech model of Rasgeth.';

  @override
  String get hfLimitPrivacy =>
      'What you say after «Talk now» is sent to Rasgeth to be transcribed; nothing is heard before.';

  @override
  String get hfLimitAndroid =>
      'On Android the microphone stays open with the screen off or another app in front, with a notification that says so.';

  @override
  String get hfLimitOthers =>
      'On iPhone, iPad and the computers it listens while the app is open; in the background it pauses and the indicator says so.';

  @override
  String get hfReaderRow => 'Who reads and how loud';

  @override
  String get hfSttRow => 'Who writes down what you say';

  @override
  String get hfSttNone => 'No transcription service yet';

  @override
  String get hfPickConversation => 'Choose the conversation';

  @override
  String get hfNoRecent => 'No conversation yet';

  @override
  String get hfHandsFreeRow => 'Hands-free voice';

  @override
  String hfHandsFreeOn(String state) {
    return 'On: $state';
  }

  @override
  String get hfHandsFreeOff => 'Off on this device';

  @override
  String get fsrTitle => 'Search the conversations';

  @override
  String get fsrGo => 'Search';

  @override
  String get fsrHint =>
      'The words in every conversation: the agents\', the Chat\'s and the inspectors\'. At least two letters.';

  @override
  String get fsrNone => 'No results.';

  @override
  String get fsrUntitled => 'New conversation';

  @override
  String get fsrInspector => 'Inspector';

  @override
  String get g7WzRoleFull => 'A complete Rasgeth';

  @override
  String get g7WzRoleFullText => 'Its agents, projects and chats live here.';

  @override
  String get g7WzRoleNode => 'A node of another Rasgeth';

  @override
  String get g7WzRoleNodeText =>
      'It lends this machine to another Rasgeth: commands, local models, room for projects and backups.';

  @override
  String get g7WzNoWay => 'No way of thinking yet';

  @override
  String g7WzWays(String ways) {
    return 'Connected: $ways';
  }

  @override
  String get g7WzWayKeys => 'API keys';

  @override
  String get g7WzWayLocal => 'a model on this computer';

  @override
  String get g7WzWayServer => 'your own server';

  @override
  String get g7WzOpenModels => 'Models and subscriptions';

  @override
  String get g7WzNoLocal => 'No model on this computer yet';

  @override
  String g7WzLocal(String model) {
    return 'In use: $model';
  }

  @override
  String get g7WzOpenLocal => 'Models on this computer';

  @override
  String get g7WzAssignLead =>
      'Who decides gets the strongest model, who answers a quick one: God, Demi-God, the assistants and the others, each with its own.';

  @override
  String get g7WzOpenAssign => 'Choose who uses which model';

  @override
  String get g7WzTelegramLead =>
      'Write to Demi-God from your phone, also by voice: a bot of your own, made in a minute with BotFather.';

  @override
  String get g7WzOpenTelegram => 'Set up Telegram';

  @override
  String get g7WzOpenBackups => 'Backups and their destinations';

  @override
  String get g7WzOpenCode => 'GitHub and Gitea';

  @override
  String get g7WzOpenRemote => 'Access from outside home';

  @override
  String g7WzPresetText(String n) {
    return '$n kinds of action only you approve';
  }

  @override
  String get g7WzSafetyMore => 'Everything about safety and costs';

  @override
  String get g7WzCustom => 'Your own choice';

  @override
  String get g7WzPassword => 'Password';

  @override
  String get g7WzPasswordAgain => 'The password again';

  @override
  String g7WzDiskFree(String gb) {
    return 'Free on disk: $gb GB';
  }

  @override
  String get g7WzRedo => 'Redo the setup';

  @override
  String get g7WzRedoText =>
      'The page\'s guided setup, one step at a time: every step is saved at once.';

  @override
  String get g7WzContinue => 'Continue the setup';

  @override
  String get g7WzContinueText =>
      'Models, who uses which, imports, Telegram, backups, access from outside and safety: one step at a time, each one can be skipped.';

  @override
  String get g7AcpRemove => 'Remove';

  @override
  String get g7ImpOpen => 'Import from other agents';

  @override
  String get g7ImpRow => 'From Claude Code, Codex, Cursor and the chat exports';

  @override
  String get g7AcpRow => 'Claude Code, Codex, Gemini CLI as agents of a project';

  @override
  String get g7PlRow => 'Every change to the settings and to the code, undoable';

  @override
  String get g7NewsRow => 'What\'s new in this version';

  @override
  String get g7HubTitle => 'Setup, imports and history';

  @override
  String get g7SetupCode => 'The setup code shown by the machine';

  @override
  String get g7SetupCodeYes => 'No password yet? Use the setup code';

  @override
  String get g7SetupCodeNo => 'Sign in with the password';

  @override
  String get trayOpen => 'Open';

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayStay => 'Stay in the system tray when you close the window';

  @override
  String get trayStayHelp =>
      'Requests, questions and task reports keep arriving as notifications; the icon\'s menu opens the app again or quits it.';

  @override
  String get trayNone => 'This desktop has no system tray: closing the window quits the app.';

  @override
  String get pushDesktopInTray =>
      'With the window closed the app stays in the system tray and notifications still arrive. After «Quit» this computer gets nothing: Rasgeth\'s page and the linked chats still do.';

  @override
  String get hfWakeNeedsModel =>
      'The wake word needs its speech model on this device (Settings, Voice); until then tap the indicator, then «Talk now».';

  @override
  String hfWakeModelAbout(String mb) {
    return 'The wake word is heard on this device with a small speech model (Vosk, Apache-2.0): $mb MB to download once, kept here. Nothing you say leaves the device before the wake word.';
  }

  @override
  String get hfWakeModelAboutSoon =>
      'The wake word is heard on this device with a small speech model (Vosk, Apache-2.0), downloaded once and kept here.';

  @override
  String get hfWakeStageServer => 'Rasgeth is downloading the speech model (only the first time)';

  @override
  String get hfWakeStageEngine =>
      'Downloading the recogniser for this computer (only the first time)';

  @override
  String get hfWakeStageModel => 'Bringing the speech model to this device (only the first time)';

  @override
  String get hfWakeLoading => 'Starting the wake word…';

  @override
  String get hfWakeRetry => 'Try again';

  @override
  String get hfWakeOnFirst => 'Switch hands-free voice on first.';

  @override
  String get hfWakeErrFailed => 'the download stopped; check the connection and try again';

  @override
  String get hfWakeErrServer => 'Rasgeth could not download the speech model';

  @override
  String get hfWakeErrChecksum =>
      'the recogniser that arrived is not the expected one, so it was not kept';

  @override
  String get hfWakeErrBroken => 'the speech model did not start on this device; download it again';

  @override
  String get moSysPersistarLine =>
      'The context of every conversation with a local model is saved on disk: coming back to it, even after a restart, does not read it all again.';

  @override
  String get smpMorning => 'Good morning';

  @override
  String get smpAfternoon => 'Good afternoon';

  @override
  String get smpEvening => 'Good evening';

  @override
  String smpMorningName(String name) {
    return 'Good morning, $name';
  }

  @override
  String smpAfternoonName(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String smpEveningName(String name) {
    return 'Good evening, $name';
  }

  @override
  String get smpHeroLead => 'What do you need today?';

  @override
  String get smpAskHint => 'Ask me anything…';

  @override
  String get smpReplyHint => 'Reply…';

  @override
  String get smpSend => 'Send';

  @override
  String get smpSettings => 'Settings';

  @override
  String get smpInProgress => 'IN PROGRESS';

  @override
  String get smpNoTopics =>
      'Nothing in progress. Write above what you need: I\'ll take care of it.';

  @override
  String get smpLoading => 'Loading…';

  @override
  String smpArchive(String n) {
    return 'Archive ($n)';
  }

  @override
  String get smpJustStarted => 'Just started';

  @override
  String smpFrom(String name) {
    return 'from $name';
  }

  @override
  String get smpUnread => 'Something new';

  @override
  String get smpWaiting => 'waiting for you';

  @override
  String get smpWorking => 'working';

  @override
  String get smpReady => 'ready';

  @override
  String get smpOtherOne => 'One thing waits for your answer';

  @override
  String smpOtherMany(String n) {
    return '$n things wait for your answer';
  }

  @override
  String get smpBack => 'Back';

  @override
  String get smpMore => 'More';

  @override
  String get smpRename => 'Rename';

  @override
  String get smpPin => 'Keep at the top';

  @override
  String get smpUnpin => 'Don\'t keep at the top';

  @override
  String get smpArchiveThis => 'Put in the archive';

  @override
  String get smpEmptyTopic => 'Nothing written here yet.';

  @override
  String get smpWorkingNow => 'I\'m working on it…';

  @override
  String get smpMove => 'Move';

  @override
  String get smpMovedHere => 'Brought here from another topic';

  @override
  String get smpRoutedIn => 'in:';

  @override
  String get smpRoutedUnsure => 'I wasn\'t sure: I put it here';

  @override
  String smpMovedTo(String title) {
    return 'Moved to «$title»';
  }

  @override
  String get smpMovedElsewhere => 'Moved to another topic';

  @override
  String get smpDecide => 'A decision for you';

  @override
  String get smpAskAllow => 'Can I go ahead?';

  @override
  String get smpAskCritical => 'Careful: this can\'t be undone. Can I go ahead?';

  @override
  String smpFor(String title) {
    return 'for: $title';
  }

  @override
  String get smpYes => 'Yes, go ahead';

  @override
  String get smpNo => 'No';

  @override
  String get smpMoveTitle => 'Move to another topic';

  @override
  String get smpMoveLead => 'Your message and my answer go there, and I answer there again.';

  @override
  String get smpNewTopic => 'New topic';

  @override
  String get smpNewTopicName => 'What should it be called? (you can leave it empty)';

  @override
  String get smpSearchHint => 'Search in your topics';

  @override
  String get smpInArchive => 'IN THE ARCHIVE';

  @override
  String get smpArchiveTitle => 'Archive';

  @override
  String get smpArchiveLead =>
      'Topics left untouched for a few days rest here. Tap one to take it back.';

  @override
  String get smpNothingFound => 'Nothing found with these words.';

  @override
  String get smpArchiveEmpty => 'The archive is empty.';

  @override
  String get smpRequestsTitle => 'Waiting for you';

  @override
  String get smpNothingWaits => 'Nothing waits for you.';

  @override
  String get smpNotify => 'Notifications on this device';

  @override
  String get smpNotifyBlocked => 'Blocked by the browser: allow them in its settings.';

  @override
  String get smpVoice => 'Voice';

  @override
  String get smpVoiceHelp => 'Talk to me and hear the answers, on this device.';

  @override
  String get smpSpend => 'Ask me before spending';

  @override
  String get smpSpendHelp => 'Before paying or buying anything I always ask you.';

  @override
  String get smpAlways => 'Always';

  @override
  String get smpYourName => 'Your name';

  @override
  String get smpYourNameLabel => 'What should I call you?';

  @override
  String get smpNoName => 'Add';

  @override
  String get smpLink => 'Link';

  @override
  String get smpLinked => 'Linked';

  @override
  String get smpTheme => 'Look';

  @override
  String get smpColour => 'Colour';

  @override
  String get smpLanguage => 'Language';

  @override
  String get smpFullView => 'Full view';

  @override
  String get smpFullViewHelp => 'Every setting, for who wants to see how it works inside.';

  @override
  String get smpSignOut => 'Sign out';

  @override
  String get uiTitle => 'Interface';

  @override
  String get uiHelp =>
      'The simple one shows only your topics and a few settings; the full one shows everything. Each device remembers its own.';

  @override
  String get uiSimple => 'Simple';

  @override
  String get uiFull => 'Full';

  @override
  String get wzLook => 'Interface';

  @override
  String get wzLookQ => 'How would you like to see Rasgeth?';

  @override
  String get wzLookLead => 'You can change it whenever you like, on each device.';

  @override
  String get wzLookSimple => 'Simple';

  @override
  String get wzLookSimpleText =>
      'A big box to ask for what you need, your topics in progress and a few settings. For everyday things.';

  @override
  String get wzLookFull => 'Full';

  @override
  String get wzLookFullText =>
      'Agents, projects, tools, models and every setting. For who wants to see how it works inside.';

  @override
  String get wzLookName => 'What should we call you?';

  @override
  String get wzLookNameHint => 'Your name (optional)';

  @override
  String get smpOther => 'Something else…';

  @override
  String get smpOtherHint => 'Write your answer';

  @override
  String get prSection => 'Rules';

  @override
  String get prQ => 'What should Rasgeth watch for you?';

  @override
  String get prLead =>
      'Write a rule once and Rasgeth keeps it by itself: when something happens, if it is as you say, it tells you, asks you, blocks or stops the agents. A rule never gives anyone more than you have.';

  @override
  String get prMagic => 'Magic rule';

  @override
  String get prNew => 'New rule';

  @override
  String get prListTitle => 'Your rules';

  @override
  String get prListLead =>
      'A rule acts only when it is on. Each one is tried on its two examples before it switches on.';

  @override
  String get prNone => 'No rules yet. Describe one to God with «Magic rule», or write it yourself.';

  @override
  String get prFiresTitle => 'What the rules did';

  @override
  String get prFiresLead => 'The last times a rule acted, newest first.';

  @override
  String get prTplMargin => 'Weekly margin of the subscription';

  @override
  String get prTplMarginQ => 'Warn me at +5, stop the agents at +2?';

  @override
  String get prTplMarginLead =>
      'The margin is how much of the week has passed minus how much of it is used. Two rules, added switched off: you switch them on.';

  @override
  String get prTplAdd => 'Add the two rules';

  @override
  String prHoldTitle(String name) {
    return 'Stopped by the rule «$name»';
  }

  @override
  String prHoldSince(String when) {
    return 'since $when';
  }

  @override
  String get prResumeNow => 'Resume';

  @override
  String get prByYou => 'you';

  @override
  String get prByGod => 'made with God';

  @override
  String get prByTemplate => 'ready-made';

  @override
  String prLastFired(String when) {
    return 'last acted $when';
  }

  @override
  String get prEdit => 'Change';

  @override
  String get prHistory => 'History';

  @override
  String prHistoryOf(String name) {
    return 'History of «$name»';
  }

  @override
  String prHistoryBy(String by, String version) {
    return '$by, version $version';
  }

  @override
  String get prUndo => 'Undo the last change';

  @override
  String get prRemove => 'Remove';

  @override
  String prRemoveQ(String name) {
    return 'Remove the rule «$name»?';
  }

  @override
  String get prRemoveLead => 'It stops acting at once. Its history stays: «Undo» brings it back.';

  @override
  String get prChCreated => 'Made';

  @override
  String get prChChanged => 'Changed';

  @override
  String get prChEnabled => 'Switched on';

  @override
  String get prChDisabled => 'Switched off';

  @override
  String get prChRemoved => 'Removed';

  @override
  String get prChUndone => 'Undone';

  @override
  String get prName => 'Name';

  @override
  String get prNamePh => 'No push on Sundays';

  @override
  String get prWords => 'In your words (optional)';

  @override
  String get prWhen => 'When';

  @override
  String get prWhenQ => 'what happens?';

  @override
  String get prIf => 'If';

  @override
  String get prIfQ => 'what must be true? (all of it)';

  @override
  String get prIfNone => 'No conditions: it acts every time.';

  @override
  String get prThen => 'Then';

  @override
  String get prThenQ => 'what does Rasgeth do?';

  @override
  String get prValue => 'Value';

  @override
  String get prAddCond => 'Add a condition';

  @override
  String get prRemoveCond => 'Remove the condition';

  @override
  String get prAddAct => 'Add an action';

  @override
  String get prRemoveAct => 'Remove the action';

  @override
  String get prNotifyPh => 'What to tell you (empty: what happened)';

  @override
  String get prReasonPh => 'Why (the agent reads it)';

  @override
  String get prScopeAll => 'All';

  @override
  String get prScopeProject => 'That project\'s';

  @override
  String get prScopeAgent => 'That agent';

  @override
  String get prResumePerson => 'I resume them';

  @override
  String get prResumeAuto => 'It is fine again';

  @override
  String get prToolsOff => 'Tools to switch off';

  @override
  String get prAutomation => 'Automation';

  @override
  String get prCommand => 'Command';

  @override
  String get prProjectPh => 'Project (empty: the rules\' own folder)';

  @override
  String get prCommandSafe =>
      'It runs in the sandbox, checked as an agent\'s command: what is truly dangerous asks you, and no key is in its environment.';

  @override
  String get prCron => 'Schedule';

  @override
  String get prCronHelp =>
      'Minute, hour, day, month, weekday: 0 9 * * 1-5 is 9:00 on working days.';

  @override
  String get prExamples => 'Try';

  @override
  String get prExamplesQ => 'one case where it must act, one where it must not';

  @override
  String get prExFire => 'It must act';

  @override
  String get prExPass => 'It must not act';

  @override
  String get prExOk => 'As expected';

  @override
  String get prExBad => 'Not as expected';

  @override
  String get prTrialOk => 'Both examples go as they should: the rule can switch on.';

  @override
  String get prTry => 'Try';

  @override
  String get prSaveOff => 'Save switched off';

  @override
  String get prSaveOn => 'Save and switch on';

  @override
  String get prAnd => ' and ';

  @override
  String prSayWhen(String event) {
    return 'When $event';
  }

  @override
  String prSayWhenTime(String cron) {
    return 'At the times $cron';
  }

  @override
  String prSayIf(String conds) {
    return 'if $conds';
  }

  @override
  String prSayThen(String acts) {
    return 'then $acts';
  }

  @override
  String get prSayNotify => 'tell you';

  @override
  String prSayNotifyText(String text) {
    return 'tell you «$text»';
  }

  @override
  String get prSayAsk => 'ask you first';

  @override
  String get prSayBlock => 'block it';

  @override
  String get prSayStop => 'stop the agents after they save, until you resume them';

  @override
  String get prSayStopAuto => 'stop the agents after they save, until it is fine again';

  @override
  String prSayToolsOff(String what) {
    return 'switch off $what';
  }

  @override
  String prSayAutomation(String name) {
    return 'start the automation «$name»';
  }

  @override
  String prSayCommand(String command) {
    return 'run «$command» in the sandbox';
  }

  @override
  String get prEvUsage => 'the subscription\'s use is read';

  @override
  String get prEvBudget => 'a budget is used';

  @override
  String get prEvTool => 'a tool or command is about to run';

  @override
  String get prEvFile => 'a file is about to be written';

  @override
  String get prEvAgentDone => 'an agent finishes';

  @override
  String get prEvSchedule => 'at a time';

  @override
  String get prFieldMargin => 'the margin (points)';

  @override
  String get prFieldUsed => 'the use (%)';

  @override
  String get prFieldWindow => 'the window';

  @override
  String get prFieldProvider => 'the subscription';

  @override
  String get prFieldBudgetPct => 'the budget used (%)';

  @override
  String get prFieldBudget => 'the budget';

  @override
  String get prFieldTool => 'the tool';

  @override
  String get prFieldCommand => 'the command';

  @override
  String get prFieldPath => 'the path';

  @override
  String get prFieldProject => 'the project';

  @override
  String get prFieldAgent => 'the agent';

  @override
  String get prFieldStop => 'how it ended';

  @override
  String get prOpLt => 'is less than';

  @override
  String get prOpLte => 'is at most';

  @override
  String get prOpGt => 'is more than';

  @override
  String get prOpGte => 'is at least';

  @override
  String get prOpEq => 'is';

  @override
  String get prOpNeq => 'is not';

  @override
  String get prOpMatches => 'looks like';

  @override
  String get prOpContains => 'contains';

  @override
  String get prActNotify => 'Tell me';

  @override
  String get prActAsk => 'Ask me first';

  @override
  String get prActBlock => 'Block it';

  @override
  String get prActStop => 'Stop the agents';

  @override
  String get prActToolsOff => 'Switch tools off';

  @override
  String get prActAutomation => 'Start an automation';

  @override
  String get prActCommand => 'Run a command';

  @override
  String get prMagicAsk => 'What should the rule do?';

  @override
  String get prMagicPh =>
      'For example: if the weekly margin drops under 5 tell me, under 2 stop everyone';

  @override
  String get prMagicStep1 => 'You say it';

  @override
  String get prMagicStep2 => 'God builds and tries it';

  @override
  String get prMagicStep3 => 'You decide';

  @override
  String get prMagicProposal => 'God\'s rule';

  @override
  String get prMagicMissing => 'Still missing:';

  @override
  String get prMagicNotTested => 'Its examples do not pass yet; it will be made switched off:';

  @override
  String get prMagicRefuse => 'Refuse';

  @override
  String get prMagicChange => 'Change';

  @override
  String get prMagicApprove => 'Approve';

  @override
  String get prMagicDone => 'Done: the rule is among your rules.';

  @override
  String get prMagicBuilding => 'God is building the rule with you in the conversation.';

  @override
  String get prMagicGo => 'Start with God';

  @override
  String get prMagicSendNo => 'Send the no';

  @override
  String get prMagicWhy => 'What is wrong (God reads it)';

  @override
  String get prHub => 'When, if, then: what Rasgeth watches for you';

  @override
  String get prEvWebhook => 'its address is called (webhook)';

  @override
  String get prFieldBody => 'what it sends';

  @override
  String get prHook => 'Address';

  @override
  String get prHookQ => 'Make a new secret for this rule\'s address?';

  @override
  String get prHookQLead => 'The secret is shown only once. An old secret stops working.';

  @override
  String get prHookMake => 'Make the secret';

  @override
  String prHookTitle(String name) {
    return 'Address of «$name»';
  }

  @override
  String get prHookLead =>
      'Give the service this address and the secret (in the header x-redgiant-secret, or at the end of the address). What it sends is only data the rule looks at: never instructions.';

  @override
  String get prHookAddress => 'Address';

  @override
  String get prHookSecret => 'Secret';

  @override
  String get prHookSecretHelp => 'Shown only now: copy it.';

  @override
  String get syEmAccel => 'Acceleration';

  @override
  String syEmAccelOk(String kind) {
    return '$kind works';
  }

  @override
  String get syEmAccel_container => 'none in a container';

  @override
  String get syEmAccel_disabled =>
      'virtualization is switched off (BIOS) or the hypervisor is missing';

  @override
  String get syEmAccel_kvm_denied =>
      'KVM is there but this user may not use it (add it to the kvm group)';

  @override
  String get syEmAccel_no_kvm =>
      'No KVM: turn on virtualization in the BIOS and load the KVM module';

  @override
  String get syEmAccel_unknown => 'unknown until the emulator is installed';

  @override
  String get syEmAdb => 'adb (platform-tools)';

  @override
  String get syEmAdbIdle =>
      'adb is not running, so running emulators and phones are not known: Rasgeth does not start it just to look.';

  @override
  String syEmApi(String api) {
    return 'API $api';
  }

  @override
  String get syEmAttached => 'Running now';

  @override
  String get syEmAvds => 'Virtual devices';

  @override
  String get syEmContainer =>
      'Rasgeth runs in a container here, so emulators cannot run on this machine: they come from a node with Android Studio or the SDK (a Windows, Mac or Linux computer paired in Settings › Nodes).';

  @override
  String get syEmEmulator => 'Emulator';

  @override
  String get syEmFolder => 'Folder of the Android SDK';

  @override
  String get syEmFolderForget => 'Forget it';

  @override
  String get syEmFolderHelp => 'The folder with platform-tools, emulator or system-images inside.';

  @override
  String get syEmFolderLabel => 'Full path of the SDK folder';

  @override
  String get syEmFolderLead =>
      'Only if the SDK is somewhere Rasgeth does not look by itself. It looks at ANDROID_HOME, ANDROID_SDK_ROOT, Android Studio\'s settings, Android Studio\'s usual place and adb on the PATH.';

  @override
  String get syEmFolderSave => 'Use this folder';

  @override
  String get syEmHere => 'This machine';

  @override
  String get syEmImageMissing => 'image missing';

  @override
  String get syEmImages => 'System images';

  @override
  String get syEmLead =>
      'Android emulators, Android phones on USB or Wi-Fi, and iOS simulators: what this machine and your nodes have, and what is missing. Here Rasgeth only looks: nothing is installed or started.';

  @override
  String get syEmLookAgain => 'Look again';

  @override
  String get syEmLooked => 'Where Rasgeth looked';

  @override
  String get syEmLooking => 'Looking…';

  @override
  String get syEmMax => 'Emulators at once';

  @override
  String get syEmMaxLead =>
      'How many emulators may run together on this machine: each one takes 2 to 4 GB of memory.';

  @override
  String get syEmMiss_accel => 'Hardware acceleration: without it emulators are too slow.';

  @override
  String get syEmMiss_avd => 'A virtual device that can start here.';

  @override
  String get syEmMiss_cmdline_tools =>
      'cmdline-tools (sdkmanager, avdmanager), to download images and create virtual devices.';

  @override
  String get syEmMiss_emulator => 'The Android Emulator package of the SDK.';

  @override
  String get syEmMiss_emulator_old =>
      'The emulator is old: Rasgeth can propose the update, which you approve.';

  @override
  String get syEmMiss_ios_bridge => 'A bridge for touches on iOS simulators (comes with 3.12.2).';

  @override
  String get syEmMiss_platform_tools => 'platform-tools (adb), to talk to emulators and phones.';

  @override
  String get syEmMiss_sdk =>
      'An Android SDK (Android Studio installs it; or choose its folder below).';

  @override
  String get syEmMiss_system_image => 'A system image for this processor.';

  @override
  String get syEmMiss_xcode => 'Xcode, for iOS simulators (from the App Store).';

  @override
  String get syEmMissing => 'What is missing';

  @override
  String get syEmNoNodes =>
      'No nodes paired. Pair a computer with Android Studio in Settings › Nodes to use its emulators from here.';

  @override
  String get syEmNoSdk =>
      'No Android SDK found. Choose its folder below if you have one, or install Android Studio (or the SDK alone); a guided install will come, and always asks you first.';

  @override
  String get syEmNodeOffline => 'offline';

  @override
  String get syEmNodeOld => 'This node has not said what it has: it is offline or older than 3.11.';

  @override
  String get syEmNodes => 'Your nodes';

  @override
  String get syEmNodesLead => 'What the machines paired with this one have, as each one last said.';

  @override
  String get syEmNone => 'none';

  @override
  String get syEmNoneAttached => 'No emulator running and no phone attached.';

  @override
  String get syEmNotReady => 'Not ready yet: see what is missing below.';

  @override
  String get syEmOffline => 'not responding';

  @override
  String get syEmPhoneUsb => 'Phone over USB';

  @override
  String get syEmPhoneWifi => 'Phone over Wi-Fi';

  @override
  String get syEmPlayStore => 'Play Store';

  @override
  String get syEmQ => 'Emulators and phones';

  @override
  String syEmReady(String count) {
    return 'Ready: emulators can run here ($count virtual devices).';
  }

  @override
  String get syEmRunningEmu => 'Emulator';

  @override
  String get syEmSdk => 'Android SDK';

  @override
  String get syEmSection => 'Emulators';

  @override
  String get syEmSimulators => 'iOS simulators';

  @override
  String get syEmSrc_ANDROID_HOME => 'from ANDROID_HOME';

  @override
  String get syEmSrc_ANDROID_SDK_ROOT => 'from ANDROID_SDK_ROOT';

  @override
  String get syEmSrc_custom => 'the folder you chose';

  @override
  String get syEmSrc_path => 'around adb or the emulator on the PATH';

  @override
  String get syEmSrc_standard => 'Android Studio\'s usual place';

  @override
  String get syEmSrc_studio => 'from Android Studio\'s settings';

  @override
  String get syEmSystem => 'System';

  @override
  String get syEmUnauthorized => 'waiting for your yes on the phone';

  @override
  String get syEmXcode => 'Xcode';

  @override
  String get syOffline => 'offline';

  @override
  String get syHubEmulators =>
      'Android emulators, phones and iOS simulators, here and on the nodes';

  @override
  String get syAgents => 'Agents';

  @override
  String get syDsBack => 'Back';

  @override
  String syDsError(String error) {
    return 'It cannot be shown: $error';
  }

  @override
  String get syDsHome => 'Home';

  @override
  String get syDsRecents => 'Recent apps';

  @override
  String get syDsRotate => 'Turn';

  @override
  String syDsScreen(String name) {
    return 'The screen of $name';
  }

  @override
  String get syDsShared =>
      'The agents\' device: you see what they do. Take control to use it yourself.';

  @override
  String get syDsStarting => 'Starting the emulator without a window: it takes about a minute.';

  @override
  String get syDsYours =>
      'Yours now: tap, hold, swipe and type on it. Nothing you do here reaches a model or the log. Give it back when you are done.';

  @override
  String get syEmDevices => 'Devices';

  @override
  String get syEmDevicesLead =>
      'Open one to see it live on the right: an emulator that is off starts without a window.';

  @override
  String get syEmNoDevices => 'No device here yet.';

  @override
  String get syEmOpen => 'Open';

  @override
  String get syEmStartedHere => 'started by Rasgeth';

  @override
  String get syEmStop => 'Switch off';

  @override
  String get syScreenGiveBack => 'Give it back to the agents';

  @override
  String get syScreenStarting => 'Starting the browser…';

  @override
  String get syScreenTake => 'Take control';

  @override
  String get syDsState_off => 'off';

  @override
  String get syDsState_offline => 'not responding';

  @override
  String get syDsState_on => 'on';

  @override
  String get syDsState_starting => 'starting…';

  @override
  String get syDsState_unauthorized => 'waiting for your yes on the phone';

  @override
  String get syEiAvdName => 'Name of the virtual phone';

  @override
  String get syEiAvdNameHelp => 'Letters, digits, dot, dash and underscore.';

  @override
  String get syEiBlock_container =>
      'Rasgeth runs in a container here, and emulators cannot run inside it. Pair a node (a computer with Rasgeth) and its emulators appear here.';

  @override
  String get syEiBlock_emulators_running =>
      'An emulator is running: switch it off first, then update.';

  @override
  String get syEiBlock_folder_not_empty =>
      'That folder already holds other things and is not an Android SDK: choose a new or empty folder.';

  @override
  String get syEiBlock_folder_relative => 'The folder must be a full path.';

  @override
  String syEiBlock_java_old(String major) {
    return 'The Java found is version $major: Android\'s tools need 17 or newer. Install a Java 17 or set JAVA_HOME to one, then look again.';
  }

  @override
  String get syEiBlock_no_accel =>
      'This computer has no hardware acceleration for virtual machines: an emulator would be far too slow to use. Nothing is installed; a node on a computer that has it is better.';

  @override
  String get syEiBlock_no_java =>
      'Android\'s tools need Java 17 or newer, and none was found (JAVA_HOME, the PATH, Android Studio). Install a Java 17 (for example Eclipse Temurin or OpenLogic) or Android Studio, then look again. Rasgeth does not install Java by itself.';

  @override
  String get syEiBlock_nothing => 'Nothing is missing here.';

  @override
  String get syEiBlock_offline =>
      'Google\'s list of packages (with the licences) could not be read. Check the internet connection and try again.';

  @override
  String get syEiBlock_unsupported =>
      'Google makes no Android emulator for this system and processor. A node on another computer can bring one.';

  @override
  String get syEiCancelled => 'Stopped. You can start again whenever you like.';

  @override
  String get syEiClose => 'Close';

  @override
  String get syEiDone => 'Done. The report of this machine has been read again.';

  @override
  String get syEiFailed =>
      'The install did not finish. What is already in the folder stays; you can try again.';

  @override
  String get syEiFolder => 'Folder';

  @override
  String get syEiFolderApply => 'Plan again';

  @override
  String get syEiFolderHelp =>
      'A full path; a new or empty folder, or an Android SDK already there.';

  @override
  String get syEiFolderOther => 'Another folder or name';

  @override
  String get syEiFolderStandard => 'the standard place on this system';

  @override
  String get syEiInstall => 'Install what is missing';

  @override
  String syEiJava(String major) {
    return 'With Java $major:';
  }

  @override
  String get syEiLead =>
      'Rasgeth downloads them from Google only now, with your yes, and puts everything in this folder (the virtual phone goes where the emulator keeps them). Nothing else on the computer changes.';

  @override
  String get syEiLicenceAccept => 'I read and accept these licences';

  @override
  String get syEiLicenceHelp =>
      'Rasgeth says yes on your behalf only to these, only for this install.';

  @override
  String get syEiLicences => 'Licences';

  @override
  String get syEiLicencesLead =>
      'Google\'s terms for these pieces, in full. Read them: the install starts only once you accept them.';

  @override
  String get syEiNote_bios =>
      'Virtualization is switched off: switch it on in the BIOS/UEFI (VT-x or AMD-V) and, on Windows, the Windows Hypervisor Platform feature.';

  @override
  String get syEiNote_ios_bridge =>
      'iOS: the bridge for touches comes with Rasgeth 3.12.2; there is nothing to install now.';

  @override
  String get syEiNote_kvm_group =>
      'Linux: /dev/kvm is there but this user may not use it. An administrator can add the user to the kvm group, then log in again.';

  @override
  String get syEiNote_node => 'Settings › Nodes: pair a computer that can run emulators.';

  @override
  String get syEiNote_xcode =>
      'iOS simulators need Xcode, from the App Store: Rasgeth does not install it. iOS comes with Rasgeth 3.12.2.';

  @override
  String get syEiReading => 'Reading Google\'s list of packages…';

  @override
  String get syEiRunning => 'Starting…';

  @override
  String get syEiStart => 'Install';

  @override
  String get syEiStartUpdate => 'Update';

  @override
  String syEiStep_avd(String name) {
    return 'The virtual phone $name';
  }

  @override
  String syEiStep_cmdline_tools(String version) {
    return 'Android\'s command-line tools $version (sdkmanager, avdmanager)';
  }

  @override
  String get syEiStep_emulator => 'The Android emulator';

  @override
  String syEiStep_emulator_update(String version) {
    return 'The emulator, at its latest version $version';
  }

  @override
  String get syEiStep_licences => 'The licences you read and accepted';

  @override
  String get syEiStep_platform_tools => 'Platform tools (adb)';

  @override
  String get syEiStep_system_image => 'Android 15 (API 35) for this processor';

  @override
  String get syEiSteps => 'What it will do';

  @override
  String get syEiStopNow => 'Stop';

  @override
  String get syEiTitle => 'Install the Android pieces';

  @override
  String get syEiTitleUpdate => 'Update the emulator';

  @override
  String syEiTotal(String size) {
    return 'To download: $size';
  }

  @override
  String get syEiUpdate => 'Update the emulator';

  @override
  String get syUiDetails => 'Details for whoever helps you';

  @override
  String get smpOldServer =>
      'This simple interface needs Rasgeth 3.12 or newer on the server, and this one is older. Ask whoever looks after it to update the server to 3.12; meanwhile the full interface works.';

  @override
  String get smpTopicsFailed =>
      'Your topics did not arrive. Try again in a moment, or use the full interface.';

  @override
  String get smpTryAgain => 'Try again';

  @override
  String smpMascotOf(String name, String state) {
    return '$name: $state';
  }

  @override
  String get smpMoodRest => 'here for you';

  @override
  String get smpMoodListen => 'listening';

  @override
  String get smpMoodThink => 'thinking';

  @override
  String get smpMoodWork => 'at work';

  @override
  String get smpMoodWait => 'waiting for you';

  @override
  String get smpMoodHappy => 'happy, something is done';

  @override
  String get smpMoodWorried => 'worried, something went wrong';

  @override
  String get smpSatellite => 'Satellite';

  @override
  String get smpSatelliteChat => 'Satellite · Chat';

  @override
  String get smpChatLead => 'Fancy a chat? I\'m here.';

  @override
  String get smpChatHint => 'Write to Satellite...';

  @override
  String get smpRecentChats => 'LATEST CHATS';

  @override
  String get smpNoChats => 'No chats yet: write here and we start one.';

  @override
  String get smpUntitledChat => 'A new chat';

  @override
  String smpTodayAt(String time) {
    return 'Today, $time';
  }

  @override
  String get smpYesterday => 'Yesterday';

  @override
  String get smpYourAgents => 'YOUR AGENTS';

  @override
  String get smpOpenChat => 'Open the chat';

  @override
  String smpAgentIs(String name, String state) {
    return '$name, $state';
  }

  @override
  String get nudgeTitle => 'A word from God now and then';

  @override
  String get nudgeHelp =>
      'At most once a day, never at night: about something waiting for you, or a good morning. It asks nothing.';

  @override
  String get nudgeEvery => 'How often';

  @override
  String get nudgeDay => 'Once a day';

  @override
  String get nudgeTwoDays => 'Every other day';

  @override
  String get nudgeWeek => 'Once a week';

  @override
  String get smpDoingThink => 'is thinking…';

  @override
  String get smpDoingSearch => 'is searching…';

  @override
  String get smpDoingWork => 'is working…';

  @override
  String get smpDoingWait => 'is waiting for you';

  @override
  String smpSpentHere(String usd) {
    return 'Spent here: $usd';
  }

  @override
  String get smpRouting => 'Putting it in the right topic…';

  @override
  String get cvFoundGalleryTitle => 'Pictures from the web';

  @override
  String get cvFoundAll => 'All';

  @override
  String cvFoundAllTitle(String n) {
    return 'All the pictures ($n)';
  }

  @override
  String get cvFoundImageBroken => 'Picture not available';

  @override
  String get cvFoundOpenPage => 'Open the page';

  @override
  String get cvFoundOpenPicture => 'Open the picture big';

  @override
  String get cvFoundClose => 'Close';

  @override
  String get cvFoundPrevious => 'Previous picture';

  @override
  String get cvFoundNext => 'Next picture';

  @override
  String get cvFoundDirect => 'direct';

  @override
  String get cvFoundStop1 => '1 stop';

  @override
  String cvFoundStopN(String n) {
    return '$n stops';
  }

  @override
  String get cvFoundChoose => 'Choose';

  @override
  String cvFoundChooseText(
    String kind,
    String label,
    String departs,
    String arrives,
    String from,
    String to,
    String date,
    String price,
  ) {
    return 'I choose the $kind $label, $departs to $arrives, $from to $to$date$price. Ask me to confirm before you book or pay anything.';
  }

  @override
  String get cvFoundKindTrain => 'train';

  @override
  String get cvFoundKindFlight => 'flight';

  @override
  String cvFoundMapAlt(String from, String to) {
    return 'Map of the route from $from to $to';
  }

  @override
  String get cvFoundModeWalk => 'On foot';

  @override
  String get cvFoundModeTransit => 'Transit';

  @override
  String get cvFoundModeDrive => 'Car';

  @override
  String get cvFoundModeByWalk => 'on foot';

  @override
  String get cvFoundModeByTransit => 'by transit';

  @override
  String get cvFoundModeByDrive => 'by car';

  @override
  String cvFoundMinutes(String n) {
    return '$n min';
  }

  @override
  String cvFoundHours(String h, String m) {
    return '$h h $m min';
  }

  @override
  String get cvFoundOpenMaps => 'Open in Maps';

  @override
  String cvFoundRating(String n) {
    return 'Rated $n out of 5';
  }
}
