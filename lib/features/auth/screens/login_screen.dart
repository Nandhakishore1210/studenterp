import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final err = await ref.read(authProvider.notifier).signIn(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final profile = ref.read(authProvider).valueOrNull;
    if (profile == null) return;
    switch (profile.role) {
      case 'superadmin': context.go('/superadmin'); break;
      case 'admin':      context.go('/admin');      break;
      case 'staff':      context.go('/staff');      break;
      default:           context.go('/student');    break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(selectedRoleProvider) ?? 'student';
    final university = ref.watch(selectedUniversityProvider);

    final roleConfig = switch (role) {
      'staff' => (
        label: 'Teacher',
        color: AppColors.staffColor,
        gradient: AppColors.staffGradient,
        icon: Icons.school_rounded,
        hint: 'Use your employee email',
      ),
      'admin' => (
        label: 'Admin',
        color: AppColors.adminColor,
        gradient: AppColors.adminGradient,
        icon: Icons.admin_panel_settings_rounded,
        hint: 'Use your admin email',
      ),
      _ => (
        label: 'Student',
        color: AppColors.studentColor,
        gradient: AppColors.studentGradient,
        icon: Icons.person_rounded,
        hint: 'Use your register number or email',
      ),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + university
                  Row(children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                    if (university != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleConfig.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: roleConfig.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(university['code'] as String,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: roleConfig.color)),
                        ]),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 32),

                  // Role icon
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: roleConfig.gradient,
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: roleConfig.color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Icon(roleConfig.icon, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  Text('${roleConfig.label}\nSign In',
                      style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary, height: 1.15, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text(roleConfig.hint,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                  if (university != null) ...[
                    const SizedBox(height: 4),
                    Text(university['name'] as String,
                        style: GoogleFonts.inter(fontSize: 13, color: roleConfig.color, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 32),

                  // Email field
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: role == 'student' ? 'Email / Register No' : 'Email',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: roleConfig.color, width: 2)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 14),

                  // Password field
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: roleConfig.color, width: 2)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Enter your password' : null,
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(foregroundColor: roleConfig.color),
                      child: Text('Forgot Password?',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: roleConfig.color)),
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.redLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!,
                            style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
                      ]),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 8),

                  // Sign in button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: roleConfig.color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        shadowColor: roleConfig.color.withOpacity(0.4),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text('Sign In as ${roleConfig.label}',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Demo credentials
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text('Demo Credentials',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 10),
                      _demoRow('Password (all):', 'Pass@1234', roleConfig.color),
                      const SizedBox(height: 6),
                      _demoRow('Admin:', 'admin@kct.edu', roleConfig.color),
                      const SizedBox(height: 6),
                      _demoRow('Staff:', 'staff.kct.cse1@kct.edu', roleConfig.color),
                      const SizedBox(height: 6),
                      _demoRow('Student:', 'stu.kct.cse.a.1@student.edu', roleConfig.color),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoRow(String label, String value, Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(width: 4),
      Expanded(child: Text(value,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
    ],
  );
}
