import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/attendance_indicator.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _deptFilter;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lowAsync = ref.watch(lowAttendanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabs, tabs: const [
          Tab(text: 'Low Attendance'),
          Tab(text: 'Summary'),
        ]),
      ),
      body: lowAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: e.toString()),
        data: (data) => TabBarView(controller: _tabs, children: [
          _LowAttendanceList(data: data),
          _SummaryCharts(data: data),
        ]),
      ),
    );
  }
}

class _LowAttendanceList extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  const _LowAttendanceList({required this.data});

  @override
  State<_LowAttendanceList> createState() => _LowAttendanceListState();
}

class _LowAttendanceListState extends State<_LowAttendanceList> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    List filtered = widget.data;
    if (_filter == 'detained') {
      filtered = widget.data.where((r) => r['eligibility_status'] == 'detained').toList();
    } else if (_filter == 'at_risk') {
      filtered = widget.data.where((r) => r['eligibility_status'] == 'at_risk').toList();
    }

    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('${filtered.length} records', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          _Chip('All', null, _filter, () => setState(() => _filter = null)),
          const SizedBox(width: 8),
          _Chip('🔴 Detained', 'detained', _filter, () => setState(() => _filter = 'detained')),
          const SizedBox(width: 8),
          _Chip('🟡 At Risk', 'at_risk', _filter, () => setState(() => _filter = 'at_risk')),
        ]),
      ),
      const Divider(height: 1),
      Expanded(child: filtered.isEmpty
        ? const Center(child: Text('No records', style: TextStyle(color: AppColors.textSecondary)))
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _AnalyticsTile(record: filtered[i]),
          )),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? value, current;
  final VoidCallback onTap;
  const _Chip(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? AppColors.adminColor : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.textSecondary,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final Map record;
  const _AnalyticsTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final pct = (record['effective_percentage'] as num?)?.toDouble() ?? 0;
    final rawPct = (record['raw_percentage'] as num?)?.toDouble() ?? 0;
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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record['student_name'] as String? ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${record['register_no']} • ${record['department'] ?? ''}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          EligibilityBadge(status: eligibility),
        ]),
        const SizedBox(height: 6),
        Text(record['subject_name'] as String? ?? '',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: AttendanceProgressBar(percentage: pct)),
          const SizedBox(width: 8),
          Text('${pct.toStringAsFixed(1)}%',
              style: TextStyle(color: AppColors.attendanceColor(pct), fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Text('Raw: ${rawPct.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 10),
          MlOdBadge(applicable: mlApplicable, rawPercentage: rawPct),
        ]),
      ]),
    );
  }
}

class _SummaryCharts extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _SummaryCharts({required this.data});

  @override
  Widget build(BuildContext context) {
    final detained = data.where((r) => r['eligibility_status'] == 'detained')
        .map((r) => r['student_id']).toSet().length;
    final atRisk   = data.where((r) => r['eligibility_status'] == 'at_risk')
        .map((r) => r['student_id']).toSet().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Pie chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            const Text('Attendance Status Distribution',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: PieChart(PieChartData(
              sections: [
                PieChartSectionData(
                  value: detained.toDouble(),
                  color: AppColors.attendanceRed,
                  title: 'Detained\n$detained',
                  radius: 80,
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: atRisk.toDouble(),
                  color: AppColors.attendanceYellow,
                  title: 'At Risk\n$atRisk',
                  radius: 80,
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
              sectionsSpace: 3,
              centerSpaceRadius: 40,
            ))),
          ]),
        ),
        const SizedBox(height: 16),

        // Department breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Department-wise Issues',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            ...() {
              final byDept = <String, int>{};
              for (final r in data) {
                final dept = r['department'] as String? ?? 'Unknown';
                byDept[dept] = (byDept[dept] ?? 0) + 1;
              }
              final sorted = byDept.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              return sorted.take(5).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.adminColor)),
                ]),
              )).toList();
            }(),
          ]),
        ),
      ]),
    );
  }
}
