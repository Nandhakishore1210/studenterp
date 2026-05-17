import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/widgets/attendance_indicator.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

final _subjectStudentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, id) =>
        SupabaseService.getSubjectStudentDetails(id));

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectAssignmentId;
  const SubjectDetailScreen({super.key, required this.subjectAssignmentId});

  @override
  ConsumerState<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  String _filter = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(_subjectStudentsProvider(widget.subjectAssignmentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Subject Students', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_subjectStudentsProvider(widget.subjectAssignmentId)),
          ),
        ],
      ),
      body: studentsAsync.when(
        loading: () => const ShimmerList(count: 8, itemHeight: 80),
        error: (e, _) => AppError(message: e.toString()),
        data: (students) {
          final total    = students.length;
          final eligible = students.where((s) => (s['eligibility_status'] as String?) == 'eligible').length;
          final atRisk   = students.where((s) => (s['eligibility_status'] as String?) == 'at_risk').length;
          final detained = students.where((s) => (s['eligibility_status'] as String?) == 'detained').length;

          final filtered = students.where((s) {
            final name    = (s['full_name'] as String? ?? '').toLowerCase();
            final reg     = (s['register_no'] as String? ?? '').toLowerCase();
            final matchSearch = _search.isEmpty || name.contains(_search) || reg.contains(_search);
            final status  = s['eligibility_status'] as String? ?? 'eligible';
            final matchFilter = _filter == 'all' || status == _filter;
            return matchSearch && matchFilter;
          }).toList()
            ..sort((a, b) {
              final pA = (a['effective_percentage'] as num?)?.toDouble() ?? 0;
              final pB = (b['effective_percentage'] as num?)?.toDouble() ?? 0;
              return pA.compareTo(pB);
            });

          return Column(children: [
            // Stats banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                _StatChip('$total', 'Total', AppColors.primary),
                const SizedBox(width: 8),
                _StatChip('$eligible', 'Eligible', const Color(0xFF059669)),
                const SizedBox(width: 8),
                _StatChip('$atRisk', 'At Risk', const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _StatChip('$detained', 'Detained', const Color(0xFFDC2626)),
              ]),
            ),

            // Search + filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or reg no…',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final f in ['all', 'detained', 'at_risk', 'eligible'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f == 'all' ? 'All' : f == 'at_risk' ? 'At Risk' : f.capitalize()),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.staffColor.withOpacity(0.15),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _filter == f ? AppColors.staffColor : AppColors.textSecondary,
                          ),
                          side: BorderSide(color: _filter == f ? AppColors.staffColor : AppColors.border),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No students found', style: GoogleFonts.inter(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _StudentCard(student: filtered[i]),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(children: [
      Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: color)),
    ]),
  );
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final name     = student['full_name'] as String? ?? 'Student';
    final reg      = student['register_no'] as String? ?? '';
    final section  = student['section'] as String? ?? '';
    final dept     = student['department'] as String? ?? '';
    final phone    = student['phone'] as String?;
    final email    = student['email'] as String?;
    final pct      = (student['effective_percentage'] as num?)?.toDouble() ?? 0;
    final status   = student['eligibility_status'] as String? ?? 'eligible';
    final total    = student['total_classes'] as int? ?? 0;
    final present  = student['present_count'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _showStudentDetails(context, student),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.attendanceLightColor(pct),
            child: Text(name.isNotEmpty ? name[0] : '?',
                style: TextStyle(color: AppColors.attendanceColor(pct), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('$reg • Sec $section • $dept',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              Text('$present/$total classes',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
              const SizedBox(width: 8),
              EligibilityBadge(status: status),
            ]),
          ])),
          AttendanceIndicatorChip(percentage: pct),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
        ]),
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> student) {
    final name    = student['full_name'] as String? ?? 'Student';
    final reg     = student['register_no'] as String? ?? '';
    final section = student['section'] as String? ?? '';
    final dept    = student['department'] as String? ?? '';
    final phone   = student['phone'] as String?;
    final email   = student['email'] as String?;
    final pct     = (student['effective_percentage'] as num?)?.toDouble() ?? 0;
    final status  = student['eligibility_status'] as String? ?? 'eligible';
    final total   = student['total_classes'] as int? ?? 0;
    final present = student['present_count'] as int? ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.attendanceLightColor(pct),
              child: Text(name.isNotEmpty ? name[0] : '?',
                  style: TextStyle(fontSize: 24, color: AppColors.attendanceColor(pct), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
              Text(reg, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
            ])),
            AttendanceCircle(percentage: pct, size: 60),
          ]),
          const SizedBox(height: 20),
          _DetailRow(Icons.school_outlined, 'Department', dept),
          _DetailRow(Icons.group_outlined, 'Section', section),
          _DetailRow(Icons.class_outlined, 'Classes', '$present present / $total total'),
          if (phone != null) _DetailRow(Icons.phone_outlined, 'Phone', phone),
          if (email != null) _DetailRow(Icons.email_outlined, 'Email', email),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Eligibility: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            EligibilityBadge(status: status),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.textHint),
      const SizedBox(width: 10),
      Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
      Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
    ]),
  );
}

extension _CapExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
