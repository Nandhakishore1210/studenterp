import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(authProvider);
    final studentAsync = ref.watch(studentRecordProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false),
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: e.toString()),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            child: Column(children: [
              // Avatar section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      profile.fullName.isNotEmpty ? profile.fullName[0] : 'U',
                      style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(profile.email, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(profile.role.toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: 8),

              // Student details
              studentAsync.when(
                data: (s) {
                  if (s == null) return const SizedBox.shrink();
                  return _InfoSection('Academic Details', [
                    _InfoRow(Icons.badge_outlined,   'Register No',  s.registerNo),
                    _InfoRow(Icons.school_outlined,  'Department',   s.departmentName ?? '-'),
                    _InfoRow(Icons.book_outlined,    'Course',       s.courseName ?? '-'),
                    _InfoRow(Icons.format_list_numbered, 'Semester', 'Semester ${s.currentSemester}'),
                    _InfoRow(Icons.group_outlined,   'Batch',        s.batch),
                    if (s.section != null)
                      _InfoRow(Icons.class_outlined, 'Section',      s.section!),
                  ]);
                },
                loading: () => const ShimmerCard(height: 200),
                error: (_, __) => const SizedBox.shrink(),
              ),

              _InfoSection('Contact', [
                if (profile.phone != null)
                  _InfoRow(Icons.phone_outlined, 'Phone', profile.phone!),
                _InfoRow(Icons.email_outlined, 'Email', profile.email),
              ]),

              // Logout
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/');
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          );
        },
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _InfoSection(this.title, this.rows);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12)),
      ),
      ...rows,
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      const Spacer(),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
    ]),
  );
}
