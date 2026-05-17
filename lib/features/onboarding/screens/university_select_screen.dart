import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class UniversitySelectScreen extends ConsumerWidget {
  const UniversitySelectScreen({super.key});

  static const _colleges = [
    {
      'name': 'Kumaraguru College of Technology',
      'code': 'KCT',  'city': 'Coimbatore', 'est': '1984',
      'color': 0xFF1D4ED8, 'abbr': 'KCT',
      'adminEmail':   'admin@kct.edu',
      'staffEmail':   'staff.kct.cse1@kct.edu',
      'studentEmail': 'stu.kct.cse.a.1@student.edu',
    },
    {
      'name': 'Sri Krishna College of Technology',
      'code': 'SKCT', 'city': 'Coimbatore', 'est': '2001',
      'color': 0xFF16A34A, 'abbr': 'SKCT',
      'adminEmail':   'admin@skct.edu',
      'staffEmail':   'staff.skct.cse1@skct.edu',
      'studentEmail': 'stu.skct.cse.a.1@student.edu',
    },
    {
      'name': 'PSG College of Technology',
      'code': 'PSG',  'city': 'Coimbatore', 'est': '1951',
      'color': 0xFF7C3AED, 'abbr': 'PSG',
      'adminEmail':   'admin@psg.edu',
      'staffEmail':   'staff.psg.cse1@psg.edu',
      'studentEmail': 'stu.psg.cse.a.1@student.edu',
    },
    {
      'name': 'Eeshwar Engineering College',
      'code': 'ESH',  'city': 'Coimbatore', 'est': '2009',
      'color': 0xFFDC2626, 'abbr': 'ESH',
      'adminEmail':   'admin@esh.edu',
      'staffEmail':   'staff.esh.cse1@esh.edu',
      'studentEmail': 'stu.esh.cse.a.1@student.edu',
    },
    {
      'name': 'Karpagam College of Engineering',
      'code': 'KCE',  'city': 'Coimbatore', 'est': '2001',
      'color': 0xFF0D9488, 'abbr': 'KCE',
      'adminEmail':   'admin@kce.edu',
      'staffEmail':   'staff.kce.cse1@kce.edu',
      'studentEmail': 'stu.kce.cse.a.1@student.edu',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Brand
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.studentGradient,
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Student+',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary, letterSpacing: -0.5)),
                        Text('Campus ERP Platform',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      ]),
                    ]),
                    const SizedBox(height: 32),
                    Text('Select your\nInstitution',
                        style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary, height: 1.15, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text('Choose the college you belong to',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),

              // College list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final college = Map<String, dynamic>.from(_colleges[i]);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CollegeCard(
                          college: college,
                          onTap: () {
                            ref.read(selectedUniversityProvider.notifier).state = college;
                            ctx.push('/select-role');
                          },
                        ),
                      );
                    },
                    childCount: _colleges.length,
                  ),
                ),
              ),

              // Demo credentials section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: _DemoCredentialsSection(colleges: _colleges),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demo credentials ──────────────────────────────────────────────
class _DemoCredentialsSection extends StatefulWidget {
  final List<Map<String, dynamic>> colleges;
  const _DemoCredentialsSection({required this.colleges});

  @override
  State<_DemoCredentialsSection> createState() => _DemoCredentialsSectionState();
}

class _DemoCredentialsSectionState extends State<_DemoCredentialsSection> {
  bool _expanded = false;
  int _selectedCollege = 0;

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied: $text', style: GoogleFonts.inter(fontSize: 13)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final college = widget.colleges[_selectedCollege];
    final color = Color(college['color'] as int);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // Header — always visible
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textHint),
              const SizedBox(width: 8),
              Text('Demo Credentials',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const Spacer(),
              Text('Pass@1234',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _copy('Pass@1234'),
                child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textHint),
              ),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18, color: AppColors.textHint),
            ]),
          ),
        ),

        if (_expanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // College tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(widget.colleges.length, (i) {
                    final c = widget.colleges[i];
                    final col = Color(c['color'] as int);
                    final sel = i == _selectedCollege;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCollege = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? col : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c['abbr'] as String,
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : AppColors.textSecondary)),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),

              // Password row
              _CredRow(
                icon: Icons.lock_outline_rounded,
                label: 'Password',
                value: 'Pass@1234',
                color: AppColors.textSecondary,
                onCopy: () => _copy('Pass@1234'),
              ),
              const SizedBox(height: 8),
              _CredRow(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin',
                value: college['adminEmail'] as String,
                color: color,
                onCopy: () => _copy(college['adminEmail'] as String),
              ),
              const SizedBox(height: 8),
              _CredRow(
                icon: Icons.person_outlined,
                label: 'Staff',
                value: college['staffEmail'] as String,
                color: color,
                onCopy: () => _copy(college['staffEmail'] as String),
              ),
              const SizedBox(height: 8),
              _CredRow(
                icon: Icons.school_outlined,
                label: 'Student',
                value: college['studentEmail'] as String,
                color: color,
                onCopy: () => _copy(college['studentEmail'] as String),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _CredRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback onCopy;
  const _CredRow({
    required this.icon, required this.label,
    required this.value, required this.color, required this.onCopy,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 6),
    SizedBox(
      width: 56,
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
    ),
    Expanded(
      child: Text(value,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis),
    ),
    GestureDetector(
      onTap: onCopy,
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.copy_rounded, size: 13, color: AppColors.textHint),
      ),
    ),
  ]);
}

// ── College card ───────────────────────────────────────────────────
class _CollegeCard extends StatelessWidget {
  final Map<String, dynamic> college;
  final VoidCallback onTap;
  const _CollegeCard({required this.college, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(college['color'] as int);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(college['abbr'] as String,
                    style: GoogleFonts.inter(
                        color: color, fontWeight: FontWeight.w800, fontSize: 11),
                    textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(college['name'] as String,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(college['city'] as String,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 8),
                Container(width: 3, height: 3,
                    decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('Est. ${college['est']}',
                    style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 12)),
              ]),
            ])),
            Icon(Icons.chevron_right_rounded, color: color, size: 22),
          ]),
        ),
      ),
    );
  }
}
