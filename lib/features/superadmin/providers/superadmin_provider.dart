import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/supabase_service.dart';

final allUniversitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) =>
    SupabaseService.getUniversities());

final superadminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final client = SupabaseService.client;
  final profiles = await client.from('profiles').select('role');
  final counts = <String, int>{'student': 0, 'staff': 0, 'admin': 0, 'total': 0};
  for (final p in profiles as List) {
    final role = p['role'] as String? ?? '';
    counts['total'] = (counts['total'] ?? 0) + 1;
    if (counts.containsKey(role)) counts[role] = (counts[role] ?? 0) + 1;
  }
  final unis = await SupabaseService.getUniversities();
  counts['universities'] = unis.length;
  return counts;
});

final universityScopedUsersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, universityId) =>
        SupabaseService.getAllProfiles(universityId: universityId));
