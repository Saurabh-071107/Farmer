import 'dart:async';
import 'package:flutter/material.dart';
import '../services/active_consultation_state.dart';
import '../services/api_service.dart';
import '../services/app_translations.dart';
import 'agora_video_call_screen.dart';

class QueueWaitingRoomScreen extends StatefulWidget {
  final bool isAppointment;

  const QueueWaitingRoomScreen({
    super.key,
    this.isAppointment = false,
  });

  @override
  State<QueueWaitingRoomScreen> createState() => _QueueWaitingRoomScreenState();
}

class _QueueWaitingRoomScreenState extends State<QueueWaitingRoomScreen> {
  final FarmerApiService _api = FarmerApiService();
  Timer? _pollingTimer;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 3 seconds for live queue changes & doctor incoming calls
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      await _checkQueueAndCalls();
    });
    // Immediate first check
    _checkQueueAndCalls();
  }

  Future<void> _checkQueueAndCalls() async {
    final state = ActiveConsultationState.instance;

    // 1. Check for incoming call initiated by doctor
    try {
      final callData = await _api.checkIncomingCall(
        appointmentId: state.queueAppointmentId ?? state.appointmentId,
      );

      if (callData != null && callData['hasIncomingCall'] == true && mounted) {
        _pollingTimer?.cancel();
        final appointment = callData['appointment'] ?? {};
        final channel = callData['agoraChannel'] ?? appointment['callRoomId'] ?? 'telecom-room';
        final aptId = (appointment['id'] ?? state.queueAppointmentId ?? state.appointmentId ?? 'apt-call').toString();

        state.startCall(aptId);
        _api.acceptCall(aptId);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AgoraVideoCallScreen(
              appointmentId: aptId,
              channelName: channel,
              doctorName: state.queueDoctorName ?? state.appointmentDoctorName ?? 'Veterinarian',
              animalName: state.queueAnimalName ?? state.appointmentAnimal ?? 'Livestock',
            ),
          ),
        );
        return;
      }
    } catch (_) {}

    // 2. Refresh queue position
    if (!widget.isAppointment) {
      try {
        final qStatus = await _api.getQueueStatus();
        if (qStatus != null && qStatus['inQueue'] == true && mounted) {
          state.updateQueueStatus(
            queueToken: qStatus['tokenNumber'] ?? qStatus['token'],
            servingToken: qStatus['currentlyServing'] ?? qStatus['servingToken'],
            positionAhead: qStatus['patientsAhead'] ?? qStatus['position'] ?? qStatus['positionAhead'],
            estimatedMinutes: qStatus['estimatedWaitMinutes'],
          );
          if (qStatus['appointment'] != null && qStatus['appointment']['id'] != null) {
            state.queueAppointmentId = qStatus['appointment']['id'].toString();
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _confirmLeaveQueue() async {
    final state = ActiveConsultationState.instance;
    final token = state.queueToken ?? 'Q-01';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text('leave_queue'.tr.isNotEmpty ? 'leave_queue'.tr : 'Leave Queue?'),
          ],
        ),
        content: Text(
          'Are you sure you want to leave the consultation queue? You will forfeit Token $token and have to register again.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave Queue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLeaving = true);
      _pollingTimer?.cancel();

      if (state.queueAppointmentId != null) {
        await _api.leaveQueue(state.queueAppointmentId!);
      }
      state.clearQueue();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left the queue.'),
            backgroundColor: Colors.black87,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ActiveConsultationState.instance,
      builder: (context, _) {
        final state = ActiveConsultationState.instance;
        final isQueue = !widget.isAppointment && state.hasQueue;

        final doctorName = isQueue ? (state.queueDoctorName ?? 'Dr. Anand Sharma') : (state.appointmentDoctorName ?? 'Dr. Anand Sharma');
        final doctorImage = isQueue ? (state.queueDoctorImage ?? 'assets/images/doctor.png') : (state.appointmentDoctorImage ?? 'assets/images/doctor.png');
        final doctorSpec = isQueue ? (state.queueDoctorSpecialization ?? 'Bovine Medicine & Surgery') : (state.appointmentDoctorSpecialization ?? 'Veterinary Officer');
        final doctorClinic = state.queueDoctorClinic ?? 'Veterinary Dispensary';

        final animalName = isQueue ? (state.queueAnimalName ?? 'Livestock') : (state.appointmentAnimal ?? 'Livestock');
        final animalTag = isQueue ? (state.queueAnimalTag ?? 'ANML-01') : (state.appointmentAnimalTag ?? 'ANML-01');
        final symptoms = isQueue ? state.queueSymptoms : state.appointmentSymptoms;
        final photos = isQueue ? state.queuePhotos : state.appointmentPhotos;

        final myToken = state.queueToken ?? 'Q-01';
        final servingToken = state.queueServingToken ?? 'Q-01';
        final ahead = state.queuePositionAhead ?? 0;
        final estMins = state.queueEstimatedMinutes ?? (ahead * 3);

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isQueue ? 'Live Queue Waiting Room' : 'Appointment Waiting Room',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isQueue ? 'Live Sync Active' : 'Scheduled Confirmation',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LIVE QUEUE HERO CARD OR APPOINTMENT SLIP
                if (isQueue)
                  _buildQueueStatusHero(myToken, servingToken, ahead, estMins)
                else
                  _buildAppointmentSlipHero(state),

                const SizedBox(height: 16),

                // 2. ATTENDING DOCTOR CARD
                _buildDoctorCard(doctorName, doctorImage, doctorSpec, doctorClinic),

                const SizedBox(height: 16),

                // 3. PATIENT & INTAKE DETAILS CARD
                _buildPatientIntakeCard(animalName, animalTag, symptoms, photos, state.queueDescription),

                const SizedBox(height: 16),

                // 4. WAITING NOTICE / INSTRUCTIONS
                _buildInstructionsCard(),

                const SizedBox(height: 24),

                // 5. LEAVE QUEUE BUTTON (Only in Queue flow)
                if (isQueue)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _isLeaving ? null : _confirmLeaveQueue,
                    icon: _isLeaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                        : const Icon(Icons.exit_to_app_rounded),
                    label: Text(
                      _isLeaving ? 'Leaving Queue...' : 'Leave Consultation Queue',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueStatusHero(String myToken, String servingToken, int ahead, int estMins) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'WAITING ROOM',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ahead == 0 ? 'YOU ARE NEXT!' : 'Turn: #$ahead ahead',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'YOUR TOKEN',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      myToken,
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 60, color: Colors.white24),
              Column(
                children: [
                  const Text(
                    'NOW SERVING',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      servingToken,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  ahead == 0
                      ? 'Doctor is preparing to call you now'
                      : 'Estimated Wait: ~$estMins mins ($ahead patient${ahead > 1 ? 's' : ''} in queue)',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSlipHero(ActiveConsultationState state) {
    final aptNum = state.appointmentNumber ?? 'APT-2026-PENDING';
    final isAccepted = (state.appointmentStatus ?? '').toLowerCase() == 'accepted';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIGITAL APPOINTMENT SLIP',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAccepted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAccepted ? 'DOCTOR CONFIRMED' : 'AWAITING ACCEPTANCE',
                  style: TextStyle(
                    color: isAccepted ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aptNum,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B5E20),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${state.appointmentDate ?? "Scheduled Date"} at ${state.appointmentTime ?? "Selected Time"}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(String name, String image, String spec, String clinic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 54,
              height: 54,
              color: const Color(0xFFE8F5E9),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF1B5E20), size: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 2),
                Text(
                  spec,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 2),
                Text(
                  clinic,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientIntakeCard(
    String animalName,
    String tag,
    List<String> symptoms,
    List<String> photos,
    String notes,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PATIENT & INTAKE DETAILS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.6),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tag #$tag',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            animalName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (symptoms.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: symptoms.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (notes.isNotEmpty) ...[
            Text(
              notes,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: photos.take(3).map((p) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade100,
                ),
                child: const Icon(Icons.image_rounded, size: 24, color: Colors.grey),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waiting Room Guidelines',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Please keep your phone nearby with volume ON.\n• Dr. will initiate the video call when your turn arrives.\n• Farmers cannot initiate the call directly.',
                  style: TextStyle(fontSize: 11.5, height: 1.4, color: Colors.green.shade900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
