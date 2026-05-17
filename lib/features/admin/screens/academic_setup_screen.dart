import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../providers/admin_provider.dart';

class AcademicSetupScreen extends ConsumerStatefulWidget {
  const AcademicSetupScreen({super.key});

  @override
  ConsumerState<AcademicSetupScreen> createState() => _AcademicSetupScreenState();
}

class _AcademicSetupScreenState extends ConsumerState<AcademicSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Academic Setup'),
      automaticallyImplyLeading: false,
      bottom: TabBar(controller: _tabs, tabs: const [
        Tab(text: 'Departments'),
        Tab(text: 'Subjects'),
        Tab(text: 'Calendar'),
      ]),
    ),
    body: TabBarView(controller: _tabs, children: [
      _DepartmentsTab(),
      _SubjectsTab(),
      _CalendarTab(),
    ]),
  );
}

class _DepartmentsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DepartmentsTab> createState() => _DepartmentsTabState();
}

class _DepartmentsTabState extends ConsumerState<_DepartmentsTab> {
  List<Map<String, dynamic>> _depts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.client
          .from('departments').select().order('name');
      setState(() { _depts = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Add Department'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Department Name')),
        const SizedBox(height: 10),
        TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g. CSE)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
            await SupabaseService.client.from('departments').insert({
              'name': nameCtrl.text.trim(),
              'code': codeCtrl.text.trim().toUpperCase(),
            });
            Navigator.pop(context);
            _load();
          },
          child: const Text('Add'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
    body: _loading ? const AppLoading() : _depts.isEmpty
      ? const Center(child: Text('No departments', style: TextStyle(color: AppColors.textSecondary)))
      : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _depts.length,
          itemBuilder: (_, i) {
            final d = _depts[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(d['code'] as String? ?? '?',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              title: Text(d['name'] as String? ?? ''),
              subtitle: Text('Code: ${d['code']}'),
            );
          },
        ),
  );
}

class _SubjectsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends ConsumerState<_SubjectsTab> {
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.client
          .from('subjects').select().order('semester_number').order('name');
      setState(() { _subjects = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => _loading ? const AppLoading() : _subjects.isEmpty
    ? const Center(child: Text('No subjects', style: TextStyle(color: AppColors.textSecondary)))
    : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _subjects.length,
        itemBuilder: (_, i) {
          final s = _subjects[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceVariant,
              child: Text('S${s['semester_number']}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            title: Text(s['name'] as String? ?? ''),
            subtitle: Text('${s['code']} • ${s['credits']} credits'),
            trailing: s['is_practical'] == true
                ? const Chip(label: Text('Lab', style: TextStyle(fontSize: 10)))
                : null,
          );
        },
      );
}

class _CalendarTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calAsync = ref.watch(academicCalendarProvider);
    return calAsync.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppError(message: e.toString()),
      data: (events) {
        if (events.isEmpty) return const Center(
          child: Text('No calendar events', style: TextStyle(color: AppColors.textSecondary)));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (_, i) {
            final e = events[i];
            final typeColors = {
              'holiday': AppColors.attendanceRed,
              'exam':    AppColors.attendanceYellow,
              'semester_start': AppColors.attendanceGreen,
              'semester_end':   AppColors.attendanceRed,
              'event':   AppColors.primary,
            };
            final color = typeColors[e['event_type']] ?? AppColors.primary;
            return ListTile(
              leading: Container(
                width: 10, height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
              title: Text(e['title'] as String? ?? ''),
              subtitle: Text(e['start_date'] as String? ?? ''),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text((e['event_type'] as String? ?? '').replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: color, fontSize: 10)),
              ),
            );
          },
        );
      },
    );
  }
}
