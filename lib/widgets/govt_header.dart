import 'package:flutter/material.dart';

class GovtHeaderWidget extends StatelessWidget {
  final double scaleFactor;

  const GovtHeaderWidget({
    super.key,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final emblemHeight = (64.0 * scaleFactor).clamp(52.0, 76.0);
    final titleFontSize = (15.0 * scaleFactor).clamp(13.0, 18.0);
    final deptFontSize = (13.5 * scaleFactor).clamp(11.5, 16.0);
    final mainHeadingSize = (28.0 * scaleFactor).clamp(24.0, 34.0);
    final subtitleSize = (14.0 * scaleFactor).clamp(12.5, 16.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Emblem Bar: National Emblem [Left] - Titles [Center] - State Seal [Right]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // National Emblem (Left)
              Image.asset(
                'assets/images/national_emblem.png',
                height: emblemHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.account_balance,
                  size: emblemHeight,
                  color: const Color(0xFF263238),
                ),
              ),

              // Department Titles (Center)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GOVERNMENT OF MAHARASHTRA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Animal Husbandry Department',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: deptFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // State Seal (Right)
              Image.asset(
                'assets/images/state_seal.png',
                height: emblemHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.verified,
                  size: emblemHeight,
                  color: const Color(0xFFFFB300),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: (16 * scaleFactor).clamp(12.0, 22.0)),

        // Main Slogan (Large Green Heading)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'FOR OUR FARMERS,\nFOR OUR LIVESTOCK',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: mainHeadingSize,
              fontWeight: FontWeight.w900,
              height: 1.18,
              letterSpacing: 0.3,
              color: const Color(0xFF1B5E20),
            ),
          ),
        ),

        SizedBox(height: (8 * scaleFactor).clamp(6.0, 12.0)),

        // Subtitle slogan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Healthy Livestock, Prosperous Farmer, Prosperous Nation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF37474F),
              height: 1.35,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}
