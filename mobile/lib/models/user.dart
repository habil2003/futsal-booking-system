class User {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profileImage;
  final String role;
  final bool isApproved;
  final DateTime? createdAt;  // ← ADD

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profileImage,
    required this.role,
    required this.isApproved,
    this.createdAt,  // ← ADD
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      role: json['role'],
      isApproved: json['isApproved'],
      createdAt: json['createdAt'] != null  // ← ADD
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'role': role,
      'isApproved': isApproved,
      'createdAt': createdAt?.toIso8601String(),  // ← ADD
    };
  }
}


