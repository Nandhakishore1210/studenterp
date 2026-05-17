import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/staff_provider.dart';
import '../../../core/constants/app_colors.dart';

class StaffShell extends ConsumerWidget {
  final Widget child;
  const StaffShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffRecordProvider);
    final location   = GoRouterState.of(context).matchedLocation;

    final staff = staffAsync.valueOrNull;
    final showPerforma = staff?.isMentor == true || staff?.isClassAdvisor == true;

    final tabs = [
      (icon: Icons.home_outlined,            activeIcon: Icons.home_rounded,             label: 'Home',     path: '/staff',               color: AppColors.staffColor),
      (icon: Icons.bar_chart_outlined,       activeIcon: Icons.bar_chart_rounded,        label: 'Reports',  path: '/staff/reports',       color: AppColors.staffColor),
      if (showPerforma)
        (icon: Icons.groups_outlined,        activeIcon: Icons.groups_rounded,           label: 'Performa', path: '/staff/performa',      color: AppColors.staffColor),
      (icon: Icons.notifications_outlined,   activeIcon: Icons.notifications_rounded,    label: 'Alerts',   path: '/staff/notifications', color: AppColors.staffColor),
      (icon: Icons.person_outline,           activeIcon: Icons.person_rounded,           label: 'Profile',  path: '/staff/profile',       color: AppColors.staffColor),
    ];

    int index = tabs.indexWhere((t) => t.path == location);
    if (index < 0) index = tabs.indexWhere((t) => location.startsWith('${t.path}/'));
    if (index < 0) index = 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: child,
        bottomNavigationBar: _StaffNavBar(tabs: tabs, index: index),
      ),
    );
  }
}

class _StaffNavBar extends StatelessWidget {
  final List<({IconData icon, IconData activeIcon, String label, String path, Color color})> tabs;
  final int index;
  const _StaffNavBar({required this.tabs, required this.index});

  @override
  Widget build(BuildContext context) {
    const c = AppColors.staffColor;
    const light = Color(0xFFF3EEFF);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final selected = i == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go(tab.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? light : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          selected ? tab.activeIcon : tab.icon,
                          color: selected ? c : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? c : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
