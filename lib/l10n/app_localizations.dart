import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('hi'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'NIRVANA'**
  String get appName;

  /// Greeting on onboarding and home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Nirvana'**
  String get welcomeTitle;

  /// Warm subtitle welcoming the user
  ///
  /// In en, this message translates to:
  /// **'A calm, gentle space designed for your comfort, memory, and peace of mind.'**
  String get welcomeSubtitle;

  /// Button to begin onboarding
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Next button in multi-step flows
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Button to go back to previous screen
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// Navigation label for Home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavLabel;

  /// Navigation label for Activities / Games Hub
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activitiesNavLabel;

  /// Navigation label for Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsNavLabel;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get todayGreetingMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get todayGreetingAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get todayGreetingEvening;

  /// Card title to start today's games
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activities'**
  String get dailyActivitiesCardTitle;

  /// Card subtitle for activities
  ///
  /// In en, this message translates to:
  /// **'Gentle memory and recognition games made for you.'**
  String get dailyActivitiesCardSubtitle;

  /// Primary action button to start activities
  ///
  /// In en, this message translates to:
  /// **'Start Activities'**
  String get startActivitiesButton;

  /// Daily comforting message on the home screen
  ///
  /// In en, this message translates to:
  /// **'Take your time. There is no rush, and you are doing wonderful.'**
  String get dailySupportiveMessage;

  /// Title for memories section
  ///
  /// In en, this message translates to:
  /// **'My Memories & Photos'**
  String get exploreMemoriesTitle;

  /// Subtitle for memories section
  ///
  /// In en, this message translates to:
  /// **'Look at familiar faces and cherished moments.'**
  String get exploreMemoriesSubtitle;

  /// Button to view memories
  ///
  /// In en, this message translates to:
  /// **'View Memories'**
  String get viewMemoriesButton;

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'App Settings & Comfort'**
  String get settingsTitle;

  /// Subtitle for settings screen
  ///
  /// In en, this message translates to:
  /// **'Adjust the app to make it easy and comfortable for your eyes.'**
  String get settingsSubtitle;

  /// Header for accessibility settings section
  ///
  /// In en, this message translates to:
  /// **'Visual & Motion Comfort'**
  String get accessibilitySectionTitle;

  /// Setting title for reduced motion
  ///
  /// In en, this message translates to:
  /// **'Reduced Motion'**
  String get reducedMotionTitle;

  /// Explanation of reduced motion
  ///
  /// In en, this message translates to:
  /// **'Turns off moving effects and animations for a steadier screen.'**
  String get reducedMotionSubtitle;

  /// Setting title for high contrast
  ///
  /// In en, this message translates to:
  /// **'High Contrast Mode'**
  String get highContrastTitle;

  /// Explanation of high contrast
  ///
  /// In en, this message translates to:
  /// **'Bolder text and stronger outlines for easier reading.'**
  String get highContrastSubtitle;

  /// Setting title for text size
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSizeTitle;

  /// Explanation of text size setting
  ///
  /// In en, this message translates to:
  /// **'Make words and numbers larger and clearer.'**
  String get textSizeSubtitle;

  /// Standard large text option
  ///
  /// In en, this message translates to:
  /// **'Large (Standard)'**
  String get textSizeStandard;

  /// Extra large text option
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get textSizeExtraLarge;

  /// Maximum text size option
  ///
  /// In en, this message translates to:
  /// **'Maximum Clarity'**
  String get textSizeMaximum;

  /// Setting title for language selection
  ///
  /// In en, this message translates to:
  /// **'Language / भाषा / Idioma'**
  String get languageTitle;

  /// Explanation of language selection
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language.'**
  String get languageSubtitle;

  /// Header on language selection screen
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get selectLanguageTitle;

  /// Subtitle on language selection screen
  ///
  /// In en, this message translates to:
  /// **'Tap the language you feel most comfortable using.'**
  String get selectLanguageSubtitle;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Spanish language name
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// Hindi language name
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get hindi;

  /// Button to confirm settings or language
  ///
  /// In en, this message translates to:
  /// **'Apply Selection'**
  String get saveAndApply;

  /// Onboarding step 1 title
  ///
  /// In en, this message translates to:
  /// **'A Gentle Companion'**
  String get onboardingStep1Title;

  /// Onboarding step 1 body
  ///
  /// In en, this message translates to:
  /// **'Nirvana is here to help keep your mind active with simple, pleasant daily moments.'**
  String get onboardingStep1Body;

  /// Onboarding step 2 title
  ///
  /// In en, this message translates to:
  /// **'Designed for Easy Reading'**
  String get onboardingStep2Title;

  /// Onboarding step 2 body
  ///
  /// In en, this message translates to:
  /// **'Everything is sized generously with clear buttons and no confusing menus.'**
  String get onboardingStep2Body;

  /// Onboarding step 3 title
  ///
  /// In en, this message translates to:
  /// **'Ready Whenever You Are'**
  String get onboardingStep3Title;

  /// Onboarding step 3 body
  ///
  /// In en, this message translates to:
  /// **'Take things at your own pace. There are no timers or penalties here.'**
  String get onboardingStep3Body;

  /// Button to complete onboarding
  ///
  /// In en, this message translates to:
  /// **'Enter Nirvana'**
  String get onboardingFinishButton;

  /// Supportive loading message
  ///
  /// In en, this message translates to:
  /// **'Getting everything ready for you...'**
  String get loadingMessage;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'Nothing Here Right Now'**
  String get emptyStateTitle;

  /// Empty state supportive text
  ///
  /// In en, this message translates to:
  /// **'Check back a little later or explore another activity.'**
  String get emptyStateMessage;

  /// Gentle error title avoiding harsh red words
  ///
  /// In en, this message translates to:
  /// **'Let\'s Take a Gentle Pause'**
  String get errorStateTitle;

  /// Supportive error message
  ///
  /// In en, this message translates to:
  /// **'We ran into a small hiccup. Everything is safe. Would you like to try again?'**
  String get errorStateMessage;

  /// Button to retry an action
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgainButton;

  /// Button to return to home screen
  ///
  /// In en, this message translates to:
  /// **'Return Home'**
  String get goHomeButton;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About Nirvana'**
  String get aboutAppTitle;

  /// About app version info
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0 • Compassionate Cognitive Care'**
  String get aboutAppVersion;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
