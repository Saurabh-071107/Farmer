class AnimalModel {
  final String id;
  final String tagNumber;
  final String ownerId;
  final String name;
  final String species;
  final String breed;
  final double ageYears;
  final String gender;
  final String lactationStage;
  final double dailyMilkYieldLiters;
  final String photoUrl;
  final String vaccinationStatus;
  final String healthStatus;
  final Map<String, dynamic>? treatmentInfo;

  AnimalModel({
    required this.id,
    required this.tagNumber,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageYears,
    required this.gender,
    required this.lactationStage,
    required this.dailyMilkYieldLiters,
    required this.photoUrl,
    required this.vaccinationStatus,
    required this.healthStatus,
    this.treatmentInfo,
  });

  bool get isUnderTreatment {
    final lower = healthStatus.toLowerCase();
    return lower.contains('treatment') ||
        lower.contains('sick') ||
        lower.contains('examination') ||
        lower.contains('critical');
  }

  String get assetImage {
    if (photoUrl.isNotEmpty && photoUrl.startsWith('assets/')) {
      return photoUrl;
    }
    final lowerSpecies = species.toLowerCase();
    final lowerBreed = breed.toLowerCase();
    if (lowerSpecies.contains('buffalo') || lowerBreed.contains('murrah')) {
      return 'assets/images/animal_buffalo.png';
    } else if (lowerSpecies.contains('goat') || lowerSpecies.contains('sheep') || lowerBreed.contains('boer')) {
      return 'assets/images/animal_goat.png';
    }
    return 'assets/images/animal_cow.png';
  }

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['id'] ?? '',
      tagNumber: json['tagNumber'] ?? '',
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      species: json['species'] ?? 'Cow',
      breed: json['breed'] ?? '',
      ageYears: (json['ageYears'] as num?)?.toDouble() ?? 1.0,
      gender: json['gender'] ?? 'Female',
      lactationStage: json['lactationStage'] ?? 'Active',
      dailyMilkYieldLiters: (json['dailyMilkYieldLiters'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photoUrl'] ?? '',
      vaccinationStatus: json['vaccinationStatus'] ?? 'Up to Date',
      healthStatus: json['healthStatus'] ?? 'Healthy',
      treatmentInfo: json['treatmentInfo'] is Map<String, dynamic> ? json['treatmentInfo'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tagNumber': tagNumber,
      'ownerId': ownerId,
      'name': name,
      'species': species,
      'breed': breed,
      'ageYears': ageYears,
      'gender': gender,
      'lactationStage': lactationStage,
      'dailyMilkYieldLiters': dailyMilkYieldLiters,
      'photoUrl': photoUrl,
      'vaccinationStatus': vaccinationStatus,
      'healthStatus': healthStatus,
      if (treatmentInfo != null) 'treatmentInfo': treatmentInfo,
    };
  }

  AnimalModel copyWith({
    String? id,
    String? tagNumber,
    String? ownerId,
    String? name,
    String? species,
    String? breed,
    double? ageYears,
    String? gender,
    String? lactationStage,
    double? dailyMilkYieldLiters,
    String? photoUrl,
    String? vaccinationStatus,
    String? healthStatus,
    Map<String, dynamic>? treatmentInfo,
  }) {
    return AnimalModel(
      id: id ?? this.id,
      tagNumber: tagNumber ?? this.tagNumber,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      ageYears: ageYears ?? this.ageYears,
      gender: gender ?? this.gender,
      lactationStage: lactationStage ?? this.lactationStage,
      dailyMilkYieldLiters: dailyMilkYieldLiters ?? this.dailyMilkYieldLiters,
      photoUrl: photoUrl ?? this.photoUrl,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      treatmentInfo: treatmentInfo ?? this.treatmentInfo,
    );
  }
}
