import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/superadmin_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';

class SuperadminSettingsScreen extends ConsumerWidget {
  const SuperadminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Account Management'),
          _SettingsTile(
            icon: Icons.person_add_rounded,
            label: 'Create College Admin',
            subtitle: 'Add a new admin for any college',
            color: const Color(0xFF2563EB),
            onTap: () => context.push('/superadmin/create-account'),
          ),
          _SettingsTile(
            icon: Icons.add_business_rounded,
            label: 'Add New College',
            subtitle: 'Register a new institution',
            color: const Color(0xFF7C3AED),
            onTap: () => context.push('/superadmin/add-college'),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Demo Credentials'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _CredRow('Super Admin:', 'superadmin@studentplus.edu', const Color(0xFF7C3AED)),
              const SizedBox(height: 8),
              _CredRow('Password:', 'Pass@1234', AppColors.textSecondary),
            ]),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Session'),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            subtitle: 'Log out of superadmin panel',
            color: AppColors.error,
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary, letterSpacing: 0.5)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.subtitle,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
    ),
  );
}

class _CredRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CredRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
    const SizedBox(width: 8),
    Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  ]);
}
