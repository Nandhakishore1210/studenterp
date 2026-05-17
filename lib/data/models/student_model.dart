import 'package:equatable/equatable.dart';
import 'user_profile_model.dart';

class StudentModel extends Equatable {
  final String id;
  final String profileId;
  final String registerNo;
  final String? departmentId;
  final String? courseId;
  final int currentSemester;
  final String batch;
  final String? section;
  final UserProfile? profile;
  final String? departmentName;
  final String? courseName;

  const StudentModel({
    required this.id,
    required this.profileId,
    required this.registerNo,
    this.departmentId,
    this.courseId,
    required this.currentSemester,
    required this.batch,
    this.section,
    this.profile,
    this.departmentName,
    this.courseName,
  });

  factory StudentModel.fromMap(Map<String, dynamic> m) {
    final profileMap = m['profiles'] as Map<String, dynamic>?;
    final deptMap    = m['departments'] as Map<String, dynamic>?;
    final courseMap  = m['courses'] as Map<String, dynamic>?;
    return StudentModel(
      id:              m['id'] as String,
      profileId:       m['profile_id'] as String,
      registerNo:      m['register_no'] as String,
      departmentId:    m['department_id'] as String?,
      courseId:        m['course_id'] as String?,
      currentSemester: m['current_semester'] as int? ?? 1,
      batch:           m['batch'] as String? ?? '',
      section:         m['section'] as String?,
      profile:         profileMap != null ? UserProfile.fromMap(profileMap) : null,
      departmentName:  deptMap?['name'] as String?,
      courseName:      courseMap?['name'] as String?,
    );
  }

  String get fullName => profile?.fullName ?? 'Unknown';
  String get email    => profile?.email ?? '';
  String get avatarUrl => profile?.avatarUrl ?? '';

  @override
  List<Object?> get props => [id, registerNo];
}
