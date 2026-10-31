# Graph Report - lib  (2026-10-31)

## Corpus Check
- 189 files · ~147,679 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 8 file(s) not represented in the graph (top: .arb 8)

## Summary
- 5341 nodes · 6838 edges · 146 communities (133 shown, 13 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- L10n Locale Classes
- L10n Base Strings (Hindi)
- L10n Assamese Strings
- L10n Bengali Strings
- L10n English Strings
- L10n Khasi Strings
- L10n Mizo Strings
- L10n Manipuri Strings
- L10n Nepali Strings
- Caregiver Models
- Elder Theme Colors
- Patient Device Panel
- Audio & TTS Service
- Location Help Providers
- Clay 3D Header
- Caregiver Providers
- Jigsaw Puzzle Controller
- Hive Adapters
- Patient Dashboard
- Caregiver Patient Onboarding
- Voice & Locale Providers
- Elder App Shell
- Location Help Models
- Patient Pairing Providers
- Game Progress Service
- Responsive Layout
- Elder Card Widget
- Supabase Caregiver Repo
- Caregiver Push Notifications
- Caregiver Dashboard Pages
- AI Assistant Service
- Reminder Status List
- Jigsaw Puzzle Screen
- Clay 3D Scaffold
- Caregiver Patient Location
- Phone Formatting
- Location Help Dialogs
- Accessibility Providers
- Elder Game Button
- Supabase Repo Contracts
- Family Photos Screen
- Clay Button & Session Restore
- Clay 3D Card
- Notification Service
- Games Hub Screen
- Sync Engine
- Social Account Encryption
- Ask Nirvana & Onboarding UI
- Who Is This Game
- Ask Nirvana Provider
- Game Level Model
- Reminder Providers
- Game Session Providers
- Game Completion Dialog
- Backend SMS Service
- Clay 3D Painters
- Ask Nirvana Intent
- Patient Pairing Screen
- App Router
- Family Photo Providers
- Grocery Memory Controller
- Games
- Utils/Voice Helper
- Ai Assistant Service
- Family Member Item
- Remember Objects Controller
- Clay 3D Theme
- Caregiver Dashboard Pages 2
- Supabase Sync Repository
- Difficulty Recommender
- Ask Nirvana Screen
- Puzzle Item
- Family Photo
- Hive Reminder Repository
- Caregiver Register Screen
- Clay 3D Input
- Who Is This Screen
- Caregiver Repository
- Repositories/Location Help
- Patient Home Screen
- Patient Welcome Screen
- Clay 3D Section
- Widgets/Voice Helper
- Game Session
- Patient Reminders Screen
- Patient Pairing Success Screen
- Hive Boxes
- Game Level Map Screen
- Reminder
- Needs Help Banner
- Nirvana Story Service
- Social Media Accounts Section
- Community 93 ConsumerWidget
- Supabase Config
- Hive Difficulty Stats
- Caregiver Event Notification Service
- Social Media Account
- Caregiver Notification Repository
- Location Sharing Active Screen
- Remember Objects Screen
- Community 101 build
- Grocery Memory Screen
- Game Item
- Social Media Account Form
- Nirvana Story
- Connectivity Monitor
- Hive Family Photo
- Hive Reminder
- Hive Sync Event
- Nirvana Intent Router
- Caregiver Login Screen
- Puzzle Piece Tile
- Elder Game Card
- Game Level Map Path
- Patient Header
- Social Media Account Providers
- Hive Patient Session
- Reminder Log
- Game Enums
- Supabase Reminder Pull Repository
- Caregiver Bottom Navigation
- Location Help Repository
- Community 124 build
- Community 125 AppLocalizations
- Location Service
- Puzzle Board
- Hive Reminder Log
- Community 130 build
- Game Header
- Help Flow
- Generated/App Localizations
- Caregiver Notification Repository 2
- Pairing Repository
- Clay 3D Dialog
- Session Restore Gate
- Community 140 _handleLogin
- Community 141 _handleRegister
- Community 142 AudioService

## God Nodes (most connected - your core abstractions)
1. `localeProvider` - 41 edges
2. `_` - 31 edges
3. `voiceEnabledProvider` - 26 edges
4. `caregiverAuthProvider` - 14 edges
5. `selectedPatientProvider` - 14 edges
6. `AppLocalizations` - 13 edges
7. `GameDifficulty` - 12 edges
8. `localPatientSessionProvider` - 12 edges
9. `highContrastProvider` - 10 edges
10. `IConnectivityMonitor` - 10 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `localeProvider`  [EXTRACTED]
  features/games/presentation/jigsaw_puzzle/jigsaw_puzzle_screen.dart → app/providers/accessibility_providers.dart
- `_handleHint` --references--> `localeProvider`  [EXTRACTED]
  features/games/presentation/jigsaw_puzzle/jigsaw_puzzle_screen.dart → app/providers/accessibility_providers.dart
- `_handleSlotDrop` --references--> `localeProvider`  [EXTRACTED]
  features/games/presentation/jigsaw_puzzle/jigsaw_puzzle_screen.dart → app/providers/accessibility_providers.dart
- `_openPictureSelector` --references--> `localeProvider`  [EXTRACTED]
  features/games/presentation/jigsaw_puzzle/jigsaw_puzzle_screen.dart → app/providers/accessibility_providers.dart
- `build` --references--> `localeProvider`  [EXTRACTED]
  features/games/presentation/widgets/game_completion_dialog.dart → app/providers/accessibility_providers.dart

## Import Cycles
- None detected.

## Communities (146 total, 13 thin omitted)

### Community 0 - "L10n Locale Classes"
Cohesion: 0.01
Nodes (243): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+235 more)

### Community 1 - "L10n Base Strings (Hindi)"
Cohesion: 0.01
Nodes (235): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+227 more)

### Community 2 - "L10n Assamese Strings"
Cohesion: 0.01
Nodes (235): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+227 more)

### Community 3 - "L10n Bengali Strings"
Cohesion: 0.01
Nodes (235): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+227 more)

### Community 4 - "L10n English Strings"
Cohesion: 0.01
Nodes (235): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+227 more)

### Community 5 - "L10n Khasi Strings"
Cohesion: 0.01
Nodes (235): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+227 more)

### Community 6 - "L10n Mizo Strings"
Cohesion: 0.01
Nodes (235): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+227 more)

### Community 7 - "L10n Manipuri Strings"
Cohesion: 0.01
Nodes (235): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+227 more)

### Community 8 - "L10n Nepali Strings"
Cohesion: 0.01
Nodes (235): aboutAppTitle, aboutAppVersion, accessibilitySectionTitle, accountActionsTooltip, accountDeletedSnack, accountDeleteErrorSnack, accountsNavLabel, activitiesBannerSubtitle (+227 more)

### Community 9 - "Caregiver Models"
Cohesion: 0.02
Nodes (100): accessibilitySettings, acknowledgedAt, audioPrompts, avatarUrl, CaregiverGameRecord, caregiverId, caregiverPhone, CaregiverProfile (+92 more)

### Community 10 - "Elder Theme Colors"
Cohesion: 0.02
Nodes (98): amberBg, amberBorder, amberDeep, background, backgroundAlt, backgroundClay, border, borderHighContrast (+90 more)

### Community 11 - "Patient Device Panel"
Cohesion: 0.04
Nodes (66): _ActiveCodeCard, code, _ConnectedDeviceCard, contactAsync, _copyPasscode, _countdownTimer, createState, device (+58 more)

### Community 12 - "Audio & TTS Service"
Cohesion: 0.03
Nodes (46): _activeSpeechCompleter, _activeTtsLanguage, AudioFeedbackType, _audioPlayer, _availableLanguages, cloudTtsLanguageMap, _currentLanguage, _discoverAvailableLanguages (+38 more)

### Community 13 - "Location Help Providers"
Cohesion: 0.04
Nodes (53): caregiverLocationHelpNotifierProvider, caregiverName, caregiverPhone, clearError, confirmAndStart, copyWith, currentLocation, _deviceId (+45 more)

### Community 14 - "Clay 3D Header"
Cohesion: 0.04
Nodes (42): build, ClayHeader3D, _HeaderIconButton, icon, onBack, onTap, semanticLabel, subtitle (+34 more)

### Community 15 - "Caregiver Providers"
Cohesion: 0.04
Nodes (45): CaregiverSyncInfo, PairingCodeInfo, backendSmsServiceProvider, _bumpSessionRevision, caregiverEventNotificationServiceProvider, caregiverNotificationRepositoryProvider, caregiverNotificationsNotifierProvider, caregiverNotificationsProvider (+37 more)

### Community 16 - "Jigsaw Puzzle Controller"
Cohesion: 0.04
Nodes (45): activeImage, adaptiveDifficultySuggestion, allPieces, availableImages, changeDifficulty, changeImage, col, cols (+37 more)

### Community 17 - "Hive Adapters"
Cohesion: 0.06
Nodes (33): HiveDifficultyStatsAdapter, HiveFamilyPhotoAdapter, HivePatientDeviceSessionAdapter, HiveReminderAdapter, HiveReminderLogAdapter, HiveSyncEventAdapter, read, typeId (+25 more)

### Community 18 - "Patient Dashboard"
Cohesion: 0.04
Nodes (46): _ActionCardItem, bannerInset, bannerLavender, canvas, cardSurface, center, ClayActionCard, clayCardShadow (+38 more)

### Community 19 - "Caregiver Patient Onboarding"
Cohesion: 0.05
Nodes (43): _audioPrompts, _buildBottomBar, _buildClayField, _buildCurrentStepContent, _buildFieldLabel, _buildProgressIndicator, _buildStep1PatientInformation, _buildStep2AccessibilityPreferences (+35 more)

### Community 20 - "Voice & Locale Providers"
Cohesion: 0.09
Nodes (40): localeProvider, voiceEnabledProvider, audioServiceProvider, isSpeakingProvider, build, VoiceHelper, VoiceOnboardingPrompt, build (+32 more)

### Community 21 - "Elder App Shell"
Cohesion: 0.07
Nodes (27): build, _buildNavItem, ElderAppShell, navigationShell, _onTap, createTextTheme, ElderTypography, CaregiverNotification (+19 more)

### Community 22 - "Location Help Models"
Cohesion: 0.05
Nodes (40): accuracy, active, ActiveSessionCheckResult, altitude, caregiverId, caregiverName, caregiverPhone, createdAt (+32 more)

### Community 23 - "Patient Pairing Providers"
Cohesion: 0.06
Nodes (25): PairDeviceResult, copyWith, errorMessage, isDevicePairedProvider, isError, isLoading, isSuccess, monitor (+17 more)

### Community 24 - "Game Progress Service"
Cohesion: 0.05
Nodes (33): _allCompletedDates, areAllLevelsCompleted, _box, _boxName, _cache, checkAndPerformDailyReset, completeLevel, dispose (+25 more)

### Community 25 - "Responsive Layout"
Cohesion: 0.05
Nodes (37): build, child, children, compact, expanded, gridChildWidth, gridColumns, isAtLeastMedium (+29 more)

### Community 26 - "Elder Card Widget"
Cohesion: 0.06
Nodes (33): backgroundColor, borderColor, borderRadius, borderWidth, build, child, customShadow, ElderCard (+25 more)

### Community 27 - "Supabase Caregiver Repo"
Cohesion: 0.05
Nodes (32): _cachedProfile, _cacheFamilyPhoto, _client, _connectivityMonitor, createPatient, createReminder, deleteReminder, _difficultyLevelToString (+24 more)

### Community 28 - "Caregiver Push Notifications"
Cohesion: 0.05
Nodes (33): body, CaregiverNotificationPayload, CaregiverPushNotificationService, channelDescription, channelId, channelName, currentFcmToken, _currentToken (+25 more)

### Community 29 - "Caregiver Dashboard Pages"
Cohesion: 0.06
Nodes (23): build, CaregiverAlertsPage, CaregiverHomePage, CaregiverRemindersPage, children, icon, _PageSectionTitle, title (+15 more)

### Community 30 - "AI Assistant Service"
Cohesion: 0.06
Nodes (26): _activityResponse, _aiService, executeTool, _familyPhotos, _familyResponse, _gameResponse, _goodbyeResponse, _gratitudeResponse (+18 more)

### Community 31 - "Reminder Status List"
Cohesion: 0.06
Nodes (31): CaregiverReminderRecord, _AddOrEditReminderSheet, _AddOrEditReminderSheetState, _allDays, createState, _descController, dispose, _formatRecurrence (+23 more)

### Community 32 - "Jigsaw Puzzle Screen"
Cohesion: 0.06
Nodes (26): JigsawPuzzleController, PuzzleImage, build, _buildAdaptivePaceBanner, _buildTrayPieces, _controller, createState, difficulty (+18 more)

### Community 33 - "Clay 3D Scaffold"
Cohesion: 0.07
Nodes (17): build, FloatingAmbient3DLayer, showBottomWave, showLeftCloud, appBar, body, bottomNavigationBar, build (+9 more)

### Community 34 - "Caregiver Patient Location"
Cohesion: 0.08
Nodes (27): selectedPatientProvider, _buildRecallView, LocationSession, PatientLocation, build, _callPatient, CaregiverPatientLocationScreen, _CaregiverPatientLocationScreenState (+19 more)

### Community 35 - "Phone Formatting"
Cohesion: 0.07
Nodes (26): _, defaultCountryCode, format, isValid, mask, PhoneFormat, toDialable, toSmsDialable (+18 more)

### Community 36 - "Location Help Dialogs"
Cohesion: 0.06
Nodes (26): build, LocationHelpConfirmationDialog, LocationPermissionRationaleDialog, onCancel, onConfirm, onOpenSettings, build, HelpButton (+18 more)

### Community 37 - "Accessibility Providers"
Cohesion: 0.09
Nodes (25): HighContrastNotifier, _loadSavedLocale, LocaleNotifier, nirvanaFullySupportedLocales, _persist, ReducedMotionNotifier, scale, setHighContrast (+17 more)

### Community 38 - "Elder Game Button"
Cohesion: 0.07
Nodes (20): backgroundColor, build, ElderGameButton, foregroundColor, icon, isSecondary, label, minHeight (+12 more)

### Community 39 - "Supabase Repo Contracts"
Cohesion: 0.07
Nodes (29): generatePairingCode, getAccessiblePatients, getActiveReminders, getCurrentProfile, getDevices, getFamilyPhotos, getGameSessionsByPatient, getNotifications (+21 more)

### Community 40 - "Family Photos Screen"
Cohesion: 0.07
Nodes (28): action, build, _choosePhoto, createState, _delete, dispose, _editing, _FamilyPhotoEditor (+20 more)

### Community 41 - "Clay Button & Session Restore"
Cohesion: 0.07
Nodes (24): build, RestoringSessionScreen, borderRadius, build, ClayButton3D, color, icon, isLoading (+16 more)

### Community 42 - "Clay 3D Card"
Cohesion: 0.07
Nodes (24): borderRadius, build, child, ClayCard3D, ClayPill3D, ClaySlab3D, color, customShadows (+16 more)

### Community 43 - "Notification Service"
Cohesion: 0.07
Nodes (20): firebaseMessagingBackgroundHandler, cancelAll, cancelReminder, channelDesc, channelId, channelName, _ensureTimeZoneInitialized, handleNotificationResponse (+12 more)

### Community 44 - "Games Hub Screen"
Cohesion: 0.09
Nodes (9): _buildGameCard, createState, initState, onSessionCompleted, completeOnboarding, resetOnboarding, LanguageSelectorScreen, _buildScaleOption (+1 more)

### Community 45 - "Sync Engine"
Cohesion: 0.07
Nodes (24): box, calculateBackoff, _connectivityMonitor, _connectivitySub, deadLettered, dispose, engine, enqueueEvent (+16 more)

### Community 46 - "Social Account Encryption"
Cohesion: 0.08
Nodes (19): applicationPepper, derive, keyFor, _keyLengthInBytes, SocialAccountEncryptionKey, _storage, storageKeyPrefix, _cipher (+11 more)

### Community 47 - "Ask Nirvana & Onboarding UI"
Cohesion: 0.12
Nodes (21): highContrastProvider, reducedMotionProvider, textScaleProvider, appRouterProvider, _AskNirvanaScreenState, build, build, createState (+13 more)

### Community 48 - "Who Is This Game"
Cohesion: 0.07
Nodes (24): activeHintText, answers, availableFamily, completeGame, copyWith, currentQuestion, currentQuestionIndex, difficulty (+16 more)

### Community 49 - "Ask Nirvana Provider"
Cohesion: 0.08
Nodes (26): AskNirvanaNotifier, AskNirvanaState, AssistantVoiceState, _audioService, clearConversation, copyWith, dispose, errorMessage (+18 more)

### Community 50 - "Game Level Model"
Cohesion: 0.07
Nodes (25): bestScore, completedAt, config, description, difficulty, fromMap, gameType, getJourneySubtitle (+17 more)

### Community 51 - "Reminder Providers"
Cohesion: 0.08
Nodes (19): eventService, getActiveReminders, getReminderLogs, pull, reminderLogsProvider, reminderPullRepositoryProvider, repo, syncEngine (+11 more)

### Community 52 - "Game Session Providers"
Cohesion: 0.08
Nodes (16): gameSessionRepositoryProvider, monitor, IGameSessionRepository, _client, _connectivityMonitor, _difficultyToInt, _generateUuid, getRecentGameSessions (+8 more)

### Community 53 - "Game Completion Dialog"
Cohesion: 0.08
Nodes (21): GameLevel, GameLevelProgress, build, _buildMetric, _calculateStars, createState, _getStarEncouragement, level (+13 more)

### Community 54 - "Backend SMS Service"
Cohesion: 0.08
Nodes (24): _, backendSent, BackendSmsService, buildPasscodeSmsBody, channel, composerOpened, _defaultLaunch, failure (+16 more)

### Community 55 - "Clay 3D Painters"
Cohesion: 0.10
Nodes (23): center, ClayCloud3DPainter, ClayHeart3DPainter, ClayPebble3DPainter, ClaySphere3DPainter, ClayStar3DPainter, ClayWaveLandscape3DPainter, _CloudSphere (+15 more)

### Community 56 - "Ask Nirvana Intent"
Cohesion: 0.08
Nodes (22): activity, dailyRoutine, fallback, familyInfo, gameAction, GameIntentAction, games, generalConversation (+14 more)

### Community 57 - "Patient Pairing Screen"
Cohesion: 0.09
Nodes (22): autofocus, build, _Clay3DPinBox, _clearAll, _codeLength, controller, _controllers, createState (+14 more)

### Community 58 - "App Router"
Cohesion: 0.08
Nodes (8): gamesNavigatorKey, homeNavigatorKey, initialLocation, pushService, refreshListenable, rootNavigatorKey, router, tapSub

### Community 59 - "Family Photo Providers"
Cohesion: 0.09
Nodes (14): familyPhotoActionsProvider, familyPhotoRepositoryProvider, IFamilyPhotoRepository, pairedPatientId, patientId, ref, remove, repository (+6 more)

### Community 60 - "Grocery Memory Controller"
Cohesion: 0.08
Nodes (21): availableGroceries, basketItemIds, completeGame, copyWith, difficulty, GroceryMemoryState, hintHighlightedItemId, hintsUsed (+13 more)

### Community 62 - "Utils/Voice Helper"
Cohesion: 0.09
Nodes (20): _audioService, child, createState, enableVoiceFeedback, errorMessage, isSpeaking, listen, listeningPrompt (+12 more)

### Community 63 - "Ai Assistant Service"
Cohesion: 0.09
Nodes (20): aiAssistantServiceProvider, client, _connectionFailureMessages, connectivity, _connectivityMonitor, getAiFallbackResponse, getAiResponse, _getConnectionFailureMessage (+12 more)

### Community 64 - "Family Member Item"
Cohesion: 0.09
Nodes (21): alternativeRelationshipOptions, avatarColor, avatarIcon, defaultFamilyMembers, FamilyMemberItem, fromFamilyPhoto, hintDescription, id (+13 more)

### Community 65 - "Remember Objects Controller"
Cohesion: 0.09
Nodes (21): availableCatalogue, completeGame, copyWith, difficulty, hintHighlightedItemId, hintsUsed, isCompleted, isMemorizationPhase (+13 more)

### Community 66 - "Clay 3D Theme"
Cohesion: 0.09
Nodes (20): buttonShadow, canvas, cardShadow, cardSurface, Clay3DTheme, coral, coralLight, deepShadow (+12 more)

### Community 67 - "Caregiver Dashboard Pages 2"
Cohesion: 0.13
Nodes (16): build, CaregiverDashboardScreen, _CaregiverDashboardScreenState, createState, _logout, _refreshData, _selectedIndex, _titles (+8 more)

### Community 68 - "Supabase Sync Repository"
Cohesion: 0.10
Nodes (15): ISupabaseSyncRepository, _client, processSyncEvent, processSyncEventsBatch, SupabaseSyncRepository, _client, _connectivityMonitor, _generateLocalDemoCode (+7 more)

### Community 69 - "Difficulty Recommender"
Cohesion: 0.09
Nodes (18): _computeReward, DifficultyRecommender, difficultyRecommenderProvider, _epsilon, _getStats, kDefaultPatientId, _key, _maxWindowSize (+10 more)

### Community 70 - "Ask Nirvana Screen"
Cohesion: 0.10
Nodes (20): _buildAssistantHeaderArea, _buildChatBubble, _buildConversationList, _buildLiveTranscriptBubble, _buildPrimaryMicrophoneArea, _buildSecondaryTextInputArea, _confirmClearConversation, createState (+12 more)

### Community 71 - "Puzzle Item"
Cohesion: 0.09
Nodes (20): assetPath, categoryIcon, courtyardGarden, defaultFamiliarImages, description, familyGathering, getLandmarkClue, homeKitchen (+12 more)

### Community 72 - "Family Photo"
Cohesion: 0.10
Nodes (18): audioNoteUrl, copyWith, createdAt, displayOrder, fromHive, fromMap, hasPhoto, id (+10 more)

### Community 73 - "Hive Reminder Repository"
Cohesion: 0.10
Nodes (16): SyncEngine, completeReminder, createReminder, deleteReminder, dismissReminderLaterToday, _eventNotificationService, getActiveReminders, getReminderById (+8 more)

### Community 74 - "Caregiver Register Screen"
Cohesion: 0.10
Nodes (20): _buildClayInput, CaregiverRegisterScreen, _CaregiverRegisterScreenState, _confirmPasswordController, createState, dispose, _emailController, _errorMessage (+12 more)

### Community 75 - "Clay 3D Input"
Cohesion: 0.10
Nodes (16): autofocus, build, ClayTextField3D, controller, enabled, hint, isRequired, keyboardType (+8 more)

### Community 76 - "Who Is This Screen"
Cohesion: 0.11
Nodes (16): whoIsThisFamilyMembersProvider, WhoIsThisController, _controller, createState, difficulty, _handleCompletion, _handleExit, initState (+8 more)

### Community 78 - "Caregiver Repository"
Cohesion: 0.11
Nodes (18): createPatient, createReminder, deleteReminder, getAssignedPatients, getCurrentCaregiver, getFamilyPhotos, getGameHistory, getReminderStatus (+10 more)

### Community 79 - "Repositories/Location Help"
Cohesion: 0.10
Nodes (13): checkActiveSession, _client, _connectivityMonitor, fetchCaregiverActiveSession, getLatestLocation, startLocationSession, stopLocationSession, updateLocation (+5 more)

### Community 80 - "Patient Home Screen"
Cohesion: 0.11
Nodes (13): createState, dispose, _duePopupChecked, _formattedDate, initState, _onScroll, PatientHomeScreen, _PatientHomeScreenState (+5 more)

### Community 81 - "Patient Welcome Screen"
Cohesion: 0.12
Nodes (13): ClaySurface, _ClaySurfaceState, _animController, build, createState, dispose, _fadeAnim, initState (+5 more)

### Community 82 - "Clay 3D Section"
Cohesion: 0.11
Nodes (18): accentColor, badge, build, caption, child, ClayFeatureCard3D, ClaySection3D, ClayStatCard3D (+10 more)

### Community 83 - "Widgets/Voice Helper"
Cohesion: 0.11
Nodes (17): activeColor, _animationController, createState, dispose, icon, inactiveColor, initState, _isListening (+9 more)

### Community 84 - "Game Session"
Cohesion: 0.11
Nodes (17): activityMetadata, completedAt, correctAnswers, difficulty, durationSeconds, fromJson, GameSession, gameType (+9 more)

### Community 85 - "Patient Reminders Screen"
Cohesion: 0.11
Nodes (16): _ClayProgressBanner3D, completedCount, createState, _formatTime, _formatTimeOfDay, _isSameDay, _NotificationTile, now (+8 more)

### Community 86 - "Patient Pairing Success Screen"
Cohesion: 0.12
Nodes (12): build, build, _animController, build, createState, dispose, _fadeAnim, initState (+4 more)

### Community 87 - "Hive Boxes"
Cohesion: 0.11
Nodes (16): difficultyStats, familyPhotos, HiveBoxes, hiveDifficultyStats, hiveFamilyPhoto, hivePatientDeviceSession, hiveReminder, hiveReminderLog (+8 more)

### Community 88 - "Game Level Map Screen"
Cohesion: 0.11
Nodes (11): _buildBottomActionBar, _buildTopHeader, _confirmReset, createState, dispose, gameType, _getLockedMessage, initState (+3 more)

### Community 89 - "Reminder"
Cohesion: 0.11
Nodes (17): body, completedAt, copyWith, createdAt, fromHive, id, isActive, isCompleted (+9 more)

### Community 90 - "Needs Help Banner"
Cohesion: 0.14
Nodes (11): _launchLevel, _openGameMap, startHelpFlow, build, NeedsHelpBanner, build, _formatTime, _FreshnessDot (+3 more)

### Community 91 - "Nirvana Story Service"
Cohesion: 0.12
Nodes (13): formatStoryResponse, getStory, _lastStoryId, NirvanaStoryService, nirvanaStoryServiceProvider, _random, reset, build (+5 more)

### Community 92 - "Social Media Accounts Section"
Cohesion: 0.12
Nodes (12): SocialMediaAccount, account, _AccountAction, build, _copyPassword, onDelete, onEdit, _showEditor (+4 more)

### Community 93 - "Community 93 ConsumerWidget"
Cohesion: 0.15
Nodes (15): VoiceFeedbackWrapper, _CaregiverScrollPage, ActivitySummaryCards, build, build, GameHistoryList, build, ReminderStatusList (+7 more)

### Community 94 - "Supabase Config"
Cohesion: 0.12
Nodes (12): isConfigured, supabaseAnonKey, SupabaseConfig, supabaseUrl, done, fromString, label, laterToday (+4 more)

### Community 95 - "Hive Difficulty Stats"
Cohesion: 0.12
Nodes (12): difficultyId, gameTypeId, lastPlayedAt, patientId, rewardScores, sessionCount, copyWith, id (+4 more)

### Community 96 - "Caregiver Event Notification Service"
Cohesion: 0.12
Nodes (14): CaregiverEventNotificationService, _client, _generateUuid, notifyDevicePaired, notifyDeviceRevoked, notifyGameCompleted, notifyReminderCompleted, notifyReminderMissed (+6 more)

### Community 97 - "Social Media Account"
Cohesion: 0.12
Nodes (14): copyWith, decodeList, encodeList, fromJson, fromStorage, icon, id, label (+6 more)

### Community 98 - "Caregiver Notification Repository"
Cohesion: 0.13
Nodes (11): _client, _connectivityMonitor, createNotification, getNotifications, getNotificationsStream, getUnreadCount, _localNotifications, _localStreamController (+3 more)

### Community 99 - "Location Sharing Active Screen"
Cohesion: 0.18
Nodes (11): build, _callCaregiver, createState, dispose, initState, LocationSharingActiveScreen, _LocationSharingActiveScreenState, _stopSharing (+3 more)

### Community 100 - "Remember Objects Screen"
Cohesion: 0.13
Nodes (12): RememberObjectsController, _buildMemorizationView, _controller, createState, difficulty, _handleCompletion, _handleExit, initState (+4 more)

### Community 101 - "Community 101 build"
Cohesion: 0.22
Nodes (6): build, build, _buildLegacy, _buildActionGrid, _launcherItems, build

### Community 102 - "Grocery Memory Screen"
Cohesion: 0.13
Nodes (13): GroceryMemoryController, _buildShelfView, _buildShoppingListView, _controller, createState, difficulty, _handleCompletion, _handleExit (+5 more)

### Community 103 - "Game Item"
Cohesion: 0.13
Nodes (13): category, defaultEverydayItems, defaultGroceryItems, emoji, fallbackIcon, GameItem, hashCode, id (+5 more)

### Community 104 - "Social Media Account Form"
Cohesion: 0.13
Nodes (13): build, createState, dispose, _formKey, initialAccount, initState, _isSaving, _obscurePassword (+5 more)

### Community 105 - "Nirvana Story"
Cohesion: 0.14
Nodes (11): NirvanaIntentResult, category, content, id, language, NirvanaStory, NirvanaStoryLibrary, stories (+3 more)

### Community 106 - "Connectivity Monitor"
Cohesion: 0.15
Nodes (10): checkStatus, _connectivity, ConnectivityMonitor, connectivityMonitorProvider, IConnectivityMonitor, _mapToStatus, monitor, NetworkStatus (+2 more)

### Community 107 - "Hive Family Photo"
Cohesion: 0.14
Nodes (11): createdAt, displayOrder, id, isDeleted, localBytes, localPath, name, patientId (+3 more)

### Community 108 - "Hive Reminder"
Cohesion: 0.14
Nodes (13): body, completedAt, createdAt, id, isActive, isCompleted, notificationId, patientId (+5 more)

### Community 109 - "Hive Sync Event"
Cohesion: 0.14
Nodes (13): createdAt, deadLetter, entityId, entityType, eventId, operation, patientId, payload (+5 more)

### Community 110 - "Nirvana Intent Router"
Cohesion: 0.14
Nodes (13): _matchActivity, _matchDailyRoutine, _matchFamily, _matchGamesAndBoredom, _matchHelp, _matchMemories, _matchOrientation, _matchReminders (+5 more)

### Community 111 - "Caregiver Login Screen"
Cohesion: 0.15
Nodes (12): CaregiverLoginScreen, _CaregiverLoginScreenState, createState, dispose, _emailController, _errorMessage, _formKey, _friendlyLoginError (+4 more)

### Community 112 - "Puzzle Piece Tile"
Cohesion: 0.14
Nodes (13): build, col, height, imagePath, isGhost, isPlaced, isSelected, onTap (+5 more)

### Community 113 - "Elder Game Card"
Cohesion: 0.14
Nodes (13): build, _buildFallback, ElderGameCard, emoji, fallbackIcon, iconColor, imagePath, isHighlightedAsHint (+5 more)

### Community 114 - "Game Level Map Path"
Cohesion: 0.14
Nodes (13): build, _buildPositionedNode, GameLevelMapPath, highestUnlockedIndex, highestUnlockedLevel, langCode, levels, onLevelTapped (+5 more)

### Community 115 - "Patient Header"
Cohesion: 0.14
Nodes (13): build, ClayIconButton, dateLabel, DatePill, greeting, icon, label, onFavorite (+5 more)

### Community 117 - "Hive Patient Session"
Cohesion: 0.15
Nodes (12): accessibilitySettings, copyWith, deviceId, displayName, fromMap, isActive, isPaired, lastSyncAt (+4 more)

### Community 118 - "Reminder Log"
Cohesion: 0.15
Nodes (11): action, actionTimestamp, createdAt, fromHive, id, metadata, patientId, reminderId (+3 more)

### Community 119 - "Game Enums"
Cohesion: 0.15
Nodes (9): GameDifficulty, GameType, hard, id, jigsawPieceCount, jigsawPuzzle, localizedLabel, localizedSubtitle (+1 more)

### Community 121 - "Supabase Reminder Pull Repository"
Cohesion: 0.17
Nodes (9): _client, _deviceId, fetchReminders, _fromRow, _notificationService, _scheduledAtFromRow, SupabaseReminderPullRepository, syncToLocal (+1 more)

### Community 122 - "Caregiver Bottom Navigation"
Cohesion: 0.17
Nodes (11): build, CaregiverBottomNavigation, icon, _items, label, _NavigationItem, onSelected, onTap (+3 more)

### Community 123 - "Location Help Repository"
Cohesion: 0.17
Nodes (10): checkActiveSession, fetchCaregiverActiveSession, getLatestLocation, ILocationHelpRepository, startLocationSession, stopLocationSession, updateLocation, watchLocationUpdates (+2 more)

### Community 124 - "Community 124 build"
Cohesion: 0.27
Nodes (12): build, PatientDashboard, build, _maybeShowDueReminder, _UpcomingReminderCard, build, _ClayPatientReminderCard3D, localPatientSessionProvider (+4 more)

### Community 125 - "Community 125 AppLocalizations"
Cohesion: 0.17
Nodes (11): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsAs, AppLocalizationsBn, AppLocalizationsEn, AppLocalizationsHi, AppLocalizationsKha, AppLocalizationsLus (+3 more)

### Community 126 - "Location Service"
Cohesion: 0.18
Nodes (9): checkPermission, getCurrentPosition, isServiceEnabled, LocationPermissionOutcome, LocationService, openAppSettings, openLocationSettings, positionStream (+1 more)

### Community 127 - "Puzzle Board"
Cohesion: 0.20
Nodes (7): JigsawPuzzleState, boardHeight, boardWidth, build, _buildEmptySlotPlaceholder, PuzzleBoard, state

### Community 128 - "Hive Reminder Log"
Cohesion: 0.20
Nodes (8): action, actionTimestamp, createdAt, id, metadata, patientId, reminderId, toMap

### Community 130 - "Community 130 build"
Cohesion: 0.24
Nodes (10): build, _generateCode, PatientDevicePanel, _PatientDevicePanelState, _revokeDevice, _sendPasscodeSms, pairingCodeProvider, pairingRepositoryProvider (+2 more)

### Community 131 - "Game Header"
Cohesion: 0.20
Nodes (8): build, difficulty, GameHeader, isHintAvailable, onExit, onHint, _showExitConfirmDialog, title

### Community 132 - "Help Flow"
Cohesion: 0.20
Nodes (6): confirmAndStart, confirmed, notifier, of, state, true

### Community 135 - "Caregiver Notification Repository 2"
Cohesion: 0.22
Nodes (8): createNotification, getNotifications, getNotificationsStream, getUnreadCount, ICaregiverNotificationRepository, markAllAsRead, markAsRead, SupabaseCaregiverNotificationRepository

### Community 136 - "Pairing Repository"
Cohesion: 0.22
Nodes (7): generatePairingCode, getLinkedDevice, getPatientContact, IPairingRepository, revokeDevice, sendPasscodeSms, SupabasePairingRepository

### Community 137 - "Clay 3D Dialog"
Cohesion: 0.25
Nodes (5): barrierDismissible, clayDialogInsets, clayDialogShape, symmetric, w

### Community 140 - "Community 140 _handleLogin"
Cohesion: 0.40
Nodes (4): _handleLogin, build, _showSuccessDialog, patientOnboardingProvider

### Community 141 - "Community 141 _handleRegister"
Cohesion: 0.40
Nodes (4): _handleRegister, build, PatientSelectorWidget, assignedPatientsProvider

## Knowledge Gaps
- **4236 isolated node(s):** `scale`, `nirvanaFullySupportedLocales`, `toggle`, `setReducedMotion`, `setHighContrast` (+4231 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 4493 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GameDifficulty` connect `Game Enums` to `Jigsaw Puzzle Screen`, `Remember Objects Controller`, `Game Header`, `Remember Objects Screen`, `Grocery Memory Screen`, `Who Is This Screen`, `Jigsaw Puzzle Controller`, `Who Is This Game`, `Game Level Model`, `Game Session`, `Grocery Memory Controller`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `scale`, `nirvanaFullySupportedLocales`, `toggle` to the rest of the system?**
  _4236 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `L10n Locale Classes` be split into smaller, more focused modules?**
  _Cohesion score 0.007874015748031496 - nodes in this community are weakly interconnected._
- **Why does `_` connect `Backend SMS Service` to `Games Hub Screen`, `Clay 3D Header`, `Repositories/Location Help`, `Social Media Accounts Section`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **Should `L10n Base Strings (Hindi)` be split into smaller, more focused modules?**
  _Cohesion score 0.008438818565400843 - nodes in this community are weakly interconnected._
- **Should `L10n Assamese Strings` be split into smaller, more focused modules?**
  _Cohesion score 0.00847457627118644 - nodes in this community are weakly interconnected._
- **Should `L10n Bengali Strings` be split into smaller, more focused modules?**
  _Cohesion score 0.00847457627118644 - nodes in this community are weakly interconnected._