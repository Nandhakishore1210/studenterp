import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

class ExamScheduleScreen extends ConsumerWidget {
  const ExamScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(examScheduleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Schedule')),
      body: async.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 90),
        error: (e, _) => AppError(message: e.toString()),
        data: (data) {
          if (data.isEmpty) return const Center(
            child: Text('No exams scheduled', style: TextStyle(color: AppColors.textSecondary)));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ExamCard(exam: data[i]),
          );
        },
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Map exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final subject = exam['subjects'] as Map?;
    final date    = DateTime.parse(exam['exam_date'] as String);
    final type    = exam['exam_type'] as String? ?? 'exam';
    final isPast  = date.isBefore(DateTime.now());

    final typeColors = {
      'CIA':      AppColors.primary,
      'model':    const Color(0xFF673AB7),
      'semester': const Color(0xFFE91E63),
    };
    final color = typeColors[type] ?? AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isPast ? AppColors.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPast ? AppColors.border : color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('dd').format(date),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(DateFormat('MMM').format(date),
                style: TextStyle(color: color, fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subject?['name'] as String? ?? 'Unknown',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                  color: isPast ? AppColors.textSecondary : AppColors.textPrimary)),
          Text(subject?['code'] as String? ?? '',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(type.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            if (exam['start_time'] != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 2),
              Text('${exam['start_time']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (exam['venue'] != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.room, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 2),
              Text(exam['venue'] as String,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ]),
        ])),
        if (isPast)
          const Icon(Icons.check_circle, color: AppColors.attendanceGreen, size: 20),
      ]),
    );
  }
}
