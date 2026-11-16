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
  /// **'Update RedGiant?'**
  String get updNowTitle;

  /// No description provided for @updNowBody.
  ///
  /// In en, this message translates to:
  /// **'RedGiant downloads {version}, then restarts: for a minute or two it does not answer. You see every step, and the app reconnects by itself as soon as RedGiant is back.'**
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
  /// **'How this device hears from RedGiant when the app is closed'**
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
  /// **'Off on this device: RedGiant cannot tell you anything while the app is closed.'**
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
  /// **'The distributor gave an address, but RedGiant could not be reached: the app tries again at the next start.'**
  String get pushEndpointNotSent;

  /// No description provided for @pushFailedNetwork.
  ///
  /// In en, this message translates to:
  /// **'The distributor has no network now: try again in a moment.'**
  String get pushFailedNetwork;

  /// No description provided for @pushFailedVapid.
  ///
  /// In en, this message translates to:
  /// **'The distributor wants RedGiant\'s VAPID key, which is in the keychain: open the keychain on RedGiant and try again.'**
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
  /// **'The distributor brings RedGiant\'s notifications to this phone, encrypted: you choose it (ntfy, your own ntfy, Sunup…), no Google or RedGiant cloud in between.'**
  String get pushDistributorHint;

  /// No description provided for @pushNoDistributor.
  ///
  /// In en, this message translates to:
  /// **'There is no UnifiedPush distributor on this phone.'**
  String get pushNoDistributor;

  /// No description provided for @pushNoDistributorMeans.
  ///
  /// In en, this message translates to:
  /// **'Without one, RedGiant cannot reach you while the app is closed: you see requests and answers only by opening the app (or in a linked chat, like Telegram).'**
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
  /// **'With the app closed this computer gets nothing: RedGiant\'s page and the linked chats still do.'**
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
  /// **'Share to RedGiant'**
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
  /// **'RedGiant has no voice to read with yet.'**
  String get voiceNoReader;

  /// No description provided for @voiceNoReaderHow.
  ///
  /// In en, this message translates to:
  /// **'Add a key for OpenAI, ElevenLabs or Google Gemini in RedGiant\'s Settings, Voice: then choose it here.'**
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
  /// **'It is written down by RedGiant\'s transcription (Settings, Voice, Transcription), the same as the page\'s.'**
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
  /// **'The microphone is not allowed: allow it in the system\'s settings for RGCompanion.'**
  String get voiceMicDenied;

  /// No description provided for @voiceMicFailed.
  ///
  /// In en, this message translates to:
  /// **'The microphone did not start: is another app using it?'**
  String get voiceMicFailed;

  /// No description provided for @voiceErrNoService.
  ///
  /// In en, this message translates to:
  /// **'RedGiant has no transcription service: choose one in Settings, Voice, Transcription.'**
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
  /// **'The recording could not be converted for whisper on RedGiant\'s computer.'**
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
  /// **'RedGiant cannot be reached: check the connection.'**
  String get voiceErrServer;

  /// No description provided for @voiceErrOther.
  ///
  /// In en, this message translates to:
  /// **'The voice did not work: try again.'**
  String get voiceErrOther;

  /// No description provided for @notifyTestFailed.
  ///
  /// In en, this message translates to:
  /// **'The system did not show it: are notifications on for RGCompanion in its settings?'**
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
  /// **'RedGiant cannot be reached: check the connection.'**
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
  /// **'On this computer RedGiant does the update to {version} in its own window: it downloads, closes and starts again as the new version. Here you see the steps it reports.'**
  String updNowBodyLocal(String version);

  /// No description provided for @updFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow the update'**
  String get updFollow;

  /// No description provided for @upd2Title.
  ///
  /// In en, this message translates to:
  /// **'Updating RedGiant from {from} to {to}'**
  String upd2Title(String from, String to);

  /// No description provided for @upd2TitleTo.
  ///
  /// In en, this message translates to:
  /// **'Updating RedGiant to {to}'**
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
  /// **'RedGiant is restarting, reconnecting…'**
  String get upd2Restarting;

  /// No description provided for @upd2Attempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {n} · no answer for {time}'**
  String upd2Attempt(String n, String time);

  /// No description provided for @upd2Back.
  ///
  /// In en, this message translates to:
  /// **'RedGiant answers: checking it is the new version…'**
  String get upd2Back;

  /// No description provided for @upd2Keeps.
  ///
  /// In en, this message translates to:
  /// **'RedGiant keeps working while it downloads: it stops only for the restart, a minute or two.'**
  String get upd2Keeps;

  /// No description provided for @upd2ComesBack.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open: it reconnects by itself as soon as RedGiant answers as the new version.'**
  String get upd2ComesBack;

  /// No description provided for @upd2Local.
  ///
  /// In en, this message translates to:
  /// **'On this computer RedGiant does the update in its own window, with the bar and the time: here you see the steps it reports, and if this window stays open it reconnects by itself when RedGiant is back.'**
  String get upd2Local;

  /// No description provided for @upd2Older.
  ///
  /// In en, this message translates to:
  /// **'This RedGiant does not report each step\'s details yet (they come with 3.8.1): you see where it is and for how long.'**
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
  /// **'Back to RedGiant'**
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
  /// **'Restart RedGiant as the new version'**
  String get upd2Step_restart;

  /// No description provided for @upd2Step_wait.
  ///
  /// In en, this message translates to:
  /// **'Check that RedGiant answers'**
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
  /// **'Only a version signed by RedGiant is installed.'**
  String get upd2StepText_check;

  /// No description provided for @upd2StepText_download.
  ///
  /// In en, this message translates to:
  /// **'RedGiant keeps working while it downloads.'**
  String get upd2StepText_download;

  /// No description provided for @upd2StepText_files.
  ///
  /// In en, this message translates to:
  /// **'The programs of the system around RedGiant.'**
  String get upd2StepText_files;

  /// No description provided for @upd2StepText_install.
  ///
  /// In en, this message translates to:
  /// **'A copy of every file replaced is kept: if something goes wrong, it goes back as it was.'**
  String get upd2StepText_install;

  /// No description provided for @upd2StepText_restart.
  ///
  /// In en, this message translates to:
  /// **'For a minute or two RedGiant does not answer: the app reconnects by itself.'**
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
  /// **'Nothing changed: RedGiant {from} keeps working. Check that the machine reaches the internet, then press «Try again»: what came down already is not downloaded twice.'**
  String upd2WhyText_download(String from);

  /// No description provided for @upd2Why_files.
  ///
  /// In en, this message translates to:
  /// **'The system\'s new files could not be installed.'**
  String get upd2Why_files;

  /// No description provided for @upd2WhyText_files.
  ///
  /// In en, this message translates to:
  /// **'Every file went back as it was and RedGiant {from} keeps working. Try again in a while; if it happens again, download the diagnostics from the page (Settings › General › Diagnostics) and send them.'**
  String upd2WhyText_files(String from);

  /// No description provided for @upd2Why_not_up.
  ///
  /// In en, this message translates to:
  /// **'The new version did not start.'**
  String get upd2Why_not_up;

  /// No description provided for @upd2WhyText_not_up.
  ///
  /// In en, this message translates to:
  /// **'RedGiant went back to {from} by itself: nothing is lost. Try again in a while; if it happens again, download the diagnostics from the page (Settings › General › Diagnostics) and send them.'**
  String upd2WhyText_not_up(String from);

  /// No description provided for @upd2Why_no_images.
  ///
  /// In en, this message translates to:
  /// **'This version has nothing for this machine\'s processor.'**
  String get upd2Why_no_images;

  /// No description provided for @upd2WhyText_no_images.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: RedGiant {from} keeps working. Wait for the next version.'**
  String upd2WhyText_no_images(String from);

  /// No description provided for @upd2Why_breaking.
  ///
  /// In en, this message translates to:
  /// **'This version cannot be installed over the current one.'**
  String get upd2Why_breaking;

  /// No description provided for @upd2WhyText_breaking.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: RedGiant {from} keeps working. Open RedGiant\'s page from the computer: it guides you through the clean install.'**
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
  /// **'RedGiant does not answer any more.'**
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
  /// **'Nothing changed: RedGiant {from} keeps working. Try again in a while.'**
  String upd2WhyText_start(String from);

  /// No description provided for @upd2WhySaid.
  ///
  /// In en, this message translates to:
  /// **'RedGiant said: {error}'**
  String upd2WhySaid(String error);
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
