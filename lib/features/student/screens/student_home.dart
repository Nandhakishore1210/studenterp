import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/student_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_loading.dart';

class StudentHome extends ConsumerWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(authProvider);
    final studentAsync = ref.watch(studentRecordProvider);
    final attendAsync  = ref.watch(studentAttendanceProvider);
    final notifAsync   = ref.watch(studentNotificationsProvider);
    final assignAsync  = ref.watch(studentAssignmentsProvider);
    final unread = notifAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: RefreshIndicator(
          color: AppColors.primary,
          displacement: 80,
          onRefresh: () async {
            ref.invalidate(studentAttendanceProvider);
            ref.invalidate(studentAssignmentsProvider);
            ref.invalidate(studentNotificationsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Gradient hero ─────────────────────────────────
              SliverToBoxAdapter(child: _HeroSection(
                profileAsync: profileAsync,
                studentAsync: studentAsync,
                unread: unread,
              )),

              SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ── Attendance overview ──────────────────────
                  const SizedBox(height: 20),
                  _SectionHeader('Attendance Overview', 'See All',
                      () => context.go('/student/attendance')),
                  const SizedBox(height: 10),
                  attendAsync.when(
                    data: (list) => list.isEmpty
                        ? const _EmptyCard('No attendance data yet')
                        : _AttendanceSummaryCard(attendanceList: list),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ShimmerCard(height: 110),
                    ),
                    error: (e, _) => _ErrCard(e.toString()),
                  ),

                  // ── Quick access ─────────────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader('Quick Access', null, null),
                  const SizedBox(height: 12),
                  const _QuickGrid(),

                  // ── Pending assignments ──────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader('Pending Assignments', 'See All',
                      () => context.go('/student/assignments')),
                  const SizedBox(height: 10),
                  assignAsync.when(
                    data: (list) {
                      final pending = list.where((a) => !a.isSubmitted).take(3).toList();
                      return pending.isEmpty
                          ? const _EmptyCard('All assignments submitted!')
                          : Column(children: pending.map((a) => _AssignmentItem(a: a)).toList());
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ShimmerCard(height: 70),
                    ),
                    error: (e, _) => _ErrCard(e.toString()),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Section ────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final AsyncValue profileAsync;
  final AsyncValue studentAsync;
  final int unread;
  const _HeroSection({required this.profileAsync, required this.studentAsync, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.studentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 40, right: 60,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // App bar row
                Row(children: [
                  // App brand
                  Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text('Student+',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                  ]),
                  const Spacer(),
                  // Notification bell
                  GestureDetector(
                    onTap: () => context.push('/student/notifications'),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                        if (unread > 0)
                          Positioned(
                            right: 8, top: 8,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Greeting
                profileAsync.when(
                  data: (p) => Text(
                    'Hello, ${p?.fullName.split(' ').first ?? 'Student'}!',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
                  ),
                  loading: () => const SizedBox(height: 30),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 4),
                Text('Welcome back to your dashboard',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                const SizedBox(height: 16),

                // Student info card
                studentAsync.when(
                  data: (s) {
                    if (s == null) return const SizedBox();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Text(
                            s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
                            style: GoogleFonts.inter(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.fullName,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(s.registerNo,
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        ])),
                        const SizedBox(width: 8),
                        Wrap(spacing: 6, children: [
                          _HeroChip('Sem ${s.currentSemester}'),
                          if (s.section != null) _HeroChip(s.section!),
                        ]),
                      ]),
                    );
                  },
                  loading: () => const ShimmerCard(height: 60),
                  error: (_, __) => const SizedBox(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String text;
  const _HeroChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

// ── Section header ───────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader(this.title, this.actionLabel, this.onAction);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      Text(title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2)),
      const Spacer(),
      if (actionLabel != null && onAction != null)
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(actionLabel!,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
    ]),
  );
}

// ── Attendance summary card ──────────────────────────────────────
class _AttendanceSummaryCard extends StatelessWidget {
  final List attendanceList;
  const _AttendanceSummaryCard({required this.attendanceList});

  @override
  Widget build(BuildContext context) {
    final overall = attendanceList.map((a) => a.effectivePercentage as double).reduce((a, b) => a + b)
        / attendanceList.length;
    final detained = attendanceList.where((a) => a.eligibilityStatus == 'detained').length;
    final atRisk   = attendanceList.where((a) => a.eligibilityStatus == 'at_risk').length;
    final color    = AppColors.attendanceColor(overall);
    final bgColor  = AppColors.attendanceLightColor(overall);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        // Circular progress
        SizedBox(
          width: 84, height: 84,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: overall / 100,
              strokeWidth: 7,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${overall.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              Text('avg', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textHint)),
            ]),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(child: Column(children: [
          _StatRow('Total Subjects', '${attendanceList.length}', AppColors.textPrimary),
          const SizedBox(height: 8),
          _StatRow('At Risk', '$atRisk', atRisk > 0 ? AppColors.warning : AppColors.textPrimary),
          const SizedBox(height: 8),
          _StatRow('Detained', '$detained', detained > 0 ? AppColors.error : AppColors.textPrimary),
        ])),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Icon(overall >= 75 ? Icons.check_circle_outline_rounded
                : overall >= 65 ? Icons.warning_amber_rounded
                : Icons.cancel_outlined,
                color: color, size: 20),
            const SizedBox(height: 4),
            Text(overall >= 75 ? 'Good' : overall >= 65 ? 'Risk' : 'Low',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _StatRow(this.label, this.value, this.valueColor);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
    const Spacer(),
    Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
  ]);
}

// ── Quick access grid ────────────────────────────────────────────
class _QuickGrid extends StatelessWidget {
  const _QuickGrid();

  // isTab=true → context.go (shell tab), isTab=false → context.push (full-page)
  static const _items = [
    (icon: Icons.calendar_today_rounded, label: 'Timetable', path: '/student/timetable', color: Color(0xFF2563EB), isTab: false),
    (icon: Icons.grade_rounded,          label: 'Marks',     path: '/student/marks',     color: Color(0xFF7C3AED), isTab: true),
    (icon: Icons.receipt_long_rounded,   label: 'Fees',      path: '/student/fees',      color: Color(0xFF059669), isTab: false),
    (icon: Icons.event_note_rounded,     label: 'Exams',     path: '/student/exams',     color: Color(0xFFDC2626), isTab: false),
    (icon: Icons.folder_open_rounded,    label: 'Materials', path: '/student/materials', color: Color(0xFFD97706), isTab: false),
    (icon: Icons.insert_chart_rounded,   label: 'Results',   path: '/student/results',   color: Color(0xFF0891B2), isTab: false),
    (icon: Icons.event_available_rounded, label: 'Apply OD', path: '/student/apply-od',  color: Color(0xFF7C3AED), isTab: false),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: _items.map((e) => _QuickTile(item: e)).toList(),
    ),
  );
}

class _QuickTile extends StatelessWidget {
  final ({IconData icon, String label, String path, Color color, bool isTab}) item;
  const _QuickTile({required this.item});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: () => item.isTab ? context.go(item.path) : context.push(item.path),
      borderRadius: BorderRadius.circular(16),
      splashColor: item.color.withOpacity(0.08),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(item.label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

// ── Assignment item ──────────────────────────────────────────────
class _AssignmentItem extends StatelessWidget {
  final dynamic a;
  const _AssignmentItem({required this.a});

  String _due(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0)  return 'Overdue';
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    return 'Due ${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final overdue  = a.isOverdue as bool;
    final dueLabel = _due(a.dueDate as DateTime);
    final badgeColor = overdue ? AppColors.error   : AppColors.warning;
    final badgeBg    = overdue ? AppColors.redLight : AppColors.yellowLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/student/assignments'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title as String,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(a.subject?.name as String? ?? '',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                child: Text(dueLabel,
                    style: GoogleFonts.inter(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String msg;
  const _EmptyCard(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 32),
      const SizedBox(height: 8),
      Text(msg, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
    ])),
  );
}

class _ErrCard extends StatelessWidget {
  final String msg;
  const _ErrCard(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.redLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error.withOpacity(0.2)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: GoogleFonts.inter(color: AppColors.error, fontSize: 12))),
    ]),
  );
}
