import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VaccinationFlowTrackingModal extends StatefulWidget {
  final String? initialBookingId;

  const VaccinationFlowTrackingModal({super.key, this.initialBookingId});

  static Future<void> show(BuildContext context, {String? bookingId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VaccinationFlowTrackingModal(initialBookingId: bookingId),
    );
  }

  @override
  State<VaccinationFlowTrackingModal> createState() => _VaccinationFlowTrackingModalState();
}

class _VaccinationFlowTrackingModalState extends State<VaccinationFlowTrackingModal> {
  static const Color _green = Color(0xFF1B5E20);
  static const Color _teal = Color(0xFF00796B);

  Timer? _pollTimer;
  Map<String, dynamic>? _liveBookingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchLiveStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveStatus() async {
    final bId = widget.initialBookingId ?? _liveBookingData?['bookingId'] ?? _liveBookingData?['id'];

    if (bId != null && bId.isNotEmpty) {
      try {
        final res = await FarmerApiService().getVaccinationBookingStatus(bId);
        if (res['success'] == true && mounted) {
          setState(() {
            _liveBookingData = res['booking'];
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    try {
      final active = await FarmerApiService().getActiveVaccinationBooking();
      if (active['hasActiveBooking'] == true && mounted) {
        setState(() {
          _liveBookingData = active['booking'];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getCurrentStep(String? status) {
    if (status == null) return 0;
    final s = status.toUpperCase();
    if (s == 'COMPLETED' || s == 'ADMINISTERED') return 3;
    if (s == 'OUT_FOR_VACCINATION') return 2;
    if (s == 'ACCEPTED' || s == 'DISPATCHED') return 1;
    return 0; // CONFIRMED or REQUESTED
  }

  @override
  Widget build(BuildContext context) {
    final status = _liveBookingData?['status']?.toString() ?? 'CONFIRMED';
    final currentStep = _getCurrentStep(status);
    final isDone = currentStep == 3;
    final otp = _liveBookingData?['verificationOtp']?.toString() ?? '----';
    final paravetName = _liveBookingData?['assignedVaccinatorName']?.toString();
    final paravetPhone = _liveBookingData?['assignedVaccinatorPhone']?.toString();
    final certId = _liveBookingData?['certificateId']?.toString();
    final animalName = _liveBookingData?['animalName']?.toString() ?? 'Livestock';
    final animalTag = _liveBookingData?['animalTag']?.toString() ?? '';
    final vaccineName = _liveBookingData?['vaccineName']?.toString() ?? 'Vaccine';
    final bookingId = _liveBookingData?['bookingId']?.toString() ?? _liveBookingData?['id']?.toString() ?? 'VB-2026';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFE8F5E9) : const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDone ? Icons.verified : Icons.vaccines,
                    color: isDone ? _green : _teal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Animal: $animalName ($animalTag) • ID: $bookingId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _green),
                ),
              )
            else ...[
              // Stepper
              _buildFlowStepper(currentStep),
              const SizedBox(height: 20),

              // Doorstep OTP Card (Shown while awaiting or during administration)
              if (!isDone && otp != '----')
                _buildGoldenOtpCard(otp),

              // Paravet Contact Card if Assigned
              if (paravetName != null && paravetName.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildParavetCard(paravetName, paravetPhone),
              ],

              // Certificate Card if Done
              if (isDone && certId != null && certId.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCertificateCard(certId, animalName, vaccineName),
              ],

              const SizedBox(height: 20),

              // Auto-refresh reminder
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live sync with laboratory dispatch & paravet',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStepper(int currentStep) {
    final steps = [
      {'title': 'Slot Booked', 'desc': 'Doorstep request logged'},
      {'title': 'Accepted', 'desc': 'Field paravet allocated'},
      {'title': 'En Route / Admin', 'desc': 'Doorstep OTP verification'},
      {'title': 'Certified', 'desc': 'NADCP Certificate issued'},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final isPast = index < currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        Color dotColor;
        if (isPast || isCurrent) {
          dotColor = currentStep == 3 ? _green : _teal;
        } else {
          dotColor = Colors.grey.shade300;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: (isPast || isCurrent) ? dotColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: Center(
                    child: isPast
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : (isCurrent
                            ? const Icon(Icons.circle, size: 10, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                ),
                              )),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: isPast ? dotColor : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index]['title']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent ? const Color(0xFF0F172A) : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      steps[index]['desc']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrent ? dotColor : Colors.grey.shade500,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildGoldenOtpCard(String otp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.key, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Doorstep Verification OTP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SHOW TO PARAVET',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFBBF24)),
            ),
            child: Text(
              otp,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: Color(0xFF78350F),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Give this 4-digit OTP to the visiting paravet upon arrival to confirm vaccination administration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParavetCard(String name, String? phone) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFDBEAFE),
            foregroundColor: const Color(0xFF1D4ED8),
            child: const Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Assigned Field Paravet • Cold Chain Monitored',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone, color: Color(0xFF2563eb)),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(String certId, String animalName, String vaccineName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: _green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Digital Vaccination Certificate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Certificate Number: $certId',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF047857),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Official biological proof of $vaccineName dose for $animalName recorded in Government Animal Health Registry.',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }
}
