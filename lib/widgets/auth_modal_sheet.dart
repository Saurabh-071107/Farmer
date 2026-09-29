import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';

enum AuthMode { login, register }
enum RegisterStep { aadhaarVerify, mobileOtp }

class FarmerAuthSheet extends StatefulWidget {
  final AuthMode initialMode;

  const FarmerAuthSheet({
    super.key,
    this.initialMode = AuthMode.login,
  });

  static Future<void> show(BuildContext context, {AuthMode mode = AuthMode.login}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FarmerAuthSheet(initialMode: mode),
    );
  }

  @override
  State<FarmerAuthSheet> createState() => _FarmerAuthSheetState();
}

class _FarmerAuthSheetState extends State<FarmerAuthSheet> {
  final FarmerApiService _apiService = FarmerApiService();

  late AuthMode _currentMode;
  RegisterStep _registerStep = RegisterStep.aadhaarVerify;

  // Login Controllers
  final _loginPhoneController = TextEditingController(text: '9876543210');
  final _loginOtpController = TextEditingController();
  bool _loginOtpSent = false;
  String? _loginServerOtp;
  bool _isLoginLoading = false;
  String? _loginError;

  // Register Controllers (Step 1: Aadhaar)
  final _regNameController = TextEditingController(text: 'Ramesh Patel');
  final _regAadhaarController = TextEditingController(text: '548291042381');
  final _regFarmerIdController = TextEditingController();
  final _regVillageController = TextEditingController(text: 'Khed');
  final _regDistrictController = TextEditingController(text: 'Pune');
  String? _verifiedFarmerId;

  // Register Controllers (Step 2: Mobile & OTP)
  final _regPhoneController = TextEditingController();
  final _regOtpController = TextEditingController();
  bool _regOtpSent = false;
  String? _regServerOtp;
  bool _isRegLoading = false;
  String? _regError;

  // Resend Countdown Timer
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loginPhoneController.dispose();
    _loginOtpController.dispose();
    _regNameController.dispose();
    _regAadhaarController.dispose();
    _regFarmerIdController.dispose();
    _regVillageController.dispose();
    _regDistrictController.dispose();
    _regPhoneController.dispose();
    _regOtpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // LOGIN FLOW HANDLERS
  // ---------------------------------------------------------------------------
  Future<void> _handleSendLoginOtp() async {
    final phone = _loginPhoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _loginError = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isLoginLoading = true;
      _loginError = null;
    });

    try {
      final res = await _apiService.sendOtp(phone: phone, type: 'login');
      setState(() {
        _loginOtpSent = true;
        _loginServerOtp = res['otp'] ?? '1234';
        _loginOtpController.text = res['otp'] ?? '1234';
      });
      _startTimer();
    } catch (e) {
      setState(() => _loginError = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoginLoading = false);
    }
  }

  Future<void> _handleVerifyLoginOtp() async {
    final phone = _loginPhoneController.text.trim();
    final otp = _loginOtpController.text.trim();

    if (otp.length < 4) {
      setState(() => _loginError = 'Please enter the OTP (Demo: 1234).');
      return;
    }

    setState(() {
      _isLoginLoading = true;
      _loginError = null;
    });

    try {
      await _apiService.verifyOtpLogin(phone: phone, otp: otp);

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FarmerHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _loginError = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoginLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTRATION FLOW HANDLERS
  // ---------------------------------------------------------------------------
  Future<void> _handleVerifyAadhaar() async {
    final name = _regNameController.text.trim();
    final aadhaar = _regAadhaarController.text.trim();

    if (name.isEmpty) {
      setState(() => _regError = 'Please enter your Full Name.');
      return;
    }

    if (aadhaar.replaceAll(RegExp(r'\D'), '').length != 12) {
      setState(() => _regError = 'Aadhaar Number must be exactly 12 numeric digits.');
      return;
    }

    setState(() {
      _isRegLoading = true;
      _regError = null;
    });

    try {
      final res = await _apiService.verifyAadhaar(
        aadhaarNumber: aadhaar,
        farmerId: _regFarmerIdController.text.trim(),
        name: name,
      );

      setState(() {
        _verifiedFarmerId = res['farmerId'];
        _registerStep = RegisterStep.mobileOtp;
      });
    } catch (e) {
      setState(() => _regError = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isRegLoading = false);
    }
  }

  Future<void> _handleSendRegisterOtp() async {
    final phone = _regPhoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _regError = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isRegLoading = true;
      _regError = null;
    });

    try {
      final res = await _apiService.sendOtp(phone: phone, type: 'register');
      setState(() {
        _regOtpSent = true;
        _regServerOtp = res['otp'];
        _regOtpController.text = res['otp'] ?? '123456';
      });
      _startTimer();
    } catch (e) {
      setState(() => _regError = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isRegLoading = false);
    }
  }

  Future<void> _handleCompleteRegistration() async {
    final phone = _regPhoneController.text.trim();
    final otp = _regOtpController.text.trim();

    if (otp.length < 4) {
      setState(() => _regError = 'Please enter the OTP (Demo: 1234).');
      return;
    }

    setState(() {
      _isRegLoading = true;
      _regError = null;
    });

    try {
      await _apiService.completeRegistration(
        name: _regNameController.text.trim(),
        phone: phone,
        aadhaarNumber: _regAadhaarController.text.trim(),
        farmerId: _verifiedFarmerId ?? _regFarmerIdController.text.trim(),
        village: _regVillageController.text.trim(),
        district: _regDistrictController.text.trim(),
        state: 'Maharashtra',
        otp: otp,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FarmerHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _regError = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isRegLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFAF5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Top Segmented Switcher (Login / Register)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'Login (Mobile OTP)',
                      isSelected: _currentMode == AuthMode.login,
                      onTap: () {
                        setState(() {
                          _currentMode = AuthMode.login;
                          _loginError = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'Register (Aadhaar)',
                      isSelected: _currentMode == AuthMode.register,
                      onTap: () {
                        setState(() {
                          _currentMode = AuthMode.register;
                          _regError = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _currentMode == AuthMode.login
                    ? _buildLoginForm()
                    : _buildRegisterForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGIN FORM VIEW
  // ---------------------------------------------------------------------------
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF1B5E20), size: 22),
            SizedBox(width: 8),
            Text(
              'Secure Farmer Login',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter your registered 10-digit mobile number to verify via instant OTP.',
          style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 16),

        if (_loginError != null) _buildErrorBanner(_loginError!),

        // Mobile Number Field
        _buildPhoneField(
          controller: _loginPhoneController,
          enabled: !_loginOtpSent,
        ),

        const SizedBox(height: 12),

        // Pre-fill Demo Account Helper Pill
        if (!_loginOtpSent)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () {
                setState(() {
                  _loginPhoneController.text = '9876543210';
                  _loginError = null;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: Color(0xFFE65100), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Demo: Ramesh Patel (9876543210) | OTP: 1234',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // OTP Field (Shown once OTP is requested)
        if (_loginOtpSent) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OTP sent to +91 ${_loginPhoneController.text}. Demo OTP is $_loginServerOtp',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildOtpField(controller: _loginOtpController),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _loginOtpSent = false),
                child: const Text('Change Number', style: TextStyle(fontSize: 12.5)),
              ),
              Text(
                _secondsRemaining > 0 ? 'Resend in ${_secondsRemaining}s' : '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Primary Action Button
        ElevatedButton(
          onPressed: _isLoginLoading
              ? null
              : (_loginOtpSent ? _handleVerifyLoginOtp : _handleSendLoginOtp),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6D00),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 4,
          ),
          child: _isLoginLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _loginOtpSent ? 'Verify OTP & Login' : 'Get Login OTP',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REGISTRATION FORM VIEW (STEP 1 & STEP 2)
  // ---------------------------------------------------------------------------
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stepper Header
        Row(
          children: [
            _buildStepCircle(step: 1, label: 'Aadhaar KYC', isActive: _registerStep == RegisterStep.aadhaarVerify),
            Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
            _buildStepCircle(step: 2, label: 'Mobile OTP', isActive: _registerStep == RegisterStep.mobileOtp),
          ],
        ),
        const SizedBox(height: 16),

        if (_regError != null) _buildErrorBanner(_regError!),

        // STEP 1: AADHAAR & FARMER VERIFICATION
        if (_registerStep == RegisterStep.aadhaarVerify) ...[
          const Text(
            'Step 1: Government Identity Verification',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verify your 12-digit Aadhaar Card with National Livestock & DBT Database.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 14),

          _buildInputField(
            controller: _regNameController,
            label: 'Farmer Full Name (As on Aadhaar)',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),

          _buildInputField(
            controller: _regAadhaarController,
            label: '12-Digit Aadhaar Card Number',
            icon: Icons.credit_card_outlined,
            keyboardType: TextInputType.number,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _regVillageController,
                  label: 'Village / Taluka',
                  icon: Icons.home_work_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  controller: _regDistrictController,
                  label: 'District',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildInputField(
            controller: _regFarmerIdController,
            label: 'Farmer ID / Kisan Card (Optional)',
            icon: Icons.badge_outlined,
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isRegLoading ? null : _handleVerifyAadhaar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: _isRegLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify Identity & Proceed',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ],

        // STEP 2: MOBILE NUMBER & OTP VERIFICATION
        if (_registerStep == RegisterStep.mobileOtp) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identity Verified: ${_regNameController.text}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1B5E20), fontSize: 13),
                      ),
                      Text(
                        'Assigned Farmer ID: $_verifiedFarmerId',
                        style: const TextStyle(color: Color(0xFF388E3C), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _registerStep = RegisterStep.aadhaarVerify),
                  child: const Text('Edit', style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Step 2: Link Mobile Number',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Important Rule: Each phone number can only have ONE registered account.',
            style: TextStyle(fontSize: 12, color: Color(0xFFD84315), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),

          _buildPhoneField(
            controller: _regPhoneController,
            enabled: !_regOtpSent,
          ),

          if (_regOtpSent) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sms_outlined, color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OTP sent to +91 ${_regPhoneController.text}. Demo Code: $_regServerOtp',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFBF360C)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildOtpField(controller: _regOtpController),
          ],

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isRegLoading
                ? null
                : (_regOtpSent ? _handleCompleteRegistration : _handleSendRegisterOtp),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: _isRegLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _regOtpSent ? 'Verify & Create Account' : 'Send Mobile Verification OTP',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildStepCircle({required int step, required String label, required bool isActive}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? const Color(0xFF1B5E20) : Colors.grey.shade300,
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF1B5E20) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        counterText: '',
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          margin: const EdgeInsets.only(right: 8),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇮🇳 +91', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            ],
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF1F8E9).withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
        ),
      ),
    );
  }

  Widget _buildOtpField({required TextEditingController controller}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 8,
        color: Color(0xFF1B5E20),
      ),
      decoration: InputDecoration(
        labelText: 'Enter OTP (Demo: 1234)',
        counterText: '',
        prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFF1B5E20)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFA5D6A7), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
        filled: true,
        fillColor: const Color(0xFFF1F8E9).withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.6),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
