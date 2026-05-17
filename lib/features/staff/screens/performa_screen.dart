import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/staff_provider.dart';
import '../../../shared/widgets/attendance_indicator.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';

class PerformaScreen extends ConsumerStatefulWidget {
  const PerformaScreen({super.key});

  @override
  ConsumerState<PerformaScreen> createState() => _PerformaScreenState();
}

class _PerformaScreenState extends ConsumerState<PerformaScreen> {
  String? _selectedStudentId;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final staffAsync    = ref.watch(staffRecordProvider);
    final performaAsync = ref.watch(menteesPerformaProvider);

    final staff = staffAsync.valueOrNull;
    if (staff == null || (!staff.isMentor && !staff.isClassAdvisor)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Performa'), automaticallyImplyLeading: false),
        body: const Center(
          child: Text('Performa is available for Mentors and Class Advisors only.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mentor Performa'), automaticallyImplyLeading: false),
      body: performaAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: e.toString()),
        data: (data) {
          // Group by student
          final grouped = groupBy(data, (Map m) => m['student_id'] as String);
          final students = grouped.keys.toList();

          if (students.isEmpty) return const Center(
            child: Text('No mentees assigned', style: TextStyle(color: AppColors.textSecondary)));

          return Row(children: [
            // Student list (left panel on wide screens, selector on small)
            if (MediaQuery.of(context).size.width > 600)
              SizedBox(
                width: 220,
                child: _StudentSidebar(
                  studentIds: students,
                  data: data,
                  selected: _selectedStudentId,
                  onSelected: (id) => setState(() => _selectedStudentId = id),
                ),
              ),

            Expanded(child: _selectedStudentId != null
                ? _StudentPerformaDetail(
                    studentId: _selectedStudentId!,
                    subjects: grouped[_selectedStudentId!] ?? [],
                    noteCtrl: _noteCtrl,
                    staffId: staff.id,
                  )
                : Column(children: [
                    // Mobile: show list
                    Expanded(child: _StudentSidebar(
                      studentIds: students,
                      data: data,
                      selected: null,
                      onSelected: (id) => setState(() => _selectedStudentId = id),
                    )),
                  ])),
          ]);
        },
      ),
    );
  }
}

class _StudentSidebar extends StatelessWidget {
  final List<String> studentIds;
  final List data;
  final String? selected;
  final ValueChanged<String> onSelected;
  const _StudentSidebar({required this.studentIds, required this.data, this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    child: ListView.separated(
      itemCount: studentIds.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final id = studentIds[i];
        final studentData = data.firstWhere((m) => m['student_id'] == id, orElse: () => {});
        final name  = studentData['student_name'] as String? ?? 'Student';
        final regNo = studentData['register_no'] as String? ?? '';
        final effPct = (studentData['effective_percentage'] as num?)?.toDouble() ?? 0;

        return ListTile(
          selected: selected == id,
          selectedTileColor: AppColors.primaryLight,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.attendanceLightColor(effPct),
            child: Text(name[0], style: TextStyle(color: AppColors.attendanceColor(effPct), fontWeight: FontWeight.bold)),
          ),
          title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          subtitle: Text(regNo, style: const TextStyle(fontSize: 11)),
          trailing: AttendanceIndicatorChip(percentage: effPct, compact: true),
          onTap: () => onSelected(id),
        );
      },
    ),
  );
}

class _StudentPerformaDetail extends StatefulWidget {
  final String studentId;
  final List subjects;
  final TextEditingController noteCtrl;
  final String staffId;
  const _StudentPerformaDetail({
    required this.studentId,
    required this.subjects,
    required this.noteCtrl,
    required this.staffId,
  });

  @override
  State<_StudentPerformaDetail> createState() => _StudentPerformaDetailState();
}

class _StudentPerformaDetailState extends State<_StudentPerformaDetail>
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
    final s = widget.subjects.isNotEmpty ? widget.subjects.first : {};
    final studentName = s['student_name'] as String? ?? 'Student';
    final semester    = s['current_semester'] as int? ?? 1;
    final dept        = s['department'] as String? ?? '';
    final section     = s['section'] as String? ?? '';
    final batch       = s['batch'] as String? ?? '';

    // Overall stats
    final totalClasses    = widget.subjects.fold<int>(0, (s, m) => s + ((m['total_classes'] as int?) ?? 0));
    final totalPresent    = widget.subjects.fold<int>(0, (s, m) => s + ((m['present_count'] as int?) ?? 0));
    final totalEffPresent = widget.subjects.fold<int>(0, (s, m) => s + ((m['effective_present_count'] as int?) ?? 0));
    final effPct = totalClasses > 0 ? (totalEffPresent / totalClasses * 100) : 0.0;
    final detained = widget.subjects.where((m) => m['eligibility_status'] == 'detained').length;
    final atRisk   = widget.subjects.where((m) => m['eligibility_status'] == 'at_risk').length;

    return Column(children: [
      // Header
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.attendanceLightColor(effPct),
            child: Text(studentName[0], style: TextStyle(fontSize: 20,
                color: AppColors.attendanceColor(effPct), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Sem $semester • $dept • Sec $section • $batch',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          AttendanceCircle(percentage: effPct, size: 56),
        ]),
      ),
      // Stats row
      Container(
        color: AppColors.surfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem('${widget.subjects.length}', 'Subjects'),
          _StatItem('$detained', 'Detained', color: detained > 0 ? AppColors.attendanceRed : null),
          _StatItem('$atRisk', 'At Risk', color: atRisk > 0 ? AppColors.attendanceYellow : null),
          _StatItem('$totalClasses', 'Total\nClasses'),
          _StatItem('$totalEffPresent', 'Effective\nPresent'),
        ]),
      ),
      // Tabs
      TabBar(
        controller: _tabs,
        tabs: const [Tab(text: 'Attendance'), Tab(text: 'ML/OD'), Tab(text: 'Counselling')],
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        // Attendance heatmap/list
        ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: widget.subjects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final sub = widget.subjects[i];
            final rawPct = (sub['raw_percentage'] as num?)?.toDouble() ?? 0;
            final effPctSub = (sub['effective_percentage'] as num?)?.toDouble() ?? 0;
            final mlApplicable = sub['is_ml_od_applicable'] as bool? ?? false;
            final eligibility  = sub['eligibility_status'] as String? ?? 'eligible';
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sub['subject_name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(sub['subject_code'] as String? ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ])),
                  EligibilityBadge(status: eligibility),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _MiniStat('${sub['total_classes']}', 'Total'),
                  _MiniStat('${sub['present_count']}', 'Present'),
                  _MiniStat('${rawPct.toStringAsFixed(1)}%', 'Raw', color: AppColors.attendanceColor(rawPct)),
                  _MiniStat('${sub['ml_od_count']}', 'ML/OD'),
                  _MiniStat('${effPctSub.toStringAsFixed(1)}%', 'Effective', color: AppColors.attendanceColor(effPctSub)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: AttendanceProgressBar(percentage: effPctSub)),
                  const SizedBox(width: 8),
                  MlOdBadge(applicable: mlApplicable, rawPercentage: rawPct),
                ]),
              ]),
            );
          },
        ),

        // ML/OD approval
        _MlOdTab(studentId: widget.studentId, staffId: widget.staffId),

        // Counselling notes
        _CounsellingTab(studentId: widget.studentId, staffId: widget.staffId, noteCtrl: widget.noteCtrl),
      ])),
    ]);
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color? color;
  const _StatItem(this.value, this.label, {this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
  ]);
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color? color;
  const _MiniStat(this.value, this.label, {this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
  ]));
}

// ── ML/OD Tab ─────────────────────────────────────────────────────
class _MlOdTab extends StatefulWidget {
  final String studentId, staffId;
  const _MlOdTab({required this.studentId, required this.staffId});

  @override
  State<_MlOdTab> createState() => _MlOdTabState();
}

class _MlOdTabState extends State<_MlOdTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.client
          .from('ml_od')
          .select('*, subjects(*)')
          .eq('student_id', widget.studentId)
          .order('created_at', ascending: false);
      setState(() { _requests = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id) async {
    await SupabaseService.approveMlOd(id, widget.staffId);
    await _load();
  }

  Future<void> _reject(String id) async {
    await SupabaseService.rejectMlOd(id, widget.staffId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoading();
    if (_requests.isEmpty) return const Center(
        child: Text('No ML/OD requests', style: TextStyle(color: AppColors.textSecondary)));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _requests.length,
      itemBuilder: (_, i) {
        final r       = _requests[i];
        final subject = r['subjects'] as Map?;
        final status  = r['status'] as String? ?? 'pending';
        final type    = r['type'] as String? ?? 'OD';
        final start   = r['start_date'] as String? ?? '';
        final end     = r['end_date']   as String? ?? '';
        final reason  = r['reason']     as String? ?? '';
        final id      = r['id'] as String;

        final isPending  = status == 'pending';
        final isApproved = status == 'approved';

        final typeColor = type == 'ML' ? const Color(0xFFDC2626) : AppColors.staffColor;
        final statusColor = isApproved ? const Color(0xFF059669)
            : isPending ? const Color(0xFFD97706) : const Color(0xFF6B7280);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(type, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: typeColor)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(
                subject?['name'] as String? ?? 'Subject',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('$start → $end', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(reason, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => _reject(id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Reject', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () => _approve(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Approve', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                )),
              ]),
            ],
          ]),
        );
      },
    );
  }
}

class _CounsellingTab extends StatefulWidget {
  final String studentId, staffId;
  final TextEditingController noteCtrl;
  const _CounsellingTab({required this.studentId, required this.staffId, required this.noteCtrl});

  @override
  State<_CounsellingTab> createState() => _CounsellingTabState();
}

class _CounsellingTabState extends State<_CounsellingTab> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  String _selectedType = 'attendance';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getCounsellingNotes(widget.studentId);
      setState(() { _notes = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addNote() async {
    if (widget.noteCtrl.text.isEmpty) return;
    await SupabaseService.addCounsellingNote({
      'student_id': widget.studentId,
      'staff_id':   widget.staffId,
      'note':       widget.noteCtrl.text.trim(),
      'type':       _selectedType,
    });
    widget.noteCtrl.clear();
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    // Add note
    Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        TextField(
          controller: widget.noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Add counselling remark',
            prefixIcon: Icon(Icons.note_outlined),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Row(children: [
          DropdownButton<String>(
            value: _selectedType,
            items: ['attendance', 'academic', 'personal', 'general']
                .map((t) => DropdownMenuItem(value: t, child: Text(t.capitalize())))
                .toList(),
            onChanged: (v) => v != null ? setState(() => _selectedType = v) : null,
          ),
          const Spacer(),
          ElevatedButton(onPressed: _addNote, child: const Text('Add Note')),
        ]),
      ]),
    ),
    const Divider(height: 1),
    if (_loading)
      const AppLoading()
    else if (_notes.isEmpty)
      const Padding(padding: EdgeInsets.all(24),
        child: Text('No counselling records', style: TextStyle(color: AppColors.textSecondary)))
    else
      Expanded(child: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (_, i) {
          final n = _notes[i];
          final staff = n['staff'] as Map?;
          final staffProfile = staff?['profiles'] as Map?;
          return ListTile(
            leading: const Icon(Icons.note_outlined, color: AppColors.staffColor),
            title: Text(n['note'] as String, style: const TextStyle(fontSize: 13)),
            subtitle: Text('${staffProfile?['full_name'] ?? 'Staff'} • ${n['type']}',
                style: const TextStyle(fontSize: 11)),
          );
        },
      )),
  ]);
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
