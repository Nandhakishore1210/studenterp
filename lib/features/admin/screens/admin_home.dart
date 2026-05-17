import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

// Department color palette (cycles through)
const _deptColors = [
  Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFF059669),
  Color(0xFFDB2777), Color(0xFFD97706), Color(0xFF0891B2),
  Color(0xFFDC2626), Color(0xFF65A30D), Color(0xFF9333EA), Color(0xFF0369A1),
];

class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync  = ref.watch(authProvider);
    final uniNameAsync  = ref.watch(adminUniversityNameProvider);
    final deptAsync     = ref.watch(adminDeptStatsProvider);
    final lowAsync      = ref.watch(lowAttendanceProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: RefreshIndicator(
          color: AppColors.adminColor,
          displacement: 80,
          onRefresh: () async {
            ref.invalidate(adminDeptStatsProvider);
            ref.invalidate(lowAttendanceProvider);
            ref.invalidate(adminUniversityNameProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Hero ──────────────────────────────────────────
              SliverToBoxAdapter(child: _AdminHero(
                profileAsync: profileAsync,
                uniNameAsync: uniNameAsync,
                deptAsync: deptAsync,
                lowAsync: lowAsync,
                ref: ref,
              )),

              SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ── Departments ──────────────────────────────
                  const SizedBox(height: 20),
                  _SectionHeader('Departments', 'See All', () => context.go('/admin/users')),
                  const SizedBox(height: 12),
                  deptAsync.when(
                    loading: () => SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 4,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, __) => const ShimmerCard(height: 130, width: 140),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppError(message: e.toString()),
                    ),
                    data: (depts) => SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: depts.length,
                        itemBuilder: (_, i) => Padding(
                          padding: EdgeInsets.only(right: i < depts.length - 1 ? 10 : 0),
                          child: _DeptCard(dept: depts[i], color: _deptColors[i % _deptColors.length]),
                        ),
                      ),
                    ),
                  ),

                  // ── Quick Actions ─────────────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader('Quick Actions', null, null),
                  const SizedBox(height: 12),
                  const _AdminActionsGrid(),

                  // ── Low Attendance ────────────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader('Low Attendance Students', 'See All',
                      () => context.go('/admin/analytics')),
                  const SizedBox(height: 10),
                  lowAsync.when(
                    loading: () => const ShimmerList(count: 3, itemHeight: 70),
                    error: (e, _) => AppError(message: e.toString()),
                    data: (low) {
                      final top = low.take(5).toList();
                      if (top.isEmpty) return _AllGoodCard();
                      return Column(
                          children: top.map((r) => _LowAttendanceTile(record: r)).toList());
                    },
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

// ── Admin Hero ────────────────────────────────────────────────────
class _AdminHero extends StatelessWidget {
  final AsyncValue profileAsync;
  final AsyncValue<String?> uniNameAsync;
  final AsyncValue<List<Map<String, dynamic>>> deptAsync;
  final AsyncValue<List<Map<String, dynamic>>> lowAsync;
  final WidgetRef ref;
  const _AdminHero({
    required this.profileAsync,
    required this.uniNameAsync,
    required this.deptAsync,
    required this.lowAsync,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.adminGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(
          top: -20, right: -10,
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
          ),
        ),
        Positioned(
          top: 50, right: 50,
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // App bar row
              Row(children: [
                Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text('Student+',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/admin/notifications'),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/');
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // University name
              uniNameAsync.when(
                data: (name) => name == null ? const SizedBox() : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(name,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700,
                          letterSpacing: 0.3)),
                ),
                loading: () => const SizedBox(height: 24),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 8),

              // Greeting
              profileAsync.when(
                data: (p) => Text(
                  'Hello, ${p?.fullName.split(' ').first ?? 'Admin'}!',
                  style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
                      letterSpacing: -0.3),
                ),
                loading: () => const SizedBox(height: 28),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 2),
              Text('Admin Dashboard — Manage your institution',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
              const SizedBox(height: 20),

              // Stats row
              _buildStatsRow(deptAsync, lowAsync),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<Map<String, dynamic>>> deptAsync,
    AsyncValue<List<Map<String, dynamic>>> lowAsync,
  ) {
    final totalStudents = deptAsync.valueOrNull?.fold<int>(0, (s, d) => s + (d['student_count'] as int)) ?? 0;
    final totalStaff    = deptAsync.valueOrNull?.fold<int>(0, (s, d) => s + (d['staff_count'] as int)) ?? 0;
    final totalDepts    = deptAsync.valueOrNull?.length ?? 0;
    final lowCount      = lowAsync.valueOrNull
        ?.map((r) => r['student_id']).toSet().length ?? 0;

    if (deptAsync.isLoading) return const ShimmerCard(height: 80);

    return Row(children: [
      _HeroStat('Students', '$totalStudents', Icons.people_rounded, Colors.white),
      const SizedBox(width: 8),
      _HeroStat('Staff', '$totalStaff', Icons.person_rounded, const Color(0xFFFBBF24)),
      const SizedBox(width: 8),
      _HeroStat('Depts', '$totalDepts', Icons.school_rounded, const Color(0xFF86EFAC)),
      const SizedBox(width: 8),
      _HeroStat('Low Att.', '$lowCount', Icons.warning_amber_rounded, const Color(0xFFF87171)),
    ]);
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _HeroStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Department card ───────────────────────────────────────────────
class _DeptCard extends StatelessWidget {
  final Map<String, dynamic> dept;
  final Color color;
  const _DeptCard({required this.dept, required this.color});

  @override
  Widget build(BuildContext context) {
    final students = dept['student_count'] as int? ?? 0;
    final staff    = dept['staff_count'] as int? ?? 0;
    final code     = dept['code'] as String? ?? '';
    final name     = dept['name'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.go('/admin/users'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(code,
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800, color: color)),
            ),
          ),
          const SizedBox(height: 8),
          Text(name,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(children: [
            Icon(Icons.people_rounded, size: 12, color: color),
            const SizedBox(width: 3),
            Text('$students',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 8),
            Icon(Icons.person_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 3),
            Text('$staff',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint)),
          ]),
        ]),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────
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
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, letterSpacing: -0.2)),
      const Spacer(),
      if (actionLabel != null && onAction != null)
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFFCE7F3), borderRadius: BorderRadius.circular(8)),
            child: Text(actionLabel!,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.adminColor, fontWeight: FontWeight.w600)),
          ),
        ),
    ]),
  );
}

// ── Quick actions grid ────────────────────────────────────────────
class _AdminActionsGrid extends StatelessWidget {
  const _AdminActionsGrid();

  static const _actions = [
    (icon: Icons.people_rounded,      label: 'Manage\nUsers',     path: '/admin/users',          color: Color(0xFF2563EB), isTab: true),
    (icon: Icons.school_rounded,      label: 'Academic\nSetup',   path: '/admin/academic',       color: Color(0xFF7C3AED), isTab: false),
    (icon: Icons.tune_rounded,        label: 'Attendance\nRules', path: '/admin/rules',          color: Color(0xFF059669), isTab: true),
    (icon: Icons.analytics_rounded,   label: 'Analytics',         path: '/admin/analytics',      color: Color(0xFFDB2777), isTab: true),
    (icon: Icons.campaign_rounded,    label: 'Notifications',     path: '/admin/notifications',  color: Color(0xFFD97706), isTab: false),
    (icon: Icons.person_add_rounded,  label: 'Create\nAccount',   path: '/admin/create-account', color: Color(0xFF0891B2), isTab: false),
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
      childAspectRatio: 1.05,
      children: _actions.map((a) => _ActionTile(action: a)).toList(),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final ({IconData icon, String label, String path, Color color, bool isTab}) action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: () => action.isTab ? context.go(action.path) : context.push(action.path),
      borderRadius: BorderRadius.circular(16),
      splashColor: action.color.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, color: action.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(action.label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center, maxLines: 2),
        ]),
      ),
    ),
  );
}

// ── Low attendance tile ───────────────────────────────────────────
class _LowAttendanceTile extends StatelessWidget {
  final Map record;
  const _LowAttendanceTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final pct         = (record['effective_percentage'] as num?)?.toDouble() ?? 0;
    final eligibility = record['eligibility_status'] as String? ?? 'eligible';
    final statusColor = eligibility == 'detained' ? AppColors.error   : AppColors.warning;
    final statusBg    = eligibility == 'detained' ? AppColors.redLight : AppColors.yellowLight;
    final name        = record['student_name'] as String? ?? '?';
    final dept        = record['department'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: statusBg,
          child: Text(name[0],
              style: GoogleFonts.inter(
                  color: statusColor, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(
              '${record['subject_name'] ?? ''} • ${dept.length > 20 ? dept.substring(0, 18) + '…' : dept}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
            child: Text('${pct.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                    color: statusColor, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(eligibility == 'detained' ? 'Detained' : 'At Risk',
              style: GoogleFonts.inter(
                  fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _AllGoodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
        const SizedBox(height: 10),
        Text('All students have good attendance!',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}
