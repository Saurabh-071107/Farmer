class HealthCaseModel {
  final String id;
  final String animalId;
  final String farmerId;
  final String? vetId;
  final List<String> symptoms;
  final String description;
  final List<String> photoUrls;
  final int aiRiskScore;
  final String aiPredictedDisease;
  final double aiConfidence;
  final String aiSeverity;
  final bool suspectedOutbreak;
  final String status;
  final String? vetNotes;
  final String? caseNumber;
  final String createdAt;
  final List<String> firstAid;
  final List<String> recommendedTests;
  final List<String> possibleConditions;
  final String urgencyLabel;
  final String explanation;

  HealthCaseModel({
    required this.id,
    required this.animalId,
    required this.farmerId,
    this.vetId,
    required this.symptoms,
    required this.description,
    required this.photoUrls,
    required this.aiRiskScore,
    required this.aiPredictedDisease,
    required this.aiConfidence,
    required this.aiSeverity,
    required this.suspectedOutbreak,
    required this.status,
    this.vetNotes,
    this.caseNumber,
    required this.createdAt,
    this.firstAid = const [],
    this.recommendedTests = const [],
    this.possibleConditions = const [],
    this.urgencyLabel = '',
    this.explanation = '',
  });

  String get formattedCaseId {
    if (caseNumber != null && caseNumber!.isNotEmpty) return caseNumber!;
    if (id.startsWith('CASE-')) return id;
    final digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return 'CASE-2026-${digits.substring(digits.length - 4).padLeft(6, '0')}';
    }
    return 'CASE-2026-000101';
  }

  factory HealthCaseModel.fromJson(Map<String, dynamic> json) {
    final aiAnalysis = json['aiAnalysis'] is Map<String, dynamic> ? json['aiAnalysis'] as Map<String, dynamic> : null;
    
    double confidence = (aiAnalysis?['confidence'] as num?)?.toDouble() ?? 
                        (json['aiConfidence'] as num?)?.toDouble() ?? 0.85;
    if (confidence <= 1.0) {
      confidence = confidence * 100.0;
    }

    final rawSeverity = (json['severity'] ?? aiAnalysis?['severity'] ?? aiAnalysis?['riskLevel'] ?? json['aiSeverity'] ?? 'Medium').toString();
    
    return HealthCaseModel(
      id: (json['id'] ?? json['caseId'] ?? '').toString(),
      animalId: (json['animalId'] ?? '').toString(),
      farmerId: (json['farmerId'] ?? '').toString(),
      vetId: json['vetId']?.toString(),
      symptoms: List<String>.from(json['symptoms'] ?? json['majorSymptoms'] ?? []),
      description: (json['description'] ?? json['additionalSymptoms'] ?? '').toString(),
      photoUrls: List<String>.from(json['photoUrls'] ?? (json['images'] is List ? json['images'] : [])),
      aiRiskScore: (json['aiRiskScore'] as num?)?.toInt() ?? (rawSeverity.toUpperCase() == 'CRITICAL' ? 95 : (rawSeverity.toUpperCase() == 'HIGH' ? 80 : (rawSeverity.toUpperCase() == 'MEDIUM' ? 50 : 20))),
      aiPredictedDisease: (json['preliminaryCondition'] ?? aiAnalysis?['primaryCondition'] ?? json['aiPredictedDisease'] ?? 'Veterinary Clinical Evaluation').toString(),
      aiConfidence: double.parse(confidence.toStringAsFixed(1)),
      aiSeverity: rawSeverity.toUpperCase(),
      suspectedOutbreak: json['suspectedOutbreak'] == true || rawSeverity.toUpperCase() == 'CRITICAL',
      status: (json['status'] ?? 'reported').toString(),
      vetNotes: json['vetNotes']?.toString(),
      caseNumber: (json['caseNumber'] ?? json['caseId'] ?? (json['id'] != null && json['id'].toString().startsWith('CASE-') ? json['id'].toString() : null))?.toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      firstAid: (aiAnalysis?['firstAid'] ?? json['firstAid'] as List? ?? [])
          .map<String>((e) => e.toString())
          .toList(),
      recommendedTests: (aiAnalysis?['recommendedTests'] ?? json['recommendedTests'] as List? ?? [])
          .map<String>((e) => e.toString())
          .toList(),
      possibleConditions: (aiAnalysis?['possibleConditions'] ?? json['possibleConditions'] as List? ?? [])
          .map<String>((c) {
            if (c is Map) {
              final name = c['name'] ?? c['condition'] ?? '';
              final probVal = c['probability'] as num?;
              final prob = probVal != null
                  ? '${(probVal * (probVal <= 1 ? 100 : 1)).toInt()}%'
                  : '';
              final sev = c['severity'] ?? '';
              final parts = [name, prob, sev].where((p) => p.toString().isNotEmpty).toList();
              return parts.join(' • ');
            }
            return c.toString();
          })
          .toList(),
      urgencyLabel: (aiAnalysis?['urgencyLabel'] ?? json['urgencyLabel'] ?? '').toString(),
      explanation: (aiAnalysis?['explanation'] ?? json['explanation'] ?? '').toString(),
    );
  }
}
