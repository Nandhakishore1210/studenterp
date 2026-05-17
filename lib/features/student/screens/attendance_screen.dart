import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/attendance_utils.dart';
import '../../../data/models/attendance_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendAsync = ref.watch(studentAttendanceProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shadowColor: AppColors.border,
              elevation: 0,
              scrolledUnderElevation: 1,
              title: Text('Attendance',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                  onPressed: () => _showInfo(ctx),
                ),
                const SizedBox(width: 4),
              ],
              systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
            ),
          ],
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(studentAttendanceProvider),
            child: attendAsync.when(
              loading: () => const ShimmerList(count: 5, itemHeight: 130),
              error: (e, _) => Center(
                child: Text(e.toString(), style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bar_chart_outlined, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No attendance data available',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                    ]),
                  );
                }
                final total    = list.fold<int>(0, (s, a) => s + a.totalClasses);
                final present  = list.fold<int>(0, (s, a) => s + a.effectivePresentCount);
                final pct      = total > 0 ? present / total * 100 : 0.0;
                final detained = list.where((a) => a.eligibilityStatus == 'detained').length;
                final atRisk   = list.where((a) => a.eligibilityStatus == 'at_risk').length;

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _OverallCard(pct: pct, total: total, present: present, detained: detained, atRisk: atRisk, subjectCount: list.length),
                    _MLODBanner(),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text('Subject-wise Breakdown',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2)),
                    ),
                    ...list.map((a) => _SubjectCard(a: a)),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('How It\'s Calculated', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoSection('Raw Attendance', 'Classes attended ÷ Total conducted × 100'),
          const SizedBox(height: 12),
          _InfoSection('ML/OD Rule', 'Applied only when raw attendance ≥ 65%'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _Legend(color: AppColors.attendanceGreen, label: '≥ 75% — Eligible'),
          const SizedBox(height: 8),
          _Legend(color: AppColors.attendanceYellow, label: '65–74% — At Risk'),
          const SizedBox(height: 8),
          _Legend(color: AppColors.attendanceRed, label: '< 65% — Detained'),
        ]),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title, body;
  const _InfoSection(this.title, this.body);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
    const SizedBox(height: 4),
    Text(body, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
  ]);
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 12, height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    ),
    const SizedBox(width: 10),
    Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
  ]);
}

// ── Overall card ─────────────────────────────────────────────────
class _OverallCard extends StatelessWidget {
  final double pct;
  final int total, present, detained, atRisk, subjectCount;
  const _OverallCard({required this.pct, required this.total, required this.present,
    required this.detained, required this.atRisk, required this.subjectCount});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.attendanceColor(pct);
    final label = pct >= 75 ? 'Eligible' : pct >= 65 ? 'At Risk' : 'Detained';
    final bgColor = AppColors.attendanceLightColor(pct);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Top portion
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Row(children: [
            // Circular gauge
            SizedBox(
              width: 96, height: 96,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation(color.withOpacity(0.1)),
                  strokeCap: StrokeCap.round,
                ),
                CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${pct.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
                  Text('overall', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textHint)),
                ]),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(children: [
              _ORow('Present', '$present / $total', AppColors.textPrimary),
              const SizedBox(height: 8),
              _ORow('Subjects', '$subjectCount', AppColors.textPrimary),
              const SizedBox(height: 8),
              _ORow('At Risk', '$atRisk', atRisk > 0 ? AppColors.warning : AppColors.textPrimary),
              const SizedBox(height: 8),
              _ORow('Detained', '$detained', detained > 0 ? AppColors.error : AppColors.textPrimary),
            ])),
          ]),
        ),

        // Bottom status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
              ]),
              Text('${pct.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _ORow extends StatelessWidget {
  final String l, v;
  final Color c;
  const _ORow(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(l, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
    const Spacer(),
    Text(v, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
  ]);
}

class _MLODBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'ML/OD classes are counted only if raw attendance ≥ 65%.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
        )),
      ]),
    ),
  );
}

// ── Subject card ─────────────────────────────────────────────────
class _SubjectCard extends StatelessWidget {
  final AttendanceEffective a;
  const _SubjectCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final pct   = a.effectivePercentage;
    final color = AppColors.attendanceColor(pct);
    final bg    = AppColors.attendanceLightColor(pct);
    final label = a.eligibilityStatus == 'detained' ? 'Detained'
        : a.eligibilityStatus == 'at_risk' ? 'At Risk' : 'Eligible';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.subject?.name ?? 'Subject',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(a.subject?.code ?? '',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${pct.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ),
            ]),
          ]),
        ),

        // Stats and bar
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              _StatBox('Total',   '${a.totalClasses}',              const Color(0xFF64748B)),
              const SizedBox(width: 8),
              _StatBox('Present', '${a.presentCount}',              AppColors.success),
              const SizedBox(width: 8),
              _StatBox('Absent',  '${a.totalClasses - a.presentCount}', AppColors.error),
              if (a.mlOdCount > 0) ...[
                const SizedBox(width: 8),
                _StatBox('ML/OD', '${a.mlOdCount}',                AppColors.info),
              ],
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 7,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (a.eligibilityStatus != 'eligible') ...[
              const SizedBox(height: 10),
              _HintBanner(a: a, color: color, bg: bg),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(children: [
      Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    ]),
  ));
}

class _HintBanner extends StatelessWidget {
  final AttendanceEffective a;
  final Color color, bg;
  const _HintBanner({required this.a, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) {
    final toReach = AttendanceUtils.classesToReach75(a.totalClasses, a.effectivePresentCount);
    final canMiss = AttendanceUtils.classesCanMiss(a.totalClasses, a.effectivePresentCount);
    final detained = a.eligibilityStatus == 'detained';
    final text = detained
        ? 'Attend $toReach more classes to reach 75%'
        : canMiss > 0
            ? 'You can safely miss $canMiss more classes'
            : 'Attend $toReach more classes to reach 75%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(Icons.lightbulb_outline_rounded, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
