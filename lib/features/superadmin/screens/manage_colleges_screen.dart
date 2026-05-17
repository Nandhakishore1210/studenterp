import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/superadmin_provider.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_loading.dart';

class ManageCollegesScreen extends ConsumerWidget {
  const ManageCollegesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unisAsync = ref.watch(allUniversitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: Text('Manage Colleges', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/superadmin/add-college'),
            tooltip: 'Add College',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allUniversitiesProvider),
          ),
        ],
      ),
      body: unisAsync.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 100),
        error: (e, _) => AppError(message: e.toString()),
        data: (unis) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: unis.length,
          itemBuilder: (_, i) => _CollegeCard(college: unis[i], ref: ref),
        ),
      ),
    );
  }
}

class _CollegeCard extends StatelessWidget {
  final Map<String, dynamic> college;
  final WidgetRef ref;
  const _CollegeCard({required this.college, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name     = college['name'] as String? ?? '';
    final code     = college['code'] as String? ?? '';
    final city     = college['city'] as String? ?? '';
    final website  = college['website'] as String? ?? '';
    final isActive = college['is_active'] as bool? ?? true;
    final id       = college['id'] as String;
    final color    = const Color(0xFF7C3AED);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppColors.border : Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(code.length > 4 ? code.substring(0, 4) : code,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800,
                      color: isActive ? color : Colors.grey))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14,
                  color: isActive ? AppColors.textPrimary : Colors.grey)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                const SizedBox(width: 2),
                Text(city, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ]),
              if (website.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(website, style: GoogleFonts.inter(fontSize: 11, color: color),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit'),
              onPressed: () => context.push('/superadmin/edit-college/$id'),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              icon: Icon(isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 14),
              label: Text(isActive ? 'Deactivate' : 'Activate'),
              onPressed: () async {
                await SupabaseService.toggleUniversity(id, !isActive);
                ref.invalidate(allUniversitiesProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? const Color(0xFFDC2626) : const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ── Add / Edit College Screen ─────────────────────────────────────
class AddEditCollegeScreen extends ConsumerStatefulWidget {
  final String? collegeId;
  const AddEditCollegeScreen({super.key, this.collegeId});

  @override
  ConsumerState<AddEditCollegeScreen> createState() => _AddEditCollegeScreenState();
}

class _AddEditCollegeScreenState extends ConsumerState<AddEditCollegeScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _codeCtrl  = TextEditingController();
  final _cityCtrl  = TextEditingController();
  final _estCtrl   = TextEditingController();
  final _webCtrl   = TextEditingController();
  bool _loading    = false;
  bool _active     = true;
  String? _error;

  bool get _isEdit => widget.collegeId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadCollege();
  }

  Future<void> _loadCollege() async {
    final data = await SupabaseService.client
        .from('universities')
        .select()
        .eq('id', widget.collegeId!)
        .single();
    setState(() {
      _nameCtrl.text = data['name'] ?? '';
      _codeCtrl.text = data['code'] ?? '';
      _cityCtrl.text = data['city'] ?? '';
      _estCtrl.text  = data['established_year']?.toString() ?? '';
      _webCtrl.text  = data['website'] ?? '';
      _active        = data['is_active'] ?? true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _codeCtrl.dispose(); _cityCtrl.dispose();
    _estCtrl.dispose();  _webCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final payload = {
      'name':              _nameCtrl.text.trim(),
      'code':              _codeCtrl.text.trim().toUpperCase(),
      'city':              _cityCtrl.text.trim(),
      'is_active':         _active,
      if (_webCtrl.text.isNotEmpty) 'website': _webCtrl.text.trim(),
      if (_estCtrl.text.isNotEmpty) 'established_year': int.tryParse(_estCtrl.text.trim()),
    };

    final err = _isEdit
        ? await SupabaseService.updateUniversity(widget.collegeId!, payload)
        : await SupabaseService.createUniversity(payload);

    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      ref.invalidate(allUniversitiesProvider);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit College' : 'Add College',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _field(_nameCtrl, 'College Name', Icons.school_outlined, required: true),
            const SizedBox(height: 14),
            _field(_codeCtrl, 'College Code (e.g. KCT)', Icons.tag_rounded, required: true),
            const SizedBox(height: 14),
            _field(_cityCtrl, 'City', Icons.location_on_outlined, required: true),
            const SizedBox(height: 14),
            _field(_estCtrl, 'Established Year', Icons.calendar_today_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _field(_webCtrl, 'Website (optional)', Icons.language_outlined),
            const SizedBox(height: 14),
            Row(children: [
              const Text('Active:', style: TextStyle(fontWeight: FontWeight.w600)),
              Switch(value: _active, activeColor: const Color(0xFF7C3AED),
                  onChanged: (v) => setState(() => _active = v)),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(_isEdit ? 'Update College' : 'Add College',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    );
  }
}
