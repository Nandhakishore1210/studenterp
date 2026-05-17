import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/staff_provider.dart';
import '../../../data/services/supabase_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_constants.dart';

class UploadMaterialsScreen extends ConsumerStatefulWidget {
  final String subjectAssignmentId;
  const UploadMaterialsScreen({super.key, required this.subjectAssignmentId});

  @override
  ConsumerState<UploadMaterialsScreen> createState() => _UploadMaterialsScreenState();
}

class _UploadMaterialsScreenState extends ConsumerState<UploadMaterialsScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  List<Map<String, dynamic>> _materials = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.client
          .from('study_materials')
          .select()
          .eq('subject_assignment_id', widget.subjectAssignmentId)
          .order('uploaded_at', ascending: false);
      setState(() { _materials = List<Map<String, dynamic>>.from(res); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title')));
      return;
    }

    setState(() => _uploading = true);
    try {
      final staff = ref.read(staffRecordProvider).valueOrNull;
      if (staff == null) throw Exception('Staff not found');

      final file   = result.files.first;
      final ext    = file.extension?.toLowerCase() ?? 'other';
      final type   = ['pdf', 'ppt', 'video', 'doc'].contains(ext) ? ext : 'other';
      final path   = '${widget.subjectAssignmentId}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      final url = await SupabaseService.uploadFile(
        SupabaseConstants.materialsBucket, path,
        file.bytes!.toList(), 'application/octet-stream',
      );

      await SupabaseService.addMaterial({
        'subject_assignment_id': widget.subjectAssignmentId,
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'file_url':    url,
        'file_type':   type,
        'uploaded_by': staff.id,
      });

      _titleCtrl.clear(); _descCtrl.clear();
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material uploaded!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Study Materials')),
    body: Column(children: [
      // Upload form
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 10),
          TextField(controller: _descCtrl, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.description_outlined))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _upload,
            icon: _uploading ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload),
            label: const Text('Upload File'),
          ),
        ]),
      ),
      const Divider(height: 1),

      // List
      _loading ? const AppLoading() : Expanded(child: _materials.isEmpty
        ? const Center(child: Text('No materials uploaded', style: TextStyle(color: AppColors.textSecondary)))
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _materials.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final m = _materials[i];
              final url = m['file_url'] as String?;
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border)),
                leading: const Icon(Icons.attach_file, color: AppColors.primary),
                title: Text(m['title'] as String, style: const TextStyle(fontSize: 13)),
                subtitle: Text(m['file_type'] as String? ?? '', style: const TextStyle(fontSize: 11)),
                trailing: url != null ? IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => launchUrl(Uri.parse(url)),
                ) : null,
              );
            },
          )),
    ]),
  );
}
