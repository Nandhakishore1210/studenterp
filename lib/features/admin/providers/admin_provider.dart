import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/constants/supabase_constants.dart';

// Admin's own university_id (derived from their profile)
final adminUniversityIdProvider = FutureProvider<String?>((ref) async {
  final profile = await SupabaseService.getMyProfile();
  return profile?['university_id'] as String?;
});

// University name for display
final adminUniversityNameProvider = FutureProvider<String?>((ref) async {
  final profile = await SupabaseService.getMyProfile();
  final uniId = profile?['university_id'] as String?;
  if (uniId == null) return null;
  final unis = await SupabaseService.getUniversities();
  return unis.where((u) => u['id'] == uniId).firstOrNull?['name'] as String?;
});

// Department stats for this university (name, code, student_count, staff_count)
final adminDeptStatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uniId = await ref.watch(adminUniversityIdProvider.future);
  if (uniId == null) return [];
  return SupabaseService.getDepartmentStats(uniId);
});

// Low attendance scoped to this university
final lowAttendanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uniId = await ref.watch(adminUniversityIdProvider.future);
  if (uniId == null) return [];
  return SupabaseService.getLowAttendanceByUniversity(uniId);
});

// All users scoped to this university
final allUsersProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, role) async {
  final uniId = await ref.watch(adminUniversityIdProvider.future);
  return SupabaseService.getAllProfiles(role: role, universityId: uniId);
});

// Attendance rules
final attendanceRulesProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return SupabaseService.getAttendanceRules(SupabaseConstants.currentAcademicYear);
});

// Academic calendar
final academicCalendarProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getCalendar(SupabaseConstants.currentAcademicYear);
});
