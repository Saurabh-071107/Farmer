import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pashu_farmer/models/animal_model.dart';
import 'package:pashu_farmer/services/active_consultation_state.dart';
import 'package:pashu_farmer/services/api_service.dart';
import 'package:pashu_farmer/services/app_translations.dart';
import 'package:pashu_farmer/services/session_manager.dart';
import 'package:pashu_farmer/widgets/floating_nav_bar.dart';
import '../widgets/queue_intake_sheet.dart';
import 'agora_video_call_screen.dart';
import 'queue_waiting_room_screen.dart';

class DoctorConsultationScreen extends StatefulWidget {
  final AnimalModel? animal;
  final int initialTabIndex;

  const DoctorConsultationScreen({
    super.key,
    this.animal,
    this.initialTabIndex = 0,
  });

  @override
  State<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF2E7D32);
  static const Color _orange = Color(0xFFFF6D00);
  static const Color _bg = Color(0xFFFBF9F4);

  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Appointment booking state
  int _selectedDoctorIndex = 0;
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = 0;
  int _selectedAnimalTypeIndex = 0;
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _doctors = [
    {
      'id': 'usr-vet-1',
      'name': 'Dr. Anand Sharma',
      'image': 'assets/images/doctor_1.png',
      'role': 'Veterinary Officer (B.V.Sc & A.H.)',
      'experience': '9 Years Experience',
      'rating': '4.9',
      'reviews': '180+',
      'specialization': 'Bovine Medicine & Surgery',
      'languages': 'English, Hindi, Marathi',
      'hospitalClinic': 'Rural Veterinary Dispensary, Pune Division',
      'isOnline': true,
      'waitMins': 2,
      'queueCount': 1,
    },
    {
      'id': 'usr-vet-2',
      'name': 'Dr. Priya Deshmukh',
      'image': 'assets/images/doctor_2.png',
      'role': 'Senior Veterinary Surgeon (M.V.Sc)',
      'experience': '4 Years Experience',
      'rating': '4.8',
      'reviews': '95+',
      'specialization': 'Epidemiology & Livestock Diagnostics',
      'languages': 'English, Marathi, Hindi',
      'hospitalClinic': 'District Animal PolyClinic, Baramati',
      'isOnline': true,
      'waitMins': 3,
      'queueCount': 2,
    },
    {
      'id': 'usr-vet-3',
      'name': 'Dr. Rajesh Kulkarni',
      'image': 'assets/images/doctor_1.png',
      'role': 'Chief Livestock Specialist (M.V.Sc)',
      'experience': '12 Years Experience',
      'rating': '4.9',
      'reviews': '240+',
      'specialization': 'Ruminant Health & Infectious Diseases',
      'languages': 'English, Hindi, Marathi',
      'hospitalClinic': 'Central Cattle Care Hospital, Pune',
      'isOnline': true,
      'waitMins': 1,
      'queueCount': 0,
    },
  ];

  final List<Map<String, String>> _dates = [
    {'label': 'Today', 'date': '26 Sep', 'day': 'Sat'},
    {'label': 'Tomorrow', 'date': '27 Sep', 'day': 'Sun'},
    {'label': 'Mon', 'date': '28 Sep', 'day': 'Mon'},
    {'label': 'Tue', 'date': '29 Sep', 'day': 'Tue'},
    {'label': 'Wed', 'date': '30 Sep', 'day': 'Wed'},
  ];

  final List<String> _timeSlots = [
    '09:30 AM',
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '04:00 PM',
    '05:30 PM',
  ];

  final List<String> _animalTypes = [
    'Cow',
    'Buffalo',
    'Goat',
    'Sheep',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });

    if (widget.animal != null) {
      final sp = widget.animal!.species.toLowerCase();
      if (sp.contains('buffalo')) {
        _selectedAnimalTypeIndex = 1;
      } else if (sp.contains('goat')) {
        _selectedAnimalTypeIndex = 2;
      } else if (sp.contains('sheep')) {
        _selectedAnimalTypeIndex = 3;
      } else {
        _selectedAnimalTypeIndex = 0;
      }
    }

    _fetchLiveDoctors();
  }

  Future<void> _fetchLiveDoctors() async {
    try {
      final liveVets = await FarmerApiService().getVeterinarians();
      if (liveVets.isNotEmpty && mounted) {
        setState(() {
          _doctors = liveVets.map((v) {
            final isFemale = (v['name'] ?? '').toString().toLowerCase().contains('priya');
            return {
              'id': v['id']?.toString() ?? 'usr-vet-1',
              'name': v['name']?.toString() ?? 'Veterinary Doctor',
              'image': isFemale ? 'assets/images/doctor_2.png' : 'assets/images/doctor_1.png',
              'role': v['specialization'] != null ? '${v['specialization']} Specialist' : 'Veterinary Officer',
              'experience': '${v['experienceYears'] ?? 6} Years Experience',
              'rating': '4.9',
              'reviews': '120+',
              'specialization': v['specialization'] ?? 'General Veterinary Medicine',
              'languages': 'English, Hindi, Marathi',
              'hospitalClinic': v['hospitalClinic'] ?? 'Rural Veterinary Dispensary',
              'isOnline': v['availableForCalls'] ?? true,
              'waitMins': 2,
              'queueCount': 1,
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _bg,
          extendBody: true,
          bottomNavigationBar: FloatingNavBar(
            currentIndex: 0,
            onTap: (_) => Navigator.popUntil(context, (r) => r.isFirst),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context),
                _buildTabSelector(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvailableDoctorsTab(),
                      _buildBookAppointmentTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── APP BAR ──────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: Color(0xFF1B2A1E), size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'veterinary_doctor'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2A1E),
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'tele_consult_subtitle'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          // Emergency Helpline Badge Button
          InkWell(
            onTap: _showEmergencyDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_in_talk_rounded,
                      color: Color(0xFFC62828), size: 16),
                  SizedBox(width: 4),
                  Text(
                    '1962',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP TAB SELECTOR ─────────────────────────────────────
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8DC),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              index: 0,
              icon: Icons.bolt_rounded,
              title: 'instant_call'.tr,
              subtitle: 'join_queue'.tr,
            ),
          ),
          Expanded(
            child: _tabButton(
              index: 1,
              icon: Icons.calendar_month_rounded,
              title: 'book_appointment'.tr,
              subtitle: 'schedule'.tr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _orange : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _orange.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF555555),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : const Color(0xFF424242),
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: AVAILABLE DOCTORS NOW (JOIN QUEUE / INSTANT CALL)
  // ══════════════════════════════════════════════════════════
  Widget _buildAvailableDoctorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live status banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '14 Doctors Online • Avg Wait: ~2 mins',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'free_service'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Doctor Cards
          ..._doctors.map((doc) => _buildDoctorCard(doc)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Image Container
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 84,
                      height: 94,
                      color: const Color(0xFFF1F8E9),
                      child: Image.asset(
                        doc['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.person_rounded,
                              size: 44, color: _green),
                        ),
                      ),
                    ),
                  ),
                  // Online green pulse badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFF2E7D32), size: 7),
                          SizedBox(width: 3),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Doctor Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc['name'] as String,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2A1E),
                            ),
                          ),
                        ),
                        // Online indicator pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF2E7D32), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'online'.tr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Rating and Reviews
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB300), size: 17),
                        const SizedBox(width: 3),
                        Text(
                          '${doc['rating']} (${doc['reviews']} reviews)',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${doc['experience']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Role
                    Text(
                      doc['role'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Specialization & Languages
                    Text(
                      '${doc['specialization']} • ${doc['languages']}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Join Queue button (full width)
          SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openQueueModal(doc),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'join_queue'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2: BOOK APPOINTMENT
  // ══════════════════════════════════════════════════════════
  Widget _buildBookAppointmentTab() {
    final activeState = ActiveConsultationState.instance;
    final bool hasExistingAppointment = activeState.hasAppointment;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasExistingAppointment) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFE65100), size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Active Appointment Exists',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You already have an appointment with ${activeState.appointmentDoctorName} on ${activeState.appointmentDate} at ${activeState.appointmentTime} for ${activeState.appointmentAnimal}.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Consecutive bookings are not allowed. Please cancel or finish your active appointment first.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          activeState.clearAppointment();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Previous appointment cancelled. You may now book a new slot.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: Color(0xFFC62828)),
                      label: const Text(
                        'Cancel Active Appointment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC62828),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF9A9A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Section 1: Choose Doctor
          _sectionHeader('select_doctor'.tr),
          const SizedBox(height: 6),
          _buildDoctorSelectorHorizontal(),

          const SizedBox(height: 14),

          // Section 2: Choose Date
          _sectionHeader('select_date'.tr),
          const SizedBox(height: 6),
          _buildDateSelector(),

          const SizedBox(height: 14),

          // Section 3: Choose Time Slot
          _sectionHeader('select_time'.tr),
          const SizedBox(height: 6),
          _buildTimeSlotGrid(),

          const SizedBox(height: 14),

          // Section 4: Animal & Issue Note
          _sectionHeader('select_animal'.tr),
          const SizedBox(height: 6),
          _buildAnimalTypeSelector(),

          const SizedBox(height: 12),

          // Optional symptom notes field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'symptoms_problem'.tr,
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9E9E9E)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Big Confirm Appointment Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _confirmAppointment,
              icon: Icon(
                hasExistingAppointment
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              label: Text(
                hasExistingAppointment
                    ? 'Consecutive Booking Blocked'
                    : 'confirm_booking'.tr,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasExistingAppointment ? const Color(0xFF9E9E9E) : _orange,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1B2A1E),
      ),
    );
  }

  Widget _buildDoctorSelectorHorizontal() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _doctors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final doc = _doctors[index];
          final isSelected = _selectedDoctorIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDoctorIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 190,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? _orange : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      doc['image'] as String,
                      width: 50,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 60,
                        color: const Color(0xFFE8F5E9),
                        child: const Icon(Icons.person, color: _green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          doc['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? _orange : const Color(0xFF1B2A1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doc['role'] as String,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFB300), size: 14),
                            Text(
                              ' ${doc['rating']}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildDateSelector() {
    return Row(
      children: List.generate(_dates.length, (index) {
        final d = _dates[index];
        final isSelected = _selectedDateIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDateIndex = index),
            child: Container(
              margin: EdgeInsets.only(right: index == _dates.length - 1 ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _orange : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _orange : Colors.grey.shade300,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    d['label']!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d['date']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : _green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeSlotGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _timeSlotChip(0)),
            const SizedBox(width: 8),
            Expanded(child: _timeSlotChip(1)),
            const SizedBox(width: 8),
            Expanded(child: _timeSlotChip(2)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _timeSlotChip(3)),
            const SizedBox(width: 8),
            Expanded(child: _timeSlotChip(4)),
            const SizedBox(width: 8),
            Expanded(child: _timeSlotChip(5)),
          ],
        ),
      ],
    );
  }

  Widget _timeSlotChip(int index) {
    final slot = _timeSlots[index];
    final isSelected = _selectedTimeIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTimeIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _green : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          slot,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF263238),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_animalTypes.length, (index) {
        final type = _animalTypes[index];
        final isSelected = _selectedAnimalTypeIndex == index;
        return InkWell(
          onTap: () => setState(() => _selectedAnimalTypeIndex = index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _green : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.pets_outlined,
                  size: 15,
                  color: isSelected ? _green : Colors.grey.shade600,
                ),
                const SizedBox(width: 5),
                Text(
                  type == 'Cow'
                      ? 'cat_cow'.tr
                      : type == 'Buffalo'
                          ? 'cat_buffalo'.tr
                          : type == 'Goat'
                              ? 'cat_goat'.tr
                              : type,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? _green : const Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }


  void _openQueueModal(Map<String, dynamic> doc) async {
    final active = ActiveConsultationState.instance;

    // 1. Single-Queue Check (User Rule: Cannot join queue of other doctor if already in queue)
    if (active.hasQueue) {
      final currentDoc = active.queueDoctorName ?? 'a veterinarian';
      final currentToken = active.queueToken ?? 'Q-01';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.block_rounded, color: Colors.red, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Already in Queue',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'You are already in $currentDoc\'s queue with Token $currentToken. You cannot join multiple doctor queues simultaneously.\n\nPlease leave your current queue or return to your waiting room.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (active.queueAppointmentId != null) {
                  await FarmerApiService().leaveQueue(active.queueAppointmentId!);
                }
                active.clearQueue();
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Left previous queue. You may now join.')),
                  );
                }
              },
              child: const Text('Leave Current Queue', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QueueWaitingRoomScreen(isAppointment: false),
                  ),
                );
              },
              child: const Text('Go to Waiting Room', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Pre-queue clinical intake sheet: Symptoms, Description & mandatory/optional photos
    final intakeData = await showQueueIntakeBottomSheet(
      context,
      doctor: doc,
      preselectedAnimal: widget.animal,
    );

    if (intakeData == null || !mounted) return;

    // 3. Register queue in backend & obtain official sequential token
    try {
      final docId = doc['id']?.toString() ?? 'usr-vet-1';
      final docName = doc['name']?.toString() ?? 'Dr. Anand Sharma';
      final docImage = doc['image']?.toString() ?? 'assets/images/doctor_1.png';

      final res = await FarmerApiService().joinQueueCall(
        doctorId: docId,
        doctorName: docName,
        doctorImage: docImage,
        animalName: intakeData.animal.name,
        animalId: intakeData.animal.id,
        animalTag: intakeData.animal.tagNumber,
        species: intakeData.animal.species,
        symptoms: intakeData.symptoms,
        description: intakeData.description,
        photoUrls: intakeData.photoPaths,
        expectedTime: '~1-3 mins',
      );

      final apt = res['appointment'] is Map<String, dynamic> ? res['appointment'] as Map<String, dynamic> : res;
      final assignedToken = apt['queueToken']?.toString() ?? res['queueToken']?.toString() ?? 'Q-01';
      final servingToken = res['servingToken']?.toString() ?? 'Q-01';
      final posAhead = (res['positionAhead'] as num?)?.toInt() ?? 0;
      final estWait = (res['estimatedMinutes'] as num?)?.toInt() ?? 3;
      final aptId = apt['id']?.toString() ?? res['id']?.toString();

      active.setQueue(
        appointmentId: aptId,
        doctorId: docId,
        doctorName: docName,
        doctorImage: docImage,
        doctorSpecialization: doc['specialization']?.toString() ?? 'Bovine Medicine',
        doctorClinic: doc['hospitalClinic']?.toString() ?? 'Rural Dispensary',
        queueToken: assignedToken,
        servingToken: servingToken,
        position: posAhead + 1,
        positionAhead: posAhead,
        estimatedMinutes: estWait,
        animalName: intakeData.animal.name,
        animalTag: intakeData.animal.tagNumber,
        species: intakeData.animal.species,
        symptoms: intakeData.symptoms,
        description: intakeData.description,
        photos: intakeData.photoPaths,
      );

      if (!mounted) return;

      // 4. Navigate directly to Waiting Room (Farmer cannot start call, only doctor initiates)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const QueueWaitingRoomScreen(isAppointment: false),
        ),
      ).then((_) => setState(() {}));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _confirmAppointment() {
    if (ActiveConsultationState.instance.hasAppointment) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
              SizedBox(width: 8),
              Text(
                'Active Appointment Exists',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Text(
            'You already have an active appointment booked with ${ActiveConsultationState.instance.appointmentDoctorName} on ${ActiveConsultationState.instance.appointmentDate} at ${ActiveConsultationState.instance.appointmentTime}.\n\nConsecutive bookings are not allowed. Please cancel or complete your current appointment first.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  ActiveConsultationState.instance.clearAppointment();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Previous appointment cancelled. You can now book.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
              ),
              child: const Text(
                'Cancel Old & Rebook',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final selectedDoc = _doctors[_selectedDoctorIndex];
    final selectedDate = _dates[_selectedDateIndex];
    final selectedTime = _timeSlots[_selectedTimeIndex];
    final selectedAnimal = _animalTypes[_selectedAnimalTypeIndex];

    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _green, size: 48),
            ),
            const SizedBox(height: 14),
            Text(
              'appointment_confirmed'.tr,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Your tele-veterinary consultation is successfully scheduled.',
              style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _dialogRow(Icons.person_rounded, 'Doctor',
                      selectedDoc['name'] as String),
                  const Divider(height: 16),
                  _dialogRow(Icons.calendar_today_rounded, 'Date & Day',
                      '${selectedDate['label']} (${selectedDate['date']})'),
                  const Divider(height: 16),
                  _dialogRow(Icons.access_time_rounded, 'Time Slot', selectedTime),
                  const Divider(height: 16),
                  _dialogRow(Icons.pets_rounded, 'Animal', selectedAnimal),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final appointmentSlipNum = 'APT-${DateTime.now().year}-${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
                  
                  ActiveConsultationState.instance.setAppointment(
                    doctorName: selectedDoc['name'] as String,
                    doctorImage: selectedDoc['image'] as String,
                    doctorId: selectedDoc['id']?.toString() ?? 'usr-vet-1',
                    doctorSpecialization: selectedDoc['specialization'] as String?,
                    date: '${selectedDate['label']} (${selectedDate['date']})',
                    time: selectedTime,
                    animal: selectedAnimal,
                    appointmentNumber: appointmentSlipNum,
                    appointmentStatus: 'scheduled',
                    notes: _notesController.text.trim(),
                  );
                  
                  // Asynchronously persist to backend database
                  FarmerApiService().bookAppointment(
                    vetId: selectedDoc['id']?.toString() ?? 'usr-vet-1',
                    animalId: widget.animal?.id ?? selectedAnimal,
                    notes: _notesController.text.trim().isNotEmpty
                        ? _notesController.text.trim()
                        : 'Scheduled consult for $selectedAnimal on ${selectedDate['label']} at $selectedTime',
                    type: 'video_call',
                  );

                  Navigator.pop(diagContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Appointment $appointmentSlipNum scheduled with ${selectedDoc['name']}. Time: $selectedTime',
                      ),
                      backgroundColor: _green,
                    ),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QueueWaitingRoomScreen(isAppointment: true),
                    ),
                  ).then((_) => setState(() {}));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Open Waiting Room & Slip',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _orange),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E))),
      ],
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828)),
            SizedBox(width: 8),
            Text('Emergency Helpline 1962',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFC62828))),
          ],
        ),
        content: const Text(
          'You can call the toll-free number 1962 for 24/7 livestock ambulance and urgent veterinary emergency support.\n\nDo you want to initiate the call now?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connecting to 1962 emergency helpline...'),
                  backgroundColor: Color(0xFFC62828),
                ),
              );
            },
            icon: const Icon(Icons.call, color: Colors.white, size: 18),
            label: const Text('Call 1962',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// QUEUE MODAL CONTENT WITH LIVE STATUS
// ══════════════════════════════════════════════════════════════
class _QueueSheetContent extends StatefulWidget {
  final Map<String, dynamic> doc;
  final String animalName;
  final String? animalId = null;
  final String? species = null;
  final List<String> symptoms = const [];
  final String description = '';
  final List<String> photos = const [];

  const _QueueSheetContent({
    required this.doc,
    required this.animalName,
  });

  @override
  State<_QueueSheetContent> createState() => _QueueSheetContentState();
}

class _QueueSheetContentState extends State<_QueueSheetContent> {
  int _secondsLeft = 8;
  final int _queuePos = 1;
  int _leaveCooldown = 5;
  Timer? _timer;
  String? _queueAppointmentId;
  String? _queueChannelName;
  String? _queueCaseNumber;
  bool _isDisposed = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    ActiveConsultationState.instance.setQueue(
      doctorName: widget.doc['name'] as String,
      doctorImage: widget.doc['image'] as String,
      position: _queuePos,
      animalName: widget.animalName,
      expectedTime: '~1-2 mins',
      symptoms: widget.symptoms,
      description: widget.description,
      photos: widget.photos,
    );

    // Register queue in backend
    FarmerApiService().joinQueueCall(
      doctorId: widget.doc['id']?.toString() ?? 'usr-vet-1',
      doctorName: widget.doc['name']?.toString() ?? 'Dr. Anand Sharma',
      doctorImage: widget.doc['image']?.toString() ?? 'assets/images/doctor_1.png',
      animalName: widget.animalName,
      animalId: widget.animalId,
      species: widget.species,
      symptoms: widget.symptoms,
      description: widget.description,
      photoUrls: widget.photos,
      expectedTime: '~1-2 mins',
    ).then((res) {
      if (mounted && !_isDisposed) {
        final aptId = (res['id'] ?? res['appointmentId'])?.toString();
        final token = (res['queueToken'] ?? res['tokenNumber'] ?? res['token'])?.toString();
        setState(() {
          _queueAppointmentId = aptId;
          _queueChannelName = res['agoraChannel'] ?? res['callRoomId'] ?? 'agora-$aptId';
          _queueCaseNumber = res['caseNumber'] ?? res['caseId'] ?? 'CASE-2026-000101';
        });
        if (aptId != null) ActiveConsultationState.instance.queueAppointmentId = aptId;
        if (token != null) ActiveConsultationState.instance.queueToken = token;
      }
    }).catchError((_) {});

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _isDisposed || _isConnecting) {
        t.cancel();
        return;
      }

      // Check if doctor activated the call from Vet app
      try {
        final incoming = await FarmerApiService().checkIncomingCall(appointmentId: _queueAppointmentId);
        if (!mounted || _isDisposed || _isConnecting) {
          t.cancel();
          return;
        }
        if (incoming != null && incoming['hasIncomingCall'] == true) {
          t.cancel();
          _connectToAgora(incoming['agoraChannel'] ?? _queueChannelName ?? 'agora-queue');
          return;
        }
      } catch (_) {}

      if (!mounted || _isDisposed || _isConnecting) {
        t.cancel();
        return;
      }

      setState(() {
        if (_leaveCooldown > 0) _leaveCooldown--;
        if (_secondsLeft <= 1) {
          _secondsLeft = 0;
          t.cancel();
          _connectToAgora(_queueChannelName ?? 'agora-live-queue');
        } else {
          _secondsLeft--;
        }
      });
    });
  }

  void _connectToAgora(String channelName) {
    if (_isConnecting || !mounted || _isDisposed) return;
    _isConnecting = true;
    _timer?.cancel();
    _timer = null;

    final aptId = _queueAppointmentId ?? 'queue-apt-1';
    final doc = widget.doc;
    final animal = widget.animalName;

    Navigator.pop(context); // close queue sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgoraVideoCallScreen(
          appointmentId: aptId,
          channelName: channelName,
          doctorName: doc['name'] as String,
          doctorRole: doc['role'] as String? ?? 'Veterinary Officer',
          doctorImage: doc['image'] as String? ?? 'assets/images/doctor_1.png',
          animalName: animal,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  widget.doc['image'] as String,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doc['name'] as String,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    Text(
                      'Govt. Tele-Veterinary Officer',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Queue Badge Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6D00),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _queuePos == 1
                            ? 'You are Next! Doctor Connecting...'
                            : 'Queue Position: #$_queuePos',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const CircularProgressIndicator(
                  color: Color(0xFFFF6D00),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 12),
                Text(
                  _queuePos == 1
                      ? 'Doctor is now connecting to your call...'
                      : 'Estimated wait time: ~00:${_secondsLeft.toString().padLeft(2, '0')} mins',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B2A1E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Animal: ${widget.animalName}${widget.species != null ? " (${widget.species})" : ""}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B2A1E),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
                  ),
                  child: Text(
                    'Case ID: ${_queueCaseNumber ?? "CASE-2026-000101"}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
                if (widget.symptoms.isNotEmpty) ...[

                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 5,
                    runSpacing: 5,
                    children: widget.symptoms.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                if (widget.photos.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_camera_rounded, size: 14, color: Color(0xFFFF6D00)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.photos.length} photo(s) submitted for triage',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6D00),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: const Text(
                    'Direct Triage Channel Active • Auto-joining room or tap Connect Now',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF795548),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Primary Action: Connect Video Call Now
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                _connectToAgora(_queueChannelName ?? 'agora-live-queue');
              },
              icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
              label: Text(
                _secondsLeft > 0
                    ? 'Connect Video Call Now (${_secondsLeft}s)'
                    : 'Connecting to Doctor...',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary Actions
          Row(
            children: [
              // Leave Queue button with 5s countdown
              Expanded(
                child: OutlinedButton(
                  onPressed: _leaveCooldown > 0
                      ? null
                      : () {
                          ActiveConsultationState.instance.clearQueue();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You have left the queue.'),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(
                      color: _leaveCooldown > 0
                          ? Colors.grey.shade300
                          : const Color(0xFFC62828),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _leaveCooldown > 0
                        ? 'Leave Queue (${_leaveCooldown}s)'
                        : 'Leave Queue',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _leaveCooldown > 0
                          ? Colors.grey.shade400
                          : const Color(0xFFC62828),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Wait in Background / Home Screen button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Queue active! Position #$_queuePos & expected time shown on home screen.',
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    );
                  },
                  icon: const Icon(Icons.home_outlined,
                      color: Colors.white, size: 19),
                  label: Text(
                    'keep_active'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ACTIVE CALL SIMULATION DIALOG
// ══════════════════════════════════════════════════════════════
class _ActiveCallDialog extends StatefulWidget {
  final Map<String, dynamic> doc;
  final bool isVideo;

  const _ActiveCallDialog({
    required this.doc,
    required this.isVideo,
  });

  @override
  State<_ActiveCallDialog> createState() => _ActiveCallDialogState();
}

class _ActiveCallDialogState extends State<_ActiveCallDialog> {
  int _callSeconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isCamOff = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeDisplay {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: const Color(0xFF1E2822),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 8),
                      const SizedBox(width: 5),
                      Text(
                        _timeDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.isVideo ? 'Video Call' : 'Audio Call',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Doctor Big Avatar / Video View
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      widget.doc['image'] as String,
                      width: 140,
                      height: 155,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 140,
                        height: 155,
                        color: Colors.white12,
                        child: const Icon(Icons.person,
                            size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.doc['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Call in Progress • Veterinary Consultation',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // In-Call Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute
                IconButton.filledTonal(
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  style: IconButton.styleFrom(
                    backgroundColor: _isMuted ? Colors.red : Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                  ),
                ),

                // End Call
                IconButton.filled(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.call_end_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(18),
                  ),
                ),

                // Video toggle
                if (widget.isVideo)
                  IconButton.filledTonal(
                    onPressed: () => setState(() => _isCamOff = !_isCamOff),
                    icon: Icon(_isCamOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: _isCamOff ? Colors.red : Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
