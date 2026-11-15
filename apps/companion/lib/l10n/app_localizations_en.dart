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
  String get pushOff => 'Not on for this device yet.';

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
    return 'RedGiant installs $version and restarts: for a few minutes it does not answer, then the app connects again by itself.';
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
}
