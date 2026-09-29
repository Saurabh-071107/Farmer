import 'package:flutter/material.dart';
import '../widgets/floating_nav_bar.dart';
import '../services/active_consultation_state.dart';
import '../services/api_service.dart';
import '../services/app_translations.dart';
import '../services/session_manager.dart';
import 'report_detail_screen.dart';

class TestsAndReportsScreen extends StatefulWidget {
  final int initialCategoryIndex;

  const TestsAndReportsScreen({
    super.key,
    this.initialCategoryIndex = 0,
  });

  @override
  State<TestsAndReportsScreen> createState() => _TestsAndReportsScreenState();
}

class _TestsAndReportsScreenState extends State<TestsAndReportsScreen> {
  static const Color _orange = Color(0xFFFF6D00);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _bg = Color(0xFFFBF9F4);

  late int _selectedCategoryIndex;

  // Categories corresponding to user reference
  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'All Animals',
      'image': 'assets/images/test_icon_13.png',
      'type': 'All',
    },
    {
      'label': 'Cows',
      'image': 'assets/images/test_icon_13.png',
      'type': 'Cow',
    },
    {
      'label': 'Buffaloes',
      'image': 'assets/images/test_icon_14.png',
      'type': 'Buffalo',
    },
    {
      'label': 'Goats',
      'image': 'assets/images/test_icon_15.png',
      'type': 'Goat',
    },
    {
      'label': 'Others',
      'image': 'assets/images/test_icon_16.png',
      'type': 'Other',
    },
  ];

  // 6 Tests in the 3x2 grid with photoroom assets from user
  final List<Map<String, dynamic>> _tests = [
    {
      'name': 'Blood Test',
      'subtitle': 'General Health,\nInfection',
      'imageAsset': 'assets/images/test_icon_8.png',
      'color': const Color(0xFF00897B),
      'bgColor': const Color(0xFFE0F2F1),
    },
    {
      'name': 'Fecal Test',
      'subtitle': 'Parasites,\nDigestive Health',
      'imageAsset': 'assets/images/test_icon_9.png',
      'color': const Color(0xFFF57C00),
      'bgColor': const Color(0xFFFFF3E0),
    },
    {
      'name': 'Milk Test',
      'subtitle': 'Quality, Mastitis\nDetection',
      'imageAsset': 'assets/images/test_icon_10.png',
      'color': const Color(0xFF1976D2),
      'bgColor': const Color(0xFFE3F2FD),
    },
    {
      'name': 'Disease Screening',
      'subtitle': 'FMD, Brucellosis,\nTB, etc.',
      'imageAsset': 'assets/images/test_icon_9.png',
      'color': const Color(0xFF7B1FA2),
      'bgColor': const Color(0xFFF3E5F5),
    },
    {
      'name': 'Pregnancy Test',
      'subtitle': 'Early Detection',
      'imageAsset': 'assets/images/test_icon_11.png',
      'color': const Color(0xFFE91E63),
      'bgColor': const Color(0xFFFFEBEE),
    },
    {
      'name': 'DNA & Genetic Test',
      'subtitle': 'Breed Identification',
      'imageAsset': 'assets/images/test_icon_12.png',
      'color': const Color(0xFF388E3C),
      'bgColor': const Color(0xFFE8F5E9),
    },
  ];

  // Dynamic Recent Reports loaded from live MongoDB Atlas backend
  final List<Map<String, dynamic>> _recentReports = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex;
    _loadBackendCases();
  }

  Future<void> _loadBackendCases() async {
    try {
      final animals = await FarmerApiService().getMyAnimals();
      final cases = await FarmerApiService().getMyCases();

      // 1. Load live completed pathology lab reports from MongoDB Atlas
      final completedReports = await FarmerApiService().getFarmerCompletedReports();
      for (final r in completedReports) {
        final isAbnormal = r['isAbnormal'] == true;
        final repItem = {
          'id': r['reportId'] ?? r['id'],
          'animalName': r['animalTag'] ?? 'Livestock',
          'animalType': r['animalType'] ?? 'Cow',
          'animalImage': 'assets/images/animal_cow.png',
          'testName': r['testType'] ?? 'Diagnostic Pathology Assay',
          'date': 'Tested on ${r['finalizedAt']?.toString().split('T')[0] ?? 'Recent'}',
          'status': isAbnormal ? 'Abnormal Findings' : 'Normal / Completed',
          'statusColor': isAbnormal ? const Color(0xFFD32F2F) : _green,
          'tagBg': isAbnormal ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
          'tagColor': isAbnormal ? const Color(0xFFC62828) : const Color(0xFF00695C),
          'vetNotes': r['observations'] ?? r['resultSummary'] ?? 'Diagnostic analysis completed by accredited veterinary pathology laboratory.',
          'parameters': r['parameters'] ?? {},
          'testResult': r['testResult'] ?? 'Normal',
        };
        if (!_recentReports.any((existing) => existing['id'] == repItem['id'])) {
          _recentReports.insert(0, repItem);
        }
      }

      for (final a in animals) {
        final reports = await FarmerApiService().getAnimalLabReports(a.tagNumber);
        for (final r in reports) {
          final isAbnormal = r['isAbnormal'] == true;
          final repItem = {
            'id': r['reportId'] ?? r['id'],
            'animalName': a.name,
            'animalType': a.species,
            'animalImage': a.assetImage,
            'testName': r['testType'] ?? 'Diagnostic Pathology Assay',
            'date': 'Tested on ${r['finalizedAt']?.toString().split('T')[0] ?? 'Recent'}',
            'status': isAbnormal ? 'Abnormal Findings' : 'Normal / Completed',
            'statusColor': isAbnormal ? const Color(0xFFD32F2F) : _green,
            'tagBg': isAbnormal ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
            'tagColor': isAbnormal ? const Color(0xFFC62828) : const Color(0xFF00695C),
            'vetNotes': r['observations'] ?? r['resultSummary'] ?? 'Diagnostic report completed.',
            'parameters': r['parameters'] ?? {},
            'testResult': r['testResult'] ?? 'Normal',
          };
          if (!_recentReports.any((existing) => existing['id'] == repItem['id'])) {
            _recentReports.insert(0, repItem);
          }
        }
      }

      if (cases.isNotEmpty && mounted) {
        setState(() {
          for (final c in cases) {
            final isTreated = c['status'] == 'treated' || c['status'] == 'prescribed';
            final item = {
              'id': c['id'],
              'animalName': c['animalName'] ?? 'Livestock',
              'animalType': c['species'] ?? 'Cow',
              'animalImage': 'assets/images/animal_cow.png',
              'testName': c['aiPredictedDisease'] ?? 'Clinical Diagnosis',
              'date': 'Reported on ${DateTime.tryParse(c['createdAt'] ?? '')?.toLocal().toString().split(' ')[0] ?? 'Recent'}',
              'status': isTreated ? 'Prescribed & Treated' : (c['status'] ?? 'Under Examination'),
              'statusColor': isTreated ? _green : const Color(0xFFF57C00),
              'tagBg': const Color(0xFFE0F2F1),
              'tagColor': const Color(0xFF00695C),
              'vetNotes': c['vetNotes'],
              'prescriptions': c['prescriptions'],
              'recommendedTests': c['recommendedTests'],
            };
            if (!_recentReports.any((r) => r['id'] == item['id'] || r['testName'] == item['testName'])) {
              _recentReports.insert(0, item);
            }
          }
        });
      }
    } catch (_) {}
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 95),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroBanner(),
                        const SizedBox(height: 16),
                        _buildCategorySelector(),
                        const SizedBox(height: 22),
                        _buildSectionHeader('book_a_test'.tr, () => _openBookTestModal(context)),
                        const SizedBox(height: 12),
                        _buildBookTestGrid(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('recent_reports'.tr, () {}),
                        const SizedBox(height: 12),
                        if (_recentReports.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.assignment_outlined, size: 38, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                Text(
                                  'No Diagnostic Reports Yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Book a lab test above to receive verified digital pathology reports.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._recentReports.map(_buildReportCard),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // APP BAR
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
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
              child: const Icon(Icons.chevron_left_rounded,
                  color: Color(0xFF1B2A1E), size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'tests_and_reports'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // "How it works?" button
          InkWell(
            onTap: () => _showHowItWorksModal(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_rounded, color: _green, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    'how_it_works'.tr,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _green,
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

  // HERO BANNER
  Widget _buildHeroBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9C4),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/test_banner.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, e, s) => Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFFFF8E1),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep Your Livestock Healthy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Book tests, view reports and get expert insights.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF616161),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ANIMAL CATEGORIES SELECTOR
  Widget _buildCategorySelector() {
    return Row(
      children: List.generate(_categories.length, (index) {
        final cat = _categories[index];
        final isSelected = _selectedCategoryIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  right: index == _categories.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _orange : Colors.grey.shade200,
                  width: isSelected ? 1.8 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    cat['image'] as String,
                    height: 42,
                    fit: BoxFit.contain,
                    errorBuilder: (_, e, s) => const Icon(
                      Icons.pets_rounded,
                      size: 32,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? _orange : const Color(0xFF424242),
                      ),
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

  // SECTION HEADER
  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B2A1E),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            children: [
              Text(
                'view_all'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _orange,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: _orange),
            ],
          ),
        ),
      ],
    );
  }

  // 6 TEST CARDS (3x2 GRID)
  Widget _buildBookTestGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTestCard(_tests[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildTestCard(_tests[1])),
            const SizedBox(width: 8),
            Expanded(child: _buildTestCard(_tests[2])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTestCard(_tests[3])),
            const SizedBox(width: 8),
            Expanded(child: _buildTestCard(_tests[4])),
            const SizedBox(width: 8),
            Expanded(child: _buildTestCard(_tests[5])),
          ],
        ),
      ],
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    return InkWell(
      onTap: () => _openBookTestModal(context, initialTest: test['name'] as String),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 126,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: test['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    test['imageAsset'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (_, e, s) => Icon(
                      test['icon'] as IconData? ?? Icons.science_rounded,
                      color: test['color'] as Color,
                      size: 20,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 19, color: Colors.grey.shade400),
              ],
            ),
            const Spacer(),
            Text(
              test['name'] as String,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              test['subtitle'] as String,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // RECENT REPORT CARD
  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              height: 58,
              color: const Color(0xFFF1F8E9),
              child: Image.asset(
                report['animalImage'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => const Icon(Icons.pets_rounded, color: _green, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        report['animalName'] as String,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2A1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: report['tagBg'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report['testName'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: report['tagColor'] as Color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  report['date'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: report['statusColor'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          report['status'] as String,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: report['statusColor'] as Color,
                          ),
                        ),
                      ],
                    ),
                    Text('|', style: TextStyle(color: Colors.grey.shade400)),
                    InkWell(
                      onTap: () => _openReportDetails(report),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Report',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: _orange,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: _orange),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Red PDF Icon Button
          InkWell(
            onTap: () => _openReportDetails(report),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFC62828), size: 22),
                  SizedBox(height: 2),
                  Text(
                    'PDF',
                    style: TextStyle(
                      fontSize: 10,
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

  // HOW IT WORKS MODAL
  void _showHowItWorksModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'How Diagnostic Testing Works',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
            ),
            const SizedBox(height: 16),
            _howItWorksStep(1, 'Book Test & Pick Animal',
                'Select the diagnostic test and the registered animal from your livestock profile.'),
            const SizedBox(height: 12),
            _howItWorksStep(2, 'Doorstep Sample Collection',
                'A government-certified veterinary technician visits your farm to collect samples safely.'),
            const SizedBox(height: 12),
            _howItWorksStep(3, 'Digital Lab Report in 24h',
                'Verified results and doctor recommendations are delivered straight to your phone.'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Got it',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _howItWorksStep(int step, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _green),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1B2A1E)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // REDESIGNED TEST BOOKING MODAL
  void _openBookTestModal(BuildContext context, {String? initialTest}) {
    final cached = FarmerApiService.getCachedAnimals();
    final List<Map<String, String>> animals = cached.isNotEmpty
        ? cached.map((a) => {
            'id': a.id,
            'name': a.name,
            'species': a.species,
            'tag': a.tagNumber.isNotEmpty ? a.tagNumber : a.id,
            'image': a.assetImage,
          }).toList()
        : [
            {'id': 'ANM-001', 'name': 'Gauri', 'species': 'Cow', 'tag': 'ET-893421', 'image': 'assets/images/animal_cow.png'},
            {'id': 'ANM-002', 'name': 'Laxmi', 'species': 'Buffalo', 'tag': 'ET-441209', 'image': 'assets/images/animal_buffalo.png'},
            {'id': 'ANM-003', 'name': 'Chandu', 'species': 'Goat', 'tag': 'ET-102938', 'image': 'assets/images/animal_goat.png'},
            {'id': 'ANM-004', 'name': 'Sundari', 'species': 'Cow', 'tag': 'ET-203948', 'image': 'assets/images/animal_cow.png'},
          ];

    String selectedTest = initialTest ?? _tests[0]['name'] as String;
    String selectedAnimal = animals.isNotEmpty ? animals[0]['name']! : 'Gauri';
    String selectedDate = 'Tomorrow (27 Sep)';
    bool isBooking = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Top drag bar & header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFE0B2)),
                          ),
                          child: Image.asset(
                            'assets/images/test_icon_8.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Book Diagnostic Test',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B2A1E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Doorstep sample collection by verified technician',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF616161)),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F5F5),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Test Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '1. Select Test Type',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2A1E),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Doorstep Service',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Grid of 6 tests with images
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 74,
                        ),
                        itemCount: _tests.length,
                        itemBuilder: (ctx, i) {
                          final t = _tests[i];
                          final name = t['name'] as String;
                          final isSelected = selectedTest == name;
                          return InkWell(
                            onTap: () => setModalState(() => selectedTest = name),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? _orange : Colors.grey.shade200,
                                  width: isSelected ? 1.8 : 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _orange.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: t['bgColor'] as Color,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.asset(
                                      t['imageAsset'] as String,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: isSelected ? _orange : const Color(0xFF1B2A1E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Lab Kit',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: _orange,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 22),

                      // Section 2: Animal Selection from Livestock
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '2. Select Animal from Livestock',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2A1E),
                            ),
                          ),
                          Text(
                            '${animals.length} In Farm',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Animal Cards with photo, name, tag
                      SizedBox(
                        height: 98,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: animals.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (ctx, i) {
                            final a = animals[i];
                            final isSelected = selectedAnimal == a['name'];
                            return InkWell(
                              onTap: () => setModalState(() => selectedAnimal = a['name']!),
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 140,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected ? _green : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _green.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            width: 38,
                                            height: 38,
                                            color: const Color(0xFFF1F8E9),
                                            child: Image.asset(
                                              a['image']!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, e, s) => const Icon(
                                                Icons.pets_rounded,
                                                color: _green,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected ? _green : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            a['species']!,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected ? Colors.white : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      a['name']!,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? _green : const Color(0xFF1B2A1E),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      a['tag']!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Section 3: Preferred Collection Date
                      const Text(
                        '3. Doorstep Sample Pickup Slot',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2A1E),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          {'title': 'Today', 'sub': 'Within 2 hrs', 'val': 'Today (Urgent)'},
                          {'title': 'Tomorrow', 'sub': '8 AM - 11 AM', 'val': 'Tomorrow (27 Sep)'},
                          {'title': 'Day After', 'sub': 'Standard', 'val': 'Day After (28 Sep)'},
                        ].map((d) {
                          final isSelected = selectedDate == d['val'];
                          return Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedDate = d['val']!),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? _orange : Colors.grey.shade200,
                                    width: isSelected ? 1.8 : 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      d['title']!,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? _orange : const Color(0xFF1B2A1E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      d['sub']!,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? _orange : Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Verified Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_user_rounded, color: _green, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'A certified veterinary technician will arrive with sterile sample vacutainers and portable cold-storage to collect samples safely at your farm.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Confirm Booking Button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9100), Color(0xFFFF6D00)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _orange.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: isBooking
                              ? null
                              : () async {
                                  setModalState(() => isBooking = true);

                                  final selectedAnimalObj = animals.firstWhere(
                                    (a) => a['name'] == selectedAnimal,
                                    orElse: () => animals.first,
                                  );

                                  final now = DateTime.now();
                                  String bookDate = now.toIso8601String().split('T')[0];
                                  if (selectedDate.contains('Tomorrow')) {
                                    bookDate = now.add(const Duration(days: 1)).toIso8601String().split('T')[0];
                                  } else if (selectedDate.contains('Day After')) {
                                    bookDate = now.add(const Duration(days: 2)).toIso8601String().split('T')[0];
                                  }

                                  try {
                                    final result = await FarmerApiService().bookDiagnosticTest(
                                      animalId: selectedAnimalObj['id'] ?? selectedAnimalObj['tag'] ?? '',
                                      animalTag: selectedAnimalObj['tag'] ?? '',
                                      testType: selectedTest,
                                      date: bookDate,
                                      slotTime: selectedDate.contains('Urgent') ? 'Within 2 hours' : '10:00 AM - 11:00 AM',
                                      notes: 'Diagnostic test booked by farmer for ${selectedAnimalObj['name']} (${selectedAnimalObj['species']})',
                                    );

                                    final booking = result['booking'] as Map<String, dynamic>? ?? result;
                                    final generatedId = (booking['bookingId'] ?? booking['id'] ?? 'TB-2026-CONFIRMED').toString();

                                    ActiveConsultationState.instance.setTestBooking(
                                      testName: selectedTest,
                                      animal: selectedAnimal,
                                      date: selectedDate,
                                      status: 'Sample Pickup Scheduled ($generatedId)',
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(sheetContext);
                                      _showBookingSuccessDialog(
                                        context,
                                        bookingId: generatedId,
                                        animalName: selectedAnimal,
                                        animalTag: selectedAnimalObj['tag'] ?? '',
                                        testType: selectedTest,
                                        slot: selectedDate,
                                      );
                                    }
                                  } catch (err) {
                                    setModalState(() => isBooking = false);
                                    final errorMsg = err.toString().replaceAll('Exception:', '').trim();
                                    if (context.mounted) {
                                      _showBookingErrorDialog(context, errorMsg);
                                    }
                                  }
                                },
                          icon: isBooking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          label: Text(
                            isBooking ? 'Booking Slot...' : 'Confirm Test Booking',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                      ),
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

  // REPORT DETAIL NAVIGATION
  void _openReportDetails(Map<String, dynamic> report) {
    final animalName = report['animalName']?.toString() ?? 'Livestock';
    final hasLiveData = report.containsKey('prescriptions') ||
        report.containsKey('vetNotes') ||
        report.containsKey('recommendedTests') ||
        report.containsKey('parameters');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(
          report: hasLiveData
              ? DiagnosticReportModel.fromCaseData(report)
              : DiagnosticReportModel.getSampleReport(animalName),
        ),
      ),
    );
  }

  void _showBookingSuccessDialog(
    BuildContext context, {
    required String bookingId,
    required String animalName,
    required String animalTag,
    required String testType,
    required String slot,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: _green, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diagnostic Slot Booked!',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Government laboratory collection scheduled',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                children: [
                  const Text(
                    'UNIQUE TEST TRACKING ID',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _green, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    bookingId,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1B2A1E)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _dialogRow('Specimen / Animal', '$animalName ($animalTag)'),
                  const Divider(height: 14),
                  _dialogRow('Investigation', testType),
                  const Divider(height: 14),
                  _dialogRow('Doorstep Slot', slot),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingErrorDialog(BuildContext context, String errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Book Test Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B2A1E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              errorMsg,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Understand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1B2A1E)),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
