// ==============================================================================
// NIRVANA - ElderGameCard Widget
// Description: Tactile, large-touch visual clay card for real image assets, groceries,
// and family faces with elder-accessible typography and claymorphic cues.
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../app/theme/elder_theme.dart';

class ElderGameCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imagePath;
  final String? emoji;
  final IconData? fallbackIcon;
  final Color? iconColor;
  final bool isSelected;
  final bool isHighlightedAsHint;
  final VoidCallback? onTap;
  final double minHeight;

  const ElderGameCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imagePath,
    this.emoji,
    this.fallbackIcon,
    this.iconColor,
    this.isSelected = false,
    this.isHighlightedAsHint = false,
    this.onTap,
    this.minHeight = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBg = Colors.white;
    Color borderColor = ElderColors.borderLight;
    double borderWidth = 1.5;
    List<BoxShadow>? shadow = ElderColors.clayShadow();

    if (isSelected) {
      cardBg = ElderColors.pastelSage;
      borderColor = ElderColors.forestDeep;
      borderWidth = 2.5;
      shadow = ElderColors.clayShadow(color: ElderColors.pastelSage);
    } else if (isHighlightedAsHint) {
      cardBg = ElderColors.pastelButtercup;
      borderColor = ElderColors.amberDeep;
      borderWidth = 2.5;
      shadow = ElderColors.clayShadow(color: ElderColors.pastelButtercup);
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '$title ${isSelected ? 'Selected' : ''} ${isHighlightedAsHint ? 'Hint' : ''}',
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
            splashColor: (iconColor ?? ElderColors.primary).withValues(alpha: 0.15),
            highlightColor: (iconColor ?? ElderColors.primary).withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 12.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top visual image / icon / selection badge
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96.0,
                        height: 96.0,
                        decoration: BoxDecoration(
                          color: (iconColor ?? ElderColors.primary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: Colors.white, width: 2.0),
                          boxShadow: ElderColors.clayShadow(),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(6.0),
                        child: imagePath != null && imagePath!.isNotEmpty
                            ? Image.asset(
                                imagePath!,
                                width: 84.0,
                                height: 84.0,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildFallback();
                                },
                              )
                            : _buildFallback(),
                      ),
                      if (isSelected)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              color: ElderColors.forestDeep,
                              shape: BoxShape.circle,
                              boxShadow: ElderColors.buttonShadow(color: ElderColors.forestDeep),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 18.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (isHighlightedAsHint && !isSelected)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              color: ElderColors.amberDeep,
                              shape: BoxShape.circle,
                              boxShadow: ElderColors.buttonShadow(color: ElderColors.amberDeep),
                            ),
                            child: const Icon(
                              Icons.lightbulb_rounded,
                              size: 18.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900,
                      color: ElderColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: ElderColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    if (emoji != null && emoji!.isNotEmpty) {
      return Text(emoji!, style: const TextStyle(fontSize: 36.0));
    }
    return Icon(
      fallbackIcon ?? Icons.category_rounded,
      size: 36.0,
      color: iconColor ?? ElderColors.primary,
    );
  }
}

