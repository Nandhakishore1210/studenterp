import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  static const _roles = [
    {
      'key': 'student',
      'label': 'Student',
      'desc': 'View attendance, marks, timetable & assignments',
      'icon': Icons.person_rounded,
      'color': 0xFF2563EB,
      'gradient': [0xFF1D4ED8, 0xFF3B82F6],
    },
    {
      'key': 'staff',
      'label': 'Teacher / Staff',
      'desc': 'Mark attendance, enter marks & manage classes',
      'icon': Icons.school_rounded,
      'color': 0xFF7C3AED,
      'gradient': [0xFF5B21B6, 0xFF7C3AED],
    },
    {
      'key': 'admin',
      'label': 'Administrator',
      'desc': 'Manage users, departments & view analytics',
      'icon': Icons.admin_panel_settings_rounded,
      'color': 0xFFDB2777,
      'gradient': [0xFF9D174D, 0xFFDB2777],
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final university = ref.watch(selectedUniversityProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => context.pop(),
                    color: AppColors.textPrimary,
                  ),
                  if (university != null)
                    Expanded(
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Color(university['color'] as int).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              university['abbr'] as String,
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800,
                                  color: Color(university['color'] as int)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          university['name'] as String,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        )),
                      ]),
                    ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Who are\nyou?',
                      style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary, height: 1.15, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('Select your role to continue',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                ]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: _roles.map((role) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RoleCard(
                        role: role,
                        onTap: () {
                          ref.read(selectedRoleProvider.notifier).state = role['key'] as String;
                          context.push('/login');
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Map<String, dynamic> role;
  final VoidCallback onTap;
  const _RoleCard({required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(role['color'] as int);
    final gradColors = (role['gradient'] as List).map((c) => Color(c as int)).toList();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(children: [
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(role['icon'] as IconData, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(role['label'] as String,
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(role['desc'] as String,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ])),
            const SizedBox(width: 8),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_rounded, color: color, size: 18),
            ),
          ]),
        ),
      ),
    );
  }
}
