import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role; // student | staff | admin
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        email: m['email'] as String,
        fullName: m['full_name'] as String,
        phone: m['phone'] as String?,
        role: m['role'] as String,
        avatarUrl: m['avatar_url'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, email, role];
}
