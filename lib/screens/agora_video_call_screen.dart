import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/active_consultation_state.dart';
import '../services/agora_rtc_service.dart';
import '../services/api_service.dart';

class AgoraVideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String channelName;
  final String doctorName;
  final String doctorRole;
  final String doctorImage;
  final String animalName;

  const AgoraVideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.channelName,
    required this.doctorName,
    this.doctorRole = 'Veterinary Officer (B.V.Sc & A.H.)',
    this.doctorImage = 'assets/images/doctor_1.png',
    this.animalName = 'Livestock',
  });

  @override
  State<AgoraVideoCallScreen> createState() => _AgoraVideoCallScreenState();
}

class _AgoraVideoCallScreenState extends State<AgoraVideoCallScreen>
    with SingleTickerProviderStateMixin {
  final AgoraRtcService _rtcService = AgoraRtcService();
  final FarmerApiService _apiService = FarmerApiService();

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription> _availableCameras = [];

  // Live Peer Stream & Audio State
  String? _doctorFrameBase64;
  bool _doctorMuted = false;
  bool _doctorVideoOff = false;
  bool _isCapturingFrame = false;
  Timer? _streamSyncTimer;
  Timer? _callStatusPollTimer;
  bool _hasConcluded = false;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    ActiveConsultationState.instance.startCall(widget.appointmentId);
    _rtcService.joinChannel(channelName: widget.channelName);
    _initCamera();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // 1. Live stream frame & audio sync timer (Every 1.5 seconds)
    _streamSyncTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _syncStreamAndAudio();
    });

    // 2. Poll for call completion by doctor (Every 2 seconds)
    _callStatusPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkCallEndedByDoctor();
    });
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        final camera = _availableCameras.firstWhere(
          (c) => c.lensDirection == (_rtcService.isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
          orElse: () => _availableCameras.first,
        );
        _cameraController = CameraController(
          camera,
          ResolutionPreset.low,
          enableAudio: !_rtcService.isMuted,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Farmer camera init error: $e');
    }
  }

  Future<void> _switchCamera() async {
    _rtcService.switchCamera();
    if (_availableCameras.length < 2) return;
    await _cameraController?.dispose();
    _cameraController = null;
    setState(() => _isCameraInitialized = false);
    await _initCamera();
  }

  Future<void> _syncStreamAndAudio() async {
    if (!mounted || _hasConcluded) return;

    // Capture local frame if video is enabled
    String? localFrame;
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_isCapturingFrame &&
        !_rtcService.isVideoOff) {
      _isCapturingFrame = true;
      try {
        final xfile = await _cameraController!.takePicture();
        final bytes = await xfile.readAsBytes();
        File(xfile.path).delete().ignore();
        localFrame = base64Encode(bytes);
      } catch (_) {}
      _isCapturingFrame = false;
    }

    // Push local frame and audio status to backend
    await _apiService.pushStreamFrame(
      appointmentId: widget.appointmentId,
      role: 'farmer',
      frame: localFrame,
      isAudioActive: !_rtcService.isMuted,
      isMuted: _rtcService.isMuted,
      isVideoOff: _rtcService.isVideoOff,
    );

    // Fetch peer (doctor) frame and audio status
    final peerData = await _apiService.getPeerStreamFrame(
      appointmentId: widget.appointmentId,
      peerRole: 'doctor',
    );

    if (peerData != null && mounted) {
      setState(() {
        if (peerData['frame'] != null && peerData['frame'].toString().isNotEmpty) {
          _doctorFrameBase64 = peerData['frame'].toString();
        }
        _doctorMuted = peerData['isMuted'] == true;
        _doctorVideoOff = peerData['isVideoOff'] == true;
      });
    }
  }

  Future<void> _checkCallEndedByDoctor() async {
    if (!mounted || _hasConcluded) return;
    try {
      final apt = await _apiService.getAppointment(widget.appointmentId);
      if (apt != null && mounted) {
        final callStatus = apt['callStatus']?.toString().toLowerCase();
        final status = apt['status']?.toString().toLowerCase();
        if (callStatus == 'completed' || status == 'completed') {
          _onDoctorConcludedCall(apt);
        }
      }
    } catch (_) {}
  }

  void _onDoctorConcludedCall(Map<String, dynamic> apt) {
    if (_hasConcluded) return;
    _hasConcluded = true;
    _streamSyncTimer?.cancel();
    _callStatusPollTimer?.cancel();

    // Mark as done in local application state
    final state = ActiveConsultationState.instance;
    state.endCall();
    state.clearQueue();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Consultation Completed',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.doctorName} has concluded your clinical tele-session. The case is officially marked as DONE.',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Patient: ${widget.animalName} • Prescription Archived',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Return to Home',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamSyncTimer?.cancel();
    _callStatusPollTimer?.cancel();
    _waveController.dispose();
    _cameraController?.dispose();
    _rtcService.leaveChannel();
    ActiveConsultationState.instance.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E293B),
            content: Text(
              'Only the attending veterinarian can conclude this clinical consultation.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: ListenableBuilder(
        listenable: _rtcService,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: SafeArea(
              child: Stack(
                children: [
                  // 1. Remote Video Area (Doctor's Live Stream)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: _doctorFrameBase64 != null && !_doctorVideoOff
                          ? Image.memory(
                              base64Decode(_doctorFrameBase64!),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (ctx, err, stack) => _buildDoctorAvatarFallback(),
                            )
                          : _buildDoctorAvatarFallback(),
                    ),
                  ),

                  // 2. Picture-in-Picture Local Camera View (Livestock Camera)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 105,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _rtcService.isVideoOff
                                ? Container(
                                    color: const Color(0xFF334155),
                                    child: const Center(
                                      child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
                                    ),
                                  )
                                : (_isCameraInitialized &&
                                        _cameraController != null &&
                                        _cameraController!.value.isInitialized)
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _cameraController!.value.previewSize?.height ?? 1,
                                          height: _cameraController!.value.previewSize?.width ?? 1,
                                          child: CameraPreview(_cameraController!),
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/animal_cow.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: const Color(0xFF1E293B),
                                          child: const Center(
                                            child: Icon(Icons.pets, color: Colors.white38),
                                          ),
                                        ),
                                      ),
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.animalName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Top Info Bar
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services_rounded, color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tele-Veterinary Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Room: ${widget.channelName}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Bottom Call Controls Bar (Farmer strictly cannot cut call)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Mute Mic
                          _controlButton(
                            icon: _rtcService.isMuted ? Icons.mic_off : Icons.mic,
                            color: _rtcService.isMuted ? Colors.redAccent : Colors.white70,
                            bgColor: _rtcService.isMuted ? Colors.red.withValues(alpha: 0.2) : Colors.white10,
                            onTap: _rtcService.toggleMute,
                          ),

                          // Toggle Video
                          _controlButton(
                            icon: _rtcService.isVideoOff ? Icons.videocam_off : Icons.videocam,
                            color: _rtcService.isVideoOff ? Colors.redAccent : Colors.white70,
                            bgColor: _rtcService.isVideoOff ? Colors.red.withValues(alpha: 0.2) : Colors.white10,
                            onTap: _rtcService.toggleVideo,
                          ),

                          // Switch Camera (Flip to show livestock animal)
                          _controlButton(
                            icon: Icons.flip_camera_ios_rounded,
                            color: Colors.white70,
                            bgColor: Colors.white10,
                            onTap: _switchCamera,
                          ),

                          // Speakerphone
                          _controlButton(
                            icon: _rtcService.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                            color: _rtcService.isSpeakerOn ? const Color(0xFF38BDF8) : Colors.white70,
                            bgColor: Colors.white10,
                            onTap: _rtcService.toggleSpeaker,
                          ),

                          // Doctor Controlled Call Badge (Strictly replacing red end-call button)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0369A1).withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_rounded, color: Color(0xFF38BDF8), size: 16),
                                SizedBox(width: 5),
                                Text(
                                  'Doctor Ends Call',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorAvatarFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final scale = _doctorMuted ? 1.0 : (1.0 + _waveController.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _doctorMuted ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_doctorMuted ? const Color(0xFFEF4444) : const Color(0xFF22C55E))
                            .withValues(alpha: 0.3),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      widget.doctorImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.doctorName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.doctorRole,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _doctorMuted ? Icons.mic_off_rounded : Icons.graphic_eq_rounded,
                  color: _doctorMuted ? const Color(0xFFEF4444) : const Color(0xFF4ADE80),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _doctorMuted ? 'Doctor Mic Muted' : 'Audio Transmitting • ${_rtcService.formattedDuration}',
                  style: TextStyle(
                    color: _doctorMuted ? const Color(0xFFEF4444) : const Color(0xFF4ADE80),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    double size = 44,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.48),
      ),
    );
  }
}
