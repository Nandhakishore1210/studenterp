import 'package:equatable/equatable.dart';
import 'attendance_model.dart';

class AssignmentModel extends Equatable {
  final String id;
  final String subjectAssignmentId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final double? maxMarks;
  final DateTime createdAt;
  final SubjectInfo? subject;
  final AssignmentSubmission? mySubmission;

  const AssignmentModel({
    required this.id,
    required this.subjectAssignmentId,
    required this.title,
    this.description,
    required this.dueDate,
    this.maxMarks,
    required this.createdAt,
    this.subject,
    this.mySubmission,
  });

  factory AssignmentModel.fromMap(Map<String, dynamic> m) {
    final assignmentMap = m['subject_assignments'] as Map<String, dynamic>?;
    final subjectMap    = assignmentMap?['subjects'] as Map<String, dynamic>?;
    final submissions   = m['assignment_submissions'] as List?;
    return AssignmentModel(
      id:                   m['id'] as String,
      subjectAssignmentId:  m['subject_assignment_id'] as String,
      title:                m['title'] as String,
      description:          m['description'] as String?,
      dueDate:              DateTime.parse(m['due_date'] as String),
      maxMarks:             (m['max_marks'] as num?)?.toDouble(),
      createdAt:            DateTime.parse(m['created_at'] as String),
      subject:              subjectMap != null ? SubjectInfo.fromMap(subjectMap) : null,
      mySubmission: submissions != null && submissions.isNotEmpty
          ? AssignmentSubmission.fromMap(submissions.first as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSubmitted => mySubmission != null;
  bool get isOverdue   => DateTime.now().isAfter(dueDate) && !isSubmitted;

  @override
  List<Object?> get props => [id];
}

class AssignmentSubmission extends Equatable {
  final String id;
  final String assignmentId;
  final String studentId;
  final DateTime submittedAt;
  final String? fileUrl;
  final double? marksObtained;
  final String? feedback;
  final String status;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.submittedAt,
    this.fileUrl,
    this.marksObtained,
    this.feedback,
    required this.status,
  });

  factory AssignmentSubmission.fromMap(Map<String, dynamic> m) => AssignmentSubmission(
        id:            m['id'] as String,
        assignmentId:  m['assignment_id'] as String,
        studentId:     m['student_id'] as String,
        submittedAt:   DateTime.parse(m['submitted_at'] as String),
        fileUrl:       m['file_url'] as String?,
        marksObtained: (m['marks_obtained'] as num?)?.toDouble(),
        feedback:      m['feedback'] as String?,
        status:        m['status'] as String? ?? 'submitted',
      );

  @override
  List<Object?> get props => [id];
}
