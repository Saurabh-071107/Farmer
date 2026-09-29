import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_flow_screen.dart';

class RegisterFlowScreen extends StatefulWidget {
  const RegisterFlowScreen({super.key});

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen>
    with SingleTickerProviderStateMixin {
  // ── Brand Colors ───────────────────────────────────────────
  static const _greenPrimary = Color(0xFF1B5E20);
  static const _greenDark = Color(0xFF0D3A13);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _orangePrimary = Color(0xFFFF6D00);
  static const _orangeDark = Color(0xFFE65100);
  static const _bg = Color(0xFFFCFAF5);

  // ── State & Controllers ────────────────────────────────────
  final _api = FarmerApiService();

  // Step 1 Controllers
  final _nameCtrl = TextEditingController(text: 'Ramesh Patel');
  final _aadhaarCtrl = TextEditingController(text: '5482 9104 2381');
  final _farmerIdCtrl = TextEditingController();

  // Step 2 Controllers
  final _phoneCtrl = TextEditingController(text: '9876543210');
  final _otpCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  int _step = 0; // 0 = Aadhaar & Identity, 1 = Phone & OTP
  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  String? _verifiedFarmerId;
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
    _nameCtrl.dispose();
    _aadhaarCtrl.dispose();
    _farmerIdCtrl.dispose();
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

  void _goToStep(int step) {
    _fadeCtrl.reset();
    setState(() {
      _step = step;
      _error = null;
    });
    _fadeCtrl.forward();
  }

  // ── Step 1 Handler: Verify Aadhaar ─────────────────────────
  Future<void> _verifyAadhaar() async {
    final name = _nameCtrl.text.trim();
    final rawAadhaar = _aadhaarCtrl.text.replaceAll(RegExp(r'\D'), '');

    final farmerId = _farmerIdCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your full name as per Aadhaar.');
      return;
    }
    if (rawAadhaar.length != 12) {
      setState(() => _error = 'Aadhaar number must be exactly 12 numeric digits.');
      return;
    }
    if (farmerId.isEmpty) {
      setState(() => _error = 'State Farmer ID / KCC ID is mandatory and cannot be empty.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.verifyAadhaar(
        aadhaarNumber: rawAadhaar,
        farmerId: farmerId,
        name: name,
      );
      _verifiedFarmerId = res['farmerId'] ?? farmerId;
      _goToStep(1);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Step 2 Handlers: OTP ───────────────────────────────────
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
      final res = await _api.sendOtp(phone: phone, type: 'register');
      _otpCtrl.text = res['otp']?.toString() ?? '1234';
      setState(() => _otpSent = true);
      _startTimer();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) FocusScope.of(context).requestFocus(_otpFocus);
      });
    } catch (e) {
      if (phone == '9876543210') {
        _otpCtrl.text = '1234';
        setState(() => _otpSent = true);
        _startTimer();
      } else {
        setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeRegistration() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    if (otp.length < 4) {
      setState(() => _error = 'Please enter the 4-digit verification code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.completeRegistration(
        name: _nameCtrl.text.trim(),
        phone: phone,
        aadhaarNumber: _aadhaarCtrl.text.replaceAll(RegExp(r'\D'), ''),
        farmerId: _verifiedFarmerId ?? _farmerIdCtrl.text.trim(),
        village: 'Shirdi',
        district: 'Ahmednagar',
        state: 'Maharashtra',
        otp: otp,
      );

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
                            padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Step Indicator Progress Bar
                                _buildStepIndicator(),

                                const SizedBox(height: 20),

                                FadeTransition(
                                  opacity: _fade,
                                  child: _step == 0 ? _buildAadhaarStep() : _buildPhoneStep(),
                                ),
                              ],
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
              opacity: 0.16,
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
                        onTap: () {
                          if (_step == 1) {
                            _goToStep(0);
                          } else {
                            Navigator.pop(context);
                          }
                        },
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
                                fontSize: 12.5,
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

  // ── Step Indicator Progress Bar ────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        // Step 1 Pill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: _step == 0 ? _greenLight : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _step == 0 ? _greenPrimary : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundColor: _step == 0 ? _greenPrimary : Colors.grey.shade500,
                  child: Text(
                    '1',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Aadhaar ID',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _step == 0 ? _greenPrimary : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Step 2 Pill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: _step == 1 ? _greenLight : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _step == 1 ? _greenPrimary : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundColor: _step == 1 ? _greenPrimary : Colors.grey.shade400,
                  child: Text(
                    '2',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Mobile OTP',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _step == 1 ? _greenPrimary : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Aadhaar Form ───────────────────────────────────
  Widget _buildAadhaarStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identity Verification',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B2A1E),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Verify your Aadhaar to link animal records to your registered farmer profile.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.35,
          ),
        ),

        const SizedBox(height: 24),

        // Farmer Full Name
        _buildFieldLabel('Full Name (as on Aadhaar)'),
        const SizedBox(height: 6),
        _buildTextInput(
          controller: _nameCtrl,
          hint: 'e.g. Ramesh Patel',
          icon: Icons.person_outline_rounded,
        ),

        const SizedBox(height: 16),

        // Aadhaar Number
        _buildFieldLabel('12-Digit Aadhaar Number'),
        const SizedBox(height: 6),
        _buildTextInput(
          controller: _aadhaarCtrl,
          hint: '5482 9104 2381',
          icon: Icons.fingerprint_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
        ),

        const SizedBox(height: 16),

        // Mandatory Farmer ID
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('State Farmer ID / KCC Number *'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200, width: 0.8),
              ),
              child: Text(
                'Required',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildTextInput(
          controller: _farmerIdCtrl,
          hint: 'e.g. MH-PASHU-2024-8921',
          icon: Icons.badge_outlined,
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildErrorBox(_error!),
        ],

        const SizedBox(height: 24),

        // Verify and Continue Button
        _buildActionButton(
          label: 'Verify Aadhaar & Proceed',
          loadingLabel: 'Verifying with UIDAI...',
          icon: Icons.arrow_forward_rounded,
          onPressed: _verifyAadhaar,
        ),

        const SizedBox(height: 20),

        // Back to Login Link
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginFlowScreen()),
            ),
            child: RichText(
              text: TextSpan(
                text: 'Already registered? ',
                style: TextStyle(
                  fontSize: 14.5,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                children: const [
                  TextSpan(
                    text: 'Login here',
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

  // ── Step 2: Phone & OTP Form ───────────────────────────────
  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verified Aadhaar Badge Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _greenLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: _greenPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aadhaar Verified Successfully',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _greenPrimary,
                      ),
                    ),
                    Text(
                      _nameCtrl.text.trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    if (_verifiedFarmerId != null)
                      Text(
                        'Assigned ID: $_verifiedFarmerId',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Mobile Authentication',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B2A1E),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your mobile number to receive security alerts and OTP login credentials.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.35,
          ),
        ),

        const SizedBox(height: 18),

        _buildFieldLabel('Mobile Number'),
        const SizedBox(height: 6),

        // Mobile Number Input Box
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10.5)),
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300, width: 1.2),
                  ),
                ),
                child: const Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B2A1E),
                  ),
                ),
              ),
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
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    hintText: '9876543210',
                  ),
                ),
              ),
              if (!_otpSent)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _orangePrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (_otpSent) ...[
          const SizedBox(height: 20),
          _buildFieldLabel('Enter 4-Digit OTP'),
          const SizedBox(height: 6),
          TextField(
            controller: _otpCtrl,
            focusNode: _otpFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 12,
              color: Color(0xFF1B2A1E),
            ),
            decoration: InputDecoration(
              hintText: '••••',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _completeRegistration(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Demo OTP is 1234',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
              _resendSeconds > 0
                  ? Text(
                      'Resend in $_resendSeconds s',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    )
                  : GestureDetector(
                      onTap: _sendOtp,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _orangePrimary,
                        ),
                      ),
                    ),
            ],
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildErrorBox(_error!),
        ],

        const SizedBox(height: 24),

        // Action Button: Send OTP or Complete Registration
        if (!_otpSent)
          _buildActionButton(
            label: 'Get Verification OTP',
            loadingLabel: 'Sending OTP...',
            icon: Icons.sms_rounded,
            onPressed: _sendOtp,
          )
        else
          _buildActionButton(
            label: 'Complete Registration & Login',
            loadingLabel: 'Finalizing Account...',
            icon: Icons.done_all_rounded,
            onPressed: _completeRegistration,
          ),

        const SizedBox(height: 16),

        // Change Aadhaar button
        Center(
          child: TextButton.icon(
            onPressed: () => _goToStep(0),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text(
              'Edit Aadhaar / Identity details',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1B2A1E),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: _greenPrimary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2A1E),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
