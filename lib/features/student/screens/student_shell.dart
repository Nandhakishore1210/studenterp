import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,       label: 'Home',       path: '/student'),
    (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded,  label: 'Attendance', path: '/student/attendance'),
    (icon: Icons.grade_outlined,     activeIcon: Icons.grade_rounded,      label: 'Marks',      path: '/student/marks'),
    (icon: Icons.task_outlined,      activeIcon: Icons.task_rounded,       label: 'Tasks',      path: '/student/assignments'),
    (icon: Icons.person_outline,     activeIcon: Icons.person_rounded,     label: 'Profile',    path: '/student/profile'),
  ];

  static int _activeIndex(String location) {
    // Exact match first, then prefix match — prevents '/student' from eating all sub-routes
    int i = _tabs.indexWhere((t) => t.path == location);
    if (i < 0) i = _tabs.indexWhere((t) => location.startsWith('${t.path}/'));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _activeIndex(location);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: child,
        bottomNavigationBar: _StudentNavBar(index: index),
      ),
    );
  }
}

class _StudentNavBar extends StatelessWidget {
  final int index;
  const _StudentNavBar({required this.index});

  @override
  Widget build(BuildContext context) {
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
            children: List.generate(StudentShell._tabs.length, (i) {
              final tab = StudentShell._tabs[i];
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          selected ? tab.activeIcon : tab.icon,
                          color: selected ? AppColors.primary : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppColors.primary : AppColors.textHint,
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
