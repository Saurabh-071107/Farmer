import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';
import '../services/app_translations.dart';
import '../widgets/floating_nav_bar.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onNavTap;

  const ProfileScreen({
    super.key,
    this.onBackToHome,
    this.onNavTap,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bg = Color(0xFFFAF8F2);
  static const Color _green = Color(0xFF1B5E20);
  static const Color _orange = Color(0xFFFF6D00);
  static const Color _dangerRed = Color(0xFFC62828);

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'P';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFCFAF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.language_rounded, color: _orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'select_language'.tr.isNotEmpty ? 'select_language'.tr : 'Change Language',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2A1E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'select_preferred_language'.tr,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF616161)),
              ),
              const SizedBox(height: 18),
              ...AppTranslations.supportedLanguages.map((lang) {
                final isSelected = SessionManager().language == lang.code;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      await SessionManager().setLanguage(lang.code);
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? _green : Colors.grey.shade300,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? _green : Colors.grey.shade100,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lang.code.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? Colors.white : const Color(0xFF424242),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.nativeName,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? _green : const Color(0xFF212121),
                                  ),
                                ),
                                Text(
                                  lang.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _green,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFCFAF5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: _dangerRed, size: 24),
            SizedBox(width: 10),
            Text(
              'Confirm Logout',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1B2A1E),
              ),
            ),
          ],
        ),
        content: Text(
          'logout_confirm'.tr,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF424242), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'logout'.tr,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await SessionManager().clearSession();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FarmerLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser ??
        FarmerUser(
          id: 'demo-farmer-01',
          name: 'Ramesh Patel',
          phone: '9876543210',
          email: 'ramesh.patel@agri.gov.in',
          role: 'farmer',
          farmerId: 'MH-PASHU-2024-8921',
          aadhaarNumber: '548291042381',
          aadhaarVerified: true,
          village: 'Shirdi',
          district: 'Ahmednagar',
          state: 'Maharashtra',
          createdAt: DateTime.now().toIso8601String(),
        );

    final initials = _getInitials(user.name);
    final animalsCount = FarmerApiService.getCachedAnimals().length;
    final currentLang = AppTranslations.supportedLanguages.firstWhere(
      (l) => l.code == SessionManager().language,
      orElse: () => AppTranslations.supportedLanguages.first,
    );

    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      bottomNavigationBar: widget.onNavTap != null
          ? null
          : FloatingNavBar(
              currentIndex: 4,
              onTap: (index) {
                if (index == 0 && widget.onBackToHome != null) {
                  widget.onBackToHome!();
                } else if (index == 4) {
                  // Already on Profile
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top App Bar
              Row(
                children: [
                  if (widget.onBackToHome != null)
                    InkWell(
                      onTap: widget.onBackToHome,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF263238),
                          size: 26,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      'profile_title'.tr,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: _green),
                        const SizedBox(width: 4),
                        Text(
                          'active_status'.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 1. Farmer Identity Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8EDE8), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar circle with initials
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFB300),
                        border: Border.all(color: const Color(0xFFC8E6C9), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: initials.length > 1 ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          color: _green,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2A1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Farmer ID pill
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: user.farmerId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Farmer ID copied to clipboard.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${"farmer_id".tr}: ${user.farmerId}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: _orange,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Aadhaar Verified Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded, size: 14, color: _green),
                                const SizedBox(width: 4),
                                Text(
                                  'aadhaar_verified'.tr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Farm & Personal Details Section (Clean, neatly boxed)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE8EDE8), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'farmer_details'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      icon: Icons.phone_android_rounded,
                      label: 'phone_number'.tr,
                      value: '+91 ${user.phone}',
                      iconColor: _green,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F1F1)),
                    _buildDetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'location'.tr,
                      value: '${user.village}, ${user.district}, ${user.state}',
                      iconColor: _orange,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F1F1)),
                    _buildDetailRow(
                      icon: Icons.pets_rounded,
                      label: 'total_livestock'.tr,
                      value: '$animalsCount Animals Registered',
                      iconColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Language Selection Card (Important Feature)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE8EDE8), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.translate_rounded, color: _orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${"app_language".tr} • ${currentLang.nativeName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2A1E),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _showLanguageSelector,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _green,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'select_preferred_language'.tr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Language option buttons in responsive row/wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppTranslations.supportedLanguages.map((lang) {
                        final isSel = SessionManager().language == lang.code;
                        return GestureDetector(
                          onTap: () async {
                            await SessionManager().setLanguage(lang.code);
                            setState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSel ? _green : const Color(0xFFF5F7F5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel ? _green : Colors.grey.shade300,
                                width: 1.2,
                              ),
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(
                                        color: _green.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  lang.nativeName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? Colors.white : const Color(0xFF2E7D32),
                                  ),
                                ),
                                if (isSel) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Kisan Call Center & Helpline Card (Official Govt Support)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'kisan_call_center'.tr,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'kisan_helpline_desc'.tr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'call_now'.tr,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: _orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 5. Logout Button
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, size: 20, color: _dangerRed),
                label: Text(
                  'logout'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _dangerRed,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF9A9A), width: 1.4),
                  backgroundColor: const Color(0xFFFFEBEE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2A1E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
