import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/staff_provider.dart';
import '../../../shared/widgets/attendance_indicator.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedAssignmentId;
  String? _filter; // null=all, 'below65', '65to75', 'above75'

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(staffSubjectAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), automaticallyImplyLeading: false),
      body: Column(children: [
        // Subject selector
        assignmentsAsync.when(
          loading: () => const ShimmerCard(height: 60),
          error: (_, __) => const SizedBox.shrink(),
          data: (assignments) {
            if (_selectedAssignmentId == null && assignments.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _selectedAssignmentId = assignments.first['id'] as String);
              });
            }
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: _selectedAssignmentId,
                decoration: const InputDecoration(labelText: 'Select Subject'),
                items: assignments.map((a) {
                  final sub = a['subjects'] as Map?;
                  return DropdownMenuItem<String>(
                    value: a['id'] as String,
                    child: Text('${sub?['name']} ${a['section'] != null ? "(Sec ${a['section']})" : ""}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedAssignmentId = v),
              ),
            );
          },
        ),

        // Filter chips
        if (_selectedAssignmentId != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FilterChip('All', null, _filter),
                const SizedBox(width: 8),
                _FilterChip('🔴 < 65%', 'below65', _filter),
                const SizedBox(width: 8),
                _FilterChip('🟡 65–75%', '65to75', _filter),
                const SizedBox(width: 8),
                _FilterChip('🟢 ≥ 75%', 'above75', _filter),
              ].map((c) => GestureDetector(
                onTap: () => setState(() => _filter = (c as _FilterChip).value),
                child: c,
              )).toList()),
            ),
          ),

        const Divider(height: 1),

        // Report table
        if (_selectedAssignmentId != null)
          Expanded(child: _ReportList(
            subjectAssignmentId: _selectedAssignmentId!,
            filter: _filter,
          )),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? current;
  const _FilterChip(this.label, this.value, this.current);

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      )),
    );
  }
}

class _ReportList extends ConsumerWidget {
  final String subjectAssignmentId;
  final String? filter;
  const _ReportList({required this.subjectAssignmentId, this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(subjectReportProvider(subjectAssignmentId));
    return reportAsync.when(
      loading: () => const ShimmerList(count: 5, itemHeight: 110),
      error: (e, _) => AppError(message: e.toString()),
      data: (data) {
        List filtered = data;
        if (filter == 'below65') {
          filtered = data.where((r) => (r['effective_percentage'] as num) < 65).toList();
        } else if (filter == '65to75') {
          filtered = data.where((r) {
            final p = (r['effective_percentage'] as num).toDouble();
            return p >= 65 && p < 75;
          }).toList();
        } else if (filter == 'above75') {
          filtered = data.where((r) => (r['effective_percentage'] as num) >= 75).toList();
        }

        if (filtered.isEmpty) return const Center(
          child: Text('No records match filter', style: TextStyle(color: AppColors.textSecondary)));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ReportStudentCard(record: filtered[i]),
        );
      },
    );
  }
}

class _ReportStudentCard extends StatelessWidget {
  final Map record;
  const _ReportStudentCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final student = record['students'] as Map?;
    final profile = student?['profiles'] as Map?;
    final rawPct  = (record['raw_percentage'] as num?)?.toDouble() ?? 0.0;
    final effPct  = (record['effective_percentage'] as num?)?.toDouble() ?? 0.0;
    final mlApplicable = record['is_ml_od_applicable'] as bool? ?? false;
    final eligibility  = record['eligibility_status'] as String? ?? 'eligible';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.staffColor.withOpacity(0.12),
            child: Text((profile?['full_name'] as String? ?? '?')[0],
                style: const TextStyle(color: AppColors.staffColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile?['full_name'] as String? ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(student?['register_no'] as String? ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          EligibilityBadge(status: eligibility),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _Stat('Total', '${record['total_classes'] ?? 0}'),
          _Stat('Present', '${record['present_count'] ?? 0}'),
          _Stat('Raw', '${rawPct.toStringAsFixed(1)}%', color: AppColors.attendanceColor(rawPct)),
          _Stat('ML/OD', '${record['ml_od_count'] ?? 0}'),
          _Stat('Effective', '${effPct.toStringAsFixed(1)}%', color: AppColors.attendanceColor(effPct)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          AttendanceProgressBar(percentage: effPct),
          const SizedBox(width: 8),
          MlOdBadge(applicable: mlApplicable, rawPercentage: rawPct),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
  ]));
}
