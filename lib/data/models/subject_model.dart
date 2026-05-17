import 'package:equatable/equatable.dart';

class SubjectModel extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? departmentId;
  final String? courseId;
  final int semesterNumber;
  final int credits;
  final bool isPractical;

  const SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    this.departmentId,
    this.courseId,
    required this.semesterNumber,
    required this.credits,
    required this.isPractical,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> m) => SubjectModel(
        id:             m['id'] as String,
        code:           m['code'] as String,
        name:           m['name'] as String,
        departmentId:   m['department_id'] as String?,
        courseId:       m['course_id'] as String?,
        semesterNumber: m['semester_number'] as int,
        credits:        m['credits'] as int? ?? 3,
        isPractical:    m['is_practical'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, code];
}
