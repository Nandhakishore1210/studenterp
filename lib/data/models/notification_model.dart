import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? targetRole;
  final String? targetDepartment;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetRole,
    this.targetDepartment,
    required this.createdAt,
    this.expiresAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> m) {
    final reads = m['notification_reads'] as List?;
    return NotificationModel(
      id:               m['id'] as String,
      title:            m['title'] as String,
      body:             m['body'] as String,
      type:             m['type'] as String? ?? 'general',
      targetRole:       m['target_role'] as String?,
      targetDepartment: m['target_department'] as String?,
      createdAt:        DateTime.parse(m['created_at'] as String),
      expiresAt:        m['expires_at'] != null ? DateTime.parse(m['expires_at'] as String) : null,
      isRead:           reads != null && reads.isNotEmpty,
    );
  }

  @override
  List<Object?> get props => [id];
}
