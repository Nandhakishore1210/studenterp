import 'package:equatable/equatable.dart';

class FeeModel extends Equatable {
  final String id;
  final String studentId;
  final String academicYear;
  final String feeType;
  final double amount;
  final DateTime? dueDate;
  final double paidAmount;
  final DateTime? paidDate;
  final String status; // pending | partial | paid

  const FeeModel({
    required this.id,
    required this.studentId,
    required this.academicYear,
    required this.feeType,
    required this.amount,
    this.dueDate,
    required this.paidAmount,
    this.paidDate,
    required this.status,
  });

  factory FeeModel.fromMap(Map<String, dynamic> m) => FeeModel(
        id:           m['id'] as String,
        studentId:    m['student_id'] as String,
        academicYear: m['academic_year'] as String,
        feeType:      m['fee_type'] as String,
        amount:       (m['amount'] as num).toDouble(),
        dueDate:      m['due_date'] != null ? DateTime.parse(m['due_date'] as String) : null,
        paidAmount:   (m['paid_amount'] as num?)?.toDouble() ?? 0.0,
        paidDate:     m['paid_date'] != null ? DateTime.parse(m['paid_date'] as String) : null,
        status:       m['status'] as String? ?? 'pending',
      );

  double get balance => amount - paidAmount;
  bool   get isPaid  => status == 'paid';

  @override
  List<Object?> get props => [id];
}
