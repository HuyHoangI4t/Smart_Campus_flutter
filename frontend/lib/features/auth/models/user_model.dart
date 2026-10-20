class UserModel {
  final int id;
  final String studentId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? studentClass;
  final String? faculty;
  final String? avatarUrl;
  final String role;

  const UserModel({
    required this.id,
    required this.studentId,
    required this.fullName,
    this.email,
    this.phone,
    this.studentClass,
    this.faculty,
    this.avatarUrl,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      studentId: json['student_id'] ?? json['studentId'] ?? json['mssv'] ?? json['masv'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? json['ho_ten'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? json['so_dien_thoai'],
      studentClass: json['class_name'] ?? json['class'] ?? json['studentClass'] ?? json['lop'],
      faculty: json['faculty'] ?? json['khoa'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? json['avatar'],
      role: json['role'] ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'mssv': studentId,
      'full_name': fullName,
      'ho_ten': fullName,
      'email': email,
      'phone': phone,
      'so_dien_thoai': phone,
      'class_name': studentClass,
      'lop': studentClass,
      'faculty': faculty,
      'khoa': faculty,
      'avatar_url': avatarUrl,
      'avatar': avatarUrl,
      'role': role,
    };
  }

  static UserModel guest() {
    return const UserModel(
      id: 0,
      studentId: 'GUEST',
      fullName: 'Khách tham quan',
      role: 'guest',
    );
  }

  bool get isGuest => role == 'guest' || studentId == 'GUEST';

  UserModel copyWith({
    int? id,
    String? studentId,
    String? fullName,
    String? email,
    String? phone,
    String? studentClass,
    String? faculty,
    String? avatarUrl,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      studentClass: studentClass ?? this.studentClass,
      faculty: faculty ?? this.faculty,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }
}

