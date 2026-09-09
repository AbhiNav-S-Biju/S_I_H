import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kha.dart';
import 'app_localizations_lus.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('as'),
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('kha'),
    Locale('lus'),
    Locale('mni'),
    Locale('ne'),
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
  /// **'Language / ভাষা / भाषा'**
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

  /// Hindi language name
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get hindi;

  /// Assamese language name
  ///
  /// In en, this message translates to:
  /// **'অসমীয়া (Assamese)'**
  String get assamese;

  /// Bengali language name
  ///
  /// In en, this message translates to:
  /// **'বাংলা (Bengali)'**
  String get bengali;

  /// Manipuri / Meitei language name
  ///
  /// In en, this message translates to:
  /// **'মৈতৈলোন্ (Manipuri / Meitei)'**
  String get manipuri;

  /// Khasi language name
  ///
  /// In en, this message translates to:
  /// **'Ka Ktien Khasi'**
  String get khasi;

  /// Mizo language name
  ///
  /// In en, this message translates to:
  /// **'Mizo ṭawng'**
  String get mizo;

  /// Nepali language name
  ///
  /// In en, this message translates to:
  /// **'नेपाली (Nepali)'**
  String get nepali;

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

  /// Title for daily activities
  ///
  /// In en, this message translates to:
  /// **'Daily Activities'**
  String get activitiesTitle;

  /// Banner title in activities screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Today\'s Fun!'**
  String get activitiesBannerTitle;

  /// Banner subtitle in activities screen
  ///
  /// In en, this message translates to:
  /// **'Choose an enjoyable activity below. Take all the time you like.'**
  String get activitiesBannerSubtitle;

  /// Activity pace label
  ///
  /// In en, this message translates to:
  /// **'Activity Pace:'**
  String get activityPace;

  /// Gentle pace option
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get paceGentle;

  /// Standard pace option
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get paceStandard;

  /// Challenge pace option
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get paceChallenge;

  /// Title of Remember Objects game
  ///
  /// In en, this message translates to:
  /// **'Remember Objects'**
  String get gameRememberObjectsTitle;

  /// Subtitle of Remember Objects game
  ///
  /// In en, this message translates to:
  /// **'Look at the friendly items, then tap what you saw'**
  String get gameRememberObjectsSubtitle;

  /// Title of Who Is This game
  ///
  /// In en, this message translates to:
  /// **'Who Is This?'**
  String get gameWhoIsThisTitle;

  /// Subtitle of Who Is This game
  ///
  /// In en, this message translates to:
  /// **'Recognize familiar faces and loved ones'**
  String get gameWhoIsThisSubtitle;

  /// Title of Grocery Memory game
  ///
  /// In en, this message translates to:
  /// **'Grocery Memory'**
  String get gameGroceryMemoryTitle;

  /// Subtitle of Grocery Memory game
  ///
  /// In en, this message translates to:
  /// **'Collect everyday items from your shopping list'**
  String get gameGroceryMemorySubtitle;

  /// Title of Dementia-Friendly Jigsaw Puzzle game
  ///
  /// In en, this message translates to:
  /// **'Familiar Jigsaw'**
  String get gameJigsawPuzzleTitle;

  /// Subtitle of Dementia-Friendly Jigsaw Puzzle game
  ///
  /// In en, this message translates to:
  /// **'Put together comforting pictures piece by piece'**
  String get gameJigsawPuzzleSubtitle;

  /// Button to start an activity
  ///
  /// In en, this message translates to:
  /// **'Play Activity ➔'**
  String get playActivityButton;

  /// Tooltip for exiting activity
  ///
  /// In en, this message translates to:
  /// **'Exit Activity'**
  String get exitActivityTooltip;

  /// Title of exit confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Leave Activity?'**
  String get leaveActivityTitle;

  /// Body message of exit confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to pause and return to the main screen? Your gentle progress is always saved.'**
  String get leaveActivityMessage;

  /// Button to stay in activity
  ///
  /// In en, this message translates to:
  /// **'Stay & Continue'**
  String get stayAndContinue;

  /// Button to exit activity
  ///
  /// In en, this message translates to:
  /// **'Yes, Exit'**
  String get yesExit;

  /// Hint button label
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hintButton;

  /// Title for activity completion
  ///
  /// In en, this message translates to:
  /// **'Activity Completed!'**
  String get activityCompletedTitle;

  /// Finish button label
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton;

  /// Instructions for memorization phase
  ///
  /// In en, this message translates to:
  /// **'Look at these items carefully. Take all the time you need.'**
  String get rememberObjectsLookCarefully;

  /// Button to proceed to recall phase
  ///
  /// In en, this message translates to:
  /// **'I am Ready ➔'**
  String get iAmReadyButton;

  /// Instructions for recall phase
  ///
  /// In en, this message translates to:
  /// **'Which items did you see? Tap them below:'**
  String get whichItemsDidYouSee;

  /// Button to complete activity
  ///
  /// In en, this message translates to:
  /// **'Complete Activity ➔'**
  String get completeActivityButton;

  /// Family and friends tag
  ///
  /// In en, this message translates to:
  /// **'Family & Friends'**
  String get familyAndFriends;

  /// Shopping list title
  ///
  /// In en, this message translates to:
  /// **'Your Shopping List'**
  String get shoppingListTitle;

  /// Shopping list subtitle
  ///
  /// In en, this message translates to:
  /// **'Review these items, then tap \'Start Shopping\' when ready.'**
  String get shoppingListSubtitle;

  /// Button to start shopping phase
  ///
  /// In en, this message translates to:
  /// **'Start Shopping ➔'**
  String get startShoppingButton;

  /// Instructions for finding items on shelf
  ///
  /// In en, this message translates to:
  /// **'Tap items from your list to put them in your cart:'**
  String get findItemsOnShelf;

  /// Welcome header on landing page
  ///
  /// In en, this message translates to:
  /// **'Welcome to NIRVANA'**
  String get landingWelcomeTitle;

  /// Subtitle on landing page prompting portal selection
  ///
  /// In en, this message translates to:
  /// **'Choose how you would like to continue.'**
  String get landingSubtitle;

  /// Title for Patient Portal
  ///
  /// In en, this message translates to:
  /// **'Patient Portal'**
  String get patientPortalTitle;

  /// Subtitle for Patient Portal
  ///
  /// In en, this message translates to:
  /// **'For patients and loved ones'**
  String get patientPortalSubtitle;

  /// Description for Patient Portal
  ///
  /// In en, this message translates to:
  /// **'Access your daily activities, reminders and family connections.'**
  String get patientPortalDescription;

  /// Action button to enter Patient Portal
  ///
  /// In en, this message translates to:
  /// **'Enter Patient Portal'**
  String get patientPortalButton;

  /// Title for Caregiver Portal
  ///
  /// In en, this message translates to:
  /// **'Caregiver Portal'**
  String get caregiverPortalTitle;

  /// Subtitle for Caregiver Portal
  ///
  /// In en, this message translates to:
  /// **'For caregivers'**
  String get caregiverPortalSubtitle;

  /// Description for Caregiver Portal
  ///
  /// In en, this message translates to:
  /// **'Manage patients, reminders, activities and caregiver information.'**
  String get caregiverPortalDescription;

  /// Action button to enter Caregiver Portal
  ///
  /// In en, this message translates to:
  /// **'Enter Caregiver Portal'**
  String get caregiverPortalButton;

  /// Title of the Ask NIRVANA screen
  ///
  /// In en, this message translates to:
  /// **'Ask NIRVANA'**
  String get askNirvanaTitle;

  /// Idle status label for the NIRVANA assistant
  ///
  /// In en, this message translates to:
  /// **'NIRVANA Companion'**
  String get askNirvanaCompanionLabel;

  /// Status label when voice recognition is active
  ///
  /// In en, this message translates to:
  /// **'I\'m listening...'**
  String get askNirvanaListening;

  /// Status label when assistant is generating response
  ///
  /// In en, this message translates to:
  /// **'Let me think...'**
  String get askNirvanaThinking;

  /// Status label when TTS is playing
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get askNirvanaSpeaking;

  /// Prompt below microphone button in idle state
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get askNirvanaTapToSpeak;

  /// Prompt below microphone button in listening state
  ///
  /// In en, this message translates to:
  /// **'I\'m listening... (Tap to finish)'**
  String get askNirvanaListeningPrompt;

  /// Prompt below microphone button in speaking state
  ///
  /// In en, this message translates to:
  /// **'Speaking... (Tap to stop)'**
  String get askNirvanaSpeakingPrompt;

  /// Prompt below microphone button in thinking state
  ///
  /// In en, this message translates to:
  /// **'Let me think...'**
  String get askNirvanaThinkingPrompt;

  /// Error state prompt under microphone button
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t understand that. Please try again.'**
  String get askNirvanaErrorPrompt;

  /// Clear conversation button label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get askNirvanaClearButton;

  /// Dialog title when confirming conversation clear
  ///
  /// In en, this message translates to:
  /// **'Clear Conversation?'**
  String get askNirvanaClearTitle;

  /// Dialog body for conversation clear confirmation
  ///
  /// In en, this message translates to:
  /// **'This will start a fresh, new conversation. Are you sure?'**
  String get askNirvanaClearMessage;

  /// Button to read assistant response aloud
  ///
  /// In en, this message translates to:
  /// **'Read Aloud'**
  String get askNirvanaReadAloud;

  /// Hint text for the secondary text input field
  ///
  /// In en, this message translates to:
  /// **'Or type here...'**
  String get askNirvanaTypeHere;

  /// Initial greeting message from the NIRVANA assistant
  ///
  /// In en, this message translates to:
  /// **'Hello! I am NIRVANA, your companion. Tap the large microphone below to talk with me, or type your question.'**
  String get askNirvanaGreeting;

  /// Message shown when speech recognition returns empty result
  ///
  /// In en, this message translates to:
  /// **'I didn\'t hear anything. Tap to speak again.'**
  String get askNirvanaNoSpeech;

  /// Message shown when speech recognition is unavailable
  ///
  /// In en, this message translates to:
  /// **'Microphone or speech recognition is not ready. You can type below anytime.'**
  String get askNirvanaMicUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'as',
    'bn',
    'en',
    'hi',
    'kha',
    'lus',
    'mni',
    'ne',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kha':
      return AppLocalizationsKha();
    case 'lus':
      return AppLocalizationsLus();
    case 'mni':
      return AppLocalizationsMni();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
