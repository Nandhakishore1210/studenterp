import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/marks_model.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/ml_od_model.dart';
import '../../../data/models/student_model.dart';
import '../../../core/constants/supabase_constants.dart';

// Student record
final studentRecordProvider = FutureProvider<StudentModel?>((ref) async {
  final data = await SupabaseService.getMyStudentRecord();
  if (data == null) return null;
  return StudentModel.fromMap(data);
});

// Attendance effective
final studentAttendanceProvider = FutureProvider<List<AttendanceEffective>>((ref) async {
  final student = await ref.watch(studentRecordProvider.future);
  if (student == null) return [];
  final data = await SupabaseService.getMyEffectiveAttendance(
    student.id,
    SupabaseConstants.currentAcademicYear,
    student.currentSemester,
  );
  return data.map(AttendanceEffective.fromMap).toList();
});

// Attendance raw for a specific subject
final subjectAttendanceRawProvider = FutureProvider.family<
    List<AttendanceRaw>, ({String studentId, String subjectId})>((ref, args) async {
  final data = await SupabaseService.getAttendanceRaw(
    args.studentId, args.subjectId,
    SupabaseConstants.currentAcademicYear,
  );
  return data.map(AttendanceRaw.fromMap).toList();
});

// Marks
final studentMarksProvider = FutureProvider<List<MarksModel>>((ref) async {
  final student = await ref.watch(studentRecordProvider.future);
  if (student == null) return [];
  final data = await SupabaseService.getMyMarks(
    student.id,
    SupabaseConstants.currentAcademicYear,
    student.currentSemester,
  );
  return data.map(MarksModel.fromMap).toList();
});

// Timetable
final studentTimetableProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final student = await ref.watch(studentRecordProvider.future);
  if (student == null) return [];
  return SupabaseService.getMyTimetable(
    student.id,
    SupabaseConstants.currentAcademicYear,
    student.currentSemester,
  );
});

// Assignments
final studentAssignmentsProvider =
    FutureProvider<List<AssignmentModel>>((ref) async {
  final student = await ref.watch(studentRecordProvider.future);
  if (student == null) return [];
  final data = await SupabaseService.getMyAssignments(
    student.id,
    SupabaseConstants.currentAcademicYear,
    student.currentSemester,
  );
  return data.map(AssignmentModel.fromMap).toList();
});

// Materials
final studentMaterialsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final student = await ref.watch(studentRecordProvider.future);
  if (student == null) return [];
  return SupabaseService.getMyMaterials(
    student.id,
    SupabaseConstants.currentAcademicYear,
    student.currentSemester,
  );
});

// Notifications
final studentNotificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final data = await SupabaseService.getNotifications('student');
  return data.map(NotificationModel.fromMap).toList();
});

// Fees
final studentFeesProvider = FutureProvider<List<FeeModel>>((ref) async {
  final student = await ref.watch(studentRecordProvider.future);
  if (student == null) return [];
  final data = await SupabaseService.getMyFees(
      student.id, SupabaseConstants.currentAcademicYear);
  return data.map(FeeModel.fromMap).toList();
});

// ML/OD
final studentMlOdProvider = FutureProvider<List<MlOdModel>>((ref) async {
  final student = await ref.watch(studentRecordProvider.future);
  if (student == null) return [];
  final data = await SupabaseService.getMyMlOd(student.id);
  return data.map(MlOdModel.fromMap).toList();
});

// Exam schedule
final examScheduleProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final student = await ref.watch(studentRecordProvider.future);
  if (student == null) return [];
  return SupabaseService.getExamSchedule(
    SupabaseConstants.currentAcademicYear,
    student.currentSemester,
  );
});
