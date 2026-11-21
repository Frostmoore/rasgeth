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
  /// **'Rasgeth'**
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
  /// **'No Rasgeth connected'**
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
  /// **'Rasgeth'**
  String get sectionServer;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get serverAddress;

  /// No description provided for @serverAddressHint.
  ///
  /// In en, this message translates to:
  /// **'rasgeth.local, https://…, 10.42.0.1'**
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
  /// **'Rasgeth does not answer at this address.'**
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
  /// **'This Rasgeth has no password yet: complete its first start.'**
  String get errNoPassword;

  /// No description provided for @errServerTooOld.
  ///
  /// In en, this message translates to:
  /// **'This Rasgeth is too old for the app: update it.'**
  String get errServerTooOld;

  /// No description provided for @errServerTooNew.
  ///
  /// In en, this message translates to:
  /// **'This app is too old for this Rasgeth: update the app.'**
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
  /// **'(attachments)'**
  String get attachmentOnly;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'The message did not leave: try again.'**
  String get sendFailed;

  /// No description provided for @attachmentTooBig.
  ///
  /// In en, this message translates to:
  /// **'{name} is too big to send (over 25 MB).'**
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
  /// **'Rasgeth\'s own protections'**
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
  /// **'No Rasgeth yet.'**
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
  /// **'Name of this Rasgeth'**
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
  /// **'Disconnect this Rasgeth?'**
  String get forgetServer;

  /// No description provided for @forgetServerBody.
  ///
  /// In en, this message translates to:
  /// **'The app forgets {name} and its device token. To come back, the password again.'**
  String forgetServerBody(String name);

  /// No description provided for @errKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'DANGER: this Rasgeth answered with another key ({fingerprint}). Another computer may be in its place: nothing was sent.'**
  String errKeyChanged(String fingerprint);

  /// No description provided for @errCertificate.
  ///
  /// In en, this message translates to:
  /// **'The certificate is not this Rasgeth\'s: the app did not go on.'**
  String get errCertificate;

  /// No description provided for @errBusy.
  ///
  /// In en, this message translates to:
  /// **'Another device is setting this Rasgeth up: one at a time.'**
  String get errBusy;

  /// No description provided for @errSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again with the password.'**
  String get errSignInAgain;

  /// No description provided for @addServerFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect a Rasgeth'**
  String get addServerFirst;

  /// No description provided for @addServer.
  ///
  /// In en, this message translates to:
  /// **'Add another Rasgeth'**
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
  /// **'Rasgeth\'s whole Settings page, inside the app, signed in with this device.'**
  String get allSettingsHint;

  /// No description provided for @allSettingsBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opens Rasgeth\'s page in the browser: sign in there as usual.'**
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
  /// **'Connect a Rasgeth that runs already'**
  String get connectExisting;

  /// No description provided for @firstStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Rasgeth yet'**
  String get firstStepsTitle;

  /// No description provided for @firstStepsLead.
  ///
  /// In en, this message translates to:
  /// **'Set up a new one from here (Rasgeth OS opens its own Wi-Fi network at the first start), or connect one you already use.'**
  String get firstStepsLead;

  /// No description provided for @setupNew.
  ///
  /// In en, this message translates to:
  /// **'Set up a new Rasgeth'**
  String get setupNew;

  /// No description provided for @setupNewHint.
  ///
  /// In en, this message translates to:
  /// **'A Rasgeth OS machine turned on for the first time: the app joins its temporary network and does the whole first start.'**
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
  /// **'What is done stays done; you can come back here, or finish from the browser, while the temporary network is open (30 minutes from when Rasgeth was turned on).'**
  String get fsLeaveBody;

  /// No description provided for @fsIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up a new Rasgeth'**
  String get fsIntroTitle;

  /// No description provided for @fsIntroLead.
  ///
  /// In en, this message translates to:
  /// **'Turn your Rasgeth on: for 30 minutes it opens the Wi-Fi network Rasgeth-Setup-XXXX. The app joins it, you create the access and choose your home network, then Rasgeth moves there and the app finds it again.'**
  String get fsIntroLead;

  /// No description provided for @fsIntroSafe.
  ///
  /// In en, this message translates to:
  /// **'Everything you type travels encrypted, with Rasgeth\'s own key checked by the app: nobody on the temporary network reads it.'**
  String get fsIntroSafe;

  /// No description provided for @fsSeen.
  ///
  /// In en, this message translates to:
  /// **'Temporary networks around'**
  String get fsSeen;

  /// No description provided for @fsNoScan.
  ///
  /// In en, this message translates to:
  /// **'The system does not show the networks around: type the four characters after Rasgeth-Setup- (you see them in the computer\'s Wi-Fi list).'**
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
  /// **'Choose Rasgeth-Setup in the window the system shows.'**
  String get fsJoiningSheet;

  /// No description provided for @fsConnecting.
  ///
  /// In en, this message translates to:
  /// **'Looking for Rasgeth on the network…'**
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
  /// **'Settings › Network › Wi-Fi: tap Rasgeth-Setup-…'**
  String get fsWhereAndroid;

  /// No description provided for @fsWhereIos.
  ///
  /// In en, this message translates to:
  /// **'Settings › Wi-Fi: tap Rasgeth-Setup-…'**
  String get fsWhereIos;

  /// No description provided for @fsWhereMac.
  ///
  /// In en, this message translates to:
  /// **'The Wi-Fi menu at the top right of the screen: choose Rasgeth-Setup-…'**
  String get fsWhereMac;

  /// No description provided for @fsWhereWindows.
  ///
  /// In en, this message translates to:
  /// **'The Wi-Fi icon at the bottom right: choose Rasgeth-Setup-…'**
  String get fsWhereWindows;

  /// No description provided for @fsWhereOther.
  ///
  /// In en, this message translates to:
  /// **'The system\'s Wi-Fi list: choose Rasgeth-Setup-…'**
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
  /// **'Rasgeth does not answer: are you on the Rasgeth-Setup network? It stays open for 30 minutes after Rasgeth is turned on.'**
  String get fsErrNotFound;

  /// No description provided for @fsErrNotHere.
  ///
  /// In en, this message translates to:
  /// **'This Rasgeth does not let a new access be created from here: finish from its page.'**
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
  /// **'The password that opens Rasgeth from every device. Keep it: it is also what opens its keychain.'**
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
  /// **'It travels encrypted to Rasgeth and stays only there; this device gets its own access, which you can sign out from Settings › Devices.'**
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
  /// **'This Rasgeth has its password already: type it to go on.'**
  String get fsSignInLead;

  /// No description provided for @fsMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth lost its network'**
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
  /// **'Which network should Rasgeth use at home? These are the ones it saw around it.'**
  String get fsHomeLead;

  /// No description provided for @fsHomeNone.
  ///
  /// In en, this message translates to:
  /// **'No network was seen around: use the cable, or type the name of a hidden network.'**
  String get fsHomeNone;

  /// No description provided for @fsHomeUnusable.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth cannot join this kind of network'**
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
  /// **'The Wi-Fi password stays only in Rasgeth.'**
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
  /// **'Rasgeth is joining «{name}»…'**
  String fsHomeWaitWifi(String name);

  /// No description provided for @fsHomeWaitCable.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth moves to the home network…'**
  String get fsHomeWaitCable;

  /// No description provided for @fsHomeWaitSub.
  ///
  /// In en, this message translates to:
  /// **'The device goes back to its own network and finds Rasgeth there (up to two minutes). If it does not work, Rasgeth opens the temporary network again and says why.'**
  String get fsHomeWaitSub;

  /// No description provided for @fsLostTitle.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth is not found'**
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
  /// **'How should Rasgeth think?'**
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
  /// **'I read the provider\'s terms: a subscription is used by me, on my own Rasgeth.'**
  String get fsTerms;

  /// No description provided for @fsBrainLater.
  ///
  /// In en, this message translates to:
  /// **'Models on this machine, your own server and the rest are in Settings › Models and subscriptions, whenever you want.'**
  String get fsBrainLater;

  /// No description provided for @fsNamesTitle.
  ///
  /// In en, this message translates to:
  /// **'The names'**
  String get fsNamesTitle;

  /// No description provided for @fsNamesLead.
  ///
  /// In en, this message translates to:
  /// **'Who runs your Rasgeth, and who speaks for it in the chats. You can change them later.'**
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
  /// **'Rasgeth is ready'**
  String get fsDoneTitle;

  /// No description provided for @fsDoneLead.
  ///
  /// In en, this message translates to:
  /// **'The temporary network is closed: Rasgeth is on your home network, and this device is connected to it.'**
  String get fsDoneLead;

  /// No description provided for @fsDoneMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth is on its new network again, and this device is connected to it.'**
  String get fsDoneMaintenance;

  /// No description provided for @fsDoneMore.
  ///
  /// In en, this message translates to:
  /// **'The rest of the first start (backups, chats, access from outside…) is in the page, whenever you want: «Settings of Rasgeth» › «All settings».'**
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
  /// **'Rasgeth is already joining a network: wait a moment.'**
  String get homeErrBusy;

  /// No description provided for @homeErrWifiOff.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is not running on Rasgeth.'**
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
  /// **'Only from the home network. Tailscale, Cloudflare or a name of your own: in «Access from outside home».'**
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
  /// **'Not on yet for this device: turn them on in You, Notifications.'**
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
  /// **'Update Rasgeth?'**
  String get updNowTitle;

  /// No description provided for @updNowBody.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth downloads {version}, then restarts: for a minute or two it does not answer. You see every step, and the app reconnects by itself as soon as Rasgeth is back.'**
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
  /// **'Waiting for Rasgeth to answer'**
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
  /// **'Interrupted: {name}'**
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
  /// **'Rasgeth picks the face from the name; once it is made you can change it.'**
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

  /// No description provided for @agentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get agentInstructions;

  /// No description provided for @agentInstructionsOf.
  ///
  /// In en, this message translates to:
  /// **'Instructions of {name}'**
  String agentInstructionsOf(String name);

  /// No description provided for @chatInstructions.
  ///
  /// In en, this message translates to:
  /// **'The Chat\'s instructions'**
  String get chatInstructions;

  /// No description provided for @agentInstructionsRow.
  ///
  /// In en, this message translates to:
  /// **'Its system prompt: read and change it'**
  String get agentInstructionsRow;

  /// No description provided for @promptDefault.
  ///
  /// In en, this message translates to:
  /// **'Built-in instructions'**
  String get promptDefault;

  /// No description provided for @promptOwn.
  ///
  /// In en, this message translates to:
  /// **'Your instructions'**
  String get promptOwn;

  /// No description provided for @promptNewChats.
  ///
  /// In en, this message translates to:
  /// **'New instructions apply to new conversations: the open ones keep theirs. The agents\' names stay right if you rename them later.'**
  String get promptNewChats;

  /// No description provided for @promptSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get promptSave;

  /// No description provided for @promptSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get promptSaved;

  /// No description provided for @promptSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not save them: {why}'**
  String promptSaveFailed(String why);

  /// No description provided for @promptReset.
  ///
  /// In en, this message translates to:
  /// **'Restore the built-in ones'**
  String get promptReset;

  /// No description provided for @promptResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Go back to the built-in instructions? Your text will be lost.'**
  String get promptResetConfirm;

  /// No description provided for @promptUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo the changes'**
  String get promptUndo;

  /// No description provided for @refineOpen.
  ///
  /// In en, this message translates to:
  /// **'Improve the instructions'**
  String get refineOpen;

  /// No description provided for @refineLead.
  ///
  /// In en, this message translates to:
  /// **'A model reads them again and proposes a clearer version. You see what changes before using it; nothing is saved until you save.'**
  String get refineLead;

  /// No description provided for @refineWish.
  ///
  /// In en, this message translates to:
  /// **'What do you want to change? (you can leave it empty)'**
  String get refineWish;

  /// No description provided for @refineWishPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: more concise; always answer with lists; specialise it in invoices. Empty: a general improvement.'**
  String get refineWishPlaceholder;

  /// No description provided for @refineEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate: {what}.'**
  String refineEstimate(String what);

  /// No description provided for @refineNoEstimate.
  ///
  /// In en, this message translates to:
  /// **'No estimate: check that the model is still connected.'**
  String get refineNoEstimate;

  /// No description provided for @refineSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent: {what}.'**
  String refineSpent(String what);

  /// No description provided for @refineCostLine.
  ///
  /// In en, this message translates to:
  /// **'about {tokens} tokens, {cost}'**
  String refineCostLine(String tokens, String cost);

  /// No description provided for @refineFree.
  ///
  /// In en, this message translates to:
  /// **'no money (a local model or a subscription)'**
  String get refineFree;

  /// No description provided for @refineCost.
  ///
  /// In en, this message translates to:
  /// **'about {usd}'**
  String refineCost(String usd);

  /// No description provided for @refineCostTiny.
  ///
  /// In en, this message translates to:
  /// **'less than a cent'**
  String get refineCostTiny;

  /// No description provided for @refineGo.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get refineGo;

  /// No description provided for @refineWorking.
  ///
  /// In en, this message translates to:
  /// **'Rewriting the instructions...'**
  String get refineWorking;

  /// No description provided for @refineChanges.
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get refineChanges;

  /// No description provided for @refineUse.
  ///
  /// In en, this message translates to:
  /// **'Use this version'**
  String get refineUse;

  /// No description provided for @refineRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get refineRetry;

  /// No description provided for @refineUsed.
  ///
  /// In en, this message translates to:
  /// **'The new version is in the field: save to keep it.'**
  String get refineUsed;

  /// No description provided for @refineSame.
  ///
  /// In en, this message translates to:
  /// **'The model left them as they were.'**
  String get refineSame;

  /// No description provided for @refineErr_budget.
  ///
  /// In en, this message translates to:
  /// **'The budget is used up: raise it in Settings, Budget.'**
  String get refineErr_budget;

  /// No description provided for @refineErr_no_model.
  ///
  /// In en, this message translates to:
  /// **'No model is connected: connect one in Settings, Models.'**
  String get refineErr_no_model;

  /// No description provided for @refineErr_no_answer.
  ///
  /// In en, this message translates to:
  /// **'The model gave no usable text. Try again or choose another model.'**
  String get refineErr_no_answer;

  /// No description provided for @refineErr_removed_parts.
  ///
  /// In en, this message translates to:
  /// **'The model left out parts that must stay (tools, names). Nothing changed: try again or choose another model.'**
  String get refineErr_removed_parts;

  /// No description provided for @attachmentNotSent.
  ///
  /// In en, this message translates to:
  /// **'not sent'**
  String get attachmentNotSent;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSub.
  ///
  /// In en, this message translates to:
  /// **'How this device hears from Rasgeth when the app is closed'**
  String get notificationsSub;

  /// No description provided for @voiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceTitle;

  /// No description provided for @voiceSub.
  ///
  /// In en, this message translates to:
  /// **'Who reads the answers aloud, and how loud'**
  String get voiceSub;

  /// No description provided for @notifyAllow.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get notifyAllow;

  /// No description provided for @notifyDeny.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get notifyDeny;

  /// No description provided for @notifyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notifyOpen;

  /// No description provided for @notifyChannelRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests for you'**
  String get notifyChannelRequests;

  /// No description provided for @notifyChannelUpdates.
  ///
  /// In en, this message translates to:
  /// **'Messages and tasks'**
  String get notifyChannelUpdates;

  /// No description provided for @notifyAnswerFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The answer did not go'**
  String get notifyAnswerFailedTitle;

  /// No description provided for @notifyAnswerFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Open the app to answer: the request is still waiting.'**
  String get notifyAnswerFailedBody;

  /// No description provided for @notifyAsksPermission.
  ///
  /// In en, this message translates to:
  /// **'{name} asks for permission'**
  String notifyAsksPermission(String name);

  /// No description provided for @notifyAsksYou.
  ///
  /// In en, this message translates to:
  /// **'{name} asks you'**
  String notifyAsksYou(String name);

  /// No description provided for @notifyCriticalTitle.
  ///
  /// In en, this message translates to:
  /// **'A truly dangerous request: open it to decide'**
  String get notifyCriticalTitle;

  /// No description provided for @notifyTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification test'**
  String get notifyTestTitle;

  /// No description provided for @notifyTestBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications from {server} reach this computer.'**
  String notifyTestBody(String server);

  /// No description provided for @notifyTestShown.
  ///
  /// In en, this message translates to:
  /// **'A test notification is on the screen.'**
  String get notifyTestShown;

  /// No description provided for @pushStateHead.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get pushStateHead;

  /// No description provided for @pushOnVia.
  ///
  /// In en, this message translates to:
  /// **'On, through {via}'**
  String pushOnVia(String via);

  /// No description provided for @pushOffHere.
  ///
  /// In en, this message translates to:
  /// **'Off on this device: Rasgeth cannot tell you anything while the app is closed.'**
  String get pushOffHere;

  /// No description provided for @pushWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the distributor\'s address…'**
  String get pushWaiting;

  /// No description provided for @pushWaitingEndpoint.
  ///
  /// In en, this message translates to:
  /// **'{name} is preparing this phone\'s address: it takes a few seconds.'**
  String pushWaitingEndpoint(String name);

  /// No description provided for @pushNowOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on: send a test to see one.'**
  String get pushNowOn;

  /// No description provided for @pushNowOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off on this device.'**
  String get pushNowOff;

  /// No description provided for @pushEndpointNotSent.
  ///
  /// In en, this message translates to:
  /// **'The distributor gave an address, but Rasgeth could not be reached: the app tries again at the next start.'**
  String get pushEndpointNotSent;

  /// No description provided for @pushFailedNetwork.
  ///
  /// In en, this message translates to:
  /// **'The distributor has no network now: try again in a moment.'**
  String get pushFailedNetwork;

  /// No description provided for @pushFailedVapid.
  ///
  /// In en, this message translates to:
  /// **'The distributor wants Rasgeth\'s VAPID key, which is in the keychain: open the keychain on Rasgeth and try again.'**
  String get pushFailedVapid;

  /// No description provided for @pushFailedAction.
  ///
  /// In en, this message translates to:
  /// **'The distributor needs something from you: open it (for example ntfy) and follow what it says.'**
  String get pushFailedAction;

  /// No description provided for @pushFailedOther.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be turned on: try again, or choose another distributor.'**
  String get pushFailedOther;

  /// No description provided for @pushDistributorDropped.
  ///
  /// In en, this message translates to:
  /// **'The distributor stopped this registration: turn notifications on again.'**
  String get pushDistributorDropped;

  /// No description provided for @pushTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on through {name}'**
  String pushTurnOn(String name);

  /// No description provided for @pushTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get pushTurnOff;

  /// No description provided for @pushLastError.
  ///
  /// In en, this message translates to:
  /// **'The last notification did not go: {error}'**
  String pushLastError(String error);

  /// No description provided for @pushDistributorHead.
  ///
  /// In en, this message translates to:
  /// **'Distributor (UnifiedPush)'**
  String get pushDistributorHead;

  /// No description provided for @pushDistributorHint.
  ///
  /// In en, this message translates to:
  /// **'The distributor brings Rasgeth\'s notifications to this phone, encrypted: you choose it (ntfy, your own ntfy, Sunup…), no Google or Rasgeth cloud in between.'**
  String get pushDistributorHint;

  /// No description provided for @pushNoDistributor.
  ///
  /// In en, this message translates to:
  /// **'There is no UnifiedPush distributor on this phone.'**
  String get pushNoDistributor;

  /// No description provided for @pushNoDistributorMeans.
  ///
  /// In en, this message translates to:
  /// **'Without one, Rasgeth cannot reach you while the app is closed: you see requests and answers only by opening the app (or in a linked chat, like Telegram).'**
  String get pushNoDistributorMeans;

  /// No description provided for @pushNoDistributorHow.
  ///
  /// In en, this message translates to:
  /// **'To have them: install ntfy (from F-Droid or the Play Store) or another UnifiedPush distributor, then come back here and press «Look again».'**
  String get pushNoDistributorHow;

  /// No description provided for @pushLookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get pushLookAgain;

  /// No description provided for @pushIosLater.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, notifications come with the published app (Apple\'s push service, prepared and switched off until then).'**
  String get pushIosLater;

  /// No description provided for @pushIosMeanwhile.
  ///
  /// In en, this message translates to:
  /// **'Meanwhile you see requests with the app open, or in a linked chat (Telegram…).'**
  String get pushIosMeanwhile;

  /// No description provided for @pushDesktopWhat.
  ///
  /// In en, this message translates to:
  /// **'While the app is open, even behind other windows, requests and questions show as the system\'s notifications, with Yes and No for ordinary requests.'**
  String get pushDesktopWhat;

  /// No description provided for @pushDesktopOn.
  ///
  /// In en, this message translates to:
  /// **'System notifications on'**
  String get pushDesktopOn;

  /// No description provided for @pushDesktopOff.
  ///
  /// In en, this message translates to:
  /// **'System notifications off'**
  String get pushDesktopOff;

  /// No description provided for @pushDesktopClosed.
  ///
  /// In en, this message translates to:
  /// **'With the app closed this computer gets nothing: Rasgeth\'s page and the linked chats still do.'**
  String get pushDesktopClosed;

  /// No description provided for @pushNotHere.
  ///
  /// In en, this message translates to:
  /// **'This system has no notifications for the app.'**
  String get pushNotHere;

  /// No description provided for @pushAboutHead.
  ///
  /// In en, this message translates to:
  /// **'How they work'**
  String get pushAboutHead;

  /// No description provided for @pushAboutSealed.
  ///
  /// In en, this message translates to:
  /// **'Each notification is encrypted for this device with keys made here: the distributor only carries it.'**
  String get pushAboutSealed;

  /// No description provided for @pushAboutCritical.
  ///
  /// In en, this message translates to:
  /// **'A truly dangerous request never has the quick Yes: the notification opens it in the app, on its own screen.'**
  String get pushAboutCritical;

  /// No description provided for @pushAboutWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'A request answered somewhere else (the page, a chat) disappears from here too.'**
  String get pushAboutWithdrawn;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share to Rasgeth'**
  String get shareTitle;

  /// No description provided for @shareWhat.
  ///
  /// In en, this message translates to:
  /// **'What you are sharing'**
  String get shareWhat;

  /// No description provided for @shareTo.
  ///
  /// In en, this message translates to:
  /// **'To whom'**
  String get shareTo;

  /// No description provided for @shareToChatHint.
  ///
  /// In en, this message translates to:
  /// **'A new conversation'**
  String get shareToChatHint;

  /// No description provided for @shareNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note…'**
  String get shareNoteHint;

  /// No description provided for @voiceReaderHead.
  ///
  /// In en, this message translates to:
  /// **'Who reads the answers'**
  String get voiceReaderHead;

  /// No description provided for @voiceModelHead.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get voiceModelHead;

  /// No description provided for @voiceVoiceHead.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceVoiceHead;

  /// No description provided for @voiceAccountVoice.
  ///
  /// In en, this message translates to:
  /// **'The voice is the one of the account with the key.'**
  String get voiceAccountVoice;

  /// No description provided for @voiceVolumeHead.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get voiceVolumeHead;

  /// No description provided for @voiceVolumeHint.
  ///
  /// In en, this message translates to:
  /// **'Up to the system\'s full volume: the phone\'s own buttons make it louder.'**
  String get voiceVolumeHint;

  /// No description provided for @voiceTry.
  ///
  /// In en, this message translates to:
  /// **'Try the voice'**
  String get voiceTry;

  /// No description provided for @voiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get voiceStop;

  /// No description provided for @voiceReadAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get voiceReadAloud;

  /// No description provided for @voiceTrySentence.
  ///
  /// In en, this message translates to:
  /// **'Hello, this is how I read the answers.'**
  String get voiceTrySentence;

  /// No description provided for @voiceNoReader.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth has no voice to read with yet.'**
  String get voiceNoReader;

  /// No description provided for @voiceNoReaderHow.
  ///
  /// In en, this message translates to:
  /// **'Add a key for OpenAI, ElevenLabs or Google Gemini in Rasgeth\'s Settings, Voice: then choose it here.'**
  String get voiceNoReaderHow;

  /// No description provided for @voiceTalkHead.
  ///
  /// In en, this message translates to:
  /// **'Press and talk'**
  String get voiceTalkHead;

  /// No description provided for @voiceTalkWhat.
  ///
  /// In en, this message translates to:
  /// **'In a conversation, hold the microphone down while you speak: let go and what you said is written in the field, to read before sending.'**
  String get voiceTalkWhat;

  /// No description provided for @voiceTalkWhere.
  ///
  /// In en, this message translates to:
  /// **'It is written down by Rasgeth\'s transcription (Settings, Voice, Transcription), the same as the page\'s.'**
  String get voiceTalkWhere;

  /// No description provided for @voiceHoldToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold down to talk'**
  String get voiceHoldToTalk;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… let go to finish'**
  String get voiceListening;

  /// No description provided for @voiceWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing down what you said…'**
  String get voiceWriting;

  /// No description provided for @voiceTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short: hold the microphone down while you speak.'**
  String get voiceTooShort;

  /// No description provided for @voiceHeardNothing.
  ///
  /// In en, this message translates to:
  /// **'I did not hear any words: try again closer to the phone.'**
  String get voiceHeardNothing;

  /// No description provided for @voiceMicDenied.
  ///
  /// In en, this message translates to:
  /// **'The microphone is not allowed: allow it in the system\'s settings for Rasgeth.'**
  String get voiceMicDenied;

  /// No description provided for @voiceMicFailed.
  ///
  /// In en, this message translates to:
  /// **'The microphone did not start: is another app using it?'**
  String get voiceMicFailed;

  /// No description provided for @voiceErrNoService.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth has no transcription service: choose one in Settings, Voice, Transcription.'**
  String get voiceErrNoService;

  /// No description provided for @voiceErrNoKey.
  ///
  /// In en, this message translates to:
  /// **'{name} has no key yet: add it in Settings, Voice.'**
  String voiceErrNoKey(String name);

  /// No description provided for @voiceErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'The recording is empty.'**
  String get voiceErrEmpty;

  /// No description provided for @voiceErrTooLong.
  ///
  /// In en, this message translates to:
  /// **'The recording is too long.'**
  String get voiceErrTooLong;

  /// No description provided for @voiceErrConvert.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be converted for whisper on Rasgeth\'s computer.'**
  String get voiceErrConvert;

  /// No description provided for @voiceErrTimeout.
  ///
  /// In en, this message translates to:
  /// **'{name} took too long to answer.'**
  String voiceErrTimeout(String name);

  /// No description provided for @voiceErrUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{name} cannot be reached: check that it is on and its address.'**
  String voiceErrUnreachable(String name);

  /// No description provided for @voiceErrKeyRefused.
  ///
  /// In en, this message translates to:
  /// **'{name} refused the key: check it in Settings, Voice.'**
  String voiceErrKeyRefused(String name);

  /// No description provided for @voiceErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'{name} says too many requests or no credit left.'**
  String voiceErrRateLimited(String name);

  /// No description provided for @voiceErrServiceError.
  ///
  /// In en, this message translates to:
  /// **'{name} answered with an error ({status}).'**
  String voiceErrServiceError(String name, String status);

  /// No description provided for @voiceErrProvider.
  ///
  /// In en, this message translates to:
  /// **'This provider cannot do it: choose another one.'**
  String get voiceErrProvider;

  /// No description provided for @voiceErrServer.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth cannot be reached: check the connection.'**
  String get voiceErrServer;

  /// No description provided for @voiceErrOther.
  ///
  /// In en, this message translates to:
  /// **'The voice did not work: try again.'**
  String get voiceErrOther;

  /// No description provided for @notifyTestFailed.
  ///
  /// In en, this message translates to:
  /// **'The system did not show it: are notifications on for Rasgeth in its settings?'**
  String get notifyTestFailed;

  /// No description provided for @tabProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get tabProjects;

  /// No description provided for @sectionCoders.
  ///
  /// In en, this message translates to:
  /// **'For those who code'**
  String get sectionCoders;

  /// No description provided for @sectionMascots.
  ///
  /// In en, this message translates to:
  /// **'Mascots'**
  String get sectionMascots;

  /// No description provided for @advancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced interface'**
  String get advancedTitle;

  /// No description provided for @advancedNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get advancedNew;

  /// No description provided for @advancedHint.
  ///
  /// In en, this message translates to:
  /// **'Adds Projects to the bar and, in every agent\'s sheet, Files, Diff and Terminal.'**
  String get advancedHint;

  /// No description provided for @advancedTerminals.
  ///
  /// In en, this message translates to:
  /// **'My agents\' terminals'**
  String get advancedTerminals;

  /// No description provided for @advancedTerminalsHint.
  ///
  /// In en, this message translates to:
  /// **'Read only; my own terminal has the row of extra keys.'**
  String get advancedTerminalsHint;

  /// No description provided for @codeTabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get codeTabTasks;

  /// No description provided for @codeTabFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get codeTabFiles;

  /// No description provided for @codeTabDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get codeTabDiff;

  /// No description provided for @codeTabTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get codeTabTerminal;

  /// No description provided for @codeTabLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get codeTabLog;

  /// No description provided for @codeTabGit.
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get codeTabGit;

  /// No description provided for @codeArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived project: read only until you restore it.'**
  String get codeArchived;

  /// No description provided for @codeArchivedShort.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get codeArchivedShort;

  /// No description provided for @codeChangedMeanwhile.
  ///
  /// In en, this message translates to:
  /// **'The file changed since you opened it: open it again.'**
  String get codeChangedMeanwhile;

  /// No description provided for @codeUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth cannot be reached: check the connection.'**
  String get codeUnreachable;

  /// No description provided for @codeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'It did not load: pull down to try again.'**
  String get codeLoadFailed;

  /// No description provided for @codeNoRepo.
  ///
  /// In en, this message translates to:
  /// **'no repository'**
  String get codeNoRepo;

  /// No description provided for @codeDetached.
  ///
  /// In en, this message translates to:
  /// **'no branch'**
  String get codeDetached;

  /// No description provided for @codeClean.
  ///
  /// In en, this message translates to:
  /// **'clean'**
  String get codeClean;

  /// No description provided for @codeChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change} other{{count} changes}}'**
  String codeChanges(int count);

  /// No description provided for @codeAheadBehind.
  ///
  /// In en, this message translates to:
  /// **'{ahead} ahead, {behind} behind'**
  String codeAheadBehind(int ahead, int behind);

  /// No description provided for @codeNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet.'**
  String get codeNoProjects;

  /// No description provided for @codeOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task in progress} other{{count} tasks in progress}}'**
  String codeOpenTasks(int count);

  /// No description provided for @codeNoOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'no task in progress'**
  String get codeNoOpenTasks;

  /// No description provided for @codeNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this project.'**
  String get codeNoTasks;

  /// No description provided for @codeColRunning.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get codeColRunning;

  /// No description provided for @codeColToVerify.
  ///
  /// In en, this message translates to:
  /// **'To verify'**
  String get codeColToVerify;

  /// No description provided for @codeColDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get codeColDone;

  /// No description provided for @codeTaskVerified.
  ///
  /// In en, this message translates to:
  /// **'verified · exit 0'**
  String get codeTaskVerified;

  /// No description provided for @codeTaskNotTestable.
  ///
  /// In en, this message translates to:
  /// **'«not testable»: {why}'**
  String codeTaskNotTestable(String why);

  /// No description provided for @codeTaskAbandoned.
  ///
  /// In en, this message translates to:
  /// **'given up: {why}'**
  String codeTaskAbandoned(String why);

  /// No description provided for @codeTaskNoVerifier.
  ///
  /// In en, this message translates to:
  /// **'verifier not run yet'**
  String get codeTaskNoVerifier;

  /// No description provided for @codeTaskVerifier.
  ///
  /// In en, this message translates to:
  /// **'verifier: {command} · {result}'**
  String codeTaskVerifier(String command, String result);

  /// No description provided for @codeTaskPassed.
  ///
  /// In en, this message translates to:
  /// **'passed'**
  String get codeTaskPassed;

  /// No description provided for @codeTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'not passed'**
  String get codeTaskFailed;

  /// No description provided for @codeTaskDiff.
  ///
  /// In en, this message translates to:
  /// **'The task\'s diff'**
  String get codeTaskDiff;

  /// No description provided for @codeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search names and text'**
  String get codeSearchHint;

  /// No description provided for @codeNoHits.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get codeNoHits;

  /// No description provided for @codeEmptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Empty folder.'**
  String get codeEmptyFolder;

  /// No description provided for @codePickFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file on the left.'**
  String get codePickFile;

  /// No description provided for @codeSmallEdit.
  ///
  /// In en, this message translates to:
  /// **'Small edit'**
  String get codeSmallEdit;

  /// No description provided for @codeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get codeSave;

  /// No description provided for @codeSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get codeSaving;

  /// No description provided for @codeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get codeSaved;

  /// No description provided for @codeAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask…'**
  String get codeAsk;

  /// No description provided for @codeAskWho.
  ///
  /// In en, this message translates to:
  /// **'Ask which agent?'**
  String get codeAskWho;

  /// No description provided for @codeAskDraft.
  ///
  /// In en, this message translates to:
  /// **'About the file `{path}`: '**
  String codeAskDraft(String path);

  /// No description provided for @codeSeeDiff.
  ///
  /// In en, this message translates to:
  /// **'See the diff'**
  String get codeSeeDiff;

  /// No description provided for @codeCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy the path'**
  String get codeCopyPath;

  /// No description provided for @codePathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied.'**
  String get codePathCopied;

  /// No description provided for @codeNotText.
  ///
  /// In en, this message translates to:
  /// **'Not a text file: open it from the page.'**
  String get codeNotText;

  /// No description provided for @codeModifiedAt.
  ///
  /// In en, this message translates to:
  /// **'changed {when}'**
  String codeModifiedAt(String when);

  /// No description provided for @codeDiffWorking.
  ///
  /// In en, this message translates to:
  /// **'Uncommitted changes'**
  String get codeDiffWorking;

  /// No description provided for @codeDiffTask.
  ///
  /// In en, this message translates to:
  /// **'Task «{title}»'**
  String codeDiffTask(String title);

  /// No description provided for @codeDiffCommit.
  ///
  /// In en, this message translates to:
  /// **'Commit {hash} {subject}'**
  String codeDiffCommit(String hash, String subject);

  /// No description provided for @codeDiffAgent.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s work'**
  String codeDiffAgent(String name);

  /// No description provided for @codeDiffWhich.
  ///
  /// In en, this message translates to:
  /// **'Which diff?'**
  String get codeDiffWhich;

  /// No description provided for @codeDiffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No differences.'**
  String get codeDiffEmpty;

  /// No description provided for @codeDiffTruncated.
  ///
  /// In en, this message translates to:
  /// **'Too long: only the first part is shown.'**
  String get codeDiffTruncated;

  /// No description provided for @codeDiffBinary.
  ///
  /// In en, this message translates to:
  /// **'A binary file: nothing to read here.'**
  String get codeDiffBinary;

  /// No description provided for @codeDiffNoHunks.
  ///
  /// In en, this message translates to:
  /// **'Renamed or mode changed only.'**
  String get codeDiffNoHunks;

  /// No description provided for @codeFileOf.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String codeFileOf(int n, int total);

  /// No description provided for @codePrevFile.
  ///
  /// In en, this message translates to:
  /// **'Previous file'**
  String get codePrevFile;

  /// No description provided for @codeNextFile.
  ///
  /// In en, this message translates to:
  /// **'Next file'**
  String get codeNextFile;

  /// No description provided for @codeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get codeKeep;

  /// No description provided for @codeKept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get codeKept;

  /// No description provided for @codeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get codeDiscard;

  /// No description provided for @codeDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded'**
  String get codeDiscarded;

  /// No description provided for @codeDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this change?'**
  String get codeDiscardTitle;

  /// No description provided for @codeDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The change to {path} is removed from the files. A copy stays in the project\'s trash (.trash/diffs) to put back.'**
  String codeDiscardBody(String path);

  /// No description provided for @codeDiscardCommitBody.
  ///
  /// In en, this message translates to:
  /// **'This change of the commit is undone in {path} (as a new uncommitted change). A copy stays in the project\'s trash (.trash/diffs).'**
  String codeDiscardCommitBody(String path);

  /// No description provided for @codeComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get codeComment;

  /// No description provided for @codeCommentHint.
  ///
  /// In en, this message translates to:
  /// **'A note for {name}'**
  String codeCommentHint(String name);

  /// No description provided for @codeCommentIntro.
  ///
  /// In en, this message translates to:
  /// **'A comment on `{path}`, at {hunk}:'**
  String codeCommentIntro(String path, String hunk);

  /// No description provided for @codeCommentSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}.'**
  String codeCommentSent(String name);

  /// No description provided for @codeCommentFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent: try again.'**
  String get codeCommentFailed;

  /// No description provided for @codeNoChat.
  ///
  /// In en, this message translates to:
  /// **'No conversation with this agent yet.'**
  String get codeNoChat;

  /// No description provided for @codeTermMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get codeTermMine;

  /// No description provided for @codeTextSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get codeTextSmaller;

  /// No description provided for @codeTextBigger.
  ///
  /// In en, this message translates to:
  /// **'Bigger text'**
  String get codeTextBigger;

  /// No description provided for @codeTermReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only: the commands the agent ran and what they printed.'**
  String get codeTermReadOnly;

  /// No description provided for @codeTermNoCommands.
  ///
  /// In en, this message translates to:
  /// **'No commands yet.'**
  String get codeTermNoCommands;

  /// No description provided for @codeReload.
  ///
  /// In en, this message translates to:
  /// **'Load again'**
  String get codeReload;

  /// No description provided for @codeTermIntro.
  ///
  /// In en, this message translates to:
  /// **'A shell in the project\'s sandbox, like the page\'s terminal.'**
  String get codeTermIntro;

  /// No description provided for @codeTermOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the terminal'**
  String get codeTermOpen;

  /// No description provided for @codeTermHint.
  ///
  /// In en, this message translates to:
  /// **'A command'**
  String get codeTermHint;

  /// No description provided for @codeTermClosed.
  ///
  /// In en, this message translates to:
  /// **'The terminal closed.'**
  String get codeTermClosed;

  /// No description provided for @codeLogAgent.
  ///
  /// In en, this message translates to:
  /// **'Which agent?'**
  String get codeLogAgent;

  /// No description provided for @codeLogAllAgents.
  ///
  /// In en, this message translates to:
  /// **'Every agent'**
  String get codeLogAllAgents;

  /// No description provided for @codeLogType.
  ///
  /// In en, this message translates to:
  /// **'Which type?'**
  String get codeLogType;

  /// No description provided for @codeLogAllTypes.
  ///
  /// In en, this message translates to:
  /// **'Every type'**
  String get codeLogAllTypes;

  /// No description provided for @codeLogErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors only'**
  String get codeLogErrors;

  /// No description provided for @codeLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the log.'**
  String get codeLogEmpty;

  /// No description provided for @codeLogOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open the conversation'**
  String get codeLogOpenChat;

  /// No description provided for @codeBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get codeBranches;

  /// No description provided for @codeCommits.
  ///
  /// In en, this message translates to:
  /// **'Commits'**
  String get codeCommits;

  /// No description provided for @codeUpstream.
  ///
  /// In en, this message translates to:
  /// **'follows {name}'**
  String codeUpstream(String name);

  /// No description provided for @codeNoUpstream.
  ///
  /// In en, this message translates to:
  /// **'not sent anywhere yet'**
  String get codeNoUpstream;

  /// No description provided for @codeCommitHint.
  ///
  /// In en, this message translates to:
  /// **'What changed (the commit\'s message)'**
  String get codeCommitHint;

  /// No description provided for @codeCommit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get codeCommit;

  /// No description provided for @codeCommitted.
  ///
  /// In en, this message translates to:
  /// **'Commit {hash} made.'**
  String codeCommitted(String hash);

  /// No description provided for @codeNothingToCommit.
  ///
  /// In en, this message translates to:
  /// **'Nothing to commit.'**
  String get codeNothingToCommit;

  /// No description provided for @codePush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get codePush;

  /// No description provided for @codePushAsked.
  ///
  /// In en, this message translates to:
  /// **'Push asked: answer it from «For you» (it is a request to you, like an agent\'s).'**
  String get codePushAsked;

  /// No description provided for @codePushDone.
  ///
  /// In en, this message translates to:
  /// **'Pushed.'**
  String get codePushDone;

  /// No description provided for @codePushDenied.
  ///
  /// In en, this message translates to:
  /// **'Not pushed: the answer was no.'**
  String get codePushDenied;

  /// No description provided for @codePushFailed.
  ///
  /// In en, this message translates to:
  /// **'The push did not work: {error}'**
  String codePushFailed(String error);

  /// No description provided for @codeNoRemote.
  ///
  /// In en, this message translates to:
  /// **'The project has no remote repository to push to.'**
  String get codeNoRemote;

  /// No description provided for @savedSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savedSave;

  /// No description provided for @savedSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this passage'**
  String get savedSaveTitle;

  /// No description provided for @savedSaveMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this message'**
  String get savedSaveMessageTitle;

  /// No description provided for @savedNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get savedNote;

  /// No description provided for @savedNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Why you keep it, what to do with it…'**
  String get savedNotePlaceholder;

  /// No description provided for @savedTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get savedTags;

  /// No description provided for @savedTagsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'New tags, separated by commas'**
  String get savedTagsPlaceholder;

  /// No description provided for @savedDone.
  ///
  /// In en, this message translates to:
  /// **'Saved: it is in your saved items, with the conversation it comes from.'**
  String get savedDone;

  /// No description provided for @savedOpenArchive.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get savedOpenArchive;

  /// No description provided for @savedFailed.
  ///
  /// In en, this message translates to:
  /// **'Not saved: {error}'**
  String savedFailed(String error);

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @savedHint.
  ///
  /// In en, this message translates to:
  /// **'Passages and messages you kept from your conversations: only you see them. Select a part of an answer and pick «Save», or use «Save» in a message\'s menu.'**
  String get savedHint;

  /// No description provided for @savedSearch.
  ///
  /// In en, this message translates to:
  /// **'Search in the saved items'**
  String get savedSearch;

  /// No description provided for @savedAllTags.
  ///
  /// In en, this message translates to:
  /// **'All tags'**
  String get savedAllTags;

  /// No description provided for @savedAllAgents.
  ///
  /// In en, this message translates to:
  /// **'All agents'**
  String get savedAllAgents;

  /// No description provided for @savedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet.'**
  String get savedEmpty;

  /// No description provided for @savedNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved matches.'**
  String get savedNoMatch;

  /// No description provided for @savedMore.
  ///
  /// In en, this message translates to:
  /// **'Show older'**
  String get savedMore;

  /// No description provided for @savedWhole.
  ///
  /// In en, this message translates to:
  /// **'Whole message'**
  String get savedWhole;

  /// No description provided for @savedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved {when}'**
  String savedOn(String when);

  /// No description provided for @savedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open in the conversation'**
  String get savedOpen;

  /// No description provided for @savedEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note and tags'**
  String get savedEdit;

  /// No description provided for @savedDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get savedDelete;

  /// No description provided for @savedDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this saved item?'**
  String get savedDeleteTitle;

  /// No description provided for @savedDeleteText.
  ///
  /// In en, this message translates to:
  /// **'The passage leaves your saved items; the conversation stays as it is.'**
  String get savedDeleteText;

  /// No description provided for @savedUnknownOrigin.
  ///
  /// In en, this message translates to:
  /// **'A conversation'**
  String get savedUnknownOrigin;

  /// No description provided for @savedFromDailyChat.
  ///
  /// In en, this message translates to:
  /// **'It comes from the daily chat of the page: open it there.'**
  String get savedFromDailyChat;

  /// No description provided for @savedNotThere.
  ///
  /// In en, this message translates to:
  /// **'The message is not in the conversation any more.'**
  String get savedNotThere;

  /// No description provided for @savedExport.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get savedExport;

  /// No description provided for @savedExportFile.
  ///
  /// In en, this message translates to:
  /// **'Save the file'**
  String get savedExportFile;

  /// No description provided for @savedExportCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy the Markdown'**
  String get savedExportCopy;

  /// No description provided for @savedExportSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved.'**
  String get savedExportSaved;

  /// No description provided for @savedExportCopied.
  ///
  /// In en, this message translates to:
  /// **'Markdown copied: paste it where you like.'**
  String get savedExportCopied;

  /// No description provided for @savedExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String savedExportFailed(String error);

  /// No description provided for @savedFileName.
  ///
  /// In en, this message translates to:
  /// **'saved.md'**
  String get savedFileName;

  /// No description provided for @quoteReply.
  ///
  /// In en, this message translates to:
  /// **'Reply to this'**
  String get quoteReply;

  /// No description provided for @quoteReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'You are replying to this passage'**
  String get quoteReplyingTo;

  /// No description provided for @quoteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this passage'**
  String get quoteRemove;

  /// No description provided for @quoteJump.
  ///
  /// In en, this message translates to:
  /// **'Go to the passage in the conversation'**
  String get quoteJump;

  /// No description provided for @quoteTooMany.
  ///
  /// In en, this message translates to:
  /// **'At most {n} passages in one message.'**
  String quoteTooMany(int n);

  /// No description provided for @messageMenu.
  ///
  /// In en, this message translates to:
  /// **'Message options'**
  String get messageMenu;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get messageCopied;

  /// No description provided for @messageSaveHint.
  ///
  /// In en, this message translates to:
  /// **'Keep this whole message in your saved items'**
  String get messageSaveHint;

  /// No description provided for @productOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get productOpen;

  /// No description provided for @productSource.
  ///
  /// In en, this message translates to:
  /// **'Source {n} of the answer'**
  String productSource(int n);

  /// No description provided for @productNoPicture.
  ///
  /// In en, this message translates to:
  /// **'No picture'**
  String get productNoPicture;

  /// No description provided for @productPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous products'**
  String get productPrevious;

  /// No description provided for @productNext.
  ///
  /// In en, this message translates to:
  /// **'Next products'**
  String get productNext;

  /// No description provided for @quoteReplyShort.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get quoteReplyShort;

  /// No description provided for @savedSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the search'**
  String get savedSearchClear;

  /// No description provided for @metricsInput.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get metricsInput;

  /// No description provided for @metricsCache.
  ///
  /// In en, this message translates to:
  /// **'cache'**
  String get metricsCache;

  /// No description provided for @metricsOutput.
  ///
  /// In en, this message translates to:
  /// **'out'**
  String get metricsOutput;

  /// No description provided for @metricsContext.
  ///
  /// In en, this message translates to:
  /// **'context'**
  String get metricsContext;

  /// No description provided for @metricsPrefill.
  ///
  /// In en, this message translates to:
  /// **'prefill'**
  String get metricsPrefill;

  /// No description provided for @metricsGeneration.
  ///
  /// In en, this message translates to:
  /// **'generation'**
  String get metricsGeneration;

  /// No description provided for @metricsTimedByClient.
  ///
  /// In en, this message translates to:
  /// **'timed by the client'**
  String get metricsTimedByClient;

  /// No description provided for @metricsServerTimings.
  ///
  /// In en, this message translates to:
  /// **'server timings'**
  String get metricsServerTimings;

  /// No description provided for @metricsStart.
  ///
  /// In en, this message translates to:
  /// **'start'**
  String get metricsStart;

  /// No description provided for @metricsFirstToken.
  ///
  /// In en, this message translates to:
  /// **'first token'**
  String get metricsFirstToken;

  /// No description provided for @metricsEnd.
  ///
  /// In en, this message translates to:
  /// **'end'**
  String get metricsEnd;

  /// No description provided for @metricsRestoredFromDisk.
  ///
  /// In en, this message translates to:
  /// **'KV cache restored from the SSD before this request'**
  String get metricsRestoredFromDisk;

  /// No description provided for @metricsCostUnknown.
  ///
  /// In en, this message translates to:
  /// **'cost not known'**
  String get metricsCostUnknown;

  /// No description provided for @metricsCostUnknownHint.
  ///
  /// In en, this message translates to:
  /// **'This model is not in the models catalog yet: its prices are not known, so its cost is not counted.'**
  String get metricsCostUnknownHint;

  /// No description provided for @metricsShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all the message\'s figures'**
  String get metricsShowAll;

  /// No description provided for @updNowBodyLocal.
  ///
  /// In en, this message translates to:
  /// **'On this computer Rasgeth does the update to {version} in its own window: it downloads, closes and starts again as the new version. Here you see the steps it reports.'**
  String updNowBodyLocal(String version);

  /// No description provided for @updFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow the update'**
  String get updFollow;

  /// No description provided for @upd2Title.
  ///
  /// In en, this message translates to:
  /// **'Updating Rasgeth from {from} to {to}'**
  String upd2Title(String from, String to);

  /// No description provided for @upd2TitleTo.
  ///
  /// In en, this message translates to:
  /// **'Updating Rasgeth to {to}'**
  String upd2TitleTo(String to);

  /// No description provided for @upd2Starting.
  ///
  /// In en, this message translates to:
  /// **'Starting the update…'**
  String get upd2Starting;

  /// No description provided for @upd2Left.
  ///
  /// In en, this message translates to:
  /// **'about {time} left'**
  String upd2Left(String time);

  /// No description provided for @upd2Total.
  ///
  /// In en, this message translates to:
  /// **'about {time} in all'**
  String upd2Total(String time);

  /// No description provided for @upd2LeftUnknown.
  ///
  /// In en, this message translates to:
  /// **'working out how long it takes…'**
  String get upd2LeftUnknown;

  /// No description provided for @upd2Elapsed.
  ///
  /// In en, this message translates to:
  /// **'running for {time}'**
  String upd2Elapsed(String time);

  /// No description provided for @upd2ToDownload.
  ///
  /// In en, this message translates to:
  /// **'{size} to download'**
  String upd2ToDownload(String size);

  /// No description provided for @upd2Steps.
  ///
  /// In en, this message translates to:
  /// **'The update\'s steps'**
  String get upd2Steps;

  /// No description provided for @upd2Restarting.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth is restarting, reconnecting…'**
  String get upd2Restarting;

  /// No description provided for @upd2Attempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {n} · no answer for {time}'**
  String upd2Attempt(String n, String time);

  /// No description provided for @upd2Back.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth answers: checking it is the new version…'**
  String get upd2Back;

  /// No description provided for @upd2Keeps.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth keeps working while it downloads: it stops only for the restart, a minute or two.'**
  String get upd2Keeps;

  /// No description provided for @upd2ComesBack.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open: it reconnects by itself as soon as Rasgeth answers as the new version.'**
  String get upd2ComesBack;

  /// No description provided for @upd2Local.
  ///
  /// In en, this message translates to:
  /// **'On this computer Rasgeth does the update in its own window, with the bar and the time: here you see the steps it reports, and if this window stays open it reconnects by itself when Rasgeth is back.'**
  String get upd2Local;

  /// No description provided for @upd2Older.
  ///
  /// In en, this message translates to:
  /// **'This Rasgeth does not report each step\'s details yet (they come with 3.8.1): you see where it is and for how long.'**
  String get upd2Older;

  /// No description provided for @upd2Done.
  ///
  /// In en, this message translates to:
  /// **'Updated to {version}'**
  String upd2Done(String version);

  /// No description provided for @upd2DoneText.
  ///
  /// In en, this message translates to:
  /// **'From {from}, in {time}. Conversations, agents and settings are as before.'**
  String upd2DoneText(String from, String time);

  /// No description provided for @upd2DoneFrom.
  ///
  /// In en, this message translates to:
  /// **'From {from}. Conversations, agents and settings are as before.'**
  String upd2DoneFrom(String from);

  /// No description provided for @upd2Reconnected.
  ///
  /// In en, this message translates to:
  /// **'The app reconnected by itself.'**
  String get upd2Reconnected;

  /// No description provided for @upd2Reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to the new version…'**
  String get upd2Reconnecting;

  /// No description provided for @upd2News.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in {version}'**
  String upd2News(String version);

  /// No description provided for @upd2Notes.
  ///
  /// In en, this message translates to:
  /// **'The version\'s notes on GitHub'**
  String get upd2Notes;

  /// No description provided for @upd2BackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Rasgeth'**
  String get upd2BackHome;

  /// No description provided for @upd2Hide.
  ///
  /// In en, this message translates to:
  /// **'Hide: the update goes on'**
  String get upd2Hide;

  /// No description provided for @upd2Retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get upd2Retry;

  /// No description provided for @upd2Close.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get upd2Close;

  /// No description provided for @upd2TookLess.
  ///
  /// In en, this message translates to:
  /// **'less than a minute'**
  String get upd2TookLess;

  /// No description provided for @upd2TookMin.
  ///
  /// In en, this message translates to:
  /// **'{min} min'**
  String upd2TookMin(String min);

  /// No description provided for @upd2TookHours.
  ///
  /// In en, this message translates to:
  /// **'{h} h {min} min'**
  String upd2TookHours(String h, String min);

  /// No description provided for @upd2ImgHere.
  ///
  /// In en, this message translates to:
  /// **'already here'**
  String get upd2ImgHere;

  /// No description provided for @upd2ImgDone.
  ///
  /// In en, this message translates to:
  /// **'downloaded'**
  String get upd2ImgDone;

  /// No description provided for @upd2ImgDatabase.
  ///
  /// In en, this message translates to:
  /// **'The database (Postgres)'**
  String get upd2ImgDatabase;

  /// No description provided for @upd2StepDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get upd2StepDone;

  /// No description provided for @upd2StepNow.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get upd2StepNow;

  /// No description provided for @upd2StepTodo.
  ///
  /// In en, this message translates to:
  /// **'to do'**
  String get upd2StepTodo;

  /// No description provided for @upd2StepFailed.
  ///
  /// In en, this message translates to:
  /// **'stopped here'**
  String get upd2StepFailed;

  /// No description provided for @upd2Step_check.
  ///
  /// In en, this message translates to:
  /// **'Check the new version\'s signature'**
  String get upd2Step_check;

  /// No description provided for @upd2Step_download.
  ///
  /// In en, this message translates to:
  /// **'Download the new version'**
  String get upd2Step_download;

  /// No description provided for @upd2Step_files.
  ///
  /// In en, this message translates to:
  /// **'Download the system\'s files'**
  String get upd2Step_files;

  /// No description provided for @upd2Step_install.
  ///
  /// In en, this message translates to:
  /// **'Install the system\'s files'**
  String get upd2Step_install;

  /// No description provided for @upd2Step_restart.
  ///
  /// In en, this message translates to:
  /// **'Restart Rasgeth as the new version'**
  String get upd2Step_restart;

  /// No description provided for @upd2Step_wait.
  ///
  /// In en, this message translates to:
  /// **'Check that Rasgeth answers'**
  String get upd2Step_wait;

  /// No description provided for @upd2Step_rollback.
  ///
  /// In en, this message translates to:
  /// **'Put the previous version back'**
  String get upd2Step_rollback;

  /// No description provided for @upd2Step_scan.
  ///
  /// In en, this message translates to:
  /// **'Compare the installed files'**
  String get upd2Step_scan;

  /// No description provided for @upd2Step_build.
  ///
  /// In en, this message translates to:
  /// **'Put the new version together'**
  String get upd2Step_build;

  /// No description provided for @upd2Step_installer.
  ///
  /// In en, this message translates to:
  /// **'Download the installer'**
  String get upd2Step_installer;

  /// No description provided for @upd2StepText_check.
  ///
  /// In en, this message translates to:
  /// **'Only a version signed by Rasgeth is installed.'**
  String get upd2StepText_check;

  /// No description provided for @upd2StepText_download.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth keeps working while it downloads.'**
  String get upd2StepText_download;

  /// No description provided for @upd2StepText_files.
  ///
  /// In en, this message translates to:
  /// **'The programs of the system around Rasgeth.'**
  String get upd2StepText_files;

  /// No description provided for @upd2StepText_install.
  ///
  /// In en, this message translates to:
  /// **'A copy of every file replaced is kept: if something goes wrong, it goes back as it was.'**
  String get upd2StepText_install;

  /// No description provided for @upd2StepText_restart.
  ///
  /// In en, this message translates to:
  /// **'For a minute or two Rasgeth does not answer: the app reconnects by itself.'**
  String get upd2StepText_restart;

  /// No description provided for @upd2StepText_wait.
  ///
  /// In en, this message translates to:
  /// **'If the new version does not answer within ten minutes, the previous one comes back by itself.'**
  String get upd2StepText_wait;

  /// No description provided for @upd2StepText_rollback.
  ///
  /// In en, this message translates to:
  /// **'The new version did not start: the previous one is coming back, nothing is lost.'**
  String get upd2StepText_rollback;

  /// No description provided for @upd2StepText_scan.
  ///
  /// In en, this message translates to:
  /// **'So only what changed is downloaded.'**
  String get upd2StepText_scan;

  /// No description provided for @upd2StepText_build.
  ///
  /// In en, this message translates to:
  /// **'The new version is prepared beside the current one.'**
  String get upd2StepText_build;

  /// No description provided for @upd2StepText_installer.
  ///
  /// In en, this message translates to:
  /// **'The whole program: it installs over the current one.'**
  String get upd2StepText_installer;

  /// No description provided for @upd2Why_download.
  ///
  /// In en, this message translates to:
  /// **'The new version could not be downloaded.'**
  String get upd2Why_download;

  /// No description provided for @upd2WhyText_download.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: Rasgeth {from} keeps working. Check that the machine reaches the internet, then press «Try again»: what came down already is not downloaded twice.'**
  String upd2WhyText_download(String from);

  /// No description provided for @upd2Why_files.
  ///
  /// In en, this message translates to:
  /// **'The system\'s new files could not be installed.'**
  String get upd2Why_files;

  /// No description provided for @upd2WhyText_files.
  ///
  /// In en, this message translates to:
  /// **'Every file went back as it was and Rasgeth {from} keeps working. Try again in a while; if it happens again, download the diagnostics from the page (Settings › General › Diagnostics) and send them.'**
  String upd2WhyText_files(String from);

  /// No description provided for @upd2Why_not_up.
  ///
  /// In en, this message translates to:
  /// **'The new version did not start.'**
  String get upd2Why_not_up;

  /// No description provided for @upd2WhyText_not_up.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth went back to {from} by itself: nothing is lost. Try again in a while; if it happens again, download the diagnostics from the page (Settings › General › Diagnostics) and send them.'**
  String upd2WhyText_not_up(String from);

  /// No description provided for @upd2Why_no_images.
  ///
  /// In en, this message translates to:
  /// **'This version has nothing for this machine\'s processor.'**
  String get upd2Why_no_images;

  /// No description provided for @upd2WhyText_no_images.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: Rasgeth {from} keeps working. Wait for the next version.'**
  String upd2WhyText_no_images(String from);

  /// No description provided for @upd2Why_breaking.
  ///
  /// In en, this message translates to:
  /// **'This version cannot be installed over the current one.'**
  String get upd2Why_breaking;

  /// No description provided for @upd2WhyText_breaking.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: Rasgeth {from} keeps working. Open Rasgeth\'s page from the computer: it guides you through the clean install.'**
  String upd2WhyText_breaking(String from);

  /// No description provided for @upd2Why_unsigned.
  ///
  /// In en, this message translates to:
  /// **'The new version is not signed.'**
  String get upd2Why_unsigned;

  /// No description provided for @upd2WhyText_unsigned.
  ///
  /// In en, this message translates to:
  /// **'For safety it was not installed: nothing changed. Look again later.'**
  String get upd2WhyText_unsigned;

  /// No description provided for @upd2Why_unreachable.
  ///
  /// In en, this message translates to:
  /// **'GitHub did not answer.'**
  String get upd2Why_unreachable;

  /// No description provided for @upd2WhyText_unreachable.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed. Check that the machine reaches the internet and press «Try again».'**
  String get upd2WhyText_unreachable;

  /// No description provided for @upd2Why_other.
  ///
  /// In en, this message translates to:
  /// **'The update did not finish.'**
  String get upd2Why_other;

  /// No description provided for @upd2WhyText_other.
  ///
  /// In en, this message translates to:
  /// **'The previous version ({from}) is running: nothing is lost. Try again in a while.'**
  String upd2WhyText_other(String from);

  /// No description provided for @upd2Why_gone.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth does not answer any more.'**
  String get upd2Why_gone;

  /// No description provided for @upd2WhyText_gone.
  ///
  /// In en, this message translates to:
  /// **'It did not come back after the restart. Check that the machine is on and in the network, then press «Try again»: the app looks for it again.'**
  String get upd2WhyText_gone;

  /// No description provided for @upd2Why_start.
  ///
  /// In en, this message translates to:
  /// **'The update did not start.'**
  String get upd2Why_start;

  /// No description provided for @upd2WhyText_start.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: Rasgeth {from} keeps working. Try again in a while.'**
  String upd2WhyText_start(String from);

  /// No description provided for @upd2WhySaid.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth said: {error}'**
  String upd2WhySaid(String error);

  /// No description provided for @upd2ScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth\'s update'**
  String get upd2ScreenTitle;

  /// No description provided for @deskAbout.
  ///
  /// In en, this message translates to:
  /// **'About Rasgeth'**
  String get deskAbout;

  /// No description provided for @deskAdvancedOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off the advanced interface'**
  String get deskAdvancedOff;

  /// No description provided for @deskAdvancedOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on the advanced interface'**
  String get deskAdvancedOn;

  /// No description provided for @deskAdvancedShort.
  ///
  /// In en, this message translates to:
  /// **'advanced'**
  String get deskAdvancedShort;

  /// No description provided for @deskAgeDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d'**
  String deskAgeDays(int n);

  /// No description provided for @deskAgeHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String deskAgeHours(int n);

  /// No description provided for @deskAgeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String deskAgeMinutes(int n);

  /// No description provided for @deskAgeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get deskAgeNow;

  /// No description provided for @deskAgeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get deskAgeYesterday;

  /// No description provided for @deskAgentAsks.
  ///
  /// In en, this message translates to:
  /// **'{name} asks: {what}'**
  String deskAgentAsks(String name, String what);

  /// No description provided for @deskAgentsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 agent} other{{n} agents}}'**
  String deskAgentsCount(int n);

  /// No description provided for @deskAgentsHead.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get deskAgentsHead;

  /// No description provided for @deskAgentsTerminals.
  ///
  /// In en, this message translates to:
  /// **'Agents\''**
  String get deskAgentsTerminals;

  /// No description provided for @deskAllProjects.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get deskAllProjects;

  /// No description provided for @deskAllProjectsLower.
  ///
  /// In en, this message translates to:
  /// **'all projects'**
  String get deskAllProjectsLower;

  /// No description provided for @deskAskChat.
  ///
  /// In en, this message translates to:
  /// **'Ask the Chat'**
  String get deskAskChat;

  /// No description provided for @deskAskGod.
  ///
  /// In en, this message translates to:
  /// **'Ask God'**
  String get deskAskGod;

  /// No description provided for @deskAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask {name} without opening the conversation…'**
  String deskAskHint(String name);

  /// No description provided for @deskAskInConversation.
  ///
  /// In en, this message translates to:
  /// **'Ask in its conversation'**
  String get deskAskInConversation;

  /// No description provided for @deskAskTag.
  ///
  /// In en, this message translates to:
  /// **'To {name}'**
  String deskAskTag(String name);

  /// No description provided for @deskAsked.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}'**
  String deskAsked(String name);

  /// No description provided for @deskAsks.
  ///
  /// In en, this message translates to:
  /// **'Asks: {what}'**
  String deskAsks(String what);

  /// No description provided for @deskByProject.
  ///
  /// In en, this message translates to:
  /// **'By project'**
  String get deskByProject;

  /// No description provided for @deskByState.
  ///
  /// In en, this message translates to:
  /// **'By state'**
  String get deskByState;

  /// No description provided for @deskChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get deskChanges;

  /// No description provided for @deskChatHint.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything…'**
  String get deskChatHint;

  /// No description provided for @deskChatSub.
  ///
  /// In en, this message translates to:
  /// **'for every day'**
  String get deskChatSub;

  /// No description provided for @deskChosenCommit.
  ///
  /// In en, this message translates to:
  /// **'Chosen commit'**
  String get deskChosenCommit;

  /// No description provided for @deskClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get deskClose;

  /// No description provided for @deskCloseFloating.
  ///
  /// In en, this message translates to:
  /// **'Close the floating panels'**
  String get deskCloseFloating;

  /// No description provided for @deskColAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get deskColAgent;

  /// No description provided for @deskColDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get deskColDuration;

  /// No description provided for @deskColSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get deskColSummary;

  /// No description provided for @deskColTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get deskColTime;

  /// No description provided for @deskColType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get deskColType;

  /// No description provided for @deskCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get deskCopy;

  /// No description provided for @deskCopyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get deskCopyJson;

  /// No description provided for @deskCriticalCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 critical} other{{n} critical}}'**
  String deskCriticalCount(int n);

  /// No description provided for @deskCriticalTitle.
  ///
  /// In en, this message translates to:
  /// **'Critical request'**
  String get deskCriticalTitle;

  /// No description provided for @deskCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get deskCut;

  /// No description provided for @deskDiffWord.
  ///
  /// In en, this message translates to:
  /// **'diff'**
  String get deskDiffWord;

  /// No description provided for @deskDockAll.
  ///
  /// In en, this message translates to:
  /// **'Put the floating panels back'**
  String get deskDockAll;

  /// No description provided for @deskDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop to attach'**
  String get deskDropHere;

  /// No description provided for @deskEventN.
  ///
  /// In en, this message translates to:
  /// **'Event {n}'**
  String deskEventN(int n);

  /// No description provided for @deskEventStream.
  ///
  /// In en, this message translates to:
  /// **'Stream of events'**
  String get deskEventStream;

  /// No description provided for @deskFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get deskFiles;

  /// No description provided for @deskFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 file} other{{n} files}}'**
  String deskFilesCount(int n);

  /// No description provided for @deskFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deskFilterAll;

  /// No description provided for @deskFilterBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get deskFilterBlocked;

  /// No description provided for @deskFilterWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get deskFilterWaiting;

  /// No description provided for @deskFilterWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get deskFilterWorking;

  /// No description provided for @deskFindAgent.
  ///
  /// In en, this message translates to:
  /// **'Find an agent…'**
  String get deskFindAgent;

  /// No description provided for @deskFloatingCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 floating panel} other{{n} floating panels}}'**
  String deskFloatingCount(int n);

  /// No description provided for @deskForYouCount.
  ///
  /// In en, this message translates to:
  /// **'{n} for you'**
  String deskForYouCount(int n);

  /// No description provided for @deskForYouPush.
  ///
  /// In en, this message translates to:
  /// **'For you: a push'**
  String get deskForYouPush;

  /// No description provided for @deskForYouShort.
  ///
  /// In en, this message translates to:
  /// **'for you'**
  String get deskForYouShort;

  /// No description provided for @deskFrozen.
  ///
  /// In en, this message translates to:
  /// **'paused'**
  String get deskFrozen;

  /// No description provided for @deskGitCommit.
  ///
  /// In en, this message translates to:
  /// **'Make a commit…'**
  String get deskGitCommit;

  /// No description provided for @deskGitCommitTitle.
  ///
  /// In en, this message translates to:
  /// **'Commit everything in the working tree'**
  String get deskGitCommitTitle;

  /// No description provided for @deskGitHistory.
  ///
  /// In en, this message translates to:
  /// **'Show the history'**
  String get deskGitHistory;

  /// No description provided for @deskGitPush.
  ///
  /// In en, this message translates to:
  /// **'Send…'**
  String get deskGitPush;

  /// No description provided for @deskGoToFile.
  ///
  /// In en, this message translates to:
  /// **'Go to file…'**
  String get deskGoToFile;

  /// No description provided for @deskGodHint.
  ///
  /// In en, this message translates to:
  /// **'Ask God to organise something…'**
  String get deskGodHint;

  /// No description provided for @deskGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get deskGrid;

  /// No description provided for @deskHintAsk.
  ///
  /// In en, this message translates to:
  /// **'ask now'**
  String get deskHintAsk;

  /// No description provided for @deskHintChoose.
  ///
  /// In en, this message translates to:
  /// **'choose'**
  String get deskHintChoose;

  /// No description provided for @deskHintFloat.
  ///
  /// In en, this message translates to:
  /// **'in a floating panel'**
  String get deskHintFloat;

  /// No description provided for @deskHintOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get deskHintOpen;

  /// No description provided for @deskHintPrefixes.
  ///
  /// In en, this message translates to:
  /// **'type @ for agents, / for commands'**
  String get deskHintPrefixes;

  /// No description provided for @deskHintPrefixesAdvanced.
  ///
  /// In en, this message translates to:
  /// **'no prefix searches everything'**
  String get deskHintPrefixesAdvanced;

  /// No description provided for @deskInContainer.
  ///
  /// In en, this message translates to:
  /// **'in the project\'s container'**
  String get deskInContainer;

  /// No description provided for @deskInConversation.
  ///
  /// In en, this message translates to:
  /// **'In the conversation'**
  String get deskInConversation;

  /// No description provided for @deskInline.
  ///
  /// In en, this message translates to:
  /// **'Inline'**
  String get deskInline;

  /// No description provided for @deskKeyDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get deskKeyDown;

  /// No description provided for @deskKeyEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get deskKeyEnter;

  /// No description provided for @deskKeyEsc.
  ///
  /// In en, this message translates to:
  /// **'Esc'**
  String get deskKeyEsc;

  /// No description provided for @deskKeyOption.
  ///
  /// In en, this message translates to:
  /// **'Opt'**
  String get deskKeyOption;

  /// No description provided for @deskKeyShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get deskKeyShift;

  /// No description provided for @deskKeySpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get deskKeySpace;

  /// No description provided for @deskKeyTab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get deskKeyTab;

  /// No description provided for @deskKeyUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get deskKeyUp;

  /// No description provided for @deskLayoutAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get deskLayoutAlways;

  /// No description provided for @deskLayoutFrom.
  ///
  /// In en, this message translates to:
  /// **'From {n} px'**
  String deskLayoutFrom(int n);

  /// No description provided for @deskLayoutHint.
  ///
  /// In en, this message translates to:
  /// **'The control room when the window is at least this wide; narrower, the phone\'s screens.'**
  String get deskLayoutHint;

  /// No description provided for @deskLayoutNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get deskLayoutNever;

  /// No description provided for @deskLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Computer\'s layout'**
  String get deskLayoutTitle;

  /// No description provided for @deskList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get deskList;

  /// No description provided for @deskLive.
  ///
  /// In en, this message translates to:
  /// **'live'**
  String get deskLive;

  /// No description provided for @deskLogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'agente:\"Coder Web\" tipo:tool.* text'**
  String get deskLogSearchHint;

  /// No description provided for @deskMenuAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get deskMenuAgents;

  /// No description provided for @deskMenuConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get deskMenuConversation;

  /// No description provided for @deskMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get deskMenuEdit;

  /// No description provided for @deskMenuFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get deskMenuFile;

  /// No description provided for @deskMenuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get deskMenuHelp;

  /// No description provided for @deskMenuView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get deskMenuView;

  /// No description provided for @deskMenuWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get deskMenuWindow;

  /// No description provided for @deskNewAgentNamed.
  ///
  /// In en, this message translates to:
  /// **'New agent «{name}»…'**
  String deskNewAgentNamed(String name);

  /// No description provided for @deskNewConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation with the open agent'**
  String get deskNewConversation;

  /// No description provided for @deskNewTerminal.
  ///
  /// In en, this message translates to:
  /// **'New terminal'**
  String get deskNewTerminal;

  /// No description provided for @deskNoActions.
  ///
  /// In en, this message translates to:
  /// **'No recent actions'**
  String get deskNoActions;

  /// No description provided for @deskNoAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents'**
  String get deskNoAgents;

  /// No description provided for @deskNoChanges.
  ///
  /// In en, this message translates to:
  /// **'none, everything is committed'**
  String get deskNoChanges;

  /// No description provided for @deskNoGit.
  ///
  /// In en, this message translates to:
  /// **'no repository: files only'**
  String get deskNoGit;

  /// No description provided for @deskNoGitShort.
  ///
  /// In en, this message translates to:
  /// **'no git'**
  String get deskNoGitShort;

  /// No description provided for @deskNoKeysHere.
  ///
  /// In en, this message translates to:
  /// **'No keys here: credentials stay on the egress routes'**
  String get deskNoKeysHere;

  /// No description provided for @deskNoProject.
  ///
  /// In en, this message translates to:
  /// **'Without a project'**
  String get deskNoProject;

  /// No description provided for @deskNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get deskNoProjects;

  /// No description provided for @deskNoTask.
  ///
  /// In en, this message translates to:
  /// **'no open task'**
  String get deskNoTask;

  /// No description provided for @deskNoTerminals.
  ///
  /// In en, this message translates to:
  /// **'Choose a terminal on the left'**
  String get deskNoTerminals;

  /// No description provided for @deskNoneHere.
  ///
  /// In en, this message translates to:
  /// **'No agent in this filter'**
  String get deskNoneHere;

  /// No description provided for @deskNothingForYou.
  ///
  /// In en, this message translates to:
  /// **'nothing to answer'**
  String get deskNothingForYou;

  /// No description provided for @deskOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String deskOfTotal(int n, int total);

  /// No description provided for @deskOnly.
  ///
  /// In en, this message translates to:
  /// **'Only'**
  String get deskOnly;

  /// No description provided for @deskOnlyErrors.
  ///
  /// In en, this message translates to:
  /// **'errors and failures'**
  String get deskOnlyErrors;

  /// No description provided for @deskOnlyRequests.
  ///
  /// In en, this message translates to:
  /// **'requests to you'**
  String get deskOnlyRequests;

  /// No description provided for @deskOpenDetail.
  ///
  /// In en, this message translates to:
  /// **'Open the detail'**
  String get deskOpenDetail;

  /// No description provided for @deskOpenInPanel.
  ///
  /// In en, this message translates to:
  /// **'Open in the side panel'**
  String get deskOpenInPanel;

  /// No description provided for @deskOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get deskOpenTasks;

  /// No description provided for @deskPaletteAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get deskPaletteAgents;

  /// No description provided for @deskPaletteAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer: {what}'**
  String deskPaletteAnswer(String what);

  /// No description provided for @deskPaletteCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get deskPaletteCommands;

  /// No description provided for @deskPaletteConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get deskPaletteConversations;

  /// No description provided for @deskPaletteEvents.
  ///
  /// In en, this message translates to:
  /// **'Log events'**
  String get deskPaletteEvents;

  /// No description provided for @deskPaletteFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get deskPaletteFiles;

  /// No description provided for @deskPaletteHint.
  ///
  /// In en, this message translates to:
  /// **'Agents, conversations, commands, files…'**
  String get deskPaletteHint;

  /// No description provided for @deskPaletteLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get deskPaletteLines;

  /// No description provided for @deskPaletteNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get deskPaletteNothing;

  /// No description provided for @deskPaletteOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open {path}'**
  String deskPaletteOpenFile(String path);

  /// No description provided for @deskPaletteRequests.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get deskPaletteRequests;

  /// No description provided for @deskPaletteTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get deskPaletteTerminal;

  /// No description provided for @deskPaletteTitle.
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get deskPaletteTitle;

  /// No description provided for @deskPanelClose.
  ///
  /// In en, this message translates to:
  /// **'Close the panel'**
  String get deskPanelClose;

  /// No description provided for @deskPanelDetach.
  ///
  /// In en, this message translates to:
  /// **'Take out of the panel'**
  String get deskPanelDetach;

  /// No description provided for @deskPanelDock.
  ///
  /// In en, this message translates to:
  /// **'Back into the side panel'**
  String get deskPanelDock;

  /// No description provided for @deskPanelResize.
  ///
  /// In en, this message translates to:
  /// **'Panel width'**
  String get deskPanelResize;

  /// No description provided for @deskPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get deskPaste;

  /// No description provided for @deskPickEvent.
  ///
  /// In en, this message translates to:
  /// **'Choose an event to see it whole'**
  String get deskPickEvent;

  /// No description provided for @deskProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get deskProject;

  /// No description provided for @deskProjectWorking.
  ///
  /// In en, this message translates to:
  /// **'{name} {state} · {n} working'**
  String deskProjectWorking(String name, String state, int n);

  /// No description provided for @deskPushAsked.
  ///
  /// In en, this message translates to:
  /// **'Asked in «For you»: the push goes once you say yes'**
  String get deskPushAsked;

  /// No description provided for @deskQuickChat.
  ///
  /// In en, this message translates to:
  /// **'Quick Chat'**
  String get deskQuickChat;

  /// No description provided for @deskQuickChatExpand.
  ///
  /// In en, this message translates to:
  /// **'Open in the side panel'**
  String get deskQuickChatExpand;

  /// No description provided for @deskQuickChatHint.
  ///
  /// In en, this message translates to:
  /// **'{keys} calls it inside the app'**
  String deskQuickChatHint(String keys);

  /// No description provided for @deskReadOnly.
  ///
  /// In en, this message translates to:
  /// **'read only'**
  String get deskReadOnly;

  /// No description provided for @deskRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get deskRedo;

  /// No description provided for @deskRemotes.
  ///
  /// In en, this message translates to:
  /// **'Remotes'**
  String get deskRemotes;

  /// No description provided for @deskRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 request} other{{n} requests}}'**
  String deskRequestsCount(int n);

  /// No description provided for @deskRunInTerminal.
  ///
  /// In en, this message translates to:
  /// **'Run «{cmd}» in your terminal of {project}'**
  String deskRunInTerminal(String cmd, String project);

  /// No description provided for @deskRunInTerminalDetail.
  ///
  /// In en, this message translates to:
  /// **'In a terminal of yours, in the project\'s container. Your commands ask no permission: it is you.'**
  String get deskRunInTerminalDetail;

  /// No description provided for @deskSameTurn.
  ///
  /// In en, this message translates to:
  /// **'In the same turn'**
  String get deskSameTurn;

  /// No description provided for @deskSearchCommits.
  ///
  /// In en, this message translates to:
  /// **'Search the commits'**
  String get deskSearchCommits;

  /// No description provided for @deskSearchEvents.
  ///
  /// In en, this message translates to:
  /// **'Events with «{q}» in the Log'**
  String deskSearchEvents(String q);

  /// No description provided for @deskSearchShort.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get deskSearchShort;

  /// No description provided for @deskSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get deskSelectAll;

  /// No description provided for @deskSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get deskSettings;

  /// No description provided for @deskShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get deskShortcuts;

  /// No description provided for @deskSideBySide.
  ///
  /// In en, this message translates to:
  /// **'Side by side'**
  String get deskSideBySide;

  /// No description provided for @deskStatusPalette.
  ///
  /// In en, this message translates to:
  /// **'{keys} palette'**
  String deskStatusPalette(String keys);

  /// No description provided for @deskStill.
  ///
  /// In en, this message translates to:
  /// **'Still'**
  String get deskStill;

  /// No description provided for @deskStopAgent.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}'**
  String deskStopAgent(String name);

  /// No description provided for @deskStopOpen.
  ///
  /// In en, this message translates to:
  /// **'Stop the open agent'**
  String get deskStopOpen;

  /// No description provided for @deskStreamHint.
  ///
  /// In en, this message translates to:
  /// **'Paused under the pointer · a click opens the Log'**
  String get deskStreamHint;

  /// No description provided for @deskSubagents.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 subagent} other{{n} subagents}}'**
  String deskSubagents(int n);

  /// No description provided for @deskTabs.
  ///
  /// In en, this message translates to:
  /// **'Tabs'**
  String get deskTabs;

  /// No description provided for @deskTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get deskTags;

  /// No description provided for @deskTaskChanges.
  ///
  /// In en, this message translates to:
  /// **'The task\'s changes'**
  String get deskTaskChanges;

  /// No description provided for @deskTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'failing'**
  String get deskTaskFailed;

  /// No description provided for @deskTaskPassed.
  ///
  /// In en, this message translates to:
  /// **'passing'**
  String get deskTaskPassed;

  /// No description provided for @deskTaskRunning.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get deskTaskRunning;

  /// No description provided for @deskTasksRule.
  ///
  /// In en, this message translates to:
  /// **'they close only with a verifier that exits 0'**
  String get deskTasksRule;

  /// No description provided for @deskTermAskHint.
  ///
  /// In en, this message translates to:
  /// **'To ask it something write in its conversation'**
  String get deskTermAskHint;

  /// No description provided for @deskTerminalsShown.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 terminal} other{{n} terminals}}'**
  String deskTerminalsShown(int n);

  /// No description provided for @deskTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme: {name}'**
  String deskTheme(String name);

  /// No description provided for @deskTiles.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get deskTiles;

  /// No description provided for @deskToSend.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{nothing to send} =1{1 commit to send} other{{n} commits to send}}'**
  String deskToSend(int n);

  /// No description provided for @deskTogglePanel.
  ///
  /// In en, this message translates to:
  /// **'Side panel'**
  String get deskTogglePanel;

  /// No description provided for @deskTypeHead.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get deskTypeHead;

  /// No description provided for @deskUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get deskUndo;

  /// No description provided for @deskVerifier.
  ///
  /// In en, this message translates to:
  /// **'Verifier'**
  String get deskVerifier;

  /// No description provided for @deskViewCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get deskViewCode;

  /// No description provided for @deskViewTerminals.
  ///
  /// In en, this message translates to:
  /// **'Terminals'**
  String get deskViewTerminals;

  /// No description provided for @deskWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get deskWhen;

  /// No description provided for @deskWhenAll.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get deskWhenAll;

  /// No description provided for @deskWhenHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get deskWhenHour;

  /// No description provided for @deskWhenToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get deskWhenToday;

  /// No description provided for @deskWhenWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get deskWhenWeek;

  /// No description provided for @deskWithChanges.
  ///
  /// In en, this message translates to:
  /// **'With changes'**
  String get deskWithChanges;

  /// No description provided for @deskWorkingCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 agent working} other{{n} agents working}}'**
  String deskWorkingCount(int n);

  /// No description provided for @deskYouWrite.
  ///
  /// In en, this message translates to:
  /// **'you can write'**
  String get deskYouWrite;

  /// No description provided for @deskYourTerminal.
  ///
  /// In en, this message translates to:
  /// **'Your terminal'**
  String get deskYourTerminal;

  /// No description provided for @deskYourTerminals.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get deskYourTerminals;

  /// No description provided for @deskNewProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get deskNewProject;

  /// No description provided for @deskProjectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get deskProjectName;

  /// No description provided for @deskProjectCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get deskProjectCreate;

  /// No description provided for @deskProjectMade.
  ///
  /// In en, this message translates to:
  /// **'Project «{name}» created, with its orchestrator.'**
  String deskProjectMade(String name);

  /// No description provided for @deskProjectFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not make the project: {why}'**
  String deskProjectFailed(String why);

  /// No description provided for @deskProjectNoGit.
  ///
  /// In en, this message translates to:
  /// **'Project «{name}» created, but without a git repository: {why}. Create it from Settings › Projects («Initialise git») once git works.'**
  String deskProjectNoGit(String name, String why);

  /// No description provided for @deskGitMissing.
  ///
  /// In en, this message translates to:
  /// **'git is not installed on this computer yet'**
  String get deskGitMissing;

  /// No description provided for @limitsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get limitsTotal;

  /// No description provided for @limitsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get limitsSpent;

  /// No description provided for @limitsContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get limitsContext;

  /// No description provided for @limitsWeekShort.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get limitsWeekShort;

  /// No description provided for @deskSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send the message (in the conversations\' fields)'**
  String get deskSendMessage;

  /// No description provided for @deskFullWindow.
  ///
  /// In en, this message translates to:
  /// **'Full window'**
  String get deskFullWindow;

  /// No description provided for @deskFullWindowOff.
  ///
  /// In en, this message translates to:
  /// **'Back to the panel'**
  String get deskFullWindowOff;

  /// No description provided for @deskBackToRoom.
  ///
  /// In en, this message translates to:
  /// **'Back to the room'**
  String get deskBackToRoom;

  /// No description provided for @deskRailLabel.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get deskRailLabel;

  /// No description provided for @deskRailWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 request for you} other{{count} requests for you}}'**
  String deskRailWaiting(int count);

  /// No description provided for @tpReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the context'**
  String get tpReading;

  /// No description provided for @tpTokens.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tokens'**
  String tpTokens(String done, String total);

  /// No description provided for @tpRate.
  ///
  /// In en, this message translates to:
  /// **'{n} tokens/s'**
  String tpRate(String n);

  /// No description provided for @tpCache.
  ///
  /// In en, this message translates to:
  /// **'{pct} from the cache'**
  String tpCache(String pct);

  /// No description provided for @tpWaitingFirst.
  ///
  /// In en, this message translates to:
  /// **'The provider does not say how far it is: waiting for the first token'**
  String get tpWaitingFirst;

  /// No description provided for @tpThinking.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get tpThinking;

  /// No description provided for @tpWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get tpWriting;

  /// No description provided for @tpWritten.
  ///
  /// In en, this message translates to:
  /// **'about {n} tokens'**
  String tpWritten(String n);

  /// No description provided for @tpGenRate.
  ///
  /// In en, this message translates to:
  /// **'about {n} tokens/s'**
  String tpGenRate(String n);

  /// No description provided for @tpReadIn.
  ///
  /// In en, this message translates to:
  /// **'context of {total} read in {time}, {pct} from the cache'**
  String tpReadIn(String total, String time, String pct);

  /// No description provided for @tpFirstAfter.
  ///
  /// In en, this message translates to:
  /// **'first token after {time}'**
  String tpFirstAfter(String time);

  /// No description provided for @compactingNow.
  ///
  /// In en, this message translates to:
  /// **'Summarising the conversation…'**
  String get compactingNow;

  /// No description provided for @asOpen.
  ///
  /// In en, this message translates to:
  /// **'Agent settings…'**
  String get asOpen;

  /// No description provided for @asTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings of {name}'**
  String asTitle(String name);

  /// No description provided for @asClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get asClose;

  /// No description provided for @asGroupGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get asGroupGeneral;

  /// No description provided for @asGroupWork.
  ///
  /// In en, this message translates to:
  /// **'Model and way'**
  String get asGroupWork;

  /// No description provided for @asGroupMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get asGroupMemory;

  /// No description provided for @asGroupLimits.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get asGroupLimits;

  /// No description provided for @asGroupTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get asGroupTools;

  /// No description provided for @asGroupKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get asGroupKnowledge;

  /// No description provided for @asKind_god.
  ///
  /// In en, this message translates to:
  /// **'God, leads everything'**
  String get asKind_god;

  /// No description provided for @asKind_demigod.
  ///
  /// In en, this message translates to:
  /// **'Demi-God, the Telegram messenger'**
  String get asKind_demigod;

  /// No description provided for @asKind_orchestrator.
  ///
  /// In en, this message translates to:
  /// **'Project lead'**
  String get asKind_orchestrator;

  /// No description provided for @asKind_agent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get asKind_agent;

  /// No description provided for @asKind_subagent.
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get asKind_subagent;

  /// No description provided for @asKind_inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector, reads only'**
  String get asKind_inspector;

  /// No description provided for @asKind_assistant.
  ///
  /// In en, this message translates to:
  /// **'Personal assistant'**
  String get asKind_assistant;

  /// No description provided for @asKindChat.
  ///
  /// In en, this message translates to:
  /// **'The everyday Chat'**
  String get asKindChat;

  /// No description provided for @asStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get asStopped;

  /// No description provided for @asMascot.
  ///
  /// In en, this message translates to:
  /// **'Mascot'**
  String get asMascot;

  /// No description provided for @asMascotHelp.
  ///
  /// In en, this message translates to:
  /// **'Renaming it never changes its face: only you change it, here.'**
  String get asMascotHelp;

  /// No description provided for @asMascotGod.
  ///
  /// In en, this message translates to:
  /// **'God\'s mascot is drawn by hand: the crowned giant star, with three little stars going round it.'**
  String get asMascotGod;

  /// No description provided for @asName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get asName;

  /// No description provided for @asRole.
  ///
  /// In en, this message translates to:
  /// **'What it does'**
  String get asRole;

  /// No description provided for @asRoleHelp.
  ///
  /// In en, this message translates to:
  /// **'One or two lines: God and the orchestrators read it to decide what to hand over.'**
  String get asRoleHelp;

  /// No description provided for @asProjects.
  ///
  /// In en, this message translates to:
  /// **'Also works for'**
  String get asProjects;

  /// No description provided for @asProjectsHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose the projects {name} also works for: there it sits under the project\'s orchestrator, which gives it tasks.'**
  String asProjectsHelp(String name);

  /// No description provided for @asSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get asSaved;

  /// No description provided for @asSavedNew.
  ///
  /// In en, this message translates to:
  /// **'Saved: it applies from new conversations.'**
  String get asSavedNew;

  /// No description provided for @asRefused.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept it: {why}'**
  String asRefused(String why);

  /// No description provided for @asNoName.
  ///
  /// In en, this message translates to:
  /// **'A name is needed.'**
  String get asNoName;

  /// No description provided for @asModelHelp.
  ///
  /// In en, this message translates to:
  /// **'Without a model of its own it uses the one of the agent above it. It applies from new conversations: you change an open conversation\'s model from its composer.'**
  String get asModelHelp;

  /// No description provided for @asModelGodHelp.
  ///
  /// In en, this message translates to:
  /// **'The model God uses; without one, the default model chosen in the setup. You change an open conversation\'s model from its composer.'**
  String get asModelGodHelp;

  /// No description provided for @asModelChatHelp.
  ///
  /// In en, this message translates to:
  /// **'The Chat\'s model, as in its header on the page. You change an open conversation\'s model from its composer.'**
  String get asModelChatHelp;

  /// No description provided for @asMode.
  ///
  /// In en, this message translates to:
  /// **'How freely it works'**
  String get asMode;

  /// No description provided for @asModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Whatever sends, publishes, deletes or pays always waits for you.'**
  String get asModeHelp;

  /// No description provided for @asMode_auto.
  ///
  /// In en, this message translates to:
  /// **'On its own'**
  String get asMode_auto;

  /// No description provided for @asMode_manual.
  ///
  /// In en, this message translates to:
  /// **'Asks permission'**
  String get asMode_manual;

  /// No description provided for @asMode_plan.
  ///
  /// In en, this message translates to:
  /// **'Plan first'**
  String get asMode_plan;

  /// No description provided for @asMode_readonly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get asMode_readonly;

  /// No description provided for @asModeExplain_auto.
  ///
  /// In en, this message translates to:
  /// **'Works on its own and asks only for what is dangerous.'**
  String get asModeExplain_auto;

  /// No description provided for @asModeExplain_manual.
  ///
  /// In en, this message translates to:
  /// **'Asks you before every change to files or commands.'**
  String get asModeExplain_manual;

  /// No description provided for @asModeExplain_plan.
  ///
  /// In en, this message translates to:
  /// **'Writes a plan first and starts once you approve it.'**
  String get asModeExplain_plan;

  /// No description provided for @asModeExplain_readonly.
  ///
  /// In en, this message translates to:
  /// **'Reads and answers, changes nothing.'**
  String get asModeExplain_readonly;

  /// No description provided for @asInstructionsHelp.
  ///
  /// In en, this message translates to:
  /// **'Its system prompt, its own or the built-in one: open conversations keep theirs.'**
  String get asInstructionsHelp;

  /// No description provided for @asMemOwn.
  ///
  /// In en, this message translates to:
  /// **'Memory of {name}: only for this agent'**
  String asMemOwn(String name);

  /// No description provided for @asMemOwnHelp.
  ///
  /// In en, this message translates to:
  /// **'Only {name} reads it, at the start of every conversation. {name} can also note here what it needs.'**
  String asMemOwnHelp(String name);

  /// No description provided for @asMemProject.
  ///
  /// In en, this message translates to:
  /// **'Memory of the project «{name}»'**
  String asMemProject(String name);

  /// No description provided for @asMemProjectHelp.
  ///
  /// In en, this message translates to:
  /// **'Every agent working on this project reads it.'**
  String get asMemProjectHelp;

  /// No description provided for @asMemNone.
  ///
  /// In en, this message translates to:
  /// **'This agent keeps no memory of its own.'**
  String get asMemNone;

  /// No description provided for @asCompact.
  ///
  /// In en, this message translates to:
  /// **'Summaries of long conversations'**
  String get asCompact;

  /// No description provided for @asCompactHelp.
  ///
  /// In en, this message translates to:
  /// **'When the conversation gets long, the agent writes a summary of the old parts, like someone taking notes. Here you choose when it does it, and how much of the latest part it keeps as it is.'**
  String get asCompactHelp;

  /// No description provided for @asCompactAt.
  ///
  /// In en, this message translates to:
  /// **'When to write the summary'**
  String get asCompactAt;

  /// No description provided for @asCompactAtValue.
  ///
  /// In en, this message translates to:
  /// **'when {n}% full'**
  String asCompactAtValue(String n);

  /// No description provided for @asCompactKeep.
  ///
  /// In en, this message translates to:
  /// **'How much of the latest part to keep as it is'**
  String get asCompactKeep;

  /// No description provided for @asCompactKeepValue.
  ///
  /// In en, this message translates to:
  /// **'the last {n}%'**
  String asCompactKeepValue(String n);

  /// No description provided for @asCompactKeepNone.
  ///
  /// In en, this message translates to:
  /// **'nothing'**
  String get asCompactKeepNone;

  /// No description provided for @asCompactDefaultIs.
  ///
  /// In en, this message translates to:
  /// **'Default for this agent\'s model: at {at}%, keeping {keep}%.'**
  String asCompactDefaultIs(String at, String keep);

  /// No description provided for @asCompactDefaults.
  ///
  /// In en, this message translates to:
  /// **'Back to the defaults'**
  String get asCompactDefaults;

  /// No description provided for @asLimitsHelp.
  ///
  /// In en, this message translates to:
  /// **'When it reaches the limit it stops and asks you. The limit counts everything spent since it was set.'**
  String get asLimitsHelp;

  /// No description provided for @asSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent so far'**
  String get asSpent;

  /// No description provided for @asLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit in dollars'**
  String get asLimit;

  /// No description provided for @asNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get asNoLimit;

  /// No description provided for @asLimitTokens.
  ///
  /// In en, this message translates to:
  /// **'Limit: {n} tokens'**
  String asLimitTokens(String n);

  /// No description provided for @asRemoveLimit.
  ///
  /// In en, this message translates to:
  /// **'Remove the limit'**
  String get asRemoveLimit;

  /// No description provided for @asLimitBad.
  ///
  /// In en, this message translates to:
  /// **'Write an amount above zero.'**
  String get asLimitBad;

  /// No description provided for @asToolsHelp.
  ///
  /// In en, this message translates to:
  /// **'For each tool: as for every agent (Settings, Tools), always on for this agent, or off. The essential ones never switch off.'**
  String get asToolsHelp;

  /// No description provided for @asToolsNewOnly.
  ///
  /// In en, this message translates to:
  /// **'Changes apply from new conversations: the ones already open keep their tools.'**
  String get asToolsNewOnly;

  /// No description provided for @asToolsTotal.
  ///
  /// In en, this message translates to:
  /// **'{name}: about {n} tokens in every message'**
  String asToolsTotal(String name, String n);

  /// No description provided for @asToolDefaultOn.
  ///
  /// In en, this message translates to:
  /// **'As for everyone (on)'**
  String get asToolDefaultOn;

  /// No description provided for @asToolDefaultOff.
  ///
  /// In en, this message translates to:
  /// **'As for everyone (off)'**
  String get asToolDefaultOff;

  /// No description provided for @asToolAlways.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get asToolAlways;

  /// No description provided for @asToolOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get asToolOff;

  /// No description provided for @asToolLocked.
  ///
  /// In en, this message translates to:
  /// **'Essential: always on'**
  String get asToolLocked;

  /// No description provided for @asEditRule.
  ///
  /// In en, this message translates to:
  /// **'Edits in open files'**
  String get asEditRule;

  /// No description provided for @asEditRuleHelp.
  ///
  /// In en, this message translates to:
  /// **'When it edits a file open in the Canvas: right away (highlighted, undoable) or as proposals you accept. A file\'s own choice wins.'**
  String get asEditRuleHelp;

  /// No description provided for @asEditNow.
  ///
  /// In en, this message translates to:
  /// **'Right away'**
  String get asEditNow;

  /// No description provided for @asEditPropose.
  ///
  /// In en, this message translates to:
  /// **'As proposals'**
  String get asEditPropose;

  /// No description provided for @asKbHelp.
  ///
  /// In en, this message translates to:
  /// **'Which collections {name} can search. Each one says who may read it; here you can make an exception for this agent. It applies from its next conversation.'**
  String asKbHelp(String name);

  /// No description provided for @asKbNone.
  ///
  /// In en, this message translates to:
  /// **'No collections yet.'**
  String get asKbNone;

  /// No description provided for @asKbByScope.
  ///
  /// In en, this message translates to:
  /// **'By where it belongs ({on})'**
  String asKbByScope(String on);

  /// No description provided for @asKbOn.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get asKbOn;

  /// No description provided for @asKbOff.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get asKbOff;

  /// No description provided for @asKbScope_global.
  ///
  /// In en, this message translates to:
  /// **'Every agent'**
  String get asKbScope_global;

  /// No description provided for @asKbScope_agent.
  ///
  /// In en, this message translates to:
  /// **'One agent'**
  String get asKbScope_agent;

  /// No description provided for @asKbScope_project.
  ///
  /// In en, this message translates to:
  /// **'A project\'s agents'**
  String get asKbScope_project;

  /// No description provided for @asDanger.
  ///
  /// In en, this message translates to:
  /// **'Stopping it'**
  String get asDanger;

  /// No description provided for @asStopHelp.
  ///
  /// In en, this message translates to:
  /// **'A pause: its turns stop now, with those under it, and its open tasks wait. «Resume» brings it back and the tasks go on in the same conversation. To take it out of the team, use «Remove…».'**
  String get asStopHelp;

  /// No description provided for @asStopAsk.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}? It is a pause: its turns stop now and its open tasks wait; «Resume» brings it back and they go on where they were.'**
  String asStopAsk(String name);

  /// No description provided for @asStopYes.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}'**
  String asStopYes(String name);

  /// No description provided for @asStoppedNow.
  ///
  /// In en, this message translates to:
  /// **'{name} is stopped.'**
  String asStoppedNow(String name);

  /// No description provided for @asLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not read it from the server: {why}'**
  String asLoadFailed(String why);

  /// No description provided for @asMenuNew.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get asMenuNew;

  /// No description provided for @asMenuModel.
  ///
  /// In en, this message translates to:
  /// **'Model and effort…'**
  String get asMenuModel;

  /// No description provided for @asMenuInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions…'**
  String get asMenuInstructions;

  /// No description provided for @asMenuStopTurn.
  ///
  /// In en, this message translates to:
  /// **'Stop what it is doing'**
  String get asMenuStopTurn;

  /// The page's `permAsks` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{agent} asks for your yes'**
  String cvPermAsks(String agent);

  /// The page's `permWhy` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Why it asks'**
  String get cvPermWhy;

  /// The page's `permDetails` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get cvPermDetails;

  /// The page's `permTool` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get cvPermTool;

  /// The page's `permRawReasons` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Reasons in the log'**
  String get cvPermRawReasons;

  /// The page's `showLess` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get cvShowLess;

  /// The page's `showAllInput` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Show the whole input'**
  String get cvShowAllInput;

  /// The page's `allow` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get cvAllow;

  /// The page's `thisChat` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'In this conversation'**
  String get cvThisChat;

  /// The page's `thisChatHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Allow {tool} without asking again, in this conversation only'**
  String cvThisChatHint(String tool);

  /// The page's `always` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get cvAlways;

  /// The page's `alwaysHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Allow {tool} from now on without asking (a rule you can undo in Settings, Platform)'**
  String cvAlwaysHint(String tool);

  /// The page's `deny` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get cvDeny;

  /// The page's `denyWhy` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Deny and say why'**
  String get cvDenyWhy;

  /// The page's `denyWhyPlaceholder` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'What to do instead (the agent reads it)'**
  String get cvDenyWhyPlaceholder;

  /// The page's `criticalTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Danger: an action that cannot be undone'**
  String get cvCriticalTitle;

  /// The page's `criticalWhat` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'What happens if you allow it'**
  String get cvCriticalWhat;

  /// The page's `toolReqTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{name} asks to switch on «{tool}»'**
  String cvToolReqTitle(String name, String tool);

  /// The page's `toolReqWhy` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Why: {why}'**
  String cvToolReqWhy(String why);

  /// The page's `toolReqHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Without your yes it stays off. «Always» changes {name}\'s tools (you can undo it in the history).'**
  String cvToolReqHint(String name);

  /// The page's `toolReqSession` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Switch on for this conversation'**
  String get cvToolReqSession;

  /// The page's `toolReqAlways` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Always for {name}'**
  String cvToolReqAlways(String name);

  /// The page's `toolReqNo` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get cvToolReqNo;

  /// The page's `agTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'An artifact asks for a permission'**
  String get cvAgTitle;

  /// The page's `agCap` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Spending cap for this artifact:'**
  String get cvAgCap;

  /// The page's `agCapHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Its questions stop when the cap is reached; you can change it in Settings › Artifacts.'**
  String get cvAgCapHint;

  /// The page's `agHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It lasts until you take it back in Settings › Artifacts. A new version of the artifact keeps it; an imported copy starts with nothing.'**
  String get cvAgHint;

  /// The page's `agAllowCap` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Allow, up to {cap}'**
  String cvAgAllowCap(String cap);

  /// The page's `agAllow` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get cvAgAllow;

  /// The page's `agDeny` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get cvAgDeny;

  /// The page's `manyAnswers` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'one or more'**
  String get cvManyAnswers;

  /// The page's `otherAnswer` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Other: write your answer'**
  String get cvOtherAnswer;

  /// The page's `proposedPlan` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Proposed plan'**
  String get cvProposedPlan;

  /// The page's `waitingAnswer` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'waiting for an answer'**
  String get cvWaitingAnswer;

  /// The page's `notAnswered` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'not answered'**
  String get cvNotAnswered;

  /// The page's `planFeedback` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'What should change? (optional)'**
  String get cvPlanFeedback;

  /// The page's `planApprove` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Approve and carry on'**
  String get cvPlanApprove;

  /// The page's `planRevise` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Keep planning'**
  String get cvPlanRevise;

  /// The page's `sendFeedback` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send the feedback'**
  String get cvSendFeedback;

  /// The page's `answer` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get cvAnswer;

  /// The page's `todosTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Steps: {done} of {all} done'**
  String cvTodosTitle(String done, String all);

  /// The page's `editMessage` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cvEditMessage;

  /// The page's `editForks` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The edited message starts a copy of this conversation from here; this one stays as it is.'**
  String get cvEditForks;

  /// The page's `editSend` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get cvEditSend;

  /// The page's `cancel` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cvCancel;

  /// The page's `forkHere` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Continue from here'**
  String get cvForkHere;

  /// The page's `forkHereHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'A new conversation with everything up to this message; this one stays as it is'**
  String get cvForkHereHint;

  /// The page's `forkStartsHere` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The new conversation goes on from here.'**
  String get cvForkStartsHere;

  /// The page's `forkEdited` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The edited message goes on from here.'**
  String get cvForkEdited;

  /// The page's `forkBack` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Back to «{title}»'**
  String cvForkBack(String title);

  /// The page's `forkOrigin` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'the original conversation'**
  String get cvForkOrigin;

  /// The page's `compaction_auto` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The conversation was summarised here (the earlier part, made ahead of time)'**
  String get cvCompactionAuto;

  /// The page's `compaction_manual` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The conversation was summarised here, as you asked'**
  String get cvCompactionManual;

  /// The page's `compaction_emergency` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The conversation was summarised here: the window was full'**
  String get cvCompactionEmergency;

  /// The page's `compaction_engine` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The subscription\'s engine summarised its conversation here (by itself)'**
  String get cvCompactionEngine;

  /// The page's `compactionUndone` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Summary undone: the whole conversation is back'**
  String get cvCompactionUndone;

  /// The page's `undo` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get cvUndo;

  /// The page's `stepLimitContinue` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cvStepLimitContinue;

  /// The page's `stepLimitContinueHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The agent reached the limit of steps: let it go on from where it stopped'**
  String get cvStepLimitContinueHint;

  /// The page's `stepLimitGoOn` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Go on'**
  String get cvStepLimitGoOn;

  /// The page's `cacheMissed` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'This answer read only {cached} tokens from the cache instead of about {expected}: something changed the beginning of the conversation, so it was computed again (slower and, online, more expensive).'**
  String cvCacheMissed(String cached, String expected);

  /// The page's `toolNoResult` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'No result: the call ended without one (the turn was cancelled or stopped).'**
  String get cvToolNoResult;

  /// The page's `toolOnMachine` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'on {name}'**
  String cvToolOnMachine(String name);

  /// The page's `toolOnNode` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'on the node {name}'**
  String cvToolOnNode(String name);

  /// The page's `viaScript` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'from a script'**
  String get cvViaScript;

  /// The page's `toolSeen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'What the agent saw'**
  String get cvToolSeen;

  /// The page's `openSubagentChat` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Open the conversation of {name}'**
  String cvOpenSubagentChat(String name);

  /// The page's `kind_subagent` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get cvKindSubagent;

  /// The page's `elsewhereAsks` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{name} is asking you something in another conversation: «{title}»'**
  String cvElsewhereAsks(String name, String title);

  /// The page's `elsewhereWorking` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{name} is working in another conversation: «{title}»'**
  String cvElsewhereWorking(String name, String title);

  /// The page's `elsewhereUntitled` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'untitled'**
  String get cvElsewhereUntitled;

  /// The page's `elsewhereAnswerHere` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Answer here'**
  String get cvElsewhereAnswerHere;

  /// The page's `open` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get cvOpen;

  /// The page's `unqueue` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Take it back (if the agent has not read it yet)'**
  String get cvUnqueue;

  /// The page's `sentWhileWorking` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Sent while the agent works: it reads it as soon as it can'**
  String get cvSentWhileWorking;

  /// The page's `writeWhileWorking` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{name} is working: write anyway, it reads it right after…'**
  String cvWriteWhileWorking(String name);

  /// The page's `writeTo` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Write to {name}…'**
  String cvWriteTo(String name);

  /// The page's `stopWhenBack` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The connection is lost: «Stop» goes as soon as it is back.'**
  String get cvStopWhenBack;

  /// The page's `sendQueued` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send: it is read as soon as the current work allows'**
  String get cvSendQueued;

  /// The page's `interrupt` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get cvInterrupt;

  /// The page's `paBadge` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Archived · read only'**
  String get cvPaBadge;

  /// The page's `paChatReadOnly` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The project «{name}» is archived: this conversation is read only.'**
  String cvPaChatReadOnly(String name);

  /// The page's `paRestore` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get cvPaRestore;

  /// The page's `impChatNotice` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Conversation brought in from {source}{date}. You can go on with it here.'**
  String cvImpChatNotice(String source, String date);

  /// The page's `viaVoice` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'said by voice'**
  String get cvViaVoice;

  /// The page's `viaVoiceHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Said hands-free; the agent was asked for an answer to read aloud'**
  String get cvViaVoiceHint;

  /// The page's `viaArtifact` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'from a widget'**
  String get cvViaArtifact;

  /// The page's `viaArtifactHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Sent by a button you clicked in an artifact or a widget'**
  String get cvViaArtifactHint;

  /// The page's `canvasOpened` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Opened {name} in the canvas'**
  String cvCanvasOpened(String name);

  /// The page's `canvasShown` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'In the canvas: press to open it again'**
  String get cvCanvasShown;

  /// The page's `boardOpen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Open the board'**
  String get cvBoardOpen;

  /// The page's `boardWaiting` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'A board with {n} variants: open it to choose or comment'**
  String cvBoardWaiting(String n);

  /// The page's `boardDone` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Board: you chose variant {n}'**
  String cvBoardDone(String n);

  /// The page's `fileSave` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cvFileSave;

  /// The page's `canvasOpen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Open it in the canvas'**
  String get cvCanvasOpen;

  /// The page's `chSecretTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'This message holds a secret'**
  String get cvChSecretTitle;

  /// The page's `chSecretText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It looks like a key, a password or a card number. Secrets never go in a chat: the model and the log would keep it. Put it in the keychain instead, and agents will use it by name without seeing it.'**
  String get cvChSecretText;

  /// The page's `chSecretFound` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Found: {list}'**
  String cvChSecretFound(String list);

  /// The page's `chSecretKind_key` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'a key'**
  String get cvChSecretKindKey;

  /// The page's `chSecretKind_password` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'a password'**
  String get cvChSecretKindPassword;

  /// The page's `chSecretKind_code` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'a PIN or code'**
  String get cvChSecretKindCode;

  /// The page's `chSecretKind_card` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'a card number'**
  String get cvChSecretKindCard;

  /// The page's `chSecretKind_iban` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'an IBAN'**
  String get cvChSecretKindIban;

  /// The page's `chSecretBack` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Back to writing'**
  String get cvChSecretBack;

  /// The page's `chSecretSend` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send without it'**
  String get cvChSecretSend;

  /// The page's `chSecretVault` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Put it in the keychain'**
  String get cvChSecretVault;

  /// The page's `attachmentOpen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Open in the canvas'**
  String get cvAttachmentOpen;

  /// The page's `toBottom` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Go to the bottom'**
  String get cvToBottom;

  /// The page's `thinking` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get cvThinking;

  /// The page's `seeAttachments` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'(see the attachments)'**
  String get cvSeeAttachments;

  /// The page's `pastedOpen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'See the whole pasted text'**
  String get cvPastedOpen;

  /// The page's `pastedAsText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Paste as text'**
  String get cvPastedAsText;

  /// The page's `remove` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cvRemove;

  /// The page's `close` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get cvClose;

  /// The page's `copied` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get cvCopied;

  /// The page's `startConversation` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Write to {name} to start.'**
  String cvStartConversation(String name);

  /// The page's `subAsks` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The sub-agent «{name}» asks for your permission.'**
  String cvSubAsks(String name);

  /// The page's `pastedSize` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{lines} lines · {chars} characters'**
  String cvPastedSize(String lines, String chars);

  /// The page's `copy` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get cvCopy;

  /// No description provided for @mailCardNone.
  ///
  /// In en, this message translates to:
  /// **'No message found'**
  String get mailCardNone;

  /// No description provided for @mailCardMore.
  ///
  /// In en, this message translates to:
  /// **'{n} more'**
  String mailCardMore(int n);

  /// No description provided for @mailCardAttachments.
  ///
  /// In en, this message translates to:
  /// **'{n} attachments'**
  String mailCardAttachments(int n);

  /// No description provided for @mailCardAttachment.
  ///
  /// In en, this message translates to:
  /// **'1 attachment'**
  String get mailCardAttachment;

  /// No description provided for @mailCardSaved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get mailCardSaved;

  /// No description provided for @mailCardShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get mailCardShowAll;

  /// No description provided for @mailCardShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get mailCardShowLess;

  /// No description provided for @mailCardFolder.
  ///
  /// In en, this message translates to:
  /// **'{mailbox}, {folder}'**
  String mailCardFolder(String mailbox, String folder);

  /// No description provided for @mailCardDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get mailCardDraft;

  /// No description provided for @mailCardTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get mailCardTo;

  /// No description provided for @mailCardSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get mailCardSubject;

  /// No description provided for @mailCardUnread.
  ///
  /// In en, this message translates to:
  /// **'unread'**
  String get mailCardUnread;

  /// No description provided for @mailCardPermTitle.
  ///
  /// In en, this message translates to:
  /// **'The email, as it would leave'**
  String get mailCardPermTitle;

  /// No description provided for @mailCardDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get mailCardDraftSaved;

  /// No description provided for @mailCardDraftChanged.
  ///
  /// In en, this message translates to:
  /// **'Draft changed'**
  String get mailCardDraftChanged;

  /// No description provided for @mailCardSentFrom.
  ///
  /// In en, this message translates to:
  /// **'Sent from {mailbox}'**
  String mailCardSentFrom(String mailbox);

  /// No description provided for @mailCardNobody.
  ///
  /// In en, this message translates to:
  /// **'nobody yet'**
  String get mailCardNobody;

  /// The page's `acpKind_read` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'read'**
  String get cvAcpKindRead;

  /// The page's `acpKind_edit` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'edit'**
  String get cvAcpKindEdit;

  /// The page's `acpKind_delete` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get cvAcpKindDelete;

  /// The page's `acpKind_move` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'move'**
  String get cvAcpKindMove;

  /// The page's `acpKind_search` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'search'**
  String get cvAcpKindSearch;

  /// The page's `acpKind_execute` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'command'**
  String get cvAcpKindExecute;

  /// The page's `acpKind_think` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'think'**
  String get cvAcpKindThink;

  /// The page's `acpKind_fetch` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'fetch'**
  String get cvAcpKindFetch;

  /// The page's `acpKind_switch_mode` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'mode'**
  String get cvAcpKindSwitchMode;

  /// The page's `acpKind_other` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'action'**
  String get cvAcpKindOther;

  /// The page's `findVia_everything` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Everything\'s index'**
  String get cvFindViaEverything;

  /// The page's `findVia_spotlight` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Spotlight\'s index'**
  String get cvFindViaSpotlight;

  /// The page's `findVia_locate` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'the locate database'**
  String get cvFindViaLocate;

  /// The page's `findVia_walk` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'searched the folders'**
  String get cvFindViaWalk;

  /// The page's `findVia_path` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'programs on the PATH'**
  String get cvFindViaPath;

  /// The page's `findVia_container` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'searched in the container'**
  String get cvFindViaContainer;

  /// The page's `findTook` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{via}, {seconds} s'**
  String cvFindTook(String via, String seconds);

  /// The page's `findTookCut` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{via}, {seconds} s (stopped at {limit} s)'**
  String cvFindTookCut(String via, String seconds, String limit);

  /// The page's `findTookInterrupted` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{via}, {seconds} s (interrupted)'**
  String cvFindTookInterrupted(String via, String seconds);

  /// The page's `tooMany` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} attachments at most'**
  String cvTooMany(String n);

  /// No description provided for @widgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get widgetTitle;

  /// No description provided for @widgetPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing a widget…'**
  String get widgetPreparing;

  /// No description provided for @widgetOpenCanvas.
  ///
  /// In en, this message translates to:
  /// **'Open in the Canvas'**
  String get widgetOpenCanvas;

  /// No description provided for @widgetKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get widgetKeep;

  /// No description provided for @widgetKeepHint.
  ///
  /// In en, this message translates to:
  /// **'Saved as an artifact in artefatti/, and opened in the Canvas'**
  String get widgetKeepHint;

  /// No description provided for @widgetKeptShort.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get widgetKeptShort;

  /// No description provided for @widgetKept.
  ///
  /// In en, this message translates to:
  /// **'Kept as {path}'**
  String widgetKept(String path);

  /// No description provided for @widgetAsks.
  ///
  /// In en, this message translates to:
  /// **'It wants to send to the chat:'**
  String get widgetAsks;

  /// No description provided for @widgetNoChat.
  ///
  /// In en, this message translates to:
  /// **'It wants to send to the chat (open a conversation first):'**
  String get widgetNoChat;

  /// No description provided for @widgetSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get widgetSend;

  /// No description provided for @widgetDismiss.
  ///
  /// In en, this message translates to:
  /// **'Leave it'**
  String get widgetDismiss;

  /// No description provided for @widgetLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get widgetLoading;

  /// No description provided for @widgetOpenInPage.
  ///
  /// In en, this message translates to:
  /// **'Open in the page'**
  String get widgetOpenInPage;

  /// No description provided for @widgetNoFrameHere.
  ///
  /// In en, this message translates to:
  /// **'This system cannot run widgets and artifacts inside the app: open it in the page, in your browser.'**
  String get widgetNoFrameHere;

  /// No description provided for @artError1.
  ///
  /// In en, this message translates to:
  /// **'1 error'**
  String get artError1;

  /// No description provided for @artErrors.
  ///
  /// In en, this message translates to:
  /// **'{n} errors'**
  String artErrors(int n);

  /// No description provided for @previewLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'The page wants to open a link'**
  String get previewLinkTitle;

  /// No description provided for @previewLinkOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get previewLinkOpen;

  /// No description provided for @embedCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get embedCopied;

  /// No description provided for @embedShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied: paste it where you want to share it'**
  String get embedShareCopied;

  /// No description provided for @embedSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}'**
  String embedSaved(String name);

  /// No description provided for @embedOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in the browser'**
  String get embedOpenInBrowser;

  /// No description provided for @embedProbeTitle.
  ///
  /// In en, this message translates to:
  /// **'Web view test'**
  String get embedProbeTitle;

  /// No description provided for @embedSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get embedSaving;

  /// No description provided for @embedSavedState.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get embedSavedState;

  /// No description provided for @embedProbeOpen.
  ///
  /// In en, this message translates to:
  /// **'Web view test'**
  String get embedProbeOpen;

  /// No description provided for @requestAnswerAllowed.
  ///
  /// In en, this message translates to:
  /// **'allowed'**
  String get requestAnswerAllowed;

  /// No description provided for @requestAnswerDenied.
  ///
  /// In en, this message translates to:
  /// **'denied'**
  String get requestAnswerDenied;

  /// No description provided for @requestDoneHere.
  ///
  /// In en, this message translates to:
  /// **'You already answered from the page or another window: {answer}.'**
  String requestDoneHere(String answer);

  /// No description provided for @requestDoneChat.
  ///
  /// In en, this message translates to:
  /// **'You already answered from {chat}: {answer}.'**
  String requestDoneChat(String chat, String answer);

  /// No description provided for @requestDoneTimeout.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered in time: {answer}.'**
  String requestDoneTimeout(String answer);

  /// No description provided for @requestDoneElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Already decided elsewhere: {answer}.'**
  String requestDoneElsewhere(String answer);

  /// No description provided for @requestDoneClosing.
  ///
  /// In en, this message translates to:
  /// **'This screen closes by itself in a few seconds.'**
  String get requestDoneClosing;

  /// No description provided for @requestCloseHint.
  ///
  /// In en, this message translates to:
  /// **'Close (Esc)'**
  String get requestCloseHint;

  /// No description provided for @requestTechDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get requestTechDetails;

  /// No description provided for @cmOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get cmOpen;

  /// No description provided for @cmPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get cmPin;

  /// No description provided for @cmUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get cmUnpin;

  /// No description provided for @cmFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to a folder'**
  String get cmFolder;

  /// No description provided for @cmFolderNew.
  ///
  /// In en, this message translates to:
  /// **'New folder…'**
  String get cmFolderNew;

  /// No description provided for @cmFolderNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get cmFolderNewTitle;

  /// No description provided for @cmFolderNewYes.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get cmFolderNewYes;

  /// No description provided for @cmFolderOut.
  ///
  /// In en, this message translates to:
  /// **'Take it out of the folder'**
  String get cmFolderOut;

  /// No description provided for @cmArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get cmArchive;

  /// No description provided for @cmUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get cmUnarchive;

  /// No description provided for @cmExport.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get cmExport;

  /// No description provided for @cmArchived.
  ///
  /// In en, this message translates to:
  /// **'Conversation archived.'**
  String get cmArchived;

  /// No description provided for @cmUnarchived.
  ///
  /// In en, this message translates to:
  /// **'Conversation brought back.'**
  String get cmUnarchived;

  /// No description provided for @cmFailed.
  ///
  /// In en, this message translates to:
  /// **'It did not work: try again.'**
  String get cmFailed;

  /// No description provided for @cmExported.
  ///
  /// In en, this message translates to:
  /// **'File saved.'**
  String get cmExported;

  /// No description provided for @cmForkOf.
  ///
  /// In en, this message translates to:
  /// **'branch of «{title}»'**
  String cmForkOf(String title);

  /// No description provided for @cmArchivedN.
  ///
  /// In en, this message translates to:
  /// **'Archived ({n})'**
  String cmArchivedN(int n);

  /// No description provided for @cmBack.
  ///
  /// In en, this message translates to:
  /// **'Back to the conversations'**
  String get cmBack;

  /// No description provided for @cmNew.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get cmNew;

  /// No description provided for @cmEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet: start one.'**
  String get cmEmpty;

  /// No description provided for @cmEmptyArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived conversations.'**
  String get cmEmptyArchived;

  /// No description provided for @cmPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get cmPinned;

  /// No description provided for @cmConversationsOf.
  ///
  /// In en, this message translates to:
  /// **'Conversations with {name}'**
  String cmConversationsOf(String name);

  /// No description provided for @cmTask.
  ///
  /// In en, this message translates to:
  /// **'Task: {title}'**
  String cmTask(String title);

  /// No description provided for @cmShared.
  ///
  /// In en, this message translates to:
  /// **'Shared conversation'**
  String get cmShared;

  /// No description provided for @pmOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get pmOpen;

  /// No description provided for @pmTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks and files'**
  String get pmTasks;

  /// No description provided for @pmCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get pmCode;

  /// No description provided for @pmAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents of {project}'**
  String pmAgents(String project);

  /// No description provided for @pmArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive the project'**
  String get pmArchive;

  /// No description provided for @pmRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get pmRestore;

  /// No description provided for @pmInitGit.
  ///
  /// In en, this message translates to:
  /// **'Initialise git'**
  String get pmInitGit;

  /// No description provided for @pmInitGitDone.
  ///
  /// In en, this message translates to:
  /// **'Git repository created for «{name}» (branch main).'**
  String pmInitGitDone(String name);

  /// No description provided for @pmAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive «{name}»?'**
  String pmAskTitle(String name);

  /// No description provided for @pmAskLead.
  ///
  /// In en, this message translates to:
  /// **'The project leaves the lists and stays readable under «Archived». Nothing is deleted: restore it whenever you like and it comes back as it was.'**
  String get pmAskLead;

  /// No description provided for @pmWorking.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 agent is working: it will be stopped} other{{n} agents are working: they will be stopped}}'**
  String pmWorking(int n);

  /// No description provided for @pmNobody.
  ///
  /// In en, this message translates to:
  /// **'No agent is working in it now.'**
  String get pmNobody;

  /// No description provided for @pmAutos.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 automation will be paused ({names}); it runs again when you restore the project.} other{{n} automations will be paused ({names}); they run again when you restore the project.}}'**
  String pmAutos(int n, String names);

  /// No description provided for @pmFactTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks stay open.'**
  String get pmFactTasks;

  /// No description provided for @pmFactSandbox.
  ///
  /// In en, this message translates to:
  /// **'Its sandbox stops, and starts again on restore.'**
  String get pmFactSandbox;

  /// No description provided for @pmFactNobody.
  ///
  /// In en, this message translates to:
  /// **'Until then no agent works in it or changes its files, and your linked chats do not use it.'**
  String get pmFactNobody;

  /// No description provided for @pmFactRestore.
  ///
  /// In en, this message translates to:
  /// **'God can archive and restore it too, always with your yes.'**
  String get pmFactRestore;

  /// No description provided for @pmStopAndArchive.
  ///
  /// In en, this message translates to:
  /// **'Stop and archive'**
  String get pmStopAndArchive;

  /// No description provided for @pmArchiveYes.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get pmArchiveYes;

  /// No description provided for @pmArchived.
  ///
  /// In en, this message translates to:
  /// **'«{name}» archived.'**
  String pmArchived(String name);

  /// No description provided for @pmRestored.
  ///
  /// In en, this message translates to:
  /// **'«{name}» restored.'**
  String pmRestored(String name);

  /// No description provided for @pmArchivedN.
  ///
  /// In en, this message translates to:
  /// **'Archived ({n})'**
  String pmArchivedN(int n);

  /// No description provided for @pmArchivedOn.
  ///
  /// In en, this message translates to:
  /// **'archived on {day}'**
  String pmArchivedOn(String day);

  /// No description provided for @pmBadge.
  ///
  /// In en, this message translates to:
  /// **'Archived · read only'**
  String get pmBadge;

  /// No description provided for @pmViewLead.
  ///
  /// In en, this message translates to:
  /// **'Archived: you can read its conversations, tasks and files. Restore it to work in it again.'**
  String get pmViewLead;

  /// No description provided for @pmConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get pmConversations;

  /// No description provided for @pmTeam.
  ///
  /// In en, this message translates to:
  /// **'The team\'s conversations'**
  String get pmTeam;

  /// No description provided for @pmNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations.'**
  String get pmNoConversations;

  /// No description provided for @pmTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get pmTasksTitle;

  /// No description provided for @pmNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks.'**
  String get pmNoTasks;

  /// No description provided for @pmNoLead.
  ///
  /// In en, this message translates to:
  /// **'This project has no lead agent.'**
  String get pmNoLead;

  /// No description provided for @pmNoGit.
  ///
  /// In en, this message translates to:
  /// **'No git repository'**
  String get pmNoGit;

  /// No description provided for @bellTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get bellTitle;

  /// No description provided for @bellTooltip.
  ///
  /// In en, this message translates to:
  /// **'Requests and notifications'**
  String get bellTooltip;

  /// No description provided for @bellPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions ({n})'**
  String bellPermissions(int n);

  /// No description provided for @bellQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions ({n})'**
  String bellQuestions(int n);

  /// No description provided for @bellWorking.
  ///
  /// In en, this message translates to:
  /// **'Working now ({n})'**
  String bellWorking(int n);

  /// No description provided for @bellNoApprovals.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for you.'**
  String get bellNoApprovals;

  /// No description provided for @bellNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions.'**
  String get bellNoQuestions;

  /// No description provided for @bellNothingRunning.
  ///
  /// In en, this message translates to:
  /// **'Nothing is running.'**
  String get bellNothingRunning;

  /// No description provided for @bellAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get bellAllow;

  /// No description provided for @bellDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get bellDeny;

  /// No description provided for @bellLook.
  ///
  /// In en, this message translates to:
  /// **'Look and decide'**
  String get bellLook;

  /// No description provided for @bellAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get bellAnswer;

  /// No description provided for @bellSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get bellSeeAll;

  /// No description provided for @pmConversationsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no conversations} =1{1 conversation} other{{n} conversations}}'**
  String pmConversationsCount(int n);

  /// No description provided for @raMenu.
  ///
  /// In en, this message translates to:
  /// **'Remove…'**
  String get raMenu;

  /// No description provided for @raTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String raTitle(String name);

  /// No description provided for @raBody.
  ///
  /// In en, this message translates to:
  /// **'{name} leaves the team: its turns stop and nobody gives it work any more. Nothing is deleted: its conversations and its history stay, readable in «Removed agents», where you can restore it.'**
  String raBody(String name);

  /// No description provided for @raWith.
  ///
  /// In en, this message translates to:
  /// **'Removed with it: {names}'**
  String raWith(String names);

  /// No description provided for @raKept.
  ///
  /// In en, this message translates to:
  /// **'Work not merged: {commits} commit(s), {files} changed file(s)'**
  String raKept(int commits, int files);

  /// No description provided for @raKeptError.
  ///
  /// In en, this message translates to:
  /// **'Work kept as it is: it could not be checked'**
  String get raKeptError;

  /// No description provided for @raKeptHow.
  ///
  /// In en, this message translates to:
  /// **'It stays on the branch {branch}: restore the agent to pick it up.'**
  String raKeptHow(String branch);

  /// No description provided for @raTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks that close («agent removed»): {count}'**
  String raTasks(int count);

  /// No description provided for @raRunning.
  ///
  /// In en, this message translates to:
  /// **'Conversations at work that stop now: {count}'**
  String raRunning(int count);

  /// No description provided for @raYes.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String raYes(String name);

  /// No description provided for @raDone.
  ///
  /// In en, this message translates to:
  /// **'{name} removed: «Removed agents» brings it back.'**
  String raDone(String name);

  /// No description provided for @raFailed.
  ///
  /// In en, this message translates to:
  /// **'Not removed: {why}'**
  String raFailed(String why);

  /// No description provided for @raProtected.
  ///
  /// In en, this message translates to:
  /// **'{name} cannot be removed.'**
  String raProtected(String name);

  /// No description provided for @raHelp.
  ///
  /// In en, this message translates to:
  /// **'It leaves the team with the agents below it; its history stays and you can restore it from «Removed agents».'**
  String get raHelp;

  /// No description provided for @raListTitle.
  ///
  /// In en, this message translates to:
  /// **'Removed agents'**
  String get raListTitle;

  /// No description provided for @raListRow.
  ///
  /// In en, this message translates to:
  /// **'Read their conversations, bring them back'**
  String get raListRow;

  /// No description provided for @raListHelp.
  ///
  /// In en, this message translates to:
  /// **'Agents removed from the team, by you or by God. Nothing was deleted: their conversations stay readable, and «Restore» brings each back with those removed with it.'**
  String get raListHelp;

  /// No description provided for @raNone.
  ///
  /// In en, this message translates to:
  /// **'No removed agents.'**
  String get raNone;

  /// No description provided for @raWhen.
  ///
  /// In en, this message translates to:
  /// **'Removed {when} by {by}'**
  String raWhen(String when, String by);

  /// No description provided for @raByYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get raByYou;

  /// No description provided for @raReason.
  ///
  /// In en, this message translates to:
  /// **'Why: {reason}'**
  String raReason(String reason);

  /// No description provided for @raRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get raRestore;

  /// No description provided for @raRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} is back in the team.'**
  String raRestored(String name);

  /// No description provided for @raRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Not restored: {why}'**
  String raRestoreFailed(String why);

  /// No description provided for @raConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations ({count})'**
  String raConversations(int count);

  /// No description provided for @raNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations.'**
  String get raNoConversations;

  /// No description provided for @raReadOnly.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed: this conversation is read only.'**
  String raReadOnly(String name);

  /// No description provided for @raBadge.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get raBadge;

  /// No description provided for @paMenu.
  ///
  /// In en, this message translates to:
  /// **'Stop…'**
  String get paMenu;

  /// No description provided for @paTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}?'**
  String paTitle(String name);

  /// No description provided for @paYes.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}'**
  String paYes(String name);

  /// No description provided for @paDone.
  ///
  /// In en, this message translates to:
  /// **'{name} is paused: «Resume» brings it back.'**
  String paDone(String name);

  /// No description provided for @paResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get paResume;

  /// No description provided for @paResumeHelp.
  ///
  /// In en, this message translates to:
  /// **'{name} is stopped (paused). «Resume» brings it back with those stopped under it, and its open tasks go on in the same conversation.'**
  String paResumeHelp(String name);

  /// No description provided for @paResumed.
  ///
  /// In en, this message translates to:
  /// **'{name} works again.'**
  String paResumed(String name);

  /// No description provided for @paResumedTasks.
  ///
  /// In en, this message translates to:
  /// **'{name} works again: its open tasks go on.'**
  String paResumedTasks(String name);

  /// No description provided for @paResumeFailed.
  ///
  /// In en, this message translates to:
  /// **'Not resumed: {why}'**
  String paResumeFailed(String why);

  /// No description provided for @paReadOnly.
  ///
  /// In en, this message translates to:
  /// **'{name} is stopped (paused): resume it to write to it.'**
  String paReadOnly(String name);

  /// No description provided for @paBadge.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paBadge;

  /// No description provided for @atWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents at work together'**
  String get atWorkTitle;

  /// No description provided for @atWorkAtMost.
  ///
  /// In en, this message translates to:
  /// **'Agents at work together, at most'**
  String get atWorkAtMost;

  /// No description provided for @atWorkHelp.
  ///
  /// In en, this message translates to:
  /// **'How many agents can work at the same moment. The others wait in the queue and start by themselves, in order, as soon as a place is free. Your own messages never wait; a sub-agent takes the place of the one waiting for it. Lowering it stops nobody: it holds for the turns that come next.'**
  String get atWorkHelp;

  /// No description provided for @atWorkNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get atWorkNoLimit;

  /// No description provided for @atWorkSummary.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{At most 1 agent at a time} other{At most {n} agents at a time}}'**
  String atWorkSummary(int n);

  /// No description provided for @atWorkNoLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Every agent with work starts at once.'**
  String get atWorkNoLimitHint;

  /// No description provided for @atWorkSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: it holds for the turns that start from now.'**
  String get atWorkSaved;

  /// No description provided for @atWorkNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get atWorkNow;

  /// No description provided for @atWorkPlaces.
  ///
  /// In en, this message translates to:
  /// **'{working} of {limit} places taken'**
  String atWorkPlaces(int working, int limit);

  /// No description provided for @atWorkPlacesNoLimit.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Nobody at work} =1{1 at work, no limit} other{{n} at work, no limit}}'**
  String atWorkPlacesNoLimit(int n);

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents\' queue'**
  String get queueTitle;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody is waiting: every agent with work is working.'**
  String get queueEmpty;

  /// No description provided for @queuedNth.
  ///
  /// In en, this message translates to:
  /// **'queued ({nth} of {of})'**
  String queuedNth(String nth, int of);

  /// No description provided for @queuedBanner.
  ///
  /// In en, this message translates to:
  /// **'Queued ({nth} of {of}): waiting for a free place'**
  String queuedBanner(String nth, int of);

  /// No description provided for @queueWaitingDoing.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a free place'**
  String get queueWaitingDoing;

  /// No description provided for @queueMoveFirst.
  ///
  /// In en, this message translates to:
  /// **'Move ahead'**
  String get queueMoveFirst;

  /// No description provided for @queueSee.
  ///
  /// In en, this message translates to:
  /// **'See the queue'**
  String get queueSee;

  /// No description provided for @queueNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get queueNext;

  /// No description provided for @queueStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get queueStop;

  /// No description provided for @queueWaited.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{waiting since just now} =1{waiting for 1 min} other{waiting for {n} min}}'**
  String queueWaited(int n);

  /// No description provided for @queueChild.
  ///
  /// In en, this message translates to:
  /// **'asked by an agent waiting for it'**
  String get queueChild;

  /// No description provided for @queueMoved.
  ///
  /// In en, this message translates to:
  /// **'moved ahead by you'**
  String get queueMoved;

  /// No description provided for @queueMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'It no longer waits: it may have just started.'**
  String get queueMoveFailed;

  /// No description provided for @statusAtWork.
  ///
  /// In en, this message translates to:
  /// **'At work {working}/{limit}'**
  String statusAtWork(int working, int limit);

  /// No description provided for @statusAtWorkNoLimit.
  ///
  /// In en, this message translates to:
  /// **'At work {n}'**
  String statusAtWorkNoLimit(int n);

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'queued {n}'**
  String statusQueued(int n);

  /// No description provided for @queueOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Change the limit'**
  String get queueOpenSettings;

  /// No description provided for @fxOpenFiles.
  ///
  /// In en, this message translates to:
  /// **'Project files'**
  String get fxOpenFiles;

  /// No description provided for @fxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Files and folders'**
  String get fxSubtitle;

  /// No description provided for @fxPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get fxPlatform;

  /// No description provided for @fxAssistants.
  ///
  /// In en, this message translates to:
  /// **'Personal agents'**
  String get fxAssistants;

  /// No description provided for @fxNewFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get fxNewFile;

  /// No description provided for @fxNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get fxNewFolder;

  /// No description provided for @fxMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get fxMake;

  /// No description provided for @fxPathHint.
  ///
  /// In en, this message translates to:
  /// **'Name, with its folder if you want one (docs/note.md)'**
  String get fxPathHint;

  /// No description provided for @fxUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get fxUpload;

  /// No description provided for @fxUploaded.
  ///
  /// In en, this message translates to:
  /// **'Files uploaded: {count}.'**
  String fxUploaded(int count);

  /// No description provided for @fxShowHidden.
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get fxShowHidden;

  /// No description provided for @fxHideHidden.
  ///
  /// In en, this message translates to:
  /// **'Hide hidden files'**
  String get fxHideHidden;

  /// No description provided for @fxRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get fxRefresh;

  /// No description provided for @fxTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get fxTerminal;

  /// No description provided for @fxFull.
  ///
  /// In en, this message translates to:
  /// **'Full window'**
  String get fxFull;

  /// No description provided for @fxFullOff.
  ///
  /// In en, this message translates to:
  /// **'Beside the conversation'**
  String get fxFullOff;

  /// No description provided for @fxClose.
  ///
  /// In en, this message translates to:
  /// **'Close the files'**
  String get fxClose;

  /// No description provided for @fxSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the files'**
  String get fxSearchHint;

  /// No description provided for @fxClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear the search'**
  String get fxClearSearch;

  /// No description provided for @fxFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get fxFolder;

  /// No description provided for @fxReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only: the project is archived'**
  String get fxReadOnly;

  /// No description provided for @fxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty folder.'**
  String get fxEmpty;

  /// No description provided for @fxDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop the files to upload them here'**
  String get fxDropHere;

  /// No description provided for @fxExists.
  ///
  /// In en, this message translates to:
  /// **'{name} already exists here.'**
  String fxExists(String name);

  /// No description provided for @fxKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get fxKeepBoth;

  /// No description provided for @fxReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get fxReplace;

  /// No description provided for @fxOpen.
  ///
  /// In en, this message translates to:
  /// **'Open in the Canvas'**
  String get fxOpen;

  /// No description provided for @fxAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask the agent'**
  String get fxAsk;

  /// No description provided for @fxRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get fxRename;

  /// No description provided for @fxDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get fxDownload;

  /// No description provided for @fxDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{name} saved.'**
  String fxDownloaded(String name);

  /// No description provided for @fxDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fxDelete;

  /// No description provided for @fxConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Move {path} to the trash (.trash)?'**
  String fxConfirmDelete(String path);

  /// No description provided for @fxConfirmDeleteForGood.
  ///
  /// In en, this message translates to:
  /// **'Delete {path} for good?'**
  String fxConfirmDeleteForGood(String path);

  /// No description provided for @fxMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get fxMore;

  /// No description provided for @fxResize.
  ///
  /// In en, this message translates to:
  /// **'Resize the files panel'**
  String get fxResize;

  /// No description provided for @fxAttachFailed.
  ///
  /// In en, this message translates to:
  /// **'{name} could not be attached.'**
  String fxAttachFailed(String name);

  /// The page's `boardChoose` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'I choose this'**
  String get cvBoardChoose;

  /// The page's `boardChosen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Chosen'**
  String get cvBoardChosen;

  /// The page's `boardChoiceWord` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'chosen'**
  String get cvBoardChoiceWord;

  /// The page's `boardCommentWord` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'comment'**
  String get cvBoardCommentWord;

  /// The page's `boardWriteComment` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get cvBoardWriteComment;

  /// The page's `boardSending` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get cvBoardSending;

  /// The page's `boardSent` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Sent to the agent'**
  String get cvBoardSent;

  /// The page's `boardOneVariant` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'1 variant'**
  String get cvBoardOneVariant;

  /// The page's `boardVariants` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} variants'**
  String cvBoardVariants(String n);

  /// The page's `boardScreens` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Width of the previews'**
  String get cvBoardScreens;

  /// The page's `boardScreen_computer` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get cvBoardScreenComputer;

  /// The page's `boardScreen_tablet` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get cvBoardScreenTablet;

  /// The page's `boardScreen_phone` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get cvBoardScreenPhone;

  /// The page's `boardFull` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get cvBoardFull;

  /// The page's `boardCommentHere` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'A comment on this variant (optional with «I choose this»)'**
  String get cvBoardCommentHere;

  /// The page's `boardSendComment` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get cvBoardSendComment;

  /// The page's `boardWhole` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'A comment on the whole board'**
  String get cvBoardWhole;

  /// The page's `boardWholeHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'For example: I like the colour of 2 with the layout of 3'**
  String get cvBoardWholeHint;

  /// The page's `boardSendToAgent` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send to the agent'**
  String get cvBoardSendToAgent;

  /// The page's `boardTab` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get cvBoardTab;

  /// The page's `boardNotFound` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'This board is no longer here'**
  String get cvBoardNotFound;

  /// The page's `canvasReload` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get cvCanvasReload;

  /// The page's `embedPort` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Port {port}'**
  String cvEmbedPort(String port);

  /// The page's `drawing` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Drawing… {percent}%'**
  String cvDrawing(String percent);

  /// The page's `arSection` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Artifacts'**
  String get cvArSection;

  /// The page's `arLead` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The small apps in a single file your agents make for you. They open in the Canvas, next to the chat.'**
  String get cvArLead;

  /// The page's `arImport` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get cvArImport;

  /// The page's `arEmptyTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'No artifacts yet'**
  String get cvArEmptyTitle;

  /// The page's `arEmpty1` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'An artifact is an HTML app in a single file that an agent makes in one turn: a calculator, a tournament board, a game, a viewer for a CSV. It runs in the Canvas, in an isolated frame, without installing anything and without going online.'**
  String get cvArEmpty1;

  /// The page's `arEmpty2` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It lives as a file in the artefatti/ folder of a project (or of God and the assistants), so you also find it among the files on the right. To get one, ask an agent for a tool you want to keep and use again; or import a .rgartifact from another Rasgeth.'**
  String get cvArEmpty2;

  /// The page's `arPlacePlatform` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'God\'s folder'**
  String get cvArPlacePlatform;

  /// The page's `arPlaceAssistants` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The assistants\' desk'**
  String get cvArPlaceAssistants;

  /// The page's `arOpen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get cvArOpen;

  /// The page's `arExport` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get cvArExport;

  /// The page's `arDelete` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cvArDelete;

  /// The page's `arVersion` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'version {n}'**
  String cvArVersion(String n);

  /// The page's `arNoHeader` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'no header'**
  String get cvArNoHeader;

  /// The page's `arLibs` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'libraries: {libs}'**
  String cvArLibs(String libs);

  /// The page's `arFrom` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'by {who}'**
  String cvArFrom(String who);

  /// The page's `arPending` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Imported · not run yet'**
  String get cvArPending;

  /// The page's `arReadOnly` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'read only: the project is archived'**
  String get cvArReadOnly;

  /// The page's `arDeleteQ` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Delete «{name}»?'**
  String cvArDeleteQ(String name);

  /// The page's `arDeleteText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The file goes to the trash of its folder, as from the file explorer.'**
  String get cvArDeleteText;

  /// The page's `arExportTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Export «{name}»'**
  String cvArExportTitle(String name);

  /// The page's `arExportZip` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'A .rgartifact file'**
  String get cvArExportZip;

  /// The page's `arExportZipText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'To import it into another Rasgeth: the app, its manifest and the fingerprint that checks it arrived intact. It carries no permissions.'**
  String get cvArExportZipText;

  /// The page's `arExportHtml` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Download as HTML'**
  String get cvArExportHtml;

  /// The page's `arExportHtmlText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'To open it elsewhere. Careful: outside Rasgeth it runs without the isolated frame, with the rights of the page you open it in.'**
  String get cvArExportHtmlText;

  /// The page's `arWhereQ` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Where should it go?'**
  String get cvArWhereQ;

  /// The page's `arWhereLead` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It goes into the artefatti/ folder of the place you choose. It starts with no permissions, and the first time it opens on its source with «Run».'**
  String get cvArWhereLead;

  /// The page's `arImported` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'«{name}» imported into {place}: the first time it opens on its source, with «Run».'**
  String cvArImported(String name, String place);

  /// The page's `arDataIgnored` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The saved data it carries was not imported.'**
  String get cvArDataIgnored;

  /// The page's `arDataImported` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Its saved data came along too.'**
  String get cvArDataImported;

  /// The page's `arHasData` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'keeps saved data'**
  String get cvArHasData;

  /// The page's `arExportData` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Include its saved data'**
  String get cvArExportData;

  /// The page's `arExportDataHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'What the app kept on Rasgeth (storage). Leave it off for a clean copy without your data.'**
  String get cvArExportDataHint;

  /// The page's `arPerms` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get cvArPerms;

  /// The page's `arWants` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It asks to {what}'**
  String cvArWants(String what);

  /// The page's `arPermGranted` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'granted'**
  String get cvArPermGranted;

  /// The page's `arPermNot` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'not granted'**
  String get cvArPermNot;

  /// The page's `arGrant` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get cvArGrant;

  /// The page's `arRevoke` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get cvArRevoke;

  /// The page's `arSpent` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{spent} spent of {cap}'**
  String cvArSpent(String spent, String cap);

  /// Settings of the server: the Artifacts row (G42.2).
  ///
  /// In en, this message translates to:
  /// **'ARTIFACTS'**
  String get sectionArtifacts;

  /// Settings of the server: the Artifacts row (G42.2).
  ///
  /// In en, this message translates to:
  /// **'The apps the agents made: open, export, import, delete and their permissions'**
  String get artifactsRowHint;

  /// The page's `vwToChat` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get cvVwToChat;

  /// The right column's tab with the conversation's files (3.8.11)
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get sideTabFiles;

  /// The right column's tab with the Canvas (3.8.11)
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get sideTabCanvas;

  /// Screen reader label of the right column tabs
  ///
  /// In en, this message translates to:
  /// **'What the right column shows'**
  String get sideTabsLabel;

  /// A file in the chat: save it on this device (3.8.11)
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get chatFileDownload;

  /// No description provided for @chatAttachmentDownload.
  ///
  /// In en, this message translates to:
  /// **'Download the attachment'**
  String get chatAttachmentDownload;

  /// No description provided for @chatFileDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}'**
  String chatFileDownloading(String name);

  /// No description provided for @chatFileDownloadOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} · {speed}/s · {left} left'**
  String chatFileDownloadOf(String done, String total, String speed, String left);

  /// No description provided for @chatFileDownloadSoFar.
  ///
  /// In en, this message translates to:
  /// **'{done} · {speed}/s'**
  String chatFileDownloadSoFar(String done, String speed);

  /// No description provided for @chatFileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}'**
  String chatFileSaved(String name);

  /// No description provided for @chatFileDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download {name}'**
  String chatFileDownloadFailed(String name);

  /// The page's `subMain` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Main agent'**
  String get cvSubMain;

  /// The page's `subPath` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Where you are'**
  String get cvSubPath;

  /// The page's `subRow` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Sub-agents'**
  String get cvSubRow;

  /// The page's `subOpenTab` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Open its tab'**
  String get cvSubOpenTab;

  /// The page's `subStatus_running` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get cvSubStatusRunning;

  /// The page's `subStatus_done` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get cvSubStatusDone;

  /// The page's `subStatus_failed` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get cvSubStatusFailed;

  /// The page's `subStatus_stopped` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get cvSubStatusStopped;

  /// The page's `subFresh` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Something new'**
  String get cvSubFresh;

  /// The page's `subWaits` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Waits for your yes'**
  String get cvSubWaits;

  /// The page's `subClose` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Close the tab'**
  String get cvSubClose;

  /// The page's `subTask` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Task received'**
  String get cvSubTask;

  /// The page's `subTaskFrom` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Task from «{name}»'**
  String cvSubTaskFrom(String name);

  /// The page's `subEnded_done` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It finished: its report went back to the agent that started it.'**
  String get cvSubEndedDone;

  /// The page's `subEnded_failed` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It did not finish its task.'**
  String get cvSubEndedFailed;

  /// The page's `subEnded_stopped` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It was stopped.'**
  String get cvSubEndedStopped;

  /// The page's `subInterrupted` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Interrupted: the server stopped while it worked.'**
  String get cvSubInterrupted;

  /// The page's `subTime` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String cvSubTime(String time);

  /// The page's `subTools` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} tools'**
  String cvSubTools(String n);

  /// The page's `subTokens` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} tokens'**
  String cvSubTokens(String n);

  /// The page's `subNoWrite` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It takes orders only from the agent that started it'**
  String get cvSubNoWrite;

  /// The page's `subStop` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get cvSubStop;

  /// The page's `cmdStrip` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Background commands'**
  String get cvCmdStrip;

  /// The page's `cmdRunningN` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} running'**
  String cvCmdRunningN(String n);

  /// The page's `cmdDoneN` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} finished'**
  String cvCmdDoneN(String n);

  /// The page's `cmdOpenStrip` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Show the background commands'**
  String get cvCmdOpenStrip;

  /// The page's `cmdShrinkStrip` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Reduce to one line'**
  String get cvCmdShrinkStrip;

  /// The page's `cmdStartedAt` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Started at {at}'**
  String cvCmdStartedAt(String at);

  /// The page's `cmdOutput` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get cvCmdOutput;

  /// The page's `cmdStop` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get cvCmdStop;

  /// The page's `cmdFinishedN` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} finished commands'**
  String cvCmdFinishedN(String n);

  /// The page's `cmdRemoveFinished` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Remove all finished'**
  String get cvCmdRemoveFinished;

  /// The page's `cmdRemove` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cvCmdRemove;

  /// The page's `cmdStatus_running` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get cvCmdStatusRunning;

  /// The page's `cmdStatus_done` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'exit code {code}'**
  String cvCmdStatusDone(String code);

  /// The page's `cmdStatus_failed` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'failed, exit code {code}'**
  String cvCmdStatusFailed(String code);

  /// The page's `cmdStatus_stopped` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'stopped'**
  String get cvCmdStatusStopped;

  /// The page's `cmdStatus_interrupted` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'interrupted (Rasgeth had stopped)'**
  String get cvCmdStatusInterrupted;

  /// The page's `cmdOutputTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Background command'**
  String get cvCmdOutputTitle;

  /// The page's `cmdStarted` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get cvCmdStarted;

  /// The page's `cmdEnded` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get cvCmdEnded;

  /// The page's `cmdFolder` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get cvCmdFolder;

  /// The page's `cmdBy` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Started by'**
  String get cvCmdBy;

  /// The page's `cmdShowTimes` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Times of every line'**
  String get cvCmdShowTimes;

  /// The page's `cmdLines` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} lines'**
  String cvCmdLines(String n);

  /// The page's `cmdNoLog` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Its log is not there any more.'**
  String get cvCmdNoLog;

  /// The page's `roomAdd` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Add an agent'**
  String get cvRoomAdd;

  /// The page's `roomAnswering` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{names} is answering…'**
  String cvRoomAnswering(String names);

  /// The page's `roomEmpty` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Write to everyone: the first one answers, or call someone with @name. Adding an agent gives it no new access: what the others write reaches it as information.'**
  String get cvRoomEmpty;

  /// The page's `roomFirst` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'answers first'**
  String get cvRoomFirst;

  /// The page's `roomGone` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'This group chat no longer exists.'**
  String get cvRoomGone;

  /// The page's `roomGroupPersonal` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get cvRoomGroupPersonal;

  /// The page's `roomInspector` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Inspector of {project}'**
  String cvRoomInspector(String project);

  /// The page's `roomLead` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Lead of {project}'**
  String cvRoomLead(String project);

  /// The page's `roomPick` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Who?'**
  String get cvRoomPick;

  /// The page's `roomRemove` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the chat'**
  String cvRoomRemove(String name);

  /// The page's `roomUsageHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'What its answers here cost, and how full its context is'**
  String get cvRoomUsageHint;

  /// The page's `roomWrite` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Write to the group (@ to call someone)'**
  String get cvRoomWrite;

  /// The page's `roomJoined` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{name} joined the chat'**
  String cvRoomJoined(String name);

  /// The page's `roomLeft` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{name} left the chat'**
  String cvRoomLeft(String name);

  /// The page's `groups` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get cvGroups;

  /// The page's `groupsEmpty` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Several agents in one chat: «Add an agent» in any conversation.'**
  String get cvGroupsEmpty;

  /// The page's `groupNew` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get cvGroupNew;

  /// The page's `chatsArchived` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Archived ({n})'**
  String cvChatsArchived(String n);

  /// The page's `chatsBefore` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Earlier chats'**
  String get cvChatsBefore;

  /// The page's `archive` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get cvArchive;

  /// The page's `unarchive` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get cvUnarchive;

  /// The page's `chatHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Ask anything: the Chat searches the web and cites its sources, makes files, pages and pictures and shows them to you, and proposes variants to choose from.'**
  String get cvChatHint;

  /// The page's `newChat` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get cvNewChat;

  /// The page's `dailyChat` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get cvDailyChat;

  /// The page's `delete` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cvDelete;

  /// The page's `deleteChatConfirm` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Delete this chat for good?'**
  String get cvDeleteChatConfirm;

  /// The page's `chatToGroup` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Go on as a group: add an agent, which gets this chat as context'**
  String get cvChatToGroup;

  /// The page's `agentModelDefault` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The default model'**
  String get cvAgentModelDefault;

  /// The page's `inspector` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get cvInspector;

  /// The page's `inspectorHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Ask the inspector about this project: it reads files, git, the activity log, tasks, the board and the budget, and changes nothing.'**
  String get cvInspectorHint;

  /// The page's `inspectorAlerts` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Tell me on Telegram when something goes wrong (abandoned task, budget exceeded, blocker, failed automation)'**
  String get cvInspectorAlerts;

  /// The page's `inspectorSummary` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Daily summary at'**
  String get cvInspectorSummary;

  /// The page's `folderMove` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Move to a folder'**
  String get cvFolderMove;

  /// The page's `folderNew` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'New folder…'**
  String get cvFolderNew;

  /// The page's `folderName` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get cvFolderName;

  /// The page's `folderOut` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Take it out of the folder'**
  String get cvFolderOut;

  /// The page's `exportMd` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get cvExportMd;

  /// The page's `board` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get cvBoard;

  /// The page's `newThread` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'New thread'**
  String get cvNewThread;

  /// The page's `title` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get cvTitle;

  /// The page's `reply` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get cvReply;

  /// The page's `search` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get cvSearch;

  /// The page's `summary` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get cvSummary;

  /// The page's `resolve` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get cvResolve;

  /// The page's `block` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get cvBlock;

  /// The page's `reopen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get cvReopen;

  /// The page's `postKinds` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'task,result,question,decision,blocker,note'**
  String get cvPostKinds;

  /// The page's `postKindLabels` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'task,result,question,decision,blocker,note'**
  String get cvPostKindLabels;

  /// The page's `statusOpen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get cvStatusOpen;

  /// The page's `statusResolved` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'resolved'**
  String get cvStatusResolved;

  /// The page's `statusBlocked` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'blocked'**
  String get cvStatusBlocked;

  /// The page's `emptyBoard` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'No threads yet.'**
  String get cvEmptyBoard;

  /// The page's `noResults` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get cvNoResults;

  /// The page's `agentWholeProject` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The whole project'**
  String get cvAgentWholeProject;

  /// The page's `boardSub` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Subproject'**
  String get cvBoardSub;

  /// The page's `you` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get cvYou;

  /// The page's `screenTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Agents\' browser'**
  String get cvScreenTitle;

  /// The page's `screenOpen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get cvScreenOpen;

  /// The page's `screenTake` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Take control'**
  String get cvScreenTake;

  /// The page's `screenGiveBack` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Give it back to the agents'**
  String get cvScreenGiveBack;

  /// The page's `screenAddress` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Web address'**
  String get cvScreenAddress;

  /// The page's `screenShared` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The browser your personal agents share: sign in once and every one of them can use that site. Take control to sign in: what you type goes to the page only, never to an agent.'**
  String get cvScreenShared;

  /// The page's `screenYours` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'You have control: the agents wait. Click and type on the screen; give it back when you are done.'**
  String get cvScreenYours;

  /// The page's `screenStarting` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Starting the browser…'**
  String get cvScreenStarting;

  /// The page's `screenUnavailable` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The agents\' browser needs Rasgeth\'s Docker installation.'**
  String get cvScreenUnavailable;

  /// The page's `teachStart` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Teach a task'**
  String get cvTeachStart;

  /// The page's `teachHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Do the task once yourself: every page, click and text is written down (never passwords), then the agent turns it into a skill you approve in Extensions'**
  String get cvTeachHint;

  /// The page's `teachWho` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Which agent learns it'**
  String get cvTeachWho;

  /// The page's `teachRecording` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Recording for {name}: do the task, then press Done. Passwords are never written down.'**
  String cvTeachRecording(String name);

  /// The page's `teachDone` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cvTeachDone;

  /// The page's `teachTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'What is this task called? (optional)'**
  String get cvTeachTitle;

  /// The page's `chatPlaceholder` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Write a message (Enter to send, Shift+Enter for a new line)'**
  String get cvChatPlaceholder;

  /// The page's `conversations` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get cvConversations;

  /// The page's `chatInstructions` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The Chat\'s instructions'**
  String get cvChatInstructions;

  /// No description provided for @termOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Open again'**
  String get termOpenAgain;

  /// No description provided for @termKeyLeft.
  ///
  /// In en, this message translates to:
  /// **'Left arrow'**
  String get termKeyLeft;

  /// No description provided for @termKeyUp.
  ///
  /// In en, this message translates to:
  /// **'Up arrow'**
  String get termKeyUp;

  /// No description provided for @termKeyDown.
  ///
  /// In en, this message translates to:
  /// **'Down arrow'**
  String get termKeyDown;

  /// No description provided for @termKeyRight.
  ///
  /// In en, this message translates to:
  /// **'Right arrow'**
  String get termKeyRight;

  /// No description provided for @termPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get termPaste;

  /// No description provided for @termShowKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Show the keyboard'**
  String get termShowKeyboard;

  /// No description provided for @termHideKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide the keyboard'**
  String get termHideKeyboard;

  /// No description provided for @spTitle.
  ///
  /// In en, this message translates to:
  /// **'Subprojects'**
  String get spTitle;

  /// No description provided for @spNew.
  ///
  /// In en, this message translates to:
  /// **'New subproject'**
  String get spNew;

  /// No description provided for @spNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New subproject in «{name}»'**
  String spNewTitle(String name);

  /// No description provided for @spNoTeam.
  ///
  /// In en, this message translates to:
  /// **'no agents'**
  String get spNoTeam;

  /// No description provided for @spTeam.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 agent} other{{n} agents}}'**
  String spTeam(int n);

  /// No description provided for @spNoAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents yet: create them from the project\'s agents.'**
  String get spNoAgents;

  /// No description provided for @spFiles.
  ///
  /// In en, this message translates to:
  /// **'The subproject\'s files'**
  String get spFiles;

  /// No description provided for @spFrom.
  ///
  /// In en, this message translates to:
  /// **'New or existing'**
  String get spFrom;

  /// No description provided for @spNewOne.
  ///
  /// In en, this message translates to:
  /// **'A new subproject'**
  String get spNewOne;

  /// No description provided for @spBringInName.
  ///
  /// In en, this message translates to:
  /// **'Bring in the project {name}'**
  String spBringInName(String name);

  /// No description provided for @spBringInTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring the project in?'**
  String get spBringInTitle;

  /// No description provided for @spBringIn.
  ///
  /// In en, this message translates to:
  /// **'Bring in'**
  String get spBringIn;

  /// No description provided for @spAdoptConfirm.
  ///
  /// In en, this message translates to:
  /// **'The project goes into this one as a subproject: its code (with its history) into the folder, its agents under this project\'s lead, its board and conversations too. Its old folder stays as a copy. Go on?'**
  String get spAdoptConfirm;

  /// No description provided for @spName.
  ///
  /// In en, this message translates to:
  /// **'Subproject name'**
  String get spName;

  /// No description provided for @spDir.
  ///
  /// In en, this message translates to:
  /// **'Folder (optional)'**
  String get spDir;

  /// No description provided for @spDirHelp.
  ///
  /// In en, this message translates to:
  /// **'Inside the project, for example apps/shop. Empty: a new folder with the name. An existing folder works too.'**
  String get spDirHelp;

  /// No description provided for @spImage.
  ///
  /// In en, this message translates to:
  /// **'Its own sandbox image (optional)'**
  String get spImage;

  /// No description provided for @spImageHelp.
  ///
  /// In en, this message translates to:
  /// **'For tools the project\'s sandbox does not have, like ghcr.io/cirruslabs/flutter:stable. The image needs bash.'**
  String get spImageHelp;

  /// No description provided for @spCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get spCreate;

  /// No description provided for @psTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get psTitle;

  /// No description provided for @psRowHint.
  ///
  /// In en, this message translates to:
  /// **'Archive, restore, initialise git'**
  String get psRowHint;

  /// No description provided for @psNewProject.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get psNewProject;

  /// No description provided for @psLead.
  ///
  /// In en, this message translates to:
  /// **'Archive a project you are not working on: it leaves the lists, nothing is deleted, and it comes back as it was.'**
  String get psLead;

  /// No description provided for @psInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get psInUse;

  /// No description provided for @psNone.
  ///
  /// In en, this message translates to:
  /// **'No projects yet.'**
  String get psNone;

  /// No description provided for @psArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get psArchived;

  /// No description provided for @psArchivedLead.
  ///
  /// In en, this message translates to:
  /// **'Read only. «Restore» puts the project back as it was, with its automations.'**
  String get psArchivedLead;

  /// No description provided for @psNoneArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived projects.'**
  String get psNoneArchived;

  /// No description provided for @csEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get csEyebrow;

  /// No description provided for @csTitle.
  ///
  /// In en, this message translates to:
  /// **'Where the code lives'**
  String get csTitle;

  /// No description provided for @csRowHint.
  ///
  /// In en, this message translates to:
  /// **'GitHub, Gitea and the projects\' repositories'**
  String get csRowHint;

  /// No description provided for @csQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where does the code live?'**
  String get csQuestion;

  /// No description provided for @csPurpose.
  ///
  /// In en, this message translates to:
  /// **'Every project gets a private repository, ready for the agents to push to. Choose GitHub, a Gitea of your own on this computer, or both. Optional.'**
  String get csPurpose;

  /// No description provided for @csGithubTile.
  ///
  /// In en, this message translates to:
  /// **'The repositories stay on your GitHub account. It needs a token allowed to make them.'**
  String get csGithubTile;

  /// No description provided for @csGiteaTitle.
  ///
  /// In en, this message translates to:
  /// **'A Gitea of your own'**
  String get csGiteaTitle;

  /// No description provided for @csGiteaTile.
  ///
  /// In en, this message translates to:
  /// **'A small private GitHub on this computer, installed and started by Rasgeth, or the Gitea you already have.'**
  String get csGiteaTile;

  /// No description provided for @csLinked.
  ///
  /// In en, this message translates to:
  /// **'connected'**
  String get csLinked;

  /// No description provided for @csBoth.
  ///
  /// In en, this message translates to:
  /// **'With both: the code lives on Gitea, and every change is copied to GitHub by itself.'**
  String get csBoth;

  /// No description provided for @csProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects you already have'**
  String get csProjects;

  /// No description provided for @csProjectsHint.
  ///
  /// In en, this message translates to:
  /// **'New projects get their repository by themselves. For the ones made before:'**
  String get csProjectsHint;

  /// No description provided for @csSync.
  ///
  /// In en, this message translates to:
  /// **'Create the repositories now'**
  String get csSync;

  /// No description provided for @csSynced.
  ///
  /// In en, this message translates to:
  /// **'repository ready'**
  String get csSynced;

  /// No description provided for @csDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get csDone;

  /// No description provided for @csDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get csDisconnect;

  /// No description provided for @csTryAndSave.
  ///
  /// In en, this message translates to:
  /// **'Try and save'**
  String get csTryAndSave;

  /// No description provided for @csGithubHint.
  ///
  /// In en, this message translates to:
  /// **'With a token you make on GitHub: Rasgeth creates the repositories and the agents push to them. The token stays with Rasgeth, never in the agents\' boxes.'**
  String get csGithubHint;

  /// No description provided for @csGithubLinked.
  ///
  /// In en, this message translates to:
  /// **'Connected as @{login}'**
  String csGithubLinked(String login);

  /// No description provided for @csGithubStep1.
  ///
  /// In en, this message translates to:
  /// **'Open GitHub\'s page for a new token (sign in if asked):'**
  String get csGithubStep1;

  /// No description provided for @csGithubOpen.
  ///
  /// In en, this message translates to:
  /// **'New token on GitHub'**
  String get csGithubOpen;

  /// No description provided for @csGithubStep2.
  ///
  /// In en, this message translates to:
  /// **'Fill it in like this:'**
  String get csGithubStep2;

  /// No description provided for @csPermName.
  ///
  /// In en, this message translates to:
  /// **'Token name: Rasgeth'**
  String get csPermName;

  /// No description provided for @csPermExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiration: one year (Rasgeth reminds you before it ends)'**
  String get csPermExpiry;

  /// No description provided for @csPermRepos.
  ///
  /// In en, this message translates to:
  /// **'Repository access: All repositories'**
  String get csPermRepos;

  /// No description provided for @csPermList.
  ///
  /// In en, this message translates to:
  /// **'Permissions, Repositories: Administration, Contents, Issues and Pull requests set to Read and write'**
  String get csPermList;

  /// No description provided for @csGithubStep3.
  ///
  /// In en, this message translates to:
  /// **'Press Generate token at the bottom, copy it and paste it here'**
  String get csGithubStep3;

  /// No description provided for @csGithubTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'It starts with github_pat_. GitHub shows it only once.'**
  String get csGithubTokenHelp;

  /// No description provided for @csGiteaHint.
  ///
  /// In en, this message translates to:
  /// **'A Git server of your own, on this computer: the repositories stay here, and you look at them in the browser like on GitHub. Rasgeth starts it and keeps it updated. Or connect a Gitea you already have.'**
  String get csGiteaHint;

  /// No description provided for @csGiteaKind.
  ///
  /// In en, this message translates to:
  /// **'Which Gitea'**
  String get csGiteaKind;

  /// No description provided for @csGiteaKindOwn.
  ///
  /// In en, this message translates to:
  /// **'Start one here'**
  String get csGiteaKindOwn;

  /// No description provided for @csGiteaKindExisting.
  ///
  /// In en, this message translates to:
  /// **'A Gitea you already have'**
  String get csGiteaKindExisting;

  /// No description provided for @csGiteaUrl.
  ///
  /// In en, this message translates to:
  /// **'Your Gitea\'s address'**
  String get csGiteaUrl;

  /// No description provided for @csGiteaUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'As you open it in the browser, for example https://git.example.org.'**
  String get csGiteaUrlHelp;

  /// No description provided for @csGiteaExtUser.
  ///
  /// In en, this message translates to:
  /// **'Your user name on it'**
  String get csGiteaExtUser;

  /// No description provided for @csGiteaToken.
  ///
  /// In en, this message translates to:
  /// **'An access token'**
  String get csGiteaToken;

  /// No description provided for @csGiteaTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'On Gitea: Settings › Applications › Generate token, with read and write on repository and user. It stays in the keychain, never in a file.'**
  String get csGiteaTokenHelp;

  /// No description provided for @csGiteaConnect.
  ///
  /// In en, this message translates to:
  /// **'Try and connect'**
  String get csGiteaConnect;

  /// No description provided for @csGiteaLinked.
  ///
  /// In en, this message translates to:
  /// **'Connected to {url}, user {user}'**
  String csGiteaLinked(String url, String user);

  /// No description provided for @csGiteaUser.
  ///
  /// In en, this message translates to:
  /// **'Your Gitea user name'**
  String get csGiteaUser;

  /// No description provided for @csGiteaUserHelp.
  ///
  /// In en, this message translates to:
  /// **'Letters, digits, dots, dashes; for example mario.'**
  String get csGiteaUserHelp;

  /// No description provided for @csGiteaPassword.
  ///
  /// In en, this message translates to:
  /// **'A password for Gitea'**
  String get csGiteaPassword;

  /// No description provided for @csGiteaPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters. You use it to open Gitea in the browser.'**
  String get csGiteaPasswordHelp;

  /// No description provided for @csGiteaAgain.
  ///
  /// In en, this message translates to:
  /// **'The same password again'**
  String get csGiteaAgain;

  /// No description provided for @csGiteaMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are different.'**
  String get csGiteaMismatch;

  /// No description provided for @csGiteaCreate.
  ///
  /// In en, this message translates to:
  /// **'Create my Gitea'**
  String get csGiteaCreate;

  /// No description provided for @csGiteaReady.
  ///
  /// In en, this message translates to:
  /// **'Gitea is ready, user {user}'**
  String csGiteaReady(String user);

  /// No description provided for @csGiteaOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Gitea'**
  String get csGiteaOpen;

  /// No description provided for @csGiteaStop.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get csGiteaStop;

  /// No description provided for @csGiteaNameNotFound.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth cannot find {host}: the DNS it uses does not know that name. The guide «Your home services» in Settings › Access from outside home says what to add, and lets you try the name.'**
  String csGiteaNameNotFound(String host);

  /// No description provided for @csGiteaHostUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth finds {host}, but its address does not answer from here (a Tailscale address, another network?). The guide «Your home services» in Settings › Access from outside home says how to fix it.'**
  String csGiteaHostUnreachable(String host);

  /// No description provided for @csJobGitea.
  ///
  /// In en, this message translates to:
  /// **'Starting Gitea'**
  String get csJobGitea;

  /// No description provided for @csJobGiteaImage.
  ///
  /// In en, this message translates to:
  /// **'Downloading Gitea (only once)'**
  String get csJobGiteaImage;

  /// No description provided for @csJobGiteaStart.
  ///
  /// In en, this message translates to:
  /// **'Starting Gitea'**
  String get csJobGiteaStart;

  /// No description provided for @csJobAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating your account'**
  String get csJobAccount;

  /// No description provided for @csNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'not needed'**
  String get csNotNeeded;

  /// No description provided for @csJobDone.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get csJobDone;

  /// No description provided for @csJobFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again; if it happens again, the details below help whoever helps you.'**
  String get csJobFailed;

  /// No description provided for @g4SfSkillsAsk.
  ///
  /// In en, this message translates to:
  /// **'Show them to me first'**
  String get g4SfSkillsAsk;

  /// No description provided for @g4SfSkillsAskText.
  ///
  /// In en, this message translates to:
  /// **'A tested skill waits in Settings › Extensions until you approve it.'**
  String get g4SfSkillsAskText;

  /// No description provided for @g4SfSkillsAuto.
  ///
  /// In en, this message translates to:
  /// **'Install them once tested'**
  String get g4SfSkillsAuto;

  /// No description provided for @g4SfSkillsAutoText.
  ///
  /// In en, this message translates to:
  /// **'A skill whose tests pass is ready at once; you can remove it from Extensions.'**
  String get g4SfSkillsAutoText;

  /// No description provided for @g4SfGuardianTitle.
  ///
  /// In en, this message translates to:
  /// **'The guardian'**
  String get g4SfGuardianTitle;

  /// No description provided for @g4SfGuardianAskText.
  ///
  /// In en, this message translates to:
  /// **'A file in your home, a system folder, another project: the agent stops and asks you, on the web or on Telegram. Reading is always free.'**
  String get g4SfGuardianAskText;

  /// No description provided for @g4SfGuardianAutoText.
  ///
  /// In en, this message translates to:
  /// **'Agents write wherever they need without asking. The other dangers you choose below still ask.'**
  String get g4SfGuardianAutoText;

  /// No description provided for @g4SfCareful.
  ///
  /// In en, this message translates to:
  /// **'Careful'**
  String get g4SfCareful;

  /// No description provided for @g4SfCarefulText.
  ///
  /// In en, this message translates to:
  /// **'Every risky action waits for you. The safest choice, also the slowest.'**
  String get g4SfCarefulText;

  /// No description provided for @g4SfBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get g4SfBalanced;

  /// No description provided for @g4SfBalancedText.
  ///
  /// In en, this message translates to:
  /// **'You approve what cannot be undone (publishing, history, disks, passwords, changes to Rasgeth); the agents in charge approve the rest.'**
  String get g4SfBalancedText;

  /// No description provided for @g4SfFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get g4SfFree;

  /// No description provided for @g4SfFreeText.
  ///
  /// In en, this message translates to:
  /// **'The agents in charge approve almost everything; you are asked only for passwords and changes to Rasgeth itself.'**
  String get g4SfFreeText;

  /// No description provided for @g4SfPersonalize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get g4SfPersonalize;

  /// No description provided for @g4SfNoLimit.
  ///
  /// In en, this message translates to:
  /// **'no limit'**
  String get g4SfNoLimit;

  /// No description provided for @g4SfNothingPaid.
  ///
  /// In en, this message translates to:
  /// **'You use only subscriptions or local models: nothing is paid per use, so there is no spending limit to set. With subscriptions the plan\'s own limits count (shown at the top).'**
  String get g4SfNothingPaid;

  /// No description provided for @g4SfKeepForever.
  ///
  /// In en, this message translates to:
  /// **'always'**
  String get g4SfKeepForever;

  /// No description provided for @g4SfKeep365.
  ///
  /// In en, this message translates to:
  /// **'one year'**
  String get g4SfKeep365;

  /// No description provided for @g4SfKeep90.
  ///
  /// In en, this message translates to:
  /// **'three months'**
  String get g4SfKeep90;

  /// No description provided for @g4SfKeep30.
  ///
  /// In en, this message translates to:
  /// **'one month'**
  String get g4SfKeep30;

  /// No description provided for @g4SfDoneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get g4SfDoneBtn;

  /// No description provided for @g4SfLead.
  ///
  /// In en, this message translates to:
  /// **'Four decisions, each on one card. You change everything whenever you like from Settings.'**
  String get g4SfLead;

  /// No description provided for @g4SfGuardQ.
  ///
  /// In en, this message translates to:
  /// **'An agent wants to write outside its project. What happens?'**
  String get g4SfGuardQ;

  /// No description provided for @g4SfGuardAsk.
  ///
  /// In en, this message translates to:
  /// **'It asks me'**
  String get g4SfGuardAsk;

  /// No description provided for @g4SfGuardAuto.
  ///
  /// In en, this message translates to:
  /// **'I let it'**
  String get g4SfGuardAuto;

  /// No description provided for @g4SfApprTitle.
  ///
  /// In en, this message translates to:
  /// **'The approvals'**
  String get g4SfApprTitle;

  /// No description provided for @g4SfApprQ.
  ///
  /// In en, this message translates to:
  /// **'Who says yes before a risky action, like deleting or publishing?'**
  String get g4SfApprQ;

  /// No description provided for @g4SfApprCustom.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{A choice of your own: 1 thing out of {of} only you approve.} other{A choice of your own: {n} things out of {of} only you approve.}}'**
  String g4SfApprCustom(int n, String of);

  /// No description provided for @g4SfCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'What only you approve'**
  String get g4SfCustomTitle;

  /// No description provided for @g4SfCustomLead.
  ///
  /// In en, this message translates to:
  /// **'Before these actions an agent asks. On: only you can approve it. Off: the agent guiding it can say yes too ({god} or the head of the project).'**
  String g4SfCustomLead(String god);

  /// No description provided for @g4SfBackTo.
  ///
  /// In en, this message translates to:
  /// **'Back to {preset}'**
  String g4SfBackTo(String preset);

  /// No description provided for @g4SfBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'The spending limit'**
  String get g4SfBudgetTitle;

  /// No description provided for @g4SfBudgetQ.
  ///
  /// In en, this message translates to:
  /// **'How much can Rasgeth spend at most with your API keys?'**
  String get g4SfBudgetQ;

  /// No description provided for @g4SfBudgetQFree.
  ///
  /// In en, this message translates to:
  /// **'With API keys a limit stops the agents before they spend too much.'**
  String get g4SfBudgetQFree;

  /// No description provided for @g4SfBudgetOther.
  ///
  /// In en, this message translates to:
  /// **'other'**
  String get g4SfBudgetOther;

  /// No description provided for @g4SfBudgetSay.
  ///
  /// In en, this message translates to:
  /// **'At \${usd} the agents stop and tell you; you raise it whenever you like.'**
  String g4SfBudgetSay(String usd);

  /// No description provided for @g4SfBudgetNone.
  ///
  /// In en, this message translates to:
  /// **'No limit: mind the pay-per-use keys.'**
  String get g4SfBudgetNone;

  /// No description provided for @g4SfSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'The agents\' skills'**
  String get g4SfSkillsTitle;

  /// No description provided for @g4SfSkillsQ.
  ///
  /// In en, this message translates to:
  /// **'After a hard problem an agent can save how it solved it, for everybody. Do I install them by myself?'**
  String get g4SfSkillsQ;

  /// No description provided for @g4SfSkillsTools.
  ///
  /// In en, this message translates to:
  /// **'The tools that run code always wait for you.'**
  String get g4SfSkillsTools;

  /// No description provided for @g4SfWhereAgents.
  ///
  /// In en, this message translates to:
  /// **'The agents work right on this computer, in the project\'s folder: the guardian checks every command that goes outside it.'**
  String get g4SfWhereAgents;

  /// No description provided for @g4SfKeepFor.
  ///
  /// In en, this message translates to:
  /// **'Keep the conversations for'**
  String get g4SfKeepFor;

  /// No description provided for @g4TlSection.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get g4TlSection;

  /// No description provided for @g4TlQ.
  ///
  /// In en, this message translates to:
  /// **'Which tools do the agents get?'**
  String get g4TlQ;

  /// No description provided for @g4TlLead.
  ///
  /// In en, this message translates to:
  /// **'Every tool is described to the model in every message, and that costs tokens. Switch off the ones you do not need: for every agent here, or for one agent from its window, tab Tools.'**
  String get g4TlLead;

  /// No description provided for @g4TlNewOnly.
  ///
  /// In en, this message translates to:
  /// **'Changes apply from new conversations: the ones already open keep their tools.'**
  String get g4TlNewOnly;

  /// No description provided for @g4TlTotal.
  ///
  /// In en, this message translates to:
  /// **'About {n} tokens in every message'**
  String g4TlTotal(String n);

  /// No description provided for @g4TlSaved.
  ///
  /// In en, this message translates to:
  /// **'Switched off: {n} tokens saved in every message'**
  String g4TlSaved(String n);

  /// No description provided for @g4TlNoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing switched off'**
  String get g4TlNoneSaved;

  /// No description provided for @g4TlWeight.
  ///
  /// In en, this message translates to:
  /// **'about {n} tokens in every message'**
  String g4TlWeight(String n);

  /// No description provided for @g4TlNeeded.
  ///
  /// In en, this message translates to:
  /// **'Always needed: {why}'**
  String g4TlNeeded(String why);

  /// No description provided for @g4TlLoading.
  ///
  /// In en, this message translates to:
  /// **'Weighing the tools…'**
  String get g4TlLoading;

  /// No description provided for @g4TlSearch.
  ///
  /// In en, this message translates to:
  /// **'Find a tool: name, command or what it does'**
  String get g4TlSearch;

  /// No description provided for @g4TlNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No tool for «{q}».'**
  String g4TlNoMatch(String q);

  /// No description provided for @g4TlError.
  ///
  /// In en, this message translates to:
  /// **'The tools could not be read: {error}'**
  String g4TlError(String error);

  /// No description provided for @g4TlHowMany.
  ///
  /// In en, this message translates to:
  /// **'{on} of {all} on'**
  String g4TlHowMany(String all, String on);

  /// No description provided for @g4TlExceptOn.
  ///
  /// In en, this message translates to:
  /// **'Still on for: {names} (their own choice)'**
  String g4TlExceptOn(String names);

  /// No description provided for @g4TlExceptOff.
  ///
  /// In en, this message translates to:
  /// **'Off for: {names} (their own choice)'**
  String g4TlExceptOff(String names);

  /// No description provided for @g4TlExceptReset.
  ///
  /// In en, this message translates to:
  /// **'As for every agent'**
  String get g4TlExceptReset;

  /// No description provided for @g4CmSection.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get g4CmSection;

  /// No description provided for @g4CmOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get g4CmOneDay;

  /// No description provided for @g4CmDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String g4CmDays(String n);

  /// No description provided for @g4CmHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String g4CmHours(String n);

  /// No description provided for @g4CmOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 h'**
  String get g4CmOneHour;

  /// No description provided for @g4CmMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String g4CmMinutes(String n);

  /// No description provided for @g4CmNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get g4CmNoLimit;

  /// No description provided for @g4CmPageQ.
  ///
  /// In en, this message translates to:
  /// **'How long can the agents\' commands run?'**
  String get g4CmPageQ;

  /// No description provided for @g4CmPageLead.
  ///
  /// In en, this message translates to:
  /// **'The agents run commands on this computer: some end at once, others (a development server, a watcher, a long build) keep going in the background while the agent does other things.'**
  String get g4CmPageLead;

  /// No description provided for @g4CmBgTitle.
  ///
  /// In en, this message translates to:
  /// **'Commands in the background'**
  String get g4CmBgTitle;

  /// No description provided for @g4CmBgLead.
  ///
  /// In en, this message translates to:
  /// **'Servers, watchers and long builds. You see them in the strip above the message box and can stop them there.'**
  String get g4CmBgLead;

  /// No description provided for @g4CmAtOnce.
  ///
  /// In en, this message translates to:
  /// **'At once in one conversation'**
  String get g4CmAtOnce;

  /// No description provided for @g4CmAtOnceHelp.
  ///
  /// In en, this message translates to:
  /// **'When the limit is reached, the agent has to stop one before starting another.'**
  String get g4CmAtOnceHelp;

  /// No description provided for @g4CmAtOnceWarn.
  ///
  /// In en, this message translates to:
  /// **'No limit: an agent can start as many as it likes. Each one uses processor and memory; if the computer slows down, stop some from the strip.'**
  String get g4CmAtOnceWarn;

  /// No description provided for @g4CmLong.
  ///
  /// In en, this message translates to:
  /// **'How long one can run'**
  String get g4CmLong;

  /// No description provided for @g4CmLongHelp.
  ///
  /// In en, this message translates to:
  /// **'Past this time the command is stopped by itself.'**
  String get g4CmLongHelp;

  /// No description provided for @g4CmLongWarn.
  ///
  /// In en, this message translates to:
  /// **'No limit: a command runs until you or the agent stop it, even for days. Good for a development server; remember to stop what you no longer need.'**
  String get g4CmLongWarn;

  /// No description provided for @g4CmLog.
  ///
  /// In en, this message translates to:
  /// **'How big its log can grow'**
  String get g4CmLog;

  /// No description provided for @g4CmLogHelp.
  ///
  /// In en, this message translates to:
  /// **'Every line is kept with its time. Past this size the oldest half goes.'**
  String get g4CmLogHelp;

  /// No description provided for @g4CmLogWarn.
  ///
  /// In en, this message translates to:
  /// **'No limit: a command that writes a lot can fill the disk over time. The logs are in the project\'s .redgiant/commands folder.'**
  String get g4CmLogWarn;

  /// No description provided for @g4CmBashTitle.
  ///
  /// In en, this message translates to:
  /// **'Ordinary commands'**
  String get g4CmBashTitle;

  /// No description provided for @g4CmBashLead.
  ///
  /// In en, this message translates to:
  /// **'Those the agent waits for before going on (tests, an install, a conversion).'**
  String get g4CmBashLead;

  /// No description provided for @g4CmBash.
  ///
  /// In en, this message translates to:
  /// **'Longest wait'**
  String get g4CmBash;

  /// No description provided for @g4CmBashHelp.
  ///
  /// In en, this message translates to:
  /// **'The agent can ask for less; never for more. For longer work it uses the background.'**
  String get g4CmBashHelp;

  /// No description provided for @g4CmStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps in one turn'**
  String get g4CmStepsTitle;

  /// No description provided for @g4CmStepsLead.
  ///
  /// In en, this message translates to:
  /// **'In one turn an agent thinks, uses a tool, reads the result and goes on. Past the limit it stops and tells you where it got to; a «Continue» button under its message lets it go on.'**
  String get g4CmStepsLead;

  /// No description provided for @g4CmSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps at most'**
  String get g4CmSteps;

  /// No description provided for @g4CmStepsHelp.
  ///
  /// In en, this message translates to:
  /// **'One step is one call to the model. Default: no limit in your conversations with the agents; {n} for automations and tasks, which nobody watches. A number or «No limit» counts for every turn.'**
  String g4CmStepsHelp(String n);

  /// No description provided for @g4CmStepsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get g4CmStepsDefault;

  /// No description provided for @g4CmStepsWarn.
  ///
  /// In en, this message translates to:
  /// **'No limit, automations and tasks included: an agent can work for hours in one turn. Only the budgets stop it, so keep one set (Settings, Budgets) if the model costs money.'**
  String get g4CmStepsWarn;

  /// No description provided for @g4CmDefaults.
  ///
  /// In en, this message translates to:
  /// **'Back to the defaults'**
  String get g4CmDefaults;

  /// No description provided for @g4CmSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: it counts from the next command and the next message.'**
  String get g4CmSaved;

  /// No description provided for @g4CmUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get g4CmUndo;

  /// No description provided for @g4CmUndone.
  ///
  /// In en, this message translates to:
  /// **'Undone: the previous values are back.'**
  String get g4CmUndone;

  /// No description provided for @g4RqSection.
  ///
  /// In en, this message translates to:
  /// **'Requests to you'**
  String get g4RqSection;

  /// No description provided for @g4RqPageQ.
  ///
  /// In en, this message translates to:
  /// **'When an agent needs you'**
  String get g4RqPageQ;

  /// No description provided for @g4RqPageLead.
  ///
  /// In en, this message translates to:
  /// **'Agents ask before risky actions, ask you questions, propose plans, ask for a tool or a key. Choose whether they ask you, and how long they wait for you.'**
  String get g4RqPageLead;

  /// No description provided for @g4RqModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask me or not'**
  String get g4RqModeTitle;

  /// No description provided for @g4RqModeQ.
  ///
  /// In en, this message translates to:
  /// **'Do you want to answer the agents\' requests yourself?'**
  String get g4RqModeQ;

  /// No description provided for @g4RqModeAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask me'**
  String get g4RqModeAsk;

  /// No description provided for @g4RqModeClassifier.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ask me anything'**
  String get g4RqModeClassifier;

  /// No description provided for @g4RqAlwaysYou.
  ///
  /// In en, this message translates to:
  /// **'Even with «Don\'t ask me anything», the truly dangerous requests always reach you, everywhere: deletions for good, system files, secrets leaving, real payments and Rasgeth\'s own protections.'**
  String get g4RqAlwaysYou;

  /// No description provided for @g4RqModeAskText.
  ///
  /// In en, this message translates to:
  /// **'Requests reach you everywhere: here and on the chats you connected. Answer where it suits you: the first answer counts, and the other copies close by themselves.'**
  String get g4RqModeAskText;

  /// No description provided for @g4RqModeClassifierText.
  ///
  /// In en, this message translates to:
  /// **'Nothing reaches you: the classifier decides, a model you choose. It reads each request with the conversation and writes why it decided so. Only the truly dangerous things (listed below) still reach you, everywhere.'**
  String get g4RqModeClassifierText;

  /// No description provided for @g4RqModeClassifierWarn.
  ///
  /// In en, this message translates to:
  /// **'The classifier can be wrong, and each decision costs a small request to its model.'**
  String get g4RqModeClassifierWarn;

  /// No description provided for @g4RqTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to answer'**
  String get g4RqTimeTitle;

  /// No description provided for @g4RqTimeQ.
  ///
  /// In en, this message translates to:
  /// **'How long should an agent wait for your answer?'**
  String get g4RqTimeQ;

  /// No description provided for @g4RqTimeQSpecial.
  ///
  /// In en, this message translates to:
  /// **'How long do the truly dangerous things wait for your answer?'**
  String get g4RqTimeQSpecial;

  /// No description provided for @g4RqAfterSpecialText.
  ///
  /// In en, this message translates to:
  /// **'If you do not answer within {time}, it is a no.'**
  String g4RqAfterSpecialText(String time);

  /// No description provided for @g4RqTimeNoneSpecial.
  ///
  /// In en, this message translates to:
  /// **'They wait as long as it takes: the agent stays still until you answer.'**
  String get g4RqTimeNoneSpecial;

  /// No description provided for @g4RqSpecialTitle.
  ///
  /// In en, this message translates to:
  /// **'The truly dangerous things'**
  String get g4RqSpecialTitle;

  /// No description provided for @g4RqSpecialQ.
  ///
  /// In en, this message translates to:
  /// **'What always reaches you, wherever you are?'**
  String get g4RqSpecialQ;

  /// No description provided for @g4RqSpecialText.
  ///
  /// In en, this message translates to:
  /// **'Only these. When an agent is about to do one of them it stops and waits for you: the request reaches you here and on the chats you connected, also with «Don\'t ask me anything», and the classifier never decides it.'**
  String get g4RqSpecialText;

  /// No description provided for @g4RqSpecialNot.
  ///
  /// In en, this message translates to:
  /// **'Everyday work is not on this list: sending code with git push, an ordinary message or email, putting a site online, changing the project\'s files, using a key from the keychain for its own site. Those follow your choice above.'**
  String get g4RqSpecialNot;

  /// No description provided for @g4RqCriticalExamples.
  ///
  /// In en, this message translates to:
  /// **'For example:'**
  String get g4RqCriticalExamples;

  /// No description provided for @g4RqTimeNone.
  ///
  /// In en, this message translates to:
  /// **'The agent waits as long as it takes. Requests to switch on a tool or use a key still end after 15 and 10 minutes.'**
  String get g4RqTimeNone;

  /// No description provided for @g4RqAfterQ.
  ///
  /// In en, this message translates to:
  /// **'If you do not answer within {time}:'**
  String g4RqAfterQ(String time);

  /// No description provided for @g4RqAfterNo.
  ///
  /// In en, this message translates to:
  /// **'It is a no'**
  String get g4RqAfterNo;

  /// No description provided for @g4RqAfterClassifier.
  ///
  /// In en, this message translates to:
  /// **'The classifier decides'**
  String get g4RqAfterClassifier;

  /// No description provided for @g4RqAfterNoText.
  ///
  /// In en, this message translates to:
  /// **'An approval nobody gives is always a no. To a question the agent goes on with its best guess and tells you which.'**
  String get g4RqAfterNoText;

  /// No description provided for @g4RqAfterClassifierText.
  ///
  /// In en, this message translates to:
  /// **'When the time runs out the classifier decides in your place, as with «Don\'t ask me anything». The truly dangerous things are a no instead.'**
  String get g4RqAfterClassifierText;

  /// No description provided for @g4RqClassifierTitle.
  ///
  /// In en, this message translates to:
  /// **'The classifier'**
  String get g4RqClassifierTitle;

  /// No description provided for @g4RqClassifierQ.
  ///
  /// In en, this message translates to:
  /// **'Which model decides for you?'**
  String get g4RqClassifierQ;

  /// No description provided for @g4RqClassifierModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get g4RqClassifierModel;

  /// No description provided for @g4RqClassifierDefault.
  ///
  /// In en, this message translates to:
  /// **'The light model ({model})'**
  String g4RqClassifierDefault(String model);

  /// No description provided for @g4RqClassifierHow.
  ///
  /// In en, this message translates to:
  /// **'It reads what the agent asks, its job and the last messages of the conversation; it answers yes or no with a reason, or picks an answer to a question. When in doubt it says no; if it fails, it is a no.'**
  String get g4RqClassifierHow;

  /// No description provided for @g4RqNoModel.
  ///
  /// In en, this message translates to:
  /// **'none connected'**
  String get g4RqNoModel;

  /// No description provided for @g4RqSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: it counts from the next request.'**
  String get g4RqSaved;

  /// No description provided for @g4RqDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Decided without you'**
  String get g4RqDoneTitle;

  /// No description provided for @g4RqDoneLead.
  ///
  /// In en, this message translates to:
  /// **'Every request the classifier decided, or that ended because nobody answered in time, newest first.'**
  String get g4RqDoneLead;

  /// No description provided for @g4RqDoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'No decision taken without you yet.'**
  String get g4RqDoneEmpty;

  /// No description provided for @g4RqOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open the conversation'**
  String get g4RqOpenChat;

  /// No description provided for @g4RqByModel.
  ///
  /// In en, this message translates to:
  /// **'Classifier ({model}):'**
  String g4RqByModel(String model);

  /// No description provided for @g4RqByClassifier.
  ///
  /// In en, this message translates to:
  /// **'Classifier:'**
  String get g4RqByClassifier;

  /// No description provided for @g4RqByTimeout.
  ///
  /// In en, this message translates to:
  /// **'Time ran out:'**
  String get g4RqByTimeout;

  /// No description provided for @g4RqDecisionAllow.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get g4RqDecisionAllow;

  /// No description provided for @g4RqDecisionDeny.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get g4RqDecisionDeny;

  /// No description provided for @g4RqDecisionAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get g4RqDecisionAnswered;

  /// No description provided for @g4RqDecisionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get g4RqDecisionBlocked;

  /// No description provided for @g4RqKindApproval.
  ///
  /// In en, this message translates to:
  /// **'action'**
  String get g4RqKindApproval;

  /// No description provided for @g4RqKindQuestion.
  ///
  /// In en, this message translates to:
  /// **'question'**
  String get g4RqKindQuestion;

  /// No description provided for @g4RqKindPlan.
  ///
  /// In en, this message translates to:
  /// **'plan'**
  String get g4RqKindPlan;

  /// No description provided for @g4RqKindTool.
  ///
  /// In en, this message translates to:
  /// **'tool'**
  String get g4RqKindTool;

  /// No description provided for @g4RqKindCredential.
  ///
  /// In en, this message translates to:
  /// **'key'**
  String get g4RqKindCredential;

  /// No description provided for @g4RqKindAutomation.
  ///
  /// In en, this message translates to:
  /// **'automation'**
  String get g4RqKindAutomation;

  /// No description provided for @g4SfSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: it counts from the next action of the agents.'**
  String get g4SfSaved;

  /// No description provided for @g4SfCustomOn.
  ///
  /// In en, this message translates to:
  /// **'Only you approve it'**
  String get g4SfCustomOn;

  /// No description provided for @g4CmAtWorkLead.
  ///
  /// In en, this message translates to:
  /// **'Saved at once, for the turns that start from now.'**
  String get g4CmAtWorkLead;

  /// No description provided for @g4RulesHub.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get g4RulesHub;

  /// No description provided for @g4TlExtLead.
  ///
  /// In en, this message translates to:
  /// **'Installed from Extensions (magic integrations, agents\' proposals, your own): every agent has them. Change or remove them there.'**
  String get g4TlExtLead;

  /// No description provided for @g4TlExtTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools of the extensions'**
  String get g4TlExtTitle;

  /// No description provided for @g4SfTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety and costs'**
  String get g4SfTitle;

  /// No description provided for @g4GenAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get g4GenAccount;

  /// No description provided for @g4GenAgentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Its instructions'**
  String get g4GenAgentInstructions;

  /// No description provided for @g4GenAgentLangAll.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get g4GenAgentLangAll;

  /// No description provided for @g4GenAgentLangChange.
  ///
  /// In en, this message translates to:
  /// **'change'**
  String get g4GenAgentLangChange;

  /// No description provided for @g4GenAgentLangCommon.
  ///
  /// In en, this message translates to:
  /// **'Most common'**
  String get g4GenAgentLangCommon;

  /// No description provided for @g4GenAgentLangHelp.
  ///
  /// In en, this message translates to:
  /// **'What every agent, the Chat and the shared memory write in. New conversations use it; open ones keep theirs.'**
  String get g4GenAgentLangHelp;

  /// No description provided for @g4GenAgentLangNone.
  ///
  /// In en, this message translates to:
  /// **'No language matches «{q}».'**
  String g4GenAgentLangNone(String q);

  /// No description provided for @g4GenAgentLangSearch.
  ///
  /// In en, this message translates to:
  /// **'Search a language'**
  String get g4GenAgentLangSearch;

  /// No description provided for @g4GenAgentLangSub.
  ///
  /// In en, this message translates to:
  /// **'The agents reply in it from the next conversation.'**
  String get g4GenAgentLangSub;

  /// No description provided for @g4GenAgentLangTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents\' language'**
  String get g4GenAgentLangTitle;

  /// No description provided for @g4GenAgents.
  ///
  /// In en, this message translates to:
  /// **'For every agent'**
  String get g4GenAgents;

  /// No description provided for @g4GenAgentsLead.
  ///
  /// In en, this message translates to:
  /// **'What every agent reads, and who tries again a task an agent gives up on.'**
  String get g4GenAgentsLead;

  /// No description provided for @g4GenAlreadySet.
  ///
  /// In en, this message translates to:
  /// **'already set'**
  String get g4GenAlreadySet;

  /// No description provided for @g4GenBackupNone.
  ///
  /// In en, this message translates to:
  /// **'None: a task given up on stays so'**
  String get g4GenBackupNone;

  /// No description provided for @g4GenBackupText.
  ///
  /// In en, this message translates to:
  /// **'A task an agent gives up on is tried once more by this model, in a new conversation.'**
  String get g4GenBackupText;

  /// No description provided for @g4GenBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup model for tasks'**
  String get g4GenBackupTitle;

  /// No description provided for @g4GenCare.
  ///
  /// In en, this message translates to:
  /// **'Updates and diagnostics'**
  String get g4GenCare;

  /// No description provided for @g4GenCareLead.
  ///
  /// In en, this message translates to:
  /// **'Whether a newer Rasgeth is out, and a log to send when something goes wrong.'**
  String get g4GenCareLead;

  /// No description provided for @g4GenCloudPrivacy.
  ///
  /// In en, this message translates to:
  /// **'With {name}, what you say after the wake word goes to {name} through Rasgeth\'s server; the wake word itself is still heard only in this page.'**
  String g4GenCloudPrivacy(String name);

  /// No description provided for @g4GenDebugClear.
  ///
  /// In en, this message translates to:
  /// **'Delete the logs'**
  String get g4GenDebugClear;

  /// No description provided for @g4GenDebugClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete every log kept?'**
  String get g4GenDebugClearConfirm;

  /// No description provided for @g4GenDebugDownload.
  ///
  /// In en, this message translates to:
  /// **'Download the logs'**
  String get g4GenDebugDownload;

  /// No description provided for @g4GenDebugForced.
  ///
  /// In en, this message translates to:
  /// **'Turned on by the server\'s settings (REDGIANT_DEBUG=1).'**
  String get g4GenDebugForced;

  /// No description provided for @g4GenDebugHelp.
  ///
  /// In en, this message translates to:
  /// **'Debug mode keeps a detailed log of everything Rasgeth does: each step of starting a model with its times, the local engine\'s own messages, the requests, what the Windows program does. Turn it on when something is slow or goes wrong, repeat it, then download the logs and send them. It writes a lot (at most 300 MB, the oldest go first) and never writes passwords or keys.'**
  String get g4GenDebugHelp;

  /// No description provided for @g4GenDebugSize.
  ///
  /// In en, this message translates to:
  /// **'Logs kept: {size} in {files} files.'**
  String g4GenDebugSize(String size, String files);

  /// No description provided for @g4GenDebugSwitch.
  ///
  /// In en, this message translates to:
  /// **'Debug mode'**
  String get g4GenDebugSwitch;

  /// No description provided for @g4GenDebugText.
  ///
  /// In en, this message translates to:
  /// **'Everything Rasgeth does, written in a log you can download and send.'**
  String get g4GenDebugText;

  /// No description provided for @g4GenDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get g4GenDebugTitle;

  /// No description provided for @g4GenDraftDefaultUsed.
  ///
  /// In en, this message translates to:
  /// **'These are the built-in instructions, with what you wrote. Every tool stays as for the other agents.'**
  String get g4GenDraftDefaultUsed;

  /// No description provided for @g4GenDraftFailed.
  ///
  /// In en, this message translates to:
  /// **'{god} could not write them ({why}). Here are the built-in ones, with what you wrote.'**
  String g4GenDraftFailed(String god, String why);

  /// No description provided for @g4GenDraftLead.
  ///
  /// In en, this message translates to:
  /// **'{god} writes them from the built-in ones, fitted to what you wrote and to its settings, and chooses the tools it needs. Read, change what you like, then create it.'**
  String g4GenDraftLead(String god);

  /// No description provided for @g4GenDraftRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Write them again'**
  String get g4GenDraftRegenerate;

  /// No description provided for @g4GenDraftToolOnDefault.
  ///
  /// In en, this message translates to:
  /// **'useful for its job'**
  String get g4GenDraftToolOnDefault;

  /// No description provided for @g4GenDraftToolsAllOn.
  ///
  /// In en, this message translates to:
  /// **'Every tool on, as for the other agents.'**
  String get g4GenDraftToolsAllOn;

  /// No description provided for @g4GenDraftToolsLikeOthers.
  ///
  /// In en, this message translates to:
  /// **'All as for the other agents'**
  String get g4GenDraftToolsLikeOthers;

  /// No description provided for @g4GenDraftToolsSaved.
  ///
  /// In en, this message translates to:
  /// **'{n} switched off, saving about {tokens} tokens on every message. If it needs one later, it asks you.'**
  String g4GenDraftToolsSaved(String n, String tokens);

  /// No description provided for @g4GenDraftToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Its tools'**
  String get g4GenDraftToolsTitle;

  /// No description provided for @g4GenDraftToolTokens.
  ///
  /// In en, this message translates to:
  /// **'{tokens} tokens'**
  String g4GenDraftToolTokens(String tokens);

  /// No description provided for @g4GenDraftUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use the built-in ones'**
  String get g4GenDraftUseDefault;

  /// No description provided for @g4GenDraftWorking.
  ///
  /// In en, this message translates to:
  /// **'{god} is writing its instructions...'**
  String g4GenDraftWorking(String god);

  /// No description provided for @g4GenHasKey.
  ///
  /// In en, this message translates to:
  /// **'Key ready'**
  String get g4GenHasKey;

  /// No description provided for @g4GenImagesHelp.
  ///
  /// In en, this message translates to:
  /// **'An OpenAI key lets agents draw pictures; it costs money for each picture.'**
  String get g4GenImagesHelp;

  /// No description provided for @g4GenImagesKey.
  ///
  /// In en, this message translates to:
  /// **'OpenAI key for pictures (generate_image)'**
  String get g4GenImagesKey;

  /// No description provided for @g4GenImagesModel.
  ///
  /// In en, this message translates to:
  /// **'Picture model'**
  String get g4GenImagesModel;

  /// No description provided for @g4GenImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get g4GenImagesTitle;

  /// No description provided for @g4GenInstrText.
  ///
  /// In en, this message translates to:
  /// **'What every agent should know or do: how you like answers, your conventions, what to avoid.'**
  String get g4GenInstrText;

  /// No description provided for @g4GenInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'What every agent should know or do, whoever it is: how you like answers, your conventions, things to avoid. They are added to each agent\'s own instructions (those are in each agent\'s card under Agents).'**
  String get g4GenInstructionsHint;

  /// No description provided for @g4GenInstructionsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: answer in Italian; code and comments in English; never push without asking.'**
  String get g4GenInstructionsPlaceholder;

  /// No description provided for @g4GenInstructionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: conversations started from now on follow them.'**
  String get g4GenInstructionsSaved;

  /// No description provided for @g4GenInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Instructions for every agent'**
  String get g4GenInstructionsTitle;

  /// No description provided for @g4GenInUse.
  ///
  /// In en, this message translates to:
  /// **'in use'**
  String get g4GenInUse;

  /// No description provided for @g4GenKeyChange.
  ///
  /// In en, this message translates to:
  /// **'Use another key'**
  String get g4GenKeyChange;

  /// No description provided for @g4GenKeyGet.
  ///
  /// In en, this message translates to:
  /// **'Get a {name} key'**
  String g4GenKeyGet(String name);

  /// No description provided for @g4GenKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Kept in the keychain, encrypted; it never reaches this page again.'**
  String get g4GenKeyHelp;

  /// No description provided for @g4GenKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} key'**
  String g4GenKeyLabel(String name);

  /// No description provided for @g4GenKeyLinked.
  ///
  /// In en, this message translates to:
  /// **'Uses the {name} key you already gave (chat, extensions or voice).'**
  String g4GenKeyLinked(String name);

  /// No description provided for @g4GenLead.
  ///
  /// In en, this message translates to:
  /// **'Its look and language, then what every agent shares and the extra services. Each square opens its window; the lit ones are set.'**
  String get g4GenLead;

  /// No description provided for @g4GenLocked.
  ///
  /// In en, this message translates to:
  /// **'set by the environment'**
  String get g4GenLocked;

  /// No description provided for @g4GenLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get g4GenLogout;

  /// No description provided for @g4GenModelCloses.
  ///
  /// In en, this message translates to:
  /// **'The provider closes this model on {date}: choose another one before then.'**
  String g4GenModelCloses(String date);

  /// No description provided for @g4GenNews.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get g4GenNews;

  /// No description provided for @g4GenNewsText.
  ///
  /// In en, this message translates to:
  /// **'Everything each release brought, newest first: also what you missed.'**
  String get g4GenNewsText;

  /// No description provided for @g4GenNewsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String g4GenNewsVersion(String version);

  /// No description provided for @g4GenOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get g4GenOn;

  /// No description provided for @g4GenOwnSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth can run its own search engine (SearXNG): free, no keys, and every model can search the web with it, local ones too.'**
  String get g4GenOwnSearchHint;

  /// No description provided for @g4GenOwnSearchOn.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth\'s search engine is on: every agent and the Chat search the web with it.'**
  String get g4GenOwnSearchOn;

  /// No description provided for @g4GenOwnSearchStart.
  ///
  /// In en, this message translates to:
  /// **'Start Rasgeth\'s search engine'**
  String get g4GenOwnSearchStart;

  /// No description provided for @g4GenOwnSearchStop.
  ///
  /// In en, this message translates to:
  /// **'Switch it off'**
  String get g4GenOwnSearchStop;

  /// No description provided for @g4GenPriceKchars.
  ///
  /// In en, this message translates to:
  /// **'{usd} per 1000 characters'**
  String g4GenPriceKchars(String usd);

  /// No description provided for @g4GenPriceMinute.
  ///
  /// In en, this message translates to:
  /// **'about {usd} a minute'**
  String g4GenPriceMinute(String usd);

  /// No description provided for @g4GenPriceMtokens.
  ///
  /// In en, this message translates to:
  /// **'{usd} per million audio tokens'**
  String g4GenPriceMtokens(String usd);

  /// No description provided for @g4GenQ.
  ///
  /// In en, this message translates to:
  /// **'How do you want Rasgeth?'**
  String get g4GenQ;

  /// No description provided for @g4GenRefineAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get g4GenRefineAfter;

  /// No description provided for @g4GenRefineBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get g4GenRefineBefore;

  /// No description provided for @g4GenRefineCount.
  ///
  /// In en, this message translates to:
  /// **'{del} words out, {add} words in'**
  String g4GenRefineCount(String del, String add);

  /// No description provided for @g4GenRefineGodModel.
  ///
  /// In en, this message translates to:
  /// **'{god}\'s model'**
  String g4GenRefineGodModel(String god);

  /// No description provided for @g4GenRefineLegendAdd.
  ///
  /// In en, this message translates to:
  /// **'what is new'**
  String get g4GenRefineLegendAdd;

  /// No description provided for @g4GenRefineLegendDel.
  ///
  /// In en, this message translates to:
  /// **'what goes away'**
  String get g4GenRefineLegendDel;

  /// No description provided for @g4GenRefineModel.
  ///
  /// In en, this message translates to:
  /// **'The model that writes'**
  String get g4GenRefineModel;

  /// No description provided for @g4GenRewriteGo.
  ///
  /// In en, this message translates to:
  /// **'Rewrite'**
  String get g4GenRewriteGo;

  /// No description provided for @g4GenRewriteLead.
  ///
  /// In en, this message translates to:
  /// **'{god} starts from the instructions in the field and fits them to what the agent does now. You see the changes first.'**
  String g4GenRewriteLead(String god);

  /// No description provided for @g4GenRewriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewrite for the new job'**
  String get g4GenRewriteTitle;

  /// No description provided for @g4GenRewriteYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, rewrite them'**
  String get g4GenRewriteYes;

  /// No description provided for @g4GenSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get g4GenSaved;

  /// No description provided for @g4GenSearchDocs.
  ///
  /// In en, this message translates to:
  /// **'How to install SearXNG yourself'**
  String get g4GenSearchDocs;

  /// No description provided for @g4GenSearchHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How to set up {name}'**
  String g4GenSearchHowTitle(String name);

  /// No description provided for @g4GenSearchKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get g4GenSearchKey;

  /// No description provided for @g4GenSearchKeyKept.
  ///
  /// In en, this message translates to:
  /// **'A key is saved: leave empty to keep it.'**
  String get g4GenSearchKeyKept;

  /// No description provided for @g4GenSearchKeyPage.
  ///
  /// In en, this message translates to:
  /// **'Open the page of {name}\'s keys'**
  String g4GenSearchKeyPage(String name);

  /// No description provided for @g4GenSearchSaved.
  ///
  /// In en, this message translates to:
  /// **'From now on the models that cannot search by themselves use {name}.'**
  String g4GenSearchSaved(String name);

  /// No description provided for @g4GenSearchText.
  ///
  /// In en, this message translates to:
  /// **'Lets every agent and the Chat look things up on the web.'**
  String get g4GenSearchText;

  /// No description provided for @g4GenSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Web search'**
  String get g4GenSearchTitle;

  /// No description provided for @g4GenSearchTried.
  ///
  /// In en, this message translates to:
  /// **'It works: {n} results, the first «{first}».'**
  String g4GenSearchTried(String n, String first);

  /// No description provided for @g4GenSearchTriedEmpty.
  ///
  /// In en, this message translates to:
  /// **'It answered, but with no results for the test search.'**
  String get g4GenSearchTriedEmpty;

  /// No description provided for @g4GenSearchTry.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get g4GenSearchTry;

  /// No description provided for @g4GenSearchUrl.
  ///
  /// In en, this message translates to:
  /// **'Address of the SearXNG server'**
  String get g4GenSearchUrl;

  /// No description provided for @g4GenSearchUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'The address where your SearXNG answers.'**
  String get g4GenSearchUrlHelp;

  /// No description provided for @g4GenSearchUse.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get g4GenSearchUse;

  /// No description provided for @g4GenSearchWho.
  ///
  /// In en, this message translates to:
  /// **'Claude and the subscriptions search by themselves. The others (local models, OpenAI-compatible keys) use the service chosen here.'**
  String get g4GenSearchWho;

  /// No description provided for @g4GenServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get g4GenServices;

  /// No description provided for @g4GenServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Extras the agents can use. Each one works only if you set it; leaving a field empty switches it off.'**
  String get g4GenServicesHint;

  /// No description provided for @g4GenSttCloudHelp.
  ///
  /// In en, this message translates to:
  /// **'In the cloud: {models}. From {price}.'**
  String g4GenSttCloudHelp(String models, String price);

  /// No description provided for @g4GenSttCompatible.
  ///
  /// In en, this message translates to:
  /// **'Another compatible service'**
  String get g4GenSttCompatible;

  /// No description provided for @g4GenSttCompatibleHelp.
  ///
  /// In en, this message translates to:
  /// **'Any service with the OpenAI transcription API (speaches, whisper.cpp\'s server…), at its address.'**
  String get g4GenSttCompatibleHelp;

  /// No description provided for @g4GenSttLocal.
  ///
  /// In en, this message translates to:
  /// **'On this computer'**
  String get g4GenSttLocal;

  /// No description provided for @g4GenSttLocalHelp.
  ///
  /// In en, this message translates to:
  /// **'whisper.cpp, started by Rasgeth: free, nothing leaves the house.'**
  String get g4GenSttLocalHelp;

  /// No description provided for @g4GenSttRemote.
  ///
  /// In en, this message translates to:
  /// **'whisper on another computer'**
  String get g4GenSttRemote;

  /// No description provided for @g4GenSttRemoteHelp.
  ///
  /// In en, this message translates to:
  /// **'whisper-asr-webservice at its address, for a computer with a graphics card.'**
  String get g4GenSttRemoteHelp;

  /// No description provided for @g4GenTitle.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get g4GenTitle;

  /// No description provided for @g4GenTrying.
  ///
  /// In en, this message translates to:
  /// **'Trying the model…'**
  String get g4GenTrying;

  /// No description provided for @g4GenUiLangHelp.
  ///
  /// In en, this message translates to:
  /// **'The pages, the menus and the setup.'**
  String get g4GenUiLangHelp;

  /// No description provided for @g4GenUiLangTitle.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get g4GenUiLangTitle;

  /// No description provided for @g4GenUpdHelp.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth looks for a new version by itself at the first start of each day. Here you can look now.'**
  String get g4GenUpdHelp;

  /// No description provided for @g4GenVoiceHelp.
  ///
  /// In en, this message translates to:
  /// **'Turns voice messages (from Telegram or the microphone) into text.'**
  String get g4GenVoiceHelp;

  /// No description provided for @g4GenVoiceKey.
  ///
  /// In en, this message translates to:
  /// **'Transcription service key'**
  String get g4GenVoiceKey;

  /// No description provided for @g4GenVoiceLocalHint.
  ///
  /// In en, this message translates to:
  /// **'No account and nothing leaves this computer. Rasgeth downloads whisper.cpp and a multilingual model once (about 560 MB, with its bar in the corner) and runs them itself.'**
  String get g4GenVoiceLocalHint;

  /// No description provided for @g4GenVoiceModel.
  ///
  /// In en, this message translates to:
  /// **'Transcription model'**
  String get g4GenVoiceModel;

  /// No description provided for @g4GenVoiceModelHead.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get g4GenVoiceModelHead;

  /// No description provided for @g4GenVoiceNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'Paste the {name} key first.'**
  String g4GenVoiceNeedsKey(String name);

  /// No description provided for @g4GenVoiceNeedsUrl.
  ///
  /// In en, this message translates to:
  /// **'Write the service\'s address first.'**
  String get g4GenVoiceNeedsUrl;

  /// No description provided for @g4GenVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice messages'**
  String get g4GenVoiceTitle;

  /// No description provided for @g4GenVoiceUrl.
  ///
  /// In en, this message translates to:
  /// **'Address of the transcription service'**
  String get g4GenVoiceUrl;

  /// No description provided for @g4GenWritten.
  ///
  /// In en, this message translates to:
  /// **'written'**
  String get g4GenWritten;

  /// No description provided for @g4GenLook.
  ///
  /// In en, this message translates to:
  /// **'Look and language'**
  String get g4GenLook;

  /// No description provided for @g4GenBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: it applies to tasks given up on from now on.'**
  String get g4GenBackupSaved;

  /// No description provided for @g4GenDebugSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}'**
  String g4GenDebugSaved(String name);

  /// No description provided for @g4GenNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'What is new in Rasgeth {version}'**
  String g4GenNewsTitle(String version);

  /// No description provided for @g4GenNewsOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get g4GenNewsOk;

  /// No description provided for @g4AgTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your team'**
  String get g4AgTreeTitle;

  /// No description provided for @g4AgTreeOf.
  ///
  /// In en, this message translates to:
  /// **'The agents of {project}'**
  String g4AgTreeOf(String project);

  /// No description provided for @g4AgTreeLead.
  ///
  /// In en, this message translates to:
  /// **'Who works for you. God leads everything; each project has its lead, who hands work to the project\'s agents. An agent sees only its own project; the inspector only reads.'**
  String get g4AgTreeLead;

  /// No description provided for @g4AgTreeProjectLead.
  ///
  /// In en, this message translates to:
  /// **'The project\'s lead, the agents it hands work to, and those of other places assigned to it.'**
  String get g4AgTreeProjectLead;

  /// No description provided for @g4AgAllProjects.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get g4AgAllProjects;

  /// No description provided for @g4AgShowStopped.
  ///
  /// In en, this message translates to:
  /// **'Also the stopped ones'**
  String get g4AgShowStopped;

  /// No description provided for @g4AgNoLead.
  ///
  /// In en, this message translates to:
  /// **'This project has no orchestrator yet.'**
  String get g4AgNoLead;

  /// No description provided for @g4AgNear.
  ///
  /// In en, this message translates to:
  /// **'Demi-God and personal agents'**
  String get g4AgNear;

  /// No description provided for @g4AgAssigned.
  ///
  /// In en, this message translates to:
  /// **'assigned'**
  String get g4AgAssigned;

  /// No description provided for @g4AgArchived.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get g4AgArchived;

  /// No description provided for @g4AgOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get g4AgOpen;

  /// No description provided for @g4AgClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get g4AgClose;

  /// No description provided for @g4AgAddShort.
  ///
  /// In en, this message translates to:
  /// **'Agent under it'**
  String get g4AgAddShort;

  /// No description provided for @g4AgAddUnder.
  ///
  /// In en, this message translates to:
  /// **'Add an agent under {name}'**
  String g4AgAddUnder(String name);

  /// No description provided for @g4AgKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get g4AgKind;

  /// No description provided for @g4AgWhatItDoes.
  ///
  /// In en, this message translates to:
  /// **'What it does'**
  String get g4AgWhatItDoes;

  /// No description provided for @g4AgModelDefault.
  ///
  /// In en, this message translates to:
  /// **'The default model'**
  String get g4AgModelDefault;

  /// No description provided for @g4AgOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open its conversation'**
  String get g4AgOpenChat;

  /// No description provided for @g4AgReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Its project is archived: you can read its settings, nothing changes until the project is restored.'**
  String get g4AgReadOnly;

  /// No description provided for @g4AgGroupAssistant.
  ///
  /// In en, this message translates to:
  /// **'Services and routines'**
  String get g4AgGroupAssistant;

  /// No description provided for @g4AgRewriteOffer.
  ///
  /// In en, this message translates to:
  /// **'You changed what {name} does. Do you want {god} to rewrite its instructions for the new job? You will see them before anything changes.'**
  String g4AgRewriteOffer(String name, String god);

  /// No description provided for @g4AgRewriteNo.
  ///
  /// In en, this message translates to:
  /// **'No, keep them'**
  String get g4AgRewriteNo;

  /// No description provided for @g4AgRewriteYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, rewrite them'**
  String get g4AgRewriteYes;

  /// No description provided for @g4AgServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get g4AgServices;

  /// No description provided for @g4AgServicesHelp.
  ///
  /// In en, this message translates to:
  /// **'The services it may use. Changes apply to its new conversations.'**
  String get g4AgServicesHelp;

  /// No description provided for @g4AgNoServices.
  ///
  /// In en, this message translates to:
  /// **'No services added yet.'**
  String get g4AgNoServices;

  /// No description provided for @g4AgAddServiceHint.
  ///
  /// In en, this message translates to:
  /// **'You add services (Notion, Linear, GitHub…) in Settings, Extensions.'**
  String get g4AgAddServiceHint;

  /// No description provided for @g4AgSvcChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get g4AgSvcChecking;

  /// No description provided for @g4AgSvcWorks.
  ///
  /// In en, this message translates to:
  /// **'Works · {n} tools'**
  String g4AgSvcWorks(int n);

  /// No description provided for @g4AgSvcLogin.
  ///
  /// In en, this message translates to:
  /// **'Needs you to sign in'**
  String get g4AgSvcLogin;

  /// No description provided for @g4AgSvcBroken.
  ///
  /// In en, this message translates to:
  /// **'Not working'**
  String get g4AgSvcBroken;

  /// No description provided for @g4AgSavedNewChats.
  ///
  /// In en, this message translates to:
  /// **'Saved: it applies to its new conversations.'**
  String get g4AgSavedNewChats;

  /// No description provided for @g4AgRoutines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get g4AgRoutines;

  /// No description provided for @g4AgRoutinesHelp.
  ///
  /// In en, this message translates to:
  /// **'Work it does by itself at a set time or when something happens.'**
  String get g4AgRoutinesHelp;

  /// No description provided for @g4AgNoRoutines.
  ///
  /// In en, this message translates to:
  /// **'No routines yet.'**
  String get g4AgNoRoutines;

  /// No description provided for @g4AgNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get g4AgNewRoutine;

  /// No description provided for @g4AgNewRoutineOf.
  ///
  /// In en, this message translates to:
  /// **'A new routine for {name}'**
  String g4AgNewRoutineOf(String name);

  /// No description provided for @g4AgOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get g4AgOn;

  /// No description provided for @g4AgOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get g4AgOff;

  /// No description provided for @g4AgRoutineWhat.
  ///
  /// In en, this message translates to:
  /// **'What should it do?'**
  String get g4AgRoutineWhat;

  /// No description provided for @g4AgRoutineWhatHint.
  ///
  /// In en, this message translates to:
  /// **'For example: look at today\'s appointments and send me a summary.'**
  String get g4AgRoutineWhatHint;

  /// No description provided for @g4AgRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Its title (optional)'**
  String get g4AgRoutineTitle;

  /// No description provided for @g4AgRoutineWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get g4AgRoutineWhen;

  /// No description provided for @g4AgEvery_daily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get g4AgEvery_daily;

  /// No description provided for @g4AgEvery_weekdays.
  ///
  /// In en, this message translates to:
  /// **'Monday to Friday'**
  String get g4AgEvery_weekdays;

  /// No description provided for @g4AgEvery_weekly.
  ///
  /// In en, this message translates to:
  /// **'Every Monday'**
  String get g4AgEvery_weekly;

  /// No description provided for @g4AgEvery_hourly.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get g4AgEvery_hourly;

  /// No description provided for @g4AgRoutineTime.
  ///
  /// In en, this message translates to:
  /// **'At what time (HH:MM)'**
  String get g4AgRoutineTime;

  /// No description provided for @g4AgRoutineTimeBad.
  ///
  /// In en, this message translates to:
  /// **'A time like 09:00'**
  String get g4AgRoutineTimeBad;

  /// No description provided for @g4AgRoutineSave.
  ///
  /// In en, this message translates to:
  /// **'Save the routine'**
  String get g4AgRoutineSave;

  /// No description provided for @g4AgRoutineOnce.
  ///
  /// In en, this message translates to:
  /// **'Once, {at}'**
  String g4AgRoutineOnce(String at);

  /// No description provided for @g4AgWhenDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String g4AgWhenDaily(String time);

  /// No description provided for @g4AgWhenWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Monday to Friday at {time}'**
  String g4AgWhenWeekdays(String time);

  /// No description provided for @g4AgWhenWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every Monday at {time}'**
  String g4AgWhenWeekly(String time);

  /// No description provided for @g4AgSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get g4AgSkills;

  /// No description provided for @g4AgSkillsHelp.
  ///
  /// In en, this message translates to:
  /// **'After a job that went well, tell it «save this as a skill»: it writes the steps down and, once you approve them in Extensions, every agent can use them.'**
  String get g4AgSkillsHelp;

  /// No description provided for @g4AgShared.
  ///
  /// In en, this message translates to:
  /// **'What every agent knows about you'**
  String get g4AgShared;

  /// No description provided for @g4AgSharedHelp.
  ///
  /// In en, this message translates to:
  /// **'Who you are, your work, your tools: shared by all your personal agents.'**
  String get g4AgSharedHelp;

  /// No description provided for @g4AgStep1.
  ///
  /// In en, this message translates to:
  /// **'What should it do?'**
  String get g4AgStep1;

  /// No description provided for @g4AgStep2Help.
  ///
  /// In en, this message translates to:
  /// **'It works there, under the project\'s lead.'**
  String get g4AgStep2Help;

  /// No description provided for @g4AgStep3.
  ///
  /// In en, this message translates to:
  /// **'Its name'**
  String get g4AgStep3;

  /// No description provided for @g4AgStep4Help.
  ///
  /// In en, this message translates to:
  /// **'Usually the same as the project\'s lead; choose another for a cheaper or stronger one.'**
  String get g4AgStep4Help;

  /// No description provided for @g4AgStep5.
  ///
  /// In en, this message translates to:
  /// **'How much it may do alone'**
  String get g4AgStep5;

  /// No description provided for @g4AgStep2Asst.
  ///
  /// In en, this message translates to:
  /// **'Which services may it use?'**
  String get g4AgStep2Asst;

  /// No description provided for @g4AgStep2AsstHelp.
  ///
  /// In en, this message translates to:
  /// **'It sees only the services you switch on here. Anything that sends, publishes, deletes or pays always asks you first.'**
  String get g4AgStep2AsstHelp;

  /// No description provided for @g4AgStep3Asst.
  ///
  /// In en, this message translates to:
  /// **'How much may it do alone?'**
  String get g4AgStep3Asst;

  /// No description provided for @g4AgWhere.
  ///
  /// In en, this message translates to:
  /// **'Where it works'**
  String get g4AgWhere;

  /// No description provided for @g4AgWhereHelp.
  ///
  /// In en, this message translates to:
  /// **'In a subproject it writes only in its folder; the rest of the project it can read, and changes there go through the lead.'**
  String get g4AgWhereHelp;

  /// No description provided for @g4AgWholeProject.
  ///
  /// In en, this message translates to:
  /// **'The whole project'**
  String get g4AgWholeProject;

  /// No description provided for @g4AgOwnWords.
  ///
  /// In en, this message translates to:
  /// **'Describe the job in your own words'**
  String get g4AgOwnWords;

  /// No description provided for @g4AgOwnWordsHelp.
  ///
  /// In en, this message translates to:
  /// **'For example: keeps the website\'s texts in Italian and English and checks the links.'**
  String get g4AgOwnWordsHelp;

  /// No description provided for @g4AgRecommended.
  ///
  /// In en, this message translates to:
  /// **'recommended'**
  String get g4AgRecommended;

  /// No description provided for @g4AgModeText_auto.
  ///
  /// In en, this message translates to:
  /// **'Works by itself; asks only for risky actions (as set in Safety).'**
  String get g4AgModeText_auto;

  /// No description provided for @g4AgModeText_manual.
  ///
  /// In en, this message translates to:
  /// **'Asks before every change to files or commands.'**
  String get g4AgModeText_manual;

  /// No description provided for @g4AgModeText_plan.
  ///
  /// In en, this message translates to:
  /// **'First proposes a plan; works only once it is approved.'**
  String get g4AgModeText_plan;

  /// No description provided for @g4AgModeText_readonly.
  ///
  /// In en, this message translates to:
  /// **'Reads and answers, changes nothing.'**
  String get g4AgModeText_readonly;

  /// No description provided for @g4AgAsstMode_auto.
  ///
  /// In en, this message translates to:
  /// **'On its own'**
  String get g4AgAsstMode_auto;

  /// No description provided for @g4AgAsstMode_manual.
  ///
  /// In en, this message translates to:
  /// **'Asks first'**
  String get g4AgAsstMode_manual;

  /// No description provided for @g4AgAsstModeText_auto.
  ///
  /// In en, this message translates to:
  /// **'Works by itself; asks you only before what leaves (sending, publishing, paying) or is risky.'**
  String get g4AgAsstModeText_auto;

  /// No description provided for @g4AgAsstModeText_manual.
  ///
  /// In en, this message translates to:
  /// **'Asks you before every change.'**
  String get g4AgAsstModeText_manual;

  /// No description provided for @g4AgAsstPurpose.
  ///
  /// In en, this message translates to:
  /// **'A personal agent does one job for you, outside the projects. God hands it the work that is its own; you can also talk to it directly.'**
  String get g4AgAsstPurpose;

  /// No description provided for @g4AgAsstRole.
  ///
  /// In en, this message translates to:
  /// **'Its job'**
  String get g4AgAsstRole;

  /// No description provided for @g4AgAsstRoleHelp.
  ///
  /// In en, this message translates to:
  /// **'One or two sentences: God reads them to decide what to hand to it, so keep it narrow.'**
  String get g4AgAsstRoleHelp;

  /// No description provided for @g4AgOrAskGod.
  ///
  /// In en, this message translates to:
  /// **'Not sure which agents you need?'**
  String get g4AgOrAskGod;

  /// No description provided for @g4AgAskGod.
  ///
  /// In en, this message translates to:
  /// **'Ask {god}'**
  String g4AgAskGod(String god);

  /// No description provided for @g4AgAskGodMessage.
  ///
  /// In en, this message translates to:
  /// **'Which personal agents would be useful to me? Look at what I do with you and suggest two or three, each with a narrow job and the services it needs. Create them only after I say yes.'**
  String get g4AgAskGodMessage;

  /// No description provided for @g4AgDraftNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {god} writes its instructions'**
  String g4AgDraftNext(String god);

  /// No description provided for @g4AgDraftNextHint.
  ///
  /// In en, this message translates to:
  /// **'{god} will write its instructions and choose its tools; you see them before it is created.'**
  String g4AgDraftNextHint(String god);

  /// No description provided for @g4AgDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Its instructions and tools'**
  String get g4AgDraftTitle;

  /// No description provided for @g4AgReviewWritten.
  ///
  /// In en, this message translates to:
  /// **'written for it'**
  String get g4AgReviewWritten;

  /// No description provided for @g4AgReviewBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'the built-in ones'**
  String get g4AgReviewBuiltIn;

  /// No description provided for @g4AgNoneChosen.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get g4AgNoneChosen;

  /// No description provided for @g4AgRole_coder.
  ///
  /// In en, this message translates to:
  /// **'Programmer'**
  String get g4AgRole_coder;

  /// No description provided for @g4AgRoleText_coder.
  ///
  /// In en, this message translates to:
  /// **'Writes and changes the code, runs the tests.'**
  String get g4AgRoleText_coder;

  /// No description provided for @g4AgRole_reviewer.
  ///
  /// In en, this message translates to:
  /// **'Reviewer'**
  String get g4AgRole_reviewer;

  /// No description provided for @g4AgRoleText_reviewer.
  ///
  /// In en, this message translates to:
  /// **'Checks changes for bugs and unclear code, says where and why.'**
  String get g4AgRoleText_reviewer;

  /// No description provided for @g4AgRole_researcher.
  ///
  /// In en, this message translates to:
  /// **'Researcher'**
  String get g4AgRole_researcher;

  /// No description provided for @g4AgRoleText_researcher.
  ///
  /// In en, this message translates to:
  /// **'Looks things up on the web and in the files, with sources.'**
  String get g4AgRoleText_researcher;

  /// No description provided for @g4AgRole_writer.
  ///
  /// In en, this message translates to:
  /// **'Writer'**
  String get g4AgRole_writer;

  /// No description provided for @g4AgRoleText_writer.
  ///
  /// In en, this message translates to:
  /// **'Documentation, READMEs and texts, clear and up to date.'**
  String get g4AgRoleText_writer;

  /// No description provided for @g4AgRole_tester.
  ///
  /// In en, this message translates to:
  /// **'Tester'**
  String get g4AgRole_tester;

  /// No description provided for @g4AgRoleText_tester.
  ///
  /// In en, this message translates to:
  /// **'Writes and runs tests, reproduces bugs.'**
  String get g4AgRoleText_tester;

  /// No description provided for @g4AgRole_custom.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get g4AgRole_custom;

  /// No description provided for @g4AgRoleText_custom.
  ///
  /// In en, this message translates to:
  /// **'You describe the job in your own words.'**
  String get g4AgRoleText_custom;

  /// No description provided for @g4AgJob_secretary.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get g4AgJob_secretary;

  /// No description provided for @g4AgJobHint_secretary.
  ///
  /// In en, this message translates to:
  /// **'Your diary, your tasks and messages; a summary every morning.'**
  String get g4AgJobHint_secretary;

  /// No description provided for @g4AgJobText_secretary.
  ///
  /// In en, this message translates to:
  /// **'Keep my tasks and appointments in order, remind me of deadlines and give me a short summary of the day when I ask. Never send anything in my name without asking.'**
  String get g4AgJobText_secretary;

  /// No description provided for @g4AgJob_researcher.
  ///
  /// In en, this message translates to:
  /// **'Researcher'**
  String get g4AgJob_researcher;

  /// No description provided for @g4AgJobHint_researcher.
  ///
  /// In en, this message translates to:
  /// **'Looks things up on the web and reports with sources.'**
  String get g4AgJobHint_researcher;

  /// No description provided for @g4AgJobText_researcher.
  ///
  /// In en, this message translates to:
  /// **'Look things up on the web when I ask, compare the sources and report what you found with the links, saying what you could not confirm.'**
  String get g4AgJobText_researcher;

  /// No description provided for @g4AgJob_social.
  ///
  /// In en, this message translates to:
  /// **'Social media'**
  String get g4AgJob_social;

  /// No description provided for @g4AgJobHint_social.
  ///
  /// In en, this message translates to:
  /// **'Prepares posts and keeps an eye on your pages.'**
  String get g4AgJobHint_social;

  /// No description provided for @g4AgJobText_social.
  ///
  /// In en, this message translates to:
  /// **'Prepare posts for my pages in my style, propose them to me before publishing and tell me how the last ones went.'**
  String get g4AgJobText_social;

  /// No description provided for @g4AgJob_accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get g4AgJob_accounts;

  /// No description provided for @g4AgJobHint_accounts.
  ///
  /// In en, this message translates to:
  /// **'Invoices, payments and expenses, in order.'**
  String get g4AgJobHint_accounts;

  /// No description provided for @g4AgJobText_accounts.
  ///
  /// In en, this message translates to:
  /// **'Keep invoices, payments and expenses in order, tell me what is due and what is missing. Never pay or refund without my approval.'**
  String get g4AgJobText_accounts;

  /// No description provided for @g4AgJob_tech.
  ///
  /// In en, this message translates to:
  /// **'Tech helper'**
  String get g4AgJob_tech;

  /// No description provided for @g4AgJobHint_tech.
  ///
  /// In en, this message translates to:
  /// **'Answers technical questions and fixes small things.'**
  String get g4AgJobHint_tech;

  /// No description provided for @g4AgJobText_tech.
  ///
  /// In en, this message translates to:
  /// **'Answer my technical questions simply, with the steps to follow, and fix small problems when I ask.'**
  String get g4AgJobText_tech;

  /// No description provided for @g4AgJob_custom.
  ///
  /// In en, this message translates to:
  /// **'In my own words'**
  String get g4AgJob_custom;

  /// No description provided for @g4AgJobHint_custom.
  ///
  /// In en, this message translates to:
  /// **'Describe the job yourself.'**
  String get g4AgJobHint_custom;

  /// No description provided for @g4BuTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get g4BuTitle;

  /// No description provided for @g4BuThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month}'**
  String g4BuThisMonth(String month);

  /// No description provided for @g4BuLead.
  ///
  /// In en, this message translates to:
  /// **'What projects and agents spend, and how far they may go.'**
  String get g4BuLead;

  /// No description provided for @g4BuChart.
  ///
  /// In en, this message translates to:
  /// **'Spending day by day this month'**
  String get g4BuChart;

  /// No description provided for @g4BuHowLink.
  ///
  /// In en, this message translates to:
  /// **'How limits work'**
  String get g4BuHowLink;

  /// No description provided for @g4BuHow.
  ///
  /// In en, this message translates to:
  /// **'Limits count everything spent since you set them, not month by month. When a row reaches its limit, its agents stop before their next request and Telegram warns you as it gets close. Raise or remove the limit to let them go on. Subscriptions (Claude, ChatGPT) and models on your computer cost nothing here.'**
  String get g4BuHow;

  /// No description provided for @g4BuUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get g4BuUnderstood;

  /// No description provided for @g4BuTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get g4BuTotal;

  /// No description provided for @g4BuEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get g4BuEverything;

  /// No description provided for @g4BuNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent yet.'**
  String get g4BuNothingYet;

  /// No description provided for @g4BuProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get g4BuProjects;

  /// No description provided for @g4BuAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get g4BuAgents;

  /// No description provided for @g4BuLimitFor.
  ///
  /// In en, this message translates to:
  /// **'Limit for {name}'**
  String g4BuLimitFor(String name);

  /// No description provided for @g4BuLimitNow.
  ///
  /// In en, this message translates to:
  /// **'Now: {limit}'**
  String g4BuLimitNow(String limit);

  /// No description provided for @g4BuLimitSay.
  ///
  /// In en, this message translates to:
  /// **'At \${usd} its agents stop and tell you; you raise it whenever you like.'**
  String g4BuLimitSay(String usd);

  /// No description provided for @g4BuLimitPick.
  ///
  /// In en, this message translates to:
  /// **'Choose an amount, or write another one.'**
  String get g4BuLimitPick;

  /// No description provided for @g4BuRemoveLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get g4BuRemoveLimit;

  /// No description provided for @g4BuMonth.
  ///
  /// In en, this message translates to:
  /// **'{usd} this month'**
  String g4BuMonth(String usd);

  /// No description provided for @g4BuEver.
  ///
  /// In en, this message translates to:
  /// **'{usd} since the start'**
  String g4BuEver(String usd);

  /// No description provided for @g4BuStopped.
  ///
  /// In en, this message translates to:
  /// **'Limit reached: stopped'**
  String get g4BuStopped;

  /// No description provided for @g4BuChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get g4BuChange;

  /// No description provided for @g4BuLimitIs.
  ///
  /// In en, this message translates to:
  /// **'Limit {limit}'**
  String g4BuLimitIs(String limit);

  /// No description provided for @g4BuNoLimit.
  ///
  /// In en, this message translates to:
  /// **'no limit'**
  String get g4BuNoLimit;

  /// No description provided for @g4BuOther.
  ///
  /// In en, this message translates to:
  /// **'other'**
  String get g4BuOther;

  /// No description provided for @g4BuLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get g4BuLimitLabel;

  /// No description provided for @g4BuTokens.
  ///
  /// In en, this message translates to:
  /// **'{n} tokens'**
  String g4BuTokens(String n);

  /// No description provided for @g4BuRowHint.
  ///
  /// In en, this message translates to:
  /// **'This month, every project and agent, with their limits'**
  String get g4BuRowHint;

  /// No description provided for @g4DvRenameQ.
  ///
  /// In en, this message translates to:
  /// **'A new name for «{name}»'**
  String g4DvRenameQ(String name);

  /// No description provided for @g4DvRenamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed: {name}'**
  String g4DvRenamed(String name);

  /// No description provided for @g4HubTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get g4HubTitle;

  /// No description provided for @g4HubGeneral.
  ///
  /// In en, this message translates to:
  /// **'Language, agents\' instructions, search, images, what\'s new'**
  String get g4HubGeneral;

  /// No description provided for @g4HubAgents.
  ///
  /// In en, this message translates to:
  /// **'The tree of agents, new agents, assistants'**
  String get g4HubAgents;

  /// No description provided for @g4HubTools.
  ///
  /// In en, this message translates to:
  /// **'What every agent may use'**
  String get g4HubTools;

  /// No description provided for @g4HubCommands.
  ///
  /// In en, this message translates to:
  /// **'Background commands, agents at work together'**
  String get g4HubCommands;

  /// No description provided for @g4HubRequests.
  ///
  /// In en, this message translates to:
  /// **'Where requests reach you, how long they wait'**
  String get g4HubRequests;

  /// No description provided for @g4HubSafety.
  ///
  /// In en, this message translates to:
  /// **'Guardian, who approves, spending, skills, retention'**
  String get g4HubSafety;

  /// The page's `canvasFullscreen` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get cvCanvasFullscreen;

  /// The page's `canvasFullscreenExit` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get cvCanvasFullscreenExit;

  /// The page's `sideMaximize` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get cvSideMaximize;

  /// The page's `sideBackToChat` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Back to chat'**
  String get cvSideBackToChat;

  /// The page's `vwDownload` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get cvVwDownload;

  /// The page's `vwCanvasBack` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Canvas ({n})'**
  String cvVwCanvasBack(String n);

  /// The page's `kbTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get cvKbTitle;

  /// The page's `sideTabsLabel` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Open files and terminals'**
  String get cvSideTabsLabel;

  /// The page's `canvasAgentOpened` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Opened by the agent'**
  String get cvCanvasAgentOpened;

  /// The page's `vwKind_archive` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get cvVwKindArchive;

  /// The page's `vwKind_audio` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get cvVwKindAudio;

  /// The page's `vwKind_code` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get cvVwKindCode;

  /// The page's `vwKind_document` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get cvVwKindDocument;

  /// The page's `vwKind_font` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get cvVwKindFont;

  /// The page's `vwKind_image` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get cvVwKindImage;

  /// The page's `vwKind_layers` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Layers (OpenRaster)'**
  String get cvVwKindLayers;

  /// The page's `vwKind_markdown` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get cvVwKindMarkdown;

  /// The page's `vwKind_model` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'3D model'**
  String get cvVwKindModel;

  /// The page's `vwKind_pdf` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get cvVwKindPdf;

  /// The page's `vwKind_sheet` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet'**
  String get cvVwKindSheet;

  /// The page's `vwKind_site` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get cvVwKindSite;

  /// The page's `vwKind_slides` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get cvVwKindSlides;

  /// The page's `vwKind_table` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get cvVwKindTable;

  /// The page's `vwKind_text` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get cvVwKindText;

  /// The page's `vwKind_tree` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get cvVwKindTree;

  /// The page's `vwKind_unknown` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get cvVwKindUnknown;

  /// The page's `vwKind_video` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get cvVwKindVideo;

  /// G42.6: above the Canvas's native viewer when the page inside the app fails or does not answer.
  ///
  /// In en, this message translates to:
  /// **'The page is not answering: this is the app\'s simple view.'**
  String get embedFallbackNote;

  /// No description provided for @palTitle.
  ///
  /// In en, this message translates to:
  /// **'Agents at most in this project'**
  String get palTitle;

  /// No description provided for @palZero.
  ///
  /// In en, this message translates to:
  /// **'Orchestrator only'**
  String get palZero;

  /// No description provided for @palHelp.
  ///
  /// In en, this message translates to:
  /// **'Besides the orchestrator; sub-agents at work count too. At 0 the orchestrator works alone.'**
  String get palHelp;

  /// No description provided for @palNow.
  ///
  /// In en, this message translates to:
  /// **'Now: {n}.'**
  String palNow(String n);

  /// No description provided for @palNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get palNone;

  /// No description provided for @palOne.
  ///
  /// In en, this message translates to:
  /// **'1 agent'**
  String get palOne;

  /// No description provided for @palN.
  ///
  /// In en, this message translates to:
  /// **'{n} agents'**
  String palN(String n);

  /// No description provided for @palOver.
  ///
  /// In en, this message translates to:
  /// **'It has {n}, more than {max}: nobody is removed, but no new agent until the team is under the limit.'**
  String palOver(String n, String max);

  /// No description provided for @palSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. It is in the history of changes, where you can undo it.'**
  String get palSaved;

  /// No description provided for @pmAgentLimit.
  ///
  /// In en, this message translates to:
  /// **'Agents at most: {n}'**
  String pmAgentLimit(String n);

  /// No description provided for @errAgentLimit.
  ///
  /// In en, this message translates to:
  /// **'The project «{project}» can have at most {max} agents besides its orchestrator: it has {count}. Raise the limit in the project\'s menu or remove one.'**
  String errAgentLimit(String project, String max, String count);

  /// No description provided for @appUpdTitle.
  ///
  /// In en, this message translates to:
  /// **'{app} update'**
  String appUpdTitle(String app);

  /// No description provided for @appUpdCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for {app} updates…'**
  String appUpdCheck(String app);

  /// No description provided for @appUpdChecking.
  ///
  /// In en, this message translates to:
  /// **'Looking for a new version…'**
  String get appUpdChecking;

  /// No description provided for @appUpdUpToDate.
  ///
  /// In en, this message translates to:
  /// **'{app} {current} is the newest version.'**
  String appUpdUpToDate(String app, String current);

  /// No description provided for @appUpdAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is out: you have {current}.'**
  String appUpdAvailable(String version, String current);

  /// No description provided for @appUpdFromServer.
  ///
  /// In en, this message translates to:
  /// **'GitHub does not answer: this is the version of the Rasgeth you are connected to.'**
  String get appUpdFromServer;

  /// No description provided for @appUpdDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get appUpdDownload;

  /// No description provided for @appUpdDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {version}'**
  String appUpdDownloading(String version);

  /// No description provided for @appUpdHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get appUpdHide;

  /// No description provided for @appUpdLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdLater;

  /// No description provided for @appUpdSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get appUpdSkip;

  /// No description provided for @appUpdReady.
  ///
  /// In en, this message translates to:
  /// **'{version} is ready. {app} closes, updates and opens again where you are.'**
  String appUpdReady(String version, String app);

  /// No description provided for @appUpdVerified.
  ///
  /// In en, this message translates to:
  /// **'Signature and checksum checked with Rasgeth\'s update key.'**
  String get appUpdVerified;

  /// No description provided for @appUpdRestart.
  ///
  /// In en, this message translates to:
  /// **'Update and restart'**
  String get appUpdRestart;

  /// No description provided for @appUpdApplying.
  ///
  /// In en, this message translates to:
  /// **'Closing {app} to update it…'**
  String appUpdApplying(String app);

  /// No description provided for @appUpdRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get appUpdRetry;

  /// No description provided for @appUpdClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get appUpdClose;

  /// No description provided for @appUpdErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'GitHub cannot be reached now. Try again later.'**
  String get appUpdErrNetwork;

  /// No description provided for @appUpdErrSignature.
  ///
  /// In en, this message translates to:
  /// **'The signature of this version\'s file list is missing or not valid: nothing of it is used.'**
  String get appUpdErrSignature;

  /// No description provided for @appUpdErrNotListed.
  ///
  /// In en, this message translates to:
  /// **'This version has no {app} package for this system.'**
  String appUpdErrNotListed(String app);

  /// No description provided for @appUpdErrChecksum.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file is not the signed one: it was deleted.'**
  String get appUpdErrChecksum;

  /// No description provided for @appUpdErrDisk.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file could not be kept or opened.'**
  String get appUpdErrDisk;

  /// No description provided for @appUpdErrSwap.
  ///
  /// In en, this message translates to:
  /// **'The replacement could not start: nothing changed.'**
  String get appUpdErrSwap;

  /// No description provided for @appUpdDone.
  ///
  /// In en, this message translates to:
  /// **'{app} is now {version} (it was {from}).'**
  String appUpdDone(String app, String version, String from);

  /// No description provided for @appUpdWentBack.
  ///
  /// In en, this message translates to:
  /// **'{version} did not start: {app} went back to {current}. It is not offered again until a newer one comes out.'**
  String appUpdWentBack(String version, String app, String current);

  /// No description provided for @appUpdCarried.
  ///
  /// In en, this message translates to:
  /// **'This copy of {app} comes with Rasgeth: it is updated with Rasgeth.'**
  String appUpdCarried(String app);

  /// No description provided for @appUpdDev.
  ///
  /// In en, this message translates to:
  /// **'A build from the sources: it does not update itself.'**
  String get appUpdDev;

  /// No description provided for @knAsstSavedNewChats.
  ///
  /// In en, this message translates to:
  /// **'Saved: it applies to its new conversations.'**
  String get knAsstSavedNewChats;

  /// No description provided for @knCompactAtHint.
  ///
  /// In en, this message translates to:
  /// **'An agent can keep only so much text in mind at once, like a notebook with a fixed number of pages. Further right: the summary comes later. Further left: it comes sooner and the conversation stays lighter.'**
  String get knCompactAtHint;

  /// No description provided for @knCompactAtTitle.
  ///
  /// In en, this message translates to:
  /// **'When to write the summary'**
  String get knCompactAtTitle;

  /// No description provided for @knCompactAtValue.
  ///
  /// In en, this message translates to:
  /// **'when {n}% full'**
  String knCompactAtValue(String n);

  /// No description provided for @knCompactDefaultIs.
  ///
  /// In en, this message translates to:
  /// **'Default for this agent\'s model: at {at}%, keeping {keep}%.'**
  String knCompactDefaultIs(String at, String keep);

  /// No description provided for @knCompactDefaults.
  ///
  /// In en, this message translates to:
  /// **'Back to the defaults'**
  String get knCompactDefaults;

  /// No description provided for @knCompactExample.
  ///
  /// In en, this message translates to:
  /// **'if the agent can keep 100 pages in mind, when it reaches {at} it writes the summary: the last {keep} stay exactly as they were, the ones before become a few pages of notes.'**
  String knCompactExample(String at, String keep);

  /// No description provided for @knCompactExampleNone.
  ///
  /// In en, this message translates to:
  /// **'if the agent can keep 100 pages in mind, when it reaches {at} it turns all of them into a few pages of notes.'**
  String knCompactExampleNone(String at);

  /// No description provided for @knCompactExampleTitle.
  ///
  /// In en, this message translates to:
  /// **'For example:'**
  String get knCompactExampleTitle;

  /// No description provided for @knCompactExplain.
  ///
  /// In en, this message translates to:
  /// **'When the conversation gets long, the agent writes a summary of the old parts, like someone taking notes. Here you choose when it does it, and how much of the latest part it keeps as it is.'**
  String get knCompactExplain;

  /// No description provided for @knCompactKeepHint.
  ///
  /// In en, this message translates to:
  /// **'The most recent part stays word for word, everything before it becomes notes. More kept means the agent remembers the latest details better; on a model on your computer each kept word costs a little time once (12% is fine there).'**
  String get knCompactKeepHint;

  /// No description provided for @knCompactKeepNone.
  ///
  /// In en, this message translates to:
  /// **'nothing'**
  String get knCompactKeepNone;

  /// No description provided for @knCompactKeepTitle.
  ///
  /// In en, this message translates to:
  /// **'How much of the latest part to keep as it is'**
  String get knCompactKeepTitle;

  /// No description provided for @knCompactKeepValue.
  ///
  /// In en, this message translates to:
  /// **'the last {n}%'**
  String knCompactKeepValue(String n);

  /// No description provided for @knErr_memory_empty.
  ///
  /// In en, this message translates to:
  /// **'Write something to remember.'**
  String get knErr_memory_empty;

  /// No description provided for @knErr_memory_forgotten.
  ///
  /// In en, this message translates to:
  /// **'A memory forgotten for good cannot come back.'**
  String get knErr_memory_forgotten;

  /// No description provided for @knErr_memory_full.
  ///
  /// In en, this message translates to:
  /// **'The memory is full: delete or merge some old memories first.'**
  String get knErr_memory_full;

  /// No description provided for @knErr_memory_gone.
  ///
  /// In en, this message translates to:
  /// **'That memory is not there any more.'**
  String get knErr_memory_gone;

  /// No description provided for @knErr_memory_long.
  ///
  /// In en, this message translates to:
  /// **'A memory is at most 400 characters: write it shorter.'**
  String get knErr_memory_long;

  /// No description provided for @knErr_memory_moved.
  ///
  /// In en, this message translates to:
  /// **'The memory changed again since: undo the newer change first.'**
  String get knErr_memory_moved;

  /// No description provided for @knErr_memory_same.
  ///
  /// In en, this message translates to:
  /// **'Another memory already says the same.'**
  String get knErr_memory_same;

  /// No description provided for @knErr_memory_secret.
  ///
  /// In en, this message translates to:
  /// **'That looks like a password, a code or a card number: secrets are never kept in memory.'**
  String get knErr_memory_secret;

  /// No description provided for @knErr_memory_undone.
  ///
  /// In en, this message translates to:
  /// **'That change was already undone.'**
  String get knErr_memory_undone;

  /// No description provided for @knJob_download_knowledge_model.
  ///
  /// In en, this message translates to:
  /// **'Downloading {model} ({size}) for the knowledge, to search your files on this computer (only once)'**
  String knJob_download_knowledge_model(String model, String size);

  /// No description provided for @knJob_download_ocr.
  ///
  /// In en, this message translates to:
  /// **'Downloading the reading of text in pictures ({languages}, {size}), only once'**
  String knJob_download_ocr(String languages, String size);

  /// No description provided for @knJob_download_pgvector.
  ///
  /// In en, this message translates to:
  /// **'Downloading pgvector, the search by meaning in Rasgeth\'s database (only once)'**
  String get knJob_download_pgvector;

  /// No description provided for @knJob_error_checksum.
  ///
  /// In en, this message translates to:
  /// **'The download arrived damaged (its fingerprint does not match): try again.'**
  String get knJob_error_checksum;

  /// No description provided for @knJob_error_pgvector_unavailable.
  ///
  /// In en, this message translates to:
  /// **'pgvector is not published for this computer yet: the knowledge searches by words only.'**
  String get knJob_error_pgvector_unavailable;

  /// No description provided for @knJob_step_model_download.
  ///
  /// In en, this message translates to:
  /// **'The model'**
  String get knJob_step_model_download;

  /// No description provided for @knJob_step_ocr_languages.
  ///
  /// In en, this message translates to:
  /// **'The languages'**
  String get knJob_step_ocr_languages;

  /// No description provided for @knJob_step_ocr_program.
  ///
  /// In en, this message translates to:
  /// **'The program'**
  String get knJob_step_ocr_program;

  /// No description provided for @knJob_step_tool_download.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get knJob_step_tool_download;

  /// No description provided for @knKbAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get knKbAdd;

  /// No description provided for @knKbAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add a source'**
  String get knKbAddSource;

  /// No description provided for @knKbAddSourceTo.
  ///
  /// In en, this message translates to:
  /// **'Add a source to {name}'**
  String knKbAddSourceTo(String name);

  /// No description provided for @knKbAgentAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get knKbAgentAlways;

  /// No description provided for @knKbAgentByScopeNo.
  ///
  /// In en, this message translates to:
  /// **'As the collection says (no)'**
  String get knKbAgentByScopeNo;

  /// No description provided for @knKbAgentByScopeYes.
  ///
  /// In en, this message translates to:
  /// **'As the collection says (yes)'**
  String get knKbAgentByScopeYes;

  /// No description provided for @knKbAgentLead.
  ///
  /// In en, this message translates to:
  /// **'Which collections {name} can search. Each one says who may read it; here you can make an exception for this agent.'**
  String knKbAgentLead(String name);

  /// No description provided for @knKbAgentNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get knKbAgentNever;

  /// No description provided for @knKbAgentNewOnly.
  ///
  /// In en, this message translates to:
  /// **'It changes from the agent\'s next conversation.'**
  String get knKbAgentNewOnly;

  /// No description provided for @knKbAgentNone.
  ///
  /// In en, this message translates to:
  /// **'{name} reads no collection'**
  String knKbAgentNone(String name);

  /// No description provided for @knKbAgentOpenAll.
  ///
  /// In en, this message translates to:
  /// **'All the collections'**
  String get knKbAgentOpenAll;

  /// No description provided for @knKbAgentPieces.
  ///
  /// In en, this message translates to:
  /// **'{n} pieces'**
  String knKbAgentPieces(String n);

  /// No description provided for @knKbAgentReads.
  ///
  /// In en, this message translates to:
  /// **'{name} reads {n} collections'**
  String knKbAgentReads(String n, String name);

  /// No description provided for @knKbAgentTool.
  ///
  /// In en, this message translates to:
  /// **'It searches them with «Search the documents», and cites where each answer comes from.'**
  String get knKbAgentTool;

  /// No description provided for @knKbAllChats.
  ///
  /// In en, this message translates to:
  /// **'None chosen: the conversations with every agent.'**
  String get knKbAllChats;

  /// No description provided for @knKbBackupVectors.
  ///
  /// In en, this message translates to:
  /// **'Put the knowledge in the backup too'**
  String get knKbBackupVectors;

  /// No description provided for @knKbBackupVectorsHelp.
  ///
  /// In en, this message translates to:
  /// **'A bigger backup, but on another computer the search is ready at once, without reading everything again.'**
  String get knKbBackupVectorsHelp;

  /// No description provided for @knKbChat.
  ///
  /// In en, this message translates to:
  /// **'conversation'**
  String get knKbChat;

  /// No description provided for @knKbCiteFallback.
  ///
  /// In en, this message translates to:
  /// **'document'**
  String get knKbCiteFallback;

  /// No description provided for @knKbCloudKey.
  ///
  /// In en, this message translates to:
  /// **'Keychain entry with the key'**
  String get knKbCloudKey;

  /// No description provided for @knKbCloudKeyExample.
  ///
  /// In en, this message translates to:
  /// **'voyage_key'**
  String get knKbCloudKeyExample;

  /// No description provided for @knKbCloudKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Empty: the key given in the setup, for OpenAI, Gemini and Mistral.'**
  String get knKbCloudKeyHelp;

  /// No description provided for @knKbCloudLead.
  ///
  /// In en, this message translates to:
  /// **'The pieces of your documents are sent to the service to be read. Its key stays in the keychain.'**
  String get knKbCloudLead;

  /// No description provided for @knKbCloudModel.
  ///
  /// In en, this message translates to:
  /// **'Suggested models'**
  String get knKbCloudModel;

  /// No description provided for @knKbCloudModelName.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get knKbCloudModelName;

  /// No description provided for @knKbCloudText.
  ///
  /// In en, this message translates to:
  /// **'OpenAI, Voyage, Cohere, Gemini, Mistral, Jina or your own'**
  String get knKbCloudText;

  /// No description provided for @knKbCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'An online service'**
  String get knKbCloudTitle;

  /// No description provided for @knKbCloudTrying.
  ///
  /// In en, this message translates to:
  /// **'Trying the key…'**
  String get knKbCloudTrying;

  /// No description provided for @knKbCloudUrl.
  ///
  /// In en, this message translates to:
  /// **'Address of the service'**
  String get knKbCloudUrl;

  /// No description provided for @knKbCloudUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'One that speaks like OpenAI, ending in /v1.'**
  String get knKbCloudUrlHelp;

  /// No description provided for @knKbCloudUse.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get knKbCloudUse;

  /// No description provided for @knKbCloudWho.
  ///
  /// In en, this message translates to:
  /// **'Which service'**
  String get knKbCloudWho;

  /// No description provided for @knKbColLine.
  ///
  /// In en, this message translates to:
  /// **'{docs} documents · {pieces} pieces'**
  String knKbColLine(String docs, String pieces);

  /// No description provided for @knKbColName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get knKbColName;

  /// No description provided for @knKbColNameExample.
  ///
  /// In en, this message translates to:
  /// **'Manuals, Contracts, Recipes…'**
  String get knKbColNameExample;

  /// No description provided for @knKbColNameHelp.
  ///
  /// In en, this message translates to:
  /// **'What it holds, in a few words.'**
  String get knKbColNameHelp;

  /// No description provided for @knKbColsLead.
  ///
  /// In en, this message translates to:
  /// **'A collection groups the sources of one subject, and says which agents may read it.'**
  String get knKbColsLead;

  /// No description provided for @knKbColsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get knKbColsTitle;

  /// No description provided for @knKbConsentChats.
  ///
  /// In en, this message translates to:
  /// **'The agents that may read this collection will be able to find and quote what you wrote in your conversations and what the agents answered.'**
  String get knKbConsentChats;

  /// No description provided for @knKbConsentChatsYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, the agents may read these conversations'**
  String get knKbConsentChatsYes;

  /// No description provided for @knKbConsentMail.
  ///
  /// In en, this message translates to:
  /// **'The agents that may read this collection will be able to find and quote your mail. Rasgeth only reads the inbox: it never marks, moves or deletes a message.'**
  String get knKbConsentMail;

  /// No description provided for @knKbConsentMailYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, the agents may read this mail'**
  String get knKbConsentMailYes;

  /// No description provided for @knKbDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String knKbDays(String n);

  /// No description provided for @knKbDiskLead.
  ///
  /// In en, this message translates to:
  /// **'What the knowledge takes, and whether the backup carries it.'**
  String get knKbDiskLead;

  /// No description provided for @knKbDiskModels.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get knKbDiskModels;

  /// No description provided for @knKbDiskOcr.
  ///
  /// In en, this message translates to:
  /// **'Reading pictures'**
  String get knKbDiskOcr;

  /// No description provided for @knKbDiskTexts.
  ///
  /// In en, this message translates to:
  /// **'Pieces of text'**
  String get knKbDiskTexts;

  /// No description provided for @knKbDiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Space on the disk'**
  String get knKbDiskTitle;

  /// No description provided for @knKbDiskTotal.
  ///
  /// In en, this message translates to:
  /// **'In all'**
  String get knKbDiskTotal;

  /// No description provided for @knKbDiskVectors.
  ///
  /// In en, this message translates to:
  /// **'Index by meaning'**
  String get knKbDiskVectors;

  /// No description provided for @knKbDocsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{n} documents still to read.'**
  String knKbDocsWaiting(String n);

  /// No description provided for @knKbDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get knKbDownloading;

  /// No description provided for @knKbDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop to add them to the knowledge'**
  String get knKbDropHere;

  /// No description provided for @knKbDropOnCard.
  ///
  /// In en, this message translates to:
  /// **'Drop files on a collection to add them.'**
  String get knKbDropOnCard;

  /// No description provided for @knKbDropSay.
  ///
  /// In en, this message translates to:
  /// **'You can also drop files on this window.'**
  String get knKbDropSay;

  /// No description provided for @knKbErr_bad_choice.
  ///
  /// In en, this message translates to:
  /// **'That choice is not possible.'**
  String get knKbErr_bad_choice;

  /// No description provided for @knKbErr_bad_source.
  ///
  /// In en, this message translates to:
  /// **'That source cannot be read: check the path or the address.'**
  String get knKbErr_bad_source;

  /// No description provided for @knKbErr_embedding_failed.
  ///
  /// In en, this message translates to:
  /// **'The model did not answer: check the key and try again.'**
  String get knKbErr_embedding_failed;

  /// No description provided for @knKbErr_no_vector.
  ///
  /// In en, this message translates to:
  /// **'Searching by meaning is not ready on this computer yet.'**
  String get knKbErr_no_vector;

  /// No description provided for @knKbErr_not_found.
  ///
  /// In en, this message translates to:
  /// **'It is not there any more.'**
  String get knKbErr_not_found;

  /// No description provided for @knKbEtaSoon.
  ///
  /// In en, this message translates to:
  /// **'The time left shows after the first minutes.'**
  String get knKbEtaSoon;

  /// No description provided for @knKbFileExample.
  ///
  /// In en, this message translates to:
  /// **'/home/me/manual.pdf'**
  String get knKbFileExample;

  /// No description provided for @knKbFileHelp.
  ///
  /// In en, this message translates to:
  /// **'Its full path on the computer where Rasgeth runs.'**
  String get knKbFileHelp;

  /// No description provided for @knKbFilePath.
  ///
  /// In en, this message translates to:
  /// **'The file'**
  String get knKbFilePath;

  /// No description provided for @knKbFolderExample.
  ///
  /// In en, this message translates to:
  /// **'/home/me/Documents or C:\\Users\\me\\Documents'**
  String get knKbFolderExample;

  /// No description provided for @knKbFolderHelp.
  ///
  /// In en, this message translates to:
  /// **'Its full path on the computer where Rasgeth runs.'**
  String get knKbFolderHelp;

  /// No description provided for @knKbFolderPath.
  ///
  /// In en, this message translates to:
  /// **'The folder'**
  String get knKbFolderPath;

  /// No description provided for @knKbForAgent.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String knKbForAgent(String name);

  /// No description provided for @knKbForAll.
  ///
  /// In en, this message translates to:
  /// **'For every agent'**
  String get knKbForAll;

  /// No description provided for @knKbForProject.
  ///
  /// In en, this message translates to:
  /// **'For the project {name}'**
  String knKbForProject(String name);

  /// No description provided for @knKbForWhom.
  ///
  /// In en, this message translates to:
  /// **'Who may read it'**
  String get knKbForWhom;

  /// No description provided for @knKbHere.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get knKbHere;

  /// No description provided for @knKbHowFarBack.
  ///
  /// In en, this message translates to:
  /// **'How far back'**
  String get knKbHowFarBack;

  /// No description provided for @knKbKindText_chats.
  ///
  /// In en, this message translates to:
  /// **'What you said with the agents'**
  String get knKbKindText_chats;

  /// No description provided for @knKbKindText_file.
  ///
  /// In en, this message translates to:
  /// **'One document'**
  String get knKbKindText_file;

  /// No description provided for @knKbKindText_folder.
  ///
  /// In en, this message translates to:
  /// **'Everything inside, kept up to date'**
  String get knKbKindText_folder;

  /// No description provided for @knKbKindText_mail.
  ///
  /// In en, this message translates to:
  /// **'Only if you want it'**
  String get knKbKindText_mail;

  /// No description provided for @knKbKindText_url.
  ///
  /// In en, this message translates to:
  /// **'Read once, again when you ask'**
  String get knKbKindText_url;

  /// No description provided for @knKbKindText_workspace.
  ///
  /// In en, this message translates to:
  /// **'The files of one of your projects'**
  String get knKbKindText_workspace;

  /// No description provided for @knKbKind_chats.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get knKbKind_chats;

  /// No description provided for @knKbKind_file.
  ///
  /// In en, this message translates to:
  /// **'A file'**
  String get knKbKind_file;

  /// No description provided for @knKbKind_folder.
  ///
  /// In en, this message translates to:
  /// **'A folder'**
  String get knKbKind_folder;

  /// No description provided for @knKbKind_mail.
  ///
  /// In en, this message translates to:
  /// **'A mailbox'**
  String get knKbKind_mail;

  /// No description provided for @knKbKind_url.
  ///
  /// In en, this message translates to:
  /// **'A web page'**
  String get knKbKind_url;

  /// No description provided for @knKbKind_workspace.
  ///
  /// In en, this message translates to:
  /// **'A project'**
  String get knKbKind_workspace;

  /// No description provided for @knKbLead.
  ///
  /// In en, this message translates to:
  /// **'Choose folders, files and pages: Rasgeth reads them, cuts them into pieces and finds them by what they mean. The agents say where each answer comes from, and one click opens the file at that point.'**
  String get knKbLead;

  /// No description provided for @knKbLeftOut.
  ///
  /// In en, this message translates to:
  /// **'Left out ({n})'**
  String knKbLeftOut(String n);

  /// No description provided for @knKbLine.
  ///
  /// In en, this message translates to:
  /// **'line {n}'**
  String knKbLine(String n);

  /// No description provided for @knKbLines.
  ///
  /// In en, this message translates to:
  /// **'lines {a}–{b}'**
  String knKbLines(String a, String b);

  /// No description provided for @knKbLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get knKbLoading;

  /// No description provided for @knKbLocalText.
  ///
  /// In en, this message translates to:
  /// **'On this computer · {size} MB · {dims} numbers per piece'**
  String knKbLocalText(String dims, String size);

  /// No description provided for @knKbMail.
  ///
  /// In en, this message translates to:
  /// **'mail'**
  String get knKbMail;

  /// No description provided for @knKbMake.
  ///
  /// In en, this message translates to:
  /// **'Make it'**
  String get knKbMake;

  /// No description provided for @knKbMeaningBest.
  ///
  /// In en, this message translates to:
  /// **'The recommended one is {name}: {size} MB, downloaded once, only now that you say so.'**
  String knKbMeaningBest(String name, String size);

  /// No description provided for @knKbMeaningDownload.
  ///
  /// In en, this message translates to:
  /// **'Download {name} ({size} MB) and turn it on'**
  String knKbMeaningDownload(String name, String size);

  /// No description provided for @knKbMeaningOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Searching by meaning is off: only by words'**
  String get knKbMeaningOffTitle;

  /// No description provided for @knKbMeaningOff_downloading.
  ///
  /// In en, this message translates to:
  /// **'The model you chose is not on this computer yet: until it arrives the search goes by words.'**
  String get knKbMeaningOff_downloading;

  /// No description provided for @knKbMeaningOff_failed.
  ///
  /// In en, this message translates to:
  /// **'The model for the meaning does not answer: the search goes by words. Choose it again or another one.'**
  String get knKbMeaningOff_failed;

  /// No description provided for @knKbMeaningOff_no_model.
  ///
  /// In en, this message translates to:
  /// **'No model reads your documents by meaning yet, so the agents find a piece only when it has the same words they ask with.'**
  String get knKbMeaningOff_no_model;

  /// No description provided for @knKbMeaningOff_no_vector.
  ///
  /// In en, this message translates to:
  /// **'The part of the database that searches by meaning is missing on this computer: the search goes by words.'**
  String get knKbMeaningOff_no_vector;

  /// No description provided for @knKbMeaningOther.
  ///
  /// In en, this message translates to:
  /// **'Choose another model'**
  String get knKbMeaningOther;

  /// No description provided for @knKbMeaningTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on searching by meaning'**
  String get knKbMeaningTurnOn;

  /// No description provided for @knKbMeaningUse.
  ///
  /// In en, this message translates to:
  /// **'Use {name}'**
  String knKbMeaningUse(String name);

  /// No description provided for @knKbMeaningWhy.
  ///
  /// In en, this message translates to:
  /// **'With a model that reads by meaning, «when does the warehouse open» also finds «it opens at 7:30». It runs on this computer: your documents do not leave it.'**
  String get knKbMeaningWhy;

  /// No description provided for @knKbModelLead.
  ///
  /// In en, this message translates to:
  /// **'On this computer (downloaded once, nothing leaves the house) or an online service with your key. Changing it makes a new index in the background.'**
  String get knKbModelLead;

  /// No description provided for @knKbModelTitle.
  ///
  /// In en, this message translates to:
  /// **'The model that reads by meaning'**
  String get knKbModelTitle;

  /// No description provided for @knKbNewCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get knKbNewCollection;

  /// No description provided for @knKbNewIndex.
  ///
  /// In en, this message translates to:
  /// **'A new index for {model} is being made; the searches use the old one until it is ready.'**
  String knKbNewIndex(String model);

  /// No description provided for @knKbNoCols.
  ///
  /// In en, this message translates to:
  /// **'No collection yet.'**
  String get knKbNoCols;

  /// No description provided for @knKbNoMailboxes.
  ///
  /// In en, this message translates to:
  /// **'No mailbox is connected yet: add one in Automations.'**
  String get knKbNoMailboxes;

  /// No description provided for @knKbNoProjects.
  ///
  /// In en, this message translates to:
  /// **'There is no project yet.'**
  String get knKbNoProjects;

  /// No description provided for @knKbNoSources.
  ///
  /// In en, this message translates to:
  /// **'No source yet: add a folder, a file or a page.'**
  String get knKbNoSources;

  /// No description provided for @knKbOcrDownload.
  ///
  /// In en, this message translates to:
  /// **'Download now'**
  String get knKbOcrDownload;

  /// No description provided for @knKbOcrLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages of your documents'**
  String get knKbOcrLanguages;

  /// No description provided for @knKbOcrLead.
  ///
  /// In en, this message translates to:
  /// **'Reads photos of documents and scanned PDFs on this computer (Tesseract). Its program and languages come down the first time, a few MB.'**
  String get knKbOcrLead;

  /// No description provided for @knKbOcrOn.
  ///
  /// In en, this message translates to:
  /// **'Read the text in pictures and scans'**
  String get knKbOcrOn;

  /// No description provided for @knKbOcrOnHelp.
  ///
  /// In en, this message translates to:
  /// **'Slower than text: about a second a page.'**
  String get knKbOcrOnHelp;

  /// No description provided for @knKbOcrReady.
  ///
  /// In en, this message translates to:
  /// **'Ready on this computer.'**
  String get knKbOcrReady;

  /// No description provided for @knKbOcrTitle.
  ///
  /// In en, this message translates to:
  /// **'Text in pictures and scans'**
  String get knKbOcrTitle;

  /// No description provided for @knKbOcrToDownload.
  ///
  /// In en, this message translates to:
  /// **'To download: about {size} MB.'**
  String knKbOcrToDownload(String size);

  /// No description provided for @knKbOcrWaiting.
  ///
  /// In en, this message translates to:
  /// **'{n} pictures and scans are waiting for it.'**
  String knKbOcrWaiting(String n);

  /// No description provided for @knKbOpenCollection.
  ///
  /// In en, this message translates to:
  /// **'Open the collection {name}'**
  String knKbOpenCollection(String name);

  /// No description provided for @knKbPage.
  ///
  /// In en, this message translates to:
  /// **'page {n}'**
  String knKbPage(String n);

  /// No description provided for @knKbPause.
  ///
  /// In en, this message translates to:
  /// **'Pause the reading'**
  String get knKbPause;

  /// No description provided for @knKbPauseHelp.
  ///
  /// In en, this message translates to:
  /// **'The searches keep working; nothing new is read until you turn this off.'**
  String get knKbPauseHelp;

  /// No description provided for @knKbPickEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here in {name}.'**
  String knKbPickEmpty(String name);

  /// No description provided for @knKbPickFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file in Rasgeth'**
  String get knKbPickFile;

  /// No description provided for @knKbPickFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder in Rasgeth'**
  String get knKbPickFolder;

  /// No description provided for @knKbPickOther.
  ///
  /// In en, this message translates to:
  /// **'Choose another'**
  String get knKbPickOther;

  /// No description provided for @knKbPickPlaces.
  ///
  /// In en, this message translates to:
  /// **'Back to the projects'**
  String get knKbPickPlaces;

  /// No description provided for @knKbPickThis.
  ///
  /// In en, this message translates to:
  /// **'Choose this folder'**
  String get knKbPickThis;

  /// No description provided for @knKbPickUp.
  ///
  /// In en, this message translates to:
  /// **'Up one folder'**
  String get knKbPickUp;

  /// No description provided for @knKbPickWhere.
  ///
  /// In en, this message translates to:
  /// **'Your projects and Rasgeth\'s folders'**
  String get knKbPickWhere;

  /// No description provided for @knKbPlaceAssistants.
  ///
  /// In en, this message translates to:
  /// **'The assistants\' desk'**
  String get knKbPlaceAssistants;

  /// No description provided for @knKbPlacePlatform.
  ///
  /// In en, this message translates to:
  /// **'God\'s folder'**
  String get knKbPlacePlatform;

  /// No description provided for @knKbProv_cohere.
  ///
  /// In en, this message translates to:
  /// **'Cohere'**
  String get knKbProv_cohere;

  /// No description provided for @knKbProv_compatible.
  ///
  /// In en, this message translates to:
  /// **'Another (like OpenAI)'**
  String get knKbProv_compatible;

  /// No description provided for @knKbProv_gemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get knKbProv_gemini;

  /// No description provided for @knKbProv_jina.
  ///
  /// In en, this message translates to:
  /// **'Jina'**
  String get knKbProv_jina;

  /// No description provided for @knKbProv_mistral.
  ///
  /// In en, this message translates to:
  /// **'Mistral'**
  String get knKbProv_mistral;

  /// No description provided for @knKbProv_openai.
  ///
  /// In en, this message translates to:
  /// **'OpenAI'**
  String get knKbProv_openai;

  /// No description provided for @knKbProv_voyage.
  ///
  /// In en, this message translates to:
  /// **'Voyage'**
  String get knKbProv_voyage;

  /// No description provided for @knKbQ.
  ///
  /// In en, this message translates to:
  /// **'Your documents, for the agents to look up'**
  String get knKbQ;

  /// No description provided for @knKbQueueError.
  ///
  /// In en, this message translates to:
  /// **'Stopped for a problem: {error}'**
  String knKbQueueError(String error);

  /// No description provided for @knKbRebuild.
  ///
  /// In en, this message translates to:
  /// **'Rebuild'**
  String get knKbRebuild;

  /// No description provided for @knKbRebuildHelp.
  ///
  /// In en, this message translates to:
  /// **'Reads everything again with the same model, from the start.'**
  String get knKbRebuildHelp;

  /// No description provided for @knKbRebuildQ.
  ///
  /// In en, this message translates to:
  /// **'Rebuild the index?'**
  String get knKbRebuildQ;

  /// No description provided for @knKbRebuildText.
  ///
  /// In en, this message translates to:
  /// **'Every piece is read again. The searches keep using the index of now until the new one is ready.'**
  String get knKbRebuildText;

  /// No description provided for @knKbRecommended.
  ///
  /// In en, this message translates to:
  /// **'recommended'**
  String get knKbRecommended;

  /// No description provided for @knKbRemove.
  ///
  /// In en, this message translates to:
  /// **'Delete the collection'**
  String get knKbRemove;

  /// No description provided for @knKbRemoveQ.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String knKbRemoveQ(String name);

  /// No description provided for @knKbRemoveSource.
  ///
  /// In en, this message translates to:
  /// **'Remove this source'**
  String get knKbRemoveSource;

  /// No description provided for @knKbRemoveText.
  ///
  /// In en, this message translates to:
  /// **'Its pieces leave the knowledge. Your files stay where they are: nothing on the disk is touched.'**
  String get knKbRemoveText;

  /// No description provided for @knKbRerankLead.
  ///
  /// In en, this message translates to:
  /// **'Reads the question with each piece found and reorders them: better answers, a little slower.'**
  String get knKbRerankLead;

  /// No description provided for @knKbRerankNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get knKbRerankNone;

  /// No description provided for @knKbRerankNoneText.
  ///
  /// In en, this message translates to:
  /// **'The order of the search itself'**
  String get knKbRerankNoneText;

  /// No description provided for @knKbRerankText.
  ///
  /// In en, this message translates to:
  /// **'On this computer · {size} MB'**
  String knKbRerankText(String size);

  /// No description provided for @knKbRerankTitle.
  ///
  /// In en, this message translates to:
  /// **'The one that puts the best first'**
  String get knKbRerankTitle;

  /// No description provided for @knKbRescan.
  ///
  /// In en, this message translates to:
  /// **'Look again now'**
  String get knKbRescan;

  /// No description provided for @knKbSaveScope.
  ///
  /// In en, this message translates to:
  /// **'Save who may read it'**
  String get knKbSaveScope;

  /// No description provided for @knKbScopeAgent.
  ///
  /// In en, this message translates to:
  /// **'One agent'**
  String get knKbScopeAgent;

  /// No description provided for @knKbScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Every agent'**
  String get knKbScopeAll;

  /// No description provided for @knKbScopeProject.
  ///
  /// In en, this message translates to:
  /// **'The agents of one project'**
  String get knKbScopeProject;

  /// No description provided for @knKbSection.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get knKbSection;

  /// No description provided for @knKbSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get knKbSources;

  /// No description provided for @knKbSrcChatsAll.
  ///
  /// In en, this message translates to:
  /// **'Your conversations, last {days} days'**
  String knKbSrcChatsAll(String days);

  /// No description provided for @knKbSrcChatsOf.
  ///
  /// In en, this message translates to:
  /// **'The conversations with {names}, last {days} days'**
  String knKbSrcChatsOf(String days, String names);

  /// No description provided for @knKbSrcDocs.
  ///
  /// In en, this message translates to:
  /// **'{n} documents'**
  String knKbSrcDocs(String n);

  /// No description provided for @knKbSrcMailOf.
  ///
  /// In en, this message translates to:
  /// **'The mail of the last {days} days'**
  String knKbSrcMailOf(String days);

  /// No description provided for @knKbSrcProjectOf.
  ///
  /// In en, this message translates to:
  /// **'The files of {name}'**
  String knKbSrcProjectOf(String name);

  /// No description provided for @knKbSrcState_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not read it'**
  String get knKbSrcState_failed;

  /// No description provided for @knKbSrcState_ready.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get knKbSrcState_ready;

  /// No description provided for @knKbSrcState_scanning.
  ///
  /// In en, this message translates to:
  /// **'Looking'**
  String get knKbSrcState_scanning;

  /// No description provided for @knKbSrcState_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get knKbSrcState_waiting;

  /// No description provided for @knKbStateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to search yet: make a collection and add a folder.'**
  String get knKbStateEmpty;

  /// No description provided for @knKbStateNoModel.
  ///
  /// In en, this message translates to:
  /// **'Choose a model below to search by meaning; until then it searches by words.'**
  String get knKbStateNoModel;

  /// No description provided for @knKbStateNoVector.
  ///
  /// In en, this message translates to:
  /// **'Searching by meaning is not ready on this computer yet: for now it searches by words.'**
  String get knKbStateNoVector;

  /// No description provided for @knKbStatePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused: the searches work, nothing new is read.'**
  String get knKbStatePaused;

  /// No description provided for @knKbStateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready: {n} pieces can be searched'**
  String knKbStateReady(String n);

  /// No description provided for @knKbStateWorking.
  ///
  /// In en, this message translates to:
  /// **'Reading your documents…'**
  String get knKbStateWorking;

  /// No description provided for @knKbStatusLine.
  ///
  /// In en, this message translates to:
  /// **'{cols} collections · {pieces} pieces'**
  String knKbStatusLine(String cols, String pieces);

  /// No description provided for @knKbThreads.
  ///
  /// In en, this message translates to:
  /// **'Processor threads'**
  String get knKbThreads;

  /// No description provided for @knKbThreadsAuto.
  ///
  /// In en, this message translates to:
  /// **'automatic'**
  String get knKbThreadsAuto;

  /// No description provided for @knKbThreadsHelp.
  ///
  /// In en, this message translates to:
  /// **'Automatic leaves most of the processor to you.'**
  String get knKbThreadsHelp;

  /// No description provided for @knKbThreadsTitle.
  ///
  /// In en, this message translates to:
  /// **'How much of the processor'**
  String get knKbThreadsTitle;

  /// No description provided for @knKbToDownload.
  ///
  /// In en, this message translates to:
  /// **'To download: {size} MB'**
  String knKbToDownload(String size);

  /// No description provided for @knKbTryExample.
  ///
  /// In en, this message translates to:
  /// **'When does the warranty end?'**
  String get knKbTryExample;

  /// No description provided for @knKbTryHow.
  ///
  /// In en, this message translates to:
  /// **'{n} pieces in {ms} ms, by meaning and by words.'**
  String knKbTryHow(String ms, String n);

  /// No description provided for @knKbTryLead.
  ///
  /// In en, this message translates to:
  /// **'What the agents would find for a question, best first. Click one to open it.'**
  String get knKbTryLead;

  /// No description provided for @knKbTryNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Try other words.'**
  String get knKbTryNothing;

  /// No description provided for @knKbTrySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get knKbTrySearch;

  /// No description provided for @knKbTryTitle.
  ///
  /// In en, this message translates to:
  /// **'Try a search'**
  String get knKbTryTitle;

  /// No description provided for @knKbTryWordsOnly.
  ///
  /// In en, this message translates to:
  /// **'Searched by words only (no model for the meaning yet).'**
  String get knKbTryWordsOnly;

  /// No description provided for @knKbUploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Send files from this computer'**
  String get knKbUploadFiles;

  /// No description provided for @knKbUploadFolder.
  ///
  /// In en, this message translates to:
  /// **'Send a folder from this computer'**
  String get knKbUploadFolder;

  /// No description provided for @knKbUploadSay.
  ///
  /// In en, this message translates to:
  /// **'Or drop files here. Sent files are kept in God\'s folder, under knowledge.'**
  String get knKbUploadSay;

  /// No description provided for @knKbUploading.
  ///
  /// In en, this message translates to:
  /// **'Sending the files…'**
  String get knKbUploading;

  /// No description provided for @knKbUrl.
  ///
  /// In en, this message translates to:
  /// **'The address'**
  String get knKbUrl;

  /// No description provided for @knKbUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'Read without your logins: only public pages.'**
  String get knKbUrlHelp;

  /// No description provided for @knKbWhichChats.
  ///
  /// In en, this message translates to:
  /// **'Whose conversations'**
  String get knKbWhichChats;

  /// No description provided for @knKbWhichMailbox.
  ///
  /// In en, this message translates to:
  /// **'Which mailbox'**
  String get knKbWhichMailbox;

  /// No description provided for @knKbWhichProject.
  ///
  /// In en, this message translates to:
  /// **'Which project'**
  String get knKbWhichProject;

  /// No description provided for @knKbWhyFailed.
  ///
  /// In en, this message translates to:
  /// **'It failed: {error}'**
  String knKbWhyFailed(String error);

  /// No description provided for @knKbWhy_binary.
  ///
  /// In en, this message translates to:
  /// **'Not a document (a program, an archive…)'**
  String get knKbWhy_binary;

  /// No description provided for @knKbWhy_empty.
  ///
  /// In en, this message translates to:
  /// **'There is no text in it'**
  String get knKbWhy_empty;

  /// No description provided for @knKbWhy_encrypted.
  ///
  /// In en, this message translates to:
  /// **'Protected by a password'**
  String get knKbWhy_encrypted;

  /// No description provided for @knKbWhy_needs_libreoffice.
  ///
  /// In en, this message translates to:
  /// **'An old Office file: it needs LibreOffice.'**
  String get knKbWhy_needs_libreoffice;

  /// No description provided for @knKbWhy_needs_ocr.
  ///
  /// In en, this message translates to:
  /// **'A picture or a scan: turn on reading the text in pictures, below.'**
  String get knKbWhy_needs_ocr;

  /// No description provided for @knKbWhy_too_big.
  ///
  /// In en, this message translates to:
  /// **'Too big to read'**
  String get knKbWhy_too_big;

  /// No description provided for @knKbWhy_unsupported.
  ///
  /// In en, this message translates to:
  /// **'A kind of file it cannot read'**
  String get knKbWhy_unsupported;

  /// No description provided for @knMemAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get knMemAdd;

  /// No description provided for @knMemAddPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Something to remember, e.g. I prefer short answers'**
  String get knMemAddPlaceholder;

  /// No description provided for @knMemAlready.
  ///
  /// In en, this message translates to:
  /// **'Already remembered.'**
  String get knMemAlready;

  /// No description provided for @knMemAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Off: Rasgeth learns nothing by itself. You can still add memories here, or ask an agent to remember something.'**
  String get knMemAutoOff;

  /// No description provided for @knMemAutoOn.
  ///
  /// In en, this message translates to:
  /// **'After you write, Rasgeth notes what stays true about you: tastes, work, how you like answers. It reads only your own messages, never emails, web pages or automations, and never notes passwords.'**
  String get knMemAutoOn;

  /// No description provided for @knMemAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn by itself from the conversations'**
  String get knMemAutoTitle;

  /// No description provided for @knMemByAgent.
  ///
  /// In en, this message translates to:
  /// **'Saved by {name}'**
  String knMemByAgent(String name);

  /// No description provided for @knMemByAgentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Saved by an agent'**
  String get knMemByAgentUnknown;

  /// No description provided for @knMemByAuto.
  ///
  /// In en, this message translates to:
  /// **'Learned by itself'**
  String get knMemByAuto;

  /// No description provided for @knMemByHuman.
  ///
  /// In en, this message translates to:
  /// **'Written by you'**
  String get knMemByHuman;

  /// No description provided for @knMemByImport.
  ///
  /// In en, this message translates to:
  /// **'From your old notes'**
  String get knMemByImport;

  /// No description provided for @knMemCount.
  ///
  /// In en, this message translates to:
  /// **'{n} memories'**
  String knMemCount(String n);

  /// No description provided for @knMemCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 memory'**
  String get knMemCountOne;

  /// No description provided for @knMemDid_added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get knMemDid_added;

  /// No description provided for @knMemDid_edited.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get knMemDid_edited;

  /// No description provided for @knMemDid_forgotten.
  ///
  /// In en, this message translates to:
  /// **'Forgotten for good'**
  String get knMemDid_forgotten;

  /// No description provided for @knMemDid_removed.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get knMemDid_removed;

  /// No description provided for @knMemEdit.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get knMemEdit;

  /// No description provided for @knMemEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Change the memory'**
  String get knMemEditTitle;

  /// No description provided for @knMemEmpty.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth knows nothing about you yet. Talk with an agent, or write here something to remember.'**
  String get knMemEmpty;

  /// No description provided for @knMemEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Shared memory'**
  String get knMemEyebrow;

  /// No description provided for @knMemForget.
  ///
  /// In en, this message translates to:
  /// **'Forget for good'**
  String get knMemForget;

  /// No description provided for @knMemForgetText.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth deletes it, and its words go from the list of changes too. It can never be brought back.'**
  String get knMemForgetText;

  /// No description provided for @knMemForgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget it for good?'**
  String get knMemForgetTitle;

  /// No description provided for @knMemForgottenText.
  ///
  /// In en, this message translates to:
  /// **'Its words are gone for good.'**
  String get knMemForgottenText;

  /// No description provided for @knMemFrom.
  ///
  /// In en, this message translates to:
  /// **'from «{title}»'**
  String knMemFrom(String title);

  /// No description provided for @knMemFromUntitled.
  ///
  /// In en, this message translates to:
  /// **'from a conversation'**
  String get knMemFromUntitled;

  /// No description provided for @knMemGoShared.
  ///
  /// In en, this message translates to:
  /// **'Shared memory: what Rasgeth knows about you'**
  String get knMemGoShared;

  /// No description provided for @knMemGoSharedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get knMemGoSharedOpen;

  /// No description provided for @knMemGoSharedText.
  ///
  /// In en, this message translates to:
  /// **'Used by every agent and updated by itself while you talk.'**
  String get knMemGoSharedText;

  /// No description provided for @knMemHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent changes'**
  String get knMemHistory;

  /// No description provided for @knMemHistoryLead.
  ///
  /// In en, this message translates to:
  /// **'Every change is kept and you can take it back, except forgetting for good.'**
  String get knMemHistoryLead;

  /// No description provided for @knMemHistoryLess.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get knMemHistoryLess;

  /// No description provided for @knMemHistoryMore.
  ///
  /// In en, this message translates to:
  /// **'Show all changes'**
  String get knMemHistoryMore;

  /// No description provided for @knMemLead.
  ///
  /// In en, this message translates to:
  /// **'Every agent uses this memory, and it updates by itself while you talk. Each agent also has a memory of its own, in the agent\'s Memory tab.'**
  String get knMemLead;

  /// No description provided for @knMemListLead.
  ///
  /// In en, this message translates to:
  /// **'Changes count from the next conversation: the ones already open go on as they were.'**
  String get knMemListLead;

  /// No description provided for @knMemListTitle.
  ///
  /// In en, this message translates to:
  /// **'What it remembers'**
  String get knMemListTitle;

  /// No description provided for @knMemNoOwn.
  ///
  /// In en, this message translates to:
  /// **'This agent keeps no memory of its own.'**
  String get knMemNoOwn;

  /// No description provided for @knMemOwnCard.
  ///
  /// In en, this message translates to:
  /// **'An agent\'s own memory'**
  String get knMemOwnCard;

  /// No description provided for @knMemOwnCardQ.
  ///
  /// In en, this message translates to:
  /// **'In each agent\'s Memory tab'**
  String get knMemOwnCardQ;

  /// No description provided for @knMemOwnCardText.
  ///
  /// In en, this message translates to:
  /// **'Only that agent reads it. You write it, or the agent notes what it needs for its work.'**
  String get knMemOwnCardText;

  /// No description provided for @knMemOwnHelp.
  ///
  /// In en, this message translates to:
  /// **'Only {name} reads it, at the start of every conversation. {name} can also note here what it needs.'**
  String knMemOwnHelp(String name);

  /// No description provided for @knMemOwnPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Always answer with a short list'**
  String get knMemOwnPlaceholder;

  /// No description provided for @knMemOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory of {name}: only for this agent'**
  String knMemOwnTitle(String name);

  /// No description provided for @knMemProjectHelp.
  ///
  /// In en, this message translates to:
  /// **'Every agent working on this project reads it.'**
  String get knMemProjectHelp;

  /// No description provided for @knMemProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory of the project «{name}»'**
  String knMemProjectTitle(String name);

  /// No description provided for @knMemRemove.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get knMemRemove;

  /// No description provided for @knMemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Memory deleted.'**
  String get knMemRemoved;

  /// No description provided for @knMemSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get knMemSaved;

  /// No description provided for @knMemSharedCard.
  ///
  /// In en, this message translates to:
  /// **'Shared memory'**
  String get knMemSharedCard;

  /// No description provided for @knMemSharedCardQ.
  ///
  /// In en, this message translates to:
  /// **'This page'**
  String get knMemSharedCardQ;

  /// No description provided for @knMemSharedCardText.
  ///
  /// In en, this message translates to:
  /// **'Every agent reads it. It fills up by itself from your conversations, and you can change it here.'**
  String get knMemSharedCardText;

  /// No description provided for @knMemSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summaries of long conversations'**
  String get knMemSummaryTitle;

  /// No description provided for @knMemTitle.
  ///
  /// In en, this message translates to:
  /// **'What Rasgeth knows about you'**
  String get knMemTitle;

  /// No description provided for @knMemUndid_added.
  ///
  /// In en, this message translates to:
  /// **'Brought back'**
  String get knMemUndid_added;

  /// No description provided for @knMemUndid_edited.
  ///
  /// In en, this message translates to:
  /// **'Back as it was'**
  String get knMemUndid_edited;

  /// No description provided for @knMemUndid_removed.
  ///
  /// In en, this message translates to:
  /// **'Taken away again'**
  String get knMemUndid_removed;

  /// No description provided for @knMemUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get knMemUndo;

  /// No description provided for @knMemUndone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get knMemUndone;

  /// No description provided for @knMemUsed.
  ///
  /// In en, this message translates to:
  /// **'Space used: {used} of {limit} characters'**
  String knMemUsed(String limit, String used);

  /// No description provided for @knMemWith.
  ///
  /// In en, this message translates to:
  /// **'with {name}'**
  String knMemWith(String name);

  /// No description provided for @knSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get knSettings;

  /// No description provided for @knUiAboutHours.
  ///
  /// In en, this message translates to:
  /// **'about {h} h {min} min left'**
  String knUiAboutHours(String h, String min);

  /// No description provided for @knUiAboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'about {min} min left'**
  String knUiAboutMinutes(String min);

  /// No description provided for @knUiLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'less than a minute left'**
  String get knUiLessThanMinute;

  /// No description provided for @knUiOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String knUiOf(String done, String total);

  /// No description provided for @knUiDetails.
  ///
  /// In en, this message translates to:
  /// **'Details for whoever helps you'**
  String get knUiDetails;

  /// No description provided for @knWzDoneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get knWzDoneBtn;

  /// No description provided for @knHubKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Your documents the agents can search: collections, sources, models'**
  String get knHubKnowledge;

  /// No description provided for @knHubMemory.
  ///
  /// In en, this message translates to:
  /// **'What every agent knows about you, with every change undoable'**
  String get knHubMemory;

  /// No description provided for @cvSaveFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get cvSaveFailedShort;

  /// No description provided for @cvSaveRetry.
  ///
  /// In en, this message translates to:
  /// **'Try saving again'**
  String get cvSaveRetry;

  /// No description provided for @cvReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get cvReadOnly;

  /// No description provided for @cvPastePicture.
  ///
  /// In en, this message translates to:
  /// **'Paste a picture'**
  String get cvPastePicture;

  /// No description provided for @cvPasteNone.
  ///
  /// In en, this message translates to:
  /// **'There is no picture on the clipboard'**
  String get cvPasteNone;

  /// No description provided for @cvAskedAgent.
  ///
  /// In en, this message translates to:
  /// **'Put in the conversation\'s message'**
  String get cvAskedAgent;

  /// The one-time notice of the new name (plan 3.9.0, choice 17): it names the old one on purpose.
  ///
  /// In en, this message translates to:
  /// **'RedGiant is now called Rasgeth.'**
  String get renameNoticeTitle;

  /// Under renameNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Only the name changes: your projects, conversations, agents and keys stay as they are. Say it «RAHS-get», with a hard g.'**
  String get renameNoticeText;

  /// Closes the notice for good (the page's renameOk).
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get renameNoticeOk;

  /// The server started without internet (3.9.1, the page's noInternet): parts lists what connects once it is back (Anthropic, Telegram...).
  ///
  /// In en, this message translates to:
  /// **'No internet. Waiting for the network: {parts} (the connection starts again by itself once it is back). Everything else works, local models included.'**
  String noInternetNotice(String parts);

  /// The page's `generating_image` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Generating a picture…'**
  String get cvGeneratingImage;

  /// The page's `generating_video` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Making a video…'**
  String get cvGeneratingVideo;

  /// The page's `generating_audio` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Making a sound…'**
  String get cvGeneratingAudio;

  /// The page's `imageUnreadable` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'This picture cannot be opened'**
  String get cvImageUnreadable;

  /// The page's `imageUnreachable` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Picture not available here: {name}'**
  String cvImageUnreachable(String name);

  /// The page's `mediaNativeTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Use the model\'s own tool when it has one'**
  String get cvMediaNativeTitle;

  /// The page's `mediaNativeHelp` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Some models make pictures by themselves (ChatGPT through Codex): then theirs is used, and the picture reaches you in the chat as with ours. Off: always the provider chosen here. Asking for «your tool» in a conversation always uses ours. New conversations follow this.'**
  String get cvMediaNativeHelp;

  /// Settings › Portrait (3.9.4, «Mirror»): the page's `pr*` words (packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get ptrSection;

  /// No description provided for @ptrHub.
  ///
  /// In en, this message translates to:
  /// **'How the agents see you, built from your conversations'**
  String get ptrHub;

  /// No description provided for @ptrTitle.
  ///
  /// In en, this message translates to:
  /// **'How the agents see you'**
  String get ptrTitle;

  /// No description provided for @ptrLead.
  ///
  /// In en, this message translates to:
  /// **'This portrait builds itself from your conversations: your tastes, how you like to be spoken to, your habits, what you are working on, what to avoid. The agents you choose read it when a conversation starts. Correct it whenever you like: your word always wins.'**
  String get ptrLead;

  /// No description provided for @ptrOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Build the portrait from the conversations'**
  String get ptrOnTitle;

  /// No description provided for @ptrOnOn.
  ///
  /// In en, this message translates to:
  /// **'After a conversation goes quiet, a light model reads only your own messages and updates the portrait. It never notes passwords, keys, email addresses, phone numbers or things about other people. It spends a little from your budget.'**
  String get ptrOnOn;

  /// No description provided for @ptrOnOff.
  ///
  /// In en, this message translates to:
  /// **'Off: the portrait does not change and no agent reads it. What is here stays until you delete it.'**
  String get ptrOnOff;

  /// No description provided for @ptrWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who reads it'**
  String get ptrWhoTitle;

  /// No description provided for @ptrWhoLead.
  ///
  /// In en, this message translates to:
  /// **'Changes count from the next conversation: the ones already open go on as they were.'**
  String get ptrWhoLead;

  /// No description provided for @ptrWho_god.
  ///
  /// In en, this message translates to:
  /// **'God'**
  String get ptrWho_god;

  /// No description provided for @ptrWho_orchestrators.
  ///
  /// In en, this message translates to:
  /// **'The projects\' orchestrators'**
  String get ptrWho_orchestrators;

  /// No description provided for @ptrWho_chat.
  ///
  /// In en, this message translates to:
  /// **'The Chat'**
  String get ptrWho_chat;

  /// No description provided for @ptrWho_others.
  ///
  /// In en, this message translates to:
  /// **'Every other agent'**
  String get ptrWho_others;

  /// No description provided for @ptrListTitle.
  ///
  /// In en, this message translates to:
  /// **'Traits'**
  String get ptrListTitle;

  /// No description provided for @ptrListLead.
  ///
  /// In en, this message translates to:
  /// **'Each trait says how sure it is and where it comes from. A trait no conversation says again fades with time.'**
  String get ptrListLead;

  /// No description provided for @ptrCount.
  ///
  /// In en, this message translates to:
  /// **'{n} traits'**
  String ptrCount(String n);

  /// No description provided for @ptrCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 trait'**
  String get ptrCountOne;

  /// No description provided for @ptrEmpty.
  ///
  /// In en, this message translates to:
  /// **'No traits yet: the portrait fills in as you talk with the agents.'**
  String get ptrEmpty;

  /// No description provided for @ptrEmptyOff.
  ///
  /// In en, this message translates to:
  /// **'The portrait is off and empty.'**
  String get ptrEmptyOff;

  /// No description provided for @ptrAddPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a trait yourself, e.g. I like answers with examples'**
  String get ptrAddPlaceholder;

  /// No description provided for @ptrAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get ptrAdd;

  /// No description provided for @ptrCat_preference.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get ptrCat_preference;

  /// No description provided for @ptrCat_style.
  ///
  /// In en, this message translates to:
  /// **'How to talk to you'**
  String get ptrCat_style;

  /// No description provided for @ptrCat_habit.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get ptrCat_habit;

  /// No description provided for @ptrCat_project.
  ///
  /// In en, this message translates to:
  /// **'Current projects'**
  String get ptrCat_project;

  /// No description provided for @ptrCat_avoid.
  ///
  /// In en, this message translates to:
  /// **'To avoid'**
  String get ptrCat_avoid;

  /// No description provided for @ptrCat_about.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get ptrCat_about;

  /// No description provided for @ptrSure.
  ///
  /// In en, this message translates to:
  /// **'Sure'**
  String get ptrSure;

  /// No description provided for @ptrLikely.
  ///
  /// In en, this message translates to:
  /// **'Likely'**
  String get ptrLikely;

  /// No description provided for @ptrUnsure.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get ptrUnsure;

  /// No description provided for @ptrByYou.
  ///
  /// In en, this message translates to:
  /// **'Written by you'**
  String get ptrByYou;

  /// No description provided for @ptrSeen.
  ///
  /// In en, this message translates to:
  /// **'seen {n} times'**
  String ptrSeen(String n);

  /// No description provided for @ptrSeenOnce.
  ///
  /// In en, this message translates to:
  /// **'seen once'**
  String get ptrSeenOnce;

  /// No description provided for @ptrWhere.
  ///
  /// In en, this message translates to:
  /// **'Where it comes from'**
  String get ptrWhere;

  /// No description provided for @ptrUntitled.
  ///
  /// In en, this message translates to:
  /// **'A conversation'**
  String get ptrUntitled;

  /// No description provided for @ptrWith.
  ///
  /// In en, this message translates to:
  /// **'with {name}'**
  String ptrWith(String name);

  /// No description provided for @ptrEdit.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get ptrEdit;

  /// No description provided for @ptrRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get ptrRemove;

  /// No description provided for @ptrDeny.
  ///
  /// In en, this message translates to:
  /// **'Not true'**
  String get ptrDeny;

  /// No description provided for @ptrEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Change the trait'**
  String get ptrEditTitle;

  /// No description provided for @ptrEditNote.
  ///
  /// In en, this message translates to:
  /// **'Once you change it, the trait is yours: it never fades and nothing changes it by itself.'**
  String get ptrEditNote;

  /// No description provided for @ptrDenied.
  ///
  /// In en, this message translates to:
  /// **'{n} traits you said are not true: they will not be proposed again.'**
  String ptrDenied(String n);

  /// No description provided for @ptrDeniedOne.
  ///
  /// In en, this message translates to:
  /// **'1 trait you said is not true: it will not be proposed again.'**
  String get ptrDeniedOne;

  /// No description provided for @ptrTextTitle.
  ///
  /// In en, this message translates to:
  /// **'What the agents read'**
  String get ptrTextTitle;

  /// No description provided for @ptrTextLead.
  ///
  /// In en, this message translates to:
  /// **'The portrait exactly as it goes into a new conversation, short and always the same until it changes.'**
  String get ptrTextLead;

  /// No description provided for @ptrTextShow.
  ///
  /// In en, this message translates to:
  /// **'Show the text'**
  String get ptrTextShow;

  /// No description provided for @ptrTextHide.
  ///
  /// In en, this message translates to:
  /// **'Hide the text'**
  String get ptrTextHide;

  /// No description provided for @ptrForgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget everything'**
  String get ptrForgetTitle;

  /// No description provided for @ptrForgetLead.
  ///
  /// In en, this message translates to:
  /// **'Every trait goes, and its words go from the history too. It cannot be undone.'**
  String get ptrForgetLead;

  /// No description provided for @ptrForgetText.
  ///
  /// In en, this message translates to:
  /// **'Every trait of the portrait is deleted and its words erased from the history, the «not true» ones too. The portrait starts again empty.'**
  String get ptrForgetText;

  /// No description provided for @ptrForget.
  ///
  /// In en, this message translates to:
  /// **'Forget everything'**
  String get ptrForget;

  /// No description provided for @ptrErr_empty.
  ///
  /// In en, this message translates to:
  /// **'Write the trait.'**
  String get ptrErr_empty;

  /// No description provided for @ptrErr_long.
  ///
  /// In en, this message translates to:
  /// **'A trait is at most 200 characters: write it shorter.'**
  String get ptrErr_long;

  /// No description provided for @ptrErr_secret.
  ///
  /// In en, this message translates to:
  /// **'That looks like a password, a code or a card number: secrets never go into the portrait.'**
  String get ptrErr_secret;

  /// No description provided for @ptrErr_private.
  ///
  /// In en, this message translates to:
  /// **'Email addresses and phone numbers never go into the portrait.'**
  String get ptrErr_private;

  /// No description provided for @ptrErr_gone.
  ///
  /// In en, this message translates to:
  /// **'That trait is not there any more.'**
  String get ptrErr_gone;

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Tool groups'**
  String get tkTitle;

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Agents start with few tools, to keep every message light. The other groups are off by default: an agent switches one on by itself when the work needs it, for that conversation. Always on: the agent has it from the start. Off by you: the agent has to ask you.'**
  String get tkLead;

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'The groups for {name}: as for every agent, or a choice of its own.'**
  String tkAgentLead(String name);

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Off by default'**
  String get tkAuto;

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get tkOn;

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Off by you'**
  String get tkOff;

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'As for everyone: {state}'**
  String tkAsAll(String state);

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get tkIsDefault;

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'on for its role'**
  String get tkRole;

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'about {n} tokens when on'**
  String tkWeight(String n);

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Essential tools, always on: about {n} tokens'**
  String tkEssential(String n);

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'At the start: about {n} tokens in every message'**
  String tkStartTotal(String n);

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Off at the start: {n} tokens that weigh only if a group is switched on'**
  String tkRest(String n);

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'Tools: {list}'**
  String tkTools(String list);

  /// The page's `kit…` words (3.9.4, packages/web/src/i18n.ts).
  ///
  /// In en, this message translates to:
  /// **'off by default'**
  String get tkStateAuto;

  /// The page's `mascotSubHelp` (packages/web/src/i18n.ts): a sub-agent's card, instead of «Change mascot».
  ///
  /// In en, this message translates to:
  /// **'A sub-agent has no mascot of its own: it lives for one task, and shows a ring in its parent\'s colour.'**
  String get asMascotSub;

  /// No description provided for @auAsstNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get auAsstNewRoutine;

  /// No description provided for @auAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off: it does not run until you switch it on.'**
  String get auAutoOff;

  /// No description provided for @auAutoOn.
  ///
  /// In en, this message translates to:
  /// **'Switched on'**
  String get auAutoOn;

  /// No description provided for @auAutoStart.
  ///
  /// In en, this message translates to:
  /// **'Start from'**
  String get auAutoStart;

  /// No description provided for @auAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'What it is called'**
  String get auAutoTitle;

  /// No description provided for @auAutoTitleHelp.
  ///
  /// In en, this message translates to:
  /// **'A short name, for you.'**
  String get auAutoTitleHelp;

  /// No description provided for @auAutoWhat.
  ///
  /// In en, this message translates to:
  /// **'What to ask'**
  String get auAutoWhat;

  /// No description provided for @auAutoWhatHelp.
  ///
  /// In en, this message translates to:
  /// **'As you would write it in a chat. The answer reaches you on Telegram.'**
  String get auAutoWhatHelp;

  /// No description provided for @auAutoWho.
  ///
  /// In en, this message translates to:
  /// **'Who does it'**
  String get auAutoWho;

  /// No description provided for @auAutoWhoHelp.
  ///
  /// In en, this message translates to:
  /// **'God sees every project; a project\'s lead and agents only theirs.'**
  String get auAutoWhoHelp;

  /// No description provided for @auAutoYaml.
  ///
  /// In en, this message translates to:
  /// **'The recipe (for experts)'**
  String get auAutoYaml;

  /// No description provided for @auAutoYamlHint.
  ///
  /// In en, this message translates to:
  /// **'What the form writes. Changed here, it is saved as it is.'**
  String get auAutoYamlHint;

  /// No description provided for @auAutomationNotices.
  ///
  /// In en, this message translates to:
  /// **'Automation messages'**
  String get auAutomationNotices;

  /// No description provided for @auAutomations.
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get auAutomations;

  /// No description provided for @auAwChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get auAwChange;

  /// No description provided for @auAwLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last run'**
  String get auAwLastRun;

  /// No description provided for @auAwLead.
  ///
  /// In en, this message translates to:
  /// **'An automation asks an agent to do something at a time or when something happens; a reminder sends you a message on a day. The lit squares are switched on.'**
  String get auAwLead;

  /// No description provided for @auAwListLead.
  ///
  /// In en, this message translates to:
  /// **'Open one to switch it on or off, run it now, change it or read how it went.'**
  String get auAwListLead;

  /// No description provided for @auAwListTitle.
  ///
  /// In en, this message translates to:
  /// **'Your automations'**
  String get auAwListTitle;

  /// No description provided for @auAwNewText.
  ///
  /// In en, this message translates to:
  /// **'An agent does something for you: every morning, every week, on an email or a push.'**
  String get auAwNewText;

  /// No description provided for @auAwQ.
  ///
  /// In en, this message translates to:
  /// **'What should Rasgeth do on its own?'**
  String get auAwQ;

  /// No description provided for @auAwReminderText.
  ///
  /// In en, this message translates to:
  /// **'A message for you on the day and at the time you choose, as you wrote it.'**
  String get auAwReminderText;

  /// No description provided for @auAwSourcesLead.
  ///
  /// In en, this message translates to:
  /// **'What automations can listen to besides the clock.'**
  String get auAwSourcesLead;

  /// No description provided for @auAwSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get auAwSourcesTitle;

  /// No description provided for @auAwStarted.
  ///
  /// In en, this message translates to:
  /// **'Started: its run appears below in a moment.'**
  String get auAwStarted;

  /// No description provided for @auAxAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get auAxAdvanced;

  /// No description provided for @auAxAfterWhich.
  ///
  /// In en, this message translates to:
  /// **'Which automation'**
  String get auAxAfterWhich;

  /// No description provided for @auAxAfter_failed.
  ///
  /// In en, this message translates to:
  /// **'When it failed'**
  String get auAxAfter_failed;

  /// No description provided for @auAxAfter_ok.
  ///
  /// In en, this message translates to:
  /// **'When it went well'**
  String get auAxAfter_ok;

  /// No description provided for @auAxAfter_timeout.
  ///
  /// In en, this message translates to:
  /// **'When it took too long'**
  String get auAxAfter_timeout;

  /// No description provided for @auAxAgentOwn.
  ///
  /// In en, this message translates to:
  /// **'The agent\'s own'**
  String get auAxAgentOwn;

  /// No description provided for @auAxAnyChat.
  ///
  /// In en, this message translates to:
  /// **'any chat'**
  String get auAxAnyChat;

  /// No description provided for @auAxAnyProject.
  ///
  /// In en, this message translates to:
  /// **'Any project'**
  String get auAxAnyProject;

  /// No description provided for @auAxApprove.
  ///
  /// In en, this message translates to:
  /// **'Ask me before acting'**
  String get auAxApprove;

  /// No description provided for @auAxApproveHelp.
  ///
  /// In en, this message translates to:
  /// **'You get a question here and on your chats; without your yes it does not start.'**
  String get auAxApproveHelp;

  /// No description provided for @auAxBudget.
  ///
  /// In en, this message translates to:
  /// **'A spending limit each time'**
  String get auAxBudget;

  /// No description provided for @auAxBudgetHelp.
  ///
  /// In en, this message translates to:
  /// **'Past it, the agent stops.'**
  String get auAxBudgetHelp;

  /// No description provided for @auAxBudgetUsd.
  ///
  /// In en, this message translates to:
  /// **'Dollars at most'**
  String get auAxBudgetUsd;

  /// No description provided for @auAxCat_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get auAxCat_other;

  /// No description provided for @auAxCat_personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get auAxCat_personal;

  /// No description provided for @auAxCat_social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get auAxCat_social;

  /// No description provided for @auAxCat_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get auAxCat_work;

  /// No description provided for @auAxCondCooldown.
  ///
  /// In en, this message translates to:
  /// **'A pause between one time and the next'**
  String get auAxCondCooldown;

  /// No description provided for @auAxCondDates.
  ///
  /// In en, this message translates to:
  /// **'Only in a period'**
  String get auAxCondDates;

  /// No description provided for @auAxCondDays.
  ///
  /// In en, this message translates to:
  /// **'Only on certain days'**
  String get auAxCondDays;

  /// No description provided for @auAxCondFrom.
  ///
  /// In en, this message translates to:
  /// **'Only from certain senders'**
  String get auAxCondFrom;

  /// No description provided for @auAxCondFromHelp.
  ///
  /// In en, this message translates to:
  /// **'For emails and chat messages.'**
  String get auAxCondFromHelp;

  /// No description provided for @auAxCondHours.
  ///
  /// In en, this message translates to:
  /// **'Only at certain hours'**
  String get auAxCondHours;

  /// No description provided for @auAxCondMax.
  ///
  /// In en, this message translates to:
  /// **'Not too many times a day'**
  String get auAxCondMax;

  /// No description provided for @auAxCondWithout.
  ///
  /// In en, this message translates to:
  /// **'Never with certain words'**
  String get auAxCondWithout;

  /// No description provided for @auAxCondWords.
  ///
  /// In en, this message translates to:
  /// **'Only with certain words'**
  String get auAxCondWords;

  /// No description provided for @auAxCooldown.
  ///
  /// In en, this message translates to:
  /// **'Minutes of pause'**
  String get auAxCooldown;

  /// No description provided for @auAxCron.
  ///
  /// In en, this message translates to:
  /// **'Cron expression'**
  String get auAxCron;

  /// No description provided for @auAxCronHelp.
  ///
  /// In en, this message translates to:
  /// **'Minute, hour, day of the month, month, day of the week: 0 9 * * 1-5 is 9:00 on working days.'**
  String get auAxCronHelp;

  /// No description provided for @auAxDoes.
  ///
  /// In en, this message translates to:
  /// **'What it does'**
  String get auAxDoes;

  /// No description provided for @auAxDoesAgent.
  ///
  /// In en, this message translates to:
  /// **'An agent works'**
  String get auAxDoesAgent;

  /// No description provided for @auAxDoesHelp.
  ///
  /// In en, this message translates to:
  /// **'An agent does some work, or a plain message reaches you as written.'**
  String get auAxDoesHelp;

  /// No description provided for @auAxDoesReminder.
  ///
  /// In en, this message translates to:
  /// **'Just a message'**
  String get auAxDoesReminder;

  /// No description provided for @auAxEffort.
  ///
  /// In en, this message translates to:
  /// **'Effort'**
  String get auAxEffort;

  /// No description provided for @auAxEmailAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get auAxEmailAll;

  /// No description provided for @auAxEmailByBox.
  ///
  /// In en, this message translates to:
  /// **'Some mailboxes'**
  String get auAxEmailByBox;

  /// No description provided for @auAxEmailByCategory.
  ///
  /// In en, this message translates to:
  /// **'A category'**
  String get auAxEmailByCategory;

  /// No description provided for @auAxEmailText.
  ///
  /// In en, this message translates to:
  /// **'The text contains'**
  String get auAxEmailText;

  /// No description provided for @auAxEmailTextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'A word in the email (optional)'**
  String get auAxEmailTextPlaceholder;

  /// No description provided for @auAxEmailWhich.
  ///
  /// In en, this message translates to:
  /// **'Which mailboxes'**
  String get auAxEmailWhich;

  /// No description provided for @auAxEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every how many minutes'**
  String get auAxEveryMinutes;

  /// No description provided for @auAxFallback.
  ///
  /// In en, this message translates to:
  /// **'Then start'**
  String get auAxFallback;

  /// No description provided for @auAxFilesPath.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get auAxFilesPath;

  /// No description provided for @auAxFilesPathHelp.
  ///
  /// In en, this message translates to:
  /// **'Inside the project; a dot is the whole project.'**
  String get auAxFilesPathHelp;

  /// No description provided for @auAxFilesPattern.
  ///
  /// In en, this message translates to:
  /// **'Only these files'**
  String get auAxFilesPattern;

  /// No description provided for @auAxFilesPatternHelp.
  ///
  /// In en, this message translates to:
  /// **'For example *.pdf; empty: every file.'**
  String get auAxFilesPatternHelp;

  /// No description provided for @auAxFilesProjectHelp.
  ///
  /// In en, this message translates to:
  /// **'Make a project first: the folder is inside one.'**
  String get auAxFilesProjectHelp;

  /// No description provided for @auAxFiles_added.
  ///
  /// In en, this message translates to:
  /// **'New files'**
  String get auAxFiles_added;

  /// No description provided for @auAxFiles_changed.
  ///
  /// In en, this message translates to:
  /// **'Changed files'**
  String get auAxFiles_changed;

  /// No description provided for @auAxFiles_removed.
  ///
  /// In en, this message translates to:
  /// **'Deleted files'**
  String get auAxFiles_removed;

  /// No description provided for @auAxFirstBox.
  ///
  /// In en, this message translates to:
  /// **'The first mailbox'**
  String get auAxFirstBox;

  /// No description provided for @auAxFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get auAxFrom;

  /// No description provided for @auAxFromDay.
  ///
  /// In en, this message translates to:
  /// **'From the day'**
  String get auAxFromDay;

  /// No description provided for @auAxIfFails.
  ///
  /// In en, this message translates to:
  /// **'If it fails'**
  String get auAxIfFails;

  /// No description provided for @auAxKind_custom.
  ///
  /// In en, this message translates to:
  /// **'Written by hand (cron)'**
  String get auAxKind_custom;

  /// No description provided for @auAxKind_minutes.
  ///
  /// In en, this message translates to:
  /// **'Every few minutes'**
  String get auAxKind_minutes;

  /// No description provided for @auAxKind_once.
  ///
  /// In en, this message translates to:
  /// **'Once, on a day'**
  String get auAxKind_once;

  /// No description provided for @auAxMagic.
  ///
  /// In en, this message translates to:
  /// **'Magic automation'**
  String get auAxMagic;

  /// No description provided for @auAxMagicAllSet.
  ///
  /// In en, this message translates to:
  /// **'Everything it needs is there.'**
  String get auAxMagicAllSet;

  /// No description provided for @auAxMagicApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve and create'**
  String get auAxMagicApprove;

  /// No description provided for @auAxMagicAsk.
  ///
  /// In en, this message translates to:
  /// **'What should happen?'**
  String get auAxMagicAsk;

  /// No description provided for @auAxMagicBuilding.
  ///
  /// In en, this message translates to:
  /// **'God is building it with you: answer its questions in the conversation.'**
  String get auAxMagicBuilding;

  /// No description provided for @auAxMagicDismiss.
  ///
  /// In en, this message translates to:
  /// **'Put it away'**
  String get auAxMagicDismiss;

  /// No description provided for @auAxMagicDone.
  ///
  /// In en, this message translates to:
  /// **'Approved: it is among your automations now.'**
  String get auAxMagicDone;

  /// No description provided for @auAxMagicEdit.
  ///
  /// In en, this message translates to:
  /// **'Change it first'**
  String get auAxMagicEdit;

  /// No description provided for @auAxMagicEx1.
  ///
  /// In en, this message translates to:
  /// **'Every day at 3 check my Revolut account and tell me on WhatsApp if I received or paid money'**
  String get auAxMagicEx1;

  /// No description provided for @auAxMagicEx2.
  ///
  /// In en, this message translates to:
  /// **'When an invoice arrives in my work mailbox, save it in the project and tell me the amount'**
  String get auAxMagicEx2;

  /// No description provided for @auAxMagicEx3.
  ///
  /// In en, this message translates to:
  /// **'When I write «shopping:» on Telegram, add it to the shopping list and send me the list on Saturday'**
  String get auAxMagicEx3;

  /// No description provided for @auAxMagicExamples.
  ///
  /// In en, this message translates to:
  /// **'Or start from an example'**
  String get auAxMagicExamples;

  /// No description provided for @auAxMagicGo.
  ///
  /// In en, this message translates to:
  /// **'Ask God'**
  String get auAxMagicGo;

  /// No description provided for @auAxMagicLead.
  ///
  /// In en, this message translates to:
  /// **'Write what should happen, as you would say it to a person. God answers in a conversation of its own and builds the automation with you.'**
  String get auAxMagicLead;

  /// No description provided for @auAxMagicListLead.
  ///
  /// In en, this message translates to:
  /// **'Built with God: open one to go on with the conversation.'**
  String get auAxMagicListLead;

  /// No description provided for @auAxMagicListTitle.
  ///
  /// In en, this message translates to:
  /// **'Magic automations'**
  String get auAxMagicListTitle;

  /// No description provided for @auAxMagicMissing.
  ///
  /// In en, this message translates to:
  /// **'Before you can approve, set up what is missing:'**
  String get auAxMagicMissing;

  /// No description provided for @auAxMagicNeeds.
  ///
  /// In en, this message translates to:
  /// **'Still needed'**
  String get auAxMagicNeeds;

  /// No description provided for @auAxMagicPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Every day at 3 check my bank account and tell me on WhatsApp what came in and what went out'**
  String get auAxMagicPlaceholder;

  /// No description provided for @auAxMagicPromise1.
  ///
  /// In en, this message translates to:
  /// **'Nothing starts without your yes.'**
  String get auAxMagicPromise1;

  /// No description provided for @auAxMagicPromise2.
  ///
  /// In en, this message translates to:
  /// **'New tools and skills are tried apart and wait for you.'**
  String get auAxMagicPromise2;

  /// No description provided for @auAxMagicPromise3.
  ///
  /// In en, this message translates to:
  /// **'Keys and passwords never go in the chat: God tells you where to put them.'**
  String get auAxMagicPromise3;

  /// No description provided for @auAxMagicProposal.
  ///
  /// In en, this message translates to:
  /// **'God\'s proposal'**
  String get auAxMagicProposal;

  /// No description provided for @auAxMagicReadyBadge.
  ///
  /// In en, this message translates to:
  /// **'To approve'**
  String get auAxMagicReadyBadge;

  /// No description provided for @auAxMagicReject.
  ///
  /// In en, this message translates to:
  /// **'Not like this'**
  String get auAxMagicReject;

  /// No description provided for @auAxMagicSendNo.
  ///
  /// In en, this message translates to:
  /// **'Send to God'**
  String get auAxMagicSendNo;

  /// No description provided for @auAxMagicStarting.
  ///
  /// In en, this message translates to:
  /// **'Calling God…'**
  String get auAxMagicStarting;

  /// No description provided for @auAxMagicState_building.
  ///
  /// In en, this message translates to:
  /// **'Being built'**
  String get auAxMagicState_building;

  /// No description provided for @auAxMagicState_dismissed.
  ///
  /// In en, this message translates to:
  /// **'Put away'**
  String get auAxMagicState_dismissed;

  /// No description provided for @auAxMagicState_done.
  ///
  /// In en, this message translates to:
  /// **'Approved and created'**
  String get auAxMagicState_done;

  /// No description provided for @auAxMagicState_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready: God waits for your yes'**
  String get auAxMagicState_ready;

  /// No description provided for @auAxMagicStep1.
  ///
  /// In en, this message translates to:
  /// **'You say what you want'**
  String get auAxMagicStep1;

  /// No description provided for @auAxMagicStep2.
  ///
  /// In en, this message translates to:
  /// **'God proposes it'**
  String get auAxMagicStep2;

  /// No description provided for @auAxMagicStep3.
  ///
  /// In en, this message translates to:
  /// **'You approve it'**
  String get auAxMagicStep3;

  /// No description provided for @auAxMagicTile.
  ///
  /// In en, this message translates to:
  /// **'Tell God what you want, in your words: it asks what it needs, builds what is missing and shows it to you before anything starts.'**
  String get auAxMagicTile;

  /// No description provided for @auAxMagicWhy.
  ///
  /// In en, this message translates to:
  /// **'What is wrong? God reads it and tries again'**
  String get auAxMagicWhy;

  /// No description provided for @auAxMailboxesWatching.
  ///
  /// In en, this message translates to:
  /// **'{n} mailboxes connected: {names}.'**
  String auAxMailboxesWatching(String n, String names);

  /// No description provided for @auAxMatchAll.
  ///
  /// In en, this message translates to:
  /// **'All of them'**
  String get auAxMatchAll;

  /// No description provided for @auAxMatchAny.
  ///
  /// In en, this message translates to:
  /// **'At least one'**
  String get auAxMatchAny;

  /// No description provided for @auAxMaxPerDay.
  ///
  /// In en, this message translates to:
  /// **'At most, times a day'**
  String get auAxMaxPerDay;

  /// No description provided for @auAxMessageChat.
  ///
  /// In en, this message translates to:
  /// **'Only in this chat'**
  String get auAxMessageChat;

  /// No description provided for @auAxMessageChatHelp.
  ///
  /// In en, this message translates to:
  /// **'The chat\'s number, for a group; empty: any chat.'**
  String get auAxMessageChatHelp;

  /// No description provided for @auAxMessageFrom.
  ///
  /// In en, this message translates to:
  /// **'From whom'**
  String get auAxMessageFrom;

  /// No description provided for @auAxMessageFromHelp.
  ///
  /// In en, this message translates to:
  /// **'Part of the name or the number; empty: anyone linked.'**
  String get auAxMessageFromHelp;

  /// No description provided for @auAxMessageHandle.
  ///
  /// In en, this message translates to:
  /// **'The message is for the automation only'**
  String get auAxMessageHandle;

  /// No description provided for @auAxMessageHandleHelp.
  ///
  /// In en, this message translates to:
  /// **'Demi-God does not answer it: the automation does.'**
  String get auAxMessageHandleHelp;

  /// No description provided for @auAxMessageWhere.
  ///
  /// In en, this message translates to:
  /// **'On which chats (none chosen: all of them)'**
  String get auAxMessageWhere;

  /// No description provided for @auAxMessageWords.
  ///
  /// In en, this message translates to:
  /// **'With which words'**
  String get auAxMessageWords;

  /// No description provided for @auAxMessageWordsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'shopping, /expense'**
  String get auAxMessageWordsPlaceholder;

  /// No description provided for @auAxMissed.
  ///
  /// In en, this message translates to:
  /// **'If Rasgeth was off at its time'**
  String get auAxMissed;

  /// No description provided for @auAxMissedRun.
  ///
  /// In en, this message translates to:
  /// **'Do it as soon as it is on'**
  String get auAxMissedRun;

  /// No description provided for @auAxMissedSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip it'**
  String get auAxMissedSkip;

  /// No description provided for @auAxModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get auAxModel;

  /// No description provided for @auAxModelHelp.
  ///
  /// In en, this message translates to:
  /// **'Empty: the agent\'s own.'**
  String get auAxModelHelp;

  /// No description provided for @auAxNeedMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get auAxNeedMissing;

  /// No description provided for @auAxNeedOpen.
  ///
  /// In en, this message translates to:
  /// **'Set it up'**
  String get auAxNeedOpen;

  /// No description provided for @auAxNeedReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get auAxNeedReady;

  /// No description provided for @auAxNeedVault.
  ///
  /// In en, this message translates to:
  /// **'Add to the keychain'**
  String get auAxNeedVault;

  /// No description provided for @auAxNeed_chat.
  ///
  /// In en, this message translates to:
  /// **'The chat {what}'**
  String auAxNeed_chat(String what);

  /// No description provided for @auAxNeed_credential.
  ///
  /// In en, this message translates to:
  /// **'The key for {what}'**
  String auAxNeed_credential(String what);

  /// No description provided for @auAxNeed_email.
  ///
  /// In en, this message translates to:
  /// **'A mailbox'**
  String get auAxNeed_email;

  /// No description provided for @auAxNeed_extension.
  ///
  /// In en, this message translates to:
  /// **'The extension {what}'**
  String auAxNeed_extension(String what);

  /// No description provided for @auAxNeed_other.
  ///
  /// In en, this message translates to:
  /// **'{what}'**
  String auAxNeed_other(String what);

  /// No description provided for @auAxNextNone.
  ///
  /// In en, this message translates to:
  /// **'With these conditions it never starts at its times: check the hours and the days.'**
  String get auAxNextNone;

  /// No description provided for @auAxNextTimes.
  ///
  /// In en, this message translates to:
  /// **'Next times'**
  String get auAxNextTimes;

  /// No description provided for @auAxNightHours.
  ///
  /// In en, this message translates to:
  /// **'At night'**
  String get auAxNightHours;

  /// No description provided for @auAxNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get auAxNone;

  /// No description provided for @auAxOnceAt.
  ///
  /// In en, this message translates to:
  /// **'Day and time'**
  String get auAxOnceAt;

  /// No description provided for @auAxOnly.
  ///
  /// In en, this message translates to:
  /// **'Only if'**
  String get auAxOnly;

  /// No description provided for @auAxOnlyHelp.
  ///
  /// In en, this message translates to:
  /// **'Conditions it must meet to start; all the ones you switch on, together. Starting it by hand ignores them.'**
  String get auAxOnlyHelp;

  /// No description provided for @auAxOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get auAxOr;

  /// No description provided for @auAxOverlap.
  ///
  /// In en, this message translates to:
  /// **'If it is still working when it should start again'**
  String get auAxOverlap;

  /// No description provided for @auAxOverlapQueue.
  ///
  /// In en, this message translates to:
  /// **'Wait, then start'**
  String get auAxOverlapQueue;

  /// No description provided for @auAxOverlapSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip that time'**
  String get auAxOverlapSkip;

  /// No description provided for @auAxPick.
  ///
  /// In en, this message translates to:
  /// **'Choose…'**
  String get auAxPick;

  /// No description provided for @auAxRetries.
  ///
  /// In en, this message translates to:
  /// **'Try again, how many times'**
  String get auAxRetries;

  /// No description provided for @auAxRetryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes between tries'**
  String get auAxRetryMinutes;

  /// No description provided for @auAxRunQueued.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get auAxRunQueued;

  /// No description provided for @auAxRunTriggers.
  ///
  /// In en, this message translates to:
  /// **'email,chat message,files,another automation,task,startup,new try'**
  String get auAxRunTriggers;

  /// No description provided for @auAxSayAfter.
  ///
  /// In en, this message translates to:
  /// **'After «{name}»'**
  String auAxSayAfter(String name);

  /// No description provided for @auAxSayApprove.
  ///
  /// In en, this message translates to:
  /// **'First it asks for your yes.'**
  String get auAxSayApprove;

  /// No description provided for @auAxSayBudget.
  ///
  /// In en, this message translates to:
  /// **'It spends at most \${usd} each time.'**
  String auAxSayBudget(String usd);

  /// No description provided for @auAxSayCooldown.
  ///
  /// In en, this message translates to:
  /// **'at least {n} minutes apart'**
  String auAxSayCooldown(String n);

  /// No description provided for @auAxSayDates.
  ///
  /// In en, this message translates to:
  /// **'from {from} to {to}'**
  String auAxSayDates(String from, String to);

  /// No description provided for @auAxSayDays.
  ///
  /// In en, this message translates to:
  /// **'on {days}'**
  String auAxSayDays(String days);

  /// No description provided for @auAxSayDoes.
  ///
  /// In en, this message translates to:
  /// **'{who} does: «{what}».'**
  String auAxSayDoes(String who, String what);

  /// No description provided for @auAxSayEmail.
  ///
  /// In en, this message translates to:
  /// **'When an email arrives ({filter})'**
  String auAxSayEmail(String filter);

  /// No description provided for @auAxSayFiles.
  ///
  /// In en, this message translates to:
  /// **'When files change in {path}'**
  String auAxSayFiles(String path);

  /// No description provided for @auAxSayFilesAll.
  ///
  /// In en, this message translates to:
  /// **'When files change in the project'**
  String get auAxSayFilesAll;

  /// No description provided for @auAxSayFrom.
  ///
  /// In en, this message translates to:
  /// **'from {from}'**
  String auAxSayFrom(String from);

  /// No description provided for @auAxSayHours.
  ///
  /// In en, this message translates to:
  /// **'between {from} and {to}'**
  String auAxSayHours(String from, String to);

  /// No description provided for @auAxSayMax.
  ///
  /// In en, this message translates to:
  /// **'at most {n} times a day'**
  String auAxSayMax(String n);

  /// No description provided for @auAxSayMessage.
  ///
  /// In en, this message translates to:
  /// **'When you get a message on {where}'**
  String auAxSayMessage(String where);

  /// No description provided for @auAxSayNever.
  ///
  /// In en, this message translates to:
  /// **'Choose when it starts.'**
  String get auAxSayNever;

  /// No description provided for @auAxSayOnly.
  ///
  /// In en, this message translates to:
  /// **'Only'**
  String get auAxSayOnly;

  /// No description provided for @auAxSayQuiet.
  ///
  /// In en, this message translates to:
  /// **'It does not tell you.'**
  String get auAxSayQuiet;

  /// No description provided for @auAxSayReminder.
  ///
  /// In en, this message translates to:
  /// **'You get the message: «{text}».'**
  String auAxSayReminder(String text);

  /// No description provided for @auAxSayStartup.
  ///
  /// In en, this message translates to:
  /// **'When Rasgeth starts'**
  String get auAxSayStartup;

  /// No description provided for @auAxSayTask.
  ///
  /// In en, this message translates to:
  /// **'When a task ends'**
  String get auAxSayTask;

  /// No description provided for @auAxSayTell.
  ///
  /// In en, this message translates to:
  /// **'It tells you on {where}.'**
  String auAxSayTell(String where);

  /// No description provided for @auAxSayTellFailure.
  ///
  /// In en, this message translates to:
  /// **'It tells you on {where}, only if something goes wrong.'**
  String auAxSayTellFailure(String where);

  /// No description provided for @auAxSayWith.
  ///
  /// In en, this message translates to:
  /// **'with «{words}»'**
  String auAxSayWith(String words);

  /// No description provided for @auAxSayWithout.
  ///
  /// In en, this message translates to:
  /// **'never with «{words}»'**
  String auAxSayWithout(String words);

  /// No description provided for @auAxSayWordsAll.
  ///
  /// In en, this message translates to:
  /// **'with all of «{words}»'**
  String auAxSayWordsAll(String words);

  /// No description provided for @auAxSayWordsAny.
  ///
  /// In en, this message translates to:
  /// **'with one of «{words}»'**
  String auAxSayWordsAny(String words);

  /// No description provided for @auAxSenders.
  ///
  /// In en, this message translates to:
  /// **'Senders'**
  String get auAxSenders;

  /// No description provided for @auAxSendersPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'bank, anna@example.com, +39 333'**
  String get auAxSendersPlaceholder;

  /// No description provided for @auAxServerSays.
  ///
  /// In en, this message translates to:
  /// **'Not right yet:'**
  String get auAxServerSays;

  /// No description provided for @auAxSession.
  ///
  /// In en, this message translates to:
  /// **'Each time'**
  String get auAxSession;

  /// No description provided for @auAxSessionContinue.
  ///
  /// In en, this message translates to:
  /// **'The same one, remembering'**
  String get auAxSessionContinue;

  /// No description provided for @auAxSessionNew.
  ///
  /// In en, this message translates to:
  /// **'A new conversation'**
  String get auAxSessionNew;

  /// No description provided for @auAxStart_after.
  ///
  /// In en, this message translates to:
  /// **'After another automation'**
  String get auAxStart_after;

  /// No description provided for @auAxStart_files.
  ///
  /// In en, this message translates to:
  /// **'Files that change'**
  String get auAxStart_files;

  /// No description provided for @auAxStart_message.
  ///
  /// In en, this message translates to:
  /// **'A message in a chat'**
  String get auAxStart_message;

  /// No description provided for @auAxStart_startup.
  ///
  /// In en, this message translates to:
  /// **'When Rasgeth starts'**
  String get auAxStart_startup;

  /// No description provided for @auAxStart_task.
  ///
  /// In en, this message translates to:
  /// **'When a task ends'**
  String get auAxStart_task;

  /// No description provided for @auAxStart_time.
  ///
  /// In en, this message translates to:
  /// **'At set times'**
  String get auAxStart_time;

  /// No description provided for @auAxStartupHelp.
  ///
  /// In en, this message translates to:
  /// **'It starts every time Rasgeth is switched on.'**
  String get auAxStartupHelp;

  /// No description provided for @auAxTask_abandoned.
  ///
  /// In en, this message translates to:
  /// **'Given up'**
  String get auAxTask_abandoned;

  /// No description provided for @auAxTask_not_testable.
  ///
  /// In en, this message translates to:
  /// **'Done, not testable'**
  String get auAxTask_not_testable;

  /// No description provided for @auAxTask_verified.
  ///
  /// In en, this message translates to:
  /// **'Done and checked'**
  String get auAxTask_verified;

  /// No description provided for @auAxTell.
  ///
  /// In en, this message translates to:
  /// **'Where it tells you'**
  String get auAxTell;

  /// No description provided for @auAxTellAllHelp.
  ///
  /// In en, this message translates to:
  /// **'None chosen: on every chat you linked.'**
  String get auAxTellAllHelp;

  /// No description provided for @auAxTellAlways.
  ///
  /// In en, this message translates to:
  /// **'Every time'**
  String get auAxTellAlways;

  /// No description provided for @auAxTellEmailFrom.
  ///
  /// In en, this message translates to:
  /// **'Sent from'**
  String get auAxTellEmailFrom;

  /// No description provided for @auAxTellEmailTo.
  ///
  /// In en, this message translates to:
  /// **'Email to'**
  String get auAxTellEmailTo;

  /// No description provided for @auAxTellEmailToHelp.
  ///
  /// In en, this message translates to:
  /// **'Empty: to the mailbox itself.'**
  String get auAxTellEmailToHelp;

  /// No description provided for @auAxTellFailure.
  ///
  /// In en, this message translates to:
  /// **'Only if something goes wrong'**
  String get auAxTellFailure;

  /// No description provided for @auAxTellHelp.
  ///
  /// In en, this message translates to:
  /// **'When it is done, where the answer goes.'**
  String get auAxTellHelp;

  /// No description provided for @auAxTellNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get auAxTellNever;

  /// No description provided for @auAxTellReplyHelp.
  ///
  /// In en, this message translates to:
  /// **'A run started by a chat message answers in that chat too.'**
  String get auAxTellReplyHelp;

  /// No description provided for @auAxTellSomeHelp.
  ///
  /// In en, this message translates to:
  /// **'Only where you chose.'**
  String get auAxTellSomeHelp;

  /// No description provided for @auAxTellWhere.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get auAxTellWhere;

  /// No description provided for @auAxTimeout.
  ///
  /// In en, this message translates to:
  /// **'Longest time, in minutes'**
  String get auAxTimeout;

  /// No description provided for @auAxTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get auAxTo;

  /// No description provided for @auAxToAllChats.
  ///
  /// In en, this message translates to:
  /// **'all your chats'**
  String get auAxToAllChats;

  /// No description provided for @auAxToDay.
  ///
  /// In en, this message translates to:
  /// **'To the day'**
  String get auAxToDay;

  /// No description provided for @auAxToEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auAxToEmail;

  /// No description provided for @auAxToWeb.
  ///
  /// In en, this message translates to:
  /// **'A notice here'**
  String get auAxToWeb;

  /// No description provided for @auAxWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get auAxWhen;

  /// No description provided for @auAxWhenHelp.
  ///
  /// In en, this message translates to:
  /// **'What starts it. You can pick more than one: it starts on each of them.'**
  String get auAxWhenHelp;

  /// No description provided for @auAxWhenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every {n} minutes'**
  String auAxWhenMinutes(String n);

  /// No description provided for @auAxWithout.
  ///
  /// In en, this message translates to:
  /// **'Words that stop it'**
  String get auAxWithout;

  /// No description provided for @auAxWithoutPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'newsletter, advertising'**
  String get auAxWithoutPlaceholder;

  /// No description provided for @auAxWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get auAxWords;

  /// No description provided for @auAxWordsHelp.
  ///
  /// In en, this message translates to:
  /// **'Separated by commas.'**
  String get auAxWordsHelp;

  /// No description provided for @auAxWordsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'urgent, invoice'**
  String get auAxWordsPlaceholder;

  /// No description provided for @auAxWorkHours.
  ///
  /// In en, this message translates to:
  /// **'Office hours'**
  String get auAxWorkHours;

  /// No description provided for @auAxYamlBack.
  ///
  /// In en, this message translates to:
  /// **'Go back to the choices above'**
  String get auAxYamlBack;

  /// No description provided for @auCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get auCancel;

  /// No description provided for @auCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get auCreate;

  /// No description provided for @auDay_0.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get auDay_0;

  /// No description provided for @auDay_1.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get auDay_1;

  /// No description provided for @auDay_2.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get auDay_2;

  /// No description provided for @auDay_3.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get auDay_3;

  /// No description provided for @auDay_4.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get auDay_4;

  /// No description provided for @auDay_5.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get auDay_5;

  /// No description provided for @auDay_6.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get auDay_6;

  /// No description provided for @auDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get auDelete;

  /// No description provided for @auDeleteAutomationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this automation and its history?'**
  String get auDeleteAutomationConfirm;

  /// No description provided for @auDeliveryDelivered.
  ///
  /// In en, this message translates to:
  /// **'delivered'**
  String get auDeliveryDelivered;

  /// No description provided for @auDeliveryDeliveredTo.
  ///
  /// In en, this message translates to:
  /// **'delivered: {to}'**
  String auDeliveryDeliveredTo(String to);

  /// No description provided for @auDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'not delivered: {reason}'**
  String auDeliveryFailed(String reason);

  /// No description provided for @auDeliveryNoChat.
  ///
  /// In en, this message translates to:
  /// **'not delivered: no chat linked'**
  String get auDeliveryNoChat;

  /// No description provided for @auDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get auDisabled;

  /// No description provided for @auDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get auDismiss;

  /// No description provided for @auEmailAny.
  ///
  /// In en, this message translates to:
  /// **'any'**
  String get auEmailAny;

  /// No description provided for @auEmailFrom.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get auEmailFrom;

  /// No description provided for @auEmailFromPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'From (part of the address, optional)'**
  String get auEmailFromPlaceholder;

  /// No description provided for @auEmailNeedFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect the mailbox first: until then this automation never starts.'**
  String get auEmailNeedFirst;

  /// No description provided for @auEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject contains'**
  String get auEmailSubject;

  /// No description provided for @auEmailSubjectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The subject contains (optional)'**
  String get auEmailSubjectPlaceholder;

  /// No description provided for @auEmailWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching {user} on {host}.'**
  String auEmailWatching(String user, String host);

  /// No description provided for @auEnabled.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get auEnabled;

  /// No description provided for @auNewAutomation.
  ///
  /// In en, this message translates to:
  /// **'New automation'**
  String get auNewAutomation;

  /// No description provided for @auNewReminder.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get auNewReminder;

  /// No description provided for @auNewSecret.
  ///
  /// In en, this message translates to:
  /// **'New secret'**
  String get auNewSecret;

  /// No description provided for @auNextRun.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get auNextRun;

  /// No description provided for @auNoAutomations.
  ///
  /// In en, this message translates to:
  /// **'No automations yet. Write a recipe: when it runs, which agent works, what it is asked.'**
  String get auNoAutomations;

  /// No description provided for @auNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs yet.'**
  String get auNoRuns;

  /// No description provided for @auOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get auOpen;

  /// No description provided for @auOpenSession.
  ///
  /// In en, this message translates to:
  /// **'Open the session'**
  String get auOpenSession;

  /// No description provided for @auProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get auProjects;

  /// No description provided for @auRecipeBroken.
  ///
  /// In en, this message translates to:
  /// **'The recipe no longer reads: open it to fix it'**
  String get auRecipeBroken;

  /// No description provided for @auReminderDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get auReminderDay;

  /// No description provided for @auReminderPurpose.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth sends you this text on Telegram at the time you choose, once. No agent, no cost.'**
  String get auReminderPurpose;

  /// No description provided for @auReminderSave.
  ///
  /// In en, this message translates to:
  /// **'Save the reminder'**
  String get auReminderSave;

  /// No description provided for @auReminderWhat.
  ///
  /// In en, this message translates to:
  /// **'What to remind you of'**
  String get auReminderWhat;

  /// No description provided for @auRepoEvent_issue_comment.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get auRepoEvent_issue_comment;

  /// No description provided for @auRepoEvent_issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get auRepoEvent_issues;

  /// No description provided for @auRepoEvent_pull_request.
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get auRepoEvent_pull_request;

  /// No description provided for @auRepoEvent_push.
  ///
  /// In en, this message translates to:
  /// **'New commits'**
  String get auRepoEvent_push;

  /// No description provided for @auRepoEvent_release.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get auRepoEvent_release;

  /// No description provided for @auRunNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get auRunNow;

  /// No description provided for @auRunStatus.
  ///
  /// In en, this message translates to:
  /// **'running,done,failed,timeout,skipped'**
  String get auRunStatus;

  /// No description provided for @auRunTriggers.
  ///
  /// In en, this message translates to:
  /// **'schedule,webhook,by hand,missed run'**
  String get auRunTriggers;

  /// No description provided for @auRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get auRuns;

  /// No description provided for @auSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get auSave;

  /// No description provided for @auSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get auSettings;

  /// No description provided for @auTplDesc_blank.
  ///
  /// In en, this message translates to:
  /// **'You choose when, who and what.'**
  String get auTplDesc_blank;

  /// No description provided for @auTplDesc_morning.
  ///
  /// In en, this message translates to:
  /// **'Every working day at 8: what happened on every project.'**
  String get auTplDesc_morning;

  /// No description provided for @auTplDesc_spending.
  ///
  /// In en, this message translates to:
  /// **'On the 1st of the month: what was spent and where.'**
  String get auTplDesc_spending;

  /// No description provided for @auTplDesc_weekly.
  ///
  /// In en, this message translates to:
  /// **'Fridays at 17: the week in one message.'**
  String get auTplDesc_weekly;

  /// No description provided for @auTplText_morning.
  ///
  /// In en, this message translates to:
  /// **'Tell me in a few lines what happened yesterday on every project: work finished, problems still open, decisions to take.'**
  String get auTplText_morning;

  /// No description provided for @auTplText_spending.
  ///
  /// In en, this message translates to:
  /// **'Tell me how much was spent last month, per project and per agent, and whether anything looks out of the ordinary.'**
  String get auTplText_spending;

  /// No description provided for @auTplText_weekly.
  ///
  /// In en, this message translates to:
  /// **'Summarise this week on every project: what was finished, what is late, what is planned for next week.'**
  String get auTplText_weekly;

  /// No description provided for @auTplTitle_blank.
  ///
  /// In en, this message translates to:
  /// **'From scratch'**
  String get auTplTitle_blank;

  /// No description provided for @auTplTitle_morning.
  ///
  /// In en, this message translates to:
  /// **'Morning briefing'**
  String get auTplTitle_morning;

  /// No description provided for @auTplTitle_spending.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending'**
  String get auTplTitle_spending;

  /// No description provided for @auTplTitle_weekly.
  ///
  /// In en, this message translates to:
  /// **'The week\'s news'**
  String get auTplTitle_weekly;

  /// No description provided for @auWebhookSecretOnce.
  ///
  /// In en, this message translates to:
  /// **'Secret (shown only now; send it in the x-redgiant-secret header):'**
  String get auWebhookSecretOnce;

  /// No description provided for @auWebhookUrl.
  ///
  /// In en, this message translates to:
  /// **'Webhook'**
  String get auWebhookUrl;

  /// No description provided for @auWhenAt.
  ///
  /// In en, this message translates to:
  /// **'Once, on {at}'**
  String auWhenAt(String at);

  /// No description provided for @auWhenAtTime.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get auWhenAtTime;

  /// No description provided for @auWhenCustom.
  ///
  /// In en, this message translates to:
  /// **'On a schedule of its own ({cron})'**
  String auWhenCustom(String cron);

  /// No description provided for @auWhenDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String auWhenDaily(String time);

  /// No description provided for @auWhenDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'on day'**
  String get auWhenDayOfMonth;

  /// No description provided for @auWhenEmail.
  ///
  /// In en, this message translates to:
  /// **'When an email arrives ({filter})'**
  String auWhenEmail(String filter);

  /// No description provided for @auWhenEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'The mailbox is set once, here or in Settings › Automations › Mailbox. The email reaches the agent as information, never as instructions.'**
  String get auWhenEmailHelp;

  /// No description provided for @auWhenEveryHours.
  ///
  /// In en, this message translates to:
  /// **'every (hours)'**
  String get auWhenEveryHours;

  /// No description provided for @auWhenHours.
  ///
  /// In en, this message translates to:
  /// **'Every {n} hours'**
  String auWhenHours(String n);

  /// No description provided for @auWhenKind_daily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get auWhenKind_daily;

  /// No description provided for @auWhenKind_email.
  ///
  /// In en, this message translates to:
  /// **'On an email'**
  String get auWhenKind_email;

  /// No description provided for @auWhenKind_hours.
  ///
  /// In en, this message translates to:
  /// **'Every few hours'**
  String get auWhenKind_hours;

  /// No description provided for @auWhenKind_monthly.
  ///
  /// In en, this message translates to:
  /// **'Once a month'**
  String get auWhenKind_monthly;

  /// No description provided for @auWhenKind_repo.
  ///
  /// In en, this message translates to:
  /// **'On the repository'**
  String get auWhenKind_repo;

  /// No description provided for @auWhenKind_webhook.
  ///
  /// In en, this message translates to:
  /// **'On a web call'**
  String get auWhenKind_webhook;

  /// No description provided for @auWhenKind_weekdays.
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get auWhenKind_weekdays;

  /// No description provided for @auWhenKind_weekly.
  ///
  /// In en, this message translates to:
  /// **'Some days of the week'**
  String get auWhenKind_weekly;

  /// No description provided for @auWhenMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month on day {day} at {time}'**
  String auWhenMonthly(String day, String time);

  /// No description provided for @auWhenRepo.
  ///
  /// In en, this message translates to:
  /// **'When something happens in the repository ({events})'**
  String auWhenRepo(String events);

  /// No description provided for @auWhenRepoHelp.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth adds the webhook to the project\'s repository by itself: on Gitea at once, on GitHub once access from outside home is on.'**
  String get auWhenRepoHelp;

  /// No description provided for @auWhenWebhook.
  ///
  /// In en, this message translates to:
  /// **'When a web call arrives (webhook)'**
  String get auWhenWebhook;

  /// No description provided for @auWhenWebhookHelp.
  ///
  /// In en, this message translates to:
  /// **'Another program (a site, a form, GitHub…) calls Rasgeth\'s address; the address and its secret appear after saving.'**
  String get auWhenWebhookHelp;

  /// No description provided for @auWhenWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Monday to Friday at {time}'**
  String auWhenWeekdays(String time);

  /// No description provided for @auWhenWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week on {days} at {time}'**
  String auWhenWeekly(String days, String time);

  /// No description provided for @auWhoLead.
  ///
  /// In en, this message translates to:
  /// **'Lead of {project}'**
  String auWhoLead(String project);

  /// No description provided for @auOwnHubHint.
  ///
  /// In en, this message translates to:
  /// **'When things happen by themselves: schedules, emails, chats, files, reminders'**
  String get auOwnHubHint;

  /// No description provided for @auOwnOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open the conversation'**
  String get auOwnOpenChat;

  /// No description provided for @auOwnTalkGod.
  ///
  /// In en, this message translates to:
  /// **'Talk with God'**
  String get auOwnTalkGod;

  /// No description provided for @auOwnMailboxesElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Mailboxes are added and changed in Settings › Channels and mailboxes.'**
  String get auOwnMailboxesElsewhere;

  /// No description provided for @auOwnNoMailboxes.
  ///
  /// In en, this message translates to:
  /// **'No mailbox connected yet.'**
  String get auOwnNoMailboxes;

  /// No description provided for @auOwnCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get auOwnCopied;

  /// No description provided for @auOwnCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get auOwnCopy;

  /// No description provided for @auOwnYamlLabel.
  ///
  /// In en, this message translates to:
  /// **'The recipe in YAML'**
  String get auOwnYamlLabel;

  /// No description provided for @auOwnRoutineOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the routine'**
  String get auOwnRoutineOpen;

  /// No description provided for @auOwnNoticeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get auOwnNoticeOpen;

  /// No description provided for @auOwnNoticeFailed.
  ///
  /// In en, this message translates to:
  /// **'{name}: not done'**
  String auOwnNoticeFailed(String name);

  /// No description provided for @auOwnPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get auOwnPickTitle;

  /// No description provided for @auOwnNeedOpenWhere.
  ///
  /// In en, this message translates to:
  /// **'Open it in Settings › {where}'**
  String auOwnNeedOpenWhere(String where);

  /// No description provided for @auOwnWhereChats.
  ///
  /// In en, this message translates to:
  /// **'Channels and mailboxes'**
  String get auOwnWhereChats;

  /// No description provided for @auOwnWhereExtensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get auOwnWhereExtensions;

  /// No description provided for @auOwnWhereKeychain.
  ///
  /// In en, this message translates to:
  /// **'Keychain'**
  String get auOwnWhereKeychain;

  /// No description provided for @auOwnLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read: {why}'**
  String auOwnLoadFailed(String why);

  /// No description provided for @auOwnReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Automations can be changed only by the person (not from a project\'s device).'**
  String get auOwnReadOnly;

  /// Secret warning: send the message as written (the person's choice, 2026-11-19).
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get cvChSecretAnyway;

  /// Secret warning: what Send anyway does.
  ///
  /// In en, this message translates to:
  /// **'Not a secret (a link, an order code)? «Send anyway» sends it as you wrote it.'**
  String get cvChSecretAnywayNote;

  /// Echo (3.9.6): the search over past conversations; the page's echoSearch.
  ///
  /// In en, this message translates to:
  /// **'Search past conversations'**
  String get echoSearch;

  /// No description provided for @echoClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the search'**
  String get echoClear;

  /// No description provided for @echoNone.
  ///
  /// In en, this message translates to:
  /// **'No past conversation has these words.'**
  String get echoNone;

  /// No description provided for @echoArchived.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get echoArchived;

  /// No description provided for @echoMatches.
  ///
  /// In en, this message translates to:
  /// **'{n} messages'**
  String echoMatches(String n);

  /// No description provided for @echoMatch.
  ///
  /// In en, this message translates to:
  /// **'1 message'**
  String get echoMatch;

  /// No description provided for @echoYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get echoYou;

  /// No description provided for @echoHint.
  ///
  /// In en, this message translates to:
  /// **'Type at least two letters: every word is looked for in what you and the agents wrote.'**
  String get echoHint;

  /// No description provided for @skSection.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skSection;

  /// No description provided for @skHub.
  ///
  /// In en, this message translates to:
  /// **'The agents\' skills, their versions and the way back'**
  String get skHub;

  /// No description provided for @skQuestion.
  ///
  /// In en, this message translates to:
  /// **'What the agents learned'**
  String get skQuestion;

  /// No description provided for @skLead.
  ///
  /// In en, this message translates to:
  /// **'Skills are instructions the agents write after a job that went well, or that you give them. Each one keeps its versions: who wrote it, why and when, and you can go back to any of them.'**
  String get skLead;

  /// No description provided for @skWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get skWaitingTitle;

  /// No description provided for @skWaitingLead.
  ///
  /// In en, this message translates to:
  /// **'New skills and new versions of installed ones, tested apart. Nothing changes until you say yes.'**
  String get skWaitingLead;

  /// No description provided for @skNoneWaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing waits for you.'**
  String get skNoneWaiting;

  /// No description provided for @skNew.
  ///
  /// In en, this message translates to:
  /// **'New skill'**
  String get skNew;

  /// No description provided for @skUpdate.
  ///
  /// In en, this message translates to:
  /// **'New version of an installed skill'**
  String get skUpdate;

  /// No description provided for @skBy.
  ///
  /// In en, this message translates to:
  /// **'by {who}'**
  String skBy(String who);

  /// No description provided for @skWhy.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get skWhy;

  /// No description provided for @skTestsOk.
  ///
  /// In en, this message translates to:
  /// **'Its tests passed.'**
  String get skTestsOk;

  /// No description provided for @skScripts.
  ///
  /// In en, this message translates to:
  /// **'It has scripts ({files}): code never installs by itself.'**
  String skScripts(String files);

  /// No description provided for @skApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get skApprove;

  /// No description provided for @skReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get skReject;

  /// No description provided for @skNextSession.
  ///
  /// In en, this message translates to:
  /// **'Once installed, agents use it from their next conversation; the ones already talking keep the version they started with.'**
  String get skNextSession;

  /// No description provided for @skInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get skInstalledTitle;

  /// No description provided for @skInstalledLead.
  ///
  /// In en, this message translates to:
  /// **'Open one to see its versions.'**
  String get skInstalledLead;

  /// No description provided for @skNoneInstalled.
  ///
  /// In en, this message translates to:
  /// **'No skills yet.'**
  String get skNoneInstalled;

  /// No description provided for @skEverywhere.
  ///
  /// In en, this message translates to:
  /// **'for every project'**
  String get skEverywhere;

  /// No description provided for @skProject.
  ///
  /// In en, this message translates to:
  /// **'project {name}'**
  String skProject(String name);

  /// No description provided for @skVersionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get skVersionsTitle;

  /// No description provided for @skVersionsLead.
  ///
  /// In en, this message translates to:
  /// **'Agents use the newest from their next conversation.'**
  String get skVersionsLead;

  /// No description provided for @skVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {n}'**
  String skVersion(String n);

  /// No description provided for @skCurrent.
  ///
  /// In en, this message translates to:
  /// **'in use'**
  String get skCurrent;

  /// No description provided for @skHow_baseline.
  ///
  /// In en, this message translates to:
  /// **'As it was before the history began'**
  String get skHow_baseline;

  /// No description provided for @skHow_edited.
  ///
  /// In en, this message translates to:
  /// **'Changed by hand'**
  String get skHow_edited;

  /// No description provided for @skHow_install.
  ///
  /// In en, this message translates to:
  /// **'First version'**
  String get skHow_install;

  /// No description provided for @skHow_update.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get skHow_update;

  /// No description provided for @skHow_import.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get skHow_import;

  /// No description provided for @skHow_rollback.
  ///
  /// In en, this message translates to:
  /// **'Back to version {n}'**
  String skHow_rollback(String n);

  /// No description provided for @skUnknown.
  ///
  /// In en, this message translates to:
  /// **'author unknown'**
  String get skUnknown;

  /// No description provided for @skYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get skYou;

  /// No description provided for @skApprovedYou.
  ///
  /// In en, this message translates to:
  /// **'approved by you'**
  String get skApprovedYou;

  /// No description provided for @skApprovedAuto.
  ///
  /// In en, this message translates to:
  /// **'installed by itself (your choice in Safety)'**
  String get skApprovedAuto;

  /// No description provided for @skCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare with the one in use'**
  String get skCompare;

  /// No description provided for @skHideCompare.
  ///
  /// In en, this message translates to:
  /// **'Hide the comparison'**
  String get skHideCompare;

  /// No description provided for @skRollback.
  ///
  /// In en, this message translates to:
  /// **'Go back to version {n}'**
  String skRollback(String n);

  /// No description provided for @skRollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Go back to version {n}?'**
  String skRollbackTitle(String n);

  /// No description provided for @skRollbackText.
  ///
  /// In en, this message translates to:
  /// **'Its files replace those of «{name}» in use, as a new version: nothing is lost and you can come back here. Agents get it from their next conversation.'**
  String skRollbackText(String name);

  /// No description provided for @skRolledBack.
  ///
  /// In en, this message translates to:
  /// **'Back to version {n}: it is version {v} now.'**
  String skRolledBack(String n, String v);

  /// No description provided for @skNotRestorable.
  ///
  /// In en, this message translates to:
  /// **'Too large to keep: it cannot come back.'**
  String get skNotRestorable;

  /// No description provided for @skNoVersions.
  ///
  /// In en, this message translates to:
  /// **'No versions yet.'**
  String get skNoVersions;

  /// No description provided for @skLineTitle.
  ///
  /// In en, this message translates to:
  /// **'What changed and why'**
  String get skLineTitle;

  /// No description provided for @skCompareFull.
  ///
  /// In en, this message translates to:
  /// **'Compare: every difference'**
  String get skCompareFull;

  /// The page's `vwKind_timeline` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Video timeline'**
  String get cvVwKindTimeline;

  /// A job followed in the notifications (a video's render, G42.18) before the server counts it.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get jobNoticeStarting;

  /// How far a followed job is (G42.18).
  ///
  /// In en, this message translates to:
  /// **'{percent}% done'**
  String jobNoticePercent(int percent);

  /// How far a followed job is and the minutes left (G42.18).
  ///
  /// In en, this message translates to:
  /// **'{percent}% done, about {min} min left'**
  String jobNoticePercentLeft(int percent, int min);

  /// A followed job finished (G42.18).
  ///
  /// In en, this message translates to:
  /// **'Done: open it in the Canvas.'**
  String get jobNoticeDone;

  /// A followed job failed without a reason (G42.18).
  ///
  /// In en, this message translates to:
  /// **'It did not work.'**
  String get jobNoticeFailed;

  /// A followed job failed, with the server's reason (G42.18).
  ///
  /// In en, this message translates to:
  /// **'It did not work: {why}'**
  String jobNoticeFailedWhy(String why);

  /// A followed job was cancelled (G42.18).
  ///
  /// In en, this message translates to:
  /// **'Stopped.'**
  String get jobNoticeCancelled;

  /// A «Save as…» stopped with «Annulla» under its bar (3.10).
  ///
  /// In en, this message translates to:
  /// **'Saving {name} stopped'**
  String saveCancelled(String name);

  /// A file over 512 MB that a phone cannot hand to the system's save (3.10).
  ///
  /// In en, this message translates to:
  /// **'{name} is too big to save from the phone ({size}): save it from a computer'**
  String saveTooBigPhone(String name, String size);

  /// The page's `allowWork` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Always allow for this job'**
  String get cvAllowWork;

  /// The page's `allowWorkHint` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Allow the same kind of command on the same machine without asking again, for the rest of this conversation\'s work'**
  String get cvAllowWorkHint;

  /// The page's `chSecretKind_export` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'a password export'**
  String get cvChSecretKindExport;

  /// The page's `pwOne` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'1 password'**
  String get cvPwOne;

  /// The page's `pwMany` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{n} passwords'**
  String cvPwMany(String n);

  /// The page's `pwExportTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'This is a password export'**
  String get cvPwExportTitle;

  /// The page's `pwExportText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The message holds {what} exported from a password manager. They do not belong in a conversation: the model, the log, the search and the engine\'s transcript would keep them.'**
  String cvPwExportText(String what);

  /// The page's `pwExportVault` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Put them in the keychain'**
  String get cvPwExportVault;

  /// The page's `pwExportWithout` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send without'**
  String get cvPwExportWithout;

  /// The page's `pwExportWithoutNote` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'«Send without» sends your words with the export taken out.'**
  String get cvPwExportWithoutNote;

  /// The page's `pwExportAnyway` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get cvPwExportAnyway;

  /// The page's `pwExportAnywayTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send {what} to the agent?'**
  String cvPwExportAnywayTitle(String what);

  /// The page's `pwExportAnywayText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{what} will reach the model and stay in the conversation\'s log, in the search and in the engine\'s transcript. Only do it if you are sure.'**
  String cvPwExportAnywayText(String what);

  /// The page's `pwExportAnywayYes` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Send {what}'**
  String cvPwExportAnywayYes(String what);

  /// The page's `pwImported` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'In the keychain: {added} new, {skipped} already there.'**
  String cvPwImported(String added, String skipped);

  /// The page's `pwImportClosed` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The keychain is closed: nothing was imported. Open it in Settings › Keychain and try again.'**
  String get cvPwImportClosed;

  /// The page's `pwImportFailed` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Nothing was imported: {error}'**
  String cvPwImportFailed(String error);

  /// The page's `pwProposal` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Proposes to put the passwords of {file} in your keychain.'**
  String cvPwProposal(String file);

  /// The page's `pwProposalButton` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Put them in the keychain'**
  String get cvPwProposalButton;

  /// The page's `pwProposalAsk` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Put the passwords of {file} in the keychain?'**
  String cvPwProposalAsk(String file);

  /// The page's `pwProposalText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'They go into your keychain without the agent seeing them; then the file is destroyed.'**
  String get cvPwProposalText;

  /// The page's `pwProposalYes` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Import and destroy the file'**
  String get cvPwProposalYes;

  /// The page's `pwProposalDone` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'{added} passwords of {file} are in the keychain; the file is destroyed.'**
  String cvPwProposalDone(String added, String file);

  /// The page's `eraseForever` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Erase for good'**
  String get cvEraseForever;

  /// The page's `eraseTitle` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Erase this message for good?'**
  String get cvEraseTitle;

  /// The page's `eraseText` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It goes from the conversation\'s log, the search, the portrait and what the agent remembers of it. It cannot be undone.'**
  String get cvEraseText;

  /// The page's `eraseTextEngine` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'It goes from the conversation\'s log, the search, the portrait, what the agent remembers of it and the engine\'s own transcript. It cannot be undone.'**
  String get cvEraseTextEngine;

  /// The page's `eraseQuotes` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Also erase {n} of the agent\'s replies and results that quote it'**
  String cvEraseQuotes(String n);

  /// The page's `eraseYes` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Erase for good'**
  String get cvEraseYes;

  /// The page's `eraseDone` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'Erased for good ({n}).'**
  String cvEraseDone(String n);

  /// The page's `eraseBusy` (packages/web/src/i18n.ts, tool/chat_words.mjs).
  ///
  /// In en, this message translates to:
  /// **'The agent is working: stop it or wait for it to finish, then try again.'**
  String get cvEraseBusy;

  /// No description provided for @pairAgain.
  ///
  /// In en, this message translates to:
  /// **'Pair again'**
  String get pairAgain;

  /// No description provided for @statusPairAgain.
  ///
  /// In en, this message translates to:
  /// **'needs pairing again'**
  String get statusPairAgain;

  /// No description provided for @pairAgainTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair {name} again'**
  String pairAgainTitle(String name);

  /// No description provided for @pairAgainBody.
  ///
  /// In en, this message translates to:
  /// **'This device no longer has its key for {name}. Type the password: the server stays in the list with its settings and works again.'**
  String pairAgainBody(String name);

  /// No description provided for @pairAgainNote.
  ///
  /// In en, this message translates to:
  /// **'This device no longer has its key for this server: pair it again with the password, without removing it.'**
  String get pairAgainNote;

  /// No description provided for @errKeystore.
  ///
  /// In en, this message translates to:
  /// **'This computer could not save the access key in its keystore, so the pairing was undone and no extra device is left on the server. Try again. If it happens again, restart the computer and sign in with your password, not the PIN.'**
  String get errKeystore;

  /// No description provided for @errKeystoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get errKeystoreDetails;

  /// No description provided for @devForgetUnused.
  ///
  /// In en, this message translates to:
  /// **'Remove the ones never used'**
  String get devForgetUnused;

  /// No description provided for @devForgetUnusedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the devices never used?'**
  String get devForgetUnusedTitle;

  /// No description provided for @devForgetUnusedBody.
  ///
  /// In en, this message translates to:
  /// **'Every device that never signed in once goes (an app that could not keep its key, for example). The ones paired in the last ten minutes stay: they may be connecting right now.'**
  String get devForgetUnusedBody;

  /// No description provided for @devForgetUnusedDone.
  ///
  /// In en, this message translates to:
  /// **'Devices removed: {count}.'**
  String devForgetUnusedDone(int count);

  /// No description provided for @chAxCat_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chAxCat_other;

  /// No description provided for @chAxCat_personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get chAxCat_personal;

  /// No description provided for @chAxCat_social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get chAxCat_social;

  /// No description provided for @chAxCat_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get chAxCat_work;

  /// No description provided for @chAxMailboxAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a mailbox'**
  String get chAxMailboxAdd;

  /// No description provided for @chAxMailboxAddText.
  ///
  /// In en, this message translates to:
  /// **'As many as you like, each in its category.'**
  String get chAxMailboxAddText;

  /// No description provided for @chAxMailboxAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents may use it'**
  String get chAxMailboxAgents;

  /// No description provided for @chAxMailboxAgentsHelp.
  ///
  /// In en, this message translates to:
  /// **'They search, read and write drafts here; every email they send asks you first and shows it whole.'**
  String get chAxMailboxAgentsHelp;

  /// No description provided for @chAxMailboxCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get chAxMailboxCategory;

  /// No description provided for @chAxMailboxName.
  ///
  /// In en, this message translates to:
  /// **'Its name'**
  String get chAxMailboxName;

  /// No description provided for @chAxMailboxNameHelp.
  ///
  /// In en, this message translates to:
  /// **'For example Work or Gmail; empty: the address.'**
  String get chAxMailboxNameHelp;

  /// No description provided for @chAxMailboxNew.
  ///
  /// In en, this message translates to:
  /// **'New mailbox'**
  String get chAxMailboxNew;

  /// No description provided for @chAxMailboxNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Or a new category'**
  String get chAxMailboxNewCategory;

  /// No description provided for @chAxMailboxNewCategoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Family, Club, Shop…'**
  String get chAxMailboxNewCategoryPlaceholder;

  /// No description provided for @chAxMailboxPasswordKept.
  ///
  /// In en, this message translates to:
  /// **'Leave it empty to keep the one you gave.'**
  String get chAxMailboxPasswordKept;

  /// No description provided for @chAxMailboxPurpose.
  ///
  /// In en, this message translates to:
  /// **'A mailbox for the automations: only new mail is read, nothing is marked or moved.'**
  String get chAxMailboxPurpose;

  /// No description provided for @chAxMailboxesWatching.
  ///
  /// In en, this message translates to:
  /// **'{n} mailboxes connected: {names}.'**
  String chAxMailboxesWatching(String n, String names);

  /// No description provided for @chAxSmtpHost.
  ///
  /// In en, this message translates to:
  /// **'Sending server (SMTP)'**
  String get chAxSmtpHost;

  /// No description provided for @chAxSmtpHostHelp.
  ///
  /// In en, this message translates to:
  /// **'Only to get messages by email; empty: the usual one.'**
  String get chAxSmtpHostHelp;

  /// No description provided for @chAxSmtpPort.
  ///
  /// In en, this message translates to:
  /// **'Sending port'**
  String get chAxSmtpPort;

  /// No description provided for @chChatChange.
  ///
  /// In en, this message translates to:
  /// **'Change the settings'**
  String get chChatChange;

  /// No description provided for @chChatDiscordHow.
  ///
  /// In en, this message translates to:
  /// **'In the Discord Developer Portal create an application, add a bot, turn on Message Content Intent, copy its token, and invite the bot to a server of yours (or write to it directly).'**
  String get chChatDiscordHow;

  /// No description provided for @chChatDiscordToken.
  ///
  /// In en, this message translates to:
  /// **'Bot token'**
  String get chChatDiscordToken;

  /// No description provided for @chChatImHow.
  ///
  /// In en, this message translates to:
  /// **'Apple has no iMessage service for programs: it takes a Mac that stays on, signed in to Messages, with the free BlueBubbles server. The Mac answers with its Apple ID: use one made for Rasgeth, not your own.'**
  String get chChatImHow;

  /// No description provided for @chChatImLimits.
  ///
  /// In en, this message translates to:
  /// **'Without the Private API answers cannot be edited and nobody shows as typing; approvals and questions are answered with numbers. While the Mac sleeps or is off, messages wait and arrive when it wakes.'**
  String get chChatImLimits;

  /// No description provided for @chChatImPassword.
  ///
  /// In en, this message translates to:
  /// **'BlueBubbles server password'**
  String get chChatImPassword;

  /// No description provided for @chChatImPrivate.
  ///
  /// In en, this message translates to:
  /// **'BlueBubbles\' Private API is set up (edits and “typing...”)'**
  String get chChatImPrivate;

  /// No description provided for @chChatImStep1.
  ///
  /// In en, this message translates to:
  /// **'On the Mac make (or use) an Apple ID just for Rasgeth and sign in with it in Messages.'**
  String get chChatImStep1;

  /// No description provided for @chChatImStep2.
  ///
  /// In en, this message translates to:
  /// **'Download BlueBubbles Server from bluebubbles.app, open it and choose a server password.'**
  String get chChatImStep2;

  /// No description provided for @chChatImStep3.
  ///
  /// In en, this message translates to:
  /// **'When it asks, allow Full Disk Access and Accessibility in System Settings, Privacy & Security: it needs them to read and send messages.'**
  String get chChatImStep3;

  /// No description provided for @chChatImStep4.
  ///
  /// In en, this message translates to:
  /// **'In BlueBubbles keep the Mac from sleeping and note its address: http://<the Mac\'s address>:1234 at home, or the address of its own tunnel from outside.'**
  String get chChatImStep4;

  /// No description provided for @chChatImStep5.
  ///
  /// In en, this message translates to:
  /// **'Write the address and the password here and press Connect. From your iPhone write to the Apple ID of step 1 and send the code.'**
  String get chChatImStep5;

  /// No description provided for @chChatImUrl.
  ///
  /// In en, this message translates to:
  /// **'Address of the BlueBubbles server (http://...:1234)'**
  String get chChatImUrl;

  /// No description provided for @chChatLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked: {who}'**
  String chChatLinked(String who);

  /// No description provided for @chChatMatrixE2ee.
  ///
  /// In en, this message translates to:
  /// **'Encrypted chats: direct chats in Element are encrypted and the bot cannot read them. To keep encryption, run Pantalaimon (Matrix\'s free encryption helper) next to Rasgeth and write its address instead of the server\'s.'**
  String get chChatMatrixE2ee;

  /// No description provided for @chChatMatrixHomeserver.
  ///
  /// In en, this message translates to:
  /// **'Server address (for example https://matrix.org)'**
  String get chChatMatrixHomeserver;

  /// No description provided for @chChatMatrixHow.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth needs a Matrix account of its own, not yours: it is the one you will write to.'**
  String get chChatMatrixHow;

  /// No description provided for @chChatMatrixStep1.
  ///
  /// In en, this message translates to:
  /// **'Make a new account for the bot, for example at app.element.io (or on your own server).'**
  String get chChatMatrixStep1;

  /// No description provided for @chChatMatrixStep2.
  ///
  /// In en, this message translates to:
  /// **'Signed in as the bot, open Settings, Help & About, Advanced, Access token, and copy it. Then close that tab without signing out: signing out cancels the token.'**
  String get chChatMatrixStep2;

  /// No description provided for @chChatMatrixStep3.
  ///
  /// In en, this message translates to:
  /// **'Write the server address and paste the token here, then press Connect.'**
  String get chChatMatrixStep3;

  /// No description provided for @chChatMatrixStep4.
  ///
  /// In en, this message translates to:
  /// **'From your own account make a new room without encryption (switch off “Enable end-to-end encryption”), invite the bot (it joins by itself) and send the code that appears.'**
  String get chChatMatrixStep4;

  /// No description provided for @chChatMatrixToken.
  ///
  /// In en, this message translates to:
  /// **'The bot account\'s access token'**
  String get chChatMatrixToken;

  /// No description provided for @chChatSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send this from the chat to link it:'**
  String get chChatSendCode;

  /// No description provided for @chChatSignalHow.
  ///
  /// In en, this message translates to:
  /// **'Signal needs signal-cli-rest-api running with a number of its own linked (a second SIM or a linked device); write its address and the number here.'**
  String get chChatSignalHow;

  /// No description provided for @chChatSignalNumber.
  ///
  /// In en, this message translates to:
  /// **'The bot\'s number (+39...)'**
  String get chChatSignalNumber;

  /// No description provided for @chChatSignalUrl.
  ///
  /// In en, this message translates to:
  /// **'Address of signal-cli-rest-api'**
  String get chChatSignalUrl;

  /// No description provided for @chChatSlackApp.
  ///
  /// In en, this message translates to:
  /// **'App-level token (xapp-..., connections:write)'**
  String get chChatSlackApp;

  /// No description provided for @chChatSlackBot.
  ///
  /// In en, this message translates to:
  /// **'Bot token (xoxb-...)'**
  String get chChatSlackBot;

  /// No description provided for @chChatSlackHow.
  ///
  /// In en, this message translates to:
  /// **'At api.slack.com/apps create an app, turn on Socket Mode (no public address needed), add the scopes chat:write, im:history, app_mentions:read, files:read, files:write, subscribe to message.im and app_mention, install it and copy the two tokens.'**
  String get chChatSlackHow;

  /// No description provided for @chChatSteps.
  ///
  /// In en, this message translates to:
  /// **'Step by step'**
  String get chChatSteps;

  /// No description provided for @chChatTeamsAppId.
  ///
  /// In en, this message translates to:
  /// **'Microsoft App ID'**
  String get chChatTeamsAppId;

  /// No description provided for @chChatTeamsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download the app for Teams'**
  String get chChatTeamsDownload;

  /// No description provided for @chChatTeamsEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Messaging endpoint for Azure: {url}'**
  String chChatTeamsEndpoint(String url);

  /// No description provided for @chChatTeamsFiles.
  ///
  /// In en, this message translates to:
  /// **'Files from Rasgeth arrive as a card to accept: once accepted they are saved in your OneDrive. Voice messages cannot be sent to a bot in Teams.'**
  String get chChatTeamsFiles;

  /// No description provided for @chChatTeamsHow.
  ///
  /// In en, this message translates to:
  /// **'Teams talks to bots only through Microsoft Azure. You need a Microsoft 365 work or school account that may add custom apps (the free personal Teams does not allow bots), and Rasgeth reachable from outside (Settings, Remote access).'**
  String get chChatTeamsHow;

  /// No description provided for @chChatTeamsSecret.
  ///
  /// In en, this message translates to:
  /// **'Client secret (its Value)'**
  String get chChatTeamsSecret;

  /// No description provided for @chChatTeamsStep1.
  ///
  /// In en, this message translates to:
  /// **'Open portal.azure.com (a free account is enough), choose Create a resource, search for Azure Bot and press Create.'**
  String get chChatTeamsStep1;

  /// No description provided for @chChatTeamsStep2.
  ///
  /// In en, this message translates to:
  /// **'Give it a name, choose the Free plan (F0), Type of App: Single Tenant, Creation type: Create new Microsoft App ID. Press Create, then Go to resource.'**
  String get chChatTeamsStep2;

  /// No description provided for @chChatTeamsStep3.
  ///
  /// In en, this message translates to:
  /// **'In Configuration write this Messaging endpoint and Save: {url}. Copy the Microsoft App ID and the App Tenant ID.'**
  String chChatTeamsStep3(String url);

  /// No description provided for @chChatTeamsStep4.
  ///
  /// In en, this message translates to:
  /// **'Next to Microsoft App ID press Manage Password, then New client secret, Add, and copy its Value (it is shown only once).'**
  String get chChatTeamsStep4;

  /// No description provided for @chChatTeamsStep5.
  ///
  /// In en, this message translates to:
  /// **'In Channels add Microsoft Teams, accept the terms and press Apply.'**
  String get chChatTeamsStep5;

  /// No description provided for @chChatTeamsStep6.
  ///
  /// In en, this message translates to:
  /// **'Paste the three values here and press Connect. Then download the app for Teams with the button that appears.'**
  String get chChatTeamsStep6;

  /// No description provided for @chChatTeamsTenant.
  ///
  /// In en, this message translates to:
  /// **'App Tenant ID'**
  String get chChatTeamsTenant;

  /// No description provided for @chChatTeamsUpload.
  ///
  /// In en, this message translates to:
  /// **'In Teams open Apps, Manage your apps, Upload an app, Upload a custom app, choose the file you downloaded and press Add. Then open the chat with Rasgeth and send the code.'**
  String get chChatTeamsUpload;

  /// No description provided for @chChatTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get chChatTurnOff;

  /// No description provided for @chChatWaHow.
  ///
  /// In en, this message translates to:
  /// **'In Meta for Developers create a WhatsApp app, copy the access token, the phone number ID and the app secret, and choose a verify token. WhatsApp sends messages to a public address: Rasgeth must be reachable from outside (Settings, Remote access).'**
  String get chChatWaHow;

  /// No description provided for @chChatWaPhoneId.
  ///
  /// In en, this message translates to:
  /// **'Phone number ID'**
  String get chChatWaPhoneId;

  /// No description provided for @chChatWaSecret.
  ///
  /// In en, this message translates to:
  /// **'App secret'**
  String get chChatWaSecret;

  /// No description provided for @chChatWaToken.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get chChatWaToken;

  /// No description provided for @chChatWaVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify token (choose one)'**
  String get chChatWaVerify;

  /// No description provided for @chChatWaWebhook.
  ///
  /// In en, this message translates to:
  /// **'Webhook for Meta: {url} with the verify token you chose; subscribe to messages.'**
  String chChatWaWebhook(String url);

  /// No description provided for @chChats.
  ///
  /// In en, this message translates to:
  /// **'Other chats'**
  String get chChats;

  /// No description provided for @chChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Talk to Demi-God from Discord, Slack, Signal, WhatsApp, Matrix, Teams or iMessage too. It is one conversation: begun on Telegram or here, it goes on wherever you write. Approvals and questions arrive with buttons (on Signal, Matrix and iMessage, with numbers to reply).'**
  String get chChatsHint;

  /// No description provided for @chEmailChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get chEmailChange;

  /// No description provided for @chEmailConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect the mailbox'**
  String get chEmailConnect;

  /// No description provided for @chEmailConnected.
  ///
  /// In en, this message translates to:
  /// **'Reading {user} on {host}.'**
  String chEmailConnected(String host, String user);

  /// No description provided for @chEmailHost.
  ///
  /// In en, this message translates to:
  /// **'Mail server (IMAP)'**
  String get chEmailHost;

  /// No description provided for @chEmailHostHelp.
  ///
  /// In en, this message translates to:
  /// **'For example imap.gmail.com, outlook.office365.com, imap.mail.me.com.'**
  String get chEmailHostHelp;

  /// No description provided for @chEmailNeedFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect the mailbox first: until then this automation never starts.'**
  String get chEmailNeedFirst;

  /// No description provided for @chEmailNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get chEmailNotConnected;

  /// No description provided for @chEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Password for apps'**
  String get chEmailPassword;

  /// No description provided for @chEmailPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Better an app password (Gmail, Outlook and iCloud make one in the account\'s security settings) than your own: you can revoke it at any time. It stays in a private file on your server.'**
  String get chEmailPasswordHelp;

  /// No description provided for @chEmailPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get chEmailPort;

  /// No description provided for @chEmailPurpose.
  ///
  /// In en, this message translates to:
  /// **'A routine can start when an email arrives (an invoice, an alert). Rasgeth looks only at new mail, every two minutes, and changes nothing in your mailbox; the email reaches the agent as information, never as instructions.'**
  String get chEmailPurpose;

  /// No description provided for @chEmailSave.
  ///
  /// In en, this message translates to:
  /// **'Connect the mailbox'**
  String get chEmailSave;

  /// No description provided for @chEmailSecure.
  ///
  /// In en, this message translates to:
  /// **'Encrypted from the start (port 993)'**
  String get chEmailSecure;

  /// No description provided for @chEmailTesting.
  ///
  /// In en, this message translates to:
  /// **'Trying the mailbox…'**
  String get chEmailTesting;

  /// No description provided for @chEmailTileText.
  ///
  /// In en, this message translates to:
  /// **'For the automations that start when an email arrives.'**
  String get chEmailTileText;

  /// No description provided for @chEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get chEmailTitle;

  /// No description provided for @chEmailUser.
  ///
  /// In en, this message translates to:
  /// **'Address or username'**
  String get chEmailUser;

  /// No description provided for @chEmailWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching {user} on {host}.'**
  String chEmailWatching(String host, String user);

  /// No description provided for @chInput.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get chInput;

  /// No description provided for @chRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chRemove;

  /// No description provided for @chSbChatAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get chSbChatAccounts;

  /// No description provided for @chSbChatDiscordText.
  ///
  /// In en, this message translates to:
  /// **'A bot in your Discord server, in private messages or in a channel.'**
  String get chSbChatDiscordText;

  /// No description provided for @chSbChatImText.
  ///
  /// In en, this message translates to:
  /// **'Through a Mac that stays on, with BlueBubbles: the Mac\'s Messages app answers.'**
  String get chSbChatImText;

  /// No description provided for @chSbChatMatrixText.
  ///
  /// In en, this message translates to:
  /// **'A bot account on any Matrix server (matrix.org or your own), in a chat or a room.'**
  String get chSbChatMatrixText;

  /// No description provided for @chSbChatNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account linked yet: send the code below from the chat.'**
  String get chSbChatNoAccount;

  /// No description provided for @chSbChatOnWaiting.
  ///
  /// In en, this message translates to:
  /// **'On: send the code from the chat'**
  String get chSbChatOnWaiting;

  /// No description provided for @chSbChatSignalText.
  ///
  /// In en, this message translates to:
  /// **'A Signal number of its own, through signal-cli-rest-api.'**
  String get chSbChatSignalText;

  /// No description provided for @chSbChatSlackText.
  ///
  /// In en, this message translates to:
  /// **'An app in your Slack workspace, in Socket Mode: no public address needed.'**
  String get chSbChatSlackText;

  /// No description provided for @chSbChatTeamsText.
  ///
  /// In en, this message translates to:
  /// **'A bot in Microsoft Teams, for work or school accounts, through a free Azure Bot.'**
  String get chSbChatTeamsText;

  /// No description provided for @chSbChatWaText.
  ///
  /// In en, this message translates to:
  /// **'Your WhatsApp Business number, through Meta\'s Cloud API.'**
  String get chSbChatWaText;

  /// No description provided for @chSbChatWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the code… this window notices by itself.'**
  String get chSbChatWaiting;

  /// No description provided for @chSbChatsQ.
  ///
  /// In en, this message translates to:
  /// **'Talk to Demi-God from other apps too'**
  String get chSbChatsQ;

  /// No description provided for @chStTgAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get chStTgAccounts;

  /// No description provided for @chTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get chTelegram;

  /// No description provided for @chTgChangeBot.
  ///
  /// In en, this message translates to:
  /// **'Use another bot'**
  String get chTgChangeBot;

  /// No description provided for @chTgLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to {who}'**
  String chTgLinked(String who);

  /// No description provided for @chTgLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'Write to your bot whenever you like: Demi-God passes it on to God and brings back the answer.'**
  String get chTgLinkedHint;

  /// No description provided for @chTgOpenBot.
  ///
  /// In en, this message translates to:
  /// **'Open @{bot}'**
  String chTgOpenBot(String bot);

  /// No description provided for @chTgQr.
  ///
  /// In en, this message translates to:
  /// **'Scan with your phone\'s camera'**
  String get chTgQr;

  /// No description provided for @chTgWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to press Start… this page notices by itself.'**
  String get chTgWaiting;

  /// No description provided for @chUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get chUnlink;

  /// No description provided for @chWzConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get chWzConnect;

  /// No description provided for @chWzDoneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get chWzDoneBtn;

  /// No description provided for @chWzLocked.
  ///
  /// In en, this message translates to:
  /// **'set by the environment'**
  String get chWzLocked;

  /// No description provided for @chWzTgAsks.
  ///
  /// In en, this message translates to:
  /// **'Here I also tell you when a yes of yours is needed.'**
  String get chWzTgAsks;

  /// No description provided for @chWzTgBf1.
  ///
  /// In en, this message translates to:
  /// **'Alright. What shall we call it?'**
  String get chWzTgBf1;

  /// No description provided for @chWzTgBf2.
  ///
  /// In en, this message translates to:
  /// **'Now a username, ending in «bot».'**
  String get chWzTgBf2;

  /// No description provided for @chWzTgBf3.
  ///
  /// In en, this message translates to:
  /// **'Done! Here is the token: 123456789:AAH…'**
  String get chWzTgBf3;

  /// No description provided for @chWzTgBfName.
  ///
  /// In en, this message translates to:
  /// **'My Rasgeth'**
  String get chWzTgBfName;

  /// No description provided for @chWzTgCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get chWzTgCheck;

  /// No description provided for @chWzTgChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get chWzTgChecking;

  /// No description provided for @chWzTgDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get chWzTgDone;

  /// No description provided for @chWzTgExampleBot.
  ///
  /// In en, this message translates to:
  /// **'my_rasgeth_bot'**
  String get chWzTgExampleBot;

  /// No description provided for @chWzTgHaveToken.
  ///
  /// In en, this message translates to:
  /// **'I already have a token'**
  String get chWzTgHaveToken;

  /// No description provided for @chWzTgHello.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m {demigod}. Write to me whenever you like: I pass everything to {god} and bring you the answer.'**
  String chWzTgHello(String demigod, String god);

  /// No description provided for @chWzTgLater.
  ///
  /// In en, this message translates to:
  /// **'later'**
  String get chWzTgLater;

  /// No description provided for @chWzTgLead.
  ///
  /// In en, this message translates to:
  /// **'With Telegram you write to {demigod} from wherever you are and get the notices there: approvals, questions, long jobs, budget. Three steps, a couple of minutes.'**
  String chWzTgLead(String demigod);

  /// No description provided for @chWzTgLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to {who}. Write to {demigod} whenever you like.'**
  String chWzTgLinked(String demigod, String who);

  /// No description provided for @chWzTgLinkedShort.
  ///
  /// In en, this message translates to:
  /// **'Linked. Write to your bot whenever you like.'**
  String get chWzTgLinkedShort;

  /// No description provided for @chWzTgMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chWzTgMessage;

  /// No description provided for @chWzTgNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get chWzTgNow;

  /// No description provided for @chWzTgOfficial.
  ///
  /// In en, this message translates to:
  /// **'Telegram\'s official bot'**
  String get chWzTgOfficial;

  /// No description provided for @chWzTgOnline.
  ///
  /// In en, this message translates to:
  /// **'bot · online'**
  String get chWzTgOnline;

  /// No description provided for @chWzTgOpenBf.
  ///
  /// In en, this message translates to:
  /// **'Open BotFather'**
  String get chWzTgOpenBf;

  /// No description provided for @chWzTgPressStart.
  ///
  /// In en, this message translates to:
  /// **'Press Start to begin talking with this bot.'**
  String get chWzTgPressStart;

  /// No description provided for @chWzTgQ.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth on your phone'**
  String get chWzTgQ;

  /// No description provided for @chWzTgStart.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get chWzTgStart;

  /// No description provided for @chWzTgStep1.
  ///
  /// In en, this message translates to:
  /// **'Make the bot with @BotFather'**
  String get chWzTgStep1;

  /// No description provided for @chWzTgStep1Text.
  ///
  /// In en, this message translates to:
  /// **'BotFather is Telegram\'s official bot that makes bots. Write /newbot to it, give it a name and a username that ends in «bot».'**
  String get chWzTgStep1Text;

  /// No description provided for @chWzTgStep2.
  ///
  /// In en, this message translates to:
  /// **'Paste the token'**
  String get chWzTgStep2;

  /// No description provided for @chWzTgStep2Text.
  ///
  /// In en, this message translates to:
  /// **'BotFather answers with a long line, like 123456789:AAH… It is the bot\'s key: keep it to yourself.'**
  String get chWzTgStep2Text;

  /// No description provided for @chWzTgStep3.
  ///
  /// In en, this message translates to:
  /// **'Pair the phone'**
  String get chWzTgStep3;

  /// No description provided for @chWzTgStep3Text.
  ///
  /// In en, this message translates to:
  /// **'Open {bot} and press Start: Telegram sends it this code by itself, nothing to type.'**
  String chWzTgStep3Text(String bot);

  /// No description provided for @chWzTgToken.
  ///
  /// In en, this message translates to:
  /// **'The bot\'s token'**
  String get chWzTgToken;

  /// No description provided for @chWzTgYouWillSee.
  ///
  /// In en, this message translates to:
  /// **'What you will see in Telegram'**
  String get chWzTgYouWillSee;

  /// No description provided for @chWzTgYourBot.
  ///
  /// In en, this message translates to:
  /// **'Your bot'**
  String get chWzTgYourBot;

  /// No description provided for @chWzTgYourBotName.
  ///
  /// In en, this message translates to:
  /// **'your bot'**
  String get chWzTgYourBotName;

  /// No description provided for @chWzTrying.
  ///
  /// In en, this message translates to:
  /// **'Trying the model…'**
  String get chWzTrying;

  /// No description provided for @moActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get moActive;

  /// No description provided for @moAgentModelDefault.
  ///
  /// In en, this message translates to:
  /// **'The default model'**
  String get moAgentModelDefault;

  /// No description provided for @moAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get moAgents;

  /// No description provided for @moAgentsModel.
  ///
  /// In en, this message translates to:
  /// **'Agent\'s model'**
  String get moAgentsModel;

  /// No description provided for @moBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get moBackup;

  /// No description provided for @moBackupModelNone.
  ///
  /// In en, this message translates to:
  /// **'None: a task given up on stays so'**
  String get moBackupModelNone;

  /// No description provided for @moBackupModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup model for tasks'**
  String get moBackupModelTitle;

  /// No description provided for @moBrainChatgpt.
  ///
  /// In en, this message translates to:
  /// **'ChatGPT subscription'**
  String get moBrainChatgpt;

  /// No description provided for @moBrainChatgptDevice.
  ///
  /// In en, this message translates to:
  /// **'If OpenAI says sign-in with a device code is not allowed: on chatgpt.com open Settings, Security, and turn on device code authorization, then try again.'**
  String get moBrainChatgptDevice;

  /// No description provided for @moBrainChatgptHint.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth uses ChatGPT through OpenAI\'s official Codex program, signed in with your account. What you use counts against your plan\'s limits.'**
  String get moBrainChatgptHint;

  /// No description provided for @moBrainChatgptStart.
  ///
  /// In en, this message translates to:
  /// **'Connect ChatGPT'**
  String get moBrainChatgptStart;

  /// No description provided for @moBrainChatgptStep1.
  ///
  /// In en, this message translates to:
  /// **'Open this page and sign in:'**
  String get moBrainChatgptStep1;

  /// No description provided for @moBrainChatgptStep2.
  ///
  /// In en, this message translates to:
  /// **'Type this code there:'**
  String get moBrainChatgptStep2;

  /// No description provided for @moBrainClaude.
  ///
  /// In en, this message translates to:
  /// **'Claude subscription'**
  String get moBrainClaude;

  /// No description provided for @moBrainClaudeCode.
  ///
  /// In en, this message translates to:
  /// **'Paste the code here'**
  String get moBrainClaudeCode;

  /// No description provided for @moBrainClaudeHint.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth uses Claude through Anthropic\'s official program, signed in with your account. What you use counts against your plan\'s limits, not money.'**
  String get moBrainClaudeHint;

  /// No description provided for @moBrainClaudeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Anthropic\'s sign-in page'**
  String get moBrainClaudeOpen;

  /// No description provided for @moBrainClaudeStep2.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Claude account. At the end Anthropic shows a code: copy it.'**
  String get moBrainClaudeStep2;

  /// No description provided for @moBrainConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get moBrainConnect;

  /// No description provided for @moBrainDefault.
  ///
  /// In en, this message translates to:
  /// **'The model agents use'**
  String get moBrainDefault;

  /// No description provided for @moBrainDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'Agents use this model unless you choose another one for them. It is tried with a real question before it is saved.'**
  String get moBrainDefaultHint;

  /// No description provided for @moBrainDefaultSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: agents will use it.'**
  String get moBrainDefaultSaved;

  /// No description provided for @moBrainDefaultTry.
  ///
  /// In en, this message translates to:
  /// **'Try and use this one'**
  String get moBrainDefaultTry;

  /// No description provided for @moBrainDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get moBrainDisconnect;

  /// No description provided for @moBrainEffortHelp.
  ///
  /// In en, this message translates to:
  /// **'How much it reasons before answering: low is quick and cheap, high is slower but more careful.'**
  String get moBrainEffortHelp;

  /// No description provided for @moBrainKeyExample.
  ///
  /// In en, this message translates to:
  /// **'It looks like this: {example}'**
  String moBrainKeyExample(String example);

  /// No description provided for @moBrainKeyMake.
  ///
  /// In en, this message translates to:
  /// **'Create a key on {name}\'s page'**
  String moBrainKeyMake(String name);

  /// No description provided for @moBrainKeyTry.
  ///
  /// In en, this message translates to:
  /// **'Try and save'**
  String get moBrainKeyTry;

  /// No description provided for @moBrainKeyWorks.
  ///
  /// In en, this message translates to:
  /// **'It works: {n} models available.'**
  String moBrainKeyWorks(String n);

  /// No description provided for @moBrainLocal.
  ///
  /// In en, this message translates to:
  /// **'A model on this computer'**
  String get moBrainLocal;

  /// No description provided for @moBrainNoModel.
  ///
  /// In en, this message translates to:
  /// **'No model is connected yet, so agents cannot answer. Connect one above (a subscription, a key or a local model in the next step), or later in Settings, Models and subscriptions.'**
  String get moBrainNoModel;

  /// No description provided for @moBrainNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Did nothing open?'**
  String get moBrainNotOpened;

  /// No description provided for @moBrainOpenHere.
  ///
  /// In en, this message translates to:
  /// **'Open it here'**
  String get moBrainOpenHere;

  /// No description provided for @moBrainServer.
  ///
  /// In en, this message translates to:
  /// **'A server of yours'**
  String get moBrainServer;

  /// No description provided for @moBrainServerHint.
  ///
  /// In en, this message translates to:
  /// **'If you already run models with Ollama, LM Studio or vLLM, give Rasgeth its address.'**
  String get moBrainServerHint;

  /// No description provided for @moBrainServerKey.
  ///
  /// In en, this message translates to:
  /// **'Its key'**
  String get moBrainServerKey;

  /// No description provided for @moBrainServerKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Only if the server asks for one; most do not.'**
  String get moBrainServerKeyHelp;

  /// No description provided for @moBrainServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get moBrainServerUrl;

  /// No description provided for @moBrainServerUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'With /v1 at the end. Ollama: http://localhost:11434/v1, LM Studio: http://localhost:1234/v1.'**
  String get moBrainServerUrlHelp;

  /// No description provided for @moBrainWhyText.
  ///
  /// In en, this message translates to:
  /// **'If you already pay for Claude or ChatGPT, start with that: nothing more to pay. With a key you pay for what you use, and you can pick among many providers. A model on this computer costs nothing and keeps everything private, but it is slower and less capable than the big online ones. You can combine them: for example a subscription for hard work and a local model for small jobs.'**
  String get moBrainWhyText;

  /// No description provided for @moCatalogBuiltin.
  ///
  /// In en, this message translates to:
  /// **'the one built into Rasgeth'**
  String get moCatalogBuiltin;

  /// No description provided for @moCatalogChecked.
  ///
  /// In en, this message translates to:
  /// **'checked {when}'**
  String moCatalogChecked(String when);

  /// No description provided for @moCatalogDownloaded.
  ///
  /// In en, this message translates to:
  /// **'downloaded and signed'**
  String get moCatalogDownloaded;

  /// No description provided for @moCatalogRefresh.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get moCatalogRefresh;

  /// No description provided for @moCatalogRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get moCatalogRefreshing;

  /// No description provided for @moCatalogRow.
  ///
  /// In en, this message translates to:
  /// **'Models catalog: updated on {date}'**
  String moCatalogRow(String date);

  /// No description provided for @moCatalogUnreachable.
  ///
  /// In en, this message translates to:
  /// **'GitHub did not answer: the catalog in use stays.'**
  String get moCatalogUnreachable;

  /// No description provided for @moCatalogUnsigned.
  ///
  /// In en, this message translates to:
  /// **'The downloaded catalog has no valid signature: it was not used.'**
  String get moCatalogUnsigned;

  /// No description provided for @moCatalogVersion.
  ///
  /// In en, this message translates to:
  /// **'version {n}'**
  String moCatalogVersion(String n);

  /// No description provided for @moChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get moChat;

  /// No description provided for @moDownloaded.
  ///
  /// In en, this message translates to:
  /// **'downloaded'**
  String get moDownloaded;

  /// No description provided for @moDownloads.
  ///
  /// In en, this message translates to:
  /// **'downloads'**
  String get moDownloads;

  /// No description provided for @moEffort.
  ///
  /// In en, this message translates to:
  /// **'Effort'**
  String get moEffort;

  /// No description provided for @moEffortHint.
  ///
  /// In en, this message translates to:
  /// **'Reasoning effort: higher thinks more, is slower and costs more. From the next message.'**
  String get moEffortHint;

  /// No description provided for @moEffort_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get moEffort_high;

  /// No description provided for @moEffort_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get moEffort_low;

  /// No description provided for @moEffort_max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get moEffort_max;

  /// No description provided for @moEffort_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get moEffort_medium;

  /// No description provided for @moError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get moError;

  /// No description provided for @moFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get moFailed;

  /// No description provided for @moJob_step_model_download.
  ///
  /// In en, this message translates to:
  /// **'The model'**
  String get moJob_step_model_download;

  /// No description provided for @moLmBeyondMemory.
  ///
  /// In en, this message translates to:
  /// **'bigger than RAM and card together: part of it is read from the SSD at each token, slower'**
  String get moLmBeyondMemory;

  /// No description provided for @moLmBigChunks.
  ///
  /// In en, this message translates to:
  /// **'Big chunks'**
  String get moLmBigChunks;

  /// No description provided for @moLmBigChunksHelp.
  ///
  /// In en, this message translates to:
  /// **'Reads long messages in passes of 8,192 or 16,384 tokens instead of 4,096, when the graphics card has room for them, and loads the model in RAM when it fits with a margin: the experts go through the card once a pass, so fewer passes read faster. The first start measures them on a long message (a few minutes more) and keeps the fastest. Only for mixture-of-experts models.'**
  String get moLmBigChunksHelp;

  /// No description provided for @moLmCardDownloading.
  ///
  /// In en, this message translates to:
  /// **'downloading, {pct}%'**
  String moLmCardDownloading(String pct);

  /// No description provided for @moLmCardGet.
  ///
  /// In en, this message translates to:
  /// **'to download, {size}'**
  String moLmCardGet(String size);

  /// No description provided for @moLmCardOff.
  ///
  /// In en, this message translates to:
  /// **'chosen, turned off'**
  String get moLmCardOff;

  /// No description provided for @moLmCardPaused.
  ///
  /// In en, this message translates to:
  /// **'download paused'**
  String get moLmCardPaused;

  /// No description provided for @moLmCardReady.
  ///
  /// In en, this message translates to:
  /// **'downloaded'**
  String get moLmCardReady;

  /// No description provided for @moLmCardTooBig.
  ///
  /// In en, this message translates to:
  /// **'too big for this computer'**
  String get moLmCardTooBig;

  /// No description provided for @moLmContextTokens.
  ///
  /// In en, this message translates to:
  /// **'tokens of context'**
  String get moLmContextTokens;

  /// No description provided for @moLmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get moLmDelete;

  /// No description provided for @moLmDeleteActiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'This model is in use: the engine stops and the file is deleted. Go on?'**
  String get moLmDeleteActiveConfirm;

  /// No description provided for @moLmDiscard.
  ///
  /// In en, this message translates to:
  /// **'Throw away the download'**
  String get moLmDiscard;

  /// No description provided for @moLmDownload.
  ///
  /// In en, this message translates to:
  /// **'Download · {size}'**
  String moLmDownload(String size);

  /// No description provided for @moLmDownloadedBusy.
  ///
  /// In en, this message translates to:
  /// **'downloading'**
  String get moLmDownloadedBusy;

  /// No description provided for @moLmDownloadedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? It frees {size}.'**
  String moLmDownloadedConfirm(String name, String size);

  /// No description provided for @moLmDownloadedConfirmActive.
  ///
  /// In en, this message translates to:
  /// **'{name} is the model in use: the engine stops and the file is deleted ({size}). Go on?'**
  String moLmDownloadedConfirmActive(String name, String size);

  /// No description provided for @moLmDownloadedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No model downloaded yet.'**
  String get moLmDownloadedEmpty;

  /// No description provided for @moLmDownloadedHelp.
  ///
  /// In en, this message translates to:
  /// **'Every model file in the folder ({size} in all), the biggest first. Deleting one frees its room at once; the suggested ones can be downloaded again.'**
  String moLmDownloadedHelp(String size);

  /// No description provided for @moLmDownloadedNote.
  ///
  /// In en, this message translates to:
  /// **'{n} on the disk · {size}'**
  String moLmDownloadedNote(String n, String size);

  /// No description provided for @moLmDownloadedPartial.
  ///
  /// In en, this message translates to:
  /// **'incomplete'**
  String get moLmDownloadedPartial;

  /// No description provided for @moLmDownloadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded models'**
  String get moLmDownloadedTitle;

  /// No description provided for @moLmEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get moLmEngine;

  /// No description provided for @moLmEngineHelp.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth picks the one that suits this computer. Change it only if starting fails.'**
  String get moLmEngineHelp;

  /// No description provided for @moLmEngine_cpu.
  ///
  /// In en, this message translates to:
  /// **'Processor'**
  String get moLmEngine_cpu;

  /// No description provided for @moLmEngine_cuda.
  ///
  /// In en, this message translates to:
  /// **'NVIDIA graphics card (CUDA)'**
  String get moLmEngine_cuda;

  /// No description provided for @moLmEngine_mac.
  ///
  /// In en, this message translates to:
  /// **'The Mac\'s graphics chip (Metal), next to Rasgeth'**
  String get moLmEngine_mac;

  /// No description provided for @moLmEngine_vulkan.
  ///
  /// In en, this message translates to:
  /// **'AMD, Intel or built-in graphics (Vulkan)'**
  String get moLmEngine_vulkan;

  /// No description provided for @moLmEngine_windows.
  ///
  /// In en, this message translates to:
  /// **'Graphics card, with Windows\' own engine (Vulkan)'**
  String get moLmEngine_windows;

  /// No description provided for @moLmExperimental.
  ///
  /// In en, this message translates to:
  /// **'experimental'**
  String get moLmExperimental;

  /// No description provided for @moLmFactCache.
  ///
  /// In en, this message translates to:
  /// **'Experts\' cache in the card'**
  String get moLmFactCache;

  /// No description provided for @moLmFactRam.
  ///
  /// In en, this message translates to:
  /// **'Free RAM counted'**
  String get moLmFactRam;

  /// No description provided for @moLmFactSsd.
  ///
  /// In en, this message translates to:
  /// **'From the SSD at each token'**
  String get moLmFactSsd;

  /// No description provided for @moLmFactSsdGb.
  ///
  /// In en, this message translates to:
  /// **'about {gb} GB'**
  String moLmFactSsdGb(String gb);

  /// No description provided for @moLmFactSsdNone.
  ///
  /// In en, this message translates to:
  /// **'nothing: it fits in RAM'**
  String get moLmFactSsdNone;

  /// No description provided for @moLmGbPerSec.
  ///
  /// In en, this message translates to:
  /// **'{n} GB/s'**
  String moLmGbPerSec(String n);

  /// No description provided for @moLmHwCpu.
  ///
  /// In en, this message translates to:
  /// **'No graphics card to use: models run on the processor, slower; small ones, up to about {max} GB.'**
  String moLmHwCpu(String max);

  /// No description provided for @moLmHwGpu.
  ///
  /// In en, this message translates to:
  /// **'{name} with {vram} GB of video memory: models up to about {max} GB run on it, fast.'**
  String moLmHwGpu(String max, String name, String vram);

  /// No description provided for @moLmHwGpuUnknown.
  ///
  /// In en, this message translates to:
  /// **'An NVIDIA graphics card is available, but its memory is unknown: start with a small model.'**
  String get moLmHwGpuUnknown;

  /// No description provided for @moLmHwIgpu.
  ///
  /// In en, this message translates to:
  /// **'A graphics chip built into the processor: a little faster than the processor alone; models up to about {max} GB.'**
  String moLmHwIgpu(String max);

  /// No description provided for @moLmHwUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The engine cannot reach the graphics card here: models run on the processor, slower; up to about {max} GB.'**
  String moLmHwUnreachable(String max);

  /// No description provided for @moLmInUse.
  ///
  /// In en, this message translates to:
  /// **'in use'**
  String get moLmInUse;

  /// No description provided for @moLmLoading.
  ///
  /// In en, this message translates to:
  /// **'Looking up the models…'**
  String get moLmLoading;

  /// No description provided for @moLmMoePrefetch.
  ///
  /// In en, this message translates to:
  /// **'Next layer ahead'**
  String get moLmMoePrefetch;

  /// No description provided for @moLmOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get moLmOff;

  /// No description provided for @moLmOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get moLmOn;

  /// No description provided for @moLmOther.
  ///
  /// In en, this message translates to:
  /// **'Other models in the folder'**
  String get moLmOther;

  /// No description provided for @moLmOtherHelp.
  ///
  /// In en, this message translates to:
  /// **'A model file in the folder, not among the suggested ones ({size}).'**
  String moLmOtherHelp(String size);

  /// No description provided for @moLmPartRamSub.
  ///
  /// In en, this message translates to:
  /// **'{free} free now'**
  String moLmPartRamSub(String free);

  /// No description provided for @moLmPartSsd.
  ///
  /// In en, this message translates to:
  /// **'Models\' SSD'**
  String get moLmPartSsd;

  /// No description provided for @moLmPartSsdSub.
  ///
  /// In en, this message translates to:
  /// **'{free} free'**
  String moLmPartSsdSub(String free);

  /// No description provided for @moLmPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get moLmPause;

  /// No description provided for @moLmPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused: {done} of {total}'**
  String moLmPaused(String done, String total);

  /// No description provided for @moLmPausedAt.
  ///
  /// In en, this message translates to:
  /// **'Paused at {done}'**
  String moLmPausedAt(String done);

  /// No description provided for @moLmPreloadSpeed.
  ///
  /// In en, this message translates to:
  /// **'Model read from the disk'**
  String get moLmPreloadSpeed;

  /// No description provided for @moLmRecommended.
  ///
  /// In en, this message translates to:
  /// **'recommended'**
  String get moLmRecommended;

  /// No description provided for @moLmResume.
  ///
  /// In en, this message translates to:
  /// **'Go on'**
  String get moLmResume;

  /// No description provided for @moLmRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get moLmRoom;

  /// No description provided for @moLmScoresHint.
  ///
  /// In en, this message translates to:
  /// **'The bars compare these models with each other (five is the best of them). Speed is an estimate for this computer.'**
  String get moLmScoresHint;

  /// No description provided for @moLmSearch.
  ///
  /// In en, this message translates to:
  /// **'Other models from Hugging Face'**
  String get moLmSearch;

  /// No description provided for @moLmSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, choose a repository and a file. Files that are not models are hidden.'**
  String get moLmSearchHint;

  /// No description provided for @moLmSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. gemma, qwen, mistral'**
  String get moLmSearchPlaceholder;

  /// No description provided for @moLmShowActivation.
  ///
  /// In en, this message translates to:
  /// **'Show the activation'**
  String get moLmShowActivation;

  /// No description provided for @moLmSpecDraft.
  ///
  /// In en, this message translates to:
  /// **'With a small model of the family'**
  String get moLmSpecDraft;

  /// No description provided for @moLmSpecDraftGet.
  ///
  /// In en, this message translates to:
  /// **'Download the small model · {size}'**
  String moLmSpecDraftGet(String size);

  /// No description provided for @moLmSpecDraftHelp.
  ///
  /// In en, this message translates to:
  /// **'{name} ({size}) proposes up to 8 tokens; it stays all in the card with its own context, so the big model gets a little less room there. It only works with a model of the same family (same vocabulary): Rasgeth picks it.'**
  String moLmSpecDraftHelp(String name, String size);

  /// No description provided for @moLmSpecDraftReady.
  ///
  /// In en, this message translates to:
  /// **'small model ready'**
  String get moLmSpecDraftReady;

  /// No description provided for @moLmSpecHelp.
  ///
  /// In en, this message translates to:
  /// **'Writes faster without changing the answers: something cheap proposes the next tokens and the model checks them all in one pass, reading its weights once for several tokens. It helps most where the text is predictable (code being rewritten, long dense models outside the card); on new prose it gains little. Measured on an RTX 4080 Super: Llama 3.3 70B (mostly in RAM) from 1.1 to 2.6 tokens/s on new prose and to 7.4 on code rewritten; Qwen3 14B (in the card) from 59 to 155 on code, about even on prose. The speed is shown under each answer.'**
  String get moLmSpecHelp;

  /// No description provided for @moLmSpecNgram.
  ///
  /// In en, this message translates to:
  /// **'From the text already written'**
  String get moLmSpecNgram;

  /// No description provided for @moLmSpecNgramHelp.
  ///
  /// In en, this message translates to:
  /// **'The proposals come from pieces of the conversation that repeat (code being edited, documents quoted back): no second model, no memory used. It helps only there: on new prose nothing, and on a large dense model little even on code (measured: Llama 3.3 70B 1.1 -> 1.3). Prefer the small model when the family has one.'**
  String get moLmSpecNgramHelp;

  /// No description provided for @moLmSpecNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get moLmSpecNone;

  /// No description provided for @moLmSpecTitle.
  ///
  /// In en, this message translates to:
  /// **'Speculative decoding (for experts)'**
  String get moLmSpecTitle;

  /// No description provided for @moLmSpeedEstimate.
  ///
  /// In en, this message translates to:
  /// **'tokens/s, estimate'**
  String get moLmSpeedEstimate;

  /// No description provided for @moLmSpeedMeasured.
  ///
  /// In en, this message translates to:
  /// **'tokens/s, measured'**
  String get moLmSpeedMeasured;

  /// No description provided for @moLmSpeedTest.
  ///
  /// In en, this message translates to:
  /// **'Measure the gain'**
  String get moLmSpeedTest;

  /// No description provided for @moLmSpeedTestCode.
  ///
  /// In en, this message translates to:
  /// **'Code rewritten (tokens/s)'**
  String get moLmSpeedTestCode;

  /// No description provided for @moLmSpeedTestCost.
  ///
  /// In en, this message translates to:
  /// **'It takes a good while and a lot of compute: the model is loaded several times, minutes for a large one. Meanwhile the local model does not answer the agents.'**
  String get moLmSpeedTestCost;

  /// No description provided for @moLmSpeedTestDone.
  ///
  /// In en, this message translates to:
  /// **'The engine is back as it was. Choose the way above and start the model again to use it.'**
  String get moLmSpeedTestDone;

  /// No description provided for @moLmSpeedTestIntro.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth starts this model once for each way of writing (alone, with the small model, with the n-grams), has it write a short new text and rewrite a piece of code, and shows the tokens a second of each. In the end the engine goes back to how it was.'**
  String get moLmSpeedTestIntro;

  /// No description provided for @moLmSpeedTestMode.
  ///
  /// In en, this message translates to:
  /// **'Way'**
  String get moLmSpeedTestMode;

  /// No description provided for @moLmSpeedTestProse.
  ///
  /// In en, this message translates to:
  /// **'New text (tokens/s)'**
  String get moLmSpeedTestProse;

  /// No description provided for @moLmSpeedTestStart.
  ///
  /// In en, this message translates to:
  /// **'Start the test'**
  String get moLmSpeedTestStart;

  /// No description provided for @moLmSpeedTestTitle.
  ///
  /// In en, this message translates to:
  /// **'How much faster here'**
  String get moLmSpeedTestTitle;

  /// No description provided for @moLmStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get moLmStart;

  /// No description provided for @moLmStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get moLmStarting;

  /// No description provided for @moLmStream.
  ///
  /// In en, this message translates to:
  /// **'SSD stream'**
  String get moLmStream;

  /// No description provided for @moLmStreamCache.
  ///
  /// In en, this message translates to:
  /// **', {gb} of the card for the experts'**
  String moLmStreamCache(String gb);

  /// No description provided for @moLmStreamFromCard.
  ///
  /// In en, this message translates to:
  /// **'the model fits in the card'**
  String get moLmStreamFromCard;

  /// No description provided for @moLmStreamFromRam.
  ///
  /// In en, this message translates to:
  /// **'the model fits in RAM: the SSD is only read at the start'**
  String get moLmStreamFromRam;

  /// No description provided for @moLmStreamFromSsd.
  ///
  /// In en, this message translates to:
  /// **'about {gb} GB read from the SSD at each token'**
  String moLmStreamFromSsd(String gb);

  /// No description provided for @moLmStreamHdd.
  ///
  /// In en, this message translates to:
  /// **'Not available: {disk} is a spinning disk, too slow to read a model from at each token.'**
  String moLmStreamHdd(String disk);

  /// No description provided for @moLmStreamMaybeSsd.
  ///
  /// In en, this message translates to:
  /// **'Windows does not say whether {disk} is an SSD: use it only if it is.'**
  String moLmStreamMaybeSsd(String disk);

  /// No description provided for @moLmStreamNoRoom.
  ///
  /// In en, this message translates to:
  /// **'Not available: {disk} has only {free} free; it needs at least 20 GB.'**
  String moLmStreamNoRoom(String disk, String free);

  /// No description provided for @moLmStreamPlan.
  ///
  /// In en, this message translates to:
  /// **'In use: context up to {ctx} tokens{cache}, {source} (counting {ram} of free RAM).'**
  String moLmStreamPlan(String cache, String ctx, String ram, String source);

  /// No description provided for @moLmStreamThisDisk.
  ///
  /// In en, this message translates to:
  /// **'the models\' disk'**
  String get moLmStreamThisDisk;

  /// No description provided for @moLmStreamUnknownDisk.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth does not know yet which disk holds the models (it learns at the next start of Rasgeth): use it only if it is an SSD.'**
  String get moLmStreamUnknownDisk;

  /// No description provided for @moLmSysmemClose.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get moLmSysmemClose;

  /// No description provided for @moLmSysmemStep1.
  ///
  /// In en, this message translates to:
  /// **'Open the NVIDIA Control Panel (right click on the desktop).'**
  String get moLmSysmemStep1;

  /// No description provided for @moLmSysmemStep2.
  ///
  /// In en, this message translates to:
  /// **'Manage 3D settings, then Global Settings (or Program Settings with llama-server.exe, for the engine only).'**
  String get moLmSysmemStep2;

  /// No description provided for @moLmSysmemStep3.
  ///
  /// In en, this message translates to:
  /// **'CUDA - Sysmem Fallback Policy: choose «Prefer No Sysmem Fallback» and Apply.'**
  String get moLmSysmemStep3;

  /// No description provided for @moLmSysmemStep4.
  ///
  /// In en, this message translates to:
  /// **'Start the model again: the engine reads the setting when it starts.'**
  String get moLmSysmemStep4;

  /// No description provided for @moLmSysmemText.
  ///
  /// In en, this message translates to:
  /// **'When the card\'s memory runs out, NVIDIA\'s driver on Windows uses the computer\'s RAM instead of failing: reading messages becomes 2 to 3.5 times slower. Rasgeth cannot read this setting, so check it once:'**
  String get moLmSysmemText;

  /// No description provided for @moLmSysmemTitle.
  ///
  /// In en, this message translates to:
  /// **'NVIDIA card: turn off «CUDA Sysmem Fallback»'**
  String get moLmSysmemTitle;

  /// No description provided for @moLmThisPc.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get moLmThisPc;

  /// No description provided for @moLmTokensPerSec.
  ///
  /// In en, this message translates to:
  /// **'{n} tokens/s'**
  String moLmTokensPerSec(String n);

  /// No description provided for @moLmTokensUnit.
  ///
  /// In en, this message translates to:
  /// **'tokens/s'**
  String get moLmTokensUnit;

  /// No description provided for @moLmTooBig.
  ///
  /// In en, this message translates to:
  /// **'It needs at least {need}: this computer has room for {max}.'**
  String moLmTooBig(String max, String need);

  /// No description provided for @moLmTuneBatch.
  ///
  /// In en, this message translates to:
  /// **'passes of {n} tokens'**
  String moLmTuneBatch(String n);

  /// No description provided for @moLmTuneCache.
  ///
  /// In en, this message translates to:
  /// **'Card for the experts'**
  String get moLmTuneCache;

  /// No description provided for @moLmTuneChosen.
  ///
  /// In en, this message translates to:
  /// **'kept'**
  String get moLmTuneChosen;

  /// No description provided for @moLmTuneCtx.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get moLmTuneCtx;

  /// No description provided for @moLmTuneFailed.
  ///
  /// In en, this message translates to:
  /// **'did not start'**
  String get moLmTuneFailed;

  /// No description provided for @moLmTuneHelp.
  ///
  /// In en, this message translates to:
  /// **'Each row is a real try: the model reads a context of about 2,000 tokens and writes 64. A typical turn is an agent reading 1,500 tokens of tool results and writing 300: the fastest one is kept for this model, and you can pick another.'**
  String get moLmTuneHelp;

  /// No description provided for @moLmTuneLongRead.
  ///
  /// In en, this message translates to:
  /// **'a message of {n} tokens'**
  String moLmTuneLongRead(String n);

  /// No description provided for @moLmTuneNoCopy.
  ///
  /// In en, this message translates to:
  /// **'experts computed on the processor when reading'**
  String get moLmTuneNoCopy;

  /// No description provided for @moLmTuneRead.
  ///
  /// In en, this message translates to:
  /// **'Reading (tok/s)'**
  String get moLmTuneRead;

  /// No description provided for @moLmTuneRunning.
  ///
  /// In en, this message translates to:
  /// **'measuring…'**
  String get moLmTuneRunning;

  /// No description provided for @moLmTuneTitle.
  ///
  /// In en, this message translates to:
  /// **'Tuning on this computer'**
  String get moLmTuneTitle;

  /// No description provided for @moLmTuneTurn.
  ///
  /// In en, this message translates to:
  /// **'Typical turn (s)'**
  String get moLmTuneTurn;

  /// No description provided for @moLmTuneUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get moLmTuneUse;

  /// No description provided for @moLmTuneWrite.
  ///
  /// In en, this message translates to:
  /// **'Writing (tok/s)'**
  String get moLmTuneWrite;

  /// No description provided for @moLmUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Hugging Face does not answer: try again later.'**
  String get moLmUnavailable;

  /// No description provided for @moLmUseForAgents.
  ///
  /// In en, this message translates to:
  /// **'Use it for the agents'**
  String get moLmUseForAgents;

  /// No description provided for @moLmUsedForAgents.
  ///
  /// In en, this message translates to:
  /// **'The agents will use this model.'**
  String get moLmUsedForAgents;

  /// No description provided for @moLmVersionSuggested.
  ///
  /// In en, this message translates to:
  /// **'suggested'**
  String get moLmVersionSuggested;

  /// No description provided for @moLmVersions.
  ///
  /// In en, this message translates to:
  /// **'Version of the file'**
  String get moLmVersions;

  /// No description provided for @moLmWarmHelp.
  ///
  /// In en, this message translates to:
  /// **'The model reads its first context and writes a few words. The first time on a new graphics card this takes minutes: the card prepares its programs once, and then it is fast.'**
  String get moLmWarmHelp;

  /// No description provided for @moLmWarmSpeed.
  ///
  /// In en, this message translates to:
  /// **'Context read (as a first message)'**
  String get moLmWarmSpeed;

  /// No description provided for @moLmWhere.
  ///
  /// In en, this message translates to:
  /// **'Where the model goes'**
  String get moLmWhere;

  /// No description provided for @moLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get moLoading;

  /// No description provided for @moModelHint.
  ///
  /// In en, this message translates to:
  /// **'The model of this conversation (agents\' models: Settings, Agents)'**
  String get moModelHint;

  /// No description provided for @moModelNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get moModelNew;

  /// No description provided for @moModelPick.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get moModelPick;

  /// No description provided for @moModelSearch.
  ///
  /// In en, this message translates to:
  /// **'Search a model'**
  String get moModelSearch;

  /// No description provided for @moModelUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'data to be confirmed'**
  String get moModelUnconfirmed;

  /// No description provided for @moModelWay.
  ///
  /// In en, this message translates to:
  /// **'How it goes'**
  String get moModelWay;

  /// No description provided for @moMpChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get moMpChange;

  /// No description provided for @moMpLead.
  ///
  /// In en, this message translates to:
  /// **'Pick one or more ways: combine them as you like. Each square opens its window; the lit ones are connected.'**
  String get moMpLead;

  /// No description provided for @moMpLocalLead.
  ///
  /// In en, this message translates to:
  /// **'Free, and nothing leaves here: the computer, where the models are, the models to download and the ones already on the disk.'**
  String get moMpLocalLead;

  /// No description provided for @moMpNoDefault.
  ///
  /// In en, this message translates to:
  /// **'No model chosen'**
  String get moMpNoDefault;

  /// No description provided for @moMpNoDefaultText.
  ///
  /// In en, this message translates to:
  /// **'Connect a way above, then choose the one agents use.'**
  String get moMpNoDefaultText;

  /// No description provided for @moMpSearchLead.
  ///
  /// In en, this message translates to:
  /// **'How agents look things up on the internet. One provider at a time: the lit one is in use.'**
  String get moMpSearchLead;

  /// No description provided for @moMpSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Web search'**
  String get moMpSearchTitle;

  /// No description provided for @moSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get moSearch;

  /// No description provided for @moSearchInUse.
  ///
  /// In en, this message translates to:
  /// **'in use'**
  String get moSearchInUse;

  /// No description provided for @moSubsDeviceWait.
  ///
  /// In en, this message translates to:
  /// **'This page notices by itself when you are done.'**
  String get moSubsDeviceWait;

  /// No description provided for @moSubsLoggedAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in: {who} {plan}'**
  String moSubsLoggedAs(String plan, String who);

  /// No description provided for @moSubsProgramDownload.
  ///
  /// In en, this message translates to:
  /// **'{name} is downloaded when you switch this on (once, a few hundred MB, with its bar in the corner).'**
  String moSubsProgramDownload(String name);

  /// No description provided for @moSubsProgramSystem.
  ///
  /// In en, this message translates to:
  /// **'{name} is already installed on this computer: Rasgeth uses it.'**
  String moSubsProgramSystem(String name);

  /// No description provided for @moSubsSharedLogin.
  ///
  /// In en, this message translates to:
  /// **'{name} is already signed in on this computer: Rasgeth uses that sign-in as it is, no need to sign in again.'**
  String moSubsSharedLogin(String name);

  /// No description provided for @moSubsUseShared.
  ///
  /// In en, this message translates to:
  /// **'Use the sign-in already here'**
  String get moSubsUseShared;

  /// No description provided for @moSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Models and subscriptions'**
  String get moSubscriptions;

  /// No description provided for @moTermsOf.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s terms'**
  String moTermsOf(String name);

  /// No description provided for @moUiAboutHours.
  ///
  /// In en, this message translates to:
  /// **'about {h} h {min} min left'**
  String moUiAboutHours(String h, String min);

  /// No description provided for @moUiAboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'about {min} min left'**
  String moUiAboutMinutes(String min);

  /// No description provided for @moUiDropNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches.'**
  String get moUiDropNone;

  /// No description provided for @moUiLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'less than a minute left'**
  String get moUiLessThanMinute;

  /// No description provided for @moUiNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'not needed'**
  String get moUiNotNeeded;

  /// No description provided for @moUiOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String moUiOf(String done, String total);

  /// No description provided for @moViaLocal.
  ///
  /// In en, this message translates to:
  /// **'local'**
  String get moViaLocal;

  /// No description provided for @moViaSubscription.
  ///
  /// In en, this message translates to:
  /// **'subscription'**
  String get moViaSubscription;

  /// No description provided for @moWzAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get moWzAgents;

  /// No description provided for @moWzAgentsSub.
  ///
  /// In en, this message translates to:
  /// **'they do the work'**
  String get moWzAgentsSub;

  /// No description provided for @moWzAgentsText.
  ///
  /// In en, this message translates to:
  /// **'They get their tasks from the orchestrators: they write code, test, search.'**
  String get moWzAgentsText;

  /// No description provided for @moWzAlreadySet.
  ///
  /// In en, this message translates to:
  /// **'already set'**
  String get moWzAlreadySet;

  /// No description provided for @moWzAssign.
  ///
  /// In en, this message translates to:
  /// **'Who uses which model'**
  String get moWzAssign;

  /// No description provided for @moWzAssignChat.
  ///
  /// In en, this message translates to:
  /// **'The everyday chat, with web search: questions, texts, ideas.'**
  String get moWzAssignChat;

  /// No description provided for @moWzAssignConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect a model'**
  String get moWzAssignConnect;

  /// No description provided for @moWzAssignDemigod2.
  ///
  /// In en, this message translates to:
  /// **'Answers you on Telegram and in the chats, and passes the work on: a fast model is enough.'**
  String get moWzAssignDemigod2;

  /// No description provided for @moWzAssignEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not connected any model yet, so there is nothing to choose here. Connect one in «How should Rasgeth think?» or start a local model.'**
  String get moWzAssignEmpty;

  /// No description provided for @moWzAssignGod.
  ///
  /// In en, this message translates to:
  /// **'The one who runs everything: plans, projects, other agents. The strongest model pays off here.'**
  String get moWzAssignGod;

  /// No description provided for @moWzAssignLead.
  ///
  /// In en, this message translates to:
  /// **'Each one works with its own model: the strongest for who decides, a fast one for who answers. Touch a model to change it.'**
  String get moWzAssignLead;

  /// No description provided for @moWzAssignLocal.
  ///
  /// In en, this message translates to:
  /// **'Choose a local model'**
  String get moWzAssignLocal;

  /// No description provided for @moWzAssignOthers.
  ///
  /// In en, this message translates to:
  /// **'The agents you create later'**
  String get moWzAssignOthers;

  /// No description provided for @moWzAssignOthersHelp.
  ///
  /// In en, this message translates to:
  /// **'And the board\'s summaries, unless you choose one for them. It is tried with a real question before it is saved.'**
  String get moWzAssignOthersHelp;

  /// No description provided for @moWzAssistants.
  ///
  /// In en, this message translates to:
  /// **'Personal assistants'**
  String get moWzAssistants;

  /// No description provided for @moWzAssistantsSub.
  ///
  /// In en, this message translates to:
  /// **'they work for you'**
  String get moWzAssistantsSub;

  /// No description provided for @moWzBackupText.
  ///
  /// In en, this message translates to:
  /// **'If an agent gives up on a task (an error, the budget, no check passed), this model tries it once more, knowing what the first one did. Best from another provider.'**
  String get moWzBackupText;

  /// No description provided for @moWzBackupWindow.
  ///
  /// In en, this message translates to:
  /// **'Tries the tasks given up on once more, in a new conversation.'**
  String get moWzBackupWindow;

  /// No description provided for @moWzBrain.
  ///
  /// In en, this message translates to:
  /// **'How should Rasgeth think?'**
  String get moWzBrain;

  /// No description provided for @moWzBrainChatgpt.
  ///
  /// In en, this message translates to:
  /// **'Your ChatGPT Plus or Pro plan. You type a short code on OpenAI\'s page.'**
  String get moWzBrainChatgpt;

  /// No description provided for @moWzBrainClaude.
  ///
  /// In en, this message translates to:
  /// **'Your Claude Pro or Max plan. You sign in on Anthropic\'s page.'**
  String get moWzBrainClaude;

  /// No description provided for @moWzBrainKeys.
  ///
  /// In en, this message translates to:
  /// **'Anthropic, OpenAI, Gemini, Mistral, DeepSeek, Grok and more. You pay for what you use.'**
  String get moWzBrainKeys;

  /// No description provided for @moWzBrainKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'An API key'**
  String get moWzBrainKeysTitle;

  /// No description provided for @moWzBrainLocal.
  ///
  /// In en, this message translates to:
  /// **'Free and private: nothing leaves this computer. You choose it in the next step.'**
  String get moWzBrainLocal;

  /// No description provided for @moWzBrainQ.
  ///
  /// In en, this message translates to:
  /// **'How should Rasgeth think?'**
  String get moWzBrainQ;

  /// No description provided for @moWzBrainServer.
  ///
  /// In en, this message translates to:
  /// **'Ollama, LM Studio, vLLM or another server that speaks OpenAI\'s language.'**
  String get moWzBrainServer;

  /// No description provided for @moWzChosen.
  ///
  /// In en, this message translates to:
  /// **'chosen'**
  String get moWzChosen;

  /// No description provided for @moWzDefaultModel.
  ///
  /// In en, this message translates to:
  /// **'Default model'**
  String get moWzDefaultModel;

  /// No description provided for @moWzDemiRole.
  ///
  /// In en, this message translates to:
  /// **'The spokesperson'**
  String get moWzDemiRole;

  /// No description provided for @moWzDense.
  ///
  /// In en, this message translates to:
  /// **'{b} billion · dense'**
  String moWzDense(String b);

  /// No description provided for @moWzDiskHdd.
  ///
  /// In en, this message translates to:
  /// **'A spinning disk: too slow for the models.'**
  String get moWzDiskHdd;

  /// No description provided for @moWzDisksLead.
  ///
  /// In en, this message translates to:
  /// **'A model takes from 3 to 80 GB. A fast SSD is best: SSD stream reads from there.'**
  String get moWzDisksLead;

  /// No description provided for @moWzDisksNoMove.
  ///
  /// In en, this message translates to:
  /// **'The models can be moved to another disk only in Rasgeth\'s Windows installation.'**
  String get moWzDisksNoMove;

  /// No description provided for @moWzDisksOne.
  ///
  /// In en, this message translates to:
  /// **'Here the models stay in Rasgeth\'s data folder. In Rasgeth\'s Windows installation you can move them to another SSD.'**
  String get moWzDisksOne;

  /// No description provided for @moWzDisksTitle.
  ///
  /// In en, this message translates to:
  /// **'Where the models stay'**
  String get moWzDisksTitle;

  /// No description provided for @moWzDoneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get moWzDoneBtn;

  /// No description provided for @moWzEffortHelp.
  ///
  /// In en, this message translates to:
  /// **'A little is fast and cheap, deeply is slower but more careful. It stays fixed for each conversation.'**
  String get moWzEffortHelp;

  /// No description provided for @moWzEffortTitle.
  ///
  /// In en, this message translates to:
  /// **'How much it thinks before answering'**
  String get moWzEffortTitle;

  /// No description provided for @moWzEffort_high.
  ///
  /// In en, this message translates to:
  /// **'Deeply'**
  String get moWzEffort_high;

  /// No description provided for @moWzEffort_low.
  ///
  /// In en, this message translates to:
  /// **'A little'**
  String get moWzEffort_low;

  /// No description provided for @moWzEffort_max.
  ///
  /// In en, this message translates to:
  /// **'The most'**
  String get moWzEffort_max;

  /// No description provided for @moWzEffort_medium.
  ///
  /// In en, this message translates to:
  /// **'Just right'**
  String get moWzEffort_medium;

  /// No description provided for @moWzFitNone.
  ///
  /// In en, this message translates to:
  /// **'None runs fast enough here: the ones below work, slowly.'**
  String get moWzFitNone;

  /// No description provided for @moWzFitTab.
  ///
  /// In en, this message translates to:
  /// **'Suited'**
  String get moWzFitTab;

  /// No description provided for @moWzFitTitle.
  ///
  /// In en, this message translates to:
  /// **'Suited to this computer'**
  String get moWzFitTitle;

  /// No description provided for @moWzFitsUpTo.
  ///
  /// In en, this message translates to:
  /// **'Models up to about {max} run fast here; bigger ones use the RAM too.'**
  String moWzFitsUpTo(String max);

  /// No description provided for @moWzFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get moWzFolder;

  /// No description provided for @moWzFolderHelp.
  ///
  /// In en, this message translates to:
  /// **'A folder of this disk; it is created if it is not there.'**
  String get moWzFolderHelp;

  /// No description provided for @moWzFolderLead.
  ///
  /// In en, this message translates to:
  /// **'Where Rasgeth keeps the models\' files on this disk. The ones already downloaded are copied there.'**
  String get moWzFolderLead;

  /// No description provided for @moWzFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'The models\' folder on {disk}'**
  String moWzFolderTitle(String disk);

  /// No description provided for @moWzFree.
  ///
  /// In en, this message translates to:
  /// **'free'**
  String get moWzFree;

  /// No description provided for @moWzFreeOf.
  ///
  /// In en, this message translates to:
  /// **'free of {total} GB'**
  String moWzFreeOf(String total);

  /// No description provided for @moWzGodRole.
  ///
  /// In en, this message translates to:
  /// **'The boss'**
  String get moWzGodRole;

  /// No description provided for @moWzHereNow.
  ///
  /// In en, this message translates to:
  /// **'here now'**
  String get moWzHereNow;

  /// No description provided for @moWzHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get moWzHowItWorks;

  /// No description provided for @moWzKeyOf.
  ///
  /// In en, this message translates to:
  /// **'The key of {name}'**
  String moWzKeyOf(String name);

  /// No description provided for @moWzKeysLead.
  ///
  /// In en, this message translates to:
  /// **'A key is like a password that lets Rasgeth use the provider\'s models on your account. You pay the provider for what you use. Add as many as you like: each one is tried at once.'**
  String get moWzKeysLead;

  /// No description provided for @moWzLegend.
  ///
  /// In en, this message translates to:
  /// **'Green outline: it runs on this computer between the graphics card and the RAM, at least {n} tokens a second. The others work, but slowly.'**
  String moWzLegend(String n);

  /// No description provided for @moWzLikeAbove.
  ///
  /// In en, this message translates to:
  /// **'The same as {who}'**
  String moWzLikeAbove(String who);

  /// No description provided for @moWzLocal.
  ///
  /// In en, this message translates to:
  /// **'Local model'**
  String get moWzLocal;

  /// No description provided for @moWzLocalQ.
  ///
  /// In en, this message translates to:
  /// **'A model on this computer'**
  String get moWzLocalQ;

  /// No description provided for @moWzLocked.
  ///
  /// In en, this message translates to:
  /// **'set by the environment'**
  String get moWzLocked;

  /// No description provided for @moWzMoe.
  ///
  /// In en, this message translates to:
  /// **'{b} billion · mixture of experts'**
  String moWzMoe(String b);

  /// No description provided for @moWzMoreModels.
  ///
  /// In en, this message translates to:
  /// **'Other files and searches'**
  String get moWzMoreModels;

  /// No description provided for @moWzMoveHere.
  ///
  /// In en, this message translates to:
  /// **'Move them here'**
  String get moWzMoveHere;

  /// No description provided for @moWzMoveLead.
  ///
  /// In en, this message translates to:
  /// **'{kind}, {free} free. The models already downloaded are copied to {folder}; the model in use starts again afterwards.'**
  String moWzMoveLead(String folder, String free, String kind);

  /// No description provided for @moWzMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move the models to {disk}?'**
  String moWzMoveTitle(String disk);

  /// No description provided for @moWzNModels.
  ///
  /// In en, this message translates to:
  /// **'{n} models'**
  String moWzNModels(String n);

  /// No description provided for @moWzNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get moWzNone;

  /// No description provided for @moWzOfRamLong.
  ///
  /// In en, this message translates to:
  /// **'of RAM'**
  String get moWzOfRamLong;

  /// No description provided for @moWzOrchestrators.
  ///
  /// In en, this message translates to:
  /// **'Orchestrators'**
  String get moWzOrchestrators;

  /// No description provided for @moWzOrchestratorsSub.
  ///
  /// In en, this message translates to:
  /// **'the heads of the projects'**
  String get moWzOrchestratorsSub;

  /// No description provided for @moWzOrchestratorsText.
  ///
  /// In en, this message translates to:
  /// **'One per project: splits the work and hands it to the agents.'**
  String get moWzOrchestratorsText;

  /// No description provided for @moWzPickFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get moWzPickFolder;

  /// No description provided for @moWzPickModel.
  ///
  /// In en, this message translates to:
  /// **'Choose the model'**
  String get moWzPickModel;

  /// No description provided for @moWzPickRepo.
  ///
  /// In en, this message translates to:
  /// **'Choose a repository'**
  String get moWzPickRepo;

  /// No description provided for @moWzProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get moWzProvider;

  /// No description provided for @moWzRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get moWzRemove;

  /// No description provided for @moWzSlowTab.
  ///
  /// In en, this message translates to:
  /// **'Slow here'**
  String get moWzSlowTab;

  /// No description provided for @moWzSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'They work, but slowly'**
  String get moWzSlowTitle;

  /// No description provided for @moWzStateKey.
  ///
  /// In en, this message translates to:
  /// **'{name}: connected'**
  String moWzStateKey(String name);

  /// No description provided for @moWzStateKeys.
  ///
  /// In en, this message translates to:
  /// **'{n} keys connected'**
  String moWzStateKeys(String n);

  /// No description provided for @moWzStateLinked.
  ///
  /// In en, this message translates to:
  /// **'connected'**
  String get moWzStateLinked;

  /// No description provided for @moWzStateLocal.
  ///
  /// In en, this message translates to:
  /// **'{model}, in use'**
  String moWzStateLocal(String model);

  /// No description provided for @moWzStateLocalNext.
  ///
  /// In en, this message translates to:
  /// **'you choose it in the next step'**
  String get moWzStateLocalNext;

  /// No description provided for @moWzStateServer.
  ///
  /// In en, this message translates to:
  /// **'connected: {url}'**
  String moWzStateServer(String url);

  /// No description provided for @moWzStreamInfo1.
  ///
  /// In en, this message translates to:
  /// **'For models bigger than the graphics card, and for a much longer context.'**
  String get moWzStreamInfo1;

  /// No description provided for @moWzStreamInfo2.
  ///
  /// In en, this message translates to:
  /// **'The parts of the model used most stay in the card and in RAM; the rest is read from the SSD when needed. It works best with mixture-of-experts models; dense ones work, but slower.'**
  String get moWzStreamInfo2;

  /// No description provided for @moWzStreamInfo3.
  ///
  /// In en, this message translates to:
  /// **'At the first start Rasgeth measures this computer and keeps the fastest tuning. It needs an SSD with at least 20 GB free: a spinning disk is too slow.'**
  String get moWzStreamInfo3;

  /// No description provided for @moWzStreamOff.
  ///
  /// In en, this message translates to:
  /// **'Off: only the models that fit in the card and the RAM run.'**
  String get moWzStreamOff;

  /// No description provided for @moWzStreamOn.
  ///
  /// In en, this message translates to:
  /// **'On: models bigger than the card and the RAM read the rest from the SSD ({disk}) when needed. Slower, but they run.'**
  String moWzStreamOn(String disk);

  /// No description provided for @moWzSubscription.
  ///
  /// In en, this message translates to:
  /// **'I know that using a personal subscription (instead of an API key) in a third-party tool may not be allowed by the provider\'s terms.'**
  String get moWzSubscription;

  /// No description provided for @moWzTrying.
  ///
  /// In en, this message translates to:
  /// **'Trying the model…'**
  String get moWzTrying;

  /// No description provided for @moWzUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get moWzUnderstood;

  /// No description provided for @moWzUseFolder.
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get moWzUseFolder;

  /// No description provided for @moWzVram.
  ///
  /// In en, this message translates to:
  /// **'{gb} of video memory'**
  String moWzVram(String gb);

  /// No description provided for @moWzWhich.
  ///
  /// In en, this message translates to:
  /// **'Which one should I pick?'**
  String get moWzWhich;

  /// No description provided for @chUiAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get chUiAdvanced;

  /// No description provided for @moJob_engine.
  ///
  /// In en, this message translates to:
  /// **'Starting {model}'**
  String moJob_engine(String model);

  /// No description provided for @moJob_engine_load.
  ///
  /// In en, this message translates to:
  /// **'Loading {model}'**
  String moJob_engine_load(String model);

  /// No description provided for @moJob_error_bad_file.
  ///
  /// In en, this message translates to:
  /// **'This is not a model file of Hugging Face.'**
  String get moJob_error_bad_file;

  /// No description provided for @moJob_error_checksum.
  ///
  /// In en, this message translates to:
  /// **'The download arrived damaged (its fingerprint does not match): try again.'**
  String get moJob_error_checksum;

  /// No description provided for @moJob_error_engine_stopped.
  ///
  /// In en, this message translates to:
  /// **'The engine stopped by itself. The details below say why.'**
  String get moJob_error_engine_stopped;

  /// No description provided for @moJob_error_incomplete.
  ///
  /// In en, this message translates to:
  /// **'The download stopped before the end: press Go on to continue from where it stopped.'**
  String get moJob_error_incomplete;

  /// No description provided for @moJob_error_load_timeout.
  ///
  /// In en, this message translates to:
  /// **'The model did not load within 15 minutes. Try a smaller one.'**
  String get moJob_error_load_timeout;

  /// No description provided for @moJob_error_model_missing.
  ///
  /// In en, this message translates to:
  /// **'The model file is not in the folder any more. Download it again.'**
  String get moJob_error_model_missing;

  /// No description provided for @moJob_error_no_gpu.
  ///
  /// In en, this message translates to:
  /// **'The engine cannot see the graphics card. Update the card\'s drivers and restart the computer, or choose the processor under Advanced.'**
  String get moJob_error_no_gpu;

  /// No description provided for @moJob_error_out_of_memory.
  ///
  /// In en, this message translates to:
  /// **'There is not enough memory for this model. Choose a smaller model, or the same one in a lower quality.'**
  String get moJob_error_out_of_memory;

  /// No description provided for @moJob_model_download.
  ///
  /// In en, this message translates to:
  /// **'Downloading {model}'**
  String moJob_model_download(String model);

  /// No description provided for @moJob_speed_test.
  ///
  /// In en, this message translates to:
  /// **'Measuring {model}'**
  String moJob_speed_test(String model);

  /// No description provided for @moJob_step_draft.
  ///
  /// In en, this message translates to:
  /// **'With the small model'**
  String get moJob_step_draft;

  /// No description provided for @moJob_step_image.
  ///
  /// In en, this message translates to:
  /// **'Downloading the engine (only once)'**
  String get moJob_step_image;

  /// No description provided for @moJob_step_load.
  ///
  /// In en, this message translates to:
  /// **'Loading the model into memory'**
  String get moJob_step_load;

  /// No description provided for @moJob_step_ngram.
  ///
  /// In en, this message translates to:
  /// **'With the n-grams'**
  String get moJob_step_ngram;

  /// No description provided for @moJob_step_none.
  ///
  /// In en, this message translates to:
  /// **'The model alone'**
  String get moJob_step_none;

  /// No description provided for @moJob_step_preload.
  ///
  /// In en, this message translates to:
  /// **'Reading the model once, so the first message does not wait for the disk'**
  String get moJob_step_preload;

  /// No description provided for @moJob_step_start.
  ///
  /// In en, this message translates to:
  /// **'Starting the engine'**
  String get moJob_step_start;

  /// No description provided for @moJob_step_try.
  ///
  /// In en, this message translates to:
  /// **'Trying an answer'**
  String get moJob_step_try;

  /// No description provided for @moJob_step_tune.
  ///
  /// In en, this message translates to:
  /// **'Measuring this computer to pick the fastest setting'**
  String get moJob_step_tune;

  /// No description provided for @moLmQuality_good.
  ///
  /// In en, this message translates to:
  /// **'good quality'**
  String get moLmQuality_good;

  /// No description provided for @moLmQuality_high.
  ///
  /// In en, this message translates to:
  /// **'high quality'**
  String get moLmQuality_high;

  /// No description provided for @moLmQuality_reduced.
  ///
  /// In en, this message translates to:
  /// **'reduced quality, to fit'**
  String get moLmQuality_reduced;

  /// No description provided for @moLmScore_code.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get moLmScore_code;

  /// No description provided for @moLmScore_languages.
  ///
  /// In en, this message translates to:
  /// **'Other languages'**
  String get moLmScore_languages;

  /// No description provided for @moLmScore_smart.
  ///
  /// In en, this message translates to:
  /// **'Intelligence'**
  String get moLmScore_smart;

  /// No description provided for @moLmScore_speed.
  ///
  /// In en, this message translates to:
  /// **'Speed here'**
  String get moLmScore_speed;

  /// No description provided for @moLmScore_tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get moLmScore_tools;

  /// No description provided for @moLmSpeedMode_draft.
  ///
  /// In en, this message translates to:
  /// **'With the small model'**
  String get moLmSpeedMode_draft;

  /// No description provided for @moLmSpeedMode_ngram.
  ///
  /// In en, this message translates to:
  /// **'N-grams'**
  String get moLmSpeedMode_ngram;

  /// No description provided for @moLmSpeedMode_none.
  ///
  /// In en, this message translates to:
  /// **'Model alone'**
  String get moLmSpeedMode_none;

  /// No description provided for @chHubTelegram.
  ///
  /// In en, this message translates to:
  /// **'Demi-God on Telegram: the bot, its token and the accounts that talk to it'**
  String get chHubTelegram;

  /// No description provided for @chHubChats.
  ///
  /// In en, this message translates to:
  /// **'Demi-God on Discord, Slack, Signal, WhatsApp, Matrix, Teams and iMessage'**
  String get chHubChats;

  /// No description provided for @moHubModels.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions, API keys, your own server, the model on this computer and who uses which'**
  String get moHubModels;

  /// No description provided for @xtAddServer.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get xtAddServer;

  /// No description provided for @xtApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get xtApprove;

  /// No description provided for @xtArgs.
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get xtArgs;

  /// No description provided for @xtAxMagicDismiss.
  ///
  /// In en, this message translates to:
  /// **'Put it away'**
  String get xtAxMagicDismiss;

  /// No description provided for @xtAxMagicExamples.
  ///
  /// In en, this message translates to:
  /// **'Or start from an example'**
  String get xtAxMagicExamples;

  /// No description provided for @xtAxMagicGo.
  ///
  /// In en, this message translates to:
  /// **'Ask God'**
  String get xtAxMagicGo;

  /// No description provided for @xtAxMagicReject.
  ///
  /// In en, this message translates to:
  /// **'Not like this'**
  String get xtAxMagicReject;

  /// No description provided for @xtAxMagicSendNo.
  ///
  /// In en, this message translates to:
  /// **'Send to God'**
  String get xtAxMagicSendNo;

  /// No description provided for @xtAxMagicStarting.
  ///
  /// In en, this message translates to:
  /// **'Calling God…'**
  String get xtAxMagicStarting;

  /// No description provided for @xtAxMagicWhy.
  ///
  /// In en, this message translates to:
  /// **'What is wrong? God reads it and tries again'**
  String get xtAxMagicWhy;

  /// No description provided for @xtAxNeedMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get xtAxNeedMissing;

  /// No description provided for @xtAxNeedReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get xtAxNeedReady;

  /// No description provided for @xtAxNeedVault.
  ///
  /// In en, this message translates to:
  /// **'Add to the keychain'**
  String get xtAxNeedVault;

  /// No description provided for @xtBy.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get xtBy;

  /// No description provided for @xtCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get xtCancel;

  /// No description provided for @xtCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get xtCommand;

  /// No description provided for @xtCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get xtCopied;

  /// No description provided for @xtCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get xtCopy;

  /// No description provided for @xtCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get xtCreate;

  /// No description provided for @xtDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get xtDescription;

  /// No description provided for @xtExtAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get xtExtAdd;

  /// No description provided for @xtExtAddAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Add and connect'**
  String get xtExtAddAndConnect;

  /// No description provided for @xtExtAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get xtExtAdded;

  /// No description provided for @xtExtAppConsole.
  ///
  /// In en, this message translates to:
  /// **'Open {name}\'s developer page'**
  String xtExtAppConsole(String name);

  /// No description provided for @xtExtAppGuide.
  ///
  /// In en, this message translates to:
  /// **'Create your own app on {name} (once, about ten minutes)'**
  String xtExtAppGuide(String name);

  /// No description provided for @xtExtAskHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask God with a magic integration or extension, in your own words: God looks for a ready service in the catalog, or writes a new ability, tests it and asks you before installing anything.'**
  String get xtExtAskHelp;

  /// No description provided for @xtExtAskTitle.
  ///
  /// In en, this message translates to:
  /// **'What should your agents be able to do?'**
  String get xtExtAskTitle;

  /// No description provided for @xtExtAuth_app.
  ///
  /// In en, this message translates to:
  /// **'Your own app, with a guide'**
  String get xtExtAuth_app;

  /// No description provided for @xtExtAuth_header.
  ///
  /// In en, this message translates to:
  /// **'Needs a key'**
  String get xtExtAuth_header;

  /// No description provided for @xtExtAuth_none.
  ///
  /// In en, this message translates to:
  /// **'Nothing to sign in to'**
  String get xtExtAuth_none;

  /// No description provided for @xtExtAuth_oauth.
  ///
  /// In en, this message translates to:
  /// **'Sign in on its page'**
  String get xtExtAuth_oauth;

  /// No description provided for @xtExtBroken.
  ///
  /// In en, this message translates to:
  /// **'Not working'**
  String get xtExtBroken;

  /// No description provided for @xtExtBrokenHelp.
  ///
  /// In en, this message translates to:
  /// **'A service that does not work: check the key, or remove it and add it again. Hover over the label to see the error.'**
  String get xtExtBrokenHelp;

  /// No description provided for @xtExtCatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get xtExtCatAll;

  /// No description provided for @xtExtCat_cloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get xtExtCat_cloud;

  /// No description provided for @xtExtCat_code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get xtExtCat_code;

  /// No description provided for @xtExtCat_data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get xtExtCat_data;

  /// No description provided for @xtExtCat_design.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get xtExtCat_design;

  /// No description provided for @xtExtCat_docs.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get xtExtCat_docs;

  /// No description provided for @xtExtCat_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get xtExtCat_home;

  /// No description provided for @xtExtCat_web.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get xtExtCat_web;

  /// No description provided for @xtExtCat_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get xtExtCat_work;

  /// No description provided for @xtExtCatalog.
  ///
  /// In en, this message translates to:
  /// **'Services you can add'**
  String get xtExtCatalog;

  /// No description provided for @xtExtCatalogHelp.
  ///
  /// In en, this message translates to:
  /// **'Each one gives your agents new tools. The services\' own ones come first; the community ones are made by others.'**
  String get xtExtCatalogHelp;

  /// No description provided for @xtExtChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get xtExtChecking;

  /// No description provided for @xtExtClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID of your app'**
  String get xtExtClientId;

  /// No description provided for @xtExtClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client secret of your app'**
  String get xtExtClientSecret;

  /// No description provided for @xtExtClientSecretOptional.
  ///
  /// In en, this message translates to:
  /// **'Client secret of your app (if it has one)'**
  String get xtExtClientSecretOptional;

  /// No description provided for @xtExtCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get xtExtCommunity;

  /// No description provided for @xtExtConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get xtExtConnect;

  /// No description provided for @xtExtConnected.
  ///
  /// In en, this message translates to:
  /// **'Your services'**
  String get xtExtConnected;

  /// No description provided for @xtExtEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Everywhere'**
  String get xtExtEverywhere;

  /// No description provided for @xtExtGuide.
  ///
  /// In en, this message translates to:
  /// **'How to set up {name}'**
  String xtExtGuide(String name);

  /// No description provided for @xtExtKey.
  ///
  /// In en, this message translates to:
  /// **'{name} key'**
  String xtExtKey(String name);

  /// No description provided for @xtExtKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'It is kept in a private file on your server and never shown again, not even to the agents.'**
  String get xtExtKeyHelp;

  /// No description provided for @xtExtKeyWhere.
  ///
  /// In en, this message translates to:
  /// **'Where do I find the {name} key?'**
  String xtExtKeyWhere(String name);

  /// No description provided for @xtExtKindSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get xtExtKindSkill;

  /// No description provided for @xtExtKindTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get xtExtKindTool;

  /// No description provided for @xtExtManualOauth.
  ///
  /// In en, this message translates to:
  /// **'It signs in on its own page (OAuth)'**
  String get xtExtManualOauth;

  /// No description provided for @xtExtManualToken.
  ///
  /// In en, this message translates to:
  /// **'Key (optional, sent as Bearer)'**
  String get xtExtManualToken;

  /// No description provided for @xtExtMore.
  ///
  /// In en, this message translates to:
  /// **'More about it'**
  String get xtExtMore;

  /// No description provided for @xtExtNeedsLogin.
  ///
  /// In en, this message translates to:
  /// **'Needs you to sign in'**
  String get xtExtNeedsLogin;

  /// No description provided for @xtExtNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Ask God with the magic extension above: it can write what is missing.'**
  String get xtExtNothingFound;

  /// No description provided for @xtExtOauthHelp.
  ///
  /// In en, this message translates to:
  /// **'A new tab opens on {name}\'s page: sign in there and allow Rasgeth. Then come back here.'**
  String xtExtOauthHelp(String name);

  /// No description provided for @xtExtOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get xtExtOfficial;

  /// No description provided for @xtExtOnlyProject.
  ///
  /// In en, this message translates to:
  /// **'Only in {name}'**
  String xtExtOnlyProject(String name);

  /// No description provided for @xtExtProposals.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get xtExtProposals;

  /// No description provided for @xtExtProposalsHelp.
  ///
  /// In en, this message translates to:
  /// **'Abilities written by the agents and already tested: nothing is installed until you approve it.'**
  String get xtExtProposalsHelp;

  /// No description provided for @xtExtSearch.
  ///
  /// In en, this message translates to:
  /// **'Search a service'**
  String get xtExtSearch;

  /// No description provided for @xtExtServerUrl.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s address'**
  String xtExtServerUrl(String name);

  /// No description provided for @xtExtServerUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'As Rasgeth\'s server reaches it, for example on your home network.'**
  String get xtExtServerUrlHelp;

  /// No description provided for @xtExtSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills and tools'**
  String get xtExtSkills;

  /// No description provided for @xtExtSkillsHelp.
  ///
  /// In en, this message translates to:
  /// **'Abilities installed for your agents. Click one to read or change it.'**
  String get xtExtSkillsHelp;

  /// No description provided for @xtExtTransport.
  ///
  /// In en, this message translates to:
  /// **'How it runs'**
  String get xtExtTransport;

  /// No description provided for @xtExtTransportHttp.
  ///
  /// In en, this message translates to:
  /// **'Online (address)'**
  String get xtExtTransportHttp;

  /// No description provided for @xtExtTransportStdio.
  ///
  /// In en, this message translates to:
  /// **'On this server (command)'**
  String get xtExtTransportStdio;

  /// No description provided for @xtExtUnverified.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed on the service\'s own pages: if something does not match, its documentation is right.'**
  String get xtExtUnverified;

  /// No description provided for @xtExtUnverifiedShort.
  ///
  /// In en, this message translates to:
  /// **'to be checked'**
  String get xtExtUnverifiedShort;

  /// No description provided for @xtExtWhere.
  ///
  /// In en, this message translates to:
  /// **'Where it works'**
  String get xtExtWhere;

  /// No description provided for @xtExtWhereHelp.
  ///
  /// In en, this message translates to:
  /// **'Everywhere, or only for the agents of one project.'**
  String get xtExtWhereHelp;

  /// No description provided for @xtExtWorks.
  ///
  /// In en, this message translates to:
  /// **'Works · {n} tools'**
  String xtExtWorks(String n);

  /// No description provided for @xtExtensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get xtExtensions;

  /// No description provided for @xtFailedTests.
  ///
  /// In en, this message translates to:
  /// **'Failed its tests'**
  String get xtFailedTests;

  /// No description provided for @xtInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get xtInstructions;

  /// No description provided for @xtMediaGetKey.
  ///
  /// In en, this message translates to:
  /// **'Get a key'**
  String get xtMediaGetKey;

  /// No description provided for @xtMediaHasKey.
  ///
  /// In en, this message translates to:
  /// **'key already there'**
  String get xtMediaHasKey;

  /// No description provided for @xtMediaKey.
  ///
  /// In en, this message translates to:
  /// **'{name} key'**
  String xtMediaKey(String name);

  /// No description provided for @xtMediaKeyLinked.
  ///
  /// In en, this message translates to:
  /// **'{name} key linked'**
  String xtMediaKeyLinked(String name);

  /// No description provided for @xtMediaKeyStep1.
  ///
  /// In en, this message translates to:
  /// **'Open the {name} page where keys are made and sign in (or create an account).'**
  String xtMediaKeyStep1(String name);

  /// No description provided for @xtMediaKeyStep2.
  ///
  /// In en, this message translates to:
  /// **'Create a new key and copy it.'**
  String get xtMediaKeyStep2;

  /// No description provided for @xtMediaKeyStep3.
  ///
  /// In en, this message translates to:
  /// **'Paste it here and save:'**
  String get xtMediaKeyStep3;

  /// No description provided for @xtMediaNativeHelp.
  ///
  /// In en, this message translates to:
  /// **'Some models make pictures by themselves (ChatGPT through Codex): then theirs is used, and the picture reaches you in the chat as with ours. Off: always the provider chosen here. Asking for «your tool» in a conversation always uses ours. New conversations follow this.'**
  String get xtMediaNativeHelp;

  /// No description provided for @xtMediaNativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Use the model\'s own tool when it has one'**
  String get xtMediaNativeTitle;

  /// No description provided for @xtMediaNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'Needs its key'**
  String get xtMediaNeedsKey;

  /// No description provided for @xtMediaOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get xtMediaOff;

  /// No description provided for @xtMediaOtherProvider.
  ///
  /// In en, this message translates to:
  /// **'Choose another provider'**
  String get xtMediaOtherProvider;

  /// No description provided for @xtMediaPurpose.
  ///
  /// In en, this message translates to:
  /// **'Who makes pictures, videos, voices, music and sound effects when an agent is asked for one (the tools image_generation, video_generation and audio_generation). Choose a provider and a model for each, and paste its key: a key you already gave for the chat (OpenAI, Gemini, xAI) works here too. They are paid by the provider for what you make.'**
  String get xtMediaPurpose;

  /// No description provided for @xtMediaStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Who makes it'**
  String get xtMediaStep1;

  /// No description provided for @xtMediaStep2.
  ///
  /// In en, this message translates to:
  /// **'2. The {name} key'**
  String xtMediaStep2(String name);

  /// No description provided for @xtMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Default extensions'**
  String get xtMediaTitle;

  /// No description provided for @xtMediaTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get xtMediaTurnOff;

  /// No description provided for @xtMediaVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get xtMediaVoice;

  /// No description provided for @xtMediaVoiceFirst.
  ///
  /// In en, this message translates to:
  /// **'The account\'s first one'**
  String get xtMediaVoiceFirst;

  /// No description provided for @xtMedia_image.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get xtMedia_image;

  /// No description provided for @xtMedia_image_help.
  ///
  /// In en, this message translates to:
  /// **'Drawings, photos, illustrations, logos from a description (or from a picture).'**
  String get xtMedia_image_help;

  /// No description provided for @xtMedia_music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get xtMedia_music;

  /// No description provided for @xtMedia_music_help.
  ///
  /// In en, this message translates to:
  /// **'Songs and pieces from a description, with or without singing.'**
  String get xtMedia_music_help;

  /// No description provided for @xtMedia_sound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get xtMedia_sound;

  /// No description provided for @xtMedia_sound_help.
  ///
  /// In en, this message translates to:
  /// **'Short sounds from a description: a door, rain, a crowd, an engine.'**
  String get xtMedia_sound_help;

  /// No description provided for @xtMedia_speech.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get xtMedia_speech;

  /// No description provided for @xtMedia_speech_help.
  ///
  /// In en, this message translates to:
  /// **'A text read aloud, with the voice you choose.'**
  String get xtMedia_speech_help;

  /// No description provided for @xtMedia_video.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get xtMedia_video;

  /// No description provided for @xtMedia_video_help.
  ///
  /// In en, this message translates to:
  /// **'Short clips from a description or from a first frame. They take minutes and cost more. (OpenAI closed Sora in September 2026.)'**
  String get xtMedia_video_help;

  /// No description provided for @xtModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get xtModel;

  /// No description provided for @xtMxApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve and install'**
  String get xtMxApprove;

  /// No description provided for @xtMxArgs.
  ///
  /// In en, this message translates to:
  /// **'Arguments:'**
  String get xtMxArgs;

  /// No description provided for @xtMxBadgeApprove.
  ///
  /// In en, this message translates to:
  /// **'To install'**
  String get xtMxBadgeApprove;

  /// No description provided for @xtMxBadgeInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get xtMxBadgeInstalled;

  /// No description provided for @xtMxBadgeMissing.
  ///
  /// In en, this message translates to:
  /// **'Something missing'**
  String get xtMxBadgeMissing;

  /// No description provided for @xtMxBuilding.
  ///
  /// In en, this message translates to:
  /// **'God is building it with you: answer its questions in the conversation.'**
  String get xtMxBuilding;

  /// No description provided for @xtMxChange.
  ///
  /// In en, this message translates to:
  /// **'Change it'**
  String get xtMxChange;

  /// No description provided for @xtMxChangeGo.
  ///
  /// In en, this message translates to:
  /// **'Ask God'**
  String get xtMxChangeGo;

  /// No description provided for @xtMxChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'What should change? God proposes it again and you install it as before.'**
  String get xtMxChangeLabel;

  /// No description provided for @xtMxChanging.
  ///
  /// In en, this message translates to:
  /// **'God is changing it with you; what is installed keeps working until you approve the new version.'**
  String get xtMxChanging;

  /// No description provided for @xtMxCheckHost.
  ///
  /// In en, this message translates to:
  /// **'The address {what}'**
  String xtMxCheckHost(String what);

  /// No description provided for @xtMxCheckKey.
  ///
  /// In en, this message translates to:
  /// **'The key for {what}'**
  String xtMxCheckKey(String what);

  /// No description provided for @xtMxCheckKeyUndeclared.
  ///
  /// In en, this message translates to:
  /// **'The key {what}, used by the code but not declared'**
  String xtMxCheckKeyUndeclared(String what);

  /// No description provided for @xtMxCheckTest.
  ///
  /// In en, this message translates to:
  /// **'The test of {what}'**
  String xtMxCheckTest(String what);

  /// No description provided for @xtMxCode.
  ///
  /// In en, this message translates to:
  /// **'Read the code'**
  String get xtMxCode;

  /// No description provided for @xtMxDone.
  ///
  /// In en, this message translates to:
  /// **'Installed: every agent has these tools from its next conversation.'**
  String get xtMxDone;

  /// No description provided for @xtMxExtension.
  ///
  /// In en, this message translates to:
  /// **'Magic extension'**
  String get xtMxExtension;

  /// No description provided for @xtMxExtensionAsk.
  ///
  /// In en, this message translates to:
  /// **'What should the agents be able to do?'**
  String get xtMxExtensionAsk;

  /// No description provided for @xtMxExtensionEx1.
  ///
  /// In en, this message translates to:
  /// **'Turn a CSV into a chart and tell me the totals'**
  String get xtMxExtensionEx1;

  /// No description provided for @xtMxExtensionEx2.
  ///
  /// In en, this message translates to:
  /// **'Check that an Italian VAT number and tax code are valid'**
  String get xtMxExtensionEx2;

  /// No description provided for @xtMxExtensionEx3.
  ///
  /// In en, this message translates to:
  /// **'A skill for writing my weekly report the way I like it'**
  String get xtMxExtensionEx3;

  /// No description provided for @xtMxExtensionLead.
  ///
  /// In en, this message translates to:
  /// **'Tell God what the agents should be able to do. God asks, writes tools and skills with their tests and tries them in a closed sandbox: you see the result and install it with one button.'**
  String get xtMxExtensionLead;

  /// No description provided for @xtMxExtensionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: turn a CSV into a chart and tell me the totals'**
  String get xtMxExtensionPlaceholder;

  /// No description provided for @xtMxExtensionTile.
  ///
  /// In en, this message translates to:
  /// **'New abilities for the agents, of any kind: God writes the tools and skills, tests them apart and you install them.'**
  String get xtMxExtensionTile;

  /// No description provided for @xtMxGiveKey.
  ///
  /// In en, this message translates to:
  /// **'Give it to these tools'**
  String get xtMxGiveKey;

  /// No description provided for @xtMxGiveKeyText.
  ///
  /// In en, this message translates to:
  /// **'Only these tools will receive it, through the proxy, and only towards {hosts}: {tools}.'**
  String xtMxGiveKeyText(String hosts, String tools);

  /// No description provided for @xtMxGiveKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Give {what} to this package?'**
  String xtMxGiveKeyTitle(String what);

  /// No description provided for @xtMxIntegration.
  ///
  /// In en, this message translates to:
  /// **'Magic integration'**
  String get xtMxIntegration;

  /// No description provided for @xtMxIntegrationAsk.
  ///
  /// In en, this message translates to:
  /// **'Which service, and what for?'**
  String get xtMxIntegrationAsk;

  /// No description provided for @xtMxIntegrationEx1.
  ///
  /// In en, this message translates to:
  /// **'Connect me to Notion: search my pages and create new ones'**
  String get xtMxIntegrationEx1;

  /// No description provided for @xtMxIntegrationEx2.
  ///
  /// In en, this message translates to:
  /// **'Connect me to my management software\'s API (invoices and customers)'**
  String get xtMxIntegrationEx2;

  /// No description provided for @xtMxIntegrationEx3.
  ///
  /// In en, this message translates to:
  /// **'Read my Todoist tasks and mark them done'**
  String get xtMxIntegrationEx3;

  /// No description provided for @xtMxIntegrationLead.
  ///
  /// In en, this message translates to:
  /// **'Tell God which service and what the agents should do with it. God asks what it needs, writes the connector with its tests and tries it in a closed sandbox: you see the result and install it with one button.'**
  String get xtMxIntegrationLead;

  /// No description provided for @xtMxIntegrationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: connect me to Notion so the agents can search my pages and add notes'**
  String get xtMxIntegrationPlaceholder;

  /// No description provided for @xtMxIntegrationTile.
  ///
  /// In en, this message translates to:
  /// **'Connect Rasgeth to a service through its API (Notion, your management software, a bank…): God writes the connector, tests it apart and you install it.'**
  String get xtMxIntegrationTile;

  /// No description provided for @xtMxKeyHosts.
  ///
  /// In en, this message translates to:
  /// **'It may go only to:'**
  String get xtMxKeyHosts;

  /// No description provided for @xtMxKeyLead.
  ///
  /// In en, this message translates to:
  /// **'Paste the key here: it goes straight into your keychain, encrypted. Nobody reads it, God included; the tools receive it only through the proxy.'**
  String get xtMxKeyLead;

  /// No description provided for @xtMxKeyName.
  ///
  /// In en, this message translates to:
  /// **'Name in the keychain:'**
  String get xtMxKeyName;

  /// No description provided for @xtMxKeyOnly.
  ///
  /// In en, this message translates to:
  /// **'Used only by this package\'s tools; you can change it in Settings > Keychain.'**
  String get xtMxKeyOnly;

  /// No description provided for @xtMxKeySave.
  ///
  /// In en, this message translates to:
  /// **'Save in the keychain'**
  String get xtMxKeySave;

  /// No description provided for @xtMxKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Key for {service}'**
  String xtMxKeyTitle(String service);

  /// No description provided for @xtMxKeyValue.
  ///
  /// In en, this message translates to:
  /// **'The key'**
  String get xtMxKeyValue;

  /// No description provided for @xtMxKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get xtMxKeys;

  /// No description provided for @xtMxListLead.
  ///
  /// In en, this message translates to:
  /// **'Built with God: open one to go on with the conversation, install it, change it or remove it.'**
  String get xtMxListLead;

  /// No description provided for @xtMxListTitle.
  ///
  /// In en, this message translates to:
  /// **'Magic integrations and extensions'**
  String get xtMxListTitle;

  /// No description provided for @xtMxMissing.
  ///
  /// In en, this message translates to:
  /// **'Before you can install it, this is missing:'**
  String get xtMxMissing;

  /// No description provided for @xtMxParts.
  ///
  /// In en, this message translates to:
  /// **'What it adds'**
  String get xtMxParts;

  /// No description provided for @xtMxPromise1.
  ///
  /// In en, this message translates to:
  /// **'Nothing is installed without your yes.'**
  String get xtMxPromise1;

  /// No description provided for @xtMxPromise2.
  ///
  /// In en, this message translates to:
  /// **'Every part is tested in a closed sandbox that reaches only the services it declares.'**
  String get xtMxPromise2;

  /// No description provided for @xtMxPromise3.
  ///
  /// In en, this message translates to:
  /// **'Keys go into your keychain from the window, never in the chat.'**
  String get xtMxPromise3;

  /// No description provided for @xtMxProposal.
  ///
  /// In en, this message translates to:
  /// **'God\'s package'**
  String get xtMxProposal;

  /// No description provided for @xtMxReaches.
  ///
  /// In en, this message translates to:
  /// **'It reaches only'**
  String get xtMxReaches;

  /// No description provided for @xtMxReachesNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing: it works without the network.'**
  String get xtMxReachesNothing;

  /// No description provided for @xtMxRetest.
  ///
  /// In en, this message translates to:
  /// **'Test again'**
  String get xtMxRetest;

  /// No description provided for @xtMxState_building.
  ///
  /// In en, this message translates to:
  /// **'Being built'**
  String get xtMxState_building;

  /// No description provided for @xtMxState_dismissed.
  ///
  /// In en, this message translates to:
  /// **'Put away'**
  String get xtMxState_dismissed;

  /// No description provided for @xtMxState_done.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get xtMxState_done;

  /// No description provided for @xtMxState_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready: it waits for you'**
  String get xtMxState_ready;

  /// No description provided for @xtMxState_testing.
  ///
  /// In en, this message translates to:
  /// **'Tests running'**
  String get xtMxState_testing;

  /// No description provided for @xtMxStep1.
  ///
  /// In en, this message translates to:
  /// **'You say what you want'**
  String get xtMxStep1;

  /// No description provided for @xtMxStep2.
  ///
  /// In en, this message translates to:
  /// **'God writes and tests it'**
  String get xtMxStep2;

  /// No description provided for @xtMxStep3.
  ///
  /// In en, this message translates to:
  /// **'You install it'**
  String get xtMxStep3;

  /// No description provided for @xtMxTesting.
  ///
  /// In en, this message translates to:
  /// **'The tests are running again in the sandbox…'**
  String get xtMxTesting;

  /// No description provided for @xtMxUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get xtMxUninstall;

  /// No description provided for @xtMxUninstallText.
  ///
  /// In en, this message translates to:
  /// **'These go away: {what}. The keys added for it leave the keychain too.'**
  String xtMxUninstallText(String what);

  /// No description provided for @xtMxUninstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall {what}?'**
  String xtMxUninstallTitle(String what);

  /// No description provided for @xtMxWhyGod.
  ///
  /// In en, this message translates to:
  /// **'God has to fix it: tell it in the conversation if it does not.'**
  String get xtMxWhyGod;

  /// No description provided for @xtMxWhyHost.
  ///
  /// In en, this message translates to:
  /// **'The code reaches it but does not declare it: God has to declare it or remove it.'**
  String get xtMxWhyHost;

  /// No description provided for @xtMxWhyMissing.
  ///
  /// In en, this message translates to:
  /// **'Not in your keychain yet: add it here, it goes to these tools only.'**
  String get xtMxWhyMissing;

  /// No description provided for @xtMxWhyNotGiven.
  ///
  /// In en, this message translates to:
  /// **'It is in your keychain, but not given to these tools (or not towards these addresses).'**
  String get xtMxWhyNotGiven;

  /// No description provided for @xtMxWhyTest.
  ///
  /// In en, this message translates to:
  /// **'It failed in the sandbox: God reads why and fixes it; with a key added, the tests run again.'**
  String get xtMxWhyTest;

  /// No description provided for @xtName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get xtName;

  /// No description provided for @xtNewSkill.
  ///
  /// In en, this message translates to:
  /// **'New skill'**
  String get xtNewSkill;

  /// No description provided for @xtNoProposals.
  ///
  /// In en, this message translates to:
  /// **'No proposals.'**
  String get xtNoProposals;

  /// No description provided for @xtOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get xtOpen;

  /// No description provided for @xtProposals.
  ///
  /// In en, this message translates to:
  /// **'Proposals waiting for you'**
  String get xtProposals;

  /// No description provided for @xtReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get xtReject;

  /// No description provided for @xtRemotePasswordChange.
  ///
  /// In en, this message translates to:
  /// **'Change it'**
  String get xtRemotePasswordChange;

  /// No description provided for @xtRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get xtRemove;

  /// No description provided for @xtSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get xtSave;

  /// No description provided for @xtScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get xtScope;

  /// No description provided for @xtScopePlatform.
  ///
  /// In en, this message translates to:
  /// **'platform'**
  String get xtScopePlatform;

  /// No description provided for @xtSkillDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get xtSkillDownload;

  /// No description provided for @xtSkillDownloadHelp.
  ///
  /// In en, this message translates to:
  /// **'Download this skill as a .zip, to share it'**
  String get xtSkillDownloadHelp;

  /// No description provided for @xtSkillImport.
  ///
  /// In en, this message translates to:
  /// **'Import a skill'**
  String get xtSkillImport;

  /// No description provided for @xtSkillImportFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a .zip file'**
  String get xtSkillImportFile;

  /// No description provided for @xtSkillImportHelp.
  ///
  /// In en, this message translates to:
  /// **'A skill\'s folder as a .zip (the agentskills.io format), from another Rasgeth or another tool.'**
  String get xtSkillImportHelp;

  /// No description provided for @xtSkillImportWhere.
  ///
  /// In en, this message translates to:
  /// **'Install in'**
  String get xtSkillImportWhere;

  /// No description provided for @xtSkillImported.
  ///
  /// In en, this message translates to:
  /// **'Skill \"{name}\" imported.'**
  String xtSkillImported(String name);

  /// No description provided for @xtSkillReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'A skill with this name already exists there. Replace it?'**
  String get xtSkillReplaceConfirm;

  /// No description provided for @xtSvApprovedAuto.
  ///
  /// In en, this message translates to:
  /// **'installed by itself (your choice in Safety)'**
  String get xtSvApprovedAuto;

  /// No description provided for @xtSvApprovedYou.
  ///
  /// In en, this message translates to:
  /// **'approved by you'**
  String get xtSvApprovedYou;

  /// No description provided for @xtSvBy.
  ///
  /// In en, this message translates to:
  /// **'by {who}'**
  String xtSvBy(String who);

  /// No description provided for @xtSvCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare with the one in use'**
  String get xtSvCompare;

  /// No description provided for @xtSvCompareFull.
  ///
  /// In en, this message translates to:
  /// **'Compare: every difference'**
  String get xtSvCompareFull;

  /// No description provided for @xtSvCurrent.
  ///
  /// In en, this message translates to:
  /// **'in use'**
  String get xtSvCurrent;

  /// No description provided for @xtSvHideCompare.
  ///
  /// In en, this message translates to:
  /// **'Hide the comparison'**
  String get xtSvHideCompare;

  /// No description provided for @xtSvHow_baseline.
  ///
  /// In en, this message translates to:
  /// **'As it was before the history began'**
  String get xtSvHow_baseline;

  /// No description provided for @xtSvHow_edited.
  ///
  /// In en, this message translates to:
  /// **'Changed by hand'**
  String get xtSvHow_edited;

  /// No description provided for @xtSvHow_import.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get xtSvHow_import;

  /// No description provided for @xtSvHow_install.
  ///
  /// In en, this message translates to:
  /// **'First version'**
  String get xtSvHow_install;

  /// No description provided for @xtSvHow_rollback.
  ///
  /// In en, this message translates to:
  /// **'Back to version {n}'**
  String xtSvHow_rollback(String n);

  /// No description provided for @xtSvHow_update.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get xtSvHow_update;

  /// No description provided for @xtSvLead.
  ///
  /// In en, this message translates to:
  /// **'Every change of this skill is kept: who wrote it, why and when. Agents use the newest from their next conversation.'**
  String get xtSvLead;

  /// No description provided for @xtSvLineTitle.
  ///
  /// In en, this message translates to:
  /// **'What changed and why'**
  String get xtSvLineTitle;

  /// No description provided for @xtSvNextSession.
  ///
  /// In en, this message translates to:
  /// **'Once installed, agents use it from their next conversation; the ones already talking keep the version they started with.'**
  String get xtSvNextSession;

  /// No description provided for @xtSvNone.
  ///
  /// In en, this message translates to:
  /// **'No versions yet.'**
  String get xtSvNone;

  /// No description provided for @xtSvNotRestorable.
  ///
  /// In en, this message translates to:
  /// **'Too large to keep: it cannot come back.'**
  String get xtSvNotRestorable;

  /// No description provided for @xtSvRollback.
  ///
  /// In en, this message translates to:
  /// **'Go back to version {n}'**
  String xtSvRollback(String n);

  /// No description provided for @xtSvRollbackConfirm.
  ///
  /// In en, this message translates to:
  /// **'Its files replace those of «{name}» in use, as a new version: nothing is lost and you can come back here. Agents get it from their next conversation.'**
  String xtSvRollbackConfirm(String name);

  /// No description provided for @xtSvRollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Go back to version {n}?'**
  String xtSvRollbackTitle(String n);

  /// No description provided for @xtSvRolledBack.
  ///
  /// In en, this message translates to:
  /// **'Back to version {n}: it is version {v} now.'**
  String xtSvRolledBack(String n, String v);

  /// No description provided for @xtSvTitle.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get xtSvTitle;

  /// No description provided for @xtSvUnknown.
  ///
  /// In en, this message translates to:
  /// **'author unknown'**
  String get xtSvUnknown;

  /// No description provided for @xtSvVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {n}'**
  String xtSvVersion(String n);

  /// No description provided for @xtSvWhy.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get xtSvWhy;

  /// No description provided for @xtSvYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get xtSvYou;

  /// No description provided for @xtUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get xtUrl;

  /// No description provided for @xtWzDoneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get xtWzDoneBtn;

  /// No description provided for @xtXwAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get xtXwAddress;

  /// No description provided for @xtXwAuthor.
  ///
  /// In en, this message translates to:
  /// **'Proposed by'**
  String get xtXwAuthor;

  /// No description provided for @xtXwConnectedLead.
  ///
  /// In en, this message translates to:
  /// **'The lit ones work. Open one to sign in again or remove it.'**
  String get xtXwConnectedLead;

  /// No description provided for @xtXwFailedLead.
  ///
  /// In en, this message translates to:
  /// **'Proposals of the agents whose tests did not pass: they were never installed.'**
  String get xtXwFailedLead;

  /// No description provided for @xtXwFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get xtXwFile;

  /// No description provided for @xtXwImportText.
  ///
  /// In en, this message translates to:
  /// **'A .zip someone shared, into everything or one project.'**
  String get xtXwImportText;

  /// No description provided for @xtXwKeptFiles.
  ///
  /// In en, this message translates to:
  /// **'Files of the skill it keeps: {files}'**
  String xtXwKeptFiles(String files);

  /// No description provided for @xtXwKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get xtXwKind;

  /// No description provided for @xtXwNewSkillText.
  ///
  /// In en, this message translates to:
  /// **'Instructions you write for your agents; it installs right away.'**
  String get xtXwNewSkillText;

  /// No description provided for @xtXwOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open the file'**
  String get xtXwOpenFile;

  /// No description provided for @xtXwOwnLead.
  ///
  /// In en, this message translates to:
  /// **'For experts: a skill someone shared with you, one you write, a server not in the catalog.'**
  String get xtXwOwnLead;

  /// No description provided for @xtXwOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'Made by hand'**
  String get xtXwOwnTitle;

  /// No description provided for @xtXwPrevious.
  ///
  /// In en, this message translates to:
  /// **'Now installed'**
  String get xtXwPrevious;

  /// No description provided for @xtXwScripts.
  ///
  /// In en, this message translates to:
  /// **'It has scripts ({files}): approve only if you trust what they do.'**
  String xtXwScripts(String files);

  /// No description provided for @xtXwServerText.
  ///
  /// In en, this message translates to:
  /// **'An MCP server by address or by command, with its key if it needs one.'**
  String get xtXwServerText;

  /// No description provided for @xtXwSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get xtXwSignIn;

  /// No description provided for @xtXwSkillNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, digits and dashes, such as weekly-report.'**
  String get xtXwSkillNameHelp;

  /// No description provided for @xtXwSource.
  ///
  /// In en, this message translates to:
  /// **'Made by'**
  String get xtXwSource;

  /// No description provided for @xtXwState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get xtXwState;

  /// No description provided for @xtXwSummary.
  ///
  /// In en, this message translates to:
  /// **'Why it came'**
  String get xtXwSummary;

  /// No description provided for @xtXwTests.
  ///
  /// In en, this message translates to:
  /// **'Tests in a throwaway sandbox'**
  String get xtXwTests;

  /// No description provided for @xtXwTestsFailed.
  ///
  /// In en, this message translates to:
  /// **'tests failed'**
  String get xtXwTestsFailed;

  /// No description provided for @xtXwUpdates.
  ///
  /// In en, this message translates to:
  /// **'Update of an installed skill'**
  String get xtXwUpdates;

  /// No description provided for @xtXwWaitsYou.
  ///
  /// In en, this message translates to:
  /// **'waits for your yes'**
  String get xtXwWaitsYou;

  /// No description provided for @xtYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get xtYou;

  /// No description provided for @vkCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vkCancel;

  /// No description provided for @vkClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get vkClose;

  /// No description provided for @vkDvSection.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get vkDvSection;

  /// No description provided for @vkKcAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get vkKcAdd;

  /// No description provided for @vkKcAddSub.
  ///
  /// In en, this message translates to:
  /// **'Its value is sealed as soon as you save'**
  String get vkKcAddSub;

  /// No description provided for @vkKcAddTitle.
  ///
  /// In en, this message translates to:
  /// **'A new credential'**
  String get vkKcAddTitle;

  /// No description provided for @vkKcAgentsHow.
  ///
  /// In en, this message translates to:
  /// **'Agents use a credential with use_credential, or through the tools you bind to it below each credential.'**
  String get vkKcAgentsHow;

  /// No description provided for @vkKcAgentsHowNoProxy.
  ///
  /// In en, this message translates to:
  /// **'Agents use a credential with use_credential.'**
  String get vkKcAgentsHowNoProxy;

  /// No description provided for @vkKcAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vkKcAll;

  /// No description provided for @vkKcAllAgents.
  ///
  /// In en, this message translates to:
  /// **'Every agent'**
  String get vkKcAllAgents;

  /// No description provided for @vkKcAllAgentsHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: only the agents you choose.'**
  String get vkKcAllAgentsHelp;

  /// No description provided for @vkKcAllCats.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vkKcAllCats;

  /// No description provided for @vkKcAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask me before it is used'**
  String get vkKcAsk;

  /// No description provided for @vkKcAsk_always.
  ///
  /// In en, this message translates to:
  /// **'Every time'**
  String get vkKcAsk_always;

  /// No description provided for @vkKcAsk_never.
  ///
  /// In en, this message translates to:
  /// **'Never: I trust the rules above'**
  String get vkKcAsk_never;

  /// No description provided for @vkKcAsk_session.
  ///
  /// In en, this message translates to:
  /// **'The first time in each conversation'**
  String get vkKcAsk_session;

  /// No description provided for @vkKcAutos.
  ///
  /// In en, this message translates to:
  /// **'Automations that may use it'**
  String get vkKcAutos;

  /// No description provided for @vkKcBrAddress.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth\'s address'**
  String get vkKcBrAddress;

  /// No description provided for @vkKcBrCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get vkKcBrCode;

  /// No description provided for @vkKcBrCodeLead.
  ///
  /// In en, this message translates to:
  /// **'In the extension (the key in the browser\'s bar) write this address and this code. The code works for ten minutes and for one browser.'**
  String get vkKcBrCodeLead;

  /// No description provided for @vkKcBrCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get vkKcBrCopied;

  /// No description provided for @vkKcBrCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get vkKcBrCopy;

  /// No description provided for @vkKcBrDone.
  ///
  /// In en, this message translates to:
  /// **'Linked: «{name}». You can close this window.'**
  String vkKcBrDone(String name);

  /// No description provided for @vkKcBrDownload.
  ///
  /// In en, this message translates to:
  /// **'Download the extension'**
  String get vkKcBrDownload;

  /// No description provided for @vkKcBrDownloadFirefox.
  ///
  /// In en, this message translates to:
  /// **'Download the version for Firefox'**
  String get vkKcBrDownloadFirefox;

  /// No description provided for @vkKcBrExpired.
  ///
  /// In en, this message translates to:
  /// **'That code expired: make a new one.'**
  String get vkKcBrExpired;

  /// No description provided for @vkKcBrExpires.
  ///
  /// In en, this message translates to:
  /// **'Valid until {time}'**
  String vkKcBrExpires(String time);

  /// No description provided for @vkKcBrHowChromium.
  ///
  /// In en, this message translates to:
  /// **'Unzip it into a folder you will keep. Open {page}, switch on «Developer mode», press «Load unpacked» and choose the folder. You can also drag the zip onto that page.'**
  String vkKcBrHowChromium(String page);

  /// No description provided for @vkKcBrHowFirefox.
  ///
  /// In en, this message translates to:
  /// **'Open about:debugging#/runtime/this-firefox, press «Load Temporary Add-on…» and choose the zip. Firefox keeps it until it closes: to keep it for good it must be signed by Mozilla.'**
  String get vkKcBrHowFirefox;

  /// No description provided for @vkKcBrHowOpera.
  ///
  /// In en, this message translates to:
  /// **'Unzip it into a folder you will keep. Open opera://extensions, switch on «Developer mode» at the top right, press «Load unpacked» and choose the folder. You can also drag the zip onto that page.'**
  String get vkKcBrHowOpera;

  /// No description provided for @vkKcBrHttpNote.
  ///
  /// In en, this message translates to:
  /// **'This address starts with http: the extension accepts it only at home (this computer or the local network). From outside use remote access, with https.'**
  String get vkKcBrHttpNote;

  /// No description provided for @vkKcBrLead.
  ///
  /// In en, this message translates to:
  /// **'The keychain\'s extension fills sign-ins in Opera, Chrome, Edge, Brave and Firefox, only on the site each password belongs to, and saves the new ones here. Every use shows in the list above.'**
  String get vkKcBrLead;

  /// No description provided for @vkKcBrLink.
  ///
  /// In en, this message translates to:
  /// **'Link a browser'**
  String get vkKcBrLink;

  /// No description provided for @vkKcBrLinked.
  ///
  /// In en, this message translates to:
  /// **'linked {when}'**
  String vkKcBrLinked(String when);

  /// No description provided for @vkKcBrMakeCode.
  ///
  /// In en, this message translates to:
  /// **'Make a code'**
  String get vkKcBrMakeCode;

  /// No description provided for @vkKcBrNever.
  ///
  /// In en, this message translates to:
  /// **'not used yet'**
  String get vkKcBrNever;

  /// No description provided for @vkKcBrNone.
  ///
  /// In en, this message translates to:
  /// **'No browser linked yet.'**
  String get vkKcBrNone;

  /// No description provided for @vkKcBrSeen.
  ///
  /// In en, this message translates to:
  /// **'last seen {when}'**
  String vkKcBrSeen(String when);

  /// No description provided for @vkKcBrStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Install the extension'**
  String get vkKcBrStep1;

  /// No description provided for @vkKcBrStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Link it with a code'**
  String get vkKcBrStep2;

  /// No description provided for @vkKcBrStore.
  ///
  /// In en, this message translates to:
  /// **'Later also in the Chrome Web Store: one click to install, and it updates itself.'**
  String get vkKcBrStore;

  /// No description provided for @vkKcBrTitle.
  ///
  /// In en, this message translates to:
  /// **'In your browser'**
  String get vkKcBrTitle;

  /// No description provided for @vkKcBrUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get vkKcBrUnlink;

  /// No description provided for @vkKcBrUnlinkQ.
  ///
  /// In en, this message translates to:
  /// **'Unlink {name}?'**
  String vkKcBrUnlinkQ(String name);

  /// No description provided for @vkKcBrUnlinkText.
  ///
  /// In en, this message translates to:
  /// **'The browser stops reaching the keychain at once. The passwords stay here; to use it again, link it with a new code.'**
  String get vkKcBrUnlinkText;

  /// No description provided for @vkKcBrWhich.
  ///
  /// In en, this message translates to:
  /// **'Your browser'**
  String get vkKcBrWhich;

  /// No description provided for @vkKcBrWinLead.
  ///
  /// In en, this message translates to:
  /// **'The keychain\'s extension fills sign-ins in Opera, Chrome, Edge, Brave and Firefox, only on the site each password belongs to, and saves the new ones here.'**
  String get vkKcBrWinLead;

  /// No description provided for @vkKcBrWinTitle.
  ///
  /// In en, this message translates to:
  /// **'Link a browser'**
  String get vkKcBrWinTitle;

  /// No description provided for @vkKcCat_api.
  ///
  /// In en, this message translates to:
  /// **'API keys'**
  String get vkKcCat_api;

  /// No description provided for @vkKcCat_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get vkKcCat_bank;

  /// No description provided for @vkKcCat_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get vkKcCat_email;

  /// No description provided for @vkKcCat_login.
  ///
  /// In en, this message translates to:
  /// **'Logins'**
  String get vkKcCat_login;

  /// No description provided for @vkKcCat_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vkKcCat_other;

  /// No description provided for @vkKcCat_server.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get vkKcCat_server;

  /// No description provided for @vkKcCategory.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get vkKcCategory;

  /// No description provided for @vkKcChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get vkKcChange;

  /// No description provided for @vkKcClosed.
  ///
  /// In en, this message translates to:
  /// **'The keychain is closed'**
  String get vkKcClosed;

  /// No description provided for @vkKcClosedKeys.
  ///
  /// In en, this message translates to:
  /// **'Until it opens, the keys you gave Rasgeth stay where they were (secrets.json and the private files), and nothing is deleted.'**
  String get vkKcClosedKeys;

  /// No description provided for @vkKcCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get vkKcCopied;

  /// No description provided for @vkKcCopiedNote.
  ///
  /// In en, this message translates to:
  /// **'Copied: it leaves the clipboard in 30 seconds.'**
  String get vkKcCopiedNote;

  /// No description provided for @vkKcCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get vkKcCopy;

  /// No description provided for @vkKcEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Add the key of a service an agent should use, or import your passwords from another manager.'**
  String get vkKcEmpty;

  /// No description provided for @vkKcExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get vkKcExpired;

  /// No description provided for @vkKcExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires on'**
  String get vkKcExpires;

  /// No description provided for @vkKcExpiresHelp.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth reminds you a month before.'**
  String get vkKcExpiresHelp;

  /// No description provided for @vkKcExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {n} days'**
  String vkKcExpiresIn(String n);

  /// No description provided for @vkKcExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get vkKcExpiresToday;

  /// No description provided for @vkKcExpiringLead.
  ///
  /// In en, this message translates to:
  /// **'To renew soon:'**
  String get vkKcExpiringLead;

  /// No description provided for @vkKcExport.
  ///
  /// In en, this message translates to:
  /// **'Export sealed'**
  String get vkKcExport;

  /// No description provided for @vkKcExportGo.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get vkKcExportGo;

  /// No description provided for @vkKcExportLead.
  ///
  /// In en, this message translates to:
  /// **'A file with every credential, sealed with a passphrase of yours: without it nobody can open it, Rasgeth included.'**
  String get vkKcExportLead;

  /// No description provided for @vkKcExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export the keychain'**
  String get vkKcExportTitle;

  /// No description provided for @vkKcExported.
  ///
  /// In en, this message translates to:
  /// **'Downloaded. Keep the file and its passphrase apart.'**
  String get vkKcExported;

  /// No description provided for @vkKcEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Keychain'**
  String get vkKcEyebrow;

  /// No description provided for @vkKcFormat.
  ///
  /// In en, this message translates to:
  /// **'Value of the header'**
  String get vkKcFormat;

  /// No description provided for @vkKcFormat_1password.
  ///
  /// In en, this message translates to:
  /// **'1Password'**
  String get vkKcFormat_1password;

  /// No description provided for @vkKcFormat_bitwarden.
  ///
  /// In en, this message translates to:
  /// **'Bitwarden'**
  String get vkKcFormat_bitwarden;

  /// No description provided for @vkKcFormat_chrome.
  ///
  /// In en, this message translates to:
  /// **'Chrome or Edge'**
  String get vkKcFormat_chrome;

  /// No description provided for @vkKcFormat_firefox.
  ///
  /// In en, this message translates to:
  /// **'Firefox'**
  String get vkKcFormat_firefox;

  /// No description provided for @vkKcFormat_generic.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get vkKcFormat_generic;

  /// No description provided for @vkKcGenAgain.
  ///
  /// In en, this message translates to:
  /// **'Another one'**
  String get vkKcGenAgain;

  /// No description provided for @vkKcGenChars.
  ///
  /// In en, this message translates to:
  /// **'{n} characters'**
  String vkKcGenChars(String n);

  /// No description provided for @vkKcGenDigits.
  ///
  /// In en, this message translates to:
  /// **'Digits only (PIN)'**
  String get vkKcGenDigits;

  /// No description provided for @vkKcGenKind.
  ///
  /// In en, this message translates to:
  /// **'What it is made of'**
  String get vkKcGenKind;

  /// No description provided for @vkKcGenLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get vkKcGenLength;

  /// No description provided for @vkKcGenLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters and digits'**
  String get vkKcGenLetters;

  /// No description provided for @vkKcGenSymbols.
  ///
  /// In en, this message translates to:
  /// **'Letters, digits, symbols'**
  String get vkKcGenSymbols;

  /// No description provided for @vkKcGenUse.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get vkKcGenUse;

  /// No description provided for @vkKcGenerate.
  ///
  /// In en, this message translates to:
  /// **'Make one'**
  String get vkKcGenerate;

  /// No description provided for @vkKcHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get vkKcHeader;

  /// No description provided for @vkKcHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get vkKcHide;

  /// No description provided for @vkKcHosts.
  ///
  /// In en, this message translates to:
  /// **'Allowed addresses'**
  String get vkKcHosts;

  /// No description provided for @vkKcHostsHelp.
  ///
  /// In en, this message translates to:
  /// **'Host names separated by commas; *.example.com for all its subdomains.'**
  String get vkKcHostsHelp;

  /// No description provided for @vkKcHow.
  ///
  /// In en, this message translates to:
  /// **'How it goes on a request'**
  String get vkKcHow;

  /// No description provided for @vkKcHowHelp.
  ///
  /// In en, this message translates to:
  /// **'When an agent does not write {ref} itself, the value goes in this header. {value} stands for the secret.'**
  String vkKcHowHelp(String ref, String value);

  /// No description provided for @vkKcImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get vkKcImport;

  /// No description provided for @vkKcImport1password.
  ///
  /// In en, this message translates to:
  /// **'1Password: File > Export > CSV'**
  String get vkKcImport1password;

  /// No description provided for @vkKcImportBitwarden.
  ///
  /// In en, this message translates to:
  /// **'Bitwarden: Tools > Export vault > .csv'**
  String get vkKcImportBitwarden;

  /// No description provided for @vkKcImportChrome.
  ///
  /// In en, this message translates to:
  /// **'Chrome and Edge: Settings > Passwords > Export passwords'**
  String get vkKcImportChrome;

  /// No description provided for @vkKcImportFirefox.
  ///
  /// In en, this message translates to:
  /// **'Firefox: Passwords > menu > Export passwords'**
  String get vkKcImportFirefox;

  /// No description provided for @vkKcImportFound.
  ///
  /// In en, this message translates to:
  /// **'{n} passwords found in the {from} file. Choose the ones to keep:'**
  String vkKcImportFound(String from, String n);

  /// No description provided for @vkKcImportGo.
  ///
  /// In en, this message translates to:
  /// **'Import {n}'**
  String vkKcImportGo(String n);

  /// No description provided for @vkKcImportLead.
  ///
  /// In en, this message translates to:
  /// **'Export your passwords from the other manager as a CSV file, then choose it here. A keychain file exported by Rasgeth works too.'**
  String get vkKcImportLead;

  /// No description provided for @vkKcImportLogins.
  ///
  /// In en, this message translates to:
  /// **'Imported logins are for you only: no agent may use them until you allow it.'**
  String get vkKcImportLogins;

  /// No description provided for @vkKcImportPick.
  ///
  /// In en, this message translates to:
  /// **'Choose the file'**
  String get vkKcImportPick;

  /// No description provided for @vkKcImportSafe.
  ///
  /// In en, this message translates to:
  /// **'Delete the CSV file afterwards: it holds your passwords in clear.'**
  String get vkKcImportSafe;

  /// No description provided for @vkKcImportSealedGo.
  ///
  /// In en, this message translates to:
  /// **'Open and import'**
  String get vkKcImportSealedGo;

  /// No description provided for @vkKcImportSealedHelp.
  ///
  /// In en, this message translates to:
  /// **'The passphrase chosen when the file was exported.'**
  String get vkKcImportSealedHelp;

  /// No description provided for @vkKcImportSkipped.
  ///
  /// In en, this message translates to:
  /// **'{n} without a password were left out.'**
  String vkKcImportSkipped(String n);

  /// No description provided for @vkKcImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import passwords'**
  String get vkKcImportTitle;

  /// No description provided for @vkKcImported.
  ///
  /// In en, this message translates to:
  /// **'{n} credentials added to the keychain.'**
  String vkKcImported(String n);

  /// No description provided for @vkKcLead.
  ///
  /// In en, this message translates to:
  /// **'Sealed on this computer. Agents use them by name and never see them; you choose where each one may go and who may use it.'**
  String get vkKcLead;

  /// No description provided for @vkKcLockedAdmin.
  ///
  /// In en, this message translates to:
  /// **'Set by the administrator'**
  String get vkKcLockedAdmin;

  /// No description provided for @vkKcManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get vkKcManage;

  /// No description provided for @vkKcMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get vkKcMore;

  /// No description provided for @vkKcMoveLead.
  ///
  /// In en, this message translates to:
  /// **'From Bitwarden, 1Password, Chrome, Edge or Firefox; out in a file sealed with a passphrase of yours.'**
  String get vkKcMoveLead;

  /// No description provided for @vkKcMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring them in, take them with you'**
  String get vkKcMoveTitle;

  /// No description provided for @vkKcName.
  ///
  /// In en, this message translates to:
  /// **'Name for the agents'**
  String get vkKcName;

  /// No description provided for @vkKcNameBad.
  ///
  /// In en, this message translates to:
  /// **'Only lower-case letters, digits, - and _ (at least two)'**
  String get vkKcNameBad;

  /// No description provided for @vkKcNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Lower case, no spaces: agents write it to use the credential.'**
  String get vkKcNameHelp;

  /// No description provided for @vkKcNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'Never used'**
  String get vkKcNeverUsed;

  /// No description provided for @vkKcNoHosts.
  ///
  /// In en, this message translates to:
  /// **'Without an address no agent can use it: it stays for you only.'**
  String get vkKcNoHosts;

  /// No description provided for @vkKcNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches the search.'**
  String get vkKcNoMatch;

  /// No description provided for @vkKcNoUses.
  ///
  /// In en, this message translates to:
  /// **'No agent has used a credential yet.'**
  String get vkKcNoUses;

  /// No description provided for @vkKcNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get vkKcNone;

  /// No description provided for @vkKcNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vkKcNotes;

  /// No description provided for @vkKcPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get vkKcPassphrase;

  /// No description provided for @vkKcPassphraseAgain.
  ///
  /// In en, this message translates to:
  /// **'The passphrase again'**
  String get vkKcPassphraseAgain;

  /// No description provided for @vkKcPassphraseDiffer.
  ///
  /// In en, this message translates to:
  /// **'The two are different'**
  String get vkKcPassphraseDiffer;

  /// No description provided for @vkKcPassphraseHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters. Keep it somewhere safe: it cannot be recovered.'**
  String get vkKcPassphraseHelp;

  /// No description provided for @vkKcProt_dpapi.
  ///
  /// In en, this message translates to:
  /// **'Protected by Windows'**
  String get vkKcProt_dpapi;

  /// No description provided for @vkKcProt_env.
  ///
  /// In en, this message translates to:
  /// **'Sealed with the server\'s own key'**
  String get vkKcProt_env;

  /// No description provided for @vkKcProt_file.
  ///
  /// In en, this message translates to:
  /// **'Sealed with a key kept on this computer'**
  String get vkKcProt_file;

  /// No description provided for @vkKcProt_keychain.
  ///
  /// In en, this message translates to:
  /// **'Protected by the Mac\'s Keychain'**
  String get vkKcProt_keychain;

  /// No description provided for @vkKcQ.
  ///
  /// In en, this message translates to:
  /// **'Your keys and passwords, safe in one place'**
  String get vkKcQ;

  /// No description provided for @vkKcRemove.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get vkKcRemove;

  /// No description provided for @vkKcRemoveQ.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String vkKcRemoveQ(String name);

  /// No description provided for @vkKcRemoveText.
  ///
  /// In en, this message translates to:
  /// **'The credential goes from the keychain for good: agents and tools can no longer use it.'**
  String get vkKcRemoveText;

  /// No description provided for @vkKcSafeText.
  ///
  /// In en, this message translates to:
  /// **'Encrypted (AES-256), never in a project or in git, never written in a chat or a log.'**
  String get vkKcSafeText;

  /// No description provided for @vkKcSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name, service, user or label'**
  String get vkKcSearch;

  /// No description provided for @vkKcSecret.
  ///
  /// In en, this message translates to:
  /// **'The secret'**
  String get vkKcSecret;

  /// No description provided for @vkKcSecretLead.
  ///
  /// In en, this message translates to:
  /// **'The key, token or password. Once saved it is never shown again unless you ask.'**
  String get vkKcSecretLead;

  /// No description provided for @vkKcSecretPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste or type it here'**
  String get vkKcSecretPlaceholder;

  /// No description provided for @vkKcService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get vkKcService;

  /// No description provided for @vkKcServiceExample.
  ///
  /// In en, this message translates to:
  /// **'Revolut Business'**
  String get vkKcServiceExample;

  /// No description provided for @vkKcServiceHelp.
  ///
  /// In en, this message translates to:
  /// **'The name you know it by: Revolut, Gmail, the office server.'**
  String get vkKcServiceHelp;

  /// No description provided for @vkKcShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get vkKcShow;

  /// No description provided for @vkKcShowQ.
  ///
  /// In en, this message translates to:
  /// **'Show the secret?'**
  String get vkKcShowQ;

  /// No description provided for @vkKcShowText.
  ///
  /// In en, this message translates to:
  /// **'It will be on the screen until you hide it or close the window. Make sure nobody is looking.'**
  String get vkKcShowText;

  /// No description provided for @vkKcUnlockShow.
  ///
  /// In en, this message translates to:
  /// **'Unlock to show this secret'**
  String get vkKcUnlockShow;

  /// No description provided for @vkKcUnlockCopy.
  ///
  /// In en, this message translates to:
  /// **'Unlock to copy this secret'**
  String get vkKcUnlockCopy;

  /// No description provided for @vkKcUnlockRefused.
  ///
  /// In en, this message translates to:
  /// **'Not unlocked: the secret stays hidden.'**
  String get vkKcUnlockRefused;

  /// No description provided for @vkKcNoLockQ.
  ///
  /// In en, this message translates to:
  /// **'This device has no lock'**
  String get vkKcNoLockQ;

  /// No description provided for @vkKcNoLockText.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this device checks that it is you: no PIN, fingerprint or face is set in the system\'s settings. Anyone holding it could see your keys, so set a screen lock there. Go on anyway?'**
  String get vkKcNoLockText;

  /// No description provided for @vkKcSomeAgents.
  ///
  /// In en, this message translates to:
  /// **'The agents that may use it'**
  String get vkKcSomeAgents;

  /// No description provided for @vkKcSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get vkKcSomeone;

  /// No description provided for @vkKcSys_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat: {what}'**
  String vkKcSys_chat(String what);

  /// No description provided for @vkKcSys_email.
  ///
  /// In en, this message translates to:
  /// **'Mailbox: {what}'**
  String vkKcSys_email(String what);

  /// No description provided for @vkKcSys_git.
  ///
  /// In en, this message translates to:
  /// **'Code hosting: {what}'**
  String vkKcSys_git(String what);

  /// No description provided for @vkKcSys_mcp.
  ///
  /// In en, this message translates to:
  /// **'Extension: {what}'**
  String vkKcSys_mcp(String what);

  /// No description provided for @vkKcSys_other.
  ///
  /// In en, this message translates to:
  /// **'{what}'**
  String vkKcSys_other(String what);

  /// No description provided for @vkKcSys_provider.
  ///
  /// In en, this message translates to:
  /// **'Model provider: {what}'**
  String vkKcSys_provider(String what);

  /// No description provided for @vkKcSys_search.
  ///
  /// In en, this message translates to:
  /// **'Web search: {what}'**
  String vkKcSys_search(String what);

  /// No description provided for @vkKcSys_ssh.
  ///
  /// In en, this message translates to:
  /// **'Machine (SSH): {what}'**
  String vkKcSys_ssh(String what);

  /// No description provided for @vkKcSystem.
  ///
  /// In en, this message translates to:
  /// **'Kept by Rasgeth'**
  String get vkKcSystem;

  /// No description provided for @vkKcSystemLead.
  ///
  /// In en, this message translates to:
  /// **'Keys set by whoever installed this server (in its environment): Rasgeth uses them, they cannot be changed here.'**
  String get vkKcSystemLead;

  /// No description provided for @vkKcSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Set by the administrator'**
  String get vkKcSystemTitle;

  /// No description provided for @vkKcTags.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get vkKcTags;

  /// No description provided for @vkKcTagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Separated by commas: work, home…'**
  String get vkKcTagsHelp;

  /// No description provided for @vkKcTools.
  ///
  /// In en, this message translates to:
  /// **'Extensions\' tools that receive it'**
  String get vkKcTools;

  /// No description provided for @vkKcToolsHelp.
  ///
  /// In en, this message translates to:
  /// **'A tool chosen here gets the address to reach the service with this credential, never the value.'**
  String get vkKcToolsHelp;

  /// No description provided for @vkKcUrl.
  ///
  /// In en, this message translates to:
  /// **'Address (if any)'**
  String get vkKcUrl;

  /// No description provided for @vkKcUseAs.
  ///
  /// In en, this message translates to:
  /// **'Agents call it {name}'**
  String vkKcUseAs(String name);

  /// No description provided for @vkKcUseBrowser.
  ///
  /// In en, this message translates to:
  /// **'{name} (browser)'**
  String vkKcUseBrowser(String name);

  /// No description provided for @vkKcUse_denied.
  ///
  /// In en, this message translates to:
  /// **'asked for {name} towards {host}: you said no'**
  String vkKcUse_denied(String host, String name);

  /// No description provided for @vkKcUse_moved.
  ///
  /// In en, this message translates to:
  /// **'moved {name} here from {host}'**
  String vkKcUse_moved(String host, String name);

  /// No description provided for @vkKcUse_refused.
  ///
  /// In en, this message translates to:
  /// **'could not use {name} towards {host}'**
  String vkKcUse_refused(String host, String name);

  /// No description provided for @vkKcUse_used.
  ///
  /// In en, this message translates to:
  /// **'used {name} towards {host}'**
  String vkKcUse_used(String host, String name);

  /// No description provided for @vkKcUsedBy.
  ///
  /// In en, this message translates to:
  /// **'Used by:'**
  String get vkKcUsedBy;

  /// No description provided for @vkKcUsedByText.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth uses this key by itself. Here you can change it, choose whether agents may use it too and see every use; you remove it from its page.'**
  String get vkKcUsedByText;

  /// No description provided for @vkKcUsedTimes.
  ///
  /// In en, this message translates to:
  /// **'Used {n} times, last {when}'**
  String vkKcUsedTimes(String n, String when);

  /// No description provided for @vkKcUser.
  ///
  /// In en, this message translates to:
  /// **'User or email (if any)'**
  String get vkKcUser;

  /// No description provided for @vkKcUsesLead.
  ///
  /// In en, this message translates to:
  /// **'Every time an agent asked for a credential: when, where to, and how it went.'**
  String get vkKcUsesLead;

  /// No description provided for @vkKcUsesOne.
  ///
  /// In en, this message translates to:
  /// **'Its last uses'**
  String get vkKcUsesOne;

  /// No description provided for @vkKcUsesTitle.
  ///
  /// In en, this message translates to:
  /// **'Who used them'**
  String get vkKcUsesTitle;

  /// No description provided for @vkKcWhere.
  ///
  /// In en, this message translates to:
  /// **'Where it may go'**
  String get vkKcWhere;

  /// No description provided for @vkKcWhereLead.
  ///
  /// In en, this message translates to:
  /// **'The value is put on a request only towards these addresses: anywhere else it is refused.'**
  String get vkKcWhereLead;

  /// No description provided for @vkKcWho.
  ///
  /// In en, this message translates to:
  /// **'Who may use it'**
  String get vkKcWho;

  /// No description provided for @vkKcWhoLead.
  ///
  /// In en, this message translates to:
  /// **'Agents never see the value: they ask for it by name, and Rasgeth puts it on the request.'**
  String get vkKcWhoLead;

  /// No description provided for @vkMcSection.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get vkMcSection;

  /// No description provided for @vkSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get vkSave;

  /// No description provided for @vkSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get vkSettings;

  /// No description provided for @vkWzCode.
  ///
  /// In en, this message translates to:
  /// **'Where the code lives'**
  String get vkWzCode;

  /// No description provided for @vkWzRemote.
  ///
  /// In en, this message translates to:
  /// **'Access from outside home'**
  String get vkWzRemote;

  /// No description provided for @vkAutomations.
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get vkAutomations;

  /// No description provided for @vkChats.
  ///
  /// In en, this message translates to:
  /// **'Other chats'**
  String get vkChats;

  /// No description provided for @vkExtensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get vkExtensions;

  /// No description provided for @vkSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Models and subscriptions'**
  String get vkSubscriptions;

  /// No description provided for @vkTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get vkTelegram;

  /// No description provided for @g4211Hub.
  ///
  /// In en, this message translates to:
  /// **'Services, skills, generation and the agents\' proposals'**
  String get g4211Hub;

  /// No description provided for @g4212Hub.
  ///
  /// In en, this message translates to:
  /// **'Keys and passwords, safe in one place'**
  String get g4212Hub;

  /// No description provided for @g4211SignInOpened.
  ///
  /// In en, this message translates to:
  /// **'The service\'s page opened in the browser: sign in there, then come back here.'**
  String get g4211SignInOpened;

  /// No description provided for @g4211OpenExtensions.
  ///
  /// In en, this message translates to:
  /// **'Open Extensions'**
  String get g4211OpenExtensions;

  /// No description provided for @g4212OpenKeychain.
  ///
  /// In en, this message translates to:
  /// **'Open the keychain'**
  String get g4212OpenKeychain;

  /// No description provided for @syBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get syBackup;

  /// No description provided for @syBackupAddsHint.
  ///
  /// In en, this message translates to:
  /// **'A project whose name is taken here comes in beside it, with a number after the name.'**
  String get syBackupAddsHint;

  /// No description provided for @syBackupAlreadyHere.
  ///
  /// In en, this message translates to:
  /// **'already here, left as it is'**
  String get syBackupAlreadyHere;

  /// No description provided for @syBackupAnother.
  ///
  /// In en, this message translates to:
  /// **'Import another backup'**
  String get syBackupAnother;

  /// No description provided for @syBackupChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose the backup file'**
  String get syBackupChoose;

  /// No description provided for @syBackupCounts.
  ///
  /// In en, this message translates to:
  /// **'{agents} agents · {conversations} conversations · {size} of files'**
  String syBackupCounts(String agents, String conversations, String size);

  /// No description provided for @syBackupDownload.
  ///
  /// In en, this message translates to:
  /// **'Download {file}'**
  String syBackupDownload(String file);

  /// No description provided for @syBackupExport.
  ///
  /// In en, this message translates to:
  /// **'Make a backup'**
  String get syBackupExport;

  /// No description provided for @syBackupExportHint.
  ///
  /// In en, this message translates to:
  /// **'Projects with their files, agents, conversations, chats and the board. Keys and sign-ins to services are not in it: they stay on this computer. node_modules folders are left out (they are rebuilt).'**
  String get syBackupExportHint;

  /// No description provided for @syBackupFrom.
  ///
  /// In en, this message translates to:
  /// **'Backup of {when}'**
  String syBackupFrom(String when);

  /// No description provided for @syBackupImport.
  ///
  /// In en, this message translates to:
  /// **'Import a backup'**
  String get syBackupImport;

  /// No description provided for @syBackupImportHint.
  ///
  /// In en, this message translates to:
  /// **'From another Rasgeth or from this one. Nothing here is deleted or replaced: what is in the backup is added, and what is already here stays as it is.'**
  String get syBackupImportHint;

  /// No description provided for @syBackupImportNow.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get syBackupImportNow;

  /// No description provided for @syBackupImported.
  ///
  /// In en, this message translates to:
  /// **'Done: {projects} projects, {agents} agents and {conversations} conversations added.'**
  String syBackupImported(String agents, String conversations, String projects);

  /// No description provided for @syBackupKeepName.
  ///
  /// In en, this message translates to:
  /// **'Keep {name}'**
  String syBackupKeepName(String name);

  /// No description provided for @syBackupKeys.
  ///
  /// In en, this message translates to:
  /// **'Include the keychain'**
  String get syBackupKeys;

  /// No description provided for @syBackupKeysHelp.
  ///
  /// In en, this message translates to:
  /// **'Sealed with a passphrase of yours, with the keys of the models, chats and mailboxes: without it the backup\'s credentials cannot be opened.'**
  String get syBackupKeysHelp;

  /// No description provided for @syBackupKeysIn.
  ///
  /// In en, this message translates to:
  /// **'The backup carries a keychain: its passphrase'**
  String get syBackupKeysIn;

  /// No description provided for @syBackupKeysInHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave it empty to import everything else without the credentials.'**
  String get syBackupKeysInHelp;

  /// No description provided for @syBackupKeysWrong.
  ///
  /// In en, this message translates to:
  /// **'The keychain was not imported: wrong passphrase. Everything else was.'**
  String get syBackupKeysWrong;

  /// No description provided for @syBackupMake.
  ///
  /// In en, this message translates to:
  /// **'Prepare the backup'**
  String get syBackupMake;

  /// No description provided for @syBackupMakeAgain.
  ///
  /// In en, this message translates to:
  /// **'Prepare it again'**
  String get syBackupMakeAgain;

  /// No description provided for @syBackupNameQuestion.
  ///
  /// In en, this message translates to:
  /// **'{who} is called {here} here and {backup} in the backup. Which name does it keep?'**
  String syBackupNameQuestion(String backup, String here, String who);

  /// No description provided for @syBackupNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Every project in this backup is here already: only what is missing is added.'**
  String get syBackupNothingNew;

  /// No description provided for @syBackupPurpose.
  ///
  /// In en, this message translates to:
  /// **'Every project with its files, the agents and the conversations in one file: keep it safe, or carry it to another Rasgeth.'**
  String get syBackupPurpose;

  /// No description provided for @syBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved in your Downloads folder.'**
  String get syBackupSaved;

  /// No description provided for @syBackupSending.
  ///
  /// In en, this message translates to:
  /// **'Sending the file to Rasgeth'**
  String get syBackupSending;

  /// No description provided for @syBackupTakeName.
  ///
  /// In en, this message translates to:
  /// **'Use {name}'**
  String syBackupTakeName(String name);

  /// No description provided for @syBrainDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get syBrainDisconnect;

  /// No description provided for @syCaddyDomain.
  ///
  /// In en, this message translates to:
  /// **'The address'**
  String get syCaddyDomain;

  /// No description provided for @syCaddyDomainHelp.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth gets its HTTPS certificate from Let\'s Encrypt by itself.'**
  String get syCaddyDomainHelp;

  /// No description provided for @syCaddyPihole.
  ///
  /// In en, this message translates to:
  /// **'Inside home some routers cannot reach their own public address: then open Rasgeth at home with its usual link, or turn on Pi-hole in Settings, Access from outside home (it is optional).'**
  String get syCaddyPihole;

  /// No description provided for @syCaddyStep1.
  ///
  /// In en, this message translates to:
  /// **'At your domain\'s provider, make a DNS record of type A for the address you want (for example rasgeth.yourdomain.com) pointing at your home\'s public address. If it changes, use a dynamic DNS service.'**
  String get syCaddyStep1;

  /// No description provided for @syCaddyStep2.
  ///
  /// In en, this message translates to:
  /// **'On your router, forward ports 80 and 443 to this computer.'**
  String get syCaddyStep2;

  /// No description provided for @syCaddyWarning.
  ///
  /// In en, this message translates to:
  /// **'With this way Rasgeth\'s sign-in page is on the internet: keep the password strong and the second check on.'**
  String get syCaddyWarning;

  /// No description provided for @syCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get syCancel;

  /// No description provided for @syCfAccess.
  ///
  /// In en, this message translates to:
  /// **'Safer still: in Cloudflare Zero Trust, Access, add an application for this address, so Cloudflare asks who you are before the page even appears.'**
  String get syCfAccess;

  /// No description provided for @syCfBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy a domain on Cloudflare'**
  String get syCfBuy;

  /// No description provided for @syCfHost.
  ///
  /// In en, this message translates to:
  /// **'The address you chose'**
  String get syCfHost;

  /// No description provided for @syCfHostHelp.
  ///
  /// In en, this message translates to:
  /// **'For example rasgeth.yourdomain.com: the subdomain and domain of the Public hostname.'**
  String get syCfHostHelp;

  /// No description provided for @syCfStep1.
  ///
  /// In en, this message translates to:
  /// **'If you have no domain yet, buy one (Cloudflare sells them at cost, about 10 euros a year):'**
  String get syCfStep1;

  /// No description provided for @syCfStep2.
  ///
  /// In en, this message translates to:
  /// **'Open Tunnels in Cloudflare Zero Trust, press Create a tunnel, choose Cloudflared and give it a name (for example rasgeth):'**
  String get syCfStep2;

  /// No description provided for @syCfStep3.
  ///
  /// In en, this message translates to:
  /// **'In the step Public hostname: subdomain rasgeth, your domain, Service type HTTP, URL redgiant:7600. Save.'**
  String get syCfStep3;

  /// No description provided for @syCfStep4.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare shows a command with a long token after --token: copy only the token and write the address here.'**
  String get syCfStep4;

  /// No description provided for @syCfToken.
  ///
  /// In en, this message translates to:
  /// **'The tunnel\'s token'**
  String get syCfToken;

  /// No description provided for @syCfTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'The long string after --token in the command Cloudflare shows (it starts with eyJ).'**
  String get syCfTokenHelp;

  /// No description provided for @syCfTunnels.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare tunnels'**
  String get syCfTunnels;

  /// No description provided for @syConnecting.
  ///
  /// In en, this message translates to:
  /// **'connecting…'**
  String get syConnecting;

  /// No description provided for @syConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get syConversations;

  /// No description provided for @syErr_agent_limit.
  ///
  /// In en, this message translates to:
  /// **'The project «{project}» can have at most {max} agents besides its orchestrator: it has {count}. Raise the limit in Settings › Projects or remove one.'**
  String syErr_agent_limit(String count, String max, String project);

  /// No description provided for @syErr_agent_removed.
  ///
  /// In en, this message translates to:
  /// **'The agent was removed from the team: restore it to work with it.'**
  String get syErr_agent_removed;

  /// No description provided for @syErr_agent_stopped.
  ///
  /// In en, this message translates to:
  /// **'The agent is stopped (paused): resume it to go on.'**
  String get syErr_agent_stopped;

  /// No description provided for @syErr_bad_name.
  ///
  /// In en, this message translates to:
  /// **'That is not a name (for instance git.home.example.com).'**
  String get syErr_bad_name;

  /// No description provided for @syErr_code_rejected.
  ///
  /// In en, this message translates to:
  /// **'Anthropic did not accept this code: it may be incomplete or old. Open the sign-in page again to get a new one.'**
  String get syErr_code_rejected;

  /// No description provided for @syErr_email_failed.
  ///
  /// In en, this message translates to:
  /// **'The mailbox did not let Rasgeth in: check the server, the address and the app password.'**
  String get syErr_email_failed;

  /// No description provided for @syErr_failed.
  ///
  /// In en, this message translates to:
  /// **'The sign-in did not finish. Try again from the start.'**
  String get syErr_failed;

  /// No description provided for @syErr_host_unreachable.
  ///
  /// In en, this message translates to:
  /// **'The server\'s name is known, but its address does not answer from Rasgeth. See Settings › Access from outside home › Your home services.'**
  String get syErr_host_unreachable;

  /// No description provided for @syErr_key_rejected.
  ///
  /// In en, this message translates to:
  /// **'The provider refused this key. Check that you copied all of it and that it is still active.'**
  String get syErr_key_rejected;

  /// No description provided for @syErr_memory_empty.
  ///
  /// In en, this message translates to:
  /// **'Write something to remember.'**
  String get syErr_memory_empty;

  /// No description provided for @syErr_memory_forgotten.
  ///
  /// In en, this message translates to:
  /// **'A memory forgotten for good cannot come back.'**
  String get syErr_memory_forgotten;

  /// No description provided for @syErr_memory_full.
  ///
  /// In en, this message translates to:
  /// **'The memory is full: delete or merge some old memories first.'**
  String get syErr_memory_full;

  /// No description provided for @syErr_memory_gone.
  ///
  /// In en, this message translates to:
  /// **'That memory is not there any more.'**
  String get syErr_memory_gone;

  /// No description provided for @syErr_memory_long.
  ///
  /// In en, this message translates to:
  /// **'A memory is at most 400 characters: write it shorter.'**
  String get syErr_memory_long;

  /// No description provided for @syErr_memory_moved.
  ///
  /// In en, this message translates to:
  /// **'The memory changed again since: undo the newer change first.'**
  String get syErr_memory_moved;

  /// No description provided for @syErr_memory_same.
  ///
  /// In en, this message translates to:
  /// **'Another memory already says the same.'**
  String get syErr_memory_same;

  /// No description provided for @syErr_memory_secret.
  ///
  /// In en, this message translates to:
  /// **'That looks like a password, a code or a card number: secrets are never kept in memory.'**
  String get syErr_memory_secret;

  /// No description provided for @syErr_memory_undone.
  ///
  /// In en, this message translates to:
  /// **'That change was already undone.'**
  String get syErr_memory_undone;

  /// No description provided for @syErr_missing_permission.
  ///
  /// In en, this message translates to:
  /// **'GitHub did not let the token create repositories. Make a new one with Administration set to Read and write.'**
  String get syErr_missing_permission;

  /// No description provided for @syErr_name_not_found.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth cannot find the server\'s name in the DNS it uses. See Settings › Access from outside home › Your home services.'**
  String get syErr_name_not_found;

  /// No description provided for @syErr_no_login.
  ///
  /// In en, this message translates to:
  /// **'Open Anthropic\'s sign-in page first.'**
  String get syErr_no_login;

  /// No description provided for @syErr_no_model.
  ///
  /// In en, this message translates to:
  /// **'No model is chosen yet: open Settings, Models and subscriptions, connect one (a subscription, a key or a local model) and choose it in \"The model agents use\".'**
  String get syErr_no_model;

  /// No description provided for @syErr_no_page.
  ///
  /// In en, this message translates to:
  /// **'Anthropic\'s sign-in page could not be prepared. Try again in a moment.'**
  String get syErr_no_page;

  /// No description provided for @syErr_no_password.
  ///
  /// In en, this message translates to:
  /// **'Set a password first.'**
  String get syErr_no_password;

  /// No description provided for @syErr_portrait_empty.
  ///
  /// In en, this message translates to:
  /// **'Write the trait.'**
  String get syErr_portrait_empty;

  /// No description provided for @syErr_portrait_gone.
  ///
  /// In en, this message translates to:
  /// **'That trait is not there any more.'**
  String get syErr_portrait_gone;

  /// No description provided for @syErr_portrait_long.
  ///
  /// In en, this message translates to:
  /// **'A trait is at most 200 characters: write it shorter.'**
  String get syErr_portrait_long;

  /// No description provided for @syErr_portrait_private.
  ///
  /// In en, this message translates to:
  /// **'Email addresses and phone numbers never go into the portrait.'**
  String get syErr_portrait_private;

  /// No description provided for @syErr_portrait_secret.
  ///
  /// In en, this message translates to:
  /// **'That looks like a password, a code or a card number: secrets never go into the portrait.'**
  String get syErr_portrait_secret;

  /// No description provided for @syErr_project_archived.
  ///
  /// In en, this message translates to:
  /// **'The project is archived: restore it to work in it.'**
  String get syErr_project_archived;

  /// No description provided for @syErr_provider_stalled.
  ///
  /// In en, this message translates to:
  /// **'The provider has not answered for {minutes} minutes: I tried again {retries} times. Try again in a while, or choose another model.'**
  String syErr_provider_stalled(String minutes, String retries);

  /// No description provided for @syErr_terms.
  ///
  /// In en, this message translates to:
  /// **'First tick the box about the providers\' terms.'**
  String get syErr_terms;

  /// No description provided for @syErr_token_rejected.
  ///
  /// In en, this message translates to:
  /// **'Telegram refused this token. Copy it again from BotFather\'s message, all of it.'**
  String get syErr_token_rejected;

  /// No description provided for @syErr_too_many.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong tries: wait 15 minutes, then try again.'**
  String get syErr_too_many;

  /// No description provided for @syErr_unreachable.
  ///
  /// In en, this message translates to:
  /// **'The provider did not answer. Check the address and the internet connection, then try again.'**
  String get syErr_unreachable;

  /// No description provided for @syErr_vault_bad_file.
  ///
  /// In en, this message translates to:
  /// **'This file is not a password export Rasgeth can read.'**
  String get syErr_vault_bad_file;

  /// No description provided for @syErr_vault_bad_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase, or a damaged file.'**
  String get syErr_vault_bad_passphrase;

  /// No description provided for @syErr_vault_closed.
  ///
  /// In en, this message translates to:
  /// **'The keychain is closed on this computer.'**
  String get syErr_vault_closed;

  /// No description provided for @syErr_vault_in_git.
  ///
  /// In en, this message translates to:
  /// **'The keychain\'s folder is inside a git repository: it must never be committed. Move Rasgeth\'s data folder outside it.'**
  String get syErr_vault_in_git;

  /// No description provided for @syErr_vault_name_taken.
  ///
  /// In en, this message translates to:
  /// **'Another credential has that name for the agents: choose another one.'**
  String get syErr_vault_name_taken;

  /// No description provided for @syErr_vault_no_value.
  ///
  /// In en, this message translates to:
  /// **'Write the secret.'**
  String get syErr_vault_no_value;

  /// No description provided for @syErr_vault_not_found.
  ///
  /// In en, this message translates to:
  /// **'That credential is no longer in the keychain.'**
  String get syErr_vault_not_found;

  /// No description provided for @syErr_vault_system.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth uses this key: remove it from its page in Settings.'**
  String get syErr_vault_system;

  /// No description provided for @syErr_voice_convert.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be converted for whisper on this computer.'**
  String get syErr_voice_convert;

  /// No description provided for @syErr_voice_empty.
  ///
  /// In en, this message translates to:
  /// **'The recording is empty.'**
  String get syErr_voice_empty;

  /// No description provided for @syErr_voice_key_refused.
  ///
  /// In en, this message translates to:
  /// **'{name} refused the key: check it in Settings, Voice.'**
  String syErr_voice_key_refused(String name);

  /// No description provided for @syErr_voice_no_key.
  ///
  /// In en, this message translates to:
  /// **'{name} has no key yet: add it in Settings, Voice.'**
  String syErr_voice_no_key(String name);

  /// No description provided for @syErr_voice_no_service.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth has no transcription service: choose one in Settings, Voice, Transcription.'**
  String get syErr_voice_no_service;

  /// No description provided for @syErr_voice_provider.
  ///
  /// In en, this message translates to:
  /// **'This provider cannot do it: choose another one.'**
  String get syErr_voice_provider;

  /// No description provided for @syErr_voice_rate_limited.
  ///
  /// In en, this message translates to:
  /// **'{name} says too many requests or no credit left.'**
  String syErr_voice_rate_limited(String name);

  /// No description provided for @syErr_voice_service_error.
  ///
  /// In en, this message translates to:
  /// **'{name} answered with an error ({status}).'**
  String syErr_voice_service_error(String name, String status);

  /// No description provided for @syErr_voice_timeout.
  ///
  /// In en, this message translates to:
  /// **'{name} took too long to answer.'**
  String syErr_voice_timeout(String name);

  /// No description provided for @syErr_voice_too_long.
  ///
  /// In en, this message translates to:
  /// **'The recording is too long.'**
  String get syErr_voice_too_long;

  /// No description provided for @syErr_voice_unreachable.
  ///
  /// In en, this message translates to:
  /// **'{name} cannot be reached: check that it is on and its address.'**
  String syErr_voice_unreachable(String name);

  /// No description provided for @syErr_weak.
  ///
  /// In en, this message translates to:
  /// **'The password needs at least 10 characters.'**
  String get syErr_weak;

  /// No description provided for @syErr_wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or code.'**
  String get syErr_wrong;

  /// No description provided for @syError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get syError;

  /// No description provided for @syFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get syFailed;

  /// No description provided for @syFbArch.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get syFbArch;

  /// No description provided for @syFbBackupBusy.
  ///
  /// In en, this message translates to:
  /// **'A backup is already running.'**
  String get syFbBackupBusy;

  /// No description provided for @syFbBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Make a backup now'**
  String get syFbBackupNow;

  /// No description provided for @syFbBackupQ.
  ///
  /// In en, this message translates to:
  /// **'Best on another disk: if this one breaks, the copy is still there.'**
  String get syFbBackupQ;

  /// No description provided for @syFbBackupStarted.
  ///
  /// In en, this message translates to:
  /// **'Backup started: it shows in Downloads and jobs.'**
  String get syFbBackupStarted;

  /// No description provided for @syFbBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get syFbBackupTitle;

  /// No description provided for @syFbCannotMount.
  ///
  /// In en, this message translates to:
  /// **'Cannot be mounted here'**
  String get syFbCannotMount;

  /// No description provided for @syFbContainerDisks.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth OS runs in a container ({name}): the disks it sees are those of the machine hosting it and cannot be used from here.'**
  String syFbContainerDisks(String name);

  /// No description provided for @syFbDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get syFbDaily;

  /// No description provided for @syFbDataDir.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get syFbDataDir;

  /// No description provided for @syFbDataQ.
  ///
  /// In en, this message translates to:
  /// **'Projects, conversations and settings are here.'**
  String get syFbDataQ;

  /// No description provided for @syFbDataTitle.
  ///
  /// In en, this message translates to:
  /// **'The data'**
  String get syFbDataTitle;

  /// No description provided for @syFbDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get syFbDay;

  /// No description provided for @syFbDestDisk.
  ///
  /// In en, this message translates to:
  /// **'Backups go to the disk {label} ({path}).'**
  String syFbDestDisk(String label, String path);

  /// No description provided for @syFbDestFolder.
  ///
  /// In en, this message translates to:
  /// **'Backups go to the folder {path}.'**
  String syFbDestFolder(String path);

  /// No description provided for @syFbDestNode.
  ///
  /// In en, this message translates to:
  /// **'Backups go to the node {name}, in the storage it lends.'**
  String syFbDestNode(String name);

  /// No description provided for @syFbDestSftp.
  ///
  /// In en, this message translates to:
  /// **'Backups go to {machine}, in {path} (SFTP).'**
  String syFbDestSftp(String machine, String path);

  /// No description provided for @syFbDestSmb.
  ///
  /// In en, this message translates to:
  /// **'Backups go to the shared folder {path}, as {user}.'**
  String syFbDestSmb(String path, String user);

  /// No description provided for @syFbDisks.
  ///
  /// In en, this message translates to:
  /// **'Disks'**
  String get syFbDisks;

  /// No description provided for @syFbDisksTitle.
  ///
  /// In en, this message translates to:
  /// **'Removable disks'**
  String get syFbDisksTitle;

  /// No description provided for @syFbErr_already.
  ///
  /// In en, this message translates to:
  /// **'The container already has a folder with that name.'**
  String get syFbErr_already;

  /// No description provided for @syFbErr_auth.
  ///
  /// In en, this message translates to:
  /// **'The destination refused the sign-in: check the user and the password (or the machine\'s key).'**
  String get syFbErr_auth;

  /// No description provided for @syFbErr_bad_path.
  ///
  /// In en, this message translates to:
  /// **'Write a full folder path (/volume1/Rasgeth) or one from the home (~/backups).'**
  String get syFbErr_bad_path;

  /// No description provided for @syFbErr_denied.
  ///
  /// In en, this message translates to:
  /// **'The destination does not let this user write there.'**
  String get syFbErr_denied;

  /// No description provided for @syFbErr_disk_missing.
  ///
  /// In en, this message translates to:
  /// **'The backup disk is not connected: plug it in. Nothing was written elsewhere.'**
  String get syFbErr_disk_missing;

  /// No description provided for @syFbErr_has_filesystem.
  ///
  /// In en, this message translates to:
  /// **'That disk is formatted already: it is never formatted again from here.'**
  String get syFbErr_has_filesystem;

  /// No description provided for @syFbErr_keychain_closed.
  ///
  /// In en, this message translates to:
  /// **'Open the keychain first: the password is kept there.'**
  String get syFbErr_keychain_closed;

  /// No description provided for @syFbErr_mismatch.
  ///
  /// In en, this message translates to:
  /// **'The copy arrived different from the original: it was not kept. Try again.'**
  String get syFbErr_mismatch;

  /// No description provided for @syFbErr_needs_format.
  ///
  /// In en, this message translates to:
  /// **'That disk is not formatted.'**
  String get syFbErr_needs_format;

  /// No description provided for @syFbErr_no_container.
  ///
  /// In en, this message translates to:
  /// **'There is no container with that id on the host.'**
  String get syFbErr_no_container;

  /// No description provided for @syFbErr_no_destination.
  ///
  /// In en, this message translates to:
  /// **'Choose where backups go first.'**
  String get syFbErr_no_destination;

  /// No description provided for @syFbErr_no_disk.
  ///
  /// In en, this message translates to:
  /// **'That disk is not a removable disk of the host (any more).'**
  String get syFbErr_no_disk;

  /// No description provided for @syFbErr_not_found.
  ///
  /// In en, this message translates to:
  /// **'The folder or the destination is not there (any more).'**
  String get syFbErr_not_found;

  /// No description provided for @syFbErr_not_proxmox.
  ///
  /// In en, this message translates to:
  /// **'That machine is not a Proxmox host.'**
  String get syFbErr_not_proxmox;

  /// No description provided for @syFbErr_not_trusted.
  ///
  /// In en, this message translates to:
  /// **'Test this machine once in Settings › Machines and trust its key first.'**
  String get syFbErr_not_trusted;

  /// No description provided for @syFbErr_place_missing.
  ///
  /// In en, this message translates to:
  /// **'The folder from the host is not mounted now: nothing was written on the system disk.'**
  String get syFbErr_place_missing;

  /// No description provided for @syFbErr_smb_address.
  ///
  /// In en, this message translates to:
  /// **'Write the shared folder as \\\\host\\share\\folder (letters, digits, spaces, dots and dashes).'**
  String get syFbErr_smb_address;

  /// No description provided for @syFbErr_smb_bad_domain.
  ///
  /// In en, this message translates to:
  /// **'The domain is letters, digits, dots and dashes.'**
  String get syFbErr_smb_bad_domain;

  /// No description provided for @syFbErr_smb_bad_password.
  ///
  /// In en, this message translates to:
  /// **'This password cannot be used (no line breaks).'**
  String get syFbErr_smb_bad_password;

  /// No description provided for @syFbErr_smb_bad_user.
  ///
  /// In en, this message translates to:
  /// **'This user name cannot be used.'**
  String get syFbErr_smb_bad_user;

  /// No description provided for @syFbErr_smb_missing.
  ///
  /// In en, this message translates to:
  /// **'Shared folders need smbclient, which this installation does not have.'**
  String get syFbErr_smb_missing;

  /// No description provided for @syFbErr_unreachable.
  ///
  /// In en, this message translates to:
  /// **'The destination does not answer: is it on and on the network? Nothing was written elsewhere.'**
  String get syFbErr_unreachable;

  /// No description provided for @syFbFolderLead.
  ///
  /// In en, this message translates to:
  /// **'A folder this machine can write to: a network share, a disk mounted by you. Not inside the data folder.'**
  String get syFbFolderLead;

  /// No description provided for @syFbFolderPath.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get syFbFolderPath;

  /// No description provided for @syFbFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Or a folder'**
  String get syFbFolderTitle;

  /// No description provided for @syFbFreeOf.
  ///
  /// In en, this message translates to:
  /// **'{free} free'**
  String syFbFreeOf(String free);

  /// No description provided for @syFbFreeOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{free} GB free of {total} GB'**
  String syFbFreeOfTotal(String free, String total);

  /// No description provided for @syFbFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get syFbFri;

  /// No description provided for @syFbHostBad_bad_device.
  ///
  /// In en, this message translates to:
  /// **'This disk\'s device cannot be used.'**
  String get syFbHostBad_bad_device;

  /// No description provided for @syFbHostBad_bad_id.
  ///
  /// In en, this message translates to:
  /// **'The container id is a number, like 105.'**
  String get syFbHostBad_bad_id;

  /// No description provided for @syFbHostBad_bad_mp.
  ///
  /// In en, this message translates to:
  /// **'No free mount point.'**
  String get syFbHostBad_bad_mp;

  /// No description provided for @syFbHostBad_bad_name.
  ///
  /// In en, this message translates to:
  /// **'This disk\'s name cannot be used for a folder.'**
  String get syFbHostBad_bad_name;

  /// No description provided for @syFbHostId.
  ///
  /// In en, this message translates to:
  /// **'Container id on Proxmox'**
  String get syFbHostId;

  /// No description provided for @syFbHostIdHelp.
  ///
  /// In en, this message translates to:
  /// **'The number in Proxmox\'s list (this container is called {hostname}).'**
  String syFbHostIdHelp(String hostname);

  /// No description provided for @syFbHostKind.
  ///
  /// In en, this message translates to:
  /// **'The host'**
  String get syFbHostKind;

  /// No description provided for @syFbHostLead.
  ///
  /// In en, this message translates to:
  /// **'From a container Rasgeth sees the host\'s disks but cannot mount them: the host mounts the disk and passes a folder in. Rasgeth notices it by itself.'**
  String get syFbHostLead;

  /// No description provided for @syFbHostMany.
  ///
  /// In en, this message translates to:
  /// **'On this machine there are {n} removable disks: pick the one for backups.'**
  String syFbHostMany(String n);

  /// No description provided for @syFbHostNone.
  ///
  /// In en, this message translates to:
  /// **'No removable disk of the host is in sight: plug it into the host, or use a folder on the network below.'**
  String get syFbHostNone;

  /// No description provided for @syFbHostOne.
  ///
  /// In en, this message translates to:
  /// **'On this machine there is the disk {title}, {how}, {size}.'**
  String syFbHostOne(String how, String size, String title);

  /// No description provided for @syFbHostOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get syFbHostOther;

  /// No description provided for @syFbHostSteps.
  ///
  /// In en, this message translates to:
  /// **'To run on the host, as root'**
  String get syFbHostSteps;

  /// No description provided for @syFbHostTitle.
  ///
  /// In en, this message translates to:
  /// **'A disk of the host'**
  String get syFbHostTitle;

  /// No description provided for @syFbHostWatching.
  ///
  /// In en, this message translates to:
  /// **'Looking every few seconds: when {target} arrives it shows above, ready to use.'**
  String syFbHostWatching(String target);

  /// No description provided for @syFbHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get syFbHour;

  /// No description provided for @syFbKeep.
  ///
  /// In en, this message translates to:
  /// **'Backups kept'**
  String get syFbKeep;

  /// No description provided for @syFbKeepN.
  ///
  /// In en, this message translates to:
  /// **'keep {n}'**
  String syFbKeepN(String n);

  /// No description provided for @syFbLastFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup of {when} did not work: {why}'**
  String syFbLastFailed(String when, String why);

  /// No description provided for @syFbLastOk.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {when}, read back and complete.'**
  String syFbLastOk(String when);

  /// No description provided for @syFbListAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get syFbListAgain;

  /// No description provided for @syFbListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backup yet in {where}.'**
  String syFbListEmpty(String where);

  /// No description provided for @syFbListLead.
  ///
  /// In en, this message translates to:
  /// **'Each one can be brought back: what is new is added, nothing here is deleted.'**
  String get syFbListLead;

  /// No description provided for @syFbListShow.
  ///
  /// In en, this message translates to:
  /// **'Show the backups'**
  String get syFbListShow;

  /// No description provided for @syFbListTitle.
  ///
  /// In en, this message translates to:
  /// **'The backups there'**
  String get syFbListTitle;

  /// No description provided for @syFbMachineTitle.
  ///
  /// In en, this message translates to:
  /// **'The machine'**
  String get syFbMachineTitle;

  /// No description provided for @syFbMethod_helper.
  ///
  /// In en, this message translates to:
  /// **'Pick one: Rasgeth mounts it only for backups. System disks are never offered.'**
  String get syFbMethod_helper;

  /// No description provided for @syFbMethod_none.
  ///
  /// In en, this message translates to:
  /// **'This installation cannot mount disks (for example plain Docker without privileges): use a disk already mounted, or a folder below.'**
  String get syFbMethod_none;

  /// No description provided for @syFbMethod_udisks.
  ///
  /// In en, this message translates to:
  /// **'Pick one: the system mounts it (udisks2). System disks are never offered.'**
  String get syFbMethod_udisks;

  /// No description provided for @syFbMissing_not_installed.
  ///
  /// In en, this message translates to:
  /// **'unknown: the program that tells is not installed'**
  String get syFbMissing_not_installed;

  /// No description provided for @syFbMissing_unreadable.
  ///
  /// In en, this message translates to:
  /// **'could not be read'**
  String get syFbMissing_unreadable;

  /// No description provided for @syFbMissing_unsupported.
  ///
  /// In en, this message translates to:
  /// **'not available on this system'**
  String get syFbMissing_unsupported;

  /// No description provided for @syFbMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get syFbMon;

  /// No description provided for @syFbNetAProxy.
  ///
  /// In en, this message translates to:
  /// **'a reverse proxy'**
  String get syFbNetAProxy;

  /// No description provided for @syFbNetDns.
  ///
  /// In en, this message translates to:
  /// **'A DNS server on your network ({ip}): a name like rasgeth.home can point here.'**
  String syFbNetDns(String ip);

  /// No description provided for @syFbNetFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder there'**
  String get syFbNetFolder;

  /// No description provided for @syFbNetFolderHelp.
  ///
  /// In en, this message translates to:
  /// **'A full path (/volume1/Rasgeth, E:\\Backup) or one from the home (~/RedGiant-backups). It is made if missing.'**
  String get syFbNetFolderHelp;

  /// No description provided for @syFbNetLanOnly.
  ///
  /// In en, this message translates to:
  /// **'Local network only is a fine choice: skip this step.'**
  String get syFbNetLanOnly;

  /// No description provided for @syFbNetLead.
  ///
  /// In en, this message translates to:
  /// **'Nothing to mount: it works also in a container or in Docker. Each backup arrives under a temporary name and gets its real name only once complete and checked.'**
  String get syFbNetLead;

  /// No description provided for @syFbNetName.
  ///
  /// In en, this message translates to:
  /// **'You reached Rasgeth by name: {name}.'**
  String syFbNetName(String name);

  /// No description provided for @syFbNetNoMachines.
  ///
  /// In en, this message translates to:
  /// **'No machine yet: add your NAS or another computer in Settings › Machines (SSH), test it once, then come back here.'**
  String get syFbNetNoMachines;

  /// No description provided for @syFbNetNoNodes.
  ///
  /// In en, this message translates to:
  /// **'No paired Rasgeth yet: pair one in Settings › Nodes (it must lend its storage).'**
  String get syFbNetNoNodes;

  /// No description provided for @syFbNetNode.
  ///
  /// In en, this message translates to:
  /// **'Another Rasgeth'**
  String get syFbNetNode;

  /// No description provided for @syFbNetNotTrusted.
  ///
  /// In en, this message translates to:
  /// **'Test it in Settings › Machines first'**
  String get syFbNetNotTrusted;

  /// No description provided for @syFbNetNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found that already reaches this machine from outside.'**
  String get syFbNetNothing;

  /// No description provided for @syFbNetPick.
  ///
  /// In en, this message translates to:
  /// **'Use for backups'**
  String get syFbNetPick;

  /// No description provided for @syFbNetProxies.
  ///
  /// In en, this message translates to:
  /// **'Running on this machine: {names}.'**
  String syFbNetProxies(String names);

  /// No description provided for @syFbNetProxyFront.
  ///
  /// In en, this message translates to:
  /// **'There is already {name} in front of Rasgeth.'**
  String syFbNetProxyFront(String name);

  /// No description provided for @syFbNetSftp.
  ///
  /// In en, this message translates to:
  /// **'One of your machines'**
  String get syFbNetSftp;

  /// No description provided for @syFbNetSmb.
  ///
  /// In en, this message translates to:
  /// **'Shared folder (SMB)'**
  String get syFbNetSmb;

  /// No description provided for @syFbNetTailscale.
  ///
  /// In en, this message translates to:
  /// **'Tailscale is already running here ({name}): you can use it.'**
  String syFbNetTailscale(String name);

  /// No description provided for @syFbNetTailscaleOff.
  ///
  /// In en, this message translates to:
  /// **'Tailscale is installed here but not connected.'**
  String get syFbNetTailscaleOff;

  /// No description provided for @syFbNetTitle.
  ///
  /// In en, this message translates to:
  /// **'Or a folder on the network'**
  String get syFbNetTitle;

  /// No description provided for @syFbNoDisks.
  ///
  /// In en, this message translates to:
  /// **'No removable disk found. Plug one in and open this page again, or use a folder.'**
  String get syFbNoDisks;

  /// No description provided for @syFbNodeOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline now'**
  String get syFbNodeOffline;

  /// No description provided for @syFbNodeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syFbNodeOnline;

  /// No description provided for @syFbOff.
  ///
  /// In en, this message translates to:
  /// **'Only when I ask'**
  String get syFbOff;

  /// No description provided for @syFbOfferCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud models: always available.'**
  String get syFbOfferCloud;

  /// No description provided for @syFbOfferLocalCpu.
  ///
  /// In en, this message translates to:
  /// **'Local models: yes, small ones on the processor, up to about {max} GB (slower than a card).'**
  String syFbOfferLocalCpu(String max);

  /// No description provided for @syFbOfferLocalGpu.
  ///
  /// In en, this message translates to:
  /// **'Local models: yes, on the graphics card, up to about {max} GB.'**
  String syFbOfferLocalGpu(String max);

  /// No description provided for @syFbOfferNoLocal.
  ///
  /// In en, this message translates to:
  /// **'Local models: not offered, too little memory here. You can still add one from Settings › Models.'**
  String get syFbOfferNoLocal;

  /// No description provided for @syFbPairLater.
  ///
  /// In en, this message translates to:
  /// **'Write the main Rasgeth\'s address and the code it shows in Settings › Nodes › «Add a node». You can also do it later, from Settings.'**
  String get syFbPairLater;

  /// No description provided for @syFbPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get syFbPassword;

  /// No description provided for @syFbPasswordAgain.
  ///
  /// In en, this message translates to:
  /// **'The same password again'**
  String get syFbPasswordAgain;

  /// No description provided for @syFbPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters.'**
  String get syFbPasswordHelp;

  /// No description provided for @syFbPlaceFree.
  ///
  /// In en, this message translates to:
  /// **'{free} GB free of {total}'**
  String syFbPlaceFree(String free, String total);

  /// No description provided for @syFbPlaceNotWritable.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth cannot write here'**
  String get syFbPlaceNotWritable;

  /// No description provided for @syFbPlacesLead.
  ///
  /// In en, this message translates to:
  /// **'Folders the machine hosting Rasgeth mounted under /var/lib/redgiant/backups (a Proxmox mount point, a network share).'**
  String get syFbPlacesLead;

  /// No description provided for @syFbPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Folders mounted for backups'**
  String get syFbPlacesTitle;

  /// No description provided for @syFbPveDo.
  ///
  /// In en, this message translates to:
  /// **'Pass it to Rasgeth'**
  String get syFbPveDo;

  /// No description provided for @syFbPveDone.
  ///
  /// In en, this message translates to:
  /// **'Done: the folder {target} has arrived.'**
  String syFbPveDone(String target);

  /// No description provided for @syFbPveFormat.
  ///
  /// In en, this message translates to:
  /// **'Not formatted: format and pass it'**
  String get syFbPveFormat;

  /// No description provided for @syFbPveFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Everything on it is erased. To go on, type its name: {title}'**
  String syFbPveFormatLabel(String title);

  /// No description provided for @syFbPveFormatQ.
  ///
  /// In en, this message translates to:
  /// **'Format the disk {title}?'**
  String syFbPveFormatQ(String title);

  /// No description provided for @syFbPveFormatYes.
  ///
  /// In en, this message translates to:
  /// **'Format and pass it'**
  String get syFbPveFormatYes;

  /// No description provided for @syFbPveGuess.
  ///
  /// In en, this message translates to:
  /// **'This container is {id}.'**
  String syFbPveGuess(String id);

  /// No description provided for @syFbPveHost.
  ///
  /// In en, this message translates to:
  /// **'{name}: Proxmox {version}.'**
  String syFbPveHost(String name, String version);

  /// No description provided for @syFbPveLead.
  ///
  /// In en, this message translates to:
  /// **'If the Proxmox host is among your machines (Settings › Machines), Rasgeth can run these steps there itself. It asks you first, with every command in the request.'**
  String get syFbPveLead;

  /// No description provided for @syFbPveLook.
  ///
  /// In en, this message translates to:
  /// **'Look for the Proxmox host'**
  String get syFbPveLook;

  /// No description provided for @syFbPveNeedId.
  ///
  /// In en, this message translates to:
  /// **'Write the container id first.'**
  String get syFbPveNeedId;

  /// No description provided for @syFbPveNoDisks.
  ///
  /// In en, this message translates to:
  /// **'No removable disk on that host.'**
  String get syFbPveNoDisks;

  /// No description provided for @syFbPveNone.
  ///
  /// In en, this message translates to:
  /// **'None of your {n} machines is a Proxmox host. Add the host in Settings › Machines (as root, with Rasgeth\'s key), test it, then look again.'**
  String syFbPveNone(String n);

  /// No description provided for @syFbPveQ.
  ///
  /// In en, this message translates to:
  /// **'Pass the disk {title} of {host} to container {id}?'**
  String syFbPveQ(String host, String id, String title);

  /// No description provided for @syFbPveRestart.
  ///
  /// In en, this message translates to:
  /// **'Done on the host. If {target} does not appear in a minute, restart the container from Proxmox.'**
  String syFbPveRestart(String target);

  /// No description provided for @syFbPveText.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth asks you again in your requests, with the exact commands, before running anything on the host.'**
  String get syFbPveText;

  /// No description provided for @syFbPveTitle.
  ///
  /// In en, this message translates to:
  /// **'Do it for me'**
  String get syFbPveTitle;

  /// No description provided for @syFbPveYes.
  ///
  /// In en, this message translates to:
  /// **'Ask me with the commands'**
  String get syFbPveYes;

  /// No description provided for @syFbRamFree.
  ///
  /// In en, this message translates to:
  /// **'{gb} GB free now'**
  String syFbRamFree(String gb);

  /// No description provided for @syFbRamTotal.
  ///
  /// In en, this message translates to:
  /// **'{gb} GB in all'**
  String syFbRamTotal(String gb);

  /// No description provided for @syFbRemovable.
  ///
  /// In en, this message translates to:
  /// **'removable'**
  String get syFbRemovable;

  /// No description provided for @syFbRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get syFbRestore;

  /// No description provided for @syFbRestoreQ.
  ///
  /// In en, this message translates to:
  /// **'Restore the backup of {when}?'**
  String syFbRestoreQ(String when);

  /// No description provided for @syFbRestoreText.
  ///
  /// In en, this message translates to:
  /// **'It is read back first, then projects, agents and conversations that are not here are added. Nothing here is deleted.'**
  String get syFbRestoreText;

  /// No description provided for @syFbRestoreYes.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get syFbRestoreYes;

  /// No description provided for @syFbRoleFull.
  ///
  /// In en, this message translates to:
  /// **'Complete Rasgeth'**
  String get syFbRoleFull;

  /// No description provided for @syFbRoleFullText.
  ///
  /// In en, this message translates to:
  /// **'Agents, projects, chats and everything else, on this machine.'**
  String get syFbRoleFullText;

  /// No description provided for @syFbRoleNode.
  ///
  /// In en, this message translates to:
  /// **'Node of another Rasgeth'**
  String get syFbRoleNode;

  /// No description provided for @syFbRoleNodeText.
  ///
  /// In en, this message translates to:
  /// **'This machine works for a Rasgeth you already have.'**
  String get syFbRoleNodeText;

  /// No description provided for @syFbRoleSettingsLead.
  ///
  /// In en, this message translates to:
  /// **'You can change it at any time: it asks first and says what changes.'**
  String get syFbRoleSettingsLead;

  /// No description provided for @syFbRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get syFbRoleTitle;

  /// No description provided for @syFbSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get syFbSat;

  /// No description provided for @syFbSmbAddress.
  ///
  /// In en, this message translates to:
  /// **'Shared folder'**
  String get syFbSmbAddress;

  /// No description provided for @syFbSmbAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'As Windows writes it (\\\\nas\\backup\\Rasgeth) or smb://nas/backup/Rasgeth.'**
  String get syFbSmbAddressHelp;

  /// No description provided for @syFbSmbDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain or workgroup'**
  String get syFbSmbDomain;

  /// No description provided for @syFbSmbDomainHelp.
  ///
  /// In en, this message translates to:
  /// **'Only if your network needs one (often empty).'**
  String get syFbSmbDomainHelp;

  /// No description provided for @syFbSmbMissing.
  ///
  /// In en, this message translates to:
  /// **'Shared folders need smbclient, which this installation does not have (the Docker image and Rasgeth OS have it). On Windows use the folder field above with \\\\host\\share.'**
  String get syFbSmbMissing;

  /// No description provided for @syFbSmbPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get syFbSmbPassword;

  /// No description provided for @syFbSmbPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'It goes into the keychain only, never into a file or a log.'**
  String get syFbSmbPasswordHelp;

  /// No description provided for @syFbSmbPasswordKept.
  ///
  /// In en, this message translates to:
  /// **'Kept in the keychain: leave it empty to keep it.'**
  String get syFbSmbPasswordKept;

  /// No description provided for @syFbSmbUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get syFbSmbUser;

  /// No description provided for @syFbSshAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add this key'**
  String get syFbSshAddKey;

  /// No description provided for @syFbSshContainer.
  ///
  /// In en, this message translates to:
  /// **'In a container ({name}) SSH reaches the container itself, at its own address, as the user redgiant.'**
  String syFbSshContainer(String name);

  /// No description provided for @syFbSshKey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get syFbSshKey;

  /// No description provided for @syFbSshKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'One line starting with ssh-ed25519, ssh-rsa or ecdsa-sha2 (the .pub file).'**
  String get syFbSshKeyHelp;

  /// No description provided for @syFbSshKeyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'ssh-ed25519 AAAA… me@laptop'**
  String get syFbSshKeyPlaceholder;

  /// No description provided for @syFbSshKeys.
  ///
  /// In en, this message translates to:
  /// **'{n} key(s) allowed'**
  String syFbSshKeys(String n);

  /// No description provided for @syFbSshNeedKey.
  ///
  /// In en, this message translates to:
  /// **'Paste a public key first, then switch it on.'**
  String get syFbSshNeedKey;

  /// No description provided for @syFbSshOffHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste a public key below, then switch it on.'**
  String get syFbSshOffHelp;

  /// No description provided for @syFbSshOn.
  ///
  /// In en, this message translates to:
  /// **'SSH on'**
  String get syFbSshOn;

  /// No description provided for @syFbSshQ.
  ///
  /// In en, this message translates to:
  /// **'To work on the machine itself from a terminal. Off unless you switch it on; keys only, never passwords.'**
  String get syFbSshQ;

  /// No description provided for @syFbSshTitle.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get syFbSshTitle;

  /// No description provided for @syFbSshWhy_no_helper.
  ///
  /// In en, this message translates to:
  /// **'This installation has no Rasgeth OS system helper: SSH is managed by the system hosting it.'**
  String get syFbSshWhy_no_helper;

  /// No description provided for @syFbSshWhy_not_installed.
  ///
  /// In en, this message translates to:
  /// **'SSH (openssh-server) is not installed on this system.'**
  String get syFbSshWhy_not_installed;

  /// No description provided for @syFbSshWhy_other.
  ///
  /// In en, this message translates to:
  /// **'SSH cannot be read here: the system helper answered «{why}».'**
  String syFbSshWhy_other(String why);

  /// No description provided for @syFbSshWhy_timeout.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth OS\'s system helper took too long to answer: try again in a moment.'**
  String get syFbSshWhy_timeout;

  /// No description provided for @syFbSshWhy_unreachable.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth OS\'s system helper does not answer (redgiant-helper.socket): SSH cannot be read or changed now. Restarting the machine usually brings it back.'**
  String get syFbSshWhy_unreachable;

  /// No description provided for @syFbSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get syFbSun;

  /// No description provided for @syFbSystemLead.
  ///
  /// In en, this message translates to:
  /// **'The machine Rasgeth runs on, its role, where its data and backups live, and SSH.'**
  String get syFbSystemLead;

  /// No description provided for @syFbSystemQ.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get syFbSystemQ;

  /// No description provided for @syFbSystemSection.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get syFbSystemSection;

  /// No description provided for @syFbThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get syFbThu;

  /// No description provided for @syFbToFullQ.
  ///
  /// In en, this message translates to:
  /// **'Make this a complete Rasgeth again?'**
  String get syFbToFullQ;

  /// No description provided for @syFbToFullText.
  ///
  /// In en, this message translates to:
  /// **'It stops working for the other Rasgeth; its own agents, projects and conversations come back as they were.'**
  String get syFbToFullText;

  /// No description provided for @syFbToFullYes.
  ///
  /// In en, this message translates to:
  /// **'Make it complete'**
  String get syFbToFullYes;

  /// No description provided for @syFbToNodeQ.
  ///
  /// In en, this message translates to:
  /// **'Make this Rasgeth a node?'**
  String get syFbToNodeQ;

  /// No description provided for @syFbToNodeText.
  ///
  /// In en, this message translates to:
  /// **'It will stop being a Rasgeth of its own once paired: its agents, projects and conversations stay saved, untouched, but they rest until you make it complete again.'**
  String get syFbToNodeText;

  /// No description provided for @syFbToNodeYes.
  ///
  /// In en, this message translates to:
  /// **'Make it a node'**
  String get syFbToNodeYes;

  /// No description provided for @syFbTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get syFbTue;

  /// No description provided for @syFbUseDisk.
  ///
  /// In en, this message translates to:
  /// **'Use for backups'**
  String get syFbUseDisk;

  /// No description provided for @syFbUseFolder.
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get syFbUseFolder;

  /// No description provided for @syFbUsePlace.
  ///
  /// In en, this message translates to:
  /// **'Use for backups'**
  String get syFbUsePlace;

  /// No description provided for @syFbUseShare.
  ///
  /// In en, this message translates to:
  /// **'Use this shared folder'**
  String get syFbUseShare;

  /// No description provided for @syFbVirt.
  ///
  /// In en, this message translates to:
  /// **'Runs on'**
  String get syFbVirt;

  /// No description provided for @syFbVirtContainer.
  ///
  /// In en, this message translates to:
  /// **'a container ({name})'**
  String syFbVirtContainer(String name);

  /// No description provided for @syFbVirtNone.
  ///
  /// In en, this message translates to:
  /// **'a physical machine'**
  String get syFbVirtNone;

  /// No description provided for @syFbVirtVm.
  ///
  /// In en, this message translates to:
  /// **'a virtual machine ({name})'**
  String syFbVirtVm(String name);

  /// No description provided for @syFbWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get syFbWed;

  /// No description provided for @syFbWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get syFbWeekly;

  /// No description provided for @syFbWhenTitle.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get syFbWhenTitle;

  /// No description provided for @syFbWhyFs.
  ///
  /// In en, this message translates to:
  /// **'Format not supported'**
  String get syFbWhyFs;

  /// No description provided for @syFbWhyNoFs.
  ///
  /// In en, this message translates to:
  /// **'Not formatted'**
  String get syFbWhyNoFs;

  /// No description provided for @syFbWhyNoUuid.
  ///
  /// In en, this message translates to:
  /// **'Without an id'**
  String get syFbWhyNoUuid;

  /// No description provided for @syFbWhyNotDisk.
  ///
  /// In en, this message translates to:
  /// **'Not a disk'**
  String get syFbWhyNotDisk;

  /// No description provided for @syFbWhyNotRemovable.
  ///
  /// In en, this message translates to:
  /// **'Not removable'**
  String get syFbWhyNotRemovable;

  /// No description provided for @syFbWhySystem.
  ///
  /// In en, this message translates to:
  /// **'Holds the system'**
  String get syFbWhySystem;

  /// No description provided for @syFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get syFolder;

  /// No description provided for @syGitGiteaAgain.
  ///
  /// In en, this message translates to:
  /// **'The same password again'**
  String get syGitGiteaAgain;

  /// No description provided for @syGitGiteaGuide.
  ///
  /// In en, this message translates to:
  /// **'Open «Your home services»'**
  String get syGitGiteaGuide;

  /// No description provided for @syGitGiteaMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are different.'**
  String get syGitGiteaMismatch;

  /// No description provided for @syInspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get syInspector;

  /// No description provided for @syJob_pihole.
  ///
  /// In en, this message translates to:
  /// **'Starting Pi-hole'**
  String get syJob_pihole;

  /// No description provided for @syJob_remote.
  ///
  /// In en, this message translates to:
  /// **'Opening access from outside'**
  String get syJob_remote;

  /// No description provided for @syJob_step_account.
  ///
  /// In en, this message translates to:
  /// **'Creating your account'**
  String get syJob_step_account;

  /// No description provided for @syJob_step_arrive.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the folder'**
  String get syJob_step_arrive;

  /// No description provided for @syJob_step_ask.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your yes'**
  String get syJob_step_ask;

  /// No description provided for @syJob_step_conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get syJob_step_conversations;

  /// No description provided for @syJob_step_convert.
  ///
  /// In en, this message translates to:
  /// **'Converting'**
  String get syJob_step_convert;

  /// No description provided for @syJob_step_copy.
  ///
  /// In en, this message translates to:
  /// **'Copying the models'**
  String get syJob_step_copy;

  /// No description provided for @syJob_step_data.
  ///
  /// In en, this message translates to:
  /// **'Projects, agents and settings'**
  String get syJob_step_data;

  /// No description provided for @syJob_step_download.
  ///
  /// In en, this message translates to:
  /// **'Downloading the model'**
  String get syJob_step_download;

  /// No description provided for @syJob_step_draft.
  ///
  /// In en, this message translates to:
  /// **'With the small model'**
  String get syJob_step_draft;

  /// No description provided for @syJob_step_fetch.
  ///
  /// In en, this message translates to:
  /// **'Bringing the backup here'**
  String get syJob_step_fetch;

  /// No description provided for @syJob_step_files.
  ///
  /// In en, this message translates to:
  /// **'The projects\' files'**
  String get syJob_step_files;

  /// No description provided for @syJob_step_gitea_image.
  ///
  /// In en, this message translates to:
  /// **'Downloading Gitea (only once)'**
  String get syJob_step_gitea_image;

  /// No description provided for @syJob_step_gitea_start.
  ///
  /// In en, this message translates to:
  /// **'Starting Gitea'**
  String get syJob_step_gitea_start;

  /// No description provided for @syJob_step_image.
  ///
  /// In en, this message translates to:
  /// **'Downloading the engine (only once)'**
  String get syJob_step_image;

  /// No description provided for @syJob_step_image_download.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get syJob_step_image_download;

  /// No description provided for @syJob_step_load.
  ///
  /// In en, this message translates to:
  /// **'Loading the model into memory'**
  String get syJob_step_load;

  /// No description provided for @syJob_step_look.
  ///
  /// In en, this message translates to:
  /// **'Looking at the host'**
  String get syJob_step_look;

  /// No description provided for @syJob_step_model_download.
  ///
  /// In en, this message translates to:
  /// **'The model'**
  String get syJob_step_model_download;

  /// No description provided for @syJob_step_model_prepare.
  ///
  /// In en, this message translates to:
  /// **'Preparing it for the page'**
  String get syJob_step_model_prepare;

  /// No description provided for @syJob_step_move.
  ///
  /// In en, this message translates to:
  /// **'Copying to the new disk'**
  String get syJob_step_move;

  /// No description provided for @syJob_step_ngram.
  ///
  /// In en, this message translates to:
  /// **'With the n-grams'**
  String get syJob_step_ngram;

  /// No description provided for @syJob_step_node_check.
  ///
  /// In en, this message translates to:
  /// **'Checking the video (SHA-256)'**
  String get syJob_step_node_check;

  /// No description provided for @syJob_step_node_copy.
  ///
  /// In en, this message translates to:
  /// **'Copying the files to {node}'**
  String syJob_step_node_copy(String node);

  /// No description provided for @syJob_step_node_fetch.
  ///
  /// In en, this message translates to:
  /// **'Bringing the video back from {node}'**
  String syJob_step_node_fetch(String node);

  /// No description provided for @syJob_step_node_ffmpeg.
  ///
  /// In en, this message translates to:
  /// **'Getting ffmpeg ready on {node}'**
  String syJob_step_node_ffmpeg(String node);

  /// No description provided for @syJob_step_none.
  ///
  /// In en, this message translates to:
  /// **'The model alone'**
  String get syJob_step_none;

  /// No description provided for @syJob_step_ocr_languages.
  ///
  /// In en, this message translates to:
  /// **'The languages'**
  String get syJob_step_ocr_languages;

  /// No description provided for @syJob_step_ocr_program.
  ///
  /// In en, this message translates to:
  /// **'The program'**
  String get syJob_step_ocr_program;

  /// No description provided for @syJob_step_pihole_check.
  ///
  /// In en, this message translates to:
  /// **'Checking that it answers'**
  String get syJob_step_pihole_check;

  /// No description provided for @syJob_step_pihole_image.
  ///
  /// In en, this message translates to:
  /// **'Downloading Pi-hole (only once)'**
  String get syJob_step_pihole_image;

  /// No description provided for @syJob_step_pihole_start.
  ///
  /// In en, this message translates to:
  /// **'Starting Pi-hole'**
  String get syJob_step_pihole_start;

  /// No description provided for @syJob_step_preload.
  ///
  /// In en, this message translates to:
  /// **'Reading the model once, so the first message does not wait for the disk'**
  String get syJob_step_preload;

  /// No description provided for @syJob_step_remote_cert.
  ///
  /// In en, this message translates to:
  /// **'Getting the certificate from Let\'s Encrypt'**
  String get syJob_step_remote_cert;

  /// No description provided for @syJob_step_remote_connect.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Cloudflare'**
  String get syJob_step_remote_connect;

  /// No description provided for @syJob_step_remote_https.
  ///
  /// In en, this message translates to:
  /// **'Getting the safe address (HTTPS)'**
  String get syJob_step_remote_https;

  /// No description provided for @syJob_step_remote_image.
  ///
  /// In en, this message translates to:
  /// **'Downloading what is needed (only once)'**
  String get syJob_step_remote_image;

  /// No description provided for @syJob_step_remote_login.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to sign in to Tailscale'**
  String get syJob_step_remote_login;

  /// No description provided for @syJob_step_remote_start.
  ///
  /// In en, this message translates to:
  /// **'Starting it'**
  String get syJob_step_remote_start;

  /// No description provided for @syJob_step_restore.
  ///
  /// In en, this message translates to:
  /// **'Putting the engine back as it was'**
  String get syJob_step_restore;

  /// No description provided for @syJob_step_run.
  ///
  /// In en, this message translates to:
  /// **'Running the steps on the host'**
  String get syJob_step_run;

  /// No description provided for @syJob_step_searxng_check.
  ///
  /// In en, this message translates to:
  /// **'Checking that it answers'**
  String get syJob_step_searxng_check;

  /// No description provided for @syJob_step_searxng_image.
  ///
  /// In en, this message translates to:
  /// **'Downloading SearXNG (only once)'**
  String get syJob_step_searxng_image;

  /// No description provided for @syJob_step_searxng_start.
  ///
  /// In en, this message translates to:
  /// **'Starting it'**
  String get syJob_step_searxng_start;

  /// No description provided for @syJob_step_start.
  ///
  /// In en, this message translates to:
  /// **'Starting the engine'**
  String get syJob_step_start;

  /// No description provided for @syJob_step_switch.
  ///
  /// In en, this message translates to:
  /// **'Starting the model on Windows'**
  String get syJob_step_switch;

  /// No description provided for @syJob_step_tool_download.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get syJob_step_tool_download;

  /// No description provided for @syJob_step_tool_unpack.
  ///
  /// In en, this message translates to:
  /// **'Unpacking'**
  String get syJob_step_tool_unpack;

  /// No description provided for @syJob_step_try.
  ///
  /// In en, this message translates to:
  /// **'Trying an answer'**
  String get syJob_step_try;

  /// No description provided for @syJob_step_tune.
  ///
  /// In en, this message translates to:
  /// **'Measuring this computer to pick the fastest setting'**
  String get syJob_step_tune;

  /// No description provided for @syJob_step_verify.
  ///
  /// In en, this message translates to:
  /// **'Reading the backup back'**
  String get syJob_step_verify;

  /// No description provided for @syJob_step_video_derive.
  ///
  /// In en, this message translates to:
  /// **'Making the file'**
  String get syJob_step_video_derive;

  /// No description provided for @syJob_step_video_probe.
  ///
  /// In en, this message translates to:
  /// **'Reading the file'**
  String get syJob_step_video_probe;

  /// No description provided for @syJob_step_video_render.
  ///
  /// In en, this message translates to:
  /// **'Rendering with ffmpeg'**
  String get syJob_step_video_render;

  /// No description provided for @syJob_step_video_save.
  ///
  /// In en, this message translates to:
  /// **'Saving it in the project'**
  String get syJob_step_video_save;

  /// No description provided for @syJob_step_video_silences.
  ///
  /// In en, this message translates to:
  /// **'Finding the silences'**
  String get syJob_step_video_silences;

  /// No description provided for @syJob_step_video_sound.
  ///
  /// In en, this message translates to:
  /// **'Taking the sound'**
  String get syJob_step_video_sound;

  /// No description provided for @syJob_step_video_transcribe.
  ///
  /// In en, this message translates to:
  /// **'Writing down the words'**
  String get syJob_step_video_transcribe;

  /// No description provided for @syJob_step_video_wait.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the render before it'**
  String get syJob_step_video_wait;

  /// No description provided for @syKcImported.
  ///
  /// In en, this message translates to:
  /// **'{n} credentials added to the keychain.'**
  String syKcImported(String n);

  /// No description provided for @syKcPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get syKcPassphrase;

  /// No description provided for @syKcPassphraseHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters. Keep it somewhere safe: it cannot be recovered.'**
  String get syKcPassphraseHelp;

  /// No description provided for @syLmRecommended.
  ///
  /// In en, this message translates to:
  /// **'recommended'**
  String get syLmRecommended;

  /// No description provided for @syLoginCode.
  ///
  /// In en, this message translates to:
  /// **'Code from the app (6 digits)'**
  String get syLoginCode;

  /// No description provided for @syMcAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get syMcAdd;

  /// No description provided for @syMcAuthKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get syMcAuthKey;

  /// No description provided for @syMcAuthPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get syMcAuthPassword;

  /// No description provided for @syMcChangedNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get syMcChangedNow;

  /// No description provided for @syMcChangedText.
  ///
  /// In en, this message translates to:
  /// **'Another computer may be in the place of «{name}». Nothing was sent and the connection was refused. Trust the new key only if you know why it changed (the system was reinstalled, the machine was replaced).'**
  String syMcChangedText(String name);

  /// No description provided for @syMcChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger: the machine answered with another key'**
  String get syMcChangedTitle;

  /// No description provided for @syMcChangedWas.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get syMcChangedWas;

  /// No description provided for @syMcCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get syMcCopied;

  /// No description provided for @syMcCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get syMcCopy;

  /// No description provided for @syMcCopyKey.
  ///
  /// In en, this message translates to:
  /// **'Copy the public key'**
  String get syMcCopyKey;

  /// No description provided for @syMcEdit.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get syMcEdit;

  /// No description provided for @syMcEditorLead.
  ///
  /// In en, this message translates to:
  /// **'Where the machine is and who logs in. The key or the password goes straight into the keychain.'**
  String get syMcEditorLead;

  /// No description provided for @syMcEmpty.
  ///
  /// In en, this message translates to:
  /// **'No machine yet. Add one: Rasgeth makes a key for it, you copy its public half onto the machine.'**
  String get syMcEmpty;

  /// No description provided for @syMcFolder.
  ///
  /// In en, this message translates to:
  /// **'Working folder'**
  String get syMcFolder;

  /// No description provided for @syMcFolderHelp.
  ///
  /// In en, this message translates to:
  /// **'Where commands start; deleting outside it always asks you. A full path (/srv/app, ~/app, or on Windows E:\\coding\\site). Leave empty for the home.'**
  String get syMcFolderHelp;

  /// No description provided for @syMcFolderNone.
  ///
  /// In en, this message translates to:
  /// **'the home (every deletion asks you)'**
  String get syMcFolderNone;

  /// No description provided for @syMcHost.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get syMcHost;

  /// No description provided for @syMcHostHelp.
  ///
  /// In en, this message translates to:
  /// **'Its name or IP address on the network.'**
  String get syMcHostHelp;

  /// No description provided for @syMcHostKey.
  ///
  /// In en, this message translates to:
  /// **'Machine\'s key'**
  String get syMcHostKey;

  /// No description provided for @syMcKeyGenerate.
  ///
  /// In en, this message translates to:
  /// **'Make a new key'**
  String get syMcKeyGenerate;

  /// No description provided for @syMcKeyGenerateHelp.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth makes an ed25519 key: you will copy its public half into ~/.ssh/authorized_keys on the machine.'**
  String get syMcKeyGenerateHelp;

  /// No description provided for @syMcKeyKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep the key'**
  String get syMcKeyKeep;

  /// No description provided for @syMcKeyKeepHelp.
  ///
  /// In en, this message translates to:
  /// **'The key kept in the keychain stays as it is.'**
  String get syMcKeyKeepHelp;

  /// No description provided for @syMcKeyPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste a private key'**
  String get syMcKeyPaste;

  /// No description provided for @syMcLead.
  ///
  /// In en, this message translates to:
  /// **'Other computers your agents reach over SSH: a server, a Raspberry Pi, a computer at the office. Keys and passwords stay in the keychain; the agents choose a machine by its name and never see them.'**
  String get syMcLead;

  /// No description provided for @syMcLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get syMcLogin;

  /// No description provided for @syMcLoginGenerated.
  ///
  /// In en, this message translates to:
  /// **'key made by Rasgeth, in the keychain'**
  String get syMcLoginGenerated;

  /// No description provided for @syMcLoginImported.
  ///
  /// In en, this message translates to:
  /// **'your key, in the keychain'**
  String get syMcLoginImported;

  /// No description provided for @syMcLoginPassword.
  ///
  /// In en, this message translates to:
  /// **'password in the keychain'**
  String get syMcLoginPassword;

  /// No description provided for @syMcName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get syMcName;

  /// No description provided for @syMcNameHelp.
  ///
  /// In en, this message translates to:
  /// **'How agents call it: letters, digits, dot, dash, no spaces (web, pi, office).'**
  String get syMcNameHelp;

  /// No description provided for @syMcNew.
  ///
  /// In en, this message translates to:
  /// **'Add a machine'**
  String get syMcNew;

  /// No description provided for @syMcNewKey.
  ///
  /// In en, this message translates to:
  /// **'Make a new key'**
  String get syMcNewKey;

  /// No description provided for @syMcNewKeyQ.
  ///
  /// In en, this message translates to:
  /// **'Make a new key for this machine?'**
  String get syMcNewKeyQ;

  /// No description provided for @syMcNewKeyText.
  ///
  /// In en, this message translates to:
  /// **'The old key stops working here: copy the new public key onto the machine and remove the old one.'**
  String get syMcNewKeyText;

  /// No description provided for @syMcPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Its passphrase (if it has one)'**
  String get syMcPassphrase;

  /// No description provided for @syMcPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get syMcPassword;

  /// No description provided for @syMcPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Kept in the keychain. A key is safer: a password travels at every login.'**
  String get syMcPasswordHelp;

  /// No description provided for @syMcPasswordKept.
  ///
  /// In en, this message translates to:
  /// **'The password in the keychain stays unless you write a new one.'**
  String get syMcPasswordKept;

  /// No description provided for @syMcPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get syMcPort;

  /// No description provided for @syMcPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get syMcPrivateKey;

  /// No description provided for @syMcPrivateKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'OpenSSH or PEM. It goes into the keychain and is never shown again.'**
  String get syMcPrivateKeyHelp;

  /// No description provided for @syMcPrivateKeyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'-----BEGIN OPENSSH PRIVATE KEY-----'**
  String get syMcPrivateKeyPlaceholder;

  /// No description provided for @syMcProject.
  ///
  /// In en, this message translates to:
  /// **'project'**
  String get syMcProject;

  /// No description provided for @syMcPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get syMcPublicKey;

  /// No description provided for @syMcPublicKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Copy it into ~/.ssh/authorized_keys of the user on the machine (one line), then test the connection.'**
  String get syMcPublicKeyHelp;

  /// No description provided for @syMcRemoveQ.
  ///
  /// In en, this message translates to:
  /// **'Remove «{name}»?'**
  String syMcRemoveQ(String name);

  /// No description provided for @syMcRemoveText.
  ///
  /// In en, this message translates to:
  /// **'Its key or password leaves the keychain; agents can no longer use it. Remove the public key from the machine too.'**
  String get syMcRemoveText;

  /// No description provided for @syMcReplaceQ.
  ///
  /// In en, this message translates to:
  /// **'Trust the new key of «{name}»?'**
  String syMcReplaceQ(String name);

  /// No description provided for @syMcReplaceText.
  ///
  /// In en, this message translates to:
  /// **'Do it only if you know why the machine\'s key changed: otherwise someone could be reading what Rasgeth sends.'**
  String get syMcReplaceText;

  /// No description provided for @syMcReplaceYes.
  ///
  /// In en, this message translates to:
  /// **'Trust the new key'**
  String get syMcReplaceYes;

  /// No description provided for @syMcSafety.
  ///
  /// In en, this message translates to:
  /// **'What happens there follows the same rules as here: sudo, switching the machine off, installing system programs, changing its system files and deleting outside its working folder always ask you, also with «Don\'t ask me anything».'**
  String get syMcSafety;

  /// No description provided for @syMcSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get syMcSave;

  /// No description provided for @syMcSection.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get syMcSection;

  /// No description provided for @syMcStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Last test failed'**
  String get syMcStateFailed;

  /// No description provided for @syMcStateNew.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get syMcStateNew;

  /// No description provided for @syMcStateTrusted.
  ///
  /// In en, this message translates to:
  /// **'Key trusted'**
  String get syMcStateTrusted;

  /// No description provided for @syMcTest.
  ///
  /// In en, this message translates to:
  /// **'Test the connection'**
  String get syMcTest;

  /// No description provided for @syMcTestAuth.
  ///
  /// In en, this message translates to:
  /// **'The machine refused the login: is the public key in ~/.ssh/authorized_keys (or the password right)?'**
  String get syMcTestAuth;

  /// No description provided for @syMcTestError.
  ///
  /// In en, this message translates to:
  /// **'It did not work: {message}'**
  String syMcTestError(String message);

  /// No description provided for @syMcTestNoSecret.
  ///
  /// In en, this message translates to:
  /// **'There is no key or password in the keychain for this machine: change it and set one.'**
  String get syMcTestNoSecret;

  /// No description provided for @syMcTestOk.
  ///
  /// In en, this message translates to:
  /// **'Connected: {system}'**
  String syMcTestOk(String system);

  /// No description provided for @syMcTestTimeout.
  ///
  /// In en, this message translates to:
  /// **'The machine did not answer in time.'**
  String get syMcTestTimeout;

  /// No description provided for @syMcTestUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The machine cannot be reached: check the address and that it is on.'**
  String get syMcTestUnreachable;

  /// No description provided for @syMcTesting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get syMcTesting;

  /// No description provided for @syMcTitle.
  ///
  /// In en, this message translates to:
  /// **'Your machines'**
  String get syMcTitle;

  /// No description provided for @syMcTofuHow.
  ///
  /// In en, this message translates to:
  /// **'To see it on the machine: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub'**
  String get syMcTofuHow;

  /// No description provided for @syMcTofuText.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent yet. If the fingerprint is the machine\'s, trust it: from now on Rasgeth connects only to a machine with this key.'**
  String get syMcTofuText;

  /// No description provided for @syMcTofuTitle.
  ///
  /// In en, this message translates to:
  /// **'First connection: is this the machine\'s key?'**
  String get syMcTofuTitle;

  /// No description provided for @syMcTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust this key'**
  String get syMcTrust;

  /// No description provided for @syMcUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get syMcUser;

  /// No description provided for @syMcWho.
  ///
  /// In en, this message translates to:
  /// **'Who may use it'**
  String get syMcWho;

  /// No description provided for @syMcWhoAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get syMcWhoAgents;

  /// No description provided for @syMcWhoEveryone.
  ///
  /// In en, this message translates to:
  /// **'Every agent'**
  String get syMcWhoEveryone;

  /// No description provided for @syMcWhoEveryoneHelp.
  ///
  /// In en, this message translates to:
  /// **'God, the assistants and every project\'s agents.'**
  String get syMcWhoEveryoneHelp;

  /// No description provided for @syMcWhoLead.
  ///
  /// In en, this message translates to:
  /// **'The agents not chosen do not even see it.'**
  String get syMcWhoLead;

  /// No description provided for @syMcWhoNoAgents.
  ///
  /// In en, this message translates to:
  /// **'There are no agents yet.'**
  String get syMcWhoNoAgents;

  /// No description provided for @syMcWhoNobody.
  ///
  /// In en, this message translates to:
  /// **'nobody yet'**
  String get syMcWhoNobody;

  /// No description provided for @syMcWhoProjects.
  ///
  /// In en, this message translates to:
  /// **'Every agent of these projects'**
  String get syMcWhoProjects;

  /// No description provided for @syNdAddButton.
  ///
  /// In en, this message translates to:
  /// **'Show a pairing code'**
  String get syNdAddButton;

  /// No description provided for @syNdAddLead.
  ///
  /// In en, this message translates to:
  /// **'On the other machine, in its first start (role «Node of another Rasgeth») or in its Settings › Nodes, write this machine\'s address and the code below.'**
  String get syNdAddLead;

  /// No description provided for @syNdAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a node'**
  String get syNdAddTitle;

  /// No description provided for @syNdAddress.
  ///
  /// In en, this message translates to:
  /// **'The other Rasgeth\'s address'**
  String get syNdAddress;

  /// No description provided for @syNdAddressPh.
  ///
  /// In en, this message translates to:
  /// **'https://rasgeth.local or 192.168.1.10:3000'**
  String get syNdAddressPh;

  /// No description provided for @syNdAdmin.
  ///
  /// In en, this message translates to:
  /// **'uses and manages'**
  String get syNdAdmin;

  /// No description provided for @syNdBackupDone.
  ///
  /// In en, this message translates to:
  /// **'Copied to the node: {name}'**
  String syNdBackupDone(String name);

  /// No description provided for @syNdBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Copy now'**
  String get syNdBackupNow;

  /// No description provided for @syNdBackupsOn.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get syNdBackupsOn;

  /// No description provided for @syNdCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get syNdCode;

  /// No description provided for @syNdCodeAddress.
  ///
  /// In en, this message translates to:
  /// **'This machine\'s address, as the other one reaches it (in the local network, through Tailscale or a proxy): {address}'**
  String syNdCodeAddress(String address);

  /// No description provided for @syNdCodeExpires.
  ///
  /// In en, this message translates to:
  /// **'Valid once, for {min} more minutes.'**
  String syNdCodeExpires(String min);

  /// No description provided for @syNdCodeField.
  ///
  /// In en, this message translates to:
  /// **'Its code'**
  String get syNdCodeField;

  /// No description provided for @syNdCodePh.
  ///
  /// In en, this message translates to:
  /// **'ABCD-EFGH'**
  String get syNdCodePh;

  /// No description provided for @syNdCodeStop.
  ///
  /// In en, this message translates to:
  /// **'Stop showing it'**
  String get syNdCodeStop;

  /// No description provided for @syNdCommandsOn.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get syNdCommandsOn;

  /// No description provided for @syNdConfirm.
  ///
  /// In en, this message translates to:
  /// **'They match: confirm'**
  String get syNdConfirm;

  /// No description provided for @syNdConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get syNdConnecting;

  /// No description provided for @syNdControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get syNdControl;

  /// No description provided for @syNdControlLead.
  ///
  /// In en, this message translates to:
  /// **'Never implicit: a machine commands another only with this grant, which the commanded machine keeps and can take away.'**
  String get syNdControlLead;

  /// No description provided for @syNdControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Who may command {name}'**
  String syNdControlTitle(String name);

  /// No description provided for @syNdController.
  ///
  /// In en, this message translates to:
  /// **'Which machine'**
  String get syNdController;

  /// No description provided for @syNdCpu.
  ///
  /// In en, this message translates to:
  /// **'{n} CPU'**
  String syNdCpu(String n);

  /// No description provided for @syNdFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Its key\'s fingerprint'**
  String get syNdFingerprint;

  /// No description provided for @syNdFree.
  ///
  /// In en, this message translates to:
  /// **'{n} GB free'**
  String syNdFree(String n);

  /// No description provided for @syNdGive.
  ///
  /// In en, this message translates to:
  /// **'Give'**
  String get syNdGive;

  /// No description provided for @syNdGrantsHere.
  ///
  /// In en, this message translates to:
  /// **'Who may command this machine'**
  String get syNdGrantsHere;

  /// No description provided for @syNdGrantsLead.
  ///
  /// In en, this message translates to:
  /// **'Only these machines may use this one, each with what the person gave it. Taking it away works at once.'**
  String get syNdGrantsLead;

  /// No description provided for @syNdHere.
  ///
  /// In en, this message translates to:
  /// **'Here'**
  String get syNdHere;

  /// No description provided for @syNdJoinLead.
  ///
  /// In en, this message translates to:
  /// **'Pair this machine as a node of another Rasgeth: on that one, Settings › Nodes › «Add a node» shows its address and a code.'**
  String get syNdJoinLead;

  /// No description provided for @syNdJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Work for another Rasgeth'**
  String get syNdJoinTitle;

  /// No description provided for @syNdLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String syNdLastSeen(String when);

  /// No description provided for @syNdLead.
  ///
  /// In en, this message translates to:
  /// **'Other Rasgeth machines that work with this one: they lend commands, local models and room for projects and backups. Who may command whom is decided here, machine by machine.'**
  String get syNdLead;

  /// No description provided for @syNdLoad.
  ///
  /// In en, this message translates to:
  /// **'load {n}%'**
  String syNdLoad(String n);

  /// No description provided for @syNdModels.
  ///
  /// In en, this message translates to:
  /// **'{n} models'**
  String syNdModels(String n);

  /// No description provided for @syNdName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get syNdName;

  /// No description provided for @syNdNameHelp.
  ///
  /// In en, this message translates to:
  /// **'How the other machines and the agents call it.'**
  String get syNdNameHelp;

  /// No description provided for @syNdNoContainer.
  ///
  /// In en, this message translates to:
  /// **'commands only for who manages it'**
  String get syNdNoContainer;

  /// No description provided for @syNdNoContainerHelp.
  ///
  /// In en, this message translates to:
  /// **'There is no container there (no Docker): it runs commands only for a machine that manages it, on the machine itself. With «use» alone, files, storage and models only.'**
  String get syNdNoContainerHelp;

  /// No description provided for @syNdNoNodes.
  ///
  /// In en, this message translates to:
  /// **'No node yet.'**
  String get syNdNoNodes;

  /// No description provided for @syNdNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No project yet.'**
  String get syNdNoProjects;

  /// No description provided for @syNdNoRights.
  ///
  /// In en, this message translates to:
  /// **'No permissions'**
  String get syNdNoRights;

  /// No description provided for @syNdNoSandbox.
  ///
  /// In en, this message translates to:
  /// **'no commands'**
  String get syNdNoSandbox;

  /// No description provided for @syNdNodeName.
  ///
  /// In en, this message translates to:
  /// **'Name of the node'**
  String get syNdNodeName;

  /// No description provided for @syNdNodeNameHelp.
  ///
  /// In en, this message translates to:
  /// **'How you, the agents and the requests call it here. Empty: the name it gives itself.'**
  String get syNdNodeNameHelp;

  /// No description provided for @syNdNotReady.
  ///
  /// In en, this message translates to:
  /// **'Nodes need the keychain: this machine\'s key lives only there. Open it in Settings › Keychain.'**
  String get syNdNotReady;

  /// No description provided for @syNdOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syNdOffline;

  /// No description provided for @syNdOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syNdOnline;

  /// No description provided for @syNdPair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get syNdPair;

  /// No description provided for @syNdPairing.
  ///
  /// In en, this message translates to:
  /// **'Pairing…'**
  String get syNdPairing;

  /// No description provided for @syNdParent.
  ///
  /// In en, this message translates to:
  /// **'Works for'**
  String get syNdParent;

  /// No description provided for @syNdPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the yes on the other machine'**
  String get syNdPending;

  /// No description provided for @syNdPendingFromNode.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to be a node of this machine'**
  String syNdPendingFromNode(String name);

  /// No description provided for @syNdPendingFromPrincipal.
  ///
  /// In en, this message translates to:
  /// **'This machine will work for {name}'**
  String syNdPendingFromPrincipal(String name);

  /// No description provided for @syNdPendingLead.
  ///
  /// In en, this message translates to:
  /// **'Both machines show the same six digits and each other\'s fingerprint. If they match on both screens, confirm on both: nothing is used before.'**
  String get syNdPendingLead;

  /// No description provided for @syNdPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare and confirm'**
  String get syNdPendingTitle;

  /// No description provided for @syNdPlaces.
  ///
  /// In en, this message translates to:
  /// **'Where things run'**
  String get syNdPlaces;

  /// No description provided for @syNdPlacesLead.
  ///
  /// In en, this message translates to:
  /// **'For each project: by default everything stays here. A node pinned for commands is where its agents\' node_run goes; one for backups keeps copies of its files.'**
  String get syNdPlacesLead;

  /// No description provided for @syNdQ.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get syNdQ;

  /// No description provided for @syNdRam.
  ///
  /// In en, this message translates to:
  /// **'{n} GB RAM'**
  String syNdRam(String n);

  /// No description provided for @syNdReason.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get syNdReason;

  /// No description provided for @syNdRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused: its key changed'**
  String get syNdRefused;

  /// No description provided for @syNdReject.
  ///
  /// In en, this message translates to:
  /// **'They do not match'**
  String get syNdReject;

  /// No description provided for @syNdRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get syNdRename;

  /// No description provided for @syNdRenameQ.
  ///
  /// In en, this message translates to:
  /// **'A name for {name}'**
  String syNdRenameQ(String name);

  /// No description provided for @syNdRenderOn.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get syNdRenderOn;

  /// No description provided for @syNdRevoke.
  ///
  /// In en, this message translates to:
  /// **'Take away'**
  String get syNdRevoke;

  /// No description provided for @syNdRevokeQ.
  ///
  /// In en, this message translates to:
  /// **'Take away what {name} may do here?'**
  String syNdRevokeQ(String name);

  /// No description provided for @syNdRightAdmin.
  ///
  /// In en, this message translates to:
  /// **'Manage it'**
  String get syNdRightAdmin;

  /// No description provided for @syNdRightAdminHelp.
  ///
  /// In en, this message translates to:
  /// **'Give and take away the control of this machine to other machines, and write outside the sandbox.'**
  String get syNdRightAdminHelp;

  /// No description provided for @syNdRightUse.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get syNdRightUse;

  /// No description provided for @syNdRightUseHelp.
  ///
  /// In en, this message translates to:
  /// **'Run its agents\' commands in a sandbox here, use its models and keep files here.'**
  String get syNdRightUseHelp;

  /// No description provided for @syNdRights.
  ///
  /// In en, this message translates to:
  /// **'What it may do'**
  String get syNdRights;

  /// No description provided for @syNdRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'What {name} may do on this machine'**
  String syNdRightsTitle(String name);

  /// No description provided for @syNdSas.
  ///
  /// In en, this message translates to:
  /// **'The six digits'**
  String get syNdSas;

  /// No description provided for @syNdSection.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get syNdSection;

  /// No description provided for @syNdTheirFp.
  ///
  /// In en, this message translates to:
  /// **'The other machine\'s fingerprint'**
  String get syNdTheirFp;

  /// No description provided for @syNdThis.
  ///
  /// In en, this message translates to:
  /// **'This machine'**
  String get syNdThis;

  /// No description provided for @syNdTree.
  ///
  /// In en, this message translates to:
  /// **'The tree'**
  String get syNdTree;

  /// No description provided for @syNdTreeLead.
  ///
  /// In en, this message translates to:
  /// **'This machine, its nodes and theirs. Control is separate: it is shown under each machine.'**
  String get syNdTreeLead;

  /// No description provided for @syNdUnpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get syNdUnpair;

  /// No description provided for @syNdUnpairQ.
  ///
  /// In en, this message translates to:
  /// **'Unpair {name}?'**
  String syNdUnpairQ(String name);

  /// No description provided for @syNdUnpairText.
  ///
  /// In en, this message translates to:
  /// **'The two machines forget each other: links, grants and placements with it go. Its files stay where they are. To pair again, a new code.'**
  String get syNdUnpairText;

  /// No description provided for @syNdUse.
  ///
  /// In en, this message translates to:
  /// **'uses'**
  String get syNdUse;

  /// No description provided for @syNdWho.
  ///
  /// In en, this message translates to:
  /// **'Who may command it'**
  String get syNdWho;

  /// No description provided for @syNdWhoNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody but itself'**
  String get syNdWhoNobody;

  /// No description provided for @syOiAddress.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth\'s address in the network'**
  String get syOiAddress;

  /// No description provided for @syOiAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Where the proxy or the VPN finds Rasgeth; its port is {port}.'**
  String syOiAddressHelp(String port);

  /// No description provided for @syOiAuthCaddy.
  ///
  /// In en, this message translates to:
  /// **'Caddyfile with forward auth (Authelia), leaving out the app\'s paths'**
  String get syOiAuthCaddy;

  /// No description provided for @syOiAuthIf.
  ///
  /// In en, this message translates to:
  /// **'If you want it anyway, leave /api/ and /ws out of it: forward auth then guards the page, and Rasgeth\'s password everything else.'**
  String get syOiAuthIf;

  /// No description provided for @syOiAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Authelia, Authentik or another forward auth in front?'**
  String get syOiAuthTitle;

  /// No description provided for @syOiAuthWhy.
  ///
  /// In en, this message translates to:
  /// **'Better not: Rasgeth has its own password, with limited tries and the optional code from an authenticator app, and a sign-in in front of it blocks the app, the command line, ACP agents, the browser extension and the webhooks (Telegram, WhatsApp, automations), which come in with their own tokens.'**
  String get syOiAuthWhy;

  /// No description provided for @syOiCaddy.
  ///
  /// In en, this message translates to:
  /// **'Caddyfile: a site of its own'**
  String get syOiCaddy;

  /// No description provided for @syOiCaddyReload.
  ///
  /// In en, this message translates to:
  /// **'Then reload Caddy (caddy reload, or restart its container).'**
  String get syOiCaddyReload;

  /// No description provided for @syOiCaddyWildcard.
  ///
  /// In en, this message translates to:
  /// **'Caddyfile: inside a wildcard site you already have (*.{domain})'**
  String syOiCaddyWildcard(String domain);

  /// No description provided for @syOiCheck.
  ///
  /// In en, this message translates to:
  /// **'Check that it answers'**
  String get syOiCheck;

  /// No description provided for @syOiCheckAnswers.
  ///
  /// In en, this message translates to:
  /// **'Something answers at this address (the browser does not let the page read who): open it to see Rasgeth.'**
  String get syOiCheckAnswers;

  /// No description provided for @syOiCheckGo.
  ///
  /// In en, this message translates to:
  /// **'Check {url} from here'**
  String syOiCheckGo(String url);

  /// No description provided for @syOiCheckLead.
  ///
  /// In en, this message translates to:
  /// **'From any computer: Rasgeth answers {lb}\"ok\":true,…{rb}.'**
  String syOiCheckLead(String lb, String rb);

  /// No description provided for @syOiCheckNo.
  ///
  /// In en, this message translates to:
  /// **'No answer from this browser: check the name in the DNS, the proxy\'s block and, from outside, the VPN.'**
  String get syOiCheckNo;

  /// No description provided for @syOiCheckRedgiant.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth answers at this address.'**
  String get syOiCheckRedgiant;

  /// No description provided for @syOiClose.
  ///
  /// In en, this message translates to:
  /// **'Hide the guide'**
  String get syOiClose;

  /// No description provided for @syOiCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get syOiCopied;

  /// No description provided for @syOiCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get syOiCopy;

  /// No description provided for @syOiDnsAdguard.
  ///
  /// In en, this message translates to:
  /// **'AdGuard Home: Filters › DNS rewrites: *.{domain} or the single name → {address}.'**
  String syOiDnsAdguard(String address, String domain);

  /// No description provided for @syOiDnsLead.
  ///
  /// In en, this message translates to:
  /// **'A name instead of an address: point it to the proxy when there is one, otherwise to Rasgeth\'s address.'**
  String get syOiDnsLead;

  /// No description provided for @syOiDnsPihole.
  ///
  /// In en, this message translates to:
  /// **'Pi-hole: Settings › Local DNS › DNS Records: {name} → {address}.'**
  String syOiDnsPihole(String address, String name);

  /// No description provided for @syOiDnsRouter.
  ///
  /// In en, this message translates to:
  /// **'The router: its «static DNS», «local names» or DHCP reservation page (the name varies by router).'**
  String get syOiDnsRouter;

  /// No description provided for @syOiDnsTs.
  ///
  /// In en, this message translates to:
  /// **'Away from home with Tailscale: add the home DNS in Tailscale\'s DNS › Nameservers, restricted to your domain, so the same names work outside too.'**
  String get syOiDnsTs;

  /// No description provided for @syOiDnsWildcard.
  ///
  /// In en, this message translates to:
  /// **'Pi-hole or dnsmasq, every name of *.{domain} at once (a file in /etc/dnsmasq.d/)'**
  String syOiDnsWildcard(String domain);

  /// No description provided for @syOiHomeAdguard.
  ///
  /// In en, this message translates to:
  /// **'AdGuard Home: Filters › DNS rewrites: {name} → {address}.'**
  String syOiHomeAdguard(String address, String name);

  /// No description provided for @syOiHomeDnsmasq.
  ///
  /// In en, this message translates to:
  /// **'dnsmasq (or a file in Pi-hole\'s /etc/dnsmasq.d/)'**
  String get syOiHomeDnsmasq;

  /// No description provided for @syOiHomeHosts.
  ///
  /// In en, this message translates to:
  /// **'Pi-hole\'s records or /etc/hosts, by hand'**
  String get syOiHomeHosts;

  /// No description provided for @syOiHomeLookup.
  ///
  /// In en, this message translates to:
  /// **'On Rasgeth OS, what its DNS answers for the name'**
  String get syOiHomeLookup;

  /// No description provided for @syOiHomePihole.
  ///
  /// In en, this message translates to:
  /// **'Pi-hole: Settings › Local DNS › DNS Records: {name} → {address}.'**
  String syOiHomePihole(String address, String name);

  /// No description provided for @syOiHomeRouter.
  ///
  /// In en, this message translates to:
  /// **'The router: its «static DNS» or «local names» page: {name} → {address}.'**
  String syOiHomeRouter(String address, String name);

  /// No description provided for @syOiHomeSeen.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth asks the name server {dns}.'**
  String syOiHomeSeen(String dns);

  /// No description provided for @syOiHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your home services (Gitea, NAS…) seen by Rasgeth'**
  String get syOiHomeTitle;

  /// No description provided for @syOiHomeTs.
  ///
  /// In en, this message translates to:
  /// **'If your Pi-hole answers with Tailscale addresses (100.…), those work only for devices in Tailscale: add a local record with the address in your network as above, or let Rasgeth\'s machine use the router as DNS with the name there.'**
  String get syOiHomeTs;

  /// No description provided for @syOiHomeV6.
  ///
  /// In en, this message translates to:
  /// **'A router that answers «does not exist» to the IPv6 (AAAA) question for names added by hand: Rasgeth OS handles it already; on other systems with systemd-resolved, put Cache=no-negative in a file of /etc/systemd/resolved.conf.d/, or the name seems missing for a while.'**
  String get syOiHomeV6;

  /// No description provided for @syOiHomeWhat.
  ///
  /// In en, this message translates to:
  /// **'In the DNS Rasgeth uses, give the name that local address:'**
  String get syOiHomeWhat;

  /// No description provided for @syOiHomeWhich.
  ///
  /// In en, this message translates to:
  /// **'Which DNS Rasgeth uses: on Rasgeth OS the console (or SSH) shows it with the command below, under «Current DNS Server»; on another computer it is that computer\'s DNS (its network settings, /etc/resolv.conf on Linux). «Try a name» asks the very DNS Rasgeth uses.'**
  String get syOiHomeWhich;

  /// No description provided for @syOiHomeWhichCmd.
  ///
  /// In en, this message translates to:
  /// **'On Rasgeth OS, which DNS it uses'**
  String get syOiHomeWhichCmd;

  /// No description provided for @syOiHomeWhy.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth reaches your Gitea, NAS or other services by name, through the DNS of the machine it runs on (often the router). A name your phone opens may be unknown there, or point to an address Rasgeth cannot reach: then «A Gitea you already have» fails even though the service works.'**
  String get syOiHomeWhy;

  /// No description provided for @syOiLead.
  ///
  /// In en, this message translates to:
  /// **'A reverse proxy, a VPN, a home DNS: if you already reach your machines that way, Rasgeth goes behind them like any other service. Here are the blocks to copy.'**
  String get syOiLead;

  /// No description provided for @syOiName.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth\'s name'**
  String get syOiName;

  /// No description provided for @syOiNameHelp.
  ///
  /// In en, this message translates to:
  /// **'The name you will open, e.g. rasgeth.home.example.com.'**
  String get syOiNameHelp;

  /// No description provided for @syOiNpm1.
  ///
  /// In en, this message translates to:
  /// **'Hosts › Proxy Hosts › Add Proxy Host; Domain Names: {name}.'**
  String syOiNpm1(String name);

  /// No description provided for @syOiNpm2.
  ///
  /// In en, this message translates to:
  /// **'Scheme http, Forward Hostname / IP {address}, Forward Port {port}.'**
  String syOiNpm2(String address, String port);

  /// No description provided for @syOiNpm3.
  ///
  /// In en, this message translates to:
  /// **'Switch on «Websockets Support» (Rasgeth\'s page lives on a WebSocket) and «Block Common Exploits».'**
  String get syOiNpm3;

  /// No description provided for @syOiNpm4.
  ///
  /// In en, this message translates to:
  /// **'SSL: «Request a new SSL Certificate», «Force SSL», «HTTP/2 Support». Save.'**
  String get syOiNpm4;

  /// No description provided for @syOiOpen.
  ///
  /// In en, this message translates to:
  /// **'Show the guide'**
  String get syOiOpen;

  /// No description provided for @syOiOtherVpn.
  ///
  /// In en, this message translates to:
  /// **'WireGuard, ZeroTier and the others'**
  String get syOiOtherVpn;

  /// No description provided for @syOiOtherVpnLead.
  ///
  /// In en, this message translates to:
  /// **'The same idea: with the home network {subnet} in the peer\'s AllowedIPs (WireGuard) or as a managed route (ZeroTier), Rasgeth opens at its home address.'**
  String syOiOtherVpnLead(String subnet);

  /// No description provided for @syOiPart.
  ///
  /// In en, this message translates to:
  /// **'What you have'**
  String get syOiPart;

  /// No description provided for @syOiPartDns.
  ///
  /// In en, this message translates to:
  /// **'Home DNS'**
  String get syOiPartDns;

  /// No description provided for @syOiPartHome.
  ///
  /// In en, this message translates to:
  /// **'Your home services'**
  String get syOiPartHome;

  /// No description provided for @syOiPartProxy.
  ///
  /// In en, this message translates to:
  /// **'Reverse proxy'**
  String get syOiPartProxy;

  /// No description provided for @syOiPartVpn.
  ///
  /// In en, this message translates to:
  /// **'Tailscale or another VPN'**
  String get syOiPartVpn;

  /// No description provided for @syOiProbe.
  ///
  /// In en, this message translates to:
  /// **'Try a name'**
  String get syOiProbe;

  /// No description provided for @syOiProbeBad.
  ///
  /// In en, this message translates to:
  /// **'That is not a name (for instance git.home.example.com).'**
  String get syOiProbeBad;

  /// No description provided for @syOiProbeDnsFailed.
  ///
  /// In en, this message translates to:
  /// **'The DNS Rasgeth uses did not answer for {name}. Check that it works, then try again.'**
  String syOiProbeDnsFailed(String name);

  /// No description provided for @syOiProbeGo.
  ///
  /// In en, this message translates to:
  /// **'Try {name}'**
  String syOiProbeGo(String name);

  /// No description provided for @syOiProbeLead.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth looks the name up and opens https://{name} from where it runs, as it does for your Gitea. Nothing of the answer is kept or shown but its code.'**
  String syOiProbeLead(String name);

  /// No description provided for @syOiProbeNotFound.
  ///
  /// In en, this message translates to:
  /// **'The DNS Rasgeth uses does not know {name}. Add the name there (router, Pi-hole or AdGuard) with the proxy\'s local address, then try again.'**
  String syOiProbeNotFound(String name);

  /// No description provided for @syOiProbeOk.
  ///
  /// In en, this message translates to:
  /// **'Fine: here {name} is {address}, and https://{name} answered (HTTP {status}).'**
  String syOiProbeOk(String address, String name, String status);

  /// No description provided for @syOiProbeTailscale.
  ///
  /// In en, this message translates to:
  /// **'Here {name} is {address}: a Tailscale address, which Rasgeth cannot reach. In the DNS Rasgeth uses, give the name the proxy\'s local address.'**
  String syOiProbeTailscale(String address, String name);

  /// No description provided for @syOiProbeTimeout.
  ///
  /// In en, this message translates to:
  /// **'Here {name} is {address}, but it did not answer in time: probably an address Rasgeth cannot reach (another network, a VPN).'**
  String syOiProbeTimeout(String address, String name);

  /// No description provided for @syOiProbeTls.
  ///
  /// In en, this message translates to:
  /// **'Here {name} is {address} and answers, but with a certificate Rasgeth does not trust (made by hand?). Give the proxy a certificate from a public authority (Let\'s Encrypt).'**
  String syOiProbeTls(String address, String name);

  /// No description provided for @syOiProbeUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Here {name} is {address}, but nothing answers on https from Rasgeth. Check that it is the proxy\'s local address and that the proxy is running.'**
  String syOiProbeUnreachable(String address, String name);

  /// No description provided for @syOiProxyAddr.
  ///
  /// In en, this message translates to:
  /// **'The proxy\'s local address'**
  String get syOiProxyAddr;

  /// No description provided for @syOiProxyAddrHelp.
  ///
  /// In en, this message translates to:
  /// **'The address in your network (192.168.…) of the proxy in front of the service, or of the service itself. Not a Tailscale address (100.…): Rasgeth reaches it only if it is in Tailscale too.'**
  String get syOiProxyAddrHelp;

  /// No description provided for @syOiProxyLead.
  ///
  /// In en, this message translates to:
  /// **'The proxy can be on another machine: it only needs to reach Rasgeth\'s address. It gets the certificate (HTTPS) and sends everything on, the WebSocket included.'**
  String get syOiProxyLead;

  /// No description provided for @syOiReachedAs.
  ///
  /// In en, this message translates to:
  /// **'You are reachable already as {host}.'**
  String syOiReachedAs(String host);

  /// No description provided for @syOiReachedName.
  ///
  /// In en, this message translates to:
  /// **'This page came with a name of your network: at home it works already; from outside one of the ways below is needed (Tailscale, for instance).'**
  String get syOiReachedName;

  /// No description provided for @syOiReachedProxy.
  ///
  /// In en, this message translates to:
  /// **'This page came through a reverse proxy of your network: the guide below is filled with what Rasgeth saw.'**
  String get syOiReachedProxy;

  /// No description provided for @syOiSaid.
  ///
  /// In en, this message translates to:
  /// **'You said Rasgeth is reachable already your own way: it does not ask again to set up its ways.'**
  String get syOiSaid;

  /// No description provided for @syOiSaidUndo.
  ///
  /// In en, this message translates to:
  /// **'Ask again'**
  String get syOiSaidUndo;

  /// No description provided for @syOiSaidUrl.
  ///
  /// In en, this message translates to:
  /// **'You said Rasgeth is reachable already at {url}: it does not ask again to set up its ways, and its links (Telegram…) use that address.'**
  String syOiSaidUrl(String url);

  /// No description provided for @syOiService.
  ///
  /// In en, this message translates to:
  /// **'The service\'s name'**
  String get syOiService;

  /// No description provided for @syOiServiceHelp.
  ///
  /// In en, this message translates to:
  /// **'As you open it, e.g. git.home.example.com.'**
  String get syOiServiceHelp;

  /// No description provided for @syOiSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip: I am reachable already'**
  String get syOiSkip;

  /// No description provided for @syOiSkipNote.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth stops asking to set up its own ways out (Tailscale, Cloudflare, its own domain); they stay here if you want one later.'**
  String get syOiSkipNote;

  /// No description provided for @syOiTitle.
  ///
  /// In en, this message translates to:
  /// **'Already have your own infrastructure'**
  String get syOiTitle;

  /// No description provided for @syOiTraefik.
  ///
  /// In en, this message translates to:
  /// **'Traefik: file provider (dynamic configuration)'**
  String get syOiTraefik;

  /// No description provided for @syOiTraefikNote.
  ///
  /// In en, this message translates to:
  /// **'With Docker labels instead: the same rule and the URL as a service with loadbalancer.server.url. Use your entry point and certificate resolver names.'**
  String get syOiTraefikNote;

  /// No description provided for @syOiTsHere.
  ///
  /// In en, this message translates to:
  /// **'Tailscale on Rasgeth\'s machine'**
  String get syOiTsHere;

  /// No description provided for @syOiTsHereLead.
  ///
  /// In en, this message translates to:
  /// **'Install Tailscale on the machine and sign in (tailscale up): from your devices in the tailnet Rasgeth opens at http://<machine>:7600. For HTTPS with a real certificate:'**
  String get syOiTsHereLead;

  /// No description provided for @syOiTsRunning.
  ///
  /// In en, this message translates to:
  /// **'Tailscale runs here already as {name}: from your devices in the tailnet Rasgeth opens with that name. For HTTPS with a real certificate:'**
  String syOiTsRunning(String name);

  /// No description provided for @syOiTsServe.
  ///
  /// In en, this message translates to:
  /// **'On the machine'**
  String get syOiTsServe;

  /// No description provided for @syOiTsSubnet.
  ///
  /// In en, this message translates to:
  /// **'Tailscale as a subnet router'**
  String get syOiTsSubnet;

  /// No description provided for @syOiTsSubnetLead.
  ///
  /// In en, this message translates to:
  /// **'Tailscale on another device of the house (the router, a Pi, the proxy\'s machine) that shares the network {subnet}:'**
  String syOiTsSubnetLead(String subnet);

  /// No description provided for @syOiTsSubnetThen.
  ///
  /// In en, this message translates to:
  /// **'Approve the route in Tailscale\'s admin console (Machines › Edit route settings). Your phone then opens http://{address}:{port} from anywhere, and the names of your home DNS too if you add it in DNS › Nameservers (restricted to your domain).'**
  String syOiTsSubnetThen(String address, String port);

  /// No description provided for @syOiWs.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth keeps the page live through a WebSocket at /ws: Caddy and Traefik pass it on by themselves; Nginx needs the Upgrade headers (Websockets Support in Nginx Proxy Manager).'**
  String get syOiWs;

  /// No description provided for @syOnline.
  ///
  /// In en, this message translates to:
  /// **'connected'**
  String get syOnline;

  /// No description provided for @syOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get syOpen;

  /// No description provided for @syOsErr_bad_password.
  ///
  /// In en, this message translates to:
  /// **'A Wi-Fi password has 8 to 63 characters.'**
  String get syOsErr_bad_password;

  /// No description provided for @syOsErr_bad_ssid.
  ///
  /// In en, this message translates to:
  /// **'A network\'s name has 1 to 32 characters.'**
  String get syOsErr_bad_ssid;

  /// No description provided for @syOsErr_busy.
  ///
  /// In en, this message translates to:
  /// **'The machine is already joining a network: wait a moment.'**
  String get syOsErr_busy;

  /// No description provided for @syOsErr_cannot_https.
  ///
  /// In en, this message translates to:
  /// **'HTTPS is not managed by this installation.'**
  String get syOsErr_cannot_https;

  /// No description provided for @syOsErr_cannot_reboot.
  ///
  /// In en, this message translates to:
  /// **'Restarts are not managed by this installation.'**
  String get syOsErr_cannot_reboot;

  /// No description provided for @syOsErr_cannot_update.
  ///
  /// In en, this message translates to:
  /// **'Updates are not managed by this installation.'**
  String get syOsErr_cannot_update;

  /// No description provided for @syOsErr_cannot_wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is not managed by this installation.'**
  String get syOsErr_cannot_wifi;

  /// No description provided for @syOsErr_clean_install.
  ///
  /// In en, this message translates to:
  /// **'This version needs a clean install.'**
  String get syOsErr_clean_install;

  /// No description provided for @syOsErr_connect_failed.
  ///
  /// In en, this message translates to:
  /// **'The network refused to connect: check the password and try again.'**
  String get syOsErr_connect_failed;

  /// No description provided for @syOsErr_failed.
  ///
  /// In en, this message translates to:
  /// **'That did not work. Try again in a moment.'**
  String get syOsErr_failed;

  /// No description provided for @syOsErr_https_failed.
  ///
  /// In en, this message translates to:
  /// **'Local HTTPS did not start.'**
  String get syOsErr_https_failed;

  /// No description provided for @syOsErr_https_off.
  ///
  /// In en, this message translates to:
  /// **'Local HTTPS is off: switch it on first.'**
  String get syOsErr_https_off;

  /// No description provided for @syOsErr_manual.
  ///
  /// In en, this message translates to:
  /// **'This installation cannot update by itself.'**
  String get syOsErr_manual;

  /// No description provided for @syOsErr_no_wifi.
  ///
  /// In en, this message translates to:
  /// **'This machine has no Wi-Fi card.'**
  String get syOsErr_no_wifi;

  /// No description provided for @syOsErr_not_found.
  ///
  /// In en, this message translates to:
  /// **'That network is not in reach now.'**
  String get syOsErr_not_found;

  /// No description provided for @syOsErr_not_installed.
  ///
  /// In en, this message translates to:
  /// **'This system cannot do that.'**
  String get syOsErr_not_installed;

  /// No description provided for @syOsErr_not_trusted.
  ///
  /// In en, this message translates to:
  /// **'This device does not trust the certificate yet.'**
  String get syOsErr_not_trusted;

  /// No description provided for @syOsErr_reboot_failed.
  ///
  /// In en, this message translates to:
  /// **'The restart could not be scheduled.'**
  String get syOsErr_reboot_failed;

  /// No description provided for @syOsErr_start_failed.
  ///
  /// In en, this message translates to:
  /// **'The update could not start.'**
  String get syOsErr_start_failed;

  /// No description provided for @syOsErr_timeout.
  ///
  /// In en, this message translates to:
  /// **'The machine took too long to answer.'**
  String get syOsErr_timeout;

  /// No description provided for @syOsErr_tls_failed.
  ///
  /// In en, this message translates to:
  /// **'The certificate could not be made.'**
  String get syOsErr_tls_failed;

  /// No description provided for @syOsErr_unreachable.
  ///
  /// In en, this message translates to:
  /// **'The machine\'s helper did not answer.'**
  String get syOsErr_unreachable;

  /// No description provided for @syOsErr_wifi_off.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is not running on this machine.'**
  String get syOsErr_wifi_off;

  /// No description provided for @syOsHttpsAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get syOsHttpsAddress;

  /// No description provided for @syOsHttpsCheck.
  ///
  /// In en, this message translates to:
  /// **'Check this device'**
  String get syOsHttpsCheck;

  /// No description provided for @syOsHttpsDevice.
  ///
  /// In en, this message translates to:
  /// **'Your device'**
  String get syOsHttpsDevice;

  /// No description provided for @syOsHttpsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download the certificate'**
  String get syOsHttpsDownload;

  /// No description provided for @syOsHttpsFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Certificate\'s fingerprint (SHA-256)'**
  String get syOsHttpsFingerprint;

  /// No description provided for @syOsHttpsFirefox.
  ///
  /// In en, this message translates to:
  /// **'Firefox on any system: Settings › Privacy & Security › Certificates › View Certificates › Authorities › Import, tick «Trust this CA to identify websites».'**
  String get syOsHttpsFirefox;

  /// No description provided for @syOsHttpsHow_android.
  ///
  /// In en, this message translates to:
  /// **'Settings › Security (or Security & privacy) › More › Encryption & credentials › Install a certificate › CA certificate: «Install anyway», choose Rasgeth-CA.crt.'**
  String get syOsHttpsHow_android;

  /// No description provided for @syOsHttpsHow_iphone.
  ///
  /// In en, this message translates to:
  /// **'Open the download in Safari, «Allow». Settings › General › VPN & Device Management: install the profile. Then Settings › General › About › Certificate Trust Settings: switch on «Rasgeth on …».'**
  String get syOsHttpsHow_iphone;

  /// No description provided for @syOsHttpsHow_linux.
  ///
  /// In en, this message translates to:
  /// **'Debian/Ubuntu: sudo cp Rasgeth-CA.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates. Chrome and Firefox keep their own list: add it under the browser\'s certificate settings (Authorities, «Import»).'**
  String get syOsHttpsHow_linux;

  /// No description provided for @syOsHttpsHow_mac.
  ///
  /// In en, this message translates to:
  /// **'Open Rasgeth-CA.crt: Keychain Access adds it. Double-click «Rasgeth on …» in the login keychain, open «Trust», set «When using this certificate» to «Always Trust», close and type your password.'**
  String get syOsHttpsHow_mac;

  /// No description provided for @syOsHttpsHow_windows.
  ///
  /// In en, this message translates to:
  /// **'Open Rasgeth-CA.crt, «Install certificate…», «Current user», «Place all certificates in the following store», «Trusted Root Certification Authorities», Finish, Yes. Restart the browser.'**
  String get syOsHttpsHow_windows;

  /// No description provided for @syOsHttpsInFront.
  ///
  /// In en, this message translates to:
  /// **'You already reach Rasgeth over HTTPS through {name}: the local certificate is not needed for that address.'**
  String syOsHttpsInFront(String name);

  /// No description provided for @syOsHttpsLocal.
  ///
  /// In en, this message translates to:
  /// **'HTTPS in the local network'**
  String get syOsHttpsLocal;

  /// No description provided for @syOsHttpsLocalOff.
  ///
  /// In en, this message translates to:
  /// **'Off: Rasgeth answers on http only (or through the HTTPS you set up yourself).'**
  String get syOsHttpsLocalOff;

  /// No description provided for @syOsHttpsLocalOn.
  ///
  /// In en, this message translates to:
  /// **'https://{name} and the machine\'s addresses answer with a certificate of this machine. http keeps working until you say it is trusted.'**
  String syOsHttpsLocalOn(String name);

  /// No description provided for @syOsHttpsNotYet.
  ///
  /// In en, this message translates to:
  /// **'This device does not trust the certificate yet (or https://… does not answer): nothing has changed, http keeps working.'**
  String get syOsHttpsNotYet;

  /// No description provided for @syOsHttpsNowOnly.
  ///
  /// In en, this message translates to:
  /// **'This device trusts it. From now on http goes to https for the machine\'s local name and addresses.'**
  String get syOsHttpsNowOnly;

  /// No description provided for @syOsHttpsOffQ.
  ///
  /// In en, this message translates to:
  /// **'Switch local HTTPS off?'**
  String get syOsHttpsOffQ;

  /// No description provided for @syOsHttpsOffText.
  ///
  /// In en, this message translates to:
  /// **'Browsers that already went to https://rasgeth.local keep asking for https for up to 30 days: in those, open the machine by its address (http://192.168…:7600) until then.'**
  String get syOsHttpsOffText;

  /// No description provided for @syOsHttpsOffYes.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get syOsHttpsOffYes;

  /// No description provided for @syOsHttpsQ.
  ///
  /// In en, this message translates to:
  /// **'Should the browser show the padlock on your home network?'**
  String get syOsHttpsQ;

  /// No description provided for @syOsHttpsQr.
  ///
  /// In en, this message translates to:
  /// **'QR code to download the certificate'**
  String get syOsHttpsQr;

  /// No description provided for @syOsHttpsQrHelp.
  ///
  /// In en, this message translates to:
  /// **'On a phone on the same network, scan the code to download it.'**
  String get syOsHttpsQrHelp;

  /// No description provided for @syOsHttpsRedirect.
  ///
  /// In en, this message translates to:
  /// **'Always send to HTTPS'**
  String get syOsHttpsRedirect;

  /// No description provided for @syOsHttpsRedirectOn.
  ///
  /// In en, this message translates to:
  /// **'http requests in your network go to https; browsers remember it (HSTS, 30 days). Devices without the certificate show a warning: install it there too.'**
  String get syOsHttpsRedirectOn;

  /// No description provided for @syOsHttpsTitle.
  ///
  /// In en, this message translates to:
  /// **'HTTPS in your network'**
  String get syOsHttpsTitle;

  /// No description provided for @syOsHttpsTrustLead.
  ///
  /// In en, this message translates to:
  /// **'Download it on the device (phone: scan the code), install it as below, then press «Check this device». The certificate works only for this machine\'s local names and addresses, never for any website.'**
  String get syOsHttpsTrustLead;

  /// No description provided for @syOsHttpsTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust the certificate on each device'**
  String get syOsHttpsTrustTitle;

  /// No description provided for @syOsHttpsUntil.
  ///
  /// In en, this message translates to:
  /// **'The machine\'s certificate renews itself before'**
  String get syOsHttpsUntil;

  /// No description provided for @syOsNetSub.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get syOsNetSub;

  /// No description provided for @syOsNetSubLead.
  ///
  /// In en, this message translates to:
  /// **'How the machine joins the network, and HTTPS for the pages of your home network.'**
  String get syOsNetSubLead;

  /// No description provided for @syOsRebootNow.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get syOsRebootNow;

  /// No description provided for @syOsRebootQ.
  ///
  /// In en, this message translates to:
  /// **'Restart the machine now?'**
  String get syOsRebootQ;

  /// No description provided for @syOsRebootText.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth stops for two or three minutes while the machine restarts; agents working now are interrupted and pick up again from what was saved. This page comes back by itself.'**
  String get syOsRebootText;

  /// No description provided for @syOsRebootYes.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get syOsRebootYes;

  /// No description provided for @syOsRebooting.
  ///
  /// In en, this message translates to:
  /// **'The machine restarts in a few seconds. This page comes back by itself.'**
  String get syOsRebooting;

  /// No description provided for @syOsSecLast.
  ///
  /// In en, this message translates to:
  /// **'Last time'**
  String get syOsSecLast;

  /// No description provided for @syOsSecLastAt.
  ///
  /// In en, this message translates to:
  /// **'{when}'**
  String syOsSecLastAt(String when);

  /// No description provided for @syOsSecLastN.
  ///
  /// In en, this message translates to:
  /// **'{when}, {n} packages'**
  String syOsSecLastN(String n, String when);

  /// No description provided for @syOsSecNever.
  ///
  /// In en, this message translates to:
  /// **'Not yet (it runs once a day)'**
  String get syOsSecNever;

  /// No description provided for @syOsSecNoReboot.
  ///
  /// In en, this message translates to:
  /// **'Nothing waits for a restart.'**
  String get syOsSecNoReboot;

  /// No description provided for @syOsSecQ.
  ///
  /// In en, this message translates to:
  /// **'The system installs Debian\'s security updates by itself, every day.'**
  String get syOsSecQ;

  /// No description provided for @syOsSecReboot.
  ///
  /// In en, this message translates to:
  /// **'An update asks for a restart to finish'**
  String get syOsSecReboot;

  /// No description provided for @syOsSecTitle.
  ///
  /// In en, this message translates to:
  /// **'System security updates'**
  String get syOsSecTitle;

  /// No description provided for @syOsUpdApply.
  ///
  /// In en, this message translates to:
  /// **'Update to {version}'**
  String syOsUpdApply(String version);

  /// No description provided for @syOsUpdApplyQ.
  ///
  /// In en, this message translates to:
  /// **'Update Rasgeth to {version}?'**
  String syOsUpdApplyQ(String version);

  /// No description provided for @syOsUpdApplyText.
  ///
  /// In en, this message translates to:
  /// **'The machine downloads the new version while this one keeps working, then restarts Rasgeth: the page stops for a few minutes and comes back by itself. Nothing is lost, and if the new version does not start the previous one comes back.'**
  String get syOsUpdApplyText;

  /// No description provided for @syOsUpdApplyYes.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get syOsUpdApplyYes;

  /// No description provided for @syOsUpdBreaking.
  ///
  /// In en, this message translates to:
  /// **'This version cannot be installed over the current one: Rasgeth guides you (backup on a USB disk, reinstall Rasgeth OS, restore).'**
  String get syOsUpdBreaking;

  /// No description provided for @syOsUpdChecked.
  ///
  /// In en, this message translates to:
  /// **'Last look'**
  String get syOsUpdChecked;

  /// No description provided for @syOsUpdInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get syOsUpdInstalled;

  /// No description provided for @syOsUpdQ.
  ///
  /// In en, this message translates to:
  /// **'Is Rasgeth up to date on this machine?'**
  String get syOsUpdQ;

  /// No description provided for @syOsUpdState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get syOsUpdState;

  /// No description provided for @syOsUpdSub.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get syOsUpdSub;

  /// No description provided for @syOsUpdSubLead.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth and the system it runs on, kept up to date.'**
  String get syOsUpdSubLead;

  /// No description provided for @syOsUpdTitle.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth'**
  String get syOsUpdTitle;

  /// No description provided for @syOsUpd_applying.
  ///
  /// In en, this message translates to:
  /// **'Updating to {version}'**
  String syOsUpd_applying(String version);

  /// No description provided for @syOsUpd_available.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth {version} is ready to install'**
  String syOsUpd_available(String version);

  /// No description provided for @syOsUpd_breaking.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth {version} needs a clean install'**
  String syOsUpd_breaking(String version);

  /// No description provided for @syOsUpd_error.
  ///
  /// In en, this message translates to:
  /// **'The last update did not finish (the previous version is running)'**
  String get syOsUpd_error;

  /// No description provided for @syOsUpd_latest.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syOsUpd_latest;

  /// No description provided for @syOsUpd_unknown.
  ///
  /// In en, this message translates to:
  /// **'Not looked yet'**
  String get syOsUpd_unknown;

  /// No description provided for @syOsUpd_unreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach GitHub to look'**
  String get syOsUpd_unreachable;

  /// No description provided for @syOsUpd_unsigned.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth {version} is out, but without a signed package for Rasgeth OS yet: it comes with a later release'**
  String syOsUpd_unsigned(String version);

  /// No description provided for @syOsWifi8021x.
  ///
  /// In en, this message translates to:
  /// **'company network (not from here)'**
  String get syOsWifi8021x;

  /// No description provided for @syOsWifiConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to «{name}» ({ip})'**
  String syOsWifiConnectedTo(String ip, String name);

  /// No description provided for @syOsWifiForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get syOsWifiForget;

  /// No description provided for @syOsWifiForgetQ.
  ///
  /// In en, this message translates to:
  /// **'Forget «{name}»?'**
  String syOsWifiForgetQ(String name);

  /// No description provided for @syOsWifiForgetText.
  ///
  /// In en, this message translates to:
  /// **'The machine stops joining this network and its password is erased. If it is the network in use and there is no cable, the page stops answering until the machine has another network.'**
  String get syOsWifiForgetText;

  /// No description provided for @syOsWifiGood.
  ///
  /// In en, this message translates to:
  /// **'good signal'**
  String get syOsWifiGood;

  /// No description provided for @syOsWifiHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden network…'**
  String get syOsWifiHidden;

  /// No description provided for @syOsWifiHiddenName.
  ///
  /// In en, this message translates to:
  /// **'The network\'s name'**
  String get syOsWifiHiddenName;

  /// No description provided for @syOsWifiInReach.
  ///
  /// In en, this message translates to:
  /// **'Networks in reach'**
  String get syOsWifiInReach;

  /// No description provided for @syOsWifiInUse.
  ///
  /// In en, this message translates to:
  /// **'in use'**
  String get syOsWifiInUse;

  /// No description provided for @syOsWifiJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get syOsWifiJoin;

  /// No description provided for @syOsWifiJoined.
  ///
  /// In en, this message translates to:
  /// **'Connected to «{name}». If you are using this page over that network, it keeps working.'**
  String syOsWifiJoined(String name);

  /// No description provided for @syOsWifiJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining…'**
  String get syOsWifiJoining;

  /// No description provided for @syOsWifiKnown.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get syOsWifiKnown;

  /// No description provided for @syOsWifiKnownAway.
  ///
  /// In en, this message translates to:
  /// **'Saved, not in reach now: {names}'**
  String syOsWifiKnownAway(String names);

  /// No description provided for @syOsWifiLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking…'**
  String get syOsWifiLooking;

  /// No description provided for @syOsWifiNone.
  ///
  /// In en, this message translates to:
  /// **'No network found. Look again, or join a hidden network by its name.'**
  String get syOsWifiNone;

  /// No description provided for @syOsWifiNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected to a Wi-Fi network'**
  String get syOsWifiNotConnected;

  /// No description provided for @syOsWifiNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get syOsWifiNow;

  /// No description provided for @syOsWifiPassword.
  ///
  /// In en, this message translates to:
  /// **'Password of «{name}»'**
  String syOsWifiPassword(String name);

  /// No description provided for @syOsWifiPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'8 to 63 characters. It is kept only on the machine, readable by the system alone; Rasgeth never stores or shows it.'**
  String get syOsWifiPasswordHelp;

  /// No description provided for @syOsWifiQ.
  ///
  /// In en, this message translates to:
  /// **'Which wireless network does the machine join?'**
  String get syOsWifiQ;

  /// No description provided for @syOsWifiSaved.
  ///
  /// In en, this message translates to:
  /// **'«{name}» is saved: the machine joins it as soon as it is in reach.'**
  String syOsWifiSaved(String name);

  /// No description provided for @syOsWifiScan.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get syOsWifiScan;

  /// No description provided for @syOsWifiStrong.
  ///
  /// In en, this message translates to:
  /// **'strong signal'**
  String get syOsWifiStrong;

  /// No description provided for @syOsWifiTitle.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get syOsWifiTitle;

  /// No description provided for @syOsWifiWeak.
  ///
  /// In en, this message translates to:
  /// **'weak signal'**
  String get syOsWifiWeak;

  /// No description provided for @syOsWifiWhy_failed.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi could not be read now. Try again in a moment.'**
  String get syOsWifiWhy_failed;

  /// No description provided for @syOsWifiWhy_no_helper.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is managed by the system of this machine.'**
  String get syOsWifiWhy_no_helper;

  /// No description provided for @syOsWifiWhy_no_wifi.
  ///
  /// In en, this message translates to:
  /// **'This machine has no Wi-Fi card (or the system does not recognise it).'**
  String get syOsWifiWhy_no_wifi;

  /// No description provided for @syOsWifiWhy_not_installed.
  ///
  /// In en, this message translates to:
  /// **'This system has no Wi-Fi tools.'**
  String get syOsWifiWhy_not_installed;

  /// No description provided for @syOsWifiWhy_wifi_off.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is not running on this machine. Restart it, or connect a cable.'**
  String get syOsWifiWhy_wifi_off;

  /// No description provided for @syOsWifiWired.
  ///
  /// In en, this message translates to:
  /// **'A cable is connected: the machine uses the cable, Wi-Fi stays as a spare.'**
  String get syOsWifiWired;

  /// No description provided for @syPiholeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Pi-hole\'s own page, to see what it blocks and allow a site:'**
  String get syPiholeAdmin;

  /// No description provided for @syPiholeAds.
  ///
  /// In en, this message translates to:
  /// **'About blocking ads'**
  String get syPiholeAds;

  /// No description provided for @syPiholeAdsText.
  ///
  /// In en, this message translates to:
  /// **'Pi-hole blocks the names of well-known advertising and tracking services, for every device that uses it, phones and TVs included. Now and then a site or an app needs one of those names to work (some shop links, some streaming apps): it then looks broken.'**
  String get syPiholeAdsText;

  /// No description provided for @syPiholeAllow.
  ///
  /// In en, this message translates to:
  /// **'If a site stops working: open the Pi-hole page, Query Log, find the blocked name and press Allow. To pause all blocking for a few minutes, use Disable blocking in the same page.'**
  String get syPiholeAllow;

  /// No description provided for @syPiholeAnswers.
  ///
  /// In en, this message translates to:
  /// **'At home, {domain} now leads to {ip}.'**
  String syPiholeAnswers(String domain, String ip);

  /// No description provided for @syPiholeChanges.
  ///
  /// In en, this message translates to:
  /// **'What changes at home, and how to go back'**
  String get syPiholeChanges;

  /// No description provided for @syPiholeDevice.
  ///
  /// In en, this message translates to:
  /// **'If your router does not let you change the DNS (some providers\' routers do not), set it on each device instead: in the Wi-Fi network\'s details on phones, in the network adapter\'s settings on computers.'**
  String get syPiholeDevice;

  /// No description provided for @syPiholeDomain.
  ///
  /// In en, this message translates to:
  /// **'Your domain (optional)'**
  String get syPiholeDomain;

  /// No description provided for @syPiholeDomainHelp.
  ///
  /// In en, this message translates to:
  /// **'The address you use from outside, like rasgeth.yourdomain.com: Pi-hole answers for it with the address above. Leave it empty to use Pi-hole only to block ads.'**
  String get syPiholeDomainHelp;

  /// No description provided for @syPiholeDomainWrong.
  ///
  /// In en, this message translates to:
  /// **'It must be a name like rasgeth.yourdomain.com.'**
  String get syPiholeDomainWrong;

  /// No description provided for @syPiholeIp.
  ///
  /// In en, this message translates to:
  /// **'This computer\'s address at home'**
  String get syPiholeIp;

  /// No description provided for @syPiholeIpHelp.
  ///
  /// In en, this message translates to:
  /// **'Four numbers like 192.168.1.50. Find it on the router\'s page among the connected devices, or on this computer: \"ip a\" on Linux, \"ipconfig\" on Windows, System Settings, Network on Mac. Better if the router always gives this computer the same address (address reservation).'**
  String get syPiholeIpHelp;

  /// No description provided for @syPiholeIpWrong.
  ///
  /// In en, this message translates to:
  /// **'It must be four numbers from 0 to 255 separated by dots, like 192.168.1.50.'**
  String get syPiholeIpWrong;

  /// No description provided for @syPiholeNeed.
  ///
  /// In en, this message translates to:
  /// **'you reach Rasgeth from outside with your own domain, and at home the same link does not open. Many routers cannot send you back to your own house through the internet (the feature is called NAT loopback or hairpin, and theirs lacks it).'**
  String get syPiholeNeed;

  /// No description provided for @syPiholeNeedTitle.
  ///
  /// In en, this message translates to:
  /// **'You need it if'**
  String get syPiholeNeedTitle;

  /// No description provided for @syPiholeNoNeed.
  ///
  /// In en, this message translates to:
  /// **'you use Tailscale or Cloudflare Tunnel: those links work the same at home and outside. You can still turn it on just to block ads, if you like.'**
  String get syPiholeNoNeed;

  /// No description provided for @syPiholeNoNeedTitle.
  ///
  /// In en, this message translates to:
  /// **'You do not need it if'**
  String get syPiholeNoNeedTitle;

  /// No description provided for @syPiholeNowRouter.
  ///
  /// In en, this message translates to:
  /// **'Last step, yours: on your router (or on each device) set the DNS server to {ip}. Until then nothing at home uses Pi-hole.'**
  String syPiholeNowRouter(String ip);

  /// No description provided for @syPiholeOff.
  ///
  /// In en, this message translates to:
  /// **'To go back: put the router\'s DNS back as it was (often \"automatic\") and turn Pi-hole off here. Nothing else on your computers changes.'**
  String get syPiholeOff;

  /// No description provided for @syPiholeOn.
  ///
  /// In en, this message translates to:
  /// **'Pi-hole is on, at {ip}.'**
  String syPiholeOn(String ip);

  /// No description provided for @syPiholeOpenAdmin.
  ///
  /// In en, this message translates to:
  /// **'Open Pi-hole'**
  String get syPiholeOpenAdmin;

  /// No description provided for @syPiholePort.
  ///
  /// In en, this message translates to:
  /// **'Technical details: port 53'**
  String get syPiholePort;

  /// No description provided for @syPiholePortText.
  ///
  /// In en, this message translates to:
  /// **'Pi-hole answers on port 53 (the DNS port) of this computer\'s home address only, not on the internet, and its own page on port 8053. If something on this computer already answers on port 53 (another DNS, or the system\'s own on some Linux systems), Pi-hole cannot start: Rasgeth says so and nothing changes.'**
  String get syPiholePortText;

  /// No description provided for @syPiholeRouter.
  ///
  /// In en, this message translates to:
  /// **'For every device at once: open your router\'s page (its address is usually written under the router, like 192.168.1.1), find the DHCP or LAN settings and set the DNS server to this computer\'s home address. Devices pick it up the next time they connect (or restart them).'**
  String get syPiholeRouter;

  /// No description provided for @syPiholeSecond.
  ///
  /// In en, this message translates to:
  /// **'A second DNS: if this computer is off, devices that only know Pi-hole cannot open any site. As a second DNS you can put your router\'s address or a public one (1.1.1.1): everything keeps working when this computer is off, but devices may sometimes ask the second one and then see ads, or not find your domain at home.'**
  String get syPiholeSecond;

  /// No description provided for @syPiholeShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show its password'**
  String get syPiholeShowPassword;

  /// No description provided for @syPiholeStart.
  ///
  /// In en, this message translates to:
  /// **'Turn on Pi-hole'**
  String get syPiholeStart;

  /// No description provided for @syPiholeStop.
  ///
  /// In en, this message translates to:
  /// **'Turn off Pi-hole'**
  String get syPiholeStop;

  /// No description provided for @syPiholeTest.
  ///
  /// In en, this message translates to:
  /// **'How to check: connect your phone to the home Wi-Fi and open your Rasgeth link. If it opens, you do not need Pi-hole for this (you may still want it to block ads). If it does not, but works on mobile data, Pi-hole fixes it.'**
  String get syPiholeTest;

  /// No description provided for @syPiholeTitle.
  ///
  /// In en, this message translates to:
  /// **'The home\'s own DNS, with Pi-hole (optional)'**
  String get syPiholeTitle;

  /// No description provided for @syPiholeWhat.
  ///
  /// In en, this message translates to:
  /// **'Every device at home asks a DNS server which number is behind a name (for example rasgeth.yourdomain.com). Usually your router or your internet provider answers. Pi-hole is a small DNS that Rasgeth can run on this computer: it answers for your domain with this computer\'s home address, so the link works at home too, and it also blocks advertising and tracking for every device that uses it.'**
  String get syPiholeWhat;

  /// No description provided for @syPwSignOutOthersQ.
  ///
  /// In en, this message translates to:
  /// **'Sign out your other devices too?'**
  String get syPwSignOutOthersQ;

  /// No description provided for @syPwSignOutOthersText.
  ///
  /// In en, this message translates to:
  /// **'The other browsers and the apps signed in with the old password stay in if you keep them. Sign them out if you changed it because someone else might know it.'**
  String get syPwSignOutOthersText;

  /// No description provided for @syPwSignOutOthersYes.
  ///
  /// In en, this message translates to:
  /// **'Sign them out'**
  String get syPwSignOutOthersYes;

  /// No description provided for @syRemoteCaddy.
  ///
  /// In en, this message translates to:
  /// **'For experts: your domain pointing at home, ports 80 and 443 opened on the router. Anyone on the internet can reach the sign-in page.'**
  String get syRemoteCaddy;

  /// No description provided for @syRemoteCloudflare.
  ///
  /// In en, this message translates to:
  /// **'An address on your own domain (about 10 euros a year), nothing opened on the router. A few more steps on Cloudflare\'s site.'**
  String get syRemoteCloudflare;

  /// No description provided for @syRemoteCode.
  ///
  /// In en, this message translates to:
  /// **'Second check (recommended)'**
  String get syRemoteCode;

  /// No description provided for @syRemoteCodeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get syRemoteCodeConfirm;

  /// No description provided for @syRemoteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Besides the password, a 6-digit code from an app on your phone (Google Authenticator, Microsoft Authenticator, 2FAS…): someone who learns the password still cannot get in.'**
  String get syRemoteCodeHint;

  /// No description provided for @syRemoteCodeOff.
  ///
  /// In en, this message translates to:
  /// **'Second check off.'**
  String get syRemoteCodeOff;

  /// No description provided for @syRemoteCodeOn.
  ///
  /// In en, this message translates to:
  /// **'Second check on'**
  String get syRemoteCodeOn;

  /// No description provided for @syRemoteCodeQr.
  ///
  /// In en, this message translates to:
  /// **'Scan with the authenticator app'**
  String get syRemoteCodeQr;

  /// No description provided for @syRemoteCodeScan.
  ///
  /// In en, this message translates to:
  /// **'Scan the code with the app (or type the key below in it), then write here the 6 digits it shows.'**
  String get syRemoteCodeScan;

  /// No description provided for @syRemoteCodeStart.
  ///
  /// In en, this message translates to:
  /// **'Switch on the second check'**
  String get syRemoteCodeStart;

  /// No description provided for @syRemoteConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get syRemoteConnect;

  /// No description provided for @syRemoteHow.
  ///
  /// In en, this message translates to:
  /// **'How to reach it'**
  String get syRemoteHow;

  /// No description provided for @syRemoteNeedsPassword.
  ///
  /// In en, this message translates to:
  /// **'Set the password above first.'**
  String get syRemoteNeedsPassword;

  /// No description provided for @syRemoteNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get syRemoteNewPassword;

  /// No description provided for @syRemoteOff.
  ///
  /// In en, this message translates to:
  /// **'Switch off access from outside'**
  String get syRemoteOff;

  /// No description provided for @syRemoteOn.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth can be reached from outside at this address:'**
  String get syRemoteOn;

  /// No description provided for @syRemoteOwnDomain.
  ///
  /// In en, this message translates to:
  /// **'Your domain, open router'**
  String get syRemoteOwnDomain;

  /// No description provided for @syRemotePassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get syRemotePassword;

  /// No description provided for @syRemotePasswordChange.
  ///
  /// In en, this message translates to:
  /// **'Change it'**
  String get syRemotePasswordChange;

  /// No description provided for @syRemotePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'From outside, Rasgeth asks for this password (the link with the token stays for this computer). Choose one you use nowhere else.'**
  String get syRemotePasswordHint;

  /// No description provided for @syRemotePasswordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters. A short sentence is easy to remember and hard to guess.'**
  String get syRemotePasswordRule;

  /// No description provided for @syRemotePasswordSaved.
  ///
  /// In en, this message translates to:
  /// **'Password saved.'**
  String get syRemotePasswordSaved;

  /// No description provided for @syRemotePasswordSet.
  ///
  /// In en, this message translates to:
  /// **'A password is set'**
  String get syRemotePasswordSet;

  /// No description provided for @syRemotePurpose.
  ///
  /// In en, this message translates to:
  /// **'Use Rasgeth from your phone or another computer when you are away. First a password, then one of three ways; nothing is reachable from outside until you finish. Optional.'**
  String get syRemotePurpose;

  /// No description provided for @syRemoteSessions.
  ///
  /// In en, this message translates to:
  /// **'Signed-in browsers'**
  String get syRemoteSessions;

  /// No description provided for @syRemoteSessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Each sign-in lasts 30 days. If you lost a phone, or think someone else got in (the Rasgeth apps are signed out too):'**
  String get syRemoteSessionsHint;

  /// No description provided for @syRemoteSignOutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out everywhere'**
  String get syRemoteSignOutAll;

  /// No description provided for @syRemoteSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out everywhere.'**
  String get syRemoteSignedOut;

  /// No description provided for @syRemoteTailscale.
  ///
  /// In en, this message translates to:
  /// **'A private network between your own devices: nothing opened on the router, free for personal use. You install Tailscale on your phone too.'**
  String get syRemoteTailscale;

  /// No description provided for @syRemoteWaysFolded.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth\'s own ways out'**
  String get syRemoteWaysFolded;

  /// No description provided for @syRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get syRemove;

  /// No description provided for @sySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sySave;

  /// No description provided for @sySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get sySaved;

  /// No description provided for @sySbBackupQ.
  ///
  /// In en, this message translates to:
  /// **'All of Rasgeth in one file'**
  String get sySbBackupQ;

  /// No description provided for @sySettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sySettings;

  /// No description provided for @sySnCable.
  ///
  /// In en, this message translates to:
  /// **'I use the cable'**
  String get sySnCable;

  /// No description provided for @sySnCableDone.
  ///
  /// In en, this message translates to:
  /// **'The cable works: Rasgeth is at {address}. Join your home network with this device and open http://{address}:7600 (or http://rasgeth.local:7600).'**
  String sySnCableDone(String address);

  /// No description provided for @sySnFailed.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth could not join «{name}»: {why}'**
  String sySnFailed(String name, String why);

  /// No description provided for @sySnHidden.
  ///
  /// In en, this message translates to:
  /// **'A hidden network'**
  String get sySnHidden;

  /// No description provided for @sySnHiddenName.
  ///
  /// In en, this message translates to:
  /// **'Network name'**
  String get sySnHiddenName;

  /// No description provided for @sySnJoin.
  ///
  /// In en, this message translates to:
  /// **'Use this network'**
  String get sySnJoin;

  /// No description provided for @sySnMaintQ.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth could not find your home network, so it opened {ssid} again: choose the network it should use.'**
  String sySnMaintQ(String ssid);

  /// No description provided for @sySnNone.
  ///
  /// In en, this message translates to:
  /// **'No network was seen around: use the cable, or type the name of a hidden network.'**
  String get sySnNone;

  /// No description provided for @sySnPassword.
  ///
  /// In en, this message translates to:
  /// **'Password of «{name}»'**
  String sySnPassword(String name);

  /// No description provided for @sySnQ.
  ///
  /// In en, this message translates to:
  /// **'You are on {ssid}, Rasgeth\'s temporary network: which network should Rasgeth use at home?'**
  String sySnQ(String ssid);

  /// No description provided for @sySnTitle.
  ///
  /// In en, this message translates to:
  /// **'Your home network'**
  String get sySnTitle;

  /// No description provided for @sySnTrying.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth is joining «{name}»: this temporary network closes now. Join your home network with this device and open http://rasgeth.local:7600. If it does not work, {ssid} comes back in a minute with the reason.'**
  String sySnTrying(String name, String ssid);

  /// No description provided for @syStRemoteQ.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth away from home'**
  String get syStRemoteQ;

  /// No description provided for @syStopped.
  ///
  /// In en, this message translates to:
  /// **'stopped'**
  String get syStopped;

  /// No description provided for @syTgQr.
  ///
  /// In en, this message translates to:
  /// **'Scan with your phone\'s camera'**
  String get syTgQr;

  /// No description provided for @syTsApps.
  ///
  /// In en, this message translates to:
  /// **'Tailscale apps'**
  String get syTsApps;

  /// No description provided for @syTsDns.
  ///
  /// In en, this message translates to:
  /// **'Tailscale DNS settings'**
  String get syTsDns;

  /// No description provided for @syTsOpenSignIn.
  ///
  /// In en, this message translates to:
  /// **'Open Tailscale\'s sign-in page'**
  String get syTsOpenSignIn;

  /// No description provided for @syTsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Tailscale wants you to sign in, to add Rasgeth to your network:'**
  String get syTsSignIn;

  /// No description provided for @syTsSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up on Tailscale'**
  String get syTsSignUp;

  /// No description provided for @syTsStep1.
  ///
  /// In en, this message translates to:
  /// **'Make a free Tailscale account (with Google, Microsoft or GitHub is fine):'**
  String get syTsStep1;

  /// No description provided for @syTsStep2.
  ///
  /// In en, this message translates to:
  /// **'In Tailscale\'s DNS page switch on MagicDNS and HTTPS Certificates (they give Rasgeth a safe address):'**
  String get syTsStep2;

  /// No description provided for @syTsStep3.
  ///
  /// In en, this message translates to:
  /// **'Then here:'**
  String get syTsStep3;

  /// No description provided for @syTsStep4.
  ///
  /// In en, this message translates to:
  /// **'Install Tailscale on your phone and the other computers, signed in with the same account:'**
  String get syTsStep4;

  /// No description provided for @syUiAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get syUiAdvanced;

  /// No description provided for @syUiDone.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get syUiDone;

  /// No description provided for @syUiNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'not needed'**
  String get syUiNotNeeded;

  /// No description provided for @syUpdBrkChecked.
  ///
  /// In en, this message translates to:
  /// **'{file} · {size} · {projects} projects, {conversations} conversations, memories and settings'**
  String syUpdBrkChecked(String conversations, String file, String projects, String size);

  /// No description provided for @syUpdBrkDockerCopy.
  ///
  /// In en, this message translates to:
  /// **'The folder is inside Rasgeth\'s data volume, which a clean install removes: copy the file out first, from Rasgeth\'s folder:'**
  String get syUpdBrkDockerCopy;

  /// No description provided for @syUpdBrkDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get syUpdBrkDone;

  /// No description provided for @syUpdBrkKeys.
  ///
  /// In en, this message translates to:
  /// **'Your keychain ({n} keys, the models\', chats\' and mailboxes\' ones too) is not in the backup: it goes in only protected by a passphrase of yours.'**
  String syUpdBrkKeys(String n);

  /// No description provided for @syUpdBrkKeysAdd.
  ///
  /// In en, this message translates to:
  /// **'Add the keychain too'**
  String get syUpdBrkKeysAdd;

  /// No description provided for @syUpdBrkKeysAgain.
  ///
  /// In en, this message translates to:
  /// **'Make the backup again with the keychain'**
  String get syUpdBrkKeysAgain;

  /// No description provided for @syUpdBrkKeysIn.
  ///
  /// In en, this message translates to:
  /// **'The keychain is in the backup too, protected by your passphrase.'**
  String get syUpdBrkKeysIn;

  /// No description provided for @syUpdBrkLead.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth {version} changed too much inside to update the usual way: installed over the old one it could break.'**
  String syUpdBrkLead(String version);

  /// No description provided for @syUpdBrkNext.
  ///
  /// In en, this message translates to:
  /// **'Go on'**
  String get syUpdBrkNext;

  /// No description provided for @syUpdBrkRetry.
  ///
  /// In en, this message translates to:
  /// **'Try the backup again'**
  String get syUpdBrkRetry;

  /// No description provided for @syUpdBrkSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup made and read back: it is in this folder'**
  String get syUpdBrkSaved;

  /// No description provided for @syUpdBrkStep1.
  ///
  /// In en, this message translates to:
  /// **'Remove the old Rasgeth'**
  String get syUpdBrkStep1;

  /// No description provided for @syUpdBrkStep1Docker.
  ///
  /// In en, this message translates to:
  /// **'In Rasgeth\'s folder remove the containers and their volumes:'**
  String get syUpdBrkStep1Docker;

  /// No description provided for @syUpdBrkStep1Mac.
  ///
  /// In en, this message translates to:
  /// **'From the menu bar icon choose «Uninstall…» (or drag Rasgeth from Applications to the Bin).'**
  String get syUpdBrkStep1Mac;

  /// No description provided for @syUpdBrkStep1Os.
  ///
  /// In en, this message translates to:
  /// **'Copy the backup to a USB disk (Settings › System › Backups): reinstalling Rasgeth OS erases this machine\'s disk.'**
  String get syUpdBrkStep1Os;

  /// No description provided for @syUpdBrkStep1Source.
  ///
  /// In en, this message translates to:
  /// **'Stop Rasgeth and move its data folder away.'**
  String get syUpdBrkStep1Source;

  /// No description provided for @syUpdBrkStep1Win.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Rasgeth. When it asks whether to keep the data, you can answer No: everything is in the backup.'**
  String get syUpdBrkStep1Win;

  /// No description provided for @syUpdBrkStep2.
  ///
  /// In en, this message translates to:
  /// **'Install Rasgeth {version}'**
  String syUpdBrkStep2(String version);

  /// No description provided for @syUpdBrkStep3.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get syUpdBrkStep3;

  /// No description provided for @syUpdBrkStep3Docker.
  ///
  /// In en, this message translates to:
  /// **'Open Rasgeth, finish the setup and import the copied file in Settings › Backup › Import a backup.'**
  String get syUpdBrkStep3Docker;

  /// No description provided for @syUpdBrkStep3Os.
  ///
  /// In en, this message translates to:
  /// **'Write the new Rasgeth OS (USB stick or image) and start the machine: the first start offers «Restore from the backup» and finds it on the USB disk.'**
  String get syUpdBrkStep3Os;

  /// No description provided for @syUpdBrkStep3Text.
  ///
  /// In en, this message translates to:
  /// **'At its first start the new Rasgeth offers «Restore from the backup»: it finds it in that folder by itself.'**
  String get syUpdBrkStep3Text;

  /// No description provided for @syUpdBrkSub.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth {version} cannot be installed over the {installed}'**
  String syUpdBrkSub(String installed, String version);

  /// No description provided for @syUpdBrkSure.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth closes and its uninstaller starts. The backup stays in {folder}.'**
  String syUpdBrkSure(String folder);

  /// No description provided for @syUpdBrkTitle.
  ///
  /// In en, this message translates to:
  /// **'This version needs a clean install'**
  String get syUpdBrkTitle;

  /// No description provided for @syUpdBrkUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Rasgeth'**
  String get syUpdBrkUninstall;

  /// No description provided for @syUpdBrkUninstallYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, uninstall'**
  String get syUpdBrkUninstallYes;

  /// No description provided for @syUpdBrkUninstalling.
  ///
  /// In en, this message translates to:
  /// **'The uninstaller is starting on your desktop.'**
  String get syUpdBrkUninstalling;

  /// No description provided for @syUpdBrkWhy.
  ///
  /// In en, this message translates to:
  /// **'So it goes in three short steps: first a backup of everything (I am making it now, by myself), then you remove the old Rasgeth and install the new one, which puts everything back from the backup.'**
  String get syUpdBrkWhy;

  /// No description provided for @syUpdCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get syUpdCopied;

  /// No description provided for @syUpdCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get syUpdCopy;

  /// No description provided for @syUpdDownloadNew.
  ///
  /// In en, this message translates to:
  /// **'Download the new version'**
  String get syUpdDownloadNew;

  /// No description provided for @syUpdFoundDone.
  ///
  /// In en, this message translates to:
  /// **'Everything is back. Go on with the next steps to set up the models.'**
  String get syUpdFoundDone;

  /// No description provided for @syUpdFoundKeys.
  ///
  /// In en, this message translates to:
  /// **'The passphrase you chose for the keychain. Without it everything else is restored, and the keys of models and chats are put in again from their pages.'**
  String get syUpdFoundKeys;

  /// No description provided for @syUpdFoundLead.
  ///
  /// In en, this message translates to:
  /// **'There is a backup of {date} (Rasgeth {version}): {projects} projects and {conversations} conversations. Put everything back now?'**
  String syUpdFoundLead(String conversations, String date, String projects, String version);

  /// No description provided for @syUpdFoundRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from the backup'**
  String get syUpdFoundRestore;

  /// No description provided for @syUpdFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from the backup'**
  String get syUpdFoundTitle;

  /// No description provided for @syUpdLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get syUpdLater;

  /// No description provided for @syUpdLook.
  ///
  /// In en, this message translates to:
  /// **'Look for updates'**
  String get syUpdLook;

  /// No description provided for @syUpdLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking…'**
  String get syUpdLooking;

  /// No description provided for @syUpdReqAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get syUpdReqAgain;

  /// No description provided for @syUpdReqClose.
  ///
  /// In en, this message translates to:
  /// **'Close Rasgeth'**
  String get syUpdReqClose;

  /// No description provided for @syUpdReqClosing.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth is closing. You can close this page.'**
  String get syUpdReqClosing;

  /// No description provided for @syUpdReqDocker.
  ///
  /// In en, this message translates to:
  /// **'On the computer where Rasgeth runs, in its folder, run:'**
  String get syUpdReqDocker;

  /// No description provided for @syUpdReqInstaller.
  ///
  /// In en, this message translates to:
  /// **'If the update does not start, the whole installer is here:'**
  String get syUpdReqInstaller;

  /// No description provided for @syUpdReqInstallerLink.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth-Setup.exe'**
  String get syUpdReqInstallerLink;

  /// No description provided for @syUpdReqLead.
  ///
  /// In en, this message translates to:
  /// **'This update cannot wait: Rasgeth {version} fixes something that the {installed} cannot keep doing safely.'**
  String syUpdReqLead(String installed, String version);

  /// No description provided for @syUpdReqMac.
  ///
  /// In en, this message translates to:
  /// **'Open the downloaded file and drag Rasgeth into Applications, replacing the old one; then open it again.'**
  String get syUpdReqMac;

  /// No description provided for @syUpdReqNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get syUpdReqNow;

  /// No description provided for @syUpdReqSafe.
  ///
  /// In en, this message translates to:
  /// **'Until you update, agents and automations wait. Your conversations, projects and settings are safe: nothing is lost.'**
  String get syUpdReqSafe;

  /// No description provided for @syUpdReqSource.
  ///
  /// In en, this message translates to:
  /// **'Bring the code up to date (git pull), build it and start Rasgeth again.'**
  String get syUpdReqSource;

  /// No description provided for @syUpdReqSub.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is needed (you have {installed})'**
  String syUpdReqSub(String installed, String version);

  /// No description provided for @syUpdReqTitle.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth must be updated'**
  String get syUpdReqTitle;

  /// No description provided for @syUpdReqUpdating.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth is downloading the update: follow the window on your desktop. It restarts by itself.'**
  String get syUpdReqUpdating;

  /// No description provided for @syUpdReqUpdatingOs.
  ///
  /// In en, this message translates to:
  /// **'Rasgeth OS is updating Rasgeth: the page stops for a few minutes and comes back by itself.'**
  String get syUpdReqUpdatingOs;

  /// No description provided for @syWzBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get syWzBack;

  /// No description provided for @syWzCpu.
  ///
  /// In en, this message translates to:
  /// **'Processor'**
  String get syWzCpu;

  /// No description provided for @syWzFree.
  ///
  /// In en, this message translates to:
  /// **'free'**
  String get syWzFree;

  /// No description provided for @syWzGpu.
  ///
  /// In en, this message translates to:
  /// **'Graphics card'**
  String get syWzGpu;

  /// No description provided for @syWzMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get syWzMemory;

  /// No description provided for @syWzNoGpu.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get syWzNoGpu;

  /// No description provided for @syWzRecommended.
  ///
  /// In en, this message translates to:
  /// **'recommended'**
  String get syWzRecommended;

  /// No description provided for @syWzRemote.
  ///
  /// In en, this message translates to:
  /// **'Access from outside home'**
  String get syWzRemote;

  /// No description provided for @syWzStorage.
  ///
  /// In en, this message translates to:
  /// **'Data and backups'**
  String get syWzStorage;

  /// No description provided for @syWzThreads.
  ///
  /// In en, this message translates to:
  /// **'{n} threads'**
  String syWzThreads(String n);

  /// No description provided for @syHubTitle.
  ///
  /// In en, this message translates to:
  /// **'System and access'**
  String get syHubTitle;

  /// No description provided for @syHubRemote.
  ///
  /// In en, this message translates to:
  /// **'Password, second check, Tailscale, Cloudflare, your own domain, Pi-hole'**
  String get syHubRemote;

  /// No description provided for @syHubSystem.
  ///
  /// In en, this message translates to:
  /// **'The machine, its role, data and backups, Wi-Fi, HTTPS, SSH, updates'**
  String get syHubSystem;

  /// No description provided for @syHubMachines.
  ///
  /// In en, this message translates to:
  /// **'Your computers the agents reach over SSH'**
  String get syHubMachines;

  /// No description provided for @syHubNodes.
  ///
  /// In en, this message translates to:
  /// **'Other machines working with this one'**
  String get syHubNodes;

  /// No description provided for @syHubBackup.
  ///
  /// In en, this message translates to:
  /// **'Everything in one file, and a file brought back'**
  String get syHubBackup;

  /// No description provided for @syGateOpen.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get syGateOpen;

  /// No description provided for @hfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Hands-free voice is on'**
  String get hfServiceTitle;

  /// No description provided for @hfServiceBody.
  ///
  /// In en, this message translates to:
  /// **'The microphone stays open for the conversation by voice.'**
  String get hfServiceBody;

  /// No description provided for @hfServiceChannel.
  ///
  /// In en, this message translates to:
  /// **'Hands-free voice'**
  String get hfServiceChannel;

  /// No description provided for @hfServiceChannelText.
  ///
  /// In en, this message translates to:
  /// **'Shown while the microphone is open for hands-free voice.'**
  String get hfServiceChannelText;

  /// No description provided for @hfPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused: the app is not in front'**
  String get hfPaused;

  /// No description provided for @hfWakeNotHere.
  ///
  /// In en, this message translates to:
  /// **'On this device the wake word is not heard yet: tap the indicator, then «Talk now».'**
  String get hfWakeNotHere;

  /// No description provided for @hfWakeHelp.
  ///
  /// In en, this message translates to:
  /// **'Your wake word is kept for this device and checked with the speech model of Rasgeth.'**
  String get hfWakeHelp;

  /// No description provided for @hfLimitPrivacy.
  ///
  /// In en, this message translates to:
  /// **'What you say after «Talk now» is sent to Rasgeth to be transcribed; nothing is heard before.'**
  String get hfLimitPrivacy;

  /// No description provided for @hfLimitAndroid.
  ///
  /// In en, this message translates to:
  /// **'On Android the microphone stays open with the screen off or another app in front, with a notification that says so.'**
  String get hfLimitAndroid;

  /// No description provided for @hfLimitOthers.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, iPad and the computers it listens while the app is open; in the background it pauses and the indicator says so.'**
  String get hfLimitOthers;

  /// No description provided for @hfReaderRow.
  ///
  /// In en, this message translates to:
  /// **'Who reads and how loud'**
  String get hfReaderRow;

  /// No description provided for @hfSttRow.
  ///
  /// In en, this message translates to:
  /// **'Who writes down what you say'**
  String get hfSttRow;

  /// No description provided for @hfSttNone.
  ///
  /// In en, this message translates to:
  /// **'No transcription service yet'**
  String get hfSttNone;

  /// No description provided for @hfPickConversation.
  ///
  /// In en, this message translates to:
  /// **'Choose the conversation'**
  String get hfPickConversation;

  /// No description provided for @hfNoRecent.
  ///
  /// In en, this message translates to:
  /// **'No conversation yet'**
  String get hfNoRecent;

  /// No description provided for @hfHandsFreeRow.
  ///
  /// In en, this message translates to:
  /// **'Hands-free voice'**
  String get hfHandsFreeRow;

  /// No description provided for @hfHandsFreeOn.
  ///
  /// In en, this message translates to:
  /// **'On: {state}'**
  String hfHandsFreeOn(String state);

  /// No description provided for @hfHandsFreeOff.
  ///
  /// In en, this message translates to:
  /// **'Off on this device'**
  String get hfHandsFreeOff;

  /// No description provided for @fsrTitle.
  ///
  /// In en, this message translates to:
  /// **'Search the conversations'**
  String get fsrTitle;

  /// No description provided for @fsrGo.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get fsrGo;

  /// No description provided for @fsrHint.
  ///
  /// In en, this message translates to:
  /// **'The words in every conversation: the agents\', the Chat\'s and the inspectors\'. At least two letters.'**
  String get fsrHint;

  /// No description provided for @fsrNone.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get fsrNone;

  /// No description provided for @fsrUntitled.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get fsrUntitled;

  /// No description provided for @fsrInspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get fsrInspector;

  /// No description provided for @g7WzRoleFull.
  ///
  /// In en, this message translates to:
  /// **'A complete Rasgeth'**
  String get g7WzRoleFull;

  /// No description provided for @g7WzRoleFullText.
  ///
  /// In en, this message translates to:
  /// **'Its agents, projects and chats live here.'**
  String get g7WzRoleFullText;

  /// No description provided for @g7WzRoleNode.
  ///
  /// In en, this message translates to:
  /// **'A node of another Rasgeth'**
  String get g7WzRoleNode;

  /// No description provided for @g7WzRoleNodeText.
  ///
  /// In en, this message translates to:
  /// **'It lends this machine to another Rasgeth: commands, local models, room for projects and backups.'**
  String get g7WzRoleNodeText;

  /// No description provided for @g7WzNoWay.
  ///
  /// In en, this message translates to:
  /// **'No way of thinking yet'**
  String get g7WzNoWay;

  /// No description provided for @g7WzWays.
  ///
  /// In en, this message translates to:
  /// **'Connected: {ways}'**
  String g7WzWays(String ways);

  /// No description provided for @g7WzWayKeys.
  ///
  /// In en, this message translates to:
  /// **'API keys'**
  String get g7WzWayKeys;

  /// No description provided for @g7WzWayLocal.
  ///
  /// In en, this message translates to:
  /// **'a model on this computer'**
  String get g7WzWayLocal;

  /// No description provided for @g7WzWayServer.
  ///
  /// In en, this message translates to:
  /// **'your own server'**
  String get g7WzWayServer;

  /// No description provided for @g7WzOpenModels.
  ///
  /// In en, this message translates to:
  /// **'Models and subscriptions'**
  String get g7WzOpenModels;

  /// No description provided for @g7WzNoLocal.
  ///
  /// In en, this message translates to:
  /// **'No model on this computer yet'**
  String get g7WzNoLocal;

  /// No description provided for @g7WzLocal.
  ///
  /// In en, this message translates to:
  /// **'In use: {model}'**
  String g7WzLocal(String model);

  /// No description provided for @g7WzOpenLocal.
  ///
  /// In en, this message translates to:
  /// **'Models on this computer'**
  String get g7WzOpenLocal;

  /// No description provided for @g7WzAssignLead.
  ///
  /// In en, this message translates to:
  /// **'Who decides gets the strongest model, who answers a quick one: God, Demi-God, the assistants and the others, each with its own.'**
  String get g7WzAssignLead;

  /// No description provided for @g7WzOpenAssign.
  ///
  /// In en, this message translates to:
  /// **'Choose who uses which model'**
  String get g7WzOpenAssign;

  /// No description provided for @g7WzTelegramLead.
  ///
  /// In en, this message translates to:
  /// **'Write to Demi-God from your phone, also by voice: a bot of your own, made in a minute with BotFather.'**
  String get g7WzTelegramLead;

  /// No description provided for @g7WzOpenTelegram.
  ///
  /// In en, this message translates to:
  /// **'Set up Telegram'**
  String get g7WzOpenTelegram;

  /// No description provided for @g7WzOpenBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups and their destinations'**
  String get g7WzOpenBackups;

  /// No description provided for @g7WzOpenCode.
  ///
  /// In en, this message translates to:
  /// **'GitHub and Gitea'**
  String get g7WzOpenCode;

  /// No description provided for @g7WzOpenRemote.
  ///
  /// In en, this message translates to:
  /// **'Access from outside home'**
  String get g7WzOpenRemote;

  /// No description provided for @g7WzPresetText.
  ///
  /// In en, this message translates to:
  /// **'{n} kinds of action only you approve'**
  String g7WzPresetText(String n);

  /// No description provided for @g7WzSafetyMore.
  ///
  /// In en, this message translates to:
  /// **'Everything about safety and costs'**
  String get g7WzSafetyMore;

  /// No description provided for @g7WzCustom.
  ///
  /// In en, this message translates to:
  /// **'Your own choice'**
  String get g7WzCustom;

  /// No description provided for @g7WzPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get g7WzPassword;

  /// No description provided for @g7WzPasswordAgain.
  ///
  /// In en, this message translates to:
  /// **'The password again'**
  String get g7WzPasswordAgain;

  /// No description provided for @g7WzDiskFree.
  ///
  /// In en, this message translates to:
  /// **'Free on disk: {gb} GB'**
  String g7WzDiskFree(String gb);

  /// No description provided for @g7WzRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo the setup'**
  String get g7WzRedo;

  /// No description provided for @g7WzRedoText.
  ///
  /// In en, this message translates to:
  /// **'The page\'s guided setup, one step at a time: every step is saved at once.'**
  String get g7WzRedoText;

  /// No description provided for @g7WzContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue the setup'**
  String get g7WzContinue;

  /// No description provided for @g7WzContinueText.
  ///
  /// In en, this message translates to:
  /// **'Models, who uses which, imports, Telegram, backups, access from outside and safety: one step at a time, each one can be skipped.'**
  String get g7WzContinueText;

  /// No description provided for @g7AcpRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get g7AcpRemove;

  /// No description provided for @g7ImpOpen.
  ///
  /// In en, this message translates to:
  /// **'Import from other agents'**
  String get g7ImpOpen;

  /// No description provided for @g7ImpRow.
  ///
  /// In en, this message translates to:
  /// **'From Claude Code, Codex, Cursor and the chat exports'**
  String get g7ImpRow;

  /// No description provided for @g7AcpRow.
  ///
  /// In en, this message translates to:
  /// **'Claude Code, Codex, Gemini CLI as agents of a project'**
  String get g7AcpRow;

  /// No description provided for @g7PlRow.
  ///
  /// In en, this message translates to:
  /// **'Every change to the settings and to the code, undoable'**
  String get g7PlRow;

  /// No description provided for @g7NewsRow.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in this version'**
  String get g7NewsRow;

  /// No description provided for @g7HubTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup, imports and history'**
  String get g7HubTitle;

  /// No description provided for @g7SetupCode.
  ///
  /// In en, this message translates to:
  /// **'The setup code shown by the machine'**
  String get g7SetupCode;

  /// No description provided for @g7SetupCodeYes.
  ///
  /// In en, this message translates to:
  /// **'No password yet? Use the setup code'**
  String get g7SetupCodeYes;

  /// No description provided for @g7SetupCodeNo.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the password'**
  String get g7SetupCodeNo;
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
