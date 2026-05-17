import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/constants/app_colors.dart';

class ApplyOdScreen extends ConsumerStatefulWidget {
  const ApplyOdScreen({super.key});

  @override
  ConsumerState<ApplyOdScreen> createState() => _ApplyOdScreenState();
}

class _ApplyOdScreenState extends ConsumerState<ApplyOdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  String _type = 'OD';
  String? _selectedSubjectId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _loading = false;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      setState(() => _error = 'Please select a subject');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final student = ref.read(studentRecordProvider).valueOrNull;
    if (student == null) {
      setState(() { _loading = false; _error = 'Student record not found'; });
      return;
    }

    final fmt = DateFormat('yyyy-MM-dd');
    final err = await SupabaseService.applyMlOd(
      studentId:  student.id,
      subjectId:  _selectedSubjectId!,
      startDate:  fmt.format(_startDate),
      endDate:    fmt.format(_endDate),
      type:       _type,
      reason:     _reasonCtrl.text.trim(),
    );

    setState(() { _loading = false; });
    if (err != null) {
      setState(() => _error = err);
    } else {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(studentAttendanceProvider);
    final fmt = DateFormat('dd MMM yyyy');

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: Text('Apply OD/ML', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 72),
          const SizedBox(height: 20),
          Text('Application Submitted!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Your mentor will review and approve it.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Go Back'),
          ),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Apply OD / ML', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Type selector
            _SectionLabel('Request Type'),
            const SizedBox(height: 8),
            Row(children: [
              _TypeCard(
                label: 'OD',
                subtitle: 'On Duty',
                icon: Icons.work_outline_rounded,
                selected: _type == 'OD',
                color: AppColors.staffColor,
                onTap: () => setState(() => _type = 'OD'),
              ),
              const SizedBox(width: 12),
              _TypeCard(
                label: 'ML',
                subtitle: 'Medical Leave',
                icon: Icons.local_hospital_outlined,
                selected: _type == 'ML',
                color: const Color(0xFFDC2626),
                onTap: () => setState(() => _type = 'ML'),
              ),
            ]),
            const SizedBox(height: 24),

            // Subject selector
            _SectionLabel('Subject'),
            const SizedBox(height: 8),
            attendanceAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text(e.toString(), style: const TextStyle(color: AppColors.error)),
              data: (subjects) {
                if (subjects.isEmpty) return const Text('No subjects found');
                return DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  hint: Text('Select subject', style: GoogleFonts.inter(color: AppColors.textHint)),
                  items: subjects.map((s) => DropdownMenuItem(
                    value: s.subjectId,
                    child: Text(s.subject?.name ?? s.subjectId, style: GoogleFonts.inter(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedSubjectId = v),
                );
              },
            ),
            const SizedBox(height: 24),

            // Date range
            _SectionLabel('Date Range'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _DateField(
                label: 'From',
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
              )),
              const SizedBox(width: 12),
              Expanded(child: _DateField(
                label: 'To',
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
              )),
            ]),
            const SizedBox(height: 24),

            // Reason
            _SectionLabel('Reason'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Briefly explain the reason for your request…',
                hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (v) => (v == null || v.trim().length < 10) ? 'Please provide a reason (min 10 chars)' : null,
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text('Submit Application', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
}

class _TypeCard extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeCard({required this.label, required this.subtitle, required this.icon,
      required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? color : AppColors.textHint, size: 22),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800,
                color: selected ? color : AppColors.textPrimary)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: selected ? color : AppColors.textSecondary)),
          ]),
        ]),
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint)),
          Text(DateFormat('dd MMM yyyy').format(date),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
      ]),
    ),
  );
}
