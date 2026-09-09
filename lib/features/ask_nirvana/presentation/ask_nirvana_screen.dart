// ==============================================================================
// NIRVANA - Ask NIRVANA Screen
// Description: Dementia-friendly voice assistant interface tailored for elderly
// users. Features a primary large microphone interaction, clear state feedback,
// tactile high-contrast bubbles, secondary text input, and full accessibility.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/accessibility_providers.dart';
import '../../../app/theme/elder_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../providers/ask_nirvana_provider.dart';

class AskNirvanaScreen extends ConsumerStatefulWidget {
  const AskNirvanaScreen({super.key});

  @override
  ConsumerState<AskNirvanaScreen> createState() => _AskNirvanaScreenState();
}

class _AskNirvanaScreenState extends ConsumerState<AskNirvanaScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();

  late AnimationController _micPulseController;
  late Animation<double> _micPulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _micPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Prevent lingering speech recognition or TTS when app is backgrounded
      ref.read(askNirvanaProvider.notifier).stopListening();
      ref.read(askNirvanaProvider.notifier).stopSpeaking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _micPulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleMicTap(AssistantVoiceState voiceState) {
    final notifier = ref.read(askNirvanaProvider.notifier);
    switch (voiceState) {
      case AssistantVoiceState.listening:
        notifier.stopListening();
        break;
      case AssistantVoiceState.speaking:
        notifier.stopSpeaking();
        break;
      case AssistantVoiceState.thinking:
        // Do not interrupt thinking
        break;
      case AssistantVoiceState.idle:
      case AssistantVoiceState.error:
        notifier.startListening();
        break;
    }
  }

  void _handleSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _textFocusNode.unfocus();
    ref.read(askNirvanaProvider.notifier).sendTextMessage(text);
    _scrollToBottom();
  }

  Future<void> _confirmClearConversation(AppLocalizations? l10n) async {
    final isHighContrast = ref.read(highContrastProvider);

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ElderColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: BorderSide(
              color: isHighContrast
                  ? ElderColors.borderHighContrast
                  : ElderColors.border,
              width: 2.5,
            ),
          ),
          title: Text(
            l10n?.askNirvanaClearTitle ?? 'Clear Conversation?',
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: ElderColors.textPrimary,
            ),
          ),
          content: Text(
            l10n?.askNirvanaClearMessage ??
                'This will start a fresh, new conversation. Are you sure?',
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: ElderColors.textSecondary,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100.0, 52.0),
                side: const BorderSide(color: ElderColors.border, width: 2.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n?.backButton ?? 'Cancel',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(110.0, 52.0),
                backgroundColor: ElderColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                l10n?.askNirvanaClearButton ?? 'Clear',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      ref.read(askNirvanaProvider.notifier).clearConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(askNirvanaProvider);
    final isHighContrast = ref.watch(highContrastProvider);
    final reducedMotion = ref.watch(reducedMotionProvider);
    final textScale = ref.watch(textScaleProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Sync pulse animation with listening state
    if (state.voiceState == AssistantVoiceState.listening && !reducedMotion) {
      if (!_micPulseController.isAnimating) {
        _micPulseController.repeat(reverse: true);
      }
    } else {
      if (_micPulseController.isAnimating) {
        _micPulseController.stop();
        _micPulseController.reset();
      }
    }

    // Auto scroll when messages change
    ref.listen(askNirvanaProvider.select((s) => s.messages.length), (_, __) {
      _scrollToBottom();
    });

    final primaryColor = isHighContrast
        ? ElderColors.highContrastPrimary
        : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isHighContrast
          ? Colors.white
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: ElderColors.surface,
        elevation: 0,
        toolbarHeight: 72.0,
        centerTitle: false,
        leading: Semantics(
          label: 'Back to previous screen',
          child: IconButton(
            iconSize: 36.0,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: ElderColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(
          l10n?.askNirvanaTitle ?? 'Ask NIRVANA',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: primaryColor,
            fontSize: 26.0 * textScale.scale,
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Clear conversation and start over',
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: ElderColors.textSecondary,
                minimumSize: const Size(64.0, 48.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
              ),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 26.0,
                color: ElderColors.textSecondary,
              ),
              label: Text(
                l10n?.askNirvanaClearButton ?? 'Clear',
                style: TextStyle(
                  fontSize: 16.0 * textScale.scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _confirmClearConversation(l10n),
            ),
          ),
          const SizedBox(width: 8.0),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isHighContrast ? ElderColors.borderHighContrast : ElderColors.borderLight,
            height: isHighContrast ? 2.0 : 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Friendly Assistant Status Header Area
            _buildAssistantHeaderArea(
              context: context,
              state: state,
              isHighContrast: isHighContrast,
              textScale: textScale,
              l10n: l10n,
            ),

            // 2. Main Conversation Area
            Expanded(
              child: _buildConversationList(
                context: context,
                messages: state.messages,
                liveTranscript: state.liveTranscript,
                isHighContrast: isHighContrast,
                textScale: textScale,
              ),
            ),

            // 3. Primary Microphone Interaction Area
            _buildPrimaryMicrophoneArea(
              context: context,
              state: state,
              isHighContrast: isHighContrast,
              reducedMotion: reducedMotion,
              textScale: textScale,
              l10n: l10n,
            ),

            // 4. Secondary Text Input Area
            _buildSecondaryTextInputArea(
              context: context,
              isHighContrast: isHighContrast,
              textScale: textScale,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Friendly Assistant Status Area
  Widget _buildAssistantHeaderArea({
    required BuildContext context,
    required AskNirvanaState state,
    required bool isHighContrast,
    required TextScaleOption textScale,
    required AppLocalizations? l10n,
  }) {
    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    IconData badgeIcon;
    String statusTitle;

    switch (state.voiceState) {
      case AssistantVoiceState.listening:
        badgeBg = ElderColors.primaryContainer;
        badgeBorder = ElderColors.primary;
        badgeText = ElderColors.onPrimaryContainer;
        badgeIcon = Icons.mic_rounded;
        statusTitle = l10n?.askNirvanaListening ?? "I'm listening...";
        break;
      case AssistantVoiceState.thinking:
        badgeBg = ElderColors.supportiveBg;
        badgeBorder = ElderColors.supportiveBorder;
        badgeText = ElderColors.supportiveText;
        badgeIcon = Icons.hourglass_top_rounded;
        statusTitle = l10n?.askNirvanaThinking ?? "Let me think...";
        break;
      case AssistantVoiceState.speaking:
        badgeBg = ElderColors.primaryContainer;
        badgeBorder = ElderColors.primary;
        badgeText = ElderColors.onPrimaryContainer;
        badgeIcon = Icons.volume_up_rounded;
        statusTitle = l10n?.askNirvanaSpeaking ?? "Speaking...";
        break;
      case AssistantVoiceState.error:
        badgeBg = ElderColors.gentleErrorBg;
        badgeBorder = ElderColors.gentleErrorBorder;
        badgeText = ElderColors.gentleErrorText;
        badgeIcon = Icons.info_outline_rounded;
        statusTitle =
            state.errorMessage ??
            l10n?.askNirvanaErrorPrompt ??
            "I couldn't understand that. Please try again.";
        break;
      case AssistantVoiceState.idle:
        badgeBg = ElderColors.surfaceElevated;
        badgeBorder = ElderColors.border;
        badgeText = ElderColors.textSecondary;
        badgeIcon = Icons.spa_rounded;
        statusTitle = l10n?.askNirvanaCompanionLabel ?? "NIRVANA Companion";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ElderColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isHighContrast
                ? ElderColors.borderHighContrast
                : ElderColors.border,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Friendly Assistant Avatar
          Container(
            width: 52.0,
            height: 52.0,
            decoration: BoxDecoration(
              color: ElderColors.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: isHighContrast
                    ? ElderColors.borderHighContrast
                    : ElderColors.primary,
                width: 2.0,
              ),
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: ElderColors.primary,
              size: 30.0,
            ),
          ),
          const SizedBox(width: 14.0),
          // Status Pill / Friendly Text
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isHighContrast
                      ? ElderColors.borderHighContrast
                      : badgeBorder,
                  width: 2.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(badgeIcon, color: badgeText, size: 22.0),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 16.0 * textScale.scale,
                        fontWeight: FontWeight.w800,
                        color: badgeText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Conversation Area
  Widget _buildConversationList({
    required BuildContext context,
    required List<ChatMessage> messages,
    required String? liveTranscript,
    required bool isHighContrast,
    required TextScaleOption textScale,
  }) {
    final hasLive = liveTranscript != null && liveTranscript.trim().isNotEmpty;
    final totalCount = messages.length + (hasLive ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (hasLive && index == messages.length) {
          return _buildLiveTranscriptBubble(
            liveTranscript: liveTranscript,
            isHighContrast: isHighContrast,
            textScale: textScale,
          );
        }
        final message = messages[index];
        return _buildChatBubble(
          message: message,
          isHighContrast: isHighContrast,
          textScale: textScale,
        );
      },
    );
  }

  /// Live partial transcription bubble shown while the user speaks
  Widget _buildLiveTranscriptBubble({
    required String liveTranscript,
    required bool isHighContrast,
    required TextScaleOption textScale,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: isHighContrast
                    ? ElderColors.surfaceElevated
                    : ElderColors.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(NirvanaRadii.card),
                border: isHighContrast
                    ? Border.all(color: ElderColors.borderHighContrast, width: 2.0)
                    : null,
                boxShadow: isHighContrast ? null : NirvanaShadows.float(tint: ElderColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18.0,
                    height: 18.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ElderColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Flexible(
                    child: Text(
                      liveTranscript,
                      style: TextStyle(
                        fontSize: 18.0 * textScale.scale,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: ElderColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4.0, left: 8.0),
            width: 38.0,
            height: 38.0,
            decoration: const BoxDecoration(
              color: ElderColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Colors.white,
              size: 22.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({
    required ChatMessage message,
    required bool isHighContrast,
    required TextScaleOption textScale,
  }) {
    final isUser = message.isUser;

    Color bubbleColor;
    Color textColor;
    BorderSide borderSide;

    if (isUser) {
      bubbleColor = isHighContrast
          ? ElderColors.surfaceElevated
          : ElderColors.primaryContainer;
      textColor = ElderColors.textPrimary;
      borderSide = BorderSide(
        color: isHighContrast
            ? ElderColors.borderHighContrast
            : ElderColors.primary,
        width: 2.0,
      );
    } else {
      bubbleColor = ElderColors.surface;
      textColor = ElderColors.textPrimary;
      borderSide = BorderSide(
        color: isHighContrast
            ? ElderColors.borderHighContrast
            : ElderColors.border,
        width: 2.0,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4.0, right: 8.0),
              width: 38.0,
              height: 38.0,
              decoration: const BoxDecoration(
                color: ElderColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(NirvanaRadii.card),
                border: isHighContrast
                    ? Border.fromBorderSide(borderSide)
                    : Border.all(color: ElderColors.borderLight, width: 1.0),
                boxShadow: isHighContrast
                    ? null
                    : (isUser
                        ? NirvanaShadows.float(tint: ElderColors.primary)
                        : NirvanaShadows.card()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 18.0 * textScale.scale,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 12.0),
                    // Large, accessible Speak Aloud button
                    Semantics(
                      button: true,
                      label: 'Read response aloud',
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(askNirvanaProvider.notifier)
                              .speakMessage(message.text);
                        },
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: ElderColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: isHighContrast
                                  ? ElderColors.borderHighContrast
                                  : ElderColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.volume_up_rounded,
                                size: 22.0,
                                color: ElderColors.primary,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                AppLocalizations.of(
                                      context,
                                    )?.askNirvanaReadAloud ??
                                    'Read Aloud',
                                style: TextStyle(
                                  fontSize: 15.0 * textScale.scale,
                                  fontWeight: FontWeight.w700,
                                  color: ElderColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4.0, left: 8.0),
              width: 38.0,
              height: 38.0,
              decoration: const BoxDecoration(
                color: ElderColors.textSecondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Primary Microphone Button Area
  Widget _buildPrimaryMicrophoneArea({
    required BuildContext context,
    required AskNirvanaState state,
    required bool isHighContrast,
    required bool reducedMotion,
    required TextScaleOption textScale,
    required AppLocalizations? l10n,
  }) {
    Color micBg;
    Color micFg;
    Color micBorder;
    IconData micIcon;
    String statePromptText;
    String semanticLabel;

    switch (state.voiceState) {
      case AssistantVoiceState.listening:
        micBg = ElderColors.primary;
        micFg = Colors.white;
        micBorder = isHighContrast
            ? ElderColors.borderHighContrast
            : ElderColors.onPrimaryContainer;
        micIcon = Icons.stop_rounded;
        statePromptText =
            l10n?.askNirvanaListeningPrompt ??
            "I'm listening... (Tap to finish)";
        semanticLabel = "Listening to your voice. Tap to finish speaking.";
        break;

      case AssistantVoiceState.thinking:
        micBg = ElderColors.supportiveBg;
        micFg = ElderColors.supportiveIcon;
        micBorder = isHighContrast
            ? ElderColors.borderHighContrast
            : ElderColors.supportiveBorder;
        micIcon = Icons.hourglass_bottom_rounded;
        statePromptText = l10n?.askNirvanaThinkingPrompt ?? "Let me think...";
        semanticLabel = "NIRVANA is thinking.";
        break;

      case AssistantVoiceState.speaking:
        micBg = ElderColors.primaryContainer;
        micFg = ElderColors.primary;
        micBorder = isHighContrast
            ? ElderColors.borderHighContrast
            : ElderColors.primary;
        micIcon = Icons.stop_rounded;
        statePromptText =
            l10n?.askNirvanaSpeakingPrompt ?? "Speaking... (Tap to stop)";
        semanticLabel = "Speaking. Tap to stop speaking.";
        break;

      case AssistantVoiceState.error:
        micBg = ElderColors.gentleErrorBg;
        micFg = ElderColors.gentleErrorPrimary;
        micBorder = isHighContrast
            ? ElderColors.borderHighContrast
            : ElderColors.gentleErrorBorder;
        micIcon = Icons.replay_rounded;
        statePromptText =
            state.errorMessage ??
            l10n?.askNirvanaErrorPrompt ??
            "I couldn't understand that. Please try again.";
        semanticLabel = "Error. Tap to try speaking again.";
        break;

      case AssistantVoiceState.idle:
        micBg = isHighContrast
            ? ElderColors.highContrastPrimary
            : ElderColors.primary;
        micFg = Colors.white;
        micBorder = isHighContrast
            ? ElderColors.borderHighContrast
            : ElderColors.primary;
        micIcon = Icons.mic_rounded;
        statePromptText = l10n?.askNirvanaTapToSpeak ?? "Tap to speak";
        semanticLabel = "Tap microphone to speak to NIRVANA.";
        break;
    }

    Widget micButton = Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () => _handleMicTap(state.voiceState),
        child: Container(
          width: 92.0,
          height: 92.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: micBg,
            border: Border.all(
              color: micBorder,
              width: isHighContrast ? 4.0 : 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: micBg.withValues(alpha: 0.25),
                blurRadius: 16.0,
                spreadRadius: 2.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: Icon(micIcon, color: micFg, size: 48.0)),
        ),
      ),
    );

    // Apply gentle pulse only in listening state when reducedMotion is disabled
    if (state.voiceState == AssistantVoiceState.listening && !reducedMotion) {
      micButton = ScaleTransition(scale: _micPulseAnimation, child: micButton);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: ElderColors.surface,
        border: Border(
          top: BorderSide(
            color: isHighContrast
                ? ElderColors.borderHighContrast
                : ElderColors.border,
            width: 2.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Action: Large Microphone
          micButton,
          const SizedBox(height: 10.0),

          // Primary State Message under mic
          Text(
            statePromptText,
            style: TextStyle(
              fontSize: 20.0 * textScale.scale,
              fontWeight: FontWeight.w800,
              color: state.voiceState == AssistantVoiceState.error
                  ? ElderColors.gentleErrorText
                  : ElderColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 4. Secondary Text Input Area
  Widget _buildSecondaryTextInputArea({
    required BuildContext context,
    required bool isHighContrast,
    required TextScaleOption textScale,
    required AppLocalizations? l10n,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
      color: ElderColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text input field
          Expanded(
            child: Semantics(
              label: 'Optional: type your question here',
              child: Container(
                constraints: const BoxConstraints(minHeight: 56.0),
                decoration: BoxDecoration(
                  color: ElderColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(NirvanaRadii.button),
                  border: Border.all(
                    color: isHighContrast ? ElderColors.borderHighContrast : ElderColors.borderLight,
                    width: isHighContrast ? 2.5 : 1.0,
                  ),
                  boxShadow: NirvanaShadows.input,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _textController,
                  focusNode: _textFocusNode,
                  style: TextStyle(
                    fontSize: 18.0 * textScale.scale,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n?.askNirvanaTypeHere ?? 'Or type here...',
                    hintStyle: TextStyle(
                      fontSize: 18.0 * textScale.scale,
                      fontWeight: FontWeight.w500,
                      color: ElderColors.textMuted,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendText(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10.0),

          // Send button (Min touch size 56x56)
          Semantics(
            button: true,
            label: 'Send typed question',
            child: Material(
              color: isHighContrast
                  ? ElderColors.highContrastPrimary
                  : ElderColors.primary,
              borderRadius: BorderRadius.circular(NirvanaRadii.button),
              child: InkWell(
                onTap: _handleSendText,
                borderRadius: BorderRadius.circular(NirvanaRadii.button),
                child: Container(
                  width: 56.0,
                  height: 56.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(NirvanaRadii.button),
                    boxShadow: isHighContrast ? null : NirvanaShadows.float(tint: ElderColors.primary),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 28.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
