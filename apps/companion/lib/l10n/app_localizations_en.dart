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
  String get chatEmpty =>
      'Your conversations with Chat, day by day, show here.';

  @override
  String get inboxEmpty =>
      'Nothing to decide: when an agent asks you something, it shows here.';

  @override
  String get activityEmpty =>
      'Tasks in progress and done, grouped by agent, show here.';

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
  String get reduceMotionHint =>
      'The mascots stay still; their state shows by its sign.';

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
  String get errNoPassword =>
      'This RedGiant has no password yet: complete its first start.';

  @override
  String get errServerTooOld =>
      'This RedGiant is too old for the app: update it.';

  @override
  String get errServerTooNew =>
      'This app is too old for this RedGiant: update the app.';

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
  String get errCertificate =>
      'The certificate is not this RedGiant\'s: the app did not go on.';

  @override
  String get errBusy =>
      'Another device is setting this RedGiant up: one at a time.';

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
  String get allSettingsBrowser =>
      'Opens RedGiant\'s page in the browser: sign in there as usual.';

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
  String get fsJoiningSheet =>
      'Choose RedGiant-Setup in the window the system shows.';

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
  String get fsWhereAndroid =>
      'Settings › Network › Wi-Fi: tap RedGiant-Setup-…';

  @override
  String get fsWhereIos => 'Settings › Wi-Fi: tap RedGiant-Setup-…';

  @override
  String get fsWhereMac =>
      'The Wi-Fi menu at the top right of the screen: choose RedGiant-Setup-…';

  @override
  String get fsWhereWindows =>
      'The Wi-Fi icon at the bottom right: choose RedGiant-Setup-…';

  @override
  String get fsWhereOther =>
      'The system\'s Wi-Fi list: choose RedGiant-Setup-…';

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
  String get fsErrCancelled =>
      'The network was not joined. Try again, or join by hand.';

  @override
  String get fsErrDenied =>
      'The app needs the permission for nearby devices to join the network: allow it, or join by hand.';

  @override
  String get fsErrJoinFailed =>
      'The system could not join the network: join by hand.';

  @override
  String get fsErrNoName =>
      'Choose the network, or type its four last characters.';

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
  String get fsSignInLead =>
      'This RedGiant has its password already: type it to go on.';

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
  String get fsClaudeText =>
      'Anthropic\'s page in the browser, then the code it shows';

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
  String get fsChatgptCode =>
      'Type this code on the page; the app notices when it is done.';

  @override
  String get fsChatgptOpenAgain => 'Open the page again';

  @override
  String get fsKey => 'A key of a provider';

  @override
  String get fsKeyText =>
      'Anthropic, OpenAI, Gemini, OpenRouter…: paid per use';

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
  String get homeErrBusy =>
      'RedGiant is already joining a network: wait a moment.';

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
  String get pushOff =>
      'Not on yet for this device: turn them on in You, Notifications.';

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
  String get teamNoFavourites =>
      'No favourites yet: press and hold an agent to add it.';

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
  String get inboxCriticalHint =>
      'Truly dangerous: no swiping, it opens full screen.';

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
  String get modelHintSubscription =>
      'Within your plan\'s limits: nothing is paid per use.';

  @override
  String get modelHintKey =>
      'Paid per use with your API key: it counts toward the spending cap.';

  @override
  String modelHintNode(String node) {
    return 'Goes through the computer $node.';
  }

  @override
  String get modelHintLocal =>
      'Runs on a computer of yours: nothing is paid per use.';

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
  String get agentBlockedNow =>
      'It is blocked: open the conversation to see why.';

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
  String get sessionModelBusy =>
      'It is working: the model changes once it has finished.';

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
  String get newAgentRoleHint =>
      'For example: writes the tests and checks they pass';

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
  String get newAgentNeedsGod =>
      'God is needed to make agents: finish the first start first.';

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
  String get promptResetConfirm =>
      'Go back to the built-in instructions? Your text will be lost.';

  @override
  String get promptUndo => 'Undo the changes';

  @override
  String get refineOpen => 'Improve the instructions';

  @override
  String get refineLead =>
      'A model reads them again and proposes a clearer version. You see what changes before using it; nothing is saved until you save.';

  @override
  String get refineWish =>
      'What do you want to change? (you can leave it empty)';

  @override
  String get refineWishPlaceholder =>
      'For example: more concise; always answer with lists; specialise it in invoices. Empty: a general improvement.';

  @override
  String refineEstimate(String what) {
    return 'Estimate: $what.';
  }

  @override
  String get refineNoEstimate =>
      'No estimate: check that the model is still connected.';

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
  String get refineErr_budget =>
      'The budget is used up: raise it in Settings, Budget.';

  @override
  String get refineErr_no_model =>
      'No model is connected: connect one in Settings, Models.';

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
  String get notificationsSub =>
      'How this device hears from RedGiant when the app is closed';

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
  String get notifyAnswerFailedBody =>
      'Open the app to answer: the request is still waiting.';

  @override
  String notifyAsksPermission(String name) {
    return '$name asks for permission';
  }

  @override
  String notifyAsksYou(String name) {
    return '$name asks you';
  }

  @override
  String get notifyCriticalTitle =>
      'A truly dangerous request: open it to decide';

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
  String get pushFailedNetwork =>
      'The distributor has no network now: try again in a moment.';

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
  String get pushNoDistributor =>
      'There is no UnifiedPush distributor on this phone.';

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
  String get voiceAccountVoice =>
      'The voice is the one of the account with the key.';

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
  String get voiceTooShort =>
      'Too short: hold the microphone down while you speak.';

  @override
  String get voiceHeardNothing =>
      'I did not hear any words: try again closer to the phone.';

  @override
  String get voiceMicDenied =>
      'The microphone is not allowed: allow it in the system\'s settings for RGCompanion.';

  @override
  String get voiceMicFailed =>
      'The microphone did not start: is another app using it?';

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
  String get voiceErrProvider =>
      'This provider cannot do it: choose another one.';

  @override
  String get voiceErrServer =>
      'RedGiant cannot be reached: check the connection.';

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
  String get advancedTerminalsHint =>
      'Read only; my own terminal has the row of extra keys.';

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
  String get codeArchived =>
      'Archived project: read only until you restore it.';

  @override
  String get codeArchivedShort => 'archived';

  @override
  String get codeChangedMeanwhile =>
      'The file changed since you opened it: open it again.';

  @override
  String get codeUnreachable =>
      'RedGiant cannot be reached: check the connection.';

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
  String get codeTermReadOnly =>
      'Read only: the commands the agent ran and what they printed.';

  @override
  String get codeTermNoCommands => 'No commands yet.';

  @override
  String get codeReload => 'Load again';

  @override
  String get codeTermIntro =>
      'A shell in the project\'s sandbox, like the page\'s terminal.';

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
  String get savedDone =>
      'Saved: it is in your saved items, with the conversation it comes from.';

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
  String get savedFromDailyChat =>
      'It comes from the daily chat of the page: open it there.';

  @override
  String get savedNotThere =>
      'The message is not in the conversation any more.';

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
      'KV cache restored from the SSD before this request';

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
  String get upd2StepText_check =>
      'Only a version signed by RedGiant is installed.';

  @override
  String get upd2StepText_download =>
      'RedGiant keeps working while it downloads.';

  @override
  String get upd2StepText_files =>
      'The programs of the system around RedGiant.';

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
  String get upd2StepText_build =>
      'The new version is prepared beside the current one.';

  @override
  String get upd2StepText_installer =>
      'The whole program: it installs over the current one.';

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
  String get upd2Why_no_images =>
      'This version has nothing for this machine\'s processor.';

  @override
  String upd2WhyText_no_images(String from) {
    return 'Nothing changed: RedGiant $from keeps working. Wait for the next version.';
  }

  @override
  String get upd2Why_breaking =>
      'This version cannot be installed over the current one.';

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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files',
      one: '1 file',
    );
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
  String get deskNoKeysHere =>
      'No keys here: credentials stay on the egress routes';

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
  String get deskPushAsked =>
      'Asked in «For you»: the push goes once you say yes';

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
  String get deskStreamHint =>
      'Paused under the pointer · a click opens the Log';

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
  String get deskSendMessage =>
      'Send the message (in the conversations\' fields)';

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
  String get asMascotHelp =>
      'Renaming it never changes its face: only you change it, here.';

  @override
  String get asMascotGod =>
      'God\'s mascot is drawn by hand: it is always the red giant.';

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
  String get asModeHelp =>
      'Whatever sends, publishes, deletes or pays always waits for you.';

  @override
  String get asMode_auto => 'On its own';

  @override
  String get asMode_manual => 'Asks permission';

  @override
  String get asMode_plan => 'Plan first';

  @override
  String get asMode_readonly => 'Read only';

  @override
  String get asModeExplain_auto =>
      'Works on its own and asks only for what is dangerous.';

  @override
  String get asModeExplain_manual =>
      'Asks you before every change to files or commands.';

  @override
  String get asModeExplain_plan =>
      'Writes a plan first and starts once you approve it.';

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
  String get asMemProjectHelp =>
      'Every agent working on this project reads it.';

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
  String get cvCompactionManual =>
      'The conversation was summarised here, as you asked';

  @override
  String get cvCompactionEmergency =>
      'The conversation was summarised here: the window was full';

  @override
  String get cvCompactionEngine =>
      'The subscription\'s engine summarised its conversation here (by itself)';

  @override
  String get cvCompactionUndone =>
      'Summary undone: the whole conversation is back';

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
  String get cvSentWhileWorking =>
      'Sent while the agent works: it reads it as soon as it can';

  @override
  String cvWriteWhileWorking(String name) {
    return '$name is working: write anyway, it reads it right after…';
  }

  @override
  String cvWriteTo(String name) {
    return 'Write to $name…';
  }

  @override
  String get cvStopWhenBack =>
      'The connection is lost: «Stop» goes as soon as it is back.';

  @override
  String get cvSendQueued =>
      'Send: it is read as soon as the current work allows';

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
  String get cvViaVoiceHint =>
      'Said hands-free; the agent was asked for an answer to read aloud';

  @override
  String get cvViaArtifact => 'from a widget';

  @override
  String get cvViaArtifactHint =>
      'Sent by a button you clicked in an artifact or a widget';

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
  String get widgetKeepHint =>
      'Saved as an artifact in artefatti/, and opened in the Canvas';

  @override
  String get widgetKeptShort => 'Kept';

  @override
  String widgetKept(String path) {
    return 'Kept as $path';
  }

  @override
  String get widgetAsks => 'It wants to send to the chat:';

  @override
  String get widgetNoChat =>
      'It wants to send to the chat (open a conversation first):';

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
  String get requestDoneClosing =>
      'This screen closes by itself in a few seconds.';

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
      other:
          '$n automations will be paused ($names); they run again when you restore the project.',
      one:
          '1 automation will be paused ($names); it runs again when you restore the project.',
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
  String get pmFactRestore =>
      'God can archive and restore it too, always with your yes.';

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
  String get atWorkSaved =>
      'Saved: it holds for the turns that start from now.';

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
  String get queueEmpty =>
      'Nobody is waiting: every agent with work is working.';

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
  String get fxPathHint =>
      'Name, with its folder if you want one (docs/note.md)';

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
  String get cvBoardCommentHere =>
      'A comment on this variant (optional with «I choose this»)';

  @override
  String get cvBoardSendComment => 'Send comment';

  @override
  String get cvBoardWhole => 'A comment on the whole board';

  @override
  String get cvBoardWholeHint =>
      'For example: I like the colour of 2 with the layout of 3';

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
      'It lives as a file in the artefatti/ folder of a project (or of God and the assistants), so you also find it among the files on the right. To get one, ask an agent for a tool you want to keep and use again; or import a .rgartifact from another RedGiant.';

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
      'To import it into another RedGiant: the app, its manifest and the fingerprint that checks it arrived intact. It carries no permissions.';

  @override
  String get cvArExportHtml => 'Download as HTML';

  @override
  String get cvArExportHtmlText =>
      'To open it elsewhere. Careful: outside RedGiant it runs without the isolated frame, with the rights of the page you open it in.';

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
      'What the app kept on RedGiant (storage). Leave it off for a clean copy without your data.';

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
  String get sideTabCanvas => 'Canvas';

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
  String chatFileDownloadOf(
    String done,
    String total,
    String speed,
    String left,
  ) {
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
  String get cvSubEndedDone =>
      'It finished: its report went back to the agent that started it.';

  @override
  String get cvSubEndedFailed => 'It did not finish its task.';

  @override
  String get cvSubEndedStopped => 'It was stopped.';

  @override
  String get cvSubInterrupted =>
      'Interrupted: the server stopped while it worked.';

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
  String get cvSubNoWrite =>
      'It takes orders only from the agent that started it';

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
  String get cvCmdStatusInterrupted => 'interrupted (RedGiant had stopped)';

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
  String get cvRoomUsageHint =>
      'What its answers here cost, and how full its context is';

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
  String get cvGroupsEmpty =>
      'Several agents in one chat: «Add an agent» in any conversation.';

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
  String get cvChatToGroup =>
      'Go on as a group: add an agent, which gets this chat as context';

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
  String get cvScreenUnavailable =>
      'The agents\' browser needs RedGiant\'s Docker installation.';

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
  String get cvChatPlaceholder =>
      'Write a message (Enter to send, Shift+Enter for a new line)';

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
  String get spNoAgents =>
      'No agents yet: create them from the project\'s agents.';

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
      'A small private GitHub on this computer, installed and started by RedGiant, or the Gitea you already have.';

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
      'With a token you make on GitHub: RedGiant creates the repositories and the agents push to them. The token stays with RedGiant, never in the agents\' boxes.';

  @override
  String csGithubLinked(String login) {
    return 'Connected as @$login';
  }

  @override
  String get csGithubStep1 =>
      'Open GitHub\'s page for a new token (sign in if asked):';

  @override
  String get csGithubOpen => 'New token on GitHub';

  @override
  String get csGithubStep2 => 'Fill it in like this:';

  @override
  String get csPermName => 'Token name: RedGiant';

  @override
  String get csPermExpiry =>
      'Expiration: one year (RedGiant reminds you before it ends)';

  @override
  String get csPermRepos => 'Repository access: All repositories';

  @override
  String get csPermList =>
      'Permissions, Repositories: Administration, Contents, Issues and Pull requests set to Read and write';

  @override
  String get csGithubStep3 =>
      'Press Generate token at the bottom, copy it and paste it here';

  @override
  String get csGithubTokenHelp =>
      'It starts with github_pat_. GitHub shows it only once.';

  @override
  String get csGiteaHint =>
      'A Git server of your own, on this computer: the repositories stay here, and you look at them in the browser like on GitHub. RedGiant starts it and keeps it updated. Or connect a Gitea you already have.';

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
  String get csGiteaUserHelp =>
      'Letters, digits, dots, dashes; for example mario.';

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
    return 'RedGiant cannot find $host: the DNS it uses does not know that name. The guide «Your home services» in Settings › Access from outside home says what to add, and lets you try the name.';
  }

  @override
  String csGiteaHostUnreachable(String host) {
    return 'RedGiant finds $host, but its address does not answer from here (a Tailscale address, another network?). The guide «Your home services» in Settings › Access from outside home says how to fix it.';
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
      'You approve what cannot be undone (publishing, history, disks, passwords, changes to RedGiant); the agents in charge approve the rest.';

  @override
  String get g4SfFree => 'Free';

  @override
  String get g4SfFreeText =>
      'The agents in charge approve almost everything; you are asked only for passwords and changes to RedGiant itself.';

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
  String get g4SfGuardQ =>
      'An agent wants to write outside its project. What happens?';

  @override
  String get g4SfGuardAsk => 'It asks me';

  @override
  String get g4SfGuardAuto => 'I let it';

  @override
  String get g4SfApprTitle => 'The approvals';

  @override
  String get g4SfApprQ =>
      'Who says yes before a risky action, like deleting or publishing?';

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
  String get g4SfBudgetQ =>
      'How much can RedGiant spend at most with your API keys?';

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
  String get g4CmSaved =>
      'Saved: it counts from the next command and the next message.';

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
  String get g4RqModeQ =>
      'Do you want to answer the agents\' requests yourself?';

  @override
  String get g4RqModeAsk => 'Ask me';

  @override
  String get g4RqModeClassifier => 'Don\'t ask me anything';

  @override
  String get g4RqAlwaysYou =>
      'Even with «Don\'t ask me anything», the truly dangerous requests always reach you, everywhere: deletions for good, system files, secrets leaving, real payments and RedGiant\'s own protections.';

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
  String get g4RqTimeQSpecial =>
      'How long do the truly dangerous things wait for your answer?';

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
  String get g4SfSaved =>
      'Saved: it counts from the next action of the agents.';

  @override
  String get g4SfCustomOn => 'Only you approve it';

  @override
  String get g4CmAtWorkLead =>
      'Saved at once, for the turns that start from now.';

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
  String get g4GenAgentLangSub =>
      'The agents reply in it from the next conversation.';

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
      'Whether a newer RedGiant is out, and a log to send when something goes wrong.';

  @override
  String g4GenCloudPrivacy(String name) {
    return 'With $name, what you say after the wake word goes to $name through RedGiant\'s server; the wake word itself is still heard only in this page.';
  }

  @override
  String get g4GenDebugClear => 'Delete the logs';

  @override
  String get g4GenDebugClearConfirm => 'Delete every log kept?';

  @override
  String get g4GenDebugDownload => 'Download the logs';

  @override
  String get g4GenDebugForced =>
      'Turned on by the server\'s settings (REDGIANT_DEBUG=1).';

  @override
  String get g4GenDebugHelp =>
      'Debug mode keeps a detailed log of everything RedGiant does: each step of starting a model with its times, the local engine\'s own messages, the requests, what the Windows program does. Turn it on when something is slow or goes wrong, repeat it, then download the logs and send them. It writes a lot (at most 300 MB, the oldest go first) and never writes passwords or keys.';

  @override
  String g4GenDebugSize(String size, String files) {
    return 'Logs kept: $size in $files files.';
  }

  @override
  String get g4GenDebugSwitch => 'Debug mode';

  @override
  String get g4GenDebugText =>
      'Everything RedGiant does, written in a log you can download and send.';

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
  String get g4GenInstructionsSaved =>
      'Saved: conversations started from now on follow them.';

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
  String get g4GenKeyHelp =>
      'Kept in the keychain, encrypted; it never reaches this page again.';

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
      'RedGiant can run its own search engine (SearXNG): free, no keys, and every model can search the web with it, local ones too.';

  @override
  String get g4GenOwnSearchOn =>
      'RedGiant\'s search engine is on: every agent and the Chat search the web with it.';

  @override
  String get g4GenOwnSearchStart => 'Start RedGiant\'s search engine';

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
  String get g4GenQ => 'How do you want RedGiant?';

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
  String get g4GenSearchText =>
      'Lets every agent and the Chat look things up on the web.';

  @override
  String get g4GenSearchTitle => 'Web search';

  @override
  String g4GenSearchTried(String n, String first) {
    return 'It works: $n results, the first «$first».';
  }

  @override
  String get g4GenSearchTriedEmpty =>
      'It answered, but with no results for the test search.';

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
      'whisper.cpp, started by RedGiant: free, nothing leaves the house.';

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
      'RedGiant looks for a new version by itself at the first start of each day. Here you can look now.';

  @override
  String get g4GenVoiceHelp =>
      'Turns voice messages (from Telegram or the microphone) into text.';

  @override
  String get g4GenVoiceKey => 'Transcription service key';

  @override
  String get g4GenVoiceLocalHint =>
      'No account and nothing leaves this computer. RedGiant downloads whisper.cpp and a multilingual model once (about 560 MB, with its bar in the corner) and runs them itself.';

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
  String get g4GenBackupSaved =>
      'Saved: it applies to tasks given up on from now on.';

  @override
  String g4GenDebugSaved(String name) {
    return 'Saved: $name';
  }

  @override
  String g4GenNewsTitle(String version) {
    return 'What is new in RedGiant $version';
  }

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
  String get g4AgServicesHelp =>
      'The services it may use. Changes apply to its new conversations.';

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
  String get g4AgRoutinesHelp =>
      'Work it does by itself at a set time or when something happens.';

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
  String get g4AgModeText_manual =>
      'Asks before every change to files or commands.';

  @override
  String get g4AgModeText_plan =>
      'First proposes a plan; works only once it is approved.';

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
  String get g4AgRoleText_coder =>
      'Writes and changes the code, runs the tests.';

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
  String get g4AgRoleText_writer =>
      'Documentation, READMEs and texts, clear and up to date.';

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
  String get g4AgJobHint_researcher =>
      'Looks things up on the web and reports with sources.';

  @override
  String get g4AgJobText_researcher =>
      'Look things up on the web when I ask, compare the sources and report what you found with the links, saying what you could not confirm.';

  @override
  String get g4AgJob_social => 'Social media';

  @override
  String get g4AgJobHint_social =>
      'Prepares posts and keeps an eye on your pages.';

  @override
  String get g4AgJobText_social =>
      'Prepare posts for my pages in my style, propose them to me before publishing and tell me how the last ones went.';

  @override
  String get g4AgJob_accounts => 'Accounts';

  @override
  String get g4AgJobHint_accounts =>
      'Invoices, payments and expenses, in order.';

  @override
  String get g4AgJobText_accounts =>
      'Keep invoices, payments and expenses in order, tell me what is due and what is missing. Never pay or refund without my approval.';

  @override
  String get g4AgJob_tech => 'Tech helper';

  @override
  String get g4AgJobHint_tech =>
      'Answers technical questions and fixes small things.';

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
  String get g4BuLead =>
      'What projects and agents spend, and how far they may go.';

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
  String get g4BuRowHint =>
      'This month, every project and agent, with their limits';

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
  String get g4HubGeneral =>
      'Language, agents\' instructions, search, images, what\'s new';

  @override
  String get g4HubAgents => 'The tree of agents, new agents, assistants';

  @override
  String get g4HubTools => 'What every agent may use';

  @override
  String get g4HubCommands => 'Background commands, agents at work together';

  @override
  String get g4HubRequests => 'Where requests reach you, how long they wait';

  @override
  String get g4HubSafety =>
      'Guardian, who approves, spending, skills, retention';

  @override
  String get knAsstSavedNewChats =>
      'Saved: it applies to its new conversations.';

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
  String get knCompactKeepTitle =>
      'How much of the latest part to keep as it is';

  @override
  String knCompactKeepValue(String n) {
    return 'the last $n%';
  }

  @override
  String get knErr_memory_empty => 'Write something to remember.';

  @override
  String get knErr_memory_forgotten =>
      'A memory forgotten for good cannot come back.';

  @override
  String get knErr_memory_full =>
      'The memory is full: delete or merge some old memories first.';

  @override
  String get knErr_memory_gone => 'That memory is not there any more.';

  @override
  String get knErr_memory_long =>
      'A memory is at most 400 characters: write it shorter.';

  @override
  String get knErr_memory_moved =>
      'The memory changed again since: undo the newer change first.';

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
      'Downloading pgvector, the search by meaning in RedGiant\'s database (only once)';

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
  String get knKbAgentNewOnly =>
      'It changes from the agent\'s next conversation.';

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
  String get knKbCloudText =>
      'OpenAI, Voyage, Cohere, Gemini, Mistral, Jina or your own';

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
  String get knKbConsentChatsYes =>
      'Yes, the agents may read these conversations';

  @override
  String get knKbConsentMail =>
      'The agents that may read this collection will be able to find and quote your mail. RedGiant only reads the inbox: it never marks, moves or deletes a message.';

  @override
  String get knKbConsentMailYes => 'Yes, the agents may read this mail';

  @override
  String knKbDays(String n) {
    return '$n days';
  }

  @override
  String get knKbDiskLead =>
      'What the knowledge takes, and whether the backup carries it.';

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
  String get knKbErr_bad_source =>
      'That source cannot be read: check the path or the address.';

  @override
  String get knKbErr_embedding_failed =>
      'The model did not answer: check the key and try again.';

  @override
  String get knKbErr_no_vector =>
      'Searching by meaning is not ready on this computer yet.';

  @override
  String get knKbErr_not_found => 'It is not there any more.';

  @override
  String get knKbEtaSoon => 'The time left shows after the first minutes.';

  @override
  String get knKbFileExample => '/home/me/manual.pdf';

  @override
  String get knKbFileHelp =>
      'Its full path on the computer where RedGiant runs.';

  @override
  String get knKbFilePath => 'The file';

  @override
  String get knKbFolderExample =>
      '/home/me/Documents or C:\\Users\\me\\Documents';

  @override
  String get knKbFolderHelp =>
      'Its full path on the computer where RedGiant runs.';

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
      'Choose folders, files and pages: RedGiant reads them, cuts them into pieces and finds them by what they mean. The agents say where each answer comes from, and one click opens the file at that point.';

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
  String get knKbMeaningOffTitle =>
      'Searching by meaning is off: only by words';

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
  String get knKbNoMailboxes =>
      'No mailbox is connected yet: add one in Automations.';

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
  String get knKbPickFile => 'Choose a file in RedGiant';

  @override
  String get knKbPickFolder => 'Choose a folder in RedGiant';

  @override
  String get knKbPickOther => 'Choose another';

  @override
  String get knKbPickPlaces => 'Back to the projects';

  @override
  String get knKbPickThis => 'Choose this folder';

  @override
  String get knKbPickUp => 'Up one folder';

  @override
  String get knKbPickWhere => 'Your projects and RedGiant\'s folders';

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
  String get knKbRebuildHelp =>
      'Reads everything again with the same model, from the start.';

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
  String get knKbStateEmpty =>
      'Nothing to search yet: make a collection and add a folder.';

  @override
  String get knKbStateNoModel =>
      'Choose a model below to search by meaning; until then it searches by words.';

  @override
  String get knKbStateNoVector =>
      'Searching by meaning is not ready on this computer yet: for now it searches by words.';

  @override
  String get knKbStatePaused =>
      'Paused: the searches work, nothing new is read.';

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
  String get knKbThreadsHelp =>
      'Automatic leaves most of the processor to you.';

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
  String get knKbTryWordsOnly =>
      'Searched by words only (no model for the meaning yet).';

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
  String get knKbWhy_needs_libreoffice =>
      'An old Office file: it needs LibreOffice.';

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
  String get knMemAddPlaceholder =>
      'Something to remember, e.g. I prefer short answers';

  @override
  String get knMemAlready => 'Already remembered.';

  @override
  String get knMemAutoOff =>
      'Off: RedGiant learns nothing by itself. You can still add memories here, or ask an agent to remember something.';

  @override
  String get knMemAutoOn =>
      'After you write, RedGiant notes what stays true about you: tastes, work, how you like answers. It reads only your own messages, never emails, web pages or automations, and never notes passwords.';

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
      'RedGiant knows nothing about you yet. Talk with an agent, or write here something to remember.';

  @override
  String get knMemEyebrow => 'Shared memory';

  @override
  String get knMemForget => 'Forget for good';

  @override
  String get knMemForgetText =>
      'RedGiant deletes it, and its words go from the list of changes too. It can never be brought back.';

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
  String get knMemGoShared => 'Shared memory: what RedGiant knows about you';

  @override
  String get knMemGoSharedOpen => 'Open';

  @override
  String get knMemGoSharedText =>
      'Used by every agent and updated by itself while you talk.';

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
  String get knMemProjectHelp =>
      'Every agent working on this project reads it.';

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
  String get knMemTitle => 'What RedGiant knows about you';

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
}
