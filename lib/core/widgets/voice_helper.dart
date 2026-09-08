// ==============================================================================
// NIRVANA - Voice Helper Widgets
// Description: Reusable voice interaction components for games,
// reminders, and settings. Provides visual feedback for
// listening states and simple voice commands.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../app/theme/elder_theme.dart';
import '../../app/providers/accessibility_providers.dart';
import '../network/audio_service.dart';

/// A button that triggers voice input with visual feedback
class VoiceInputButton extends ConsumerStatefulWidget {
  final String? label;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final void Function(String? recognizedText)? onVoiceResult;
  final void Function()? onListeningStarted;
  final void Function()? onListeningStopped;

  const VoiceInputButton({
    super.key,
    this.label,
    this.size = 64.0,
    this.activeColor,
    this.inactiveColor,
    this.onVoiceResult,
    this.onListeningStarted,
    this.onListeningStopped,
  });

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isListening = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeColor = widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? Theme.of(context).colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size * _pulseAnimation.value,
                height: widget.size * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? activeColor : inactiveColor,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: _isListening ? 0.4 : 0.2),
                      blurRadius: _isListening ? 20 : 10,
                      spreadRadius: _isListening ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: widget.size * 0.35,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          widget.label ?? l10n?.todayGreetingMorning ?? 'Tap to speak',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            color: _isListening
                ? Theme.of(context).colorScheme.primary
                : ElderColors.textSecondary,
          ),
        ),
        if (_lastResult != null && _lastResult!.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              _lastResult!,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _lastResult = null;
    });
    widget.onListeningStarted?.call();

    final audioService = ref.read(audioServiceProvider);
    final locale = ref.read(localeProvider);
    final result = await audioService.listenForSpeech(
      languageCode: locale.languageCode,
    );

    if (mounted) {
      setState(() {
        _isListening = false;
        _lastResult = result;
      });
      widget.onVoiceResult?.call(result);
      widget.onListeningStopped?.call();
    }
  }

  Future<void> _stopListening() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.stopListening();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      widget.onListeningStopped?.call();
    }
  }
}

/// A text-to-speech button that reads aloud content
class SpeakButton extends ConsumerWidget {
  final String text;
  final String? languageCode;
  final IconData icon;
  final double size;

  const SpeakButton({
    super.key,
    required this.text,
    this.languageCode,
    this.icon = Icons.volume_up_rounded,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.read(audioServiceProvider);
    final isSpeaking = ref.watch(isSpeakingProvider);
    final activeLocale = ref.watch(localeProvider);

    return IconButton(
      iconSize: size,
      icon: Icon(
        isSpeaking ? Icons.volume_off_rounded : icon,
        color: isSpeaking
            ? Theme.of(context).colorScheme.primary
            : ElderColors.textSecondary,
      ),
      onPressed: isSpeaking
          ? () => audioService.stopSpeaking()
          : () => audioService.speak(
                text,
                languageCode: languageCode ?? activeLocale.languageCode,
              ),
      tooltip: 'Speak',
    );
  }
}

/// A widget that displays a listening indicator
class ListeningIndicator extends StatelessWidget {
  final String? listeningText;
  final bool isListening;

  const ListeningIndicator({
    super.key,
    this.listeningText,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isListening
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isListening
              ? Theme.of(context).colorScheme.primary
              : ElderColors.border,
          width: 2.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isListening ? 12.0 : 0,
            height: 12.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? Theme.of(context).colorScheme.primary
                  : ElderColors.textMuted,
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            listeningText ?? (isListening ? 'Listening...' : 'Tap to speak'),
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: isListening ? FontWeight.w800 : FontWeight.w500,
              color: isListening
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : ElderColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}