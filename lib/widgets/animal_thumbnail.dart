import 'package:flutter/material.dart';

/// Reusable widget that renders a transparent animal cutout overlaid on top
/// of the lush green meadow pasture background (ChatGPT Image).
class AnimalThumbnail extends StatelessWidget {
  final String assetImage;
  final double size;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;

  const AnimalThumbnail({
    super.key,
    required this.assetImage,
    this.size = 76,
    this.borderRadius = 16,
    this.contentPadding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Meadow Pasture Background Image
            Image.asset(
              'assets/images/animal_card_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFC8E6C9),
                child: const Icon(Icons.pets, color: Color(0xFF2E7D32), size: 32),
              ),
            ),

            // 2. Subtle soft tint for depth and high contrast
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),

            // 3. Animal Cutout Foreground
            Padding(
              padding: contentPadding,
              child: Image.asset(
                assetImage,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    Icons.pets_rounded,
                    color: const Color(0xFF1B5E20),
                    size: size * 0.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
