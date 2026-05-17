import 'package:equatable/equatable.dart';

class AttendanceEffective extends Equatable {
  final String id;
  final String studentId;
  final String subjectId;
  final String academicYear;
  final int semesterNumber;
  final int totalClasses;
  final int presentCount;
  final double rawPercentage;
  final int mlOdCount;
  final int effectivePresentCount;
  final double effectivePercentage;
  final bool isMlOdApplicable;
  final String eligibilityStatus; // eligible | at_risk | detained
  final DateTime lastCalculatedAt;
  final SubjectInfo? subject;

  const AttendanceEffective({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.academicYear,
    required this.semesterNumber,
    required this.totalClasses,
    required this.presentCount,
    required this.rawPercentage,
    required this.mlOdCount,
    required this.effectivePresentCount,
    required this.effectivePercentage,
    required this.isMlOdApplicable,
    required this.eligibilityStatus,
    required this.lastCalculatedAt,
    this.subject,
  });

  factory AttendanceEffective.fromMap(Map<String, dynamic> m) {
    final subMap = m['subjects'] as Map<String, dynamic>?;
    return AttendanceEffective(
      id:                    m['id'] as String,
      studentId:             m['student_id'] as String,
      subjectId:             m['subject_id'] as String,
      academicYear:          m['academic_year'] as String,
      semesterNumber:        m['semester_number'] as int,
      totalClasses:          m['total_classes'] as int? ?? 0,
      presentCount:          m['present_count'] as int? ?? 0,
      rawPercentage:         (m['raw_percentage'] as num?)?.toDouble() ?? 0.0,
      mlOdCount:             m['ml_od_count'] as int? ?? 0,
      effectivePresentCount: m['effective_present_count'] as int? ?? 0,
      effectivePercentage:   (m['effective_percentage'] as num?)?.toDouble() ?? 0.0,
      isMlOdApplicable:      m['is_ml_od_applicable'] as bool? ?? false,
      eligibilityStatus:     m['eligibility_status'] as String? ?? 'eligible',
      lastCalculatedAt:      DateTime.parse(m['last_calculated_at'] as String),
      subject:               subMap != null ? SubjectInfo.fromMap(subMap) : null,
    );
  }

  @override
  List<Object?> get props => [id, studentId, subjectId, academicYear];
}

class SubjectInfo extends Equatable {
  final String id;
  final String code;
  final String name;

  const SubjectInfo({required this.id, required this.code, required this.name});

  factory SubjectInfo.fromMap(Map<String, dynamic> m) => SubjectInfo(
        id:   m['id'] as String,
        code: m['code'] as String,
        name: m['name'] as String,
      );

  @override
  List<Object?> get props => [id];
}

class AttendanceRaw extends Equatable {
  final String id;
  final String studentId;
  final String subjectId;
  final DateTime date;
  final int? periodNumber;
  final String status; // present | absent | late | od
  final String academicYear;

  const AttendanceRaw({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.date,
    this.periodNumber,
    required this.status,
    required this.academicYear,
  });

  factory AttendanceRaw.fromMap(Map<String, dynamic> m) => AttendanceRaw(
        id:           m['id'] as String,
        studentId:    m['student_id'] as String,
        subjectId:    m['subject_id'] as String,
        date:         DateTime.parse(m['date'] as String),
        periodNumber: m['period_number'] as int?,
        status:       m['status'] as String,
        academicYear: m['academic_year'] as String,
      );

  bool get isPresent => status == 'present' || status == 'late' || status == 'od';

  @override
  List<Object?> get props => [id];
}
