import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('User Management'),
      automaticallyImplyLeading: false,
      bottom: TabBar(controller: _tabs, tabs: const [
        Tab(text: 'Students'), Tab(text: 'Staff'), Tab(text: 'Admins'),
      ]),
    ),
    body: TabBarView(controller: _tabs, children: [
      _UserList(role: 'student'),
      _UserList(role: 'staff'),
      _UserList(role: 'admin'),
    ]),
  );
}

class _UserList extends ConsumerWidget {
  final String role;
  const _UserList({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allUsersProvider(role));
    return async.when(
      loading: () => const ShimmerList(count: 6, itemHeight: 70),
      error: (e, _) => AppError(message: e.toString()),
      data: (users) {
        if (users.isEmpty) return Center(
          child: Text('No $role users found',
              style: const TextStyle(color: AppColors.textSecondary)));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (_, i) => _UserTile(user: users[i], role: role, ref: ref),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final String role;
  final WidgetRef ref;
  const _UserTile({required this.user, required this.role, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] as bool? ?? true;
    final roleColor = role == 'admin' ? AppColors.adminColor
        : role == 'staff' ? AppColors.staffColor
        : AppColors.studentColor;

    // Extra info
    String subInfo = user['email'] as String? ?? '';
    if (role == 'student') {
      final s = user['students'] as Map?;
      if (s != null) subInfo = '${s['register_no'] ?? ''} • Sem ${s['current_semester'] ?? ''}';
    } else if (role == 'staff') {
      final s = user['staff'] as Map?;
      if (s != null) subInfo = s['employee_id'] as String? ?? '';
    }

    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.12),
          child: Text((user['full_name'] as String? ?? '?')[0],
              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(user['full_name'] as String? ?? '',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary)),
        subtitle: Text(subInfo, style: const TextStyle(fontSize: 12)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(4)),
              child: const Text('Inactive', style: TextStyle(color: AppColors.error, fontSize: 11)),
            ),
          PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'deactivate') {
                await SupabaseService.deactivateUser(user['id'] as String);
                ref.invalidate(allUsersProvider);
              }
            },
            itemBuilder: (_) => [
              if (isActive)
                const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
              const PopupMenuItem(value: 'view', child: Text('View Details')),
            ],
          ),
        ]),
      ),
    );
  }
}
