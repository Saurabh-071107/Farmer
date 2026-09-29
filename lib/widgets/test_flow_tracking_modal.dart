import 'dart:async';
import 'package:flutter/material.dart';
import '../services/active_consultation_state.dart';
import '../services/api_service.dart';
import '../screens/report_detail_screen.dart';

class TestFlowTrackingModal extends StatefulWidget {
  final String? initialBookingId;

  const TestFlowTrackingModal({super.key, this.initialBookingId});

  static Future<void> show(BuildContext context, {String? bookingId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TestFlowTrackingModal(initialBookingId: bookingId),
    );
  }

  @override
  State<TestFlowTrackingModal> createState() => _TestFlowTrackingModalState();
}

class _TestFlowTrackingModalState extends State<TestFlowTrackingModal> {
  static const Color _teal = Color(0xFF00796B);
  static const Color _orange = Color(0xFFFF6D00);
  static const Color _green = Color(0xFF2E7D32);

  Timer? _pollTimer;

  Map<String, dynamic>? _liveBookingData;

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
    final state = ActiveConsultationState.instance;
    final bId = widget.initialBookingId ?? state.testBookingId;

    if (bId != null && bId.isNotEmpty) {
      try {
        final data = await FarmerApiService().getTestBookingStatus(bId);
        if (data != null && mounted) {
          setState(() {
            _liveBookingData = data;
          });
          // Update singleton active state
          state.updateTestStatus(
            status: data['status']?.toString(),
            collector: data['collectorName']?.toString(),
            phone: data['collectorPhone']?.toString(),
            otp: data['collectionOtp']?.toString(),
            reportId: data['reportId']?.toString(),
            reportSummary: data['report']?['resultSummary']?.toString(),
            isAbnormal: data['report']?['isAbnormal'] == true,
          );
        }
      } catch (_) {}
    } else {
      // Try fetching active test for farmer
      try {
        final active = await FarmerApiService().getLatestActiveTest();
        if (active != null && mounted) {
          setState(() {
            _liveBookingData = active;
          });
          state.setTestBooking(
            testName: active['testType'] ?? 'Diagnostic Test',
            animal: active['animalType'] ?? 'Livestock',
            date: active['date'] ?? active['slotDate'] ?? 'Scheduled',
            bookingId: active['bookingId'] ?? active['id'],
            animalTag: active['animalTag'],
            slotTime: active['slotTime'],
            status: active['status'],
            otp: active['collectionOtp'],
            collector: active['collectorName'],
            phone: active['collectorPhone'],
            reportId: active['reportId'],
            reportSummary: active['report']?['resultSummary'],
            isAbnormal: active['report']?['isAbnormal'] == true,
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ActiveConsultationState.instance;
    final data = _liveBookingData;

    final bookingId = data?['bookingId'] ?? data?['id'] ?? state.testBookingId ?? 'TB-2026-ACTIVE';
    final testName = data?['testType'] ?? state.testName ?? 'Diagnostic Test';
    final animalName = state.testAnimal ?? data?['animalType'] ?? 'Livestock';
    final animalTag = data?['animalTag'] ?? state.testAnimalTag ?? '';
    final slotTime = data?['slotTime'] ?? state.testSlotTime ?? '10:00 AM - 11:00 AM';
    final slotDate = data?['date'] ?? data?['slotDate'] ?? state.testDate ?? 'Scheduled';
    final status = (data?['status'] ?? state.testStatus ?? 'TEST_BOOKED').toString().toUpperCase();
    final collectorName = data?['collectorName'] ?? state.collectorName ?? '';
    final collectorPhone = data?['collectorPhone'] ?? state.collectorPhone ?? '';
    final otp = data?['collectionOtp'] ?? state.collectionOtp ?? '----';

    final isAccepted = status == 'ACCEPTED' ||
        status == 'SAMPLE_COLLECTED' ||
        status == 'IN_TESTING' ||
        status == 'TEST_IN_PROGRESS' ||
        status == 'REPORT_AVAILABLE' ||
        status == 'COMPLETED';

    final isCollected = status == 'SAMPLE_COLLECTED' ||
        status == 'IN_TESTING' ||
        status == 'TEST_IN_PROGRESS' ||
        status == 'REPORT_AVAILABLE' ||
        status == 'COMPLETED';

    final isTesting = status == 'IN_TESTING' ||
        status == 'TEST_IN_PROGRESS' ||
        status == 'REPORT_AVAILABLE' ||
        status == 'COMPLETED';

    final isCompleted = status == 'REPORT_AVAILABLE' || status == 'COMPLETED';

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnostic Test Flow',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tracking: $bookingId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _teal,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animal & Test Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FBF7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.science_rounded, color: _teal, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B2A1E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$animalName ${animalTag.isNotEmpty ? "($animalTag)" : ""} • $slotDate, $slotTime',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
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

                  // ─── OTP Banner (Show prominent OTP if accepted and not yet collected) ───
                  if (status == 'ACCEPTED' || status == 'TEST_BOOKED')
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFF8E1),
                            const Color(0xFFFFECB3).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _orange.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.key_rounded, color: _orange, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'SAMPLE COLLECTION OTP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFBF360C),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
                            ),
                            child: Text(
                              otp.isNotEmpty ? otp : '----',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                color: Color(0xFFBF360C),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            collectorName.isNotEmpty
                                ? 'Share this OTP with sample collector ($collectorName) upon specimen pickup.'
                                : 'Share this 4-digit OTP with your field collector to verify sample collection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.brown.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'PROGRESS TIMELINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // STEP 1: Slot Booked
                  _buildTimelineStep(
                    icon: Icons.check_circle_rounded,
                    iconColor: _green,
                    lineColor: isAccepted ? _green : Colors.grey.shade300,
                    title: '1. Test Slot Booked',
                    subtitle: 'Slot confirmed: $slotDate ($slotTime)',
                    isDone: true,
                    isActive: status == 'TEST_BOOKED',
                  ),

                  // STEP 2: Accepted & Collector Assigned
                  _buildTimelineStep(
                    icon: isAccepted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    iconColor: isAccepted ? _green : Colors.grey.shade400,
                    lineColor: isCollected ? _green : Colors.grey.shade300,
                    title: '2. Accepted by Laboratory',
                    subtitle: collectorName.isNotEmpty
                        ? 'Field Collector: $collectorName${collectorPhone.isNotEmpty ? " • $collectorPhone" : ""}'
                        : (status == 'TEST_BOOKED'
                            ? 'Awaiting technician acceptance & assignment...'
                            : 'Collector assigned.'),
                    isDone: isAccepted,
                    isActive: status == 'ACCEPTED',
                    extraWidget: isAccepted && collectorName.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_pin_rounded, color: _green, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Collector: $collectorName',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: _green,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),

                  // STEP 3: Sample Collection (OTP verified)
                  _buildTimelineStep(
                    icon: isCollected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    iconColor: isCollected ? _green : (status == 'ACCEPTED' ? _orange : Colors.grey.shade400),
                    lineColor: isTesting ? _green : Colors.grey.shade300,
                    title: '3. Sample Collected',
                    subtitle: isCollected
                        ? 'Specimen collected & authenticated via OTP.'
                        : (status == 'ACCEPTED'
                            ? 'Collector on the way. Provide OTP upon arrival.'
                            : 'Scheduled for doorstep collection.'),
                    isDone: isCollected,
                    isActive: status == 'SAMPLE_COLLECTED' || status == 'ACCEPTED',
                  ),

                  // STEP 4: Testing in Laboratory
                  _buildTimelineStep(
                    icon: isTesting ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    iconColor: isTesting ? _green : (status == 'SAMPLE_COLLECTED' ? _teal : Colors.grey.shade400),
                    lineColor: isCompleted ? _green : Colors.grey.shade300,
                    title: '4. Testing in Diagnostic Lab',
                    subtitle: isCompleted
                        ? 'Pathology assay finished.'
                        : (isTesting
                            ? 'Specimen under biochemical examination at state lab.'
                            : 'Awaiting specimen arrival at lab.'),
                    isDone: isCompleted,
                    isActive: status == 'IN_TESTING' || status == 'TEST_IN_PROGRESS',
                  ),

                  // STEP 5: Report Available
                  _buildTimelineStep(
                    icon: isCompleted ? Icons.verified_rounded : Icons.radio_button_unchecked,
                    iconColor: isCompleted ? _green : Colors.grey.shade400,
                    lineColor: null, // Last step
                    title: '5. Pathology Report Ready',
                    subtitle: isCompleted
                        ? 'Certified report issued and available for viewing.'
                        : 'Official report will be uploaded upon test completion.',
                    isDone: isCompleted,
                    isActive: isCompleted,
                    extraWidget: isCompleted
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                final report = data?['report'] as Map<String, dynamic>? ?? {};
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportDetailScreen(
                                      report: DiagnosticReportModel.fromCaseData({
                                        'animalName': animalName,
                                        'animalType': animalTag,
                                        'testName': testName,
                                        'date': 'Tested on $slotDate',
                                        'status': report['isAbnormal'] == true ? 'Abnormal Findings' : 'Normal',
                                        'statusColor': report['isAbnormal'] == true ? Colors.red : _green,
                                        'vetNotes': report['observations'] ?? report['resultSummary'],
                                        'parameters': report['parameters'],
                                        'testResult': report['testResult'],
                                      }),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
                              label: const Text('View Certified Report', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color iconColor,
    required Color? lineColor,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    Widget? extraWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left icon + vertical line
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone ? iconColor.withValues(alpha: 0.15) : (isActive ? Colors.amber.shade50 : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            if (lineColor != null)
              Container(
                width: 2.5,
                height: extraWidget != null ? 70 : 44,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isDone || isActive ? FontWeight.w900 : FontWeight.w700,
                    color: isDone || isActive ? const Color(0xFF1B2A1E) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ?extraWidget,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
