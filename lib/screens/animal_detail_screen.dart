import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/api_service.dart';
import '../services/app_translations.dart';
import '../services/session_manager.dart';
import '../widgets/animal_thumbnail.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/animal_form_bottom_sheet.dart';
import 'health_analyze_screen.dart';
import 'doctor_consultation_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final AnimalModel animal;
  final int initialNavIndex;
  final ValueChanged<int>? onNavTap;

  const AnimalDetailScreen({
    super.key,
    required this.animal,
    this.initialNavIndex = 1,
    this.onNavTap,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _navIndex = 1;
  late AnimalModel _currentAnimal;

  // ─────────────────────────────────────────────────────────
  static const _bg = Color(0xFFFCFAF5);
  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentAnimal = widget.animal;
    _navIndex = widget.initialNavIndex;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Doctor Consultation ────────────────────────────────
  void _connectDoctor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorConsultationScreen(animal: _currentAnimal),
      ),
    );
  }

  void _openEditAnimalModal() {
    showAnimalFormBottomSheet(
      context,
      animalToEdit: _currentAnimal,
      onSaved: (updated) {
        setState(() => _currentAnimal = updated);
      },
    );
  }

  void _confirmDeleteAnimal() async {
    final deleted = await showDeleteAnimalDialog(context, _currentAnimal);
    if (deleted && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _bookVaccinationSlot() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: _bg,
        content: Row(
          children: [
            CircularProgressIndicator(color: _green),
            SizedBox(width: 16),
            Text('Booking vaccination slot...'),
          ],
        ),
      ),
    );

    try {
      final result = await FarmerApiService().bookAppointment(
        animalId: _currentAnimal.id,
        notes: 'Vaccination request for ${_currentAnimal.name} (${_currentAnimal.species})',
      );
      if (!mounted) return;
      Navigator.pop(context); // close loader
      _showAppointmentConfirmation(
        result,
        title: 'Vaccination Slot Booked',
        subtitle: 'Vaccination appointment confirmed for ${widget.animal.name}.',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showAppointmentConfirmation(
    Map<String, dynamic> result, {
    String title = 'Appointment Confirmed',
    String subtitle = 'Your appointment has been scheduled.',
  }) {
    final apt = result['appointment'] as Map<String, dynamic>? ?? result;
    final vetName = apt['vetName'] ?? 'Dr. Anand Sharma';
    final timeStr = apt['appointmentTimeFormatted'] ?? 'Soon';
    final clinic = apt['hospitalClinic'] ?? 'Veterinary Dispensary';
    final type = apt['type'] == 'video_call' ? 'Video Call' : apt['type'] ?? 'Call';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Success Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: _green, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            // Details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _aptRow(Icons.person_rounded, 'Veterinarian', vetName, _green),
                  const Divider(height: 20),
                  _aptRow(Icons.access_time_rounded, 'Scheduled At', timeStr, _orange),
                  const Divider(height: 20),
                  _aptRow(Icons.local_hospital_rounded, 'Clinic', clinic, Colors.teal.shade700),
                  const Divider(height: 20),
                  _aptRow(Icons.videocam_rounded, 'Type', type, Colors.indigo),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aptRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B2A1E))),
          ],
        ),
      ],
    );
  }

  // ─── Navigate to Health Analyze ─────────────────────────
  void _goHealthAnalyze() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthAnalyzeScreen(
          animal: _currentAnimal,
          navIndex: _navIndex,
        ),
      ),
    );
  }

  // ─── Species badge color ─────────────────────────────────
  Color get _badgeBg {
    final s = _currentAnimal.species.toLowerCase();
    if (s.contains('buffalo')) return const Color(0xFFE8F5E9);
    if (s.contains('goat') || s.contains('sheep')) return const Color(0xFFFFEBEE);
    return const Color(0xFFFFE0B2);
  }

  Color get _badgeText {
    final s = _currentAnimal.species.toLowerCase();
    if (s.contains('buffalo')) return const Color(0xFF2E7D32);
    if (s.contains('goat') || s.contains('sheep')) return const Color(0xFFC62828);
    return _orange;
  }

  // ─── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        final animal = _currentAnimal;
        final isTreatment = animal.isUnderTreatment;

        return Scaffold(
          backgroundColor: _bg,
          extendBody: true,
          bottomNavigationBar: FloatingNavBar(
            currentIndex: _navIndex,
            onTap: (i) {
              if (widget.onNavTap != null) {
                widget.onNavTap!(i);
                Navigator.pop(context);
              } else {
                setState(() => _navIndex = i);
              }
            },
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _circleBtn(
                        Icons.chevron_left_rounded,
                        () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          animal.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B2A1E),
                          ),
                        ),
                      ),
                      // Edit button (pill outline)
                      OutlinedButton.icon(
                        onPressed: _openEditAnimalModal,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text('edit'.tr,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22)),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _confirmDeleteAnimal,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFC62828),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

            // ── Hero card ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animal image with lush meadow farm background
                    AnimalThumbnail(
                      assetImage: animal.assetImage,
                      size: 104,
                      borderRadius: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                animal.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B2A1E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _badgeBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  animal.species,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: _badgeText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${animal.ageYears.toInt()} ${'years'.tr}  •  ${animal.breed}',
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF546E7A)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${'ear_tag'.tr}: ${animal.tagNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF455A64),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isTreatment
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                                size: 16,
                                color: isTreatment
                                    ? _orange
                                    : const Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isTreatment ? 'ongoing_treatment'.tr : 'healthy'.tr,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: isTreatment
                                      ? _orange
                                      : const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.2),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF757575),
                  labelStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    Tab(text: 'info_tab'.tr),
                    Tab(text: 'health_history_tab'.tr),
                    Tab(text: 'vaccination_tab'.tr),
                    Tab(text: 'productivity_tab'.tr),
                  ],
                ),
              ),
            ),

            // ── Tab content ──────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InfoTab(
                    animal: animal,
                    onHealthAnalyze: _goHealthAnalyze,
                    onConnectDoctor: _connectDoctor,
                  ),
                  _HealthHistoryTab(
                    animal: animal,
                  ),
                  _VaccinationTab(
                    animal: animal,
                    onBookVaccination: _bookVaccinationSlot,
                  ),
                  _ProductivityTab(
                    animal: animal,
                  ),
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

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF263238), size: 26),
      ),
    );
  }
}

// ─── ACTION BUTTONS BAR (SCROLLS NATURALLY WITH SCREEN CONTENT) ──────────────
class _ActionButtonsBar extends StatelessWidget {
  final VoidCallback onHealthAnalyze;
  final VoidCallback onConnectDoctor;

  const _ActionButtonsBar({
    required this.onHealthAnalyze,
    required this.onConnectDoctor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 110),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onHealthAnalyze,
              icon: const Icon(Icons.health_and_safety_rounded, size: 22),
              label: Text(
                'health_analyze'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
                side: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onConnectDoctor,
              icon: const Icon(
                Icons.medical_services_rounded,
                size: 22,
                color: Colors.white,
              ),
              label: Text(
                'connect_doctor'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFE65100).withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 1: Basic Info ───────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final AnimalModel animal;
  final VoidCallback onHealthAnalyze;
  final VoidCallback onConnectDoctor;

  const _InfoTab({
    required this.animal,
    required this.onHealthAnalyze,
    required this.onConnectDoctor,
  });

  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final isTreatment = animal.isUnderTreatment;
    final info = animal.treatmentInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Basic Info ────────────────────────────────
          _sectionCard(
            title: 'basic_info'.tr,
            children: [
              _infoBox(Icons.calendar_month_rounded, 'date_of_birth'.tr, '12 Jan ${DateTime.now().year - animal.ageYears.toInt()}'),
              _infoBox(Icons.category_rounded, 'breed'.tr, animal.breed),
              _infoBox(Icons.monitor_weight_rounded, 'weight'.tr,
                  '${(animal.species.toLowerCase().contains('goat') ? 45 : animal.species.toLowerCase().contains('buffalo') ? 500 : 420)} kg'),
              _infoBox(Icons.tag_rounded, 'ear_tag'.tr, animal.tagNumber),
              _infoBox(Icons.location_on_rounded, 'location'.tr, 'My Farm, Pune'),
              _infoBox(Icons.transgender_rounded, 'gender'.tr, animal.gender, isLast: true),
            ],
          ),

          const SizedBox(height: 16),

          // ── Health Summary ────────────────────────────
          _sectionCard(
            title: 'health_summary'.tr,
            children: [],
            customContent: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          color: isTreatment
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isTreatment
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFFA5D6A7),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: isTreatment ? _orange : _green,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('current_health'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF757575),
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      isTreatment ? 'ongoing_treatment'.tr : 'good_status'.tr,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: isTreatment ? _orange : _green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.vaccines_rounded,
                                color: _orange, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('last_vaccine'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF757575),
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      animal.vaccinationStatus.contains('Up')
                                          ? '2 months ago'
                                          : 'Overdue',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: _orange,
                                      ),
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
                if (isTreatment && info != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suspected: ${info['suspectedDisease'] ?? 'Under Examination'}',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: _orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info['vetNotes'] ?? 'Monitoring ongoing.',
                          style: const TextStyle(
                              fontSize: 13.5, color: Color(0xFF424242), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Action Buttons Scrolling Naturally ────────
          _ActionButtonsBar(
            onHealthAnalyze: onHealthAnalyze,
            onConnectDoctor: onConnectDoctor,
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EDE6), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: _green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF546E7A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2A1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    Widget? customContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2A1E),
            ),
          ),
          const SizedBox(height: 14),
          ?customContent,
          ...children,
        ],
      ),
    );
  }
}

// ─── TAB 2: Health History & Pathology Reports ────────────────────────────────
class _HealthHistoryTab extends StatefulWidget {
  final AnimalModel animal;

  const _HealthHistoryTab({
    required this.animal,
  });

  @override
  State<_HealthHistoryTab> createState() => _HealthHistoryTabState();
}

class _HealthHistoryTabState extends State<_HealthHistoryTab> {
  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);

  bool _loading = true;
  Map<String, dynamic>? _medHistory; // central source: /animals/:id/medical-history

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final tag = widget.animal.tagNumber.isNotEmpty
          ? widget.animal.tagNumber
          : widget.animal.id;
      final history = await FarmerApiService().getAnimalMedicalHistory(tag);
      if (mounted) setState(() { _medHistory = history; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _labReports {
    final raw = _medHistory?['laboratoryTests'] as List? ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> get _treatments {
    final raw = _medHistory?['treatments'] as List? ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> get _cases {
    final raw = _medHistory?['cases'] as List? ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final isTreatment = animal.isUnderTreatment;
    final info = animal.treatmentInfo;

    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: _green)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── SECTION 1: Prescriptions & Treatments ─────────────────
                  _sectionHeader('Doctor Prescriptions & Medicines',
                      '${_treatments.length}', const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
                  const SizedBox(height: 10),

                  if (_treatments.isEmpty)
                    _emptyCard(
                      icon: Icons.medication_rounded,
                      message: 'No prescriptions recorded yet for ${animal.name}',
                      sub: 'Prescriptions added by your vet during consultations will appear here.',
                    )
                  else
                    ..._treatments.map((t) => _buildPrescriptionCard(t)),

                  const SizedBox(height: 18),

                  // ── SECTION 2: Recommended Lab Tests ─────────────────────
                  _sectionHeader('Vet-Ordered Lab Investigations',
                      '${_labReports.length}', const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
                  const SizedBox(height: 10),

                  if (_labReports.isEmpty)
                    _emptyCard(
                      icon: Icons.science_outlined,
                      message: 'No lab tests ordered yet for ${animal.name}',
                      sub: 'Tests recommended by the vet and processed by state diagnostic labs will appear here.',
                    )
                  else
                    ..._labReports.map((r) => _buildLabReportCard(r)),

                  const SizedBox(height: 18),

                  // ── SECTION 3: Clinical Case Timeline ─────────────────────
                  _sectionHeader('Clinical Case Timeline',
                      '${_cases.length}', _green, const Color(0xFFDCFCE7)),
                  const SizedBox(height: 10),

                  if (isTreatment && info != null)
                    _buildTimelineCard(
                      title: info['suspectedDisease'] ?? 'Under Examination',
                      note: info['vetNotes'] ?? 'Attending vet monitoring ongoing.',
                      date: 'Active',
                      icon: Icons.warning_amber_rounded,
                      color: _orange,
                    ),

                  if (_cases.isEmpty && !isTreatment)
                    _emptyCard(
                      icon: Icons.health_and_safety_outlined,
                      message: 'No clinical visits on record',
                      sub: 'When your vet closes a consultation, the case will appear here.',
                    )
                  else
                    ..._cases.map((c) {
                      final ai = c['aiPreliminaryAssessment'] as Map? ?? {};
                      final conditions = (ai['possibleConditions'] as List?)?.join(', ') ?? '';
                      final dateStr = DateTime.tryParse(c['date']?.toString() ?? '')
                              ?.toLocal().toString().split(' ')[0] ?? 'Recent';
                      return _buildTimelineCard(
                        title: conditions.isNotEmpty ? conditions : 'Clinical Assessment',
                        note: (c['additionalNotes'] ?? 'Veterinary case reviewed.').toString(),
                        date: dateStr,
                        icon: Icons.health_and_safety_rounded,
                        color: const Color(0xFF0284C7),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _sectionHeader(String title, String count, Color accent, Color bg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2A1E))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Text(count,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: accent)),
        ),
      ],
    );
  }

  Widget _emptyCard({required IconData icon, required String message, required String sub}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  /// Prescription card: shows medicines list + instructions + follow-up
  Widget _buildPrescriptionCard(Map<String, dynamic> t) {
    final medicines = (t['medicines'] as List? ?? []).cast<Map>();
    final diagnosis = t['diagnosis']?.toString() ?? 'Veterinary Treatment';
    final dateStr = DateTime.tryParse(t['date']?.toString() ?? '')
            ?.toLocal().toString().split(' ')[0] ?? 'Recent';
    final followUp = t['followUpDate'] != null
        ? DateTime.tryParse(t['followUpDate'].toString())
                ?.toLocal().toString().split(' ')[0] ?? ''
        : null;
    final instructions = t['specialInstructions']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.medication_rounded, color: Color(0xFF7C3AED), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(diagnosis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1B2A1E))),
                    const SizedBox(height: 2),
                    Text('Issued: $dateStr',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (followUp != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                  child: Text('Follow-up\n$followUp',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFE65100))),
                ),
            ],
          ),
          if (medicines.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Prescribed Medicines',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
            const SizedBox(height: 6),
            ...medicines.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 7, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${m['name'] ?? m['medicineName'] ?? 'Medicine'}  \u2022  ${m['dosage'] ?? ''}, ${m['frequency'] ?? ''}${m['durationDays'] != null ? '  (${m['durationDays']} days)' : ''}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B2A1E)),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Text('📋 $instructions',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabReportCard(Map<String, dynamic> r) {
    final isAbnormal = r['isAbnormal'] == true;
    final reportId = r['reportId'] ?? r['id'] ?? 'RPT-2026-LAB';
    final testType = r['testType'] ?? 'Diagnostic Pathology Assay';
    final resultSummary = r['resultSummary'] ?? r['testResult'] ?? 'Normal findings';
    final observations = r['observations'] ?? 'Verified by state laboratory.';
    final dateStr = r['finalizedAt']?.toString().split('T')[0] ?? 'Recent';
    final parameters = r['parameters'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAbnormal ? const Color(0xFFFFCDD2) : Colors.grey.shade200,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isAbnormal ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.biotech_rounded,
                  color: isAbnormal ? const Color(0xFFD32F2F) : _green,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            testType,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2A1E),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAbnormal ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAbnormal ? 'Abnormal' : 'Verified Normal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isAbnormal ? const Color(0xFFD32F2F) : _green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID: $reportId  •  $dateStr',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnostic Result: $resultSummary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isAbnormal ? const Color(0xFFB71C1C) : const Color(0xFF1B2A1E),
                  ),
                ),
                if (parameters.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...parameters.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• ${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  )),
                ],
                const SizedBox(height: 6),
                Text(
                  'Lab Technologist Note: $observations',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard({
    required String title,
    required String note,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2A1E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF546E7A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 3: Vaccination ──────────────────────────────────────────────────────
class _VaccinationTab extends StatefulWidget {
  final AnimalModel animal;
  final VoidCallback onBookVaccination;

  const _VaccinationTab({
    required this.animal,
    required this.onBookVaccination,
  });

  @override
  State<_VaccinationTab> createState() => _VaccinationTabState();
}

class _VaccinationTabState extends State<_VaccinationTab> {
  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);

  bool _loading = true;
  List<Map<String, dynamic>> _vaccinations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final tag = widget.animal.tagNumber.isNotEmpty
          ? widget.animal.tagNumber
          : widget.animal.id;
      // Use the same central medical-history endpoint — single source of truth
      final history = await FarmerApiService().getAnimalMedicalHistory(tag);
      final raw = history?['vaccinations'] as List? ?? [];
      if (mounted) {
        setState(() {
          _vaccinations = raw.whereType<Map<String, dynamic>>().toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDue = _vaccinations.any((v) =>
        (v['status'] ?? '').toString().toUpperCase() == 'DUE');

    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: _green)),
              )
            : Column(
                children: [
                  if (_vaccinations.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.vaccines_rounded, size: 42, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text('No vaccination records found for ${widget.animal.name}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text('Book a vaccination slot to get started.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else
                    ..._vaccinations.map((v) {
                      final status = (v['status'] ?? 'COMPLETED').toString().toUpperCase();
                      final isDue = status == 'DUE' || status == 'OVERDUE';
                      final isScheduled = status == 'SCHEDULED';
                      final name = v['vaccineName'] ?? v['vaccine'] ?? 'Vaccine';
                      final administered = v['administeredDate'] ?? v['bookingDate'];
                      final nextDue = v['nextDueDate'];
                      final batch = v['batchNumber'] ?? 'N/A';
                      final adminStr = administered != null
                          ? (DateTime.tryParse(administered.toString())
                                  ?.toLocal()
                                  .toString()
                                  .split(' ')[0] ??
                              administered.toString())
                          : 'Pending';
                      final nextStr = nextDue != null
                          ? (DateTime.tryParse(nextDue.toString())
                                  ?.toLocal()
                                  .toString()
                                  .split(' ')[0] ??
                              nextDue.toString())
                          : 'N/A';

                      Color accent = _green;
                      Color bgColor = const Color(0xFFE8F5E9);
                      IconData icon = Icons.check_circle_rounded;
                      String label = 'Done';
                      if (isDue) {
                        accent = _orange;
                        bgColor = const Color(0xFFFFF3E0);
                        icon = Icons.schedule_rounded;
                        label = 'Due';
                      } else if (isScheduled) {
                        accent = const Color(0xFF0284C7);
                        bgColor = const Color(0xFFE0F2FE);
                        icon = Icons.event_available_rounded;
                        label = 'Scheduled';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDue ? const Color(0xFFFFCCBC) : Colors.grey.shade200,
                              width: isDue ? 1.5 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                                child: Icon(icon, color: accent, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF1B2A1E))),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Given: $adminStr  •  Next: $nextStr',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                                          color: isDue ? _orange : const Color(0xFF546E7A)),
                                    ),
                                    if (batch != 'N/A')
                                      Text('Batch: $batch',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDue ? const Color(0xFFFFEBEE) : bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(label,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  if (hasDue || _vaccinations.isEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: widget.onBookVaccination,
                        icon: const Icon(Icons.event_available_rounded, size: 22),
                        label: const Text('Book Vaccination Slot',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}


// ─── TAB 4: Productivity ─────────────────────────────────────────────────────


class _ProductivityTab extends StatelessWidget {
  final AnimalModel animal;

  const _ProductivityTab({
    required this.animal,
  });

  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final yieldLiters = animal.dailyMilkYieldLiters;
    final hasYield = yieldLiters > 0;
    final stage = animal.lactationStage;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Milk Yield card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Milk Yield',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _yieldCard(
                            'Daily', hasYield ? '${yieldLiters.toStringAsFixed(1)} L' : 'N/A',
                            Icons.water_drop_rounded, _green)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _yieldCard(
                            'Monthly', hasYield ? '${(yieldLiters * 30).toStringAsFixed(0)} L' : 'N/A',
                            Icons.calendar_month_rounded, _orange)),
                  ],
                ),
                const SizedBox(height: 16),
                _yieldRow('Lactation Stage', stage),
                _yieldRow('Status', hasYield ? 'Active Milking' : 'Not Applicable'),
                _yieldRow('Quality', hasYield ? 'Grade A' : 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Breeding info
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Breeding Information',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E))),
                const SizedBox(height: 12),
                _yieldRow('Last Breeding', '—'),
                _yieldRow('Calving', '—'),
                _yieldRow('Parity', '—'),
              ],
            ),
          ),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _yieldCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: color.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _yieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF546E7A),
                  fontWeight: FontWeight.w700)),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E))),
        ],
      ),
    );
  }
}

