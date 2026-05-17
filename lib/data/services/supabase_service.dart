import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ─── Auth ──────────────────────────────────────────────────
  static Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => client.auth.signOut();

  static Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email);

  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;

  // ─── Profile ───────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final res = await client.from('profiles').select().eq('id', uid).single();
    return res;
  }

  static Future<Map<String, dynamic>?> getMyStudentRecord() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final res = await client
        .from('students')
        .select('*, profiles(*), departments(*), courses(*)')
        .eq('profile_id', uid)
        .single();
    return res;
  }

  static Future<Map<String, dynamic>?> getMyStaffRecord() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final res = await client
        .from('staff')
        .select('*, profiles(*), departments(*), staff_roles(*)')
        .eq('profile_id', uid)
        .single();
    return res;
  }

  // ─── Student: Attendance ───────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyEffectiveAttendance(
      String studentId, String academicYear, int semester) async {
    final res = await client
        .from('attendance_effective')
        .select('*, subjects(*)')
        .eq('student_id', studentId)
        .eq('academic_year', academicYear)
        .eq('semester_number', semester);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<List<Map<String, dynamic>>> getAttendanceRaw(
      String studentId, String subjectId, String academicYear) async {
    final res = await client
        .from('attendance_raw')
        .select()
        .eq('student_id', studentId)
        .eq('subject_id', subjectId)
        .eq('academic_year', academicYear)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Student: Marks ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyMarks(
      String studentId, String academicYear, int semester) async {
    final res = await client
        .from('marks')
        .select('*, subjects(*)')
        .eq('student_id', studentId)
        .eq('academic_year', academicYear)
        .eq('semester_number', semester)
        .order('entered_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Student: Timetable ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyTimetable(
      String studentId, String academicYear, int semester) async {
    final enrollments = await client
        .from('enrollments')
        .select('subject_assignment_id')
        .eq('student_id', studentId)
        .eq('academic_year', academicYear)
        .eq('semester_number', semester);

    final assignmentIds = (enrollments as List)
        .map((e) => e['subject_assignment_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (assignmentIds.isEmpty) return [];

    final res = await client
        .from('timetable')
        .select('*, subject_assignments(*, subjects(*), staff(*, profiles(*)))')
        .inFilter('subject_assignment_id', assignmentIds)
        .order('day_of_week')
        .order('period_number');
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Student: Assignments ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyAssignments(
      String studentId, String academicYear, int semester) async {
    final enrollments = await client
        .from('enrollments')
        .select('subject_assignment_id')
        .eq('student_id', studentId)
        .eq('academic_year', academicYear)
        .eq('semester_number', semester);

    final assignmentIds = (enrollments as List)
        .map((e) => e['subject_assignment_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (assignmentIds.isEmpty) return [];

    final res = await client
        .from('assignments')
        .select('*, subject_assignments(*, subjects(*)), assignment_submissions(*)')
        .inFilter('subject_assignment_id', assignmentIds)
        .order('due_date');
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Student: Materials ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyMaterials(
      String studentId, String academicYear, int semester) async {
    final enrollments = await client
        .from('enrollments')
        .select('subject_assignment_id')
        .eq('student_id', studentId)
        .eq('academic_year', academicYear)
        .eq('semester_number', semester);

    final assignmentIds = (enrollments as List)
        .map((e) => e['subject_assignment_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (assignmentIds.isEmpty) return [];

    final res = await client
        .from('study_materials')
        .select('*, subject_assignments(*, subjects(*))')
        .inFilter('subject_assignment_id', assignmentIds)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Student: Fees ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyFees(
      String studentId, String academicYear) async {
    final res = await client
        .from('fees')
        .select()
        .eq('student_id', studentId)
        .eq('academic_year', academicYear)
        .order('due_date');
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Notifications ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getNotifications(String role) async {
    final res = await client
        .from('notifications')
        .select('*, notification_reads(*)')
        .or('target_role.is.null,target_role.eq.$role')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Student: ML/OD ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyMlOd(String studentId) async {
    final res = await client
        .from('ml_od')
        .select('*, subjects(*)')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Exam Schedule ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getExamSchedule(
      String academicYear, int semester) async {
    final res = await client
        .from('exam_schedule')
        .select('*, subjects(*)')
        .eq('academic_year', academicYear)
        .eq('semester_number', semester)
        .order('exam_date');
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Staff: Subject Assignments ────────────────────────────
  static Future<List<Map<String, dynamic>>> getStaffSubjectAssignments(
      String staffId, String academicYear) async {
    final res = await client
        .from('subject_assignments')
        .select('*, subjects(*)')
        .eq('staff_id', staffId)
        .eq('academic_year', academicYear);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Staff: Enrolled students for subject ──────────────────
  static Future<List<Map<String, dynamic>>> getEnrolledStudents(
      String subjectAssignmentId) async {
    final res = await client
        .from('enrollments')
        .select('*, students(*, profiles(*), departments(*))')
        .eq('subject_assignment_id', subjectAssignmentId);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Staff: Mark attendance ────────────────────────────────
  static Future<void> upsertAttendance(List<Map<String, dynamic>> records) async {
    await client.from('attendance_raw').upsert(
      records,
      onConflict: 'student_id,subject_id,date,period_number,academic_year',
    );
  }

  // ─── Staff: Enter marks ────────────────────────────────────
  static Future<void> upsertMarks(List<Map<String, dynamic>> records) async {
    await client.from('marks').upsert(
      records,
      onConflict: 'student_id,subject_id,academic_year,semester_number,assessment_type',
    );
  }

  // ─── Staff: Reports ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getSubjectAttendanceReport(
      String subjectAssignmentId, String academicYear, int semester) async {
    final enrolled = await getEnrolledStudents(subjectAssignmentId);
    final studentIds = enrolled
        .map((e) => ((e['students'] as Map)['id'] as String))
        .toList();
    if (studentIds.isEmpty) return [];

    final assignment = await client
        .from('subject_assignments')
        .select('subject_id')
        .eq('id', subjectAssignmentId)
        .single();

    final res = await client
        .from('attendance_effective')
        .select('*, students(*, profiles(*))')
        .inFilter('student_id', studentIds)
        .eq('subject_id', assignment['subject_id'])
        .eq('academic_year', academicYear)
        .eq('semester_number', semester);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Staff/Mentor: Performa ────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMenteesPerforma(
      String staffId, String academicYear, int semester) async {
    final mappings = await client
        .from('mentor_mapping')
        .select('student_id')
        .eq('mentor_staff_id', staffId)
        .eq('academic_year', academicYear);

    final studentIds = (mappings as List)
        .map((e) => e['student_id'] as String)
        .toList();
    if (studentIds.isEmpty) return [];

    final res = await client
        .from('vw_student_performa')
        .select()
        .inFilter('student_id', studentIds)
        .eq('academic_year', academicYear)
        .eq('semester_number', semester);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Staff: Materials ──────────────────────────────────────
  static Future<void> addMaterial(Map<String, dynamic> material) async {
    await client.from('study_materials').insert(material);
  }

  // ─── Staff: Counselling ────────────────────────────────────
  static Future<void> addCounsellingNote(Map<String, dynamic> note) async {
    await client.from('counselling_notes').insert(note);
  }

  static Future<List<Map<String, dynamic>>> getCounsellingNotes(String studentId) async {
    final res = await client
        .from('counselling_notes')
        .select('*, staff(*, profiles(*))')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Admin: Users ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllProfiles({String? role, String? universityId}) async {
    // Build filter string for postgrest
    var q = client.from('profiles').select('*, students(*), staff(*)');
    List<Map<String, dynamic>> res;
    if (universityId != null && role != null) {
      res = await q.eq('university_id', universityId).eq('role', role).order('full_name');
    } else if (universityId != null) {
      res = await q.eq('university_id', universityId).order('full_name');
    } else if (role != null) {
      res = await q.eq('role', role).order('full_name');
    } else {
      res = await q.order('full_name');
    }
    return res;
  }

  static Future<void> deactivateUser(String profileId) async {
    await client.from('profiles').update({'is_active': false}).eq('id', profileId);
  }

  // ─── Admin: Department stats ───────────────────────────────
  static Future<List<Map<String, dynamic>>> getDepartmentStats(String universityId) async {
    final depts = await client
        .from('departments')
        .select('id, name, code')
        .eq('university_id', universityId)
        .order('name');
    final deptIds = (depts as List).map((d) => d['id'] as String).toList();
    if (deptIds.isEmpty) return [];

    final students = await client
        .from('students')
        .select('id, department_id')
        .inFilter('department_id', deptIds);
    final staff = await client
        .from('staff')
        .select('id, department_id')
        .inFilter('department_id', deptIds);

    return depts.map<Map<String, dynamic>>((dept) {
      final deptId = dept['id'] as String;
      return {
        ...Map<String, dynamic>.from(dept as Map),
        'student_count': (students as List).where((s) => s['department_id'] == deptId).length,
        'staff_count':   (staff as List).where((s) => s['department_id'] == deptId).length,
      };
    }).toList();
  }

  // ─── Admin: University-scoped low attendance ───────────────
  static Future<List<Map<String, dynamic>>> getLowAttendanceByUniversity(String universityId) async {
    final res = await client
        .from('vw_low_attendance')
        .select()
        .eq('university_id', universityId)
        .order('effective_percentage');
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Admin: Attendance Rules ───────────────────────────────
  static Future<Map<String, dynamic>?> getAttendanceRules(String academicYear) async {
    final res = await client
        .from('attendance_rules')
        .select()
        .eq('academic_year', academicYear)
        .maybeSingle();
    return res;
  }

  static Future<void> upsertAttendanceRules(Map<String, dynamic> rules) async {
    await client.from('attendance_rules').upsert(rules, onConflict: 'academic_year');
  }

  // ─── Admin: Analytics ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getLowAttendanceStudents() async {
    final res = await client
        .from('vw_low_attendance')
        .select()
        .order('effective_percentage');
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Calendar ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCalendar(String academicYear) async {
    final res = await client
        .from('academic_calendar')
        .select()
        .eq('academic_year', academicYear)
        .order('start_date');
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Universities ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getUniversities() async {
    final res = await client.from('universities').select().eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Admin: Create user via Edge Function ──────────────────
  static Future<String?> createUserAccount(Map<String, dynamic> payload) async {
    try {
      final res = await client.functions.invoke('create-user', body: payload);
      if (res.data?['error'] != null) return res.data!['error'] as String;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── ML/OD: Student apply ──────────────────────────────────
  static Future<String?> applyMlOd({
    required String studentId,
    required String subjectId,
    required String startDate,
    required String endDate,
    required String type,
    required String reason,
  }) async {
    try {
      await client.from('ml_od').insert({
        'student_id': studentId,
        'subject_id': subjectId,
        'start_date': startDate,
        'end_date':   endDate,
        'type':       type,
        'reason':     reason,
        'status':     'pending',
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── ML/OD: Mentor pending requests ────────────────────────
  static Future<List<Map<String, dynamic>>> getPendingMlOdForMentor(String staffId) async {
    final mappings = await client
        .from('mentor_mapping')
        .select('student_id')
        .eq('mentor_staff_id', staffId);
    final studentIds = (mappings as List).map((e) => e['student_id'] as String).toList();
    if (studentIds.isEmpty) return [];
    final res = await client
        .from('ml_od')
        .select('*, students(*, profiles(*)), subjects(*)')
        .inFilter('student_id', studentIds)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> approveMlOd(String id, String staffId) async {
    await client.from('ml_od').update({
      'status':      'approved',
      'approved_by': staffId,
    }).eq('id', id);
  }

  static Future<void> rejectMlOd(String id, String staffId) async {
    await client.from('ml_od').update({
      'status':      'rejected',
      'approved_by': staffId,
    }).eq('id', id);
  }

  // ─── Staff: Subject students with attendance % ─────────────
  static Future<List<Map<String, dynamic>>> getSubjectStudentDetails(
      String subjectAssignmentId) async {
    final assignment = await client
        .from('subject_assignments')
        .select('subject_id, academic_year, semester_number')
        .eq('id', subjectAssignmentId)
        .single();

    final subjectId    = assignment['subject_id'] as String;
    final academicYear = assignment['academic_year'] as String;
    final semester     = assignment['semester_number'] as int;

    final enrollments = await client
        .from('enrollments')
        .select('students(id, register_no, section, batch, profiles(full_name, phone, email), departments(name))')
        .eq('subject_assignment_id', subjectAssignmentId);

    final studentIds = (enrollments as List)
        .map((e) => ((e['students'] as Map)['id'] as String))
        .toList();
    if (studentIds.isEmpty) return [];

    final attendance = await client
        .from('attendance_effective')
        .select()
        .inFilter('student_id', studentIds)
        .eq('subject_id', subjectId)
        .eq('academic_year', academicYear)
        .eq('semester_number', semester);

    final attMap = {
      for (final a in (attendance as List)) a['student_id'] as String: a,
    };

    return enrollments.map<Map<String, dynamic>>((e) {
      final stu = e['students'] as Map;
      final stuId = stu['id'] as String;
      final att = attMap[stuId];
      return {
        'student_id':   stuId,
        'register_no':  stu['register_no'],
        'section':      stu['section'],
        'batch':        stu['batch'],
        'full_name':    (stu['profiles'] as Map?)?['full_name'],
        'phone':        (stu['profiles'] as Map?)?['phone'],
        'email':        (stu['profiles'] as Map?)?['email'],
        'department':   (stu['departments'] as Map?)?['name'],
        'total_classes':         att?['total_classes'] ?? 0,
        'present_count':         att?['present_count'] ?? 0,
        'effective_percentage':  att?['effective_percentage'] ?? 0.0,
        'eligibility_status':    att?['eligibility_status'] ?? 'eligible',
      };
    }).toList();
  }

  // ─── Geofence: Mark student present ────────────────────────
  static Future<String?> markGeofenceAttendance({
    required String studentId,
    required String subjectId,
    required String subjectAssignmentId,
    required String academicYear,
    required int periodNumber,
    required String date,
  }) async {
    try {
      await client.from('attendance_raw').upsert({
        'student_id':            studentId,
        'subject_id':            subjectId,
        'date':                  date,
        'period_number':         periodNumber,
        'academic_year':         academicYear,
        'status':                'present',
        'marked_via_geofence':   true,
      }, onConflict: 'student_id,subject_id,date,period_number,academic_year');
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Superadmin: University management ─────────────────────
  static Future<String?> createUniversity(Map<String, dynamic> data) async {
    try {
      await client.from('universities').insert(data);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> updateUniversity(String id, Map<String, dynamic> data) async {
    try {
      await client.from('universities').update(data).eq('id', id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> toggleUniversity(String id, bool isActive) async {
    try {
      await client.from('universities').update({'is_active': isActive}).eq('id', id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<Map<String, int>> getAllRoleCounts() async {
    final profiles = await client.from('profiles').select('role');
    final counts = <String, int>{'student': 0, 'staff': 0, 'admin': 0};
    for (final p in profiles as List) {
      final role = p['role'] as String? ?? '';
      if (counts.containsKey(role)) counts[role] = (counts[role] ?? 0) + 1;
    }
    return counts;
  }

  // ─── FCM Token ─────────────────────────────────────────────
  static Future<void> saveFcmToken(String token) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await client.from('profiles').update({'fcm_token': token}).eq('id', uid);
  }

  // ─── Storage ───────────────────────────────────────────────
  static Future<String> uploadFile(
      String bucket, String path, List<int> bytes, String mimeType) async {
    await client.storage.from(bucket).uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(contentType: mimeType),
    );
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
