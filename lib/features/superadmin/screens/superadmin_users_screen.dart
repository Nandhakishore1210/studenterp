import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/superadmin_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../data/services/supabase_service.dart';

class SuperadminUsersScreen extends ConsumerStatefulWidget {
  const SuperadminUsersScreen({super.key});

  @override
  ConsumerState<SuperadminUsersScreen> createState() => _SuperadminUsersScreenState();
}

class _SuperadminUsersScreenState extends ConsumerState<SuperadminUsersScreen> {
  String? _selectedUniversity;
  String  _roleFilter = 'all';
  String  _search     = '';
  final   _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final unisAsync  = ref.watch(allUniversitiesProvider);
    final usersAsync = ref.watch(universityScopedUsersProvider(_selectedUniversity));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: Text('All Users', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(universityScopedUsersProvider(_selectedUniversity))),
        ],
      ),
      body: Column(children: [
        // Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(children: [
            // University dropdown
            unisAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
              data: (unis) => DropdownButtonFormField<String?>(
                value: _selectedUniversity,
                decoration: InputDecoration(
                  labelText: 'Filter by College',
                  prefixIcon: const Icon(Icons.school_outlined, size: 18),
                  filled: true, fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Colleges')),
                  ...unis.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))),
                ],
                onChanged: (v) => setState(() => _selectedUniversity = v),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textHint),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true, fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final r in ['all', 'admin', 'staff', 'student'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(r == 'all' ? 'All' : r.capitalize()),
                      selected: _roleFilter == r,
                      onSelected: (_) => setState(() => _roleFilter = r),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF7C3AED).withOpacity(0.15),
                      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                          color: _roleFilter == r ? const Color(0xFF7C3AED) : AppColors.textSecondary),
                      side: BorderSide(color: _roleFilter == r ? const Color(0xFF7C3AED) : AppColors.border),
                    ),
                  ),
              ]),
            ),
          ]),
        ),

        Expanded(
          child: usersAsync.when(
            loading: () => const ShimmerList(count: 8, itemHeight: 70),
            error: (e, _) => AppError(message: e.toString()),
            data: (users) {
              final filtered = users.where((u) {
                final name  = (u['full_name'] as String? ?? '').toLowerCase();
                final email = (u['email'] as String? ?? '').toLowerCase();
                final role  = u['role'] as String? ?? '';
                final matchSearch = _search.isEmpty || name.contains(_search) || email.contains(_search);
                final matchRole   = _roleFilter == 'all' || role == _roleFilter;
                return matchSearch && matchRole;
              }).toList();

              if (filtered.isEmpty) return Center(
                  child: Text('No users found', style: GoogleFonts.inter(color: AppColors.textSecondary)));

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) => _UserTile(user: filtered[i], ref: ref, uniId: _selectedUniversity),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final WidgetRef ref;
  final String? uniId;
  const _UserTile({required this.user, required this.ref, this.uniId});

  static const _roleColors = {
    'admin':   Color(0xFFD97706),
    'staff':   Color(0xFF059669),
    'student': Color(0xFF2563EB),
  };

  @override
  Widget build(BuildContext context) {
    final name     = user['full_name'] as String? ?? 'Unknown';
    final email    = user['email'] as String? ?? '';
    final role     = user['role'] as String? ?? 'student';
    final isActive = user['is_active'] as bool? ?? true;
    final id       = user['id'] as String;
    final color    = _roleColors[role] ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(email, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(role, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'deactivate') {
              await SupabaseService.deactivateUser(id);
              ref.invalidate(universityScopedUsersProvider(uniId));
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'deactivate', child: Row(children: [
              Icon(Icons.block_rounded, size: 16, color: AppColors.error),
              SizedBox(width: 8),
              Text('Deactivate', style: TextStyle(color: AppColors.error)),
            ])),
          ],
          child: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textHint),
        ),
      ]),
    );
  }
}

extension _Cap on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
