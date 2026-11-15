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
