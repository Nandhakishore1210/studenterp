import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/superadmin_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../data/services/supabase_service.dart';

class SuperadminHome extends ConsumerWidget {
  const SuperadminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(superadminStatsProvider);
    final unisAsync  = ref.watch(allUniversitiesProvider);
    final profile    = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: RefreshIndicator(
        color: const Color(0xFF7C3AED),
        onRefresh: () async {
          ref.invalidate(superadminStatsProvider);
          ref.invalidate(allUniversitiesProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Hero
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFF4C1D95)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text('Student+', style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async { await ref.read(authProvider.notifier).signOut(); context.go('/'); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(children: [
                              Icon(Icons.logout_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Logout', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Super Admin', style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('Platform-wide control panel', style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.white.withOpacity(0.75))),
                        ]),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: statsAsync.when(
                  loading: () => const ShimmerList(count: 1, itemHeight: 80),
                  error: (e, _) => const SizedBox(),
                  data: (stats) => Row(children: [
                    _StatCard('Colleges',  '${stats['universities'] ?? 0}', Icons.school_rounded,         const Color(0xFF7C3AED)),
                    const SizedBox(width: 10),
                    _StatCard('Students',  '${stats['student'] ?? 0}',      Icons.person_rounded,          const Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    _StatCard('Staff',     '${stats['staff'] ?? 0}',        Icons.badge_rounded,           const Color(0xFF059669)),
                    const SizedBox(width: 10),
                    _StatCard('Admins',    '${stats['admin'] ?? 0}',        Icons.admin_panel_settings_rounded, const Color(0xFFD97706)),
                  ]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Quick Actions', style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _QuickAction(
                      icon: Icons.add_business_rounded,
                      label: 'Add College',
                      color: const Color(0xFF7C3AED),
                      onTap: () => context.push('/superadmin/add-college'),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.person_add_rounded,
                      label: 'Add Admin',
                      color: const Color(0xFF2563EB),
                      onTap: () => context.push('/superadmin/create-account'),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.people_rounded,
                      label: 'All Users',
                      color: const Color(0xFF059669),
                      onTap: () => context.go('/superadmin/users'),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.analytics_rounded,
                      label: 'Analytics',
                      color: const Color(0xFFDC2626),
                      onTap: () => context.go('/superadmin/colleges'),
                    ),
                  ]),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Colleges list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('All Colleges', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            unisAsync.when(
              loading: () => const SliverToBoxAdapter(child: ShimmerList(count: 4, itemHeight: 80)),
              error: (e, _) => SliverToBoxAdapter(child: AppError(message: e.toString())),
              data: (unis) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _CollegeRow(college: unis[i], ref: ref),
                  ),
                  childCount: unis.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

class _CollegeRow extends StatelessWidget {
  final Map<String, dynamic> college;
  final WidgetRef ref;
  const _CollegeRow({required this.college, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name     = college['name'] as String? ?? '';
    final code     = college['code'] as String? ?? '';
    final city     = college['city'] as String? ?? '';
    final isActive = college['is_active'] as bool? ?? true;
    final id       = college['id'] as String;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7C3AED).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(code.length > 4 ? code.substring(0, 4) : code,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800,
                    color: isActive ? const Color(0xFF7C3AED) : Colors.grey)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(city, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Switch(
          value: isActive,
          activeColor: const Color(0xFF7C3AED),
          onChanged: (v) async {
            await SupabaseService.toggleUniversity(id, v);
            ref.invalidate(allUniversitiesProvider);
          },
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.push('/superadmin/edit-college/$id'),
          child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textHint),
        ),
      ]),
    );
  }
}
