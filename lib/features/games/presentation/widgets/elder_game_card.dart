// ==============================================================================
// NIRVANA - ElderGameCard Widget
// Description: Tactile, large-touch visual card for real image assets, groceries,
// and family faces with elder-accessible typography and high-contrast cues.
// ==============================================================================

import 'package:flutter/material.dart';

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
    // Accessible color palette
    Color cardBg = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    double borderWidth = 2.0;

    if (isSelected) {
      cardBg = const Color(0xFFF0FDF4); // Soft mint/green
      borderColor = const Color(0xFF16A34A); // Solid green border
      borderWidth = 3.5;
    } else if (isHighlightedAsHint) {
      cardBg = const Color(0xFFFFFBEB); // Soft warm amber
      borderColor = const Color(0xFFD97706); // Amber border
      borderWidth = 3.5;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '$title ${isSelected ? 'Selected' : ''} ${isHighlightedAsHint ? 'Hint' : ''}',
      child: Material(
        color: cardBg,
        elevation: isSelected ? 4 : 2,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 3.0,
              vertical: 3.0,
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
                        color: (iconColor ?? const Color(0xFF0F766E)).withAlpha(
                          18,
                        ),
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4.0),
                      child: imagePath != null && imagePath!.isNotEmpty
                          ? Image.asset(
                              imagePath!,
                              width: 88.0,
                              height: 88.0,
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
                          padding: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 20.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (isHighlightedAsHint && !isSelected)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            size: 20.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10.0),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
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
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
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
      color: iconColor ?? const Color(0xFF0F766E),
    );
  }
}
