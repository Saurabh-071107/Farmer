import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/vaccination_flow_tracking_modal.dart';

class VaccinationScreen extends StatefulWidget {
  final int navIndex;
  const VaccinationScreen({super.key, this.navIndex = 0});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  static const _bg = Color(0xFFFCFAF5);
  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);

  int _tabIndex = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _livestock = [];
  Map<String, dynamic>? _weather;
  Map<String, dynamic>? _activeBooking;

  @override
  void initState() {
    super.initState();
    _loadLivestockVaccinationData();
  }

  Future<void> _loadLivestockVaccinationData() async {
    setState(() => _isLoading = true);
    try {
      final res = await FarmerApiService().getFarmerLivestockVaccinationStatus();
      if (mounted) {
        setState(() {
          _livestock = List<Map<String, dynamic>>.from(res['livestock'] ?? []);
          _weather = res['weather'];
          _activeBooking = res['activeBooking'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_tabIndex == 1) {
      return _livestock.where((l) => l['overallStatus'] == 'DUE').toList();
    }
    if (_tabIndex == 2) {
      return _livestock.where((l) => l['overallStatus'] == 'SCHEDULED').toList();
    }
    if (_tabIndex == 3) {
      return _livestock.where((l) => l['overallStatus'] == 'UP_TO_DATE').toList();
    }
    return _livestock;
  }

  int get _dueCount => _livestock.where((l) => l['overallStatus'] == 'DUE').length;
  int get _scheduledCount => _livestock.where((l) => l['overallStatus'] == 'SCHEDULED').length;
  int get _upToDateCount => _livestock.where((l) => l['overallStatus'] == 'UP_TO_DATE').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: widget.navIndex,
        onTap: (_) => Navigator.pop(context),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _green,
          onRefresh: _loadLivestockVaccinationData,
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabSelector(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _green))
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 95),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Active Ongoing Booking Banner
                            if (_activeBooking != null) ...[
                              _buildActiveTrackerBanner(),
                              const SizedBox(height: 12),
                            ],

                            // 2. Central AI Weather & Outbreak Surveillance Banner
                            if (_weather != null) ...[
                              _buildAiWeatherSurveillanceBanner(),
                              const SizedBox(height: 14),
                            ],

                            // 3. Livestock List
                            ..._filtered.map(_buildLivestockCard),
                            if (_filtered.isEmpty) _buildEmptyState(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 44,
              height: 44,
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
              child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1B2A1E), size: 28),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livestock Vaccination',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2A1E),
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Doorstep cold-chain biological administration & AI alerts',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = [
      'All (${_livestock.length})',
      'Due / AI Alert ($_dueCount)',
      'Scheduled ($_scheduledCount)',
      'Up to Date ($_upToDateCount)',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _tabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              selected: isSelected,
              selectedColor: _green,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? _green : Colors.grey.shade300,
                ),
              ),
              onSelected: (_) => setState(() => _tabIndex = index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTrackerBanner() {
    final b = _activeBooking!;
    final vaccine = b['vaccineName'] ?? 'Vaccine';
    final animalName = b['animalName'] ?? 'Livestock';
    final animalTag = b['animalTag'] ?? '';
    final status = (b['status'] ?? 'CONFIRMED').toString().toUpperCase();
    final otp = b['verificationOtp']?.toString();

    String statusText = 'Request Confirmed';
    if (status == 'ACCEPTED') statusText = 'Paravet Assigned & Dispatched';
    if (status == 'OUT_FOR_VACCINATION') statusText = 'Paravet En Route';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.vaccines, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE VACCINATION REQUEST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      '$vaccine • $animalName ($animalTag)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF60A5FA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (otp != null && otp.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'OTP: $otp',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFBBF24),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    VaccinationFlowTrackingModal.show(context, bookingId: b['bookingId'] ?? b['id']);
                  },
                  icon: const Icon(Icons.timeline, size: 16),
                  label: const Text('Track Live Flow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiWeatherSurveillanceBanner() {
    final temp = _weather!['temp'] ?? 26;
    final humidity = _weather!['humidity'] ?? 75;
    final condition = _weather!['weatherCondition'] ?? 'Rain';
    final desc = _weather!['description'] ?? 'monsoon weather';
    final district = _weather!['district'] ?? 'Pune';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.cloud, color: Color(0xFF16A34A), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Central AI Bio-Surveillance • $district ($condition, $temp°C, $humidity% Humidity)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'High humidity and $desc elevate bacterial spore transmission (HS & BQ). Automatic pending vaccination statuses have been scheduled for susceptible livestock.',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF15803D),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivestockCard(Map<String, dynamic> animal) {
    final name = animal['name'] ?? 'Livestock';
    final earTag = animal['earTagId'] ?? animal['animalId'] ?? '';
    final species = animal['species'] ?? 'Cow';
    final breed = animal['breed'] ?? 'Indigenous';
    final ageMonths = animal['ageMonths'] ?? 24;
    final overallStatus = animal['overallStatus'] ?? 'DUE';
    final recs = List<Map<String, dynamic>>.from(animal['aiRecommendations'] ?? []);
    final topRec = recs.isNotEmpty ? recs[0] : null;
    final activeBooking = animal['activeBooking'];

    Color badgeColor;
    Color badgeBg;
    String badgeText;
    if (overallStatus == 'SCHEDULED') {
      badgeColor = const Color(0xFF2563EB);
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = 'Scheduled';
    } else if (overallStatus == 'UP_TO_DATE') {
      badgeColor = _green;
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = 'Up to Date';
    } else {
      badgeColor = _orange;
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = 'Vaccine Due';
    }

    final isBuffalo = species.toLowerCase().contains('buff');
    final isGoat = species.toLowerCase().contains('goat') || species.toLowerCase().contains('sheep');
    String imageAsset = 'assets/images/animal_cow.png';
    if (isBuffalo) imageAsset = 'assets/images/animal_buffalo.png';
    if (isGoat) imageAsset = 'assets/images/animal_goat.png';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animal Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFF1F8E9),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.pets, color: _green, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$species ($breed) • $ageMonths Months',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Tag: $earTag',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // AI Recommendation Callout
          if (topRec != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended: ${topRec['vaccineName']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topRec['riskFactor'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Actions Row
          Row(
            children: [
              if (activeBooking != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      VaccinationFlowTrackingModal.show(context, bookingId: activeBooking['bookingId'] ?? activeBooking['id']);
                    },
                    icon: const Icon(Icons.timeline, size: 16),
                    label: const Text('Track Paravet & OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openBookSlotBottomSheet(animal, topRec),
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Book Vaccination Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.pets, size: 54, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              'No Livestock Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your cattle, buffalo, or goats on the Home screen to view their vaccination schedules.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookSlotBottomSheet(Map<String, dynamic> animal, Map<String, dynamic>? defaultRec) {
    final animalName = animal['name'] ?? 'Livestock';
    final earTag = animal['earTagId'] ?? animal['animalId'] ?? '';
    final defaultVaccine = defaultRec != null ? defaultRec['vaccineName'] : 'Foot and Mouth Disease (FMD Trivalent)';
    String selectedVaccine = defaultVaccine;
    String selectedSlot = 'Morning (09:00 AM - 12:00 PM)';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.vaccines, color: _green, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Book Doorstep Vaccination', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('For $animalName ($earTag)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 18),

              // Vaccine Selection
              const Text('Vaccine & Disease Target', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedVaccine,
                    items: [
                      'Black Quarter Vaccine (BQ)',
                      'Haemorrhagic Septicaemia (HS-Alum)',
                      'Foot and Mouth Disease (FMD Trivalent)',
                      'Brucellosis Calfhood Vaccine (Strain 19)',
                      'Enterotoxaemia (ET) Vaccine',
                      'PPR Vaccine (Goat Plague)',
                    ].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedVaccine = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Date Picker
              const Text('Preferred Date', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.calendar_today, size: 16, color: _green),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Slot Picker
              const Text('Time Slot', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedSlot,
                    items: [
                      'Morning (09:00 AM - 12:00 PM)',
                      'Afternoon (01:00 PM - 04:00 PM)',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedSlot = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setModalState(() => isSubmitting = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        try {
                          final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                          final booking = await FarmerApiService().bookVaccinationSlot(
                            animalId: earTag,
                            vaccineName: selectedVaccine,
                            bookedDate: dateStr,
                            slot: selectedSlot,
                            aiTriggered: true,
                          );

                          if (!mounted) return;
                          nav.pop();
                          _loadLivestockVaccinationData();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Vaccination booked! Booking ID: ${booking['bookingId']}'),
                              backgroundColor: _green,
                            ),
                          );

                          if (!context.mounted) return;
                          VaccinationFlowTrackingModal.show(context, bookingId: booking['bookingId']);
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Doorstep Booking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
