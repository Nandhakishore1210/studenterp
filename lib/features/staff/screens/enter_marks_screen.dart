import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/staff_provider.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_constants.dart';

class EnterMarksScreen extends ConsumerStatefulWidget {
  final String subjectAssignmentId;
  const EnterMarksScreen({super.key, required this.subjectAssignmentId});

  @override
  ConsumerState<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends ConsumerState<EnterMarksScreen> {
  String _assessmentType = 'CIA1';
  double _maxMarks = 50;
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  static const _assessmentTypes = ['CIA1', 'CIA2', 'CIA3', 'assignment', 'practical', 'model', 'semester'];
  static const _defaultMaxMarks = {
    'CIA1': 50.0, 'CIA2': 50.0, 'CIA3': 50.0,
    'assignment': 10.0, 'practical': 50.0,
    'model': 100.0, 'semester': 100.0,
  };

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(enrolledStudentsProvider(widget.subjectAssignmentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Marks')),
      body: studentsAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: e.toString()),
        data: (students) {
          for (final s in students) {
            _controllers.putIfAbsent(s.id, () => TextEditingController());
          }

          return Column(children: [
            // Controls
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: _assessmentType,
                  decoration: const InputDecoration(labelText: 'Assessment Type'),
                  items: _assessmentTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.replaceAll('CIA', 'CIA ').toUpperCase()),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() {
                      _assessmentType = v;
                      _maxMarks = _defaultMaxMarks[v] ?? 50;
                    });
                  },
                )),
                const SizedBox(width: 12),
                SizedBox(width: 90, child: TextFormField(
                  initialValue: _maxMarks.toStringAsFixed(0),
                  decoration: const InputDecoration(labelText: 'Max Marks'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _maxMarks = double.tryParse(v) ?? _maxMarks,
                )),
              ]),
            ),
            const Divider(height: 1),

            // Student list
            Expanded(child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final s = students[i];
                final ctrl = _controllers[s.id]!;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight,
                        child: Text(s.fullName[0], style: const TextStyle(color: AppColors.primary, fontSize: 13))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(s.registerNo, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                    SizedBox(width: 80, child: TextFormField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '/ ${_maxMarks.toStringAsFixed(0)}',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    )),
                  ]),
                );
              },
            )),

            // Save
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(students),
                child: _saving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Marks'),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _save(List students) async {
    setState(() => _saving = true);
    try {
      final staff = ref.read(staffRecordProvider).valueOrNull;
      if (staff == null) throw Exception('Staff record not found');

      final assignment = await SupabaseService.client
          .from('subject_assignments')
          .select('subject_id, semester_number')
          .eq('id', widget.subjectAssignmentId)
          .single();

      final records = students
          .where((s) => _controllers[s.id]?.text.isNotEmpty == true)
          .map((s) => {
            'student_id':             s.id,
            'subject_id':             assignment['subject_id'],
            'subject_assignment_id':  widget.subjectAssignmentId,
            'academic_year':          SupabaseConstants.currentAcademicYear,
            'semester_number':        assignment['semester_number'],
            'assessment_type':        _assessmentType,
            'max_marks':              _maxMarks,
            'obtained_marks':         double.tryParse(_controllers[s.id]!.text),
            'entered_by':             staff.id,
          }).toList();

      await SupabaseService.upsertMarks(records);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks saved!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
