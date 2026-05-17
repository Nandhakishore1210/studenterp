import 'package:equatable/equatable.dart';
import 'attendance_model.dart';

class MarksModel extends Equatable {
  final String id;
  final String studentId;
  final String subjectId;
  final String academicYear;
  final int semesterNumber;
  final String assessmentType;
  final double maxMarks;
  final double? obtainedMarks;
  final DateTime enteredAt;
  final SubjectInfo? subject;

  const MarksModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.academicYear,
    required this.semesterNumber,
    required this.assessmentType,
    required this.maxMarks,
    this.obtainedMarks,
    required this.enteredAt,
    this.subject,
  });

  factory MarksModel.fromMap(Map<String, dynamic> m) {
    final subMap = m['subjects'] as Map<String, dynamic>?;
    return MarksModel(
      id:             m['id'] as String,
      studentId:      m['student_id'] as String,
      subjectId:      m['subject_id'] as String,
      academicYear:   m['academic_year'] as String,
      semesterNumber: m['semester_number'] as int,
      assessmentType: m['assessment_type'] as String,
      maxMarks:       (m['max_marks'] as num).toDouble(),
      obtainedMarks:  (m['obtained_marks'] as num?)?.toDouble(),
      enteredAt:      DateTime.parse(m['entered_at'] as String),
      subject:        subMap != null ? SubjectInfo.fromMap(subMap) : null,
    );
  }

  double get percentage =>
      maxMarks > 0 ? ((obtainedMarks ?? 0) / maxMarks) * 100 : 0;

  String get displayAssessment {
    const labels = {
      'CIA1': 'CIA I', 'CIA2': 'CIA II', 'CIA3': 'CIA III',
      'assignment': 'Assignment', 'practical': 'Practical',
      'model': 'Model Exam', 'semester': 'Semester Exam',
    };
    return labels[assessmentType] ?? assessmentType;
  }

  @override
  List<Object?> get props => [id, studentId, subjectId, assessmentType, academicYear];
}
