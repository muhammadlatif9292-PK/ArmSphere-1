class AthleteModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final double? weightKg;
  final double? heightCm;
  final double? reachCm;
  final String? armDominance;
  final String? clubName;
  final String? province;
  final bool isOnboarded;

  AthleteModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.weightKg,
    this.heightCm,
    this.reachCm,
    this.armDominance,
    this.clubName,
    this.province,
    required this.isOnboarded,
  });

  factory AthleteModel.fromJson(Map<String, dynamic> json) {
    return AthleteModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      reachCm: (json['reachCm'] as num?)?.toDouble(),
      armDominance: json['armDominance']?.toString(),
      clubName: json['clubName']?.toString(),
      province: json['province']?.toString(),
      isOnboarded: json['isOnboarded'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'reachCm': reachCm,
      'armDominance': armDominance,
      'clubName': clubName,
      'province': province,
      'isOnboarded': isOnboarded,
    };
  }
}
