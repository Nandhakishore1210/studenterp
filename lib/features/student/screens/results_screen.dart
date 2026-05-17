import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/marks_model.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksAsync = ref.watch(studentMarksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Semester Results')),
      body: marksAsync.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 100),
        error: (e, _) => AppError(message: e.toString()),
        data: (marks) {
          if (marks.isEmpty) return const Center(
            child: Text('No results available', style: TextStyle(color: AppColors.textSecondary)));

          final grouped = groupBy(marks, (MarksModel m) => m.subject?.name ?? m.subjectId);
          final totalMax     = marks.fold<double>(0, (s, m) => s + m.maxMarks);
          final totalObtained = marks.where((m) => m.obtainedMarks != null)
              .fold<double>(0, (s, m) => s + m.obtainedMarks!);
          final overallGpa   = totalMax > 0 ? (totalObtained / totalMax * 10) : 0.0;

          return ListView(
            children: [
              // GPA summary
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _GpaStat('CGPA', overallGpa.toStringAsFixed(1)),
                  Container(height: 40, width: 1, color: Colors.white24),
                  _GpaStat('Total', '${totalObtained.toStringAsFixed(0)}/${totalMax.toStringAsFixed(0)}'),
                  Container(height: 40, width: 1, color: Colors.white24),
                  _GpaStat('Subjects', grouped.length.toString()),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: const Text('Subject-wise Results',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),

              ...grouped.entries.map((e) => _ResultCard(
                subjectName: e.key,
                subjectCode: e.value.first.subject?.code ?? '',
                marksList: e.value,
              )),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _GpaStat extends StatelessWidget {
  final String label, value;
  const _GpaStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
  ]);
}

class _ResultCard extends StatelessWidget {
  final String subjectName, subjectCode;
  final List<MarksModel> marksList;
  const _ResultCard({required this.subjectName, required this.subjectCode, required this.marksList});

  @override
  Widget build(BuildContext context) {
    final totalMax      = marksList.fold<double>(0, (s, m) => s + m.maxMarks);
    final totalObtained = marksList.where((m) => m.obtainedMarks != null)
        .fold<double>(0, (s, m) => s + m.obtainedMarks!);
    final pct = totalMax > 0 ? (totalObtained / totalMax * 100) : 0.0;
    final grade = _grade(pct);
    final gradeColor = pct >= 75 ? AppColors.attendanceGreen
        : pct >= 50 ? AppColors.attendanceYellow : AppColors.attendanceRed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(subjectName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subjectCode, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text('${totalObtained.toStringAsFixed(1)} / ${totalMax.toStringAsFixed(1)} marks',
                style: const TextStyle(fontSize: 13)),
          ])),
          Column(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(grade, style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Text('${pct.toStringAsFixed(1)}%',
                style: TextStyle(color: gradeColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  String _grade(double pct) {
    if (pct >= 90) return 'O';
    if (pct >= 80) return 'A+';
    if (pct >= 70) return 'A';
    if (pct >= 60) return 'B+';
    if (pct >= 50) return 'B';
    if (pct >= 40) return 'C';
    return 'F';
  }
}
