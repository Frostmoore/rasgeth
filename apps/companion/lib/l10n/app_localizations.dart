import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('it')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RGCompanion'**
  String get appTitle;

  /// No description provided for @tabTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get tabTeam;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @tabInbox.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get tabInbox;

  /// No description provided for @tabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivity;

  /// No description provided for @tabYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get tabYou;

  /// No description provided for @composerHint.
  ///
  /// In en, this message translates to:
  /// **'Write to Chat…'**
  String get composerHint;

  /// No description provided for @composerSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get composerSend;

  /// No description provided for @noServer.
  ///
  /// In en, this message translates to:
  /// **'No RedGiant connected'**
  String get noServer;

  /// No description provided for @connectFromYou.
  ///
  /// In en, this message translates to:
  /// **'Connect one from You.'**
  String get connectFromYou;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'connected'**
  String get statusConnected;

  /// No description provided for @statusUnreachable.
  ///
  /// In en, this message translates to:
  /// **'unreachable'**
  String get statusUnreachable;

  /// No description provided for @pillInbox.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get pillInbox;

  /// No description provided for @pillRunning.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get pillRunning;

  /// No description provided for @stateIdle.
  ///
  /// In en, this message translates to:
  /// **'idle'**
  String get stateIdle;

  /// No description provided for @stateThink.
  ///
  /// In en, this message translates to:
  /// **'thinking'**
  String get stateThink;

  /// No description provided for @stateWork.
  ///
  /// In en, this message translates to:
  /// **'working'**
  String get stateWork;

  /// No description provided for @stateWait.
  ///
  /// In en, this message translates to:
  /// **'waiting for you'**
  String get stateWait;

  /// No description provided for @stateError.
  ///
  /// In en, this message translates to:
  /// **'blocked'**
  String get stateError;

  /// No description provided for @mascotLabel.
  ///
  /// In en, this message translates to:
  /// **'Mascot of {name}, {state}'**
  String mascotLabel(String name, String state);

  /// No description provided for @teamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No agents yet.'**
  String get teamEmpty;

  /// No description provided for @chatNew.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get chatNew;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your conversations with Chat, day by day, show here.'**
  String get chatEmpty;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to decide: when an agent asks you something, it shows here.'**
  String get inboxEmpty;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tasks in progress and done, grouped by agent, show here.'**
  String get activityEmpty;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @reduceMotionHint.
  ///
  /// In en, this message translates to:
  /// **'The mascots stay still; their state shows by its sign.'**
  String get reduceMotionHint;

  /// No description provided for @sectionServer.
  ///
  /// In en, this message translates to:
  /// **'RedGiant'**
  String get sectionServer;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get serverAddress;

  /// No description provided for @serverAddressHint.
  ///
  /// In en, this message translates to:
  /// **'redgiant.local, https://…, 10.42.0.1'**
  String get serverAddressHint;

  /// No description provided for @serverPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get serverPassword;

  /// No description provided for @serverCode.
  ///
  /// In en, this message translates to:
  /// **'Authenticator code'**
  String get serverCode;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {machine}'**
  String connectedTo(String machine);

  /// No description provided for @errUnreachable.
  ///
  /// In en, this message translates to:
  /// **'RedGiant does not answer at this address.'**
  String get errUnreachable;

  /// No description provided for @errWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or code.'**
  String get errWrong;

  /// No description provided for @errCodeNeeded.
  ///
  /// In en, this message translates to:
  /// **'The authenticator app\'s code is needed too.'**
  String get errCodeNeeded;

  /// No description provided for @errTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many tries: try again in a few minutes.'**
  String get errTooMany;

  /// No description provided for @errNoPassword.
  ///
  /// In en, this message translates to:
  /// **'This RedGiant has no password yet: complete its first start.'**
  String get errNoPassword;

  /// No description provided for @errServerTooOld.
  ///
  /// In en, this message translates to:
  /// **'This RedGiant is too old for the app: update it.'**
  String get errServerTooOld;

  /// No description provided for @errServerTooNew.
  ///
  /// In en, this message translates to:
  /// **'This app is too old for this RedGiant: update the app.'**
  String get errServerTooNew;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'It did not work: {message}'**
  String errGeneric(String message);

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @attachmentOnly.
  ///
  /// In en, this message translates to:
  /// **'(images)'**
  String get attachmentOnly;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'The message did not leave: try again.'**
  String get sendFailed;

  /// No description provided for @attachmentTooBig.
  ///
  /// In en, this message translates to:
  /// **'{name} is over 5 MB.'**
  String attachmentTooBig(String name);

  /// No description provided for @notLive.
  ///
  /// In en, this message translates to:
  /// **'No live connection here: answers show when you open the conversation again.'**
  String get notLive;

  /// No description provided for @conversationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet: write the first message.'**
  String get conversationEmpty;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @attachmentRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get attachmentRemove;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach images'**
  String get attach;

  /// No description provided for @composerAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get composerAgentHint;

  /// No description provided for @fromSomeone.
  ///
  /// In en, this message translates to:
  /// **'from {from}'**
  String fromSomeone(String from);

  /// No description provided for @imagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 image} other{{count} images}}'**
  String imagesCount(int count);

  /// No description provided for @reasoning.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get reasoning;

  /// No description provided for @reasoningNow.
  ///
  /// In en, this message translates to:
  /// **'Reasoning…'**
  String get reasoningNow;

  /// No description provided for @writing.
  ///
  /// In en, this message translates to:
  /// **'writing…'**
  String get writing;

  /// No description provided for @toolRunning.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get toolRunning;

  /// No description provided for @toolOk.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get toolOk;

  /// No description provided for @toolFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get toolFailed;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @linkOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open this link outside the app?'**
  String get linkOpenTitle;

  /// No description provided for @linkOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get linkOpen;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @canvasFailed.
  ///
  /// In en, this message translates to:
  /// **'It cannot be shown: {error}'**
  String canvasFailed(String error);

  /// No description provided for @openWithSystem.
  ///
  /// In en, this message translates to:
  /// **'Open with the system\'s viewer'**
  String get openWithSystem;

  /// No description provided for @artifactSourceOnly.
  ///
  /// In en, this message translates to:
  /// **'On this system the app shows the artifact\'s source; its isolated preview comes with the desktop version.'**
  String get artifactSourceOnly;

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'reconnecting…'**
  String get statusReconnecting;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'It did not open: check the connection.'**
  String get openFailed;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get untitled;

  /// No description provided for @requestFrom.
  ///
  /// In en, this message translates to:
  /// **'{agent} asks you'**
  String requestFrom(String agent);

  /// No description provided for @requestCritical.
  ///
  /// In en, this message translates to:
  /// **'Truly dangerous, from {agent}'**
  String requestCritical(String agent);

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @requestLook.
  ///
  /// In en, this message translates to:
  /// **'Look at it'**
  String get requestLook;

  /// No description provided for @criticalTitle.
  ///
  /// In en, this message translates to:
  /// **'A truly dangerous request'**
  String get criticalTitle;

  /// No description provided for @criticalBody.
  ///
  /// In en, this message translates to:
  /// **'{agent} asks to do something that cannot be undone or that touches what protects you. Read it all before answering.'**
  String criticalBody(String agent);

  /// No description provided for @requestClosed.
  ///
  /// In en, this message translates to:
  /// **'Already answered ({via}).'**
  String requestClosed(String via);

  /// No description provided for @criticalNo.
  ///
  /// In en, this message translates to:
  /// **'No, do not do it'**
  String get criticalNo;

  /// No description provided for @criticalYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, do it'**
  String get criticalYes;

  /// No description provided for @criticalConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get criticalConfirmTitle;

  /// No description provided for @criticalConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be taken back.'**
  String get criticalConfirmBody;

  /// No description provided for @criticalSystem.
  ///
  /// In en, this message translates to:
  /// **'System files'**
  String get criticalSystem;

  /// No description provided for @criticalDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleting for good'**
  String get criticalDelete;

  /// No description provided for @criticalSecret.
  ///
  /// In en, this message translates to:
  /// **'A secret leaving'**
  String get criticalSecret;

  /// No description provided for @criticalPayment.
  ///
  /// In en, this message translates to:
  /// **'A real payment'**
  String get criticalPayment;

  /// No description provided for @criticalProtections.
  ///
  /// In en, this message translates to:
  /// **'RedGiant\'s own protections'**
  String get criticalProtections;

  /// No description provided for @questionFrom.
  ///
  /// In en, this message translates to:
  /// **'{agent} asks you a question'**
  String questionFrom(String agent);

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @taskRunning.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get taskRunning;

  /// No description provided for @taskOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get taskOpen;

  /// No description provided for @taskVerified.
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get taskVerified;

  /// No description provided for @taskNotTestable.
  ///
  /// In en, this message translates to:
  /// **'not testable'**
  String get taskNotTestable;

  /// No description provided for @taskAbandoned.
  ///
  /// In en, this message translates to:
  /// **'abandoned'**
  String get taskAbandoned;

  /// No description provided for @taskSteps.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps'**
  String taskSteps(int done, int total);

  /// No description provided for @verifiers.
  ///
  /// In en, this message translates to:
  /// **'Verifier'**
  String get verifiers;

  /// No description provided for @noVerifier.
  ///
  /// In en, this message translates to:
  /// **'No verifier has run yet.'**
  String get noVerifier;

  /// No description provided for @openConversation.
  ///
  /// In en, this message translates to:
  /// **'Open the conversation'**
  String get openConversation;

  /// No description provided for @reachPinned.
  ///
  /// In en, this message translates to:
  /// **'https, only with its own certificate (local CA)'**
  String get reachPinned;

  /// No description provided for @reachPublic.
  ///
  /// In en, this message translates to:
  /// **'public https (proxy, Tailscale)'**
  String get reachPublic;

  /// No description provided for @reachLoopback.
  ///
  /// In en, this message translates to:
  /// **'this computer'**
  String get reachLoopback;

  /// No description provided for @reachChannel.
  ///
  /// In en, this message translates to:
  /// **'encrypted setup channel'**
  String get reachChannel;

  /// No description provided for @noServers.
  ///
  /// In en, this message translates to:
  /// **'No RedGiant yet.'**
  String get noServers;

  /// No description provided for @useServer.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useServer;

  /// No description provided for @pinnedKey.
  ///
  /// In en, this message translates to:
  /// **'Key: {fingerprint}'**
  String pinnedKey(String fingerprint);

  /// No description provided for @renameServer.
  ///
  /// In en, this message translates to:
  /// **'Name of this RedGiant'**
  String get renameServer;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @forgetServer.
  ///
  /// In en, this message translates to:
  /// **'Disconnect this RedGiant?'**
  String get forgetServer;

  /// No description provided for @forgetServerBody.
  ///
  /// In en, this message translates to:
  /// **'The app forgets {name} and its device token. To come back, the password again.'**
  String forgetServerBody(String name);

  /// No description provided for @errKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'DANGER: this RedGiant answered with another key ({fingerprint}). Another computer may be in its place: nothing was sent.'**
  String errKeyChanged(String fingerprint);

  /// No description provided for @errCertificate.
  ///
  /// In en, this message translates to:
  /// **'The certificate is not this RedGiant\'s: the app did not go on.'**
  String get errCertificate;

  /// No description provided for @errBusy.
  ///
  /// In en, this message translates to:
  /// **'Another device is setting this RedGiant up: one at a time.'**
  String get errBusy;

  /// No description provided for @errSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again with the password.'**
  String get errSignInAgain;

  /// No description provided for @addServerFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect a RedGiant'**
  String get addServerFirst;

  /// No description provided for @addServer.
  ///
  /// In en, this message translates to:
  /// **'Add another RedGiant'**
  String get addServer;

  /// No description provided for @foundOnNetwork.
  ///
  /// In en, this message translates to:
  /// **'Found on this network'**
  String get foundOnNetwork;

  /// No description provided for @pairingNote.
  ///
  /// In en, this message translates to:
  /// **'The password is used once: the app keeps only a device token, revocable from Settings › Devices.'**
  String get pairingNote;

  /// No description provided for @allSettings.
  ///
  /// In en, this message translates to:
  /// **'All settings'**
  String get allSettings;

  /// No description provided for @allSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'RedGiant\'s whole Settings page, inside the app, signed in with this device.'**
  String get allSettingsHint;

  /// No description provided for @allSettingsBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opens RedGiant\'s page in the browser: sign in there as usual.'**
  String get allSettingsBrowser;

  /// No description provided for @allSettingsNoHttps.
  ///
  /// In en, this message translates to:
  /// **'The full settings need HTTPS: from here the page would travel in clear. Switch on HTTPS in the home network from the computer.'**
  String get allSettingsNoHttps;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @connectExisting.
  ///
  /// In en, this message translates to:
  /// **'Connect a RedGiant that runs already'**
  String get connectExisting;

  /// No description provided for @firstStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'No RedGiant yet'**
  String get firstStepsTitle;

  /// No description provided for @firstStepsLead.
  ///
  /// In en, this message translates to:
  /// **'Set up a new one from here (RedGiant OS opens its own Wi-Fi network at the first start), or connect one you already use.'**
  String get firstStepsLead;

  /// No description provided for @setupNew.
  ///
  /// In en, this message translates to:
  /// **'Set up a new RedGiant'**
  String get setupNew;

  /// No description provided for @setupNewHint.
  ///
  /// In en, this message translates to:
  /// **'A RedGiant OS machine turned on for the first time: the app joins its temporary network and does the whole first start.'**
  String get setupNewHint;

  /// No description provided for @defaultModel.
  ///
  /// In en, this message translates to:
  /// **'Default model'**
  String get defaultModel;

  /// No description provided for @setModel.
  ///
  /// In en, this message translates to:
  /// **'The model agents use when nobody chose another'**
  String get setModel;

  /// No description provided for @modelNone.
  ///
  /// In en, this message translates to:
  /// **'None yet: connect a way of thinking'**
  String get modelNone;

  /// No description provided for @devLastUsed.
  ///
  /// In en, this message translates to:
  /// **'last used {when}'**
  String devLastUsed(String when);

  /// No description provided for @devNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'never used'**
  String get devNeverUsed;

  /// No description provided for @devNone.
  ///
  /// In en, this message translates to:
  /// **'No device with its own access.'**
  String get devNone;

  /// No description provided for @devRevoke.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get devRevoke;

  /// No description provided for @devRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign this device out?'**
  String get devRevokeTitle;

  /// No description provided for @devRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'«{name}» is signed out at once and needs the password to come back.'**
  String devRevokeBody(String name);

  /// No description provided for @devThis.
  ///
  /// In en, this message translates to:
  /// **'this device'**
  String get devThis;

  /// No description provided for @fsTitle.
  ///
  /// In en, this message translates to:
  /// **'First start'**
  String get fsTitle;

  /// No description provided for @fsLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get fsLeave;

  /// No description provided for @fsLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the first start?'**
  String get fsLeaveTitle;

  /// No description provided for @fsLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'What is done stays done; you can come back here, or finish from the browser, while the temporary network is open (30 minutes from when RedGiant was turned on).'**
  String get fsLeaveBody;

  /// No description provided for @fsIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up a new RedGiant'**
  String get fsIntroTitle;

  /// No description provided for @fsIntroLead.
  ///
  /// In en, this message translates to:
  /// **'Turn your RedGiant on: for 30 minutes it opens the Wi-Fi network RedGiant-Setup-XXXX. The app joins it, you create the access and choose your home network, then RedGiant moves there and the app finds it again.'**
  String get fsIntroLead;

  /// No description provided for @fsIntroSafe.
  ///
  /// In en, this message translates to:
  /// **'Everything you type travels encrypted, with RedGiant\'s own key checked by the app: nobody on the temporary network reads it.'**
  String get fsIntroSafe;

  /// No description provided for @fsSeen.
  ///
  /// In en, this message translates to:
  /// **'Temporary networks around'**
  String get fsSeen;

  /// No description provided for @fsNoScan.
  ///
  /// In en, this message translates to:
  /// **'The system does not show the networks around: type the four characters after RedGiant-Setup- (you see them in the computer\'s Wi-Fi list).'**
  String get fsNoScan;

  /// No description provided for @fsLetters.
  ///
  /// In en, this message translates to:
  /// **'The last four characters'**
  String get fsLetters;

  /// No description provided for @fsScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get fsScanAgain;

  /// No description provided for @fsJoin.
  ///
  /// In en, this message translates to:
  /// **'Join the network'**
  String get fsJoin;

  /// No description provided for @fsByHand.
  ///
  /// In en, this message translates to:
  /// **'I join by hand'**
  String get fsByHand;

  /// No description provided for @fsJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining the temporary network…'**
  String get fsJoining;

  /// No description provided for @fsJoiningSheet.
  ///
  /// In en, this message translates to:
  /// **'Choose RedGiant-Setup in the window the system shows.'**
  String get fsJoiningSheet;

  /// No description provided for @fsConnecting.
  ///
  /// In en, this message translates to:
  /// **'Looking for RedGiant on the network…'**
  String get fsConnecting;

  /// No description provided for @fsManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Join by hand'**
  String get fsManualTitle;

  /// No description provided for @fsManualLead.
  ///
  /// In en, this message translates to:
  /// **'Join the network {ssid} (password {password}) from the Wi-Fi settings, then come back here.'**
  String fsManualLead(String ssid, String password);

  /// No description provided for @fsNetworkName.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get fsNetworkName;

  /// No description provided for @fsNetworkPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fsNetworkPassword;

  /// No description provided for @fsWhereAndroid.
  ///
  /// In en, this message translates to:
  /// **'Settings › Network › Wi-Fi: tap RedGiant-Setup-…'**
  String get fsWhereAndroid;

  /// No description provided for @fsWhereIos.
  ///
  /// In en, this message translates to:
  /// **'Settings › Wi-Fi: tap RedGiant-Setup-…'**
  String get fsWhereIos;

  /// No description provided for @fsWhereMac.
  ///
  /// In en, this message translates to:
  /// **'The Wi-Fi menu at the top right of the screen: choose RedGiant-Setup-…'**
  String get fsWhereMac;

  /// No description provided for @fsWhereWindows.
  ///
  /// In en, this message translates to:
  /// **'The Wi-Fi icon at the bottom right: choose RedGiant-Setup-…'**
  String get fsWhereWindows;

  /// No description provided for @fsWhereOther.
  ///
  /// In en, this message translates to:
  /// **'The system\'s Wi-Fi list: choose RedGiant-Setup-…'**
  String get fsWhereOther;

  /// No description provided for @fsManualNoInternet.
  ///
  /// In en, this message translates to:
  /// **'The system may say the network has no internet: that is right, stay on it.'**
  String get fsManualNoInternet;

  /// No description provided for @fsJoinedContinue.
  ///
  /// In en, this message translates to:
  /// **'Done, go on'**
  String get fsJoinedContinue;

  /// No description provided for @fsErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'RedGiant does not answer: are you on the RedGiant-Setup network? It stays open for 30 minutes after RedGiant is turned on.'**
  String get fsErrNotFound;

  /// No description provided for @fsErrNotHere.
  ///
  /// In en, this message translates to:
  /// **'This RedGiant does not let a new access be created from here: finish from its page.'**
  String get fsErrNotHere;

  /// No description provided for @fsErrCancelled.
  ///
  /// In en, this message translates to:
  /// **'The network was not joined. Try again, or join by hand.'**
  String get fsErrCancelled;

  /// No description provided for @fsErrDenied.
  ///
  /// In en, this message translates to:
  /// **'The app needs the permission for nearby devices to join the network: allow it, or join by hand.'**
  String get fsErrDenied;

  /// No description provided for @fsErrJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'The system could not join the network: join by hand.'**
  String get fsErrJoinFailed;

  /// No description provided for @fsErrNoName.
  ///
  /// In en, this message translates to:
  /// **'Choose the network, or type its four last characters.'**
  String get fsErrNoName;

  /// No description provided for @fsAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your access'**
  String get fsAccessTitle;

  /// No description provided for @fsAccessLead.
  ///
  /// In en, this message translates to:
  /// **'The password that opens RedGiant from every device. Keep it: it is also what opens its keychain.'**
  String get fsAccessLead;

  /// No description provided for @fsPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fsPassword;

  /// No description provided for @fsPasswordAgain.
  ///
  /// In en, this message translates to:
  /// **'The password again'**
  String get fsPasswordAgain;

  /// No description provided for @fsPasswordNeeded.
  ///
  /// In en, this message translates to:
  /// **'A password is needed.'**
  String get fsPasswordNeeded;

  /// No description provided for @fsPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters, not all the same.'**
  String get fsPasswordWeak;

  /// No description provided for @fsPasswordDiffer.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are different.'**
  String get fsPasswordDiffer;

  /// No description provided for @fsAccessSafe.
  ///
  /// In en, this message translates to:
  /// **'It travels encrypted to RedGiant and stays only there; this device gets its own access, which you can sign out from Settings › Devices.'**
  String get fsAccessSafe;

  /// No description provided for @fsAccessGo.
  ///
  /// In en, this message translates to:
  /// **'Create the access'**
  String get fsAccessGo;

  /// No description provided for @fsSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get fsSignInTitle;

  /// No description provided for @fsSignInLead.
  ///
  /// In en, this message translates to:
  /// **'This RedGiant has its password already: type it to go on.'**
  String get fsSignInLead;

  /// No description provided for @fsMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'RedGiant lost its network'**
  String get fsMaintenanceTitle;

  /// No description provided for @fsMaintenanceLead.
  ///
  /// In en, this message translates to:
  /// **'It opened the temporary network to be given a new one. Its owner\'s password, and nothing else changes.'**
  String get fsMaintenanceLead;

  /// No description provided for @fsHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your home network'**
  String get fsHomeTitle;

  /// No description provided for @fsHomeLead.
  ///
  /// In en, this message translates to:
  /// **'Which network should RedGiant use at home? These are the ones it saw around it.'**
  String get fsHomeLead;

  /// No description provided for @fsHomeNone.
  ///
  /// In en, this message translates to:
  /// **'No network was seen around: use the cable, or type the name of a hidden network.'**
  String get fsHomeNone;

  /// No description provided for @fsHomeUnusable.
  ///
  /// In en, this message translates to:
  /// **'RedGiant cannot join this kind of network'**
  String get fsHomeUnusable;

  /// No description provided for @fsHomeHidden.
  ///
  /// In en, this message translates to:
  /// **'A hidden network'**
  String get fsHomeHidden;

  /// No description provided for @fsHomeHiddenName.
  ///
  /// In en, this message translates to:
  /// **'Network name'**
  String get fsHomeHiddenName;

  /// No description provided for @fsHomePassword.
  ///
  /// In en, this message translates to:
  /// **'Password of «{name}»'**
  String fsHomePassword(String name);

  /// No description provided for @fsHomeSafe.
  ///
  /// In en, this message translates to:
  /// **'The Wi-Fi password stays only in RedGiant.'**
  String get fsHomeSafe;

  /// No description provided for @fsHomeJoin.
  ///
  /// In en, this message translates to:
  /// **'Use «{name}»'**
  String fsHomeJoin(String name);

  /// No description provided for @fsHomeCable.
  ///
  /// In en, this message translates to:
  /// **'I use the cable'**
  String get fsHomeCable;

  /// No description provided for @fsHomeWaitWifi.
  ///
  /// In en, this message translates to:
  /// **'RedGiant is joining «{name}»…'**
  String fsHomeWaitWifi(String name);

  /// No description provided for @fsHomeWaitCable.
  ///
  /// In en, this message translates to:
  /// **'RedGiant moves to the home network…'**
  String get fsHomeWaitCable;

  /// No description provided for @fsHomeWaitSub.
  ///
  /// In en, this message translates to:
  /// **'The device goes back to its own network and finds RedGiant there (up to two minutes). If it does not work, RedGiant opens the temporary network again and says why.'**
  String get fsHomeWaitSub;

  /// No description provided for @fsLostTitle.
  ///
  /// In en, this message translates to:
  /// **'RedGiant is not found'**
  String get fsLostTitle;

  /// No description provided for @fsLostLead.
  ///
  /// In en, this message translates to:
  /// **'Neither at home nor on {ssid}. Check that this device is back on the home network, then look again; or join the temporary network by hand to see what happened.'**
  String fsLostLead(String ssid);

  /// No description provided for @fsLookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get fsLookAgain;

  /// No description provided for @fsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get fsLanguageTitle;

  /// No description provided for @fsLanguageLead.
  ///
  /// In en, this message translates to:
  /// **'The language of the app and of the page, and the one the agents speak to you.'**
  String get fsLanguageLead;

  /// No description provided for @fsLanguageUi.
  ///
  /// In en, this message translates to:
  /// **'App and page'**
  String get fsLanguageUi;

  /// No description provided for @fsLanguageAgents.
  ///
  /// In en, this message translates to:
  /// **'The agents speak'**
  String get fsLanguageAgents;

  /// No description provided for @fsNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get fsNext;

  /// No description provided for @fsLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get fsLater;

  /// No description provided for @fsBrainTitle.
  ///
  /// In en, this message translates to:
  /// **'How should RedGiant think?'**
  String get fsBrainTitle;

  /// No description provided for @fsBrainLead.
  ///
  /// In en, this message translates to:
  /// **'A subscription you have already, or a key of a provider. Any of them, or none for now.'**
  String get fsBrainLead;

  /// No description provided for @fsClaude.
  ///
  /// In en, this message translates to:
  /// **'Claude Pro or Max'**
  String get fsClaude;

  /// No description provided for @fsClaudeText.
  ///
  /// In en, this message translates to:
  /// **'Anthropic\'s page in the browser, then the code it shows'**
  String get fsClaudeText;

  /// No description provided for @fsClaudeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Anthropic\'s page'**
  String get fsClaudeOpen;

  /// No description provided for @fsClaudeCode.
  ///
  /// In en, this message translates to:
  /// **'The code the page shows'**
  String get fsClaudeCode;

  /// No description provided for @fsChatgpt.
  ///
  /// In en, this message translates to:
  /// **'ChatGPT Plus or Pro'**
  String get fsChatgpt;

  /// No description provided for @fsChatgptText.
  ///
  /// In en, this message translates to:
  /// **'A code to type on OpenAI\'s page'**
  String get fsChatgptText;

  /// No description provided for @fsChatgptOpen.
  ///
  /// In en, this message translates to:
  /// **'Open OpenAI\'s page'**
  String get fsChatgptOpen;

  /// No description provided for @fsChatgptCode.
  ///
  /// In en, this message translates to:
  /// **'Type this code on the page; the app notices when it is done.'**
  String get fsChatgptCode;

  /// No description provided for @fsChatgptOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Open the page again'**
  String get fsChatgptOpenAgain;

  /// No description provided for @fsKey.
  ///
  /// In en, this message translates to:
  /// **'A key of a provider'**
  String get fsKey;

  /// No description provided for @fsKeyText.
  ///
  /// In en, this message translates to:
  /// **'Anthropic, OpenAI, Gemini, OpenRouter…: paid per use'**
  String get fsKeyText;

  /// No description provided for @fsKeyOf.
  ///
  /// In en, this message translates to:
  /// **'Key of {name}'**
  String fsKeyOf(String name);

  /// No description provided for @fsKeySaved.
  ///
  /// In en, this message translates to:
  /// **'{name}: the key works.'**
  String fsKeySaved(String name);

  /// No description provided for @fsTerms.
  ///
  /// In en, this message translates to:
  /// **'I read the provider\'s terms: a subscription is used by me, on my own RedGiant.'**
  String get fsTerms;

  /// No description provided for @fsBrainLater.
  ///
  /// In en, this message translates to:
  /// **'Models on this machine, your own server and the rest are in Settings, from the computer or from «All settings».'**
  String get fsBrainLater;

  /// No description provided for @fsNamesTitle.
  ///
  /// In en, this message translates to:
  /// **'The names'**
  String get fsNamesTitle;

  /// No description provided for @fsNamesLead.
  ///
  /// In en, this message translates to:
  /// **'Who runs your RedGiant, and who speaks for it in the chats. You can change them later.'**
  String get fsNamesLead;

  /// No description provided for @fsGodName.
  ///
  /// In en, this message translates to:
  /// **'The chief'**
  String get fsGodName;

  /// No description provided for @fsGodHelp.
  ///
  /// In en, this message translates to:
  /// **'It organises the work and hands it to the agents'**
  String get fsGodHelp;

  /// No description provided for @fsDemigodName.
  ///
  /// In en, this message translates to:
  /// **'The spokesperson'**
  String get fsDemigodName;

  /// No description provided for @fsDemigodHelp.
  ///
  /// In en, this message translates to:
  /// **'It answers you on Telegram and the other chats'**
  String get fsDemigodHelp;

  /// No description provided for @fsFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get fsFinish;

  /// No description provided for @fsFinishing.
  ///
  /// In en, this message translates to:
  /// **'Completing the first start…'**
  String get fsFinishing;

  /// No description provided for @fsDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'RedGiant is ready'**
  String get fsDoneTitle;

  /// No description provided for @fsDoneLead.
  ///
  /// In en, this message translates to:
  /// **'The temporary network is closed: RedGiant is on your home network, and this device is connected to it.'**
  String get fsDoneLead;

  /// No description provided for @fsDoneMaintenance.
  ///
  /// In en, this message translates to:
  /// **'RedGiant is on its new network again, and this device is connected to it.'**
  String get fsDoneMaintenance;

  /// No description provided for @fsDoneMore.
  ///
  /// In en, this message translates to:
  /// **'The rest of the first start (backups, chats, access from outside…) is in the page, whenever you want: «Settings of RedGiant» › «All settings».'**
  String get fsDoneMore;

  /// No description provided for @fsDoneGo.
  ///
  /// In en, this message translates to:
  /// **'Open the team'**
  String get fsDoneGo;

  /// No description provided for @homeErrConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'The network refused to connect: check the password and try again.'**
  String get homeErrConnectFailed;

  /// No description provided for @homeErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'That network is not in reach now.'**
  String get homeErrNotFound;

  /// No description provided for @homeErrBadPassword.
  ///
  /// In en, this message translates to:
  /// **'A Wi-Fi password has 8 to 63 characters.'**
  String get homeErrBadPassword;

  /// No description provided for @homeErrBadSsid.
  ///
  /// In en, this message translates to:
  /// **'A network\'s name has 1 to 32 characters.'**
  String get homeErrBadSsid;

  /// No description provided for @homeErrBusy.
  ///
  /// In en, this message translates to:
  /// **'RedGiant is already joining a network: wait a moment.'**
  String get homeErrBusy;

  /// No description provided for @homeErrWifiOff.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is not running on RedGiant.'**
  String get homeErrWifiOff;

  /// No description provided for @homeErrNoCable.
  ///
  /// In en, this message translates to:
  /// **'No cable with an address: connect it to the router, or choose a Wi-Fi network.'**
  String get homeErrNoCable;

  /// No description provided for @homeErrFailed.
  ///
  /// In en, this message translates to:
  /// **'That did not work. Try again in a moment.'**
  String get homeErrFailed;

  /// No description provided for @outsideNone.
  ///
  /// In en, this message translates to:
  /// **'Only from the home network. Tailscale, Cloudflare or your own name: in «All settings».'**
  String get outsideNone;

  /// No description provided for @outsideOwn.
  ///
  /// In en, this message translates to:
  /// **'Your own way in'**
  String get outsideOwn;

  /// No description provided for @outsideOwnName.
  ///
  /// In en, this message translates to:
  /// **'Your own name (Caddy)'**
  String get outsideOwnName;

  /// No description provided for @pushOff.
  ///
  /// In en, this message translates to:
  /// **'Not on for this device yet.'**
  String get pushOff;

  /// No description provided for @pushOn.
  ///
  /// In en, this message translates to:
  /// **'On, through {target}'**
  String pushOn(String target);

  /// No description provided for @pushBlocked.
  ///
  /// In en, this message translates to:
  /// **'Nothing can be sent now (the keychain is locked, or the relay is off).'**
  String get pushBlocked;

  /// No description provided for @pushTest.
  ///
  /// In en, this message translates to:
  /// **'Send a test'**
  String get pushTest;

  /// No description provided for @pushTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent.'**
  String get pushTestSent;

  /// No description provided for @pushTestFailed.
  ///
  /// In en, this message translates to:
  /// **'The test did not go: {why}'**
  String pushTestFailed(String why);

  /// No description provided for @sectionUpdates.
  ///
  /// In en, this message translates to:
  /// **'UPDATES'**
  String get sectionUpdates;

  /// No description provided for @sectionDevices.
  ///
  /// In en, this message translates to:
  /// **'DEVICES CONNECTED'**
  String get sectionDevices;

  /// No description provided for @sectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'THIS DEVICE\'S NOTIFICATIONS'**
  String get sectionNotifications;

  /// No description provided for @sectionModel.
  ///
  /// In en, this message translates to:
  /// **'MODEL AND VOICE'**
  String get sectionModel;

  /// No description provided for @sectionOutside.
  ///
  /// In en, this message translates to:
  /// **'FROM OUTSIDE HOME'**
  String get sectionOutside;

  /// No description provided for @serverSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings of {name}'**
  String serverSettingsTitle(String name);

  /// No description provided for @serverSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Name, updates, devices, model, voice'**
  String get serverSettingsSub;

  /// No description provided for @versionOf.
  ///
  /// In en, this message translates to:
  /// **'version {version}'**
  String versionOf(String version);

  /// No description provided for @updLatest.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get updLatest;

  /// No description provided for @updAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updAvailable(String version);

  /// No description provided for @updApplying.
  ///
  /// In en, this message translates to:
  /// **'Updating to {version}…'**
  String updApplying(String version);

  /// No description provided for @updInstalled.
  ///
  /// In en, this message translates to:
  /// **'installed {version}'**
  String updInstalled(String version);

  /// No description provided for @updChecked.
  ///
  /// In en, this message translates to:
  /// **'checked {when}'**
  String updChecked(String when);

  /// No description provided for @updLook.
  ///
  /// In en, this message translates to:
  /// **'Look for updates'**
  String get updLook;

  /// No description provided for @updLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking…'**
  String get updLooking;

  /// No description provided for @updNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updNow;

  /// No description provided for @updNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Update RedGiant?'**
  String get updNowTitle;

  /// No description provided for @updNowBody.
  ///
  /// In en, this message translates to:
  /// **'RedGiant installs {version} and restarts: for a few minutes it does not answer, then the app connects again by itself.'**
  String updNowBody(String version);

  /// No description provided for @updStarted.
  ///
  /// In en, this message translates to:
  /// **'The update started.'**
  String get updStarted;

  /// No description provided for @updBreaking.
  ///
  /// In en, this message translates to:
  /// **'This version needs a clean install (with a backup first): from the computer.'**
  String get updBreaking;

  /// No description provided for @updDockerHint.
  ///
  /// In en, this message translates to:
  /// **'In Docker the new version comes with these commands, on the computer that runs it:'**
  String get updDockerHint;

  /// No description provided for @updReboot.
  ///
  /// In en, this message translates to:
  /// **'A security update asks for a restart.'**
  String get updReboot;

  /// No description provided for @updBytes.
  ///
  /// In en, this message translates to:
  /// **'{done} MB of {total} MB'**
  String updBytes(String done, String total);

  /// No description provided for @updSpeed.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB/s'**
  String updSpeed(String mb);

  /// No description provided for @updEtaMin.
  ///
  /// In en, this message translates to:
  /// **'{n} min left'**
  String updEtaMin(String n);

  /// No description provided for @updEtaSec.
  ///
  /// In en, this message translates to:
  /// **'{n} s left'**
  String updEtaSec(String n);

  /// No description provided for @updStepCheck.
  ///
  /// In en, this message translates to:
  /// **'Checking the release'**
  String get updStepCheck;

  /// No description provided for @updStepDownload.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get updStepDownload;

  /// No description provided for @updStepFiles.
  ///
  /// In en, this message translates to:
  /// **'The system\'s files'**
  String get updStepFiles;

  /// No description provided for @updStepInstall.
  ///
  /// In en, this message translates to:
  /// **'Installing'**
  String get updStepInstall;

  /// No description provided for @updStepRestart.
  ///
  /// In en, this message translates to:
  /// **'Restarting'**
  String get updStepRestart;

  /// No description provided for @updStepWait.
  ///
  /// In en, this message translates to:
  /// **'Waiting for RedGiant to answer'**
  String get updStepWait;

  /// No description provided for @updStepRollback.
  ///
  /// In en, this message translates to:
  /// **'Going back to the version before'**
  String get updStepRollback;

  /// No description provided for @updStepScan.
  ///
  /// In en, this message translates to:
  /// **'Comparing the files'**
  String get updStepScan;

  /// No description provided for @updStepBuild.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get updStepBuild;

  /// No description provided for @updStepFailed.
  ///
  /// In en, this message translates to:
  /// **'It stopped'**
  String get updStepFailed;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @voiceHear.
  ///
  /// In en, this message translates to:
  /// **'Hears with: {what}'**
  String voiceHear(String what);

  /// No description provided for @voiceRead.
  ///
  /// In en, this message translates to:
  /// **'Reads with: {what}'**
  String voiceRead(String what);

  /// No description provided for @voiceNone.
  ///
  /// In en, this message translates to:
  /// **'nothing set yet'**
  String get voiceNone;

  /// No description provided for @voiceBrowser.
  ///
  /// In en, this message translates to:
  /// **'the device\'s own voice'**
  String get voiceBrowser;

  /// No description provided for @teamAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teamAll;

  /// No description provided for @teamFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get teamFavourites;

  /// No description provided for @teamFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get teamFilterLabel;

  /// No description provided for @teamNoFavourites.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet: press and hold an agent to add it.'**
  String get teamNoFavourites;

  /// No description provided for @teamNoneInProject.
  ///
  /// In en, this message translates to:
  /// **'No agent has worked in this project.'**
  String get teamNoneInProject;

  /// No description provided for @favouriteMark.
  ///
  /// In en, this message translates to:
  /// **'favourite'**
  String get favouriteMark;

  /// No description provided for @agentDoing.
  ///
  /// In en, this message translates to:
  /// **'What it is doing'**
  String get agentDoing;

  /// No description provided for @agentIdleNow.
  ///
  /// In en, this message translates to:
  /// **'Idle right now.'**
  String get agentIdleNow;

  /// No description provided for @agentWaitsYou.
  ///
  /// In en, this message translates to:
  /// **'It is waiting for your answer in «For you».'**
  String get agentWaitsYou;

  /// No description provided for @agentTask.
  ///
  /// In en, this message translates to:
  /// **'Task: {title}'**
  String agentTask(String title);

  /// No description provided for @agentLastAt.
  ///
  /// In en, this message translates to:
  /// **'Last activity: {when}'**
  String agentLastAt(String when);

  /// No description provided for @agentStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get agentStop;

  /// No description provided for @agentStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped: {name}'**
  String agentStopped(String name);

  /// No description provided for @agentStopFailed.
  ///
  /// In en, this message translates to:
  /// **'It did not stop: check the connection.'**
  String get agentStopFailed;

  /// No description provided for @agentOpenTask.
  ///
  /// In en, this message translates to:
  /// **'Open the task'**
  String get agentOpenTask;

  /// No description provided for @agentOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open the conversation'**
  String get agentOpenChat;

  /// No description provided for @favouriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get favouriteAdd;

  /// No description provided for @favouriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get favouriteRemove;

  /// No description provided for @inboxPosition.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String inboxPosition(String n, String total);

  /// No description provided for @inboxSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to say yes, left to say no.'**
  String get inboxSwipeHint;

  /// No description provided for @inboxCriticalHint.
  ///
  /// In en, this message translates to:
  /// **'Truly dangerous: no swiping, it opens full screen.'**
  String get inboxCriticalHint;

  /// No description provided for @inboxSaidYes.
  ///
  /// In en, this message translates to:
  /// **'Yes to {name}'**
  String inboxSaidYes(String name);

  /// No description provided for @inboxSaidNo.
  ///
  /// In en, this message translates to:
  /// **'No to {name}'**
  String inboxSaidNo(String name);

  /// No description provided for @inboxNext.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get inboxNext;

  /// No description provided for @modelWay.
  ///
  /// In en, this message translates to:
  /// **'How it goes'**
  String get modelWay;

  /// No description provided for @modelWaySubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get modelWaySubscription;

  /// No description provided for @modelWayKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get modelWayKey;

  /// No description provided for @modelWayNode.
  ///
  /// In en, this message translates to:
  /// **'Via {node}'**
  String modelWayNode(String node);

  /// No description provided for @modelWayLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get modelWayLocal;

  /// No description provided for @modelWayOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get modelWayOr;

  /// No description provided for @modelHintSubscription.
  ///
  /// In en, this message translates to:
  /// **'Within your plan\'s limits: nothing is paid per use.'**
  String get modelHintSubscription;

  /// No description provided for @modelHintKey.
  ///
  /// In en, this message translates to:
  /// **'Paid per use with your API key: it counts toward the spending cap.'**
  String get modelHintKey;

  /// No description provided for @modelHintNode.
  ///
  /// In en, this message translates to:
  /// **'Goes through the computer {node}.'**
  String modelHintNode(String node);

  /// No description provided for @modelHintLocal.
  ///
  /// In en, this message translates to:
  /// **'Runs on a computer of yours: nothing is paid per use.'**
  String get modelHintLocal;

  /// No description provided for @modelHintOther.
  ///
  /// In en, this message translates to:
  /// **'Through a connected provider.'**
  String get modelHintOther;

  /// No description provided for @stateActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get stateActive;

  /// No description provided for @teamAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get teamAgents;

  /// No description provided for @teamNewAgent.
  ///
  /// In en, this message translates to:
  /// **'New agent'**
  String get teamNewAgent;

  /// No description provided for @teamNoAgents.
  ///
  /// In en, this message translates to:
  /// **'No other agents yet: make one with «New agent».'**
  String get teamNoAgents;

  /// No description provided for @teamChatLead.
  ///
  /// In en, this message translates to:
  /// **'Your everyday conversations'**
  String get teamChatLead;

  /// No description provided for @agentJustAnswered.
  ///
  /// In en, this message translates to:
  /// **'It has just answered you.'**
  String get agentJustAnswered;

  /// No description provided for @agentBlockedNow.
  ///
  /// In en, this message translates to:
  /// **'It is blocked: open the conversation to see why.'**
  String get agentBlockedNow;

  /// No description provided for @effortLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get effortLow;

  /// No description provided for @effortMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get effortMedium;

  /// No description provided for @effortHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get effortHigh;

  /// No description provided for @effortMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get effortMax;

  /// No description provided for @effortTitle.
  ///
  /// In en, this message translates to:
  /// **'Reasoning effort'**
  String get effortTitle;

  /// No description provided for @agentModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get agentModel;

  /// No description provided for @agentModelInherit.
  ///
  /// In en, this message translates to:
  /// **'The same as the one above it'**
  String get agentModelInherit;

  /// No description provided for @agentModelDefault.
  ///
  /// In en, this message translates to:
  /// **'The default model'**
  String get agentModelDefault;

  /// No description provided for @agentModelSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: its next messages use it.'**
  String get agentModelSaved;

  /// No description provided for @agentModelFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not change the model.'**
  String get agentModelFailed;

  /// No description provided for @agentModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Model of {name}'**
  String agentModelTitle(String name);

  /// No description provided for @modelNow.
  ///
  /// In en, this message translates to:
  /// **'Now: {model}'**
  String modelNow(String model);

  /// No description provided for @modelUse.
  ///
  /// In en, this message translates to:
  /// **'Use {model}'**
  String modelUse(String model);

  /// No description provided for @modelInheritOf.
  ///
  /// In en, this message translates to:
  /// **'{label} ({model})'**
  String modelInheritOf(String label, String model);

  /// No description provided for @noModels.
  ///
  /// In en, this message translates to:
  /// **'No model connected: connect one in the settings.'**
  String get noModels;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More commands'**
  String get more;

  /// No description provided for @moreChanged.
  ///
  /// In en, this message translates to:
  /// **'More commands (something is not as it starts)'**
  String get moreChanged;

  /// No description provided for @moreMode.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String moreMode(String mode);

  /// No description provided for @moreModeHint.
  ///
  /// In en, this message translates to:
  /// **'It holds for all of {name}\'s conversations.'**
  String moreModeHint(String name);

  /// No description provided for @moreModel.
  ///
  /// In en, this message translates to:
  /// **'Model: {model}'**
  String moreModel(String model);

  /// No description provided for @moreModelHint.
  ///
  /// In en, this message translates to:
  /// **'The model of this conversation (agents\' models: long press the agent in Team)'**
  String get moreModelHint;

  /// No description provided for @moreModelBusy.
  ///
  /// In en, this message translates to:
  /// **'It changes once it has finished working.'**
  String get moreModelBusy;

  /// No description provided for @moreOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get moreOpen;

  /// No description provided for @moreClosed.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get moreClosed;

  /// No description provided for @moreSectionHow.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get moreSectionHow;

  /// No description provided for @moreSectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreSectionMore;

  /// No description provided for @mode_manual.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get mode_manual;

  /// No description provided for @mode_auto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get mode_auto;

  /// No description provided for @mode_plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get mode_plan;

  /// No description provided for @mode_readonly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get mode_readonly;

  /// No description provided for @modeFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not change the mode.'**
  String get modeFailed;

  /// No description provided for @agentsModel.
  ///
  /// In en, this message translates to:
  /// **'Agent\'s model'**
  String get agentsModel;

  /// No description provided for @modelPick.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get modelPick;

  /// No description provided for @sessionModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Model of this conversation'**
  String get sessionModelTitle;

  /// No description provided for @sessionModelBusy.
  ///
  /// In en, this message translates to:
  /// **'It is working: the model changes once it has finished.'**
  String get sessionModelBusy;

  /// No description provided for @asideChip.
  ///
  /// In en, this message translates to:
  /// **'Meanwhile'**
  String get asideChip;

  /// No description provided for @asideHint.
  ///
  /// In en, this message translates to:
  /// **'A quick question on the side, also while the agent works: it knows the conversation, but nothing of it enters the chat'**
  String get asideHint;

  /// No description provided for @asideTitle.
  ///
  /// In en, this message translates to:
  /// **'Meanwhile'**
  String get asideTitle;

  /// No description provided for @asideSub.
  ///
  /// In en, this message translates to:
  /// **'Not part of the conversation'**
  String get asideSub;

  /// No description provided for @asideEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about this conversation. The answer stays here: it does not enter the chat nor the agent\'s memory.'**
  String get asideEmpty;

  /// No description provided for @asidePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'A quick question…'**
  String get asidePlaceholder;

  /// No description provided for @asidePlaceholderBusy.
  ///
  /// In en, this message translates to:
  /// **'A quick question, while the agent works…'**
  String get asidePlaceholderBusy;

  /// No description provided for @asideAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get asideAsk;

  /// No description provided for @asideThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get asideThinking;

  /// No description provided for @asideFailed.
  ///
  /// In en, this message translates to:
  /// **'No answer: {why}'**
  String asideFailed(String why);

  /// No description provided for @asideToChat.
  ///
  /// In en, this message translates to:
  /// **'Bring into the chat'**
  String get asideToChat;

  /// No description provided for @asideBrought.
  ///
  /// In en, this message translates to:
  /// **'Brought into the chat.'**
  String get asideBrought;

  /// No description provided for @compactNow.
  ///
  /// In en, this message translates to:
  /// **'Summarise'**
  String get compactNow;

  /// No description provided for @compactNowHint.
  ///
  /// In en, this message translates to:
  /// **'Summarise the older part of this conversation now: the agent keeps the recent turns and can still read everything'**
  String get compactNowHint;

  /// No description provided for @compactNowAsk.
  ///
  /// In en, this message translates to:
  /// **'Summarise the conversation now. Anything to keep in particular? (optional)'**
  String get compactNowAsk;

  /// No description provided for @compactNowYes.
  ///
  /// In en, this message translates to:
  /// **'Summarise'**
  String get compactNowYes;

  /// No description provided for @compactNowSent.
  ///
  /// In en, this message translates to:
  /// **'Summarising the conversation.'**
  String get compactNowSent;

  /// No description provided for @roomFromChat.
  ///
  /// In en, this message translates to:
  /// **'Add an agent'**
  String get roomFromChat;

  /// No description provided for @roomFromChatHint.
  ///
  /// In en, this message translates to:
  /// **'Turn this conversation into a group chat: add other agents, inspectors included'**
  String get roomFromChatHint;

  /// No description provided for @roomPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Who joins the group chat?'**
  String get roomPickTitle;

  /// No description provided for @roomAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} is in the group chat: you find it in the page, among the conversations.'**
  String roomAdded(String name);

  /// No description provided for @roomFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not make the group chat.'**
  String get roomFailed;

  /// No description provided for @whileRunning.
  ///
  /// In en, this message translates to:
  /// **'Not while it works.'**
  String get whileRunning;

  /// No description provided for @newAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'New agent'**
  String get newAgentTitle;

  /// No description provided for @newAgentStep.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String newAgentStep(int n, int total);

  /// No description provided for @newAgentKindQ.
  ///
  /// In en, this message translates to:
  /// **'What kind of agent do you need?'**
  String get newAgentKindQ;

  /// No description provided for @newAgentKindAgent.
  ///
  /// In en, this message translates to:
  /// **'A project\'s agent'**
  String get newAgentKindAgent;

  /// No description provided for @newAgentKindAgentText.
  ///
  /// In en, this message translates to:
  /// **'Works in a project under its orchestrator: writes code, reviews, researches, tests.'**
  String get newAgentKindAgentText;

  /// No description provided for @newAgentKindOrch.
  ///
  /// In en, this message translates to:
  /// **'A project\'s orchestrator'**
  String get newAgentKindOrch;

  /// No description provided for @newAgentKindOrchText.
  ///
  /// In en, this message translates to:
  /// **'Leads a project: splits the work and hands it to its agents. One per project.'**
  String get newAgentKindOrchText;

  /// No description provided for @newAgentKindAsst.
  ///
  /// In en, this message translates to:
  /// **'Personal assistant'**
  String get newAgentKindAsst;

  /// No description provided for @newAgentKindAsstText.
  ///
  /// In en, this message translates to:
  /// **'Helps you outside the projects: mail, calendar, research, accounts.'**
  String get newAgentKindAsstText;

  /// No description provided for @newAgentProjectQ.
  ///
  /// In en, this message translates to:
  /// **'In which project?'**
  String get newAgentProjectQ;

  /// No description provided for @newAgentNoOrch.
  ///
  /// In en, this message translates to:
  /// **'It has no orchestrator yet: make one first.'**
  String get newAgentNoOrch;

  /// No description provided for @newAgentHasOrch.
  ///
  /// In en, this message translates to:
  /// **'It already has an orchestrator.'**
  String get newAgentHasOrch;

  /// No description provided for @newAgentNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects: make one from the page.'**
  String get newAgentNoProjects;

  /// No description provided for @newAgentNameQ.
  ///
  /// In en, this message translates to:
  /// **'What is its name and what does it do?'**
  String get newAgentNameQ;

  /// No description provided for @newAgentName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get newAgentName;

  /// No description provided for @newAgentRole.
  ///
  /// In en, this message translates to:
  /// **'Its job, in your own words'**
  String get newAgentRole;

  /// No description provided for @newAgentRoleHint.
  ///
  /// In en, this message translates to:
  /// **'For example: writes the tests and checks they pass'**
  String get newAgentRoleHint;

  /// No description provided for @newAgentMascotPreview.
  ///
  /// In en, this message translates to:
  /// **'Its mascot'**
  String get newAgentMascotPreview;

  /// No description provided for @newAgentMascotLater.
  ///
  /// In en, this message translates to:
  /// **'RedGiant picks the face from the name; once it is made you can change it.'**
  String get newAgentMascotLater;

  /// No description provided for @newAgentModelQ.
  ///
  /// In en, this message translates to:
  /// **'Which model does it use? (optional)'**
  String get newAgentModelQ;

  /// No description provided for @newAgentModelLead.
  ///
  /// In en, this message translates to:
  /// **'By default it uses the one above it.'**
  String get newAgentModelLead;

  /// No description provided for @newAgentModelGod.
  ///
  /// In en, this message translates to:
  /// **'The same as God'**
  String get newAgentModelGod;

  /// No description provided for @newAgentToolsQ.
  ///
  /// In en, this message translates to:
  /// **'Tools to switch off (optional)'**
  String get newAgentToolsQ;

  /// No description provided for @newAgentToolsLead.
  ///
  /// In en, this message translates to:
  /// **'By default it has every tool. The essential ones never switch off.'**
  String get newAgentToolsLead;

  /// No description provided for @newAgentToolsOff.
  ///
  /// In en, this message translates to:
  /// **'{n} off'**
  String newAgentToolsOff(int n);

  /// No description provided for @newAgentReview.
  ///
  /// In en, this message translates to:
  /// **'Here is the new agent'**
  String get newAgentReview;

  /// No description provided for @newAgentBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get newAgentBack;

  /// No description provided for @newAgentNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get newAgentNext;

  /// No description provided for @newAgentCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get newAgentCreate;

  /// No description provided for @newAgentCreating.
  ///
  /// In en, this message translates to:
  /// **'Making it…'**
  String get newAgentCreating;

  /// No description provided for @newAgentFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not make it: {why}'**
  String newAgentFailed(String why);

  /// No description provided for @newAgentMade.
  ///
  /// In en, this message translates to:
  /// **'{name} is in the team.'**
  String newAgentMade(String name);

  /// No description provided for @newAgentOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the conversation with {name}'**
  String newAgentOpen(String name);

  /// No description provided for @newAgentNeedsGod.
  ///
  /// In en, this message translates to:
  /// **'God is needed to make agents: finish the first start first.'**
  String get newAgentNeedsGod;

  /// No description provided for @mascotChange.
  ///
  /// In en, this message translates to:
  /// **'Change mascot'**
  String get mascotChange;

  /// No description provided for @mascotChangeAsk.
  ///
  /// In en, this message translates to:
  /// **'Give {name} a new face? The current one does not come back.'**
  String mascotChangeAsk(String name);

  /// No description provided for @mascotChangeYes.
  ///
  /// In en, this message translates to:
  /// **'New face'**
  String get mascotChangeYes;

  /// No description provided for @mascotChanged.
  ///
  /// In en, this message translates to:
  /// **'A new face for {name}.'**
  String mascotChanged(String name);

  /// No description provided for @reviewKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get reviewKind;

  /// No description provided for @reviewProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get reviewProject;

  /// No description provided for @reviewTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get reviewTools;

  /// No description provided for @reviewAllTools.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reviewAllTools;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
