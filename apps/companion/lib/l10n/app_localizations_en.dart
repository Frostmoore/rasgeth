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

  @override
  String get allSettings => 'All settings';

  @override
  String get allSettingsHint =>
      'RedGiant\'s whole Settings page, inside the app, signed in with this device.';

  @override
  String get allSettingsBrowser => 'Opens RedGiant\'s page in the browser: sign in there as usual.';

  @override
  String get allSettingsNoHttps =>
      'The full settings need HTTPS: from here the page would travel in clear. Switch on HTTPS in the home network from the computer.';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get connectExisting => 'Connect a RedGiant that runs already';

  @override
  String get firstStepsTitle => 'No RedGiant yet';

  @override
  String get firstStepsLead =>
      'Set up a new one from here (RedGiant OS opens its own Wi-Fi network at the first start), or connect one you already use.';

  @override
  String get setupNew => 'Set up a new RedGiant';

  @override
  String get setupNewHint =>
      'A RedGiant OS machine turned on for the first time: the app joins its temporary network and does the whole first start.';

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
      'What is done stays done; you can come back here, or finish from the browser, while the temporary network is open (30 minutes from when RedGiant was turned on).';

  @override
  String get fsIntroTitle => 'Set up a new RedGiant';

  @override
  String get fsIntroLead =>
      'Turn your RedGiant on: for 30 minutes it opens the Wi-Fi network RedGiant-Setup-XXXX. The app joins it, you create the access and choose your home network, then RedGiant moves there and the app finds it again.';

  @override
  String get fsIntroSafe =>
      'Everything you type travels encrypted, with RedGiant\'s own key checked by the app: nobody on the temporary network reads it.';

  @override
  String get fsSeen => 'Temporary networks around';

  @override
  String get fsNoScan =>
      'The system does not show the networks around: type the four characters after RedGiant-Setup- (you see them in the computer\'s Wi-Fi list).';

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
  String get fsJoiningSheet => 'Choose RedGiant-Setup in the window the system shows.';

  @override
  String get fsConnecting => 'Looking for RedGiant on the network…';

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
  String get fsWhereAndroid => 'Settings › Network › Wi-Fi: tap RedGiant-Setup-…';

  @override
  String get fsWhereIos => 'Settings › Wi-Fi: tap RedGiant-Setup-…';

  @override
  String get fsWhereMac => 'The Wi-Fi menu at the top right of the screen: choose RedGiant-Setup-…';

  @override
  String get fsWhereWindows => 'The Wi-Fi icon at the bottom right: choose RedGiant-Setup-…';

  @override
  String get fsWhereOther => 'The system\'s Wi-Fi list: choose RedGiant-Setup-…';

  @override
  String get fsManualNoInternet =>
      'The system may say the network has no internet: that is right, stay on it.';

  @override
  String get fsJoinedContinue => 'Done, go on';

  @override
  String get fsErrNotFound =>
      'RedGiant does not answer: are you on the RedGiant-Setup network? It stays open for 30 minutes after RedGiant is turned on.';

  @override
  String get fsErrNotHere =>
      'This RedGiant does not let a new access be created from here: finish from its page.';

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
      'The password that opens RedGiant from every device. Keep it: it is also what opens its keychain.';

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
      'It travels encrypted to RedGiant and stays only there; this device gets its own access, which you can sign out from Settings › Devices.';

  @override
  String get fsAccessGo => 'Create the access';

  @override
  String get fsSignInTitle => 'Sign in';

  @override
  String get fsSignInLead => 'This RedGiant has its password already: type it to go on.';

  @override
  String get fsMaintenanceTitle => 'RedGiant lost its network';

  @override
  String get fsMaintenanceLead =>
      'It opened the temporary network to be given a new one. Its owner\'s password, and nothing else changes.';

  @override
  String get fsHomeTitle => 'Your home network';

  @override
  String get fsHomeLead =>
      'Which network should RedGiant use at home? These are the ones it saw around it.';

  @override
  String get fsHomeNone =>
      'No network was seen around: use the cable, or type the name of a hidden network.';

  @override
  String get fsHomeUnusable => 'RedGiant cannot join this kind of network';

  @override
  String get fsHomeHidden => 'A hidden network';

  @override
  String get fsHomeHiddenName => 'Network name';

  @override
  String fsHomePassword(String name) {
    return 'Password of «$name»';
  }

  @override
  String get fsHomeSafe => 'The Wi-Fi password stays only in RedGiant.';

  @override
  String fsHomeJoin(String name) {
    return 'Use «$name»';
  }

  @override
  String get fsHomeCable => 'I use the cable';

  @override
  String fsHomeWaitWifi(String name) {
    return 'RedGiant is joining «$name»…';
  }

  @override
  String get fsHomeWaitCable => 'RedGiant moves to the home network…';

  @override
  String get fsHomeWaitSub =>
      'The device goes back to its own network and finds RedGiant there (up to two minutes). If it does not work, RedGiant opens the temporary network again and says why.';

  @override
  String get fsLostTitle => 'RedGiant is not found';

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
  String get fsBrainTitle => 'How should RedGiant think?';

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
      'I read the provider\'s terms: a subscription is used by me, on my own RedGiant.';

  @override
  String get fsBrainLater =>
      'Models on this machine, your own server and the rest are in Settings, from the computer or from «All settings».';

  @override
  String get fsNamesTitle => 'The names';

  @override
  String get fsNamesLead =>
      'Who runs your RedGiant, and who speaks for it in the chats. You can change them later.';

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
  String get fsDoneTitle => 'RedGiant is ready';

  @override
  String get fsDoneLead =>
      'The temporary network is closed: RedGiant is on your home network, and this device is connected to it.';

  @override
  String get fsDoneMaintenance =>
      'RedGiant is on its new network again, and this device is connected to it.';

  @override
  String get fsDoneMore =>
      'The rest of the first start (backups, chats, access from outside…) is in the page, whenever you want: «Settings of RedGiant» › «All settings».';

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
  String get homeErrBusy => 'RedGiant is already joining a network: wait a moment.';

  @override
  String get homeErrWifiOff => 'Wi-Fi is not running on RedGiant.';

  @override
  String get homeErrNoCable =>
      'No cable with an address: connect it to the router, or choose a Wi-Fi network.';

  @override
  String get homeErrFailed => 'That did not work. Try again in a moment.';

  @override
  String get outsideNone =>
      'Only from the home network. Tailscale, Cloudflare or your own name: in «All settings».';

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
  String get updNowTitle => 'Update RedGiant?';

  @override
  String updNowBody(String version) {
    return 'RedGiant downloads $version, then restarts: for a minute or two it does not answer. You see every step, and the app reconnects by itself as soon as RedGiant is back.';
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
  String get updStepWait => 'Waiting for RedGiant to answer';

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
    return 'Stopped: $name';
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
      'RedGiant picks the face from the name; once it is made you can change it.';

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
  String get notificationsSub => 'How this device hears from RedGiant when the app is closed';

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
      'Off on this device: RedGiant cannot tell you anything while the app is closed.';

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
      'The distributor gave an address, but RedGiant could not be reached: the app tries again at the next start.';

  @override
  String get pushFailedNetwork => 'The distributor has no network now: try again in a moment.';

  @override
  String get pushFailedVapid =>
      'The distributor wants RedGiant\'s VAPID key, which is in the keychain: open the keychain on RedGiant and try again.';

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
      'The distributor brings RedGiant\'s notifications to this phone, encrypted: you choose it (ntfy, your own ntfy, Sunup…), no Google or RedGiant cloud in between.';

  @override
  String get pushNoDistributor => 'There is no UnifiedPush distributor on this phone.';

  @override
  String get pushNoDistributorMeans =>
      'Without one, RedGiant cannot reach you while the app is closed: you see requests and answers only by opening the app (or in a linked chat, like Telegram).';

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
      'With the app closed this computer gets nothing: RedGiant\'s page and the linked chats still do.';

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
  String get shareTitle => 'Share to RedGiant';

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
  String get voiceNoReader => 'RedGiant has no voice to read with yet.';

  @override
  String get voiceNoReaderHow =>
      'Add a key for OpenAI, ElevenLabs or Google Gemini in RedGiant\'s Settings, Voice: then choose it here.';

  @override
  String get voiceTalkHead => 'Press and talk';

  @override
  String get voiceTalkWhat =>
      'In a conversation, hold the microphone down while you speak: let go and what you said is written in the field, to read before sending.';

  @override
  String get voiceTalkWhere =>
      'It is written down by RedGiant\'s transcription (Settings, Voice, Transcription), the same as the page\'s.';

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
      'The microphone is not allowed: allow it in the system\'s settings for RGCompanion.';

  @override
  String get voiceMicFailed => 'The microphone did not start: is another app using it?';

  @override
  String get voiceErrNoService =>
      'RedGiant has no transcription service: choose one in Settings, Voice, Transcription.';

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
      'The recording could not be converted for whisper on RedGiant\'s computer.';

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
  String get voiceErrServer => 'RedGiant cannot be reached: check the connection.';

  @override
  String get voiceErrOther => 'The voice did not work: try again.';

  @override
  String get notifyTestFailed =>
      'The system did not show it: are notifications on for RGCompanion in its settings?';

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
  String get codeUnreachable => 'RedGiant cannot be reached: check the connection.';

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
  String get metricsRestoredFromDisk => 'KV cache restored from the SSD before this request';

  @override
  String get metricsCostUnknown => 'cost not known';

  @override
  String get metricsCostUnknownHint =>
      'This model is not in the models catalog yet: its prices are not known, so its cost is not counted.';

  @override
  String get metricsShowAll => 'Show all the message\'s figures';

  @override
  String updNowBodyLocal(String version) {
    return 'On this computer RedGiant does the update to $version in its own window: it downloads, closes and starts again as the new version. Here you see the steps it reports.';
  }

  @override
  String get updFollow => 'Follow the update';

  @override
  String upd2Title(String from, String to) {
    return 'Updating RedGiant from $from to $to';
  }

  @override
  String upd2TitleTo(String to) {
    return 'Updating RedGiant to $to';
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
  String get upd2Restarting => 'RedGiant is restarting, reconnecting…';

  @override
  String upd2Attempt(String n, String time) {
    return 'Attempt $n · no answer for $time';
  }

  @override
  String get upd2Back => 'RedGiant answers: checking it is the new version…';

  @override
  String get upd2Keeps =>
      'RedGiant keeps working while it downloads: it stops only for the restart, a minute or two.';

  @override
  String get upd2ComesBack =>
      'Keep the app open: it reconnects by itself as soon as RedGiant answers as the new version.';

  @override
  String get upd2Local =>
      'On this computer RedGiant does the update in its own window, with the bar and the time: here you see the steps it reports, and if this window stays open it reconnects by itself when RedGiant is back.';

  @override
  String get upd2Older =>
      'This RedGiant does not report each step\'s details yet (they come with 3.8.1): you see where it is and for how long.';

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
  String get upd2BackHome => 'Back to RedGiant';

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
  String get upd2Step_restart => 'Restart RedGiant as the new version';

  @override
  String get upd2Step_wait => 'Check that RedGiant answers';

  @override
  String get upd2Step_rollback => 'Put the previous version back';

  @override
  String get upd2Step_scan => 'Compare the installed files';

  @override
  String get upd2Step_build => 'Put the new version together';

  @override
  String get upd2Step_installer => 'Download the installer';

  @override
  String get upd2StepText_check => 'Only a version signed by RedGiant is installed.';

  @override
  String get upd2StepText_download => 'RedGiant keeps working while it downloads.';

  @override
  String get upd2StepText_files => 'The programs of the system around RedGiant.';

  @override
  String get upd2StepText_install =>
      'A copy of every file replaced is kept: if something goes wrong, it goes back as it was.';

  @override
  String get upd2StepText_restart =>
      'For a minute or two RedGiant does not answer: the app reconnects by itself.';

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
    return 'Nothing changed: RedGiant $from keeps working. Check that the machine reaches the internet, then press «Try again»: what came down already is not downloaded twice.';
  }

  @override
  String get upd2Why_files => 'The system\'s new files could not be installed.';

  @override
  String upd2WhyText_files(String from) {
    return 'Every file went back as it was and RedGiant $from keeps working. Try again in a while; if it happens again, download the diagnostics from the page (Settings › General › Diagnostics) and send them.';
  }

  @override
  String get upd2Why_not_up => 'The new version did not start.';

  @override
  String upd2WhyText_not_up(String from) {
    return 'RedGiant went back to $from by itself: nothing is lost. Try again in a while; if it happens again, download the diagnostics from the page (Settings › General › Diagnostics) and send them.';
  }

  @override
  String get upd2Why_no_images => 'This version has nothing for this machine\'s processor.';

  @override
  String upd2WhyText_no_images(String from) {
    return 'Nothing changed: RedGiant $from keeps working. Wait for the next version.';
  }

  @override
  String get upd2Why_breaking => 'This version cannot be installed over the current one.';

  @override
  String upd2WhyText_breaking(String from) {
    return 'Nothing changed: RedGiant $from keeps working. Open RedGiant\'s page from the computer: it guides you through the clean install.';
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
  String get upd2Why_gone => 'RedGiant does not answer any more.';

  @override
  String get upd2WhyText_gone =>
      'It did not come back after the restart. Check that the machine is on and in the network, then press «Try again»: the app looks for it again.';

  @override
  String get upd2Why_start => 'The update did not start.';

  @override
  String upd2WhyText_start(String from) {
    return 'Nothing changed: RedGiant $from keeps working. Try again in a while.';
  }

  @override
  String upd2WhySaid(String error) {
    return 'RedGiant said: $error';
  }

  @override
  String get upd2ScreenTitle => 'RedGiant\'s update';

  @override
  String get deskAbout => 'About RGCompanion';

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
}
