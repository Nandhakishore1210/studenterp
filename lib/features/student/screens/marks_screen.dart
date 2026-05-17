import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/marks_model.dart';

class MarksScreen extends ConsumerWidget {
  const MarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksAsync = ref.watch(studentMarksProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Text('Internal Marks', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
      ),
      body: marksAsync.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 110),
        error: (e, _) => Center(child: Text(e.toString(),
            style: GoogleFonts.inter(color: AppColors.textSecondary))),
        data: (marks) {
          if (marks.isEmpty) {
            return Center(child: Text('No marks available',
                style: GoogleFonts.inter(color: AppColors.textSecondary)));
          }

          final grouped = groupBy(marks, (MarksModel m) => m.subjectId);
          final totalObt = marks.fold<double>(0, (s, m) => s + (m.obtainedMarks ?? 0));
          final totalMax = marks.fold<double>(0, (s, m) => s + m.maxMarks);
          final overallPct = totalMax > 0 ? totalObt / totalMax * 100 : 0.0;

          return ListView(children: [
            // ── Overall summary ──
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Overall Score', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${totalObt.toStringAsFixed(1)} / ${totalMax.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('${grouped.length} Subjects', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                ]),
                const Spacer(),
                SizedBox(
                  width: 72, height: 72,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: overallPct / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                    Text('${overallPct.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Text('Subject-wise Marks',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
            ),

            ...grouped.entries.map((e) {
              final subjectMarks = e.value;
              final name = subjectMarks.first.subject?.name ?? 'Subject';
              final code = subjectMarks.first.subject?.code ?? '';
              return _SubjectCard(name: name, code: code, marksList: subjectMarks);
            }),
            const SizedBox(height: 28),
          ]);
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String name, code;
  final List<MarksModel> marksList;
  const _SubjectCard({required this.name, required this.code, required this.marksList});

  double get obtained => marksList.fold(0.0, (s, m) => s + (m.obtainedMarks ?? 0));
  double get max      => marksList.fold(0.0, (s, m) => s + m.maxMarks);
  double get pct      => max > 0 ? obtained / max * 100 : 0;

  Color get _color => pct >= 75 ? const Color(0xFF22C55E) : pct >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1C1C1E))),
              const SizedBox(height: 2),
              Text(code, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${obtained.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _color)),
              const SizedBox(height: 2),
              Text('${pct.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        // Score bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 5,
              backgroundColor: _color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ),
        // Assessments
        ...marksList.map((m) => _AssessmentRow(m: m)),
        const SizedBox(height: 6),
      ]),
    );
  }
}

class _AssessmentRow extends StatelessWidget {
  final MarksModel m;
  const _AssessmentRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final obtained = m.obtainedMarks;
    final pct = m.percentage;
    final color = pct >= 75 ? const Color(0xFF22C55E) : pct >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final hasMarks = obtained != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: hasMarks ? color : AppColors.textHint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(m.displayAssessment,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151)))),
        if (!hasMarks)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
            child: Text('Pending', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
          )
        else ...[
          Text('${obtained!.toStringAsFixed(1)} / ${m.maxMarks.toStringAsFixed(0)}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 6),
          Container(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
