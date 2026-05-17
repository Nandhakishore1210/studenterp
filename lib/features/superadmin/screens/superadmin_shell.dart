import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SuperadminShell extends StatelessWidget {
  final Widget child;
  const SuperadminShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard_rounded,      label: 'Dashboard',  path: '/superadmin'),
    (icon: Icons.school_outlined,       activeIcon: Icons.school_rounded,         label: 'Colleges',   path: '/superadmin/colleges'),
    (icon: Icons.people_outline,        activeIcon: Icons.people_rounded,         label: 'Users',      path: '/superadmin/users'),
    (icon: Icons.settings_outlined,     activeIcon: Icons.settings_rounded,       label: 'Settings',   path: '/superadmin/settings'),
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final sel = i == index;
                  const c = Color(0xFF7C3AED); // superadmin purple
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.go(tab.path),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFF3E8FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(sel ? tab.activeIcon : tab.icon,
                              color: sel ? c : AppColors.textHint, size: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(tab.label, style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel ? c : AppColors.textHint,
                        )),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
