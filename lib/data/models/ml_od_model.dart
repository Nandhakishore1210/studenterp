import 'package:equatable/equatable.dart';
import 'attendance_model.dart';

class MlOdModel extends Equatable {
  final String id;
  final String studentId;
  final String? subjectId;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // ML | OD
  final String? reason;
  final String status; // pending | approved | rejected
  final DateTime createdAt;
  final SubjectInfo? subject;

  const MlOdModel({
    required this.id,
    required this.studentId,
    this.subjectId,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.reason,
    required this.status,
    required this.createdAt,
    this.subject,
  });

  factory MlOdModel.fromMap(Map<String, dynamic> m) {
    final subMap = m['subjects'] as Map<String, dynamic>?;
    return MlOdModel(
      id:        m['id'] as String,
      studentId: m['student_id'] as String,
      subjectId: m['subject_id'] as String?,
      startDate: DateTime.parse(m['start_date'] as String),
      endDate:   DateTime.parse(m['end_date'] as String),
      type:      m['type'] as String,
      reason:    m['reason'] as String?,
      status:    m['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(m['created_at'] as String),
      subject:   subMap != null ? SubjectInfo.fromMap(subMap) : null,
    );
  }

  int get days =>
      endDate.difference(startDate).inDays + 1;

  bool get isApproved => status == 'approved';
  bool get isPending  => status == 'pending';

  @override
  List<Object?> get props => [id];
}
