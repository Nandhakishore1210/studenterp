import 'package:equatable/equatable.dart';
import 'user_profile_model.dart';

class StaffModel extends Equatable {
  final String id;
  final String profileId;
  final String employeeId;
  final String? departmentId;
  final String? designation;
  final List<String> subRoles; // subject_faculty | mentor | class_advisor
  final UserProfile? profile;
  final String? departmentName;

  const StaffModel({
    required this.id,
    required this.profileId,
    required this.employeeId,
    this.departmentId,
    this.designation,
    required this.subRoles,
    this.profile,
    this.departmentName,
  });

  bool get isFaculty      => subRoles.contains('subject_faculty');
  bool get isMentor       => subRoles.contains('mentor');
  bool get isClassAdvisor => subRoles.contains('class_advisor');

  factory StaffModel.fromMap(Map<String, dynamic> m) {
    final profileMap = m['profiles'] as Map<String, dynamic>?;
    final deptMap    = m['departments'] as Map<String, dynamic>?;
    final rolesData  = m['staff_roles'] as List?;
    final roles = rolesData?.map((r) => r['role'] as String).toList() ?? [];
    return StaffModel(
      id:             m['id'] as String,
      profileId:      m['profile_id'] as String,
      employeeId:     m['employee_id'] as String,
      departmentId:   m['department_id'] as String?,
      designation:    m['designation'] as String?,
      subRoles:       roles,
      profile:        profileMap != null ? UserProfile.fromMap(profileMap) : null,
      departmentName: deptMap?['name'] as String?,
    );
  }

  String get fullName => profile?.fullName ?? 'Unknown';
  String get email    => profile?.email ?? '';

  @override
  List<Object?> get props => [id, employeeId];
}
