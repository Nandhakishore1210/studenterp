import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentMaterialsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Study Materials')),
      body: async.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 80),
        error: (e, _) => AppError(message: e.toString()),
        data: (data) {
          if (data.isEmpty) return const Center(
            child: Text('No materials uploaded', style: TextStyle(color: AppColors.textSecondary)));

          final grouped = groupBy(data, (m) {
            final sa = m['subject_assignments'] as Map?;
            final sub = sa?['subjects'] as Map?;
            return sub?['name'] as String? ?? 'Unknown';
          });

          return ListView(
            children: grouped.entries.map((e) => _SubjectMaterialsSection(
              subjectName: e.key,
              materials: e.value,
            )).toList(),
          );
        },
      ),
    );
  }
}

class _SubjectMaterialsSection extends StatelessWidget {
  final String subjectName;
  final List materials;
  const _SubjectMaterialsSection({required this.subjectName, required this.materials});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(subjectName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
      ...materials.map((m) => _MaterialTile(material: m)),
    ],
  );
}

class _MaterialTile extends StatelessWidget {
  final Map material;
  const _MaterialTile({required this.material});

  static const _typeColors = {
    'pdf':   Color(0xFFE53935),
    'ppt':   Color(0xFFFF6D00),
    'video': Color(0xFF1E88E5),
    'doc':   Color(0xFF1565C0),
    'other': AppColors.textSecondary,
  };

  static const _typeIcons = {
    'pdf':   Icons.picture_as_pdf_outlined,
    'ppt':   Icons.slideshow_outlined,
    'video': Icons.play_circle_outline,
    'doc':   Icons.description_outlined,
    'other': Icons.attach_file,
  };

  @override
  Widget build(BuildContext context) {
    final type  = material['file_type'] as String? ?? 'other';
    final color = _typeColors[type] ?? AppColors.textSecondary;
    final icon  = _typeIcons[type] ?? Icons.attach_file;
    final url   = material['file_url'] as String?;

    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(material['title'] as String? ?? '', style: const TextStyle(fontSize: 14)),
      subtitle: material['description'] != null
          ? Text(material['description'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12))
          : null,
      trailing: url != null
          ? IconButton(
              icon: const Icon(Icons.open_in_new, color: AppColors.primary),
              onPressed: () => launchUrl(Uri.parse(url)),
            )
          : null,
    );
  }
}
