import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/models/student_model.dart';
import '../../../core/constants/supabase_constants.dart';

// Staff record
final staffRecordProvider = FutureProvider<StaffModel?>((ref) async {
  final data = await SupabaseService.getMyStaffRecord();
  if (data == null) return null;
  return StaffModel.fromMap(data);
});

// Subject assignments for staff
final staffSubjectAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final staff = await ref.watch(staffRecordProvider.future);
  if (staff == null) return [];
  return SupabaseService.getStaffSubjectAssignments(staff.id, SupabaseConstants.currentAcademicYear);
});

// Students enrolled in a specific subject assignment
final enrolledStudentsProvider =
    FutureProvider.family<List<StudentModel>, String>((ref, subjectAssignmentId) async {
  final data = await SupabaseService.getEnrolledStudents(subjectAssignmentId);
  return data.map((e) {
    final s = e['students'] as Map<String, dynamic>;
    return StudentModel.fromMap(s);
  }).toList();
});

// Subject attendance report (for Reports tab)
final subjectReportProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, subjectAssignmentId) async {
  return SupabaseService.getSubjectAttendanceReport(
    subjectAssignmentId,
    SupabaseConstants.currentAcademicYear,
    SupabaseConstants.currentSemester,
  );
});

// Mentees performa data
final menteesPerformaProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final staff = await ref.watch(staffRecordProvider.future);
  if (staff == null || !staff.isMentor) return [];
  return SupabaseService.getMenteesPerforma(
    staff.id,
    SupabaseConstants.currentAcademicYear,
    SupabaseConstants.currentSemester,
  );
});

// Staff notifications
final staffNotificationsProvider = FutureProvider<List>((ref) async {
  return SupabaseService.getNotifications('staff');
});

// Attendance report filter state
final reportFilterProvider = StateProvider<String?>((ref) => null); // null=all, 'below65', '65to75', 'above75'
