import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/screens/university_select_screen.dart';
import '../../features/onboarding/screens/role_select_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';

import '../../features/student/screens/student_shell.dart';
import '../../features/student/screens/student_home.dart';
import '../../features/student/screens/attendance_screen.dart';
import '../../features/student/screens/marks_screen.dart';
import '../../features/student/screens/assignments_screen.dart';
import '../../features/student/screens/profile_screen.dart';
// Pushed student screens (no bottom nav)
import '../../features/student/screens/timetable_screen.dart';
import '../../features/student/screens/materials_screen.dart';
import '../../features/student/screens/notifications_screen.dart';
import '../../features/student/screens/fees_screen.dart';
import '../../features/student/screens/results_screen.dart';
import '../../features/student/screens/exam_schedule_screen.dart';

import '../../features/staff/screens/staff_shell.dart';
import '../../features/staff/screens/staff_home.dart';
import '../../features/staff/screens/reports_screen.dart';
import '../../features/staff/screens/performa_screen.dart';
// Pushed staff screens (no bottom nav)
import '../../features/staff/screens/mark_attendance_screen.dart';
import '../../features/staff/screens/enter_marks_screen.dart';
import '../../features/staff/screens/upload_materials_screen.dart';
import '../../features/staff/screens/manage_assignments_screen.dart';
import '../../features/staff/screens/subject_detail_screen.dart';
import '../../features/student/screens/apply_od_screen.dart';

import '../../features/superadmin/screens/superadmin_shell.dart';
import '../../features/superadmin/screens/superadmin_home.dart';
import '../../features/superadmin/screens/manage_colleges_screen.dart';
import '../../features/superadmin/screens/superadmin_users_screen.dart';
import '../../features/superadmin/screens/superadmin_settings_screen.dart';

import '../../features/admin/screens/admin_shell.dart';
import '../../features/admin/screens/admin_home.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/attendance_rules_screen.dart';
import '../../features/admin/screens/analytics_screen.dart';
// Pushed admin screens (no bottom nav)
import '../../features/admin/screens/academic_setup_screen.dart';
import '../../features/admin/screens/create_account_screen.dart';

import '../../data/services/supabase_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final supabase = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final session = supabase.auth.currentSession;
      final isLoggedIn = session != null;
      final loc = state.matchedLocation;

      const onboardingPaths = ['/', '/select-role', '/login', '/forgot-password'];
      final isOnboarding = onboardingPaths.contains(loc);

      if (!isLoggedIn && !isOnboarding) return '/';
      if (isLoggedIn && isOnboarding) {
        try {
          final profile = await SupabaseService.getMyProfile();
          switch (profile?['role']) {
            case 'superadmin': return '/superadmin';
            case 'admin':      return '/admin';
            case 'staff':      return '/staff';
            default:           return '/student';
          }
        } catch (_) {
          return '/student';
        }
      }
      return null;
    },
    routes: [
      // ── Onboarding & Auth (no shell) ─────────────────────────
      GoRoute(path: '/',                  builder: (_, __) => const UniversitySelectScreen()),
      GoRoute(path: '/select-role',       builder: (_, __) => const RoleSelectScreen()),
      GoRoute(path: '/login',             builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/forgot-password',   builder: (_, __) => const ForgotPasswordScreen()),

      // ── Superadmin Shell ──────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => SuperadminShell(child: child),
        routes: [
          GoRoute(path: '/superadmin',          builder: (_, __) => const SuperadminHome()),
          GoRoute(path: '/superadmin/colleges', builder: (_, __) => const ManageCollegesScreen()),
          GoRoute(path: '/superadmin/users',    builder: (_, __) => const SuperadminUsersScreen()),
          GoRoute(path: '/superadmin/settings', builder: (_, __) => const SuperadminSettingsScreen()),
        ],
      ),
      GoRoute(path: '/superadmin/add-college',       builder: (_, __) => const AddEditCollegeScreen()),
      GoRoute(path: '/superadmin/create-account',    builder: (_, __) => const CreateAccountScreen()),
      GoRoute(
        path: '/superadmin/edit-college/:id',
        builder: (_, state) => AddEditCollegeScreen(collegeId: state.pathParameters['id']),
      ),

      // ── Student Shell — tab screens (show bottom nav) ─────────
      ShellRoute(
        builder: (_, __, child) => StudentShell(child: child),
        routes: [
          GoRoute(path: '/student',             builder: (_, __) => const StudentHome()),
          GoRoute(path: '/student/attendance',  builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: '/student/marks',       builder: (_, __) => const MarksScreen()),
          GoRoute(path: '/student/assignments', builder: (_, __) => const AssignmentsScreen()),
          GoRoute(path: '/student/profile',     builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Student pushed screens (full-page, no bottom nav) ─────
      GoRoute(path: '/student/timetable',     builder: (_, __) => const TimetableScreen()),
      GoRoute(path: '/student/apply-od',      builder: (_, __) => const ApplyOdScreen()),
      GoRoute(path: '/student/materials',     builder: (_, __) => const MaterialsScreen()),
      GoRoute(path: '/student/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/student/fees',          builder: (_, __) => const FeesScreen()),
      GoRoute(path: '/student/results',       builder: (_, __) => const ResultsScreen()),
      GoRoute(path: '/student/exams',         builder: (_, __) => const ExamScheduleScreen()),

      // ── Staff Shell — tab screens (show bottom nav) ───────────
      ShellRoute(
        builder: (_, __, child) => StaffShell(child: child),
        routes: [
          GoRoute(path: '/staff',               builder: (_, __) => const StaffHome()),
          GoRoute(path: '/staff/reports',       builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/staff/performa',      builder: (_, __) => const PerformaScreen()),
          GoRoute(path: '/staff/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/staff/profile',       builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Staff pushed screens (full-page, no bottom nav) ───────
      GoRoute(
        path: '/staff/mark-attendance/:id',
        builder: (_, state) => MarkAttendanceScreen(
          subjectAssignmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/staff/marks/:id',
        builder: (_, state) => EnterMarksScreen(
          subjectAssignmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/staff/materials/:id',
        builder: (_, state) => UploadMaterialsScreen(
          subjectAssignmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/staff/assignments/:id',
        builder: (_, state) => ManageAssignmentsScreen(
          subjectAssignmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/staff/subject/:id',
        builder: (_, state) => SubjectDetailScreen(
          subjectAssignmentId: state.pathParameters['id']!,
        ),
      ),

      // ── Admin Shell — tab screens (show bottom nav) ───────────
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin',            builder: (_, __) => const AdminHome()),
          GoRoute(path: '/admin/users',      builder: (_, __) => const UserManagementScreen()),
          GoRoute(path: '/admin/analytics',  builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/admin/rules',      builder: (_, __) => const AttendanceRulesScreen()),
        ],
      ),

      // ── Admin pushed screens (full-page, no bottom nav) ───────
      GoRoute(path: '/admin/academic',        builder: (_, __) => const AcademicSetupScreen()),
      GoRoute(path: '/admin/create-account',  builder: (_, __) => const CreateAccountScreen()),
      GoRoute(path: '/admin/notifications',   builder: (_, __) => const NotificationsScreen()),
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Page not found', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(state.matchedLocation, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    ),
  );
});
