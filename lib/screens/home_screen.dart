import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/animal_model.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../services/weather_location_service.dart';
import '../widgets/animal_thumbnail.dart';
import '../widgets/count_up_number.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/incoming_call_overlay.dart';
import 'my_animals_screen.dart';
import 'doctor_consultation_screen.dart';
import 'vaccination_screen.dart';
import 'tests_and_reports_screen.dart';
import 'profile_screen.dart';
import 'marketplace_screen.dart';
import '../services/active_consultation_state.dart';
import '../services/app_translations.dart';
import '../widgets/test_flow_tracking_modal.dart';
import 'queue_waiting_room_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen>
    with RouteAware {
  final FarmerApiService _apiService = FarmerApiService();
  final WeatherLocationService _weatherService = WeatherLocationService();

  int _selectedNavIndex = 0;
  List<AnimalModel> _animals = [];
  bool _isLoading = false;
  Timer? _incomingCallPollTimer;
  bool _isCallModalShowing = false;

  // Dynamic Dashboard Stats fetched from backend
  int get _totalAnimals => _animals.length;
  int get _appointmentsToday =>
      ActiveConsultationState.instance.realAppointmentsTodayCount;
  int _vaccinationsDue = 0;
  Map<String, dynamic> _weather = {
    'temp': '26°C',
    'condition': 'Clear Sky',
    'city': 'Pune',
    'state': 'Maharashtra',
  };

  @override
  void initState() {
    super.initState();
    _animals = FarmerApiService.getCachedAnimals();
    _loadDashboardData();
    _startIncomingCallListener();
  }

  void _startIncomingCallListener() {
    _incomingCallPollTimer?.cancel();
    _incomingCallPollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) return;

      // 1. Check incoming vet video call (Skip entirely if already in active call)
      if (!_isCallModalShowing && !ActiveConsultationState.instance.isInActiveCall) {
        try {
          final incoming = await _apiService.checkIncomingCall();
          if (incoming != null &&
              incoming['hasIncomingCall'] == true &&
              mounted &&
              !_isCallModalShowing &&
              !ActiveConsultationState.instance.isInActiveCall) {
            _isCallModalShowing = true;
            IncomingCallOverlay.show(context, incoming);
            Future.delayed(const Duration(seconds: 15), () {
              if (mounted) _isCallModalShowing = false;
            });
          }
        } catch (_) {}
      }

      // 2. Live sync active lab test status (hide if completed, update dynamically if ongoing)
      try {
        final active = await _apiService.getLatestActiveTest();
        if (!mounted) return;
        final state = ActiveConsultationState.instance;
        if (active != null) {
          final status = (active['status'] ?? '').toString().toUpperCase();
          if (status == 'REPORT_AVAILABLE' || status == 'COMPLETED') {
            // Once test is completed, top bar must not be shown
            if (state.hasTestBooking) {
              state.clearTestBooking();
              if (mounted) setState(() {});
            }
          } else {
            final isChanged = state.testStatus != status ||
                state.collectorName != active['collectorName'] ||
                state.collectionOtp != active['collectionOtp'];
            state.setTestBooking(
              testName: active['testType'] ?? 'Diagnostic Test',
              animal: active['animalType'] ?? 'Livestock',
              animalTag: active['animalTag'],
              date: active['date'] ?? 'Scheduled',
              bookingId: active['bookingId'] ?? active['id'],
              slotTime: active['slotTime'],
              status: status,
              otp: active['collectionOtp'],
              collector: active['collectorName'],
              phone: active['collectorPhone'],
            );
            if (isChanged && mounted) setState(() {});
          }
        } else {
          if (state.isTestCompleted && state.hasTestBooking) {
            state.clearTestBooking();
            if (mounted) setState(() {});
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _incomingCallPollTimer?.cancel();
    super.dispose();
  }

  // Refresh banner and stats when returning from another screen
  @override
  void didPopNext() {
    super.didPopNext();
    if (mounted) {
      setState(() {
        _animals = FarmerApiService.getCachedAnimals();
      });
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = SessionManager().currentUser;
      final summaryFuture = _apiService.getDashboardSummary();
      final animalsFuture = _apiService.getMyAnimals();
      final weatherFuture = _weatherService.getFarmerWeatherAndLocation(
        fallbackCity: user?.district ?? 'Pune',
        fallbackState: user?.state ?? 'Maharashtra',
      );

      final results = await Future.wait([summaryFuture, animalsFuture, weatherFuture]);
      final summary = results[0] as Map<String, dynamic>;
      final animals = results[1] as List<AnimalModel>;
      final weatherResult = results[2] as FarmerWeatherResult;

      if (mounted) {
        setState(() {
          _animals = animals;
          _vaccinationsDue = summary['vaccinationsDue'] ?? 0;
          _weather = weatherResult.toMap();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? (screenWidth - 560) / 2 : 16.0;

    // Retrieve live user name dynamically (Requirement 9)
    final accountHolderName = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : 'Farmer';

    final mainDashboard = SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF1B5E20),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // 1. TOP HEADER BAR: AVATAR - NAME - NOTIFICATION BELL
              // -------------------------------------------------------------
              _buildHeaderBar(user: user, accountHolderName: accountHolderName),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 2. WEATHER & LOCATION SPLIT CARD
              // -------------------------------------------------------------
              _buildWeatherLocationCard(user: user),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 3. SUMMARY COUNTER CARDS (FAST ANIMATED COUNT-UP NUMBERS)
              // -------------------------------------------------------------
              _buildStatsRow(),

              // Live consultation queue / appointment card (strictly below stats row)
              _buildConsultationBanner(),

              const SizedBox(height: 18),

              // -------------------------------------------------------------
              // 4. SERVICE NAVIGATION GRID (6 MODULES)
              // -------------------------------------------------------------
              _buildServiceGrid(),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // 5. FEATURED LIVESTOCK CAMPAIGN BANNER
              // -------------------------------------------------------------
              _buildFeaturedBanner(),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // 6. LIVESTOCK HEALTH STATUS LIST (DYNAMICALLY LOADED FROM BACKEND)
              // -------------------------------------------------------------
              _buildAnimalsListSection(),

            ],
          ),
        ),
      ),
    );

    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_selectedNavIndex != 0) {
              setState(() => _selectedNavIndex = 0);
              _loadDashboardData();
              return;
            }
            final shouldExit = await _showExitConfirmationDialog(context);
            if (shouldExit == true) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFAF8F2),
            extendBody: true, // Allows content to show behind floating navbar
            bottomNavigationBar: FloatingNavBar(
              currentIndex: _selectedNavIndex,
              onTap: (index) {
                setState(() => _selectedNavIndex = index);
                if (index == 0) {
                  _loadDashboardData();
                }
              },
            ),
            body: _selectedNavIndex == 1
                ? MyAnimalsScreen(
                    key: ValueKey('animals_${SessionManager().language}'),
                    onBackToHome: () {
                      setState(() => _selectedNavIndex = 0);
                      _loadDashboardData();
                    },
                  )
                : _selectedNavIndex == 2
                    ? MarketplaceScreen(
                        key: ValueKey('market_${SessionManager().language}'),
                        onBackToHome: () {
                          setState(() => _selectedNavIndex = 0);
                          _loadDashboardData();
                        },
                        onNavTap: (i) {
                          setState(() => _selectedNavIndex = i);
                          if (i == 0) _loadDashboardData();
                        },
                      )
                : _selectedNavIndex == 4
                    ? ProfileScreen(
                        key: ValueKey('profile_${SessionManager().language}'),
                        onBackToHome: () {
                          setState(() => _selectedNavIndex = 0);
                          _loadDashboardData();
                        },
                        onNavTap: (i) {
                          setState(() => _selectedNavIndex = i);
                          if (i == 0) _loadDashboardData();
                        },
                      )
                    : mainDashboard,
          ),
        );
      },
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

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'P';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'good_morning'.tr;
    } else if (hour >= 12 && hour < 17) {
      return 'good_afternoon'.tr;
    } else if (hour >= 17 && hour < 21) {
      return 'good_evening'.tr;
    } else {
      return 'good_night'.tr;
    }
  }

  // ---------------------------------------------------------------------------
  // LIVE CONSULTATION BANNER (queue or booked appointment)
  // ---------------------------------------------------------------------------
  Widget _buildConsultationBanner() {
    final state = ActiveConsultationState.instance;
    if (!state.hasAny) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          if (state.hasQueue) ...[
            _buildQueueBanner(state),
            if (state.hasAppointment || state.hasTestBooking)
              const SizedBox(height: 10),
          ],
          if (state.hasAppointment) ...[
            _buildAppointmentBanner(state),
            if (state.hasTestBooking) const SizedBox(height: 10),
          ],
          if (state.hasTestBooking) _buildTestBanner(state),
        ],
      ),
    );
  }

  Widget _buildQueueBanner(ActiveConsultationState state) {
    const bannerColor = Color(0xFF1B5E20);
    final myToken = state.queueToken ?? 'Q-01';
    final servingToken = state.queueServingToken ?? 'Q-01';
    final ahead = state.queuePositionAhead ?? 0;
    final estMins = state.queueEstimatedMinutes ?? (ahead * 3);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const QueueWaitingRoomScreen(isAppointment: false),
        ),
      ).then((_) => setState(() {})),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badges Row: Token + Now Serving + Estimated Time Remaining
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TOKEN: $myToken',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: bannerColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SERVING: $servingToken',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ahead == 0 ? 'YOU ARE NEXT!' : 'Turn: #$ahead ahead (~$estMins m)',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Doctor & Actions Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 46,
                    height: 46,
                    color: Colors.white.withValues(alpha: 0.12),
                    child: Image.asset(
                      state.queueDoctorImage ?? 'assets/images/doctor.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.queueDoctorName ?? 'Veterinary Officer',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.queueAnimalName ?? "Animal"}${state.queueSymptoms.isNotEmpty ? " • ${state.queueSymptoms.join(', ')}" : " • Doctor connects you"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Buttons: Waiting Room & Leave
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Waiting Room',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: bannerColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Leave Queue?'),
                            content: Text('Are you sure you want to forfeit Token $myToken and leave the queue?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Leave'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          if (state.queueAppointmentId != null) {
                            _apiService.leaveQueue(state.queueAppointmentId!);
                          }
                          state.clearQueue();
                          if (mounted) setState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Leave',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildAppointmentBanner(ActiveConsultationState state) {
    const bannerColor = Color(0xFFE65100);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const QueueWaitingRoomScreen(isAppointment: true),
        ),
      ).then((_) => setState(() {})),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badges Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.appointmentNumber != null ? 'SLIP #${state.appointmentNumber}' : 'appointment_confirmed'.tr.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${state.appointmentDate} • ${state.appointmentTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Doctor & Actions Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 46,
                    height: 46,
                    color: Colors.white.withValues(alpha: 0.12),
                    child: Image.asset(
                      state.appointmentDoctorImage ?? 'assets/images/doctor.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.appointmentDoctorName ?? 'Veterinary Specialist',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Animal: ${state.appointmentAnimal ?? "Animal"} • Tele-consultation',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'View Slip',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: bannerColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      state.clearAppointment();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appointment cancelled.'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildTestBanner(ActiveConsultationState state) {
    const bannerColor = Color(0xFF00796B);
    final rawStatus = (state.testStatus ?? 'TEST_BOOKED').toUpperCase();

    // If test is completed, top bar of lab test booked must NOT be shown!
    if (state.isTestCompleted || rawStatus == 'REPORT_AVAILABLE' || rawStatus == 'COMPLETED') {
      return const SizedBox.shrink();
    }

    String pillText = 'LAB TEST BOOKED';
    String statusDesc = 'Sample Collection Scheduled';

    if (rawStatus == 'ACCEPTED') {
      pillText = 'COLLECTOR ASSIGNED';
      statusDesc = state.collectorName != null && state.collectorName!.isNotEmpty
          ? 'Agent ${state.collectorName} assigned'
          : 'Collector assigned • En route';
    } else if (rawStatus == 'SAMPLE_COLLECTED') {
      pillText = 'SAMPLE COLLECTED';
      statusDesc = 'Sample in transit to lab';
    } else if (rawStatus == 'IN_TESTING' || rawStatus == 'TEST_IN_PROGRESS') {
      pillText = 'IN LAB TESTING';
      statusDesc = 'Pathology analysis in progress';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pillText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.testDate ?? "Scheduled"} • Doorstep Pickup',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 46,
                  height: 46,
                  color: Colors.white.withValues(alpha: 0.15),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.science_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.testName ?? 'Veterinary Lab Test',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.testAnimal ?? "Livestock"} • $statusDesc',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.collectionOtp != null && state.collectionOtp!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OTP: ${state.collectionOtp}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF92400E),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  GestureDetector(
                    onTap: () => TestFlowTrackingModal.show(
                      context,
                      bookingId: state.testBookingId,
                    ).then((_) => setState(() {})),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'View Flow',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: bannerColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      state.clearTestBooking();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test booking cancelled.'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP HEADER WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildHeaderBar({
    required dynamic user,
    required String accountHolderName,
  }) {
    final initials = _getInitials(accountHolderName);

    return Row(
      children: [
        // Profile Avatar: Shows initials of the name when no profile photo is uploaded
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFB300),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: initials.length > 1 ? 19 : 23,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1B5E20),
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Time-based Greeting & Account Holder Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTimeBasedGreeting(),
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                '$accountHolderName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Notification Bell Icon with Badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: Color(0xFFFF6D00),
                size: 26,
              ),
              Positioned(
                top: 11,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. UNIFIED WEATHER & LOCATION CARD (SINGLE BOX BACKGROUND)
  // ---------------------------------------------------------------------------
  Widget _buildWeatherLocationCard({required dynamic user}) {
    final city = _weather['city'] ?? user?.district ?? 'Pune';
    final state = _weather['state'] ?? user?.state ?? 'Maharashtra';
    final temp = _weather['temp'] ?? '26°C';
    final condition = _weather['condition'] ?? 'Clear Sky';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE0B2), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Location Pin Icon in warm rounded container
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFE65100),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // 2. Location Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$city, $state',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF263238),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  condition,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Subtle Vertical Divider
          Container(
            height: 38,
            width: 1.2,
            color: const Color(0xFFFFE0B2),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // 4. Weather Icon & Temperature
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getWeatherIcon(condition),
                color: _getWeatherIconColor(condition),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                temp,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain') || lower.contains('drizzle')) return Icons.water_drop_outlined;
    if (lower.contains('cloud')) return Icons.cloud_outlined;
    if (lower.contains('thunder')) return Icons.bolt_rounded;
    if (lower.contains('fog') || lower.contains('haze')) return Icons.blur_on_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getWeatherIconColor(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain') || lower.contains('drizzle')) return const Color(0xFF1976D2);
    if (lower.contains('cloud')) return const Color(0xFF78909C);
    if (lower.contains('thunder')) return const Color(0xFFE65100);
    return const Color(0xFFFFA000);
  }

  // ---------------------------------------------------------------------------
  // 3. FAST ANIMATED COUNT-UP NUMBER STATS ROW
  // ---------------------------------------------------------------------------
  Widget _buildStatsRow() {
    return Row(
      children: [
        // 1. My Livestock Counter
        Expanded(
          child: _buildCountCard(
            number: _totalAnimals,
            label: 'my_livestock'.tr,
            numberColor: const Color(0xFFE64A19),
            onTap: () => setState(() => _selectedNavIndex = 1),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Vaccinations Due Counter
        Expanded(
          child: _buildCountCard(
            number: _vaccinationsDue,
            label: 'vaccinations_due'.tr,
            numberColor: const Color(0xFFE64A19),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Appointments Today Counter
        Expanded(
          child: _buildCountCard(
            number: _appointmentsToday,
            label: 'appointments_today'.tr,
            numberColor: const Color(0xFFE64A19),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DoctorConsultationScreen(),
              ),
            ).then((_) => setState(() {
                  _animals = FarmerApiService.getCachedAnimals();
                })),
          ),
        ),
      ],
    );
  }

  Widget _buildCountCard({
    required int number,
    required String label,
    required Color numberColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountUpNumber(
              targetNumber: number,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: numberColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF37474F),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. SERVICE NAVIGATION GRID (6 MODULES IN A DEDICATED CARD BOX)
  // ---------------------------------------------------------------------------
  Widget _buildServiceGrid() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E7E2), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildServiceItem(
                  imageAsset: 'assets/images/btn_img_3.png',
                  fallbackIcon: Icons.pets_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  bgColor: const Color(0xFFE8F5E9),
                  title: 'my_livestock'.tr.replaceAll('\n', ' '),
                  onTap: () => setState(() => _selectedNavIndex = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildServiceItem(
                  imageAsset: 'assets/images/btn_img_1.jpeg',
                  fallbackIcon: Icons.healing_rounded,
                  iconColor: const Color(0xFFE65100),
                  bgColor: const Color(0xFFFFF3E0),
                  title: 'tests_and_reports'.tr,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TestsAndReportsScreen(),
                    ),
                  ).then((_) => setState(() {})),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildServiceItem(
                  imageAsset: 'assets/images/service_doctor.png',
                  fallbackIcon: Icons.support_agent_rounded,
                  iconColor: const Color(0xFF00695C),
                  bgColor: const Color(0xFFE0F2F1),
                  title: 'doctor_call'.tr,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorConsultationScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildServiceItem(
                  imageAsset: 'assets/images/btn_img_2.png',
                  fallbackIcon: Icons.vaccines_rounded,
                  iconColor: const Color(0xFFD84315),
                  bgColor: const Color(0xFFFBE9E7),
                  title: 'vaccination'.tr,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const VaccinationScreen(navIndex: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildServiceItem(
                  imageAsset: 'assets/images/service_market.png',
                  fallbackIcon: Icons.storefront_rounded,
                  iconColor: const Color(0xFFE65100),
                  bgColor: const Color(0xFFFFF3E0),
                  title: 'marketplace'.tr,
                  onTap: () => setState(() => _selectedNavIndex = 2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildServiceItem(
                  imageAsset: 'assets/images/service_schemes.png',
                  fallbackIcon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFFE65100),
                  bgColor: const Color(0xFFFFF3E0),
                  title: 'govt_schemes'.tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required String imageAsset,
    required IconData fallbackIcon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFECEAE0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Icon(
                    fallbackIcon,
                    size: 30,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E),
                  height: 1.18,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. FEATURED LIVESTOCK BANNER
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedBanner() {
    return Container(
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 1. Panoramic Landscape Background Asset (provided by user)
            Positioned.fill(
              child: Image.asset(
                'assets/images/banner_samruddh.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFFCC80), Color(0xFFA5D6A7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Soft readability gradient overlay on the left
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFF8E7).withValues(alpha: 0.90),
                      const Color(0xFFFFF8E7).withValues(alpha: 0.50),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.48, 0.78],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // 3. Right Image: banner_cow.png with horns & ears
            Positioned(
              right: -6,
              bottom: 0,
              top: 4,
              width: 175,
              child: Image.asset(
                'assets/images/banner_cow.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),

            // 4. Left Content: Headline + Action Pill Button
            Positioned(
              left: 18,
              top: 18,
              bottom: 16,
              right: 145,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'HEALTHY LIVESTOCK\nPROSPEROUS NATION',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A3D14),
                      height: 1.18,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Learn More',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Colors.white,
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
    );
  }

  // ---------------------------------------------------------------------------
  // 6. LIVESTOCK HEALTH STATUS LIST
  // ---------------------------------------------------------------------------
  Widget _buildAnimalsListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Registered Livestock (${_animals.length})',
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _selectedNavIndex = 1),
              icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF1B5E20)),
              label: const Text(
                'Add Animal',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            ),
          )
        else if (_animals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No livestock registered yet. Tap "Add Animal" to get started.',
                style: TextStyle(color: Colors.grey, fontSize: 13.5),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _animals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final animal = _animals[index];
              final isTreatment = animal.isUnderTreatment;

              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = 1),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isTreatment ? const Color(0xFFFFCCBC) : Colors.grey.shade200,
                      width: isTreatment ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimalThumbnail(
                        assetImage: animal.assetImage,
                        size: 64,
                        borderRadius: 16,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  animal.name,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECEFF1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    animal.tagNumber,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF455A64),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${animal.breed} (${animal.species}) • ${animal.gender} • ${animal.ageYears} yrs',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isTreatment ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                  size: 15,
                                  color: isTreatment ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isTreatment ? 'Ongoing Treatment' : 'Healthy',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isTreatment ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9E9E9E),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
