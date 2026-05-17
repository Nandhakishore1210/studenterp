import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Teacher'), Tab(text: 'Student')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_TeacherForm(), _StudentForm()],
      ),
    );
  }
}

class _TeacherForm extends ConsumerStatefulWidget {
  const _TeacherForm();

  @override
  ConsumerState<_TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends ConsumerState<_TeacherForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  bool _isMentor = false;
  bool _isAdvisor = false;
  bool _loading = false;
  String? _error;
  String? _success;
  String? _selectedDeptId;
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepts();
  }

  Future<void> _loadDepts() async {
    final university = ref.read(selectedUniversityProvider);
    if (university == null) return;
    try {
      final res = await SupabaseService.client
          .from('departments')
          .select('id, name, code')
          .order('name');
      if (mounted) setState(() => _departments = List<Map<String, dynamic>>.from(res));
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null) {
      setState(() => _error = 'Please select a department');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });

    final university = ref.read(selectedUniversityProvider);
    final roles = ['subject_faculty'];
    if (_isMentor) roles.add('mentor');
    if (_isAdvisor) roles.add('class_advisor');

    final err = await SupabaseService.createUserAccount({
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'full_name': _nameCtrl.text.trim(),
      'role': 'staff',
      'university_id': university?['id'],
      'employee_id': _empIdCtrl.text.trim(),
      'department_id': _selectedDeptId,
      'designation': _designationCtrl.text.trim(),
      'roles': roles,
    });

    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      setState(() { _success = 'Teacher account created successfully!'; });
      _formKey.currentState!.reset();
      _nameCtrl.clear(); _emailCtrl.clear(); _passCtrl.clear();
      _empIdCtrl.clear(); _designationCtrl.clear();
      setState(() { _selectedDeptId = null; _isMentor = false; _isAdvisor = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('Personal Info'),
          _field(_nameCtrl, 'Full Name', Icons.person_outline),
          const SizedBox(height: 12),
          _field(_emailCtrl, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_passCtrl, 'Password', Icons.lock_outline, obscure: true,
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null),
          const SizedBox(height: 20),
          _sectionLabel('Job Info'),
          _field(_empIdCtrl, 'Employee ID', Icons.badge_outlined),
          const SizedBox(height: 12),
          _field(_designationCtrl, 'Designation', Icons.work_outline),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedDeptId,
            decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
            items: _departments.map((d) => DropdownMenuItem<String>(
              value: d['id'] as String,
              child: Text('${d['code']} — ${d['name']}', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => _selectedDeptId = v),
            validator: (v) => v == null ? 'Select a department' : null,
          ),
          const SizedBox(height: 20),
          _sectionLabel('Roles'),
          CheckboxListTile(
            title: const Text('Subject Faculty'),
            value: true,
            onChanged: null,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Mentor'),
            subtitle: const Text('Guides assigned students'),
            value: _isMentor,
            onChanged: (v) => setState(() => _isMentor = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Class Advisor'),
            subtitle: const Text('Oversees a full class section'),
            value: _isAdvisor,
            onChanged: (v) => setState(() => _isAdvisor = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          if (_error != null) _errorBox(_error!),
          if (_success != null) _successBox(_success!),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Teacher Account'),
          ),
        ]),
      ),
    );
  }
}

class _StudentForm extends ConsumerStatefulWidget {
  const _StudentForm();

  @override
  ConsumerState<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends ConsumerState<_StudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  String? _selectedDeptId;
  String? _selectedSection;
  int _semester = 1;
  bool _loading = false;
  String? _error;
  String? _success;
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _batchCtrl.text = '2025';
    _loadDepts();
  }

  Future<void> _loadDepts() async {
    try {
      final res = await SupabaseService.client
          .from('departments')
          .select('id, name, code')
          .order('name');
      if (mounted) setState(() => _departments = List<Map<String, dynamic>>.from(res));
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null || _selectedSection == null) {
      setState(() => _error = 'Select department and section');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });

    final university = ref.read(selectedUniversityProvider);

    final err = await SupabaseService.createUserAccount({
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'full_name': _nameCtrl.text.trim(),
      'role': 'student',
      'university_id': university?['id'],
      'register_no': _regNoCtrl.text.trim(),
      'department_id': _selectedDeptId,
      'section': _selectedSection,
      'batch': _batchCtrl.text.trim(),
      'current_semester': _semester,
    });

    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      setState(() { _success = 'Student account created successfully!'; });
      _formKey.currentState!.reset();
      _nameCtrl.clear(); _emailCtrl.clear(); _passCtrl.clear(); _regNoCtrl.clear();
      setState(() { _selectedDeptId = null; _selectedSection = null; _semester = 1; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('Personal Info'),
          _field(_nameCtrl, 'Full Name', Icons.person_outline),
          const SizedBox(height: 12),
          _field(_emailCtrl, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_passCtrl, 'Password', Icons.lock_outline, obscure: true,
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null),
          const SizedBox(height: 20),
          _sectionLabel('Academic Info'),
          _field(_regNoCtrl, 'Register Number', Icons.numbers_outlined),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedDeptId,
            decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
            items: _departments.map((d) => DropdownMenuItem<String>(
              value: d['id'] as String,
              child: Text('${d['code']} — ${d['name']}', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => _selectedDeptId = v),
            validator: (v) => v == null ? 'Select department' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSection,
                decoration: const InputDecoration(labelText: 'Section'),
                items: ['A', 'B', 'C', 'D'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedSection = v),
                validator: (v) => v == null ? 'Select' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _semester,
                decoration: const InputDecoration(labelText: 'Semester'),
                items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Sem ${i + 1}'))),
                onChanged: (v) => setState(() => _semester = v ?? 1),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _field(_batchCtrl, 'Batch (e.g. 2025)', Icons.calendar_today_outlined),
          const SizedBox(height: 20),
          if (_error != null) _errorBox(_error!),
          if (_success != null) _successBox(_success!),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Student Account'),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared helpers ─────────────────────────────────────────

Widget _sectionLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
    );

Widget _field(
  TextEditingController ctrl,
  String label,
  IconData icon, {
  bool obscure = false,
  TextInputType keyboard = TextInputType.text,
  String? Function(String?)? validator,
}) =>
    TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );

Widget _errorBox(String msg) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: AppColors.error, fontSize: 13))),
      ]),
    );

Widget _successBox(String msg) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13))),
      ]),
    );
