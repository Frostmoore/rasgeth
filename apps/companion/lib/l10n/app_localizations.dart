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

  /// No description provided for @chatDraftNote.
  ///
  /// In en, this message translates to:
  /// **'Message ready: sending comes with the next version of the app.'**
  String get chatDraftNote;

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
  /// **'redgiant.local:8787'**
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
