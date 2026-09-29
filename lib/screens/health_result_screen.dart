import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/animal_model.dart';
import '../models/health_case_model.dart';
import '../widgets/floating_nav_bar.dart';
import 'doctor_consultation_screen.dart';
import 'tests_and_reports_screen.dart';

class HealthResultScreen extends StatefulWidget {
  final HealthCaseModel caseResult;
  final AnimalModel animal;
  final int navIndex;

  const HealthResultScreen({
    super.key,
    required this.caseResult,
    required this.animal,
    this.navIndex = 1,
  });

  @override
  State<HealthResultScreen> createState() => _HealthResultScreenState();
}

class _HealthResultScreenState extends State<HealthResultScreen>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFFFCFAF5);
  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);

  final FlutterTts _flutterTts = FlutterTts();
  bool _isReading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulse;
  late AnimationController _fadeController;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _initTts();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-IN');
    } catch (_) {
      try {
        await _flutterTts.setLanguage('en-US');
      } catch (_) {}
    }
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isReading = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isReading = false);
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isReading = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => _isReading = false);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  HealthCaseModel get _case => widget.caseResult;

  Color get _severityColor {
    final sev = _case.aiSeverity.toLowerCase();
    if (sev.contains('critical') || sev.contains('high')) {
      return const Color(0xFFC62828);
    } else if (sev.contains('medium') || sev.contains('moderate')) {
      return _orange;
    }
    return _green;
  }

  Color get _severityBg {
    final sev = _case.aiSeverity.toLowerCase();
    if (sev.contains('critical') || sev.contains('high')) {
      return const Color(0xFFFFEBEE);
    } else if (sev.contains('medium') || sev.contains('moderate')) {
      return const Color(0xFFFFF3E0);
    }
    return const Color(0xFFE8F5E9);
  }

  IconData get _severityIcon {
    final sev = _case.aiSeverity.toLowerCase();
    if (sev.contains('critical') || sev.contains('high')) {
      return Icons.warning_rounded;
    } else if (sev.contains('medium') || sev.contains('moderate')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.check_circle_rounded;
  }

  String get _readAloudText {
    final name = widget.animal.name;
    final disease = _case.aiPredictedDisease.isEmpty
        ? 'Not determined'
        : _case.aiPredictedDisease;
    final severity = _case.aiSeverity;
    final outbreak =
        _case.suspectedOutbreak ? 'Warning: There is a suspected outbreak risk.' : '';
    return 'Health analysis for $name. Suspected condition: $disease. '
        'Severity level: $severity. '
        '${_case.symptoms.isNotEmpty ? 'Reported symptoms include: ${_case.symptoms.join(', ')}.' : ''} '
        '$outbreak '
        'Please consult a veterinarian for appropriate care.';
  }

  Future<void> _toggleReadAloud() async {
    if (_isReading) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isReading = false);
    } else {
      final text = _readAloudText;
      if (text.isNotEmpty) {
        if (mounted) setState(() => _isReading = true);
        await _flutterTts.speak(text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final disease = _case.aiPredictedDisease.isEmpty
        ? 'Under Evaluation'
        : _case.aiPredictedDisease;

    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: _bg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.popUntil(context, (r) => r.isFirst),
                          icon: const Icon(Icons.home_rounded, size: 20),
                          label: const Text(
                            'Go Home',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _green,
                            side: const BorderSide(
                                color: Color(0xFF2E7D32), width: 1.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorConsultationScreen(
                                  animal: widget.animal,
                                  initialTabIndex: 0,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.medical_services_rounded,
                              size: 19, color: Colors.white),
                          label: const Text(
                            'Connect Vet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FloatingNavBar(
                currentIndex: widget.navIndex,
                onTap: (_) => Navigator.popUntil(context, (r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: Color(0xFF263238), size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Analysis Result',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2A1E),
                        ),
                      ),
                    ),
                    // Read Aloud button
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, child) => Transform.scale(
                        scale: _isReading ? _pulse.value : 1.0,
                        child: child,
                      ),
                      child: GestureDetector(
                        onTap: _toggleReadAloud,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _isReading
                                ? _green
                                : const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _green.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isReading
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                size: 16,
                                color: _isReading ? Colors.white : _green,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isReading ? 'Stop' : 'Read Aloud',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _isReading ? Colors.white : _green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ── Animal mini card ─────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          widget.animal.assetImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            color: const Color(0xFFE8F5E9),
                            child: const Icon(Icons.pets, color: _green, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.animal.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B2A1E))),
                          Text(
                              '${widget.animal.species}  •  ${widget.animal.tagNumber}',
                              style: const TextStyle(
                                  fontSize: 12.5, color: Color(0xFF757575))),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Case ID: ${_case.formattedCaseId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Analyzed',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _green)),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 16),

                // ── Severity badge (big) ─────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _severityBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _severityColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _severityColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(_severityIcon, color: _severityColor, size: 48),
                      const SizedBox(height: 10),
                      Text(
                        disease,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _severityColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _severityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Severity: ${_case.aiSeverity}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _severityColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_case.aiConfidence.toInt()}% AI Confidence',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _green,
                              ),
                            ),
                          ),
                          if (_case.urgencyLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _orange.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _case.urgencyLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Symptoms Reported ────────────────────
                if (_case.symptoms.isNotEmpty) ...[
                  _sectionTitle('Symptoms Reported'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _case.symptoms
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _orange.withValues(alpha: 0.4)),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _orange,
                                  )),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Description given ────────────────────
                if (_case.description.isNotEmpty) ...[
                  _sectionTitle('Description Provided'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      _case.description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Outbreak warning ─────────────────────
                if (_case.suspectedOutbreak) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFEF9A9A), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.coronavirus_rounded,
                            color: Color(0xFFC62828), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Potential Outbreak Risk Detected',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFC62828))),
                              SizedBox(height: 3),
                              Text(
                                'Symptoms may indicate a contagious disease. Isolate the animal and notify your local Veterinary Division immediately.',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFFB71C1C),
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── AI Clinical Diagnostic Summary ──────────
                _buildClinicalExplanationCard(),

                // ── Differential Diagnoses ───────────────────
                _buildPossibleConditionsCard(),

                // ── Immediate First-Aid Protocol ─────────────
                _buildFirstAidCard(),

                // ── Recommended Diagnostic Tests ─────────────
                _buildRecommendedTestsCard(),

                // ── Recommendations ──────────────────────
                _sectionTitle('General Management Recommendations'),
                const SizedBox(height: 8),
                ..._recommendations.map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (r['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(r['icon'] as IconData,
                              color: r['color'] as Color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['title'] as String,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1B2A1E))),
                              const SizedBox(height: 3),
                              Text(r['desc'] as String,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF757575),
                                      height: 1.4)),
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
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _recommendations {
    final risk = _case.aiRiskScore;
    if (risk > 70) {
      return [
        {
          'icon': Icons.emergency_rounded,
          'title': 'Immediate Veterinary Attention',
          'desc':
              'Risk level is high. Contact a licensed veterinarian within 24 hours.',
          'color': const Color(0xFFC62828),
        },
        {
          'icon': Icons.shield_rounded,
          'title': 'Isolate the Animal',
          'desc':
              'Keep the animal away from the rest of the herd to prevent spread.',
          'color': _orange,
        },
        {
          'icon': Icons.water_drop_rounded,
          'title': 'Ensure Hydration',
          'desc':
              'Provide clean water frequently. Monitor feeding intake closely.',
          'color': Colors.teal,
        },
      ];
    } else if (risk > 40) {
      return [
        {
          'icon': Icons.monitor_heart_rounded,
          'title': 'Monitor Closely',
          'desc':
              'Observe the animal for 24-48 hours and track any worsening symptoms.',
          'color': _orange,
        },
        {
          'icon': Icons.vaccines_rounded,
          'title': 'Check Vaccination Status',
          'desc':
              'Ensure all vaccinations are up to date for the current season.',
          'color': Colors.indigo,
        },
        {
          'icon': Icons.restaurant_rounded,
          'title': 'Adjust Diet',
          'desc':
              'Ensure balanced nutrition and avoid abrupt diet changes.',
          'color': _green,
        },
      ];
    } else {
      return [
        {
          'icon': Icons.check_circle_rounded,
          'title': 'Low Risk Detected',
          'desc':
              'The animal appears mostly healthy. Continue routine monitoring.',
          'color': _green,
        },
        {
          'icon': Icons.calendar_month_rounded,
          'title': 'Schedule Routine Checkup',
          'desc':
              'Book a preventive consultation with your area veterinarian.',
          'color': Colors.teal,
        },
      ];
    }
  }

  Widget _buildClinicalExplanationCard() {
    if (_case.explanation.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
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
          Row(
            children: const [
              Icon(Icons.psychology_rounded, color: _orange, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Clinical Diagnostic Summary',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2A1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _case.explanation,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: Color(0xFF37474F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPossibleConditionsCard() {
    if (_case.possibleConditions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
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
          Row(
            children: const [
              Icon(Icons.format_list_bulleted_rounded, color: _green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Differential Diagnosis (Possibilities)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2A1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._case.possibleConditions.map((cond) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bubble_chart_rounded, size: 16, color: _orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cond,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFirstAidCard() {
    if (_case.firstAid.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.medical_services_rounded, color: _green, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Immediate First-Aid Protocol',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Critical emergency actions to perform before veterinarian arrival:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF33691E),
            ),
          ),
          const SizedBox(height: 12),
          ..._case.firstAid.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendedTestsCard() {
    if (_case.recommendedTests.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
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
          Row(
            children: const [
              Icon(Icons.biotech_rounded, color: Colors.indigo, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommended Diagnostic Tests',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2A1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirm clinical findings with authorized veterinary diagnostic tests:',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF546E7A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: _case.recommendedTests.map((test) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC5CAE9)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.science_rounded, size: 16, color: Colors.indigo),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        test,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.indigo,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TestsAndReportsScreen(initialCategoryIndex: 0),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text(
                'Book Recommended Lab Test',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                side: const BorderSide(color: Colors.indigo, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1B2A1E),
      ),
    );
  }
}
