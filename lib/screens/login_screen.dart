import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/govt_header.dart';
import '../widgets/action_pill_button.dart';
import 'login_flow_screen.dart';
import 'register_flow_screen.dart';

class FarmerLoginScreen extends StatefulWidget {
  const FarmerLoginScreen({super.key});

  @override
  State<FarmerLoginScreen> createState() => _FarmerLoginScreenState();
}

class _FarmerLoginScreenState extends State<FarmerLoginScreen>
    with TickerProviderStateMixin {
  // Staggered entry animation controller
  late AnimationController _entryController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;
  late Animation<Offset> _buttonsSlideAnimation;

  // Subtle floating idle animation for the farmer and cow
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Staggered Entry Animation (850ms)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Header enters first (0.0 -> 0.6)
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Hero farmer & cow enters second (0.25 -> 0.8)
    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Action buttons enter last (0.55 -> 1.0)
    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Continuous subtle floating breath for hero image
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _floatAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _entryController.forward().then((_) {
      if (mounted) {
        _floatController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _openLoginSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginFlowScreen()),
    );
  }

  void _openRegisterSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterFlowScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFAF5), // Warm Ivory White
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          final totalWidth = constraints.maxWidth;

          // Responsive scale factor based on standard mobile height (800)
          final scaleFactor = (totalHeight / 800.0).clamp(0.78, 1.25);
          final isTabletOrWide = totalWidth > 600;

          // Dimensioning calculations
          final footerHeight = (totalHeight * 0.14).clamp(90.0, 140.0);
          final landscapeHeight = totalHeight * 0.48;
          final heroHeight = (totalHeight * 0.43).clamp(250.0, 430.0);

          // Content maximum width for tablets/desktop
          final contentWidth = isTabletOrWide ? 500.0 : totalWidth;

          return Center(
            child: SizedBox(
              width: contentWidth,
              height: totalHeight,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  // -------------------------------------------------------------
                  // LAYER 1: Background Landscape (Fields & Hills)
                  // -------------------------------------------------------------
                  Positioned(
                    top: totalHeight * 0.24,
                    left: 0,
                    right: 0,
                    height: landscapeHeight,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.15, 0.85, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        'assets/images/landscape_bg.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),

                  // -------------------------------------------------------------
                  // LAYER 2: Bottom Folk Art Livestock Silhouette Strip
                  // -------------------------------------------------------------
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    height: footerHeight,
                    child: Image.asset(
                      'assets/images/livestock_footer.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),

                  // -------------------------------------------------------------
                  // LAYER 3: Hero Foreground: Farmer & Cow (With Smooth Animation)
                  // -------------------------------------------------------------
                  Positioned(
                    bottom: footerHeight + (totalHeight * 0.17),
                    left: 0,
                    right: 160,
                    height: heroHeight,
                    child: SlideTransition(
                      position: _heroSlideAnimation,
                      child: FadeTransition(
                        opacity: _heroFadeAnimation,
                        child: AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: child,
                          ),
                          child: Image.asset(
                            'assets/images/farmer_cow.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.pets, size: 80, color: Color(0xFF1B5E20)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // -------------------------------------------------------------
                  // LAYER 4: Top Safe Area: Government Emblems & Slogans
                  // -------------------------------------------------------------
                  Positioned(
                    top: topPadding + (10 * scaleFactor),
                    left: 0,
                    right: 0,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: GovtHeaderWidget(scaleFactor: scaleFactor),
                      ),
                    ),
                  ),

                  // -------------------------------------------------------------
                  // LAYER 5: Action Buttons (Login & Register)
                  // -------------------------------------------------------------
                  Positioned(
                    bottom: footerHeight + 22 + (bottomPadding > 0 ? bottomPadding / 2 : 0),
                    left: 20,
                    right: 20,
                    child: SlideTransition(
                      position: _buttonsSlideAnimation,
                      child: FadeTransition(
                        opacity: _buttonsFadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Primary Orange Pill Button: Login
                            ActionPillButton(
                              label: 'Login',
                              variant: PillButtonVariant.primaryOrange,
                              icon: Icons.arrow_forward_rounded,
                              onPressed: _openLoginSheet,
                            ),

                            SizedBox(height: (12 * scaleFactor).clamp(8.0, 16.0)),

                            // 2. Secondary Outlined Green Pill Button: Register
                            ActionPillButton(
                              label: 'Register as New Farmer',
                              variant: PillButtonVariant.outlinedGreen,
                              icon: Icons.person_add_alt_1_rounded,
                              onPressed: _openRegisterSheet,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Color(0xFF104A3A)),
            SizedBox(width: 8),
            Text(
              'Exit App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the app?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF104A3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
