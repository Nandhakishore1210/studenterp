import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/staff_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

class StaffHome extends ConsumerWidget {
  const StaffHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync     = ref.watch(authProvider);
    final staffAsync       = ref.watch(staffRecordProvider);
    final assignmentsAsync = ref.watch(staffSubjectAssignmentsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: RefreshIndicator(
          color: AppColors.staffColor,
          displacement: 80,
          onRefresh: () async {
            ref.invalidate(staffSubjectAssignmentsProvider);
            ref.invalidate(staffRecordProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Gradient hero ──────────────────────────────
              SliverToBoxAdapter(child: _StaffHero(
                profileAsync: profileAsync,
                staffAsync: staffAsync,
              )),

              // ── Body ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('My Subjects',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary, letterSpacing: -0.2)),
                  ),
                  const SizedBox(height: 12),
                  assignmentsAsync.when(
                    loading: () => const ShimmerList(count: 3, itemHeight: 130),
                    error: (e, _) => AppError(message: e.toString()),
                    data: (assignments) {
                      if (assignments.isEmpty) {
                        return _EmptySubjects();
                      }
                      return Column(
                        children: assignments.map((a) => _SubjectCard(assignment: a)).toList(),
                      );
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

// ── Staff Hero ───────────────────────────────────────────────────
class _StaffHero extends StatelessWidget {
  final AsyncValue profileAsync;
  final AsyncValue staffAsync;
  const _StaffHero({required this.profileAsync, required this.staffAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.staffGradient,
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
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 50, right: 50,
          child: Container(
            width: 70, height: 70,
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
              // App bar
              Row(children: [
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
                GestureDetector(
                  onTap: () => context.go('/staff/notifications'),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // Greeting
              profileAsync.when(
                data: (p) => Text(
                  'Hello, ${p?.fullName.split(' ').first ?? 'Teacher'}!',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
                ),
                loading: () => const SizedBox(height: 30),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 4),
              Text('Manage your classes below',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.75))),
              const SizedBox(height: 16),

              // Staff card
              staffAsync.when(
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
                        Text(s.designation ?? s.departmentName ?? s.employeeId,
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      ])),
                      const SizedBox(width: 8),
                      Wrap(spacing: 6, children: [
                        if (s.isFaculty)      _HeroChip('Faculty'),
                        if (s.isMentor)       _HeroChip('Mentor'),
                        if (s.isClassAdvisor) _HeroChip('Advisor'),
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
      ]),
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

// ── Subject card ─────────────────────────────────────────────────
class _SubjectCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  const _SubjectCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final subject = assignment['subjects'] as Map?;
    final id      = assignment['id'] as String;

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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F5FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.staffGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.book_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(subject?['name'] as String? ?? 'Subject',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subject?['code'] as String? ?? '',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            ])),
            if (assignment['section'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.staffColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Sec ${assignment['section']}',
                    style: GoogleFonts.inter(color: AppColors.staffColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
          ]),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _ActionBtn(
              icon: Icons.people_outline_rounded,
              label: 'Students',
              color: const Color(0xFF0891B2),
              onTap: () => context.push('/staff/subject/$id'),
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.how_to_reg_rounded,
              label: 'Attendance',
              color: const Color(0xFF2563EB),
              onTap: () => context.push('/staff/mark-attendance/$id'),
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.grade_rounded,
              label: 'Marks',
              color: const Color(0xFF7C3AED),
              onTap: () => context.push('/staff/marks/$id'),
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.folder_open_rounded,
              label: 'Materials',
              color: const Color(0xFFD97706),
              onTap: () => context.push('/staff/materials/$id'),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: Material(
    color: color.withOpacity(0.06),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: color.withOpacity(0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
        ]),
      ),
    ),
  ));
}

class _EmptySubjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.book_outlined, size: 40, color: AppColors.textHint),
      const SizedBox(height: 12),
      Text('No subjects assigned', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text('Contact admin if this is unexpected', style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 12)),
    ])),
  );
}
