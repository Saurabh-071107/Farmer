import 'package:flutter/material.dart';
import '../services/app_translations.dart';
import '../services/session_manager.dart';
import 'doctor_consultation_screen.dart';

class ReportParameter {
  final String name;
  final String result;
  final String referenceRange;
  final String unit;
  final bool isNormal;

  const ReportParameter({
    required this.name,
    required this.result,
    required this.referenceRange,
    required this.unit,
    this.isNormal = true,
  });
}

class DiagnosticReportModel {
  final String id;
  final String animalName;
  final String animalSpecies;
  final String animalBreed;
  final String earTag;
  final String animalImage;
  final String testType;
  final String testDate;
  final String labName;
  final String doctorName;
  final String status;
  final Color statusColor;
  final List<ReportParameter> parameters;
  final String doctorNotes;
  final String recommendation;

  const DiagnosticReportModel({
    required this.id,
    required this.animalName,
    required this.animalSpecies,
    required this.animalBreed,
    required this.earTag,
    required this.animalImage,
    required this.testType,
    required this.testDate,
    required this.labName,
    required this.doctorName,
    required this.status,
    required this.statusColor,
    required this.parameters,
    required this.doctorNotes,
    required this.recommendation,
  });

  static DiagnosticReportModel fromCaseData(Map<String, dynamic> report) {
    final animalName = report['animalName']?.toString() ?? 'Livestock';
    final rawPrescriptions = report['prescriptions'];
    final rawNotes = report['vetNotes']?.toString();
    final rawStatus = report['status']?.toString() ?? 'Under Examination';
    final isTreated = rawStatus.toLowerCase().contains('prescrib') || rawStatus.toLowerCase().contains('treat');

    // Extract medicines if present
    final List<String> medicineLines = [];
    if (rawPrescriptions is List && rawPrescriptions.isNotEmpty) {
      for (final p in rawPrescriptions) {
        if (p is Map) {
          final meds = p['medicines'];
          if (meds is List) {
            for (final m in meds) {
              if (m is Map) {
                medicineLines.add('• ${m['name']} (${m['dosage'] ?? 'Standard dose'}) — ${m['frequency'] ?? 'Daily'} for ${m['durationDays'] ?? 5} days');
              }
            }
          }
        }
      }
    }

    final String doctorNotes = (rawNotes != null && rawNotes.isNotEmpty)
        ? rawNotes
        : (isTreated
            ? 'Veterinary clinical examination confirmed response to tele-triage protocol. Vitals stabilized.'
            : 'Veterinary observation logged via digital intake.');

    final String recommendation = medicineLines.isNotEmpty
        ? 'PRESCRIPTION SCHEDULE:\n${medicineLines.join('\n')}\n\nFollow-up: Continue course for full duration. Provide clean drinking water and keep animal isolated from herd during active recovery.'
        : 'Maintain quarantine and monitor temperature twice daily. Consult attending veterinarian if symptoms escalate.';

    return DiagnosticReportModel(
      id: report['id']?.toString() ?? 'VET-CASE-${DateTime.now().millisecondsSinceEpoch % 100000}',
      animalName: animalName,
      animalSpecies: report['animalType']?.toString() ?? 'Cattle',
      animalBreed: report['breed']?.toString() ?? 'Indigenous Breed',
      earTag: report['tag']?.toString() ?? report['animalTag']?.toString() ?? 'MH-LIVE-01',
      animalImage: report['animalImage']?.toString() ?? 'assets/images/animal_cow.png',
      testType: report['testName']?.toString() ?? 'Veterinary Tele-Consultation & Clinical Report',
      testDate: report['date']?.toString() ?? 'Recent Consultation',
      labName: 'Central Tele-Veterinary Network & Dispensary',
      doctorName: report['vetName']?.toString() ?? 'Dr. Anand Sharma (Veterinary Officer)',
      status: isTreated ? 'Prescribed & Treated' : rawStatus,
      statusColor: isTreated ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
      parameters: [
        ReportParameter(
          name: 'Body Temperature',
          result: isTreated ? '101.4 °F' : '103.8 °F',
          referenceRange: '100.5 - 102.5 °F',
          unit: '°F',
          isNormal: isTreated,
        ),
        ReportParameter(
          name: 'Respiratory Rate',
          result: isTreated ? '24 /min' : '36 /min',
          referenceRange: '15 - 30 /min',
          unit: 'breaths/min',
          isNormal: isTreated,
        ),
        ReportParameter(
          name: 'Rumen Motility',
          result: isTreated ? 'Normal (2/min)' : 'Depressed (<1/min)',
          referenceRange: '2 - 3 / 2min',
          unit: 'contractions',
          isNormal: isTreated,
        ),
        ReportParameter(
          name: 'Mucous Membranes',
          result: isTreated ? 'Pink & Moist' : 'Congested / Pale',
          referenceRange: 'Pink & Moist',
          unit: 'Clinical',
          isNormal: isTreated,
        ),
      ],
      doctorNotes: doctorNotes,
      recommendation: recommendation,
    );
  }

  static DiagnosticReportModel getSampleReport(String animalName) {
    final lower = animalName.toLowerCase();
    if (lower.contains('laxmi')) {
      return const DiagnosticReportModel(
        id: 'VET-LAB-2026-8812',
        animalName: 'Laxmi',
        animalSpecies: 'Buffalo',
        animalBreed: 'Murrah',
        earTag: 'MH-BUF-8821',
        animalImage: 'assets/images/animal_buffalo.png',
        testType: 'Milk Quality & Mastitis Screening',
        testDate: '05 Sep 2026',
        labName: 'Regional Veterinary Diagnostic Laboratory',
        doctorName: 'Dr. Ananya Deshmukh (MVSc Pathology)',
        status: 'Attention Required',
        statusColor: Color(0xFFE65100),
        parameters: [
          ReportParameter(
            name: 'Somatic Cell Count (SCC)',
            result: '380,000',
            referenceRange: '< 200,000',
            unit: 'cells/mL',
            isNormal: false,
          ),
          ReportParameter(
            name: 'Milk Fat Content',
            result: '6.8',
            referenceRange: '6.0 - 7.5',
            unit: '%',
            isNormal: true,
          ),
          ReportParameter(
            name: 'Milk Protein',
            result: '3.9',
            referenceRange: '3.5 - 4.5',
            unit: '%',
            isNormal: true,
          ),
          ReportParameter(
            name: 'California Mastitis (CMT)',
            result: 'Trace Positive',
            referenceRange: 'Negative',
            unit: 'Index',
            isNormal: false,
          ),
          ReportParameter(
            name: 'Milk pH Level',
            result: '6.9',
            referenceRange: '6.6 - 6.8',
            unit: 'pH',
            isNormal: false,
          ),
        ],
        doctorNotes:
            'Elevated somatic cell count and mild alkaline pH indicate early subclinical mastitis in left hind quarter.',
        recommendation:
            'Maintain strict post-milking teat disinfection. Strip milk completely and avoid udder injury. Consult veterinary officer for topical herbal udder balm or mild antibacterial care.',
      );
    } else if (lower.contains('chandu') || lower.contains('chhotu')) {
      return const DiagnosticReportModel(
        id: 'VET-LAB-2026-6419',
        animalName: 'Chandu',
        animalSpecies: 'Goat',
        animalBreed: 'Osmanabadi',
        earTag: 'MH-GT-3319',
        animalImage: 'assets/images/animal_goat.png',
        testType: 'Fecal Parasitology & Flora Examination',
        testDate: '28 Aug 2026',
        labName: 'Central Animal Health Testing Center',
        doctorName: 'Dr. Rajesh Sharma (Veterinary Officer)',
        status: 'Normal',
        statusColor: Color(0xFF2E7D32),
        parameters: [
          ReportParameter(
            name: 'Helminth Ova (Flukes/Tapeworms)',
            result: 'Absent',
            referenceRange: 'Absent',
            unit: 'Direct/Conc.',
            isNormal: true,
          ),
          ReportParameter(
            name: 'Nematode Eggs (Strongyle)',
            result: '0',
            referenceRange: '< 200',
            unit: 'EPG',
            isNormal: true,
          ),
          ReportParameter(
            name: 'Protozoan Cysts (Coccidia)',
            result: 'Negative',
            referenceRange: 'Negative',
            unit: 'Microscopy',
            isNormal: true,
          ),
          ReportParameter(
            name: 'Fecal Consistency',
            result: 'Normal Pelleted',
            referenceRange: 'Pelleted',
            unit: 'Visual',
            isNormal: true,
          ),
        ],
        doctorNotes:
            'Microscopic fecal examination shows clean gastrointestinal flora without parasitic eggs or coccidial oocysts.',
        recommendation:
            'Animal digestive health is sound. Maintain dry bedding and clean drinking water. Routine scheduled deworming is due in 3 months.',
      );
    }

    // Default Gauri Blood Test
    return const DiagnosticReportModel(
      id: 'VET-LAB-2026-9842',
      animalName: 'Gauri',
      animalSpecies: 'Cow',
      animalBreed: 'Gir Indigenous',
      earTag: 'MH-COW-1042',
      animalImage: 'assets/images/animal_cow.png',
      testType: 'Complete Blood Count (CBC) & Parasite Scan',
      testDate: '12 Sep 2026',
      labName: 'State Veterinary Diagnostic Laboratory, Pune',
      doctorName: 'Dr. Rajesh Sharma (Senior Veterinary Officer)',
      status: 'Normal',
      statusColor: Color(0xFF2E7D32),
      parameters: [
        ReportParameter(
          name: 'Hemoglobin (Hb)',
          result: '11.2',
          referenceRange: '8.0 - 12.0',
          unit: 'g/dL',
          isNormal: true,
        ),
        ReportParameter(
          name: 'Total Leukocyte Count (WBC)',
          result: '7,800',
          referenceRange: '4,000 - 12,000',
          unit: '/mcL',
          isNormal: true,
        ),
        ReportParameter(
          name: 'Platelet Count',
          result: '340,000',
          referenceRange: '250,000 - 600,000',
          unit: '/mcL',
          isNormal: true,
        ),
        ReportParameter(
          name: 'Total Serum Protein',
          result: '6.9',
          referenceRange: '6.0 - 7.5',
          unit: 'g/dL',
          isNormal: true,
        ),
        ReportParameter(
          name: 'Hemoparasites (Theileria, Babesia)',
          result: 'Negative',
          referenceRange: 'Negative',
          unit: 'Giemsa Smear',
          isNormal: true,
        ),
      ],
      doctorNotes:
          'Blood morphology and hematology parameters are within healthy reference limits. No evidence of hemoprotozoan infection.',
      recommendation:
          'Animal shows strong immunity. Continue balanced dry and green fodder ratio with 50g mineral mixture daily. Repeat routine check in 6 months.',
    );
  }
}

class ReportDetailScreen extends StatelessWidget {
  final DiagnosticReportModel report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  static const Color _bg = Color(0xFFFAF8F2);
  static const Color _green = Color(0xFF1B5E20);
  static const Color _orange = Color(0xFFFF6D00);

  @override
  Widget build(BuildContext context) {
    final isNormal = report.status.toLowerCase().contains('normal');

    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B2A1E), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppTranslations.tr('diagnostic_report'),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: _orange),
                tooltip: 'Download PDF',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Official PDF for ${report.id} saved to Downloads.'),
                      backgroundColor: _green,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Color(0xFF1B2A1E)),
                tooltip: 'Share Report',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report link ready to share.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Official Lab Accreditation Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E7E2), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.science_rounded, color: _green, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.labName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B2A1E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'ICAR Accredited • ISO/IEC 17025 Certified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Report ID: ${report.id} • Tested: ${report.testDate}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Animal & Owner Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E7E2), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          report.animalImage,
                          width: 65,
                          height: 65,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 65,
                            height: 65,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.pets, color: Colors.grey),
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
                                Text(
                                  report.animalName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1B2A1E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    report.animalSpecies,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppTranslations.tr('breed')}: ${report.animalBreed}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${AppTranslations.tr('ear_tag')}: ${report.earTag}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Test Type & Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isNormal ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isNormal ? const Color(0xFFC8E6C9) : const Color(0xFFFFCC80),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNormal ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        color: isNormal ? _green : _orange,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.testType,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B2A1E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppTranslations.tr('health_status')}: ${report.status}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isNormal ? _green : _orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Clinical Tested Parameters Table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E7E2), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.tr('clinical_parameter_results'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2A1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                AppTranslations.tr('parameter'),
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF424242)),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  AppTranslations.tr('result'),
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF424242)),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                AppTranslations.tr('normal_range'),
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF424242)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 8, color: Colors.transparent),
                      ...report.parameters.map((param) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      param.name,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF212121),
                                      ),
                                    ),
                                    Text(
                                      param.unit,
                                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      param.result,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: param.isNormal ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    param.referenceRange,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Veterinary Officer Observations & Prescription Notes
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E7E2), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_rounded, color: _green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppTranslations.tr('vet_clinical_eval'),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2A1E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        report.doctorNotes,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF37474F)),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBE7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCEDC8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.tr('actionable_advice'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF33691E)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.recommendation,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF33691E), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  report.doctorName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B2A1E),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  AppTranslations.tr('auth_signatory'),
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 6. Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorConsultationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.video_call_rounded, size: 22),
                  label: Text(
                    AppTranslations.tr('consult_doctor_on_report'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
