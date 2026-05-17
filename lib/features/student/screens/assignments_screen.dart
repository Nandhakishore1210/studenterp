import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/assignment_model.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentAssignmentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: async.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 90),
        error: (e, _) => AppError(message: e.toString()),
        data: (all) {
          final pending   = all.where((a) => !a.isSubmitted).toList();
          final submitted = all.where((a) =>  a.isSubmitted).toList();
          return TabBarView(
            controller: _tabs,
            children: [
              _AssignmentList(items: pending,   empty: 'No pending assignments'),
              _AssignmentList(items: submitted, empty: 'No submitted assignments'),
              _AssignmentList(items: all,       empty: 'No assignments'),
            ],
          );
        },
      ),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  final List<AssignmentModel> items;
  final String empty;
  const _AssignmentList({required this.items, required this.empty});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(
      child: Text(empty, style: const TextStyle(color: AppColors.textSecondary)));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _AssignmentCard(assignment: items[i]),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final daysLeft = a.dueDate.difference(DateTime.now()).inDays;
    final statusColor = a.isSubmitted ? AppColors.attendanceGreen
        : a.isOverdue ? AppColors.attendanceRed
        : daysLeft <= 2 ? AppColors.attendanceYellow
        : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(a.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          _StatusBadge(assignment: a),
        ]),
        const SizedBox(height: 4),
        Text(a.subject?.name ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        if (a.description != null) ...[
          const SizedBox(height: 6),
          Text(a.description!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.calendar_today_outlined, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text('Due ${DateFormat('dd MMM yyyy').format(a.dueDate)}',
              style: TextStyle(fontSize: 12, color: statusColor)),
          if (a.maxMarks != null) ...[
            const Spacer(),
            Text('${a.maxMarks!.toStringAsFixed(0)} marks',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ]),
        if (a.mySubmission?.marksObtained != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.grade_outlined, size: 14, color: AppColors.attendanceGreen),
            const SizedBox(width: 4),
            Text('Marks: ${a.mySubmission!.marksObtained!.toStringAsFixed(1)} / ${a.maxMarks?.toStringAsFixed(1) ?? "?"}',
                style: const TextStyle(fontSize: 12, color: AppColors.attendanceGreen, fontWeight: FontWeight.w600)),
          ]),
        ],
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AssignmentModel assignment;
  const _StatusBadge({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = assignment.isSubmitted
        ? ('Submitted', AppColors.attendanceGreen, AppColors.greenLight)
        : assignment.isOverdue
            ? ('Overdue', AppColors.attendanceRed, AppColors.redLight)
            : ('Pending', AppColors.warning, AppColors.yellowLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
