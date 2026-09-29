import 'package:flutter/material.dart';
import '../screens/agora_video_call_screen.dart';
import '../services/active_consultation_state.dart';
import '../services/api_service.dart';

class IncomingCallOverlay extends StatefulWidget {
  final Map<String, dynamic> appointmentData;
  final VoidCallback onDismiss;

  const IncomingCallOverlay({
    super.key,
    required this.appointmentData,
    required this.onDismiss,
  });

  static void show(BuildContext context, Map<String, dynamic> appointmentData) {
    if (ActiveConsultationState.instance.isInActiveCall) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => IncomingCallOverlay(
        appointmentData: appointmentData,
        onDismiss: () => Navigator.of(ctx, rootNavigator: true).pop(),
      ),
    );
  }

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get apt =>
      widget.appointmentData['appointment'] as Map<String, dynamic>? ?? widget.appointmentData;

  String get doctorName => apt['vetName']?.toString() ?? 'Dr. Anand Sharma';
  String get doctorSpecialization => apt['vetSpecialization']?.toString() ?? 'Veterinary Medical Officer';
  String get animalName => apt['animalName']?.toString() ?? 'Livestock Patient';
  String get channelName =>
      widget.appointmentData['agoraChannel']?.toString() ?? apt['callRoomId']?.toString() ?? 'pashu_agora_call';
  String get appointmentId => apt['id']?.toString() ?? 'apt-live';

  void _acceptCall() async {
    ActiveConsultationState.instance.startCall(appointmentId);
    await FarmerApiService().acceptCall(appointmentId);
    widget.onDismiss();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AgoraVideoCallScreen(
            appointmentId: appointmentId,
            channelName: channelName,
            doctorName: doctorName,
            doctorRole: doctorSpecialization,
            animalName: animalName,
          ),
        ),
      );
    }
  }

  void _declineCall() async {
    await FarmerApiService().cancelAppointment(appointmentId);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calling Header Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.video_call_rounded, color: Color(0xFF4ADE80), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Incoming Tele-Vet Video Call',
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Pulsing Doctor Avatar
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF22C55E), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/doctor_1.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person,
                          size: 54,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Doctor Information
            Text(
              doctorName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              doctorSpecialization,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Animal Tag Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                'Patient: $animalName',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Action Buttons: Decline & Accept
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _declineCall,
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Decline',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                // Accept Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _acceptCall,
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accept Call',
                      style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
