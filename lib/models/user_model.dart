class FarmerUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String farmerId;
  final String aadhaarNumber;
  final bool aadhaarVerified;
  final String village;
  final String district;
  final String state;
  final String createdAt;

  FarmerUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.farmerId,
    required this.aadhaarNumber,
    required this.aadhaarVerified,
    required this.village,
    required this.district,
    required this.state,
    required this.createdAt,
  });

  factory FarmerUser.fromJson(Map<String, dynamic> json) {
    return FarmerUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'farmer').toString(),
      farmerId: (json['farmerId'] ?? json['farmer']?['farmerId'] ?? '').toString(),
      aadhaarNumber: (json['aadhaarNumber'] ?? '').toString(),
      aadhaarVerified: json['aadhaarVerified'] == true,
      village: (json['village'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      state: (json['state'] ?? 'Maharashtra').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'farmerId': farmerId,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarVerified': aadhaarVerified,
      'village': village,
      'district': district,
      'state': state,
      'createdAt': createdAt,
    };
  }
}
