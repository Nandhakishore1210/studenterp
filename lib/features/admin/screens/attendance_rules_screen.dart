import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/constants/supabase_constants.dart';

class AttendanceRulesScreen extends ConsumerStatefulWidget {
  const AttendanceRulesScreen({super.key});

  @override
  ConsumerState<AttendanceRulesScreen> createState() => _AttendanceRulesScreenState();
}

class _AttendanceRulesScreenState extends ConsumerState<AttendanceRulesScreen> {
  final _minCtrl        = TextEditingController();
  final _riskCtrl       = TextEditingController();
  final _mlOdMaxCtrl    = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _minCtrl.dispose(); _riskCtrl.dispose(); _mlOdMaxCtrl.dispose();
    super.dispose();
  }

  void _initControllers(Map<String, dynamic> rules) {
    if (_minCtrl.text.isEmpty) {
      _minCtrl.text  = (rules['detention_threshold'] ?? 65).toString();
      _riskCtrl.text = (rules['risk_threshold'] ?? 75).toString();
      _mlOdMaxCtrl.text = (rules['ml_od_max_days'] ?? 10).toString();
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.upsertAttendanceRules({
        'academic_year':       SupabaseConstants.currentAcademicYear,
        'minimum_percentage':  double.tryParse(_minCtrl.text) ?? 65.0,
        'detention_threshold': double.tryParse(_minCtrl.text) ?? 65.0,
        'risk_threshold':      double.tryParse(_riskCtrl.text) ?? 75.0,
        'ml_od_max_days':      int.tryParse(_mlOdMaxCtrl.text) ?? 10,
      });
      ref.invalidate(attendanceRulesProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rules updated!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(attendanceRulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Rules'), automaticallyImplyLeading: false),
      body: rulesAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: e.toString()),
        data: (rules) {
          if (rules != null) _initControllers(rules);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Current year
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Academic Year: ${SupabaseConstants.currentAcademicYear}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 24),

              const Text('Thresholds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('These values control attendance eligibility and ML/OD application.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),

              _RuleField(
                controller: _minCtrl,
                label: 'Detention Threshold (%)',
                hint: 'e.g. 65',
                description: 'Students below this % are marked as Detained. ML/OD is NOT applied if raw% is below this.',
                icon: Icons.block_outlined,
                color: AppColors.attendanceRed,
              ),
              const SizedBox(height: 16),

              _RuleField(
                controller: _riskCtrl,
                label: 'At-Risk Threshold (%)',
                hint: 'e.g. 75',
                description: 'Students between Detention and this threshold are marked "At Risk".',
                icon: Icons.warning_amber_outlined,
                color: AppColors.attendanceYellow,
              ),
              const SizedBox(height: 16),

              _RuleField(
                controller: _mlOdMaxCtrl,
                label: 'Maximum ML/OD Days',
                hint: 'e.g. 10',
                description: 'Maximum number of ML/OD days that can be counted toward attendance.',
                icon: Icons.medical_services_outlined,
                color: AppColors.info,
              ),
              const SizedBox(height: 32),

              // ML/OD Logic explanation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('ML/OD Calculation Logic',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 10),
                  _LogicStep('1.', 'System calculates raw attendance for each student/subject.'),
                  _LogicStep('2.', 'If raw% ≥ Detention Threshold → ML/OD days are added to present count.'),
                  _LogicStep('3.', 'If raw% < Detention Threshold → ML/OD is IGNORED.'),
                  _LogicStep('4.', 'Effective attendance = (present + ML/OD) / total × 100.'),
                  _LogicStep('5.', 'No manual override by faculty or student is permitted.'),
                ]),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Rules'),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _RuleField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint, description;
  final IconData icon;
  final Color color;
  const _RuleField({required this.controller, required this.label, required this.hint,
      required this.description, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: color),
      ),
    ),
    const SizedBox(height: 4),
    Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ),
  ]);
}

class _LogicStep extends StatelessWidget {
  final String step, text;
  const _LogicStep(this.step, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(step, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]),
  );
}
