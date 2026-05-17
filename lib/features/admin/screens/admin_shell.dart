import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_outlined,  activeIcon: Icons.dashboard_rounded,  label: 'Dashboard', path: '/admin',           color: AppColors.adminColor),
    (icon: Icons.people_outlined,     activeIcon: Icons.people_rounded,     label: 'Users',     path: '/admin/users',     color: AppColors.adminColor),
    (icon: Icons.analytics_outlined,  activeIcon: Icons.analytics_rounded,  label: 'Analytics', path: '/admin/analytics', color: AppColors.adminColor),
    (icon: Icons.tune_outlined,       activeIcon: Icons.tune_rounded,       label: 'Settings',  path: '/admin/rules',     color: AppColors.adminColor),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int index = _tabs.indexWhere((t) => t.path == location);
    if (index < 0) index = _tabs.indexWhere((t) => location.startsWith('${t.path}/'));
    if (index < 0) index = 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: child,
        bottomNavigationBar: _AdminNavBar(index: index),
      ),
    );
  }
}

class _AdminNavBar extends StatelessWidget {
  final int index;
  const _AdminNavBar({required this.index});

  @override
  Widget build(BuildContext context) {
    const c = AppColors.adminColor;
    const light = Color(0xFFFCE7F3);
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
            children: List.generate(AdminShell._tabs.length, (i) {
              final tab = AdminShell._tabs[i];
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
