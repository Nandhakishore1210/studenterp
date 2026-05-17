import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/staff_provider.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

class ManageAssignmentsScreen extends ConsumerStatefulWidget {
  final String subjectAssignmentId;
  const ManageAssignmentsScreen({super.key, required this.subjectAssignmentId});

  @override
  ConsumerState<ManageAssignmentsScreen> createState() => _ManageAssignmentsScreenState();
}

class _ManageAssignmentsScreenState extends ConsumerState<ManageAssignmentsScreen> {
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.client
          .from('assignments')
          .select('*, assignment_submissions(count)')
          .eq('subject_assignment_id', widget.subjectAssignmentId)
          .order('due_date');
      setState(() { _assignments = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    double maxMarks = 10;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Create Assignment'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *')),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(
              initialValue: maxMarks.toStringAsFixed(0),
              decoration: const InputDecoration(labelText: 'Max Marks'),
              keyboardType: TextInputType.number,
              onChanged: (v) => maxMarks = double.tryParse(v) ?? maxMarks,
            )),
            const SizedBox(width: 10),
            Expanded(child: InkWell(
              onTap: () async {
                final d = await showDatePicker(context: ctx,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setDialogState(() => dueDate = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due Date'),
                child: Text(DateFormat('dd/MM/yyyy').format(dueDate)),
              ),
            )),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              final staff = ref.read(staffRecordProvider).valueOrNull;
              if (staff == null) return;
              await SupabaseService.client.from('assignments').insert({
                'subject_assignment_id': widget.subjectAssignmentId,
                'title':       titleCtrl.text.trim(),
                'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                'due_date':    dueDate.toIso8601String(),
                'max_marks':   maxMarks,
                'created_by':  staff.id,
              });
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manage Assignments')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _showCreateDialog,
      icon: const Icon(Icons.add),
      label: const Text('New Assignment'),
    ),
    body: _loading ? const AppLoading() : _assignments.isEmpty
      ? const Center(child: Text('No assignments created', style: TextStyle(color: AppColors.textSecondary)))
      : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _assignments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final a = _assignments[i];
            final submissionsCount = (a['assignment_submissions'] as List?)?.first['count'] ?? 0;
            final due = DateTime.parse(a['due_date'] as String);
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(a['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: due.isBefore(DateTime.now()) ? AppColors.redLight : AppColors.greenLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(due.isBefore(DateTime.now()) ? 'Closed' : 'Active',
                        style: TextStyle(
                            fontSize: 11,
                            color: due.isBefore(DateTime.now()) ? AppColors.error : AppColors.attendanceGreen,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                if (a['description'] != null)
                  Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(a['description'] as String,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Due: ${DateFormat('dd MMM yyyy').format(due)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.assignment_turned_in_outlined, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('$submissionsCount submissions',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ]),
              ]),
            );
          },
        ),
  );
}
