import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_flow_screen.dart';

class LoginFlowScreen extends StatefulWidget {
  const LoginFlowScreen({super.key});

  @override
  State<LoginFlowScreen> createState() => _LoginFlowScreenState();
}

class _LoginFlowScreenState extends State<LoginFlowScreen>
    with SingleTickerProviderStateMixin {
  // ── Brand Colors ───────────────────────────────────────────
  static const _greenPrimary = Color(0xFF1B5E20);
  static const _greenDark = Color(0xFF0D3A13);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _orangePrimary = Color(0xFFFF6D00);
  static const _orangeDark = Color(0xFFE65100);
  static const _bg = Color(0xFFFCFAF5);

  // ── Controllers & State ────────────────────────────────────
  final _api = FarmerApiService();
  final _phoneCtrl = TextEditingController(text: '9876543210');
  final _otpCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  int _resendSeconds = 0;
  Timer? _timer;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Please enter a valid 10-digit mobile number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.sendOtp(phone: phone, type: 'login');
      final receivedOtp = res['otp']?.toString() ?? '1234';
      _otpCtrl.text = receivedOtp;
      setState(() => _otpSent = true);
      _startTimer();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) FocusScope.of(context).requestFocus(_otpFocus);
      });
      _fadeCtrl.reset();
      _fadeCtrl.forward();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() => _error = 'Please enter the 4-digit verification OTP.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.verifyOtpLogin(phone: phone, otp: otp);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FarmerHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final headerHeight = (size.height * 0.32).clamp(245.0, 295.0);
    final footerHeight = (size.height * 0.12).clamp(75.0, 105.0);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── LAYER 1: BOTTOM FOLK ART LIVESTOCK SILHOUETTE STRIP ──
          Positioned(
            bottom: bottomPadding > 0 ? bottomPadding * 0.5 : 4,
            left: 0,
            right: 0,
            height: footerHeight,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/livestock_footer.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ),

          // ── LAYER 2: SCROLLABLE HERO & FORM CONTENT ──────────────
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── TOP HERO HEADER SECTION ────────────────────────
                  _buildHeroHeader(headerHeight, topPadding),

                  // ── MAIN FORM CARD OVERLAY ─────────────────────────
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8ECE9), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                            child: FadeTransition(
                              opacity: _fade,
                              child: _otpSent ? _buildOtpForm() : _buildPhoneForm(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Ensure form card does not touch footer on scroll
                  SizedBox(height: footerHeight + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────
  Widget _buildHeroHeader(double height, double topPadding) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenDark, _greenPrimary, Color(0xFF2E7D32)],
        ),
      ),
      child: Stack(
        children: [
          // Background Landscape Art
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/landscape_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ),

          // Header Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Govt Badges (Enlarged to 50px)
                      Image.asset(
                        'assets/images/national_emblem.png',
                        height: 50,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/images/state_seal.png',
                        height: 50,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GOVERNMENT OF MAHARASHTRA',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.shade200,
                                letterSpacing: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Department of Animal Husbandry',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Centered Pashu Mitra App Logo & Title
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 36, color: Color(0xFF1B5E20)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Pashu Mitra',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phone Input Form (Step 1) ──────────────────────────────
  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B2A1E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your registered mobile number to login`.',
          style: TextStyle(
            fontSize: 14.5,
            color: Colors.grey.shade600,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 24),

        // Mobile Number Field Label
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B2A1E),
          ),
        ),
        const SizedBox(height: 8),

        // Mobile Number Input Box
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _error != null ? Colors.red.shade400 : Colors.grey.shade300,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              // +91 Flag / Country Code Prefix
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10.5)),
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300, width: 1.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                  ],
                ),
              ),

              // Phone Number Input
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Color(0xFF1B2A1E),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    hintText: 'Enter your mobile number',
                    hintStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                    ),
                  ),
                  onSubmitted: (_) => _sendOtp(),
                ),
              ),

              // Clear text button
              if (_phoneCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                  onPressed: () {
                    setState(() => _phoneCtrl.clear());
                  },
                ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildErrorBox(_error!),
        ],

        const SizedBox(height: 24),

        // Primary Send OTP Action Button
        _buildActionButton(
          label: 'Get OTP',
          loadingLabel: 'Sending OTP...',
          icon: Icons.arrow_forward_rounded,
          onPressed: _sendOtp,
        ),

        const SizedBox(height: 24),

        // Switch to Registration
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RegisterFlowScreen()),
            ),
            child: RichText(
              text: TextSpan(
                text: 'New farmer? ',
                style: TextStyle(
                  fontSize: 14.5,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                children: const [
                  TextSpan(
                    text: 'Register here',
                    style: TextStyle(
                      color: _orangePrimary,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── OTP Verification Form (Step 2) ─────────────────────────
  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _greenLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: _greenPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OTP Dispatched',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _greenPrimary,
                      ),
                    ),
                    Text(
                      'Sent to +91 ${_phoneCtrl.text.trim()}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _fadeCtrl.reset();
                  _fadeCtrl.forward();
                  setState(() {
                    _otpSent = false;
                    _otpCtrl.clear();
                    _error = null;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _greenPrimary, width: 1),
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _greenPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B2A1E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please enter the 4-digit.',
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 24),

        // OTP Input Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _otpCtrl,
            focusNode: _otpFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 14,
              color: Color(0xFF1B2A1E),
            ),
            decoration: InputDecoration(
              hintText: '••••',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 28,
                letterSpacing: 10,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FBF9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _greenPrimary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onSubmitted: (_) => _verifyOtp(),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildErrorBox(_error!),
        ],

        const SizedBox(height: 24),

        // Verify and Login Button
        _buildActionButton(
          label: 'Verify & Enter App',
          loadingLabel: 'Verifying OTP...',
          icon: Icons.login_rounded,
          onPressed: _verifyOtp,
        ),

        const SizedBox(height: 20),

        // Resend Timer Row
        Center(
          child: _resendSeconds > 0
              ? Text(
                  'Resend code in $_resendSeconds seconds',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : TextButton.icon(
                  onPressed: _loading ? null : _sendOtp,
                  icon: const Icon(Icons.refresh_rounded, color: _orangePrimary, size: 18),
                  label: const Text(
                    'Resend OTP Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _orangePrimary,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Action Button with Sharp Corners ───────────────────────
  Widget _buildActionButton({
    required String label,
    required String loadingLabel,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [_orangePrimary, _orangeDark],
        ),
        boxShadow: [
          BoxShadow(
            color: _orangePrimary.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _loading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loadingLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(icon, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Error Banner ───────────────────────────────────────────
  Widget _buildErrorBox(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF9A9A), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
