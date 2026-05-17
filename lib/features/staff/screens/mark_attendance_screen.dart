import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../providers/staff_provider.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_constants.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  final String subjectAssignmentId;
  const MarkAttendanceScreen({super.key, required this.subjectAssignmentId});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedPeriod = 1;
  final Map<String, String> _statuses = {}; // studentId -> status
  bool _saving = false;
  bool _geoVerified = false;
  String? _geoStatus;

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _verifyLocation() async {
    setState(() => _geoStatus = 'Checking location…');
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _geoStatus = 'Location permission denied');
        return;
      }
      // Fetch timetable classroom location for this assignment + period
      final rows = await SupabaseService.client
          .from('timetable')
          .select('classroom_lat, classroom_lng, geofence_radius_m')
          .eq('subject_assignment_id', widget.subjectAssignmentId)
          .eq('period_number', _selectedPeriod)
          .maybeSingle();

      final classLat = rows?['classroom_lat'] as double?;
      final classLng = rows?['classroom_lng'] as double?;
      final radius   = (rows?['geofence_radius_m'] as int? ?? 100).toDouble();

      if (classLat == null || classLng == null) {
        setState(() { _geoVerified = true; _geoStatus = 'Classroom location not set — proceeding without check'; });
        return;
      }

      final pos  = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final dist = _haversineDistance(pos.latitude, pos.longitude, classLat, classLng);

      if (dist <= radius) {
        setState(() { _geoVerified = true; _geoStatus = 'Location verified ✓ (${dist.toStringAsFixed(0)}m from classroom)'; });
      } else {
        setState(() { _geoVerified = false; _geoStatus = 'You are ${dist.toStringAsFixed(0)}m away — must be within ${radius.toStringAsFixed(0)}m'; });
      }
    } catch (e) {
      setState(() { _geoStatus = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(enrolledStudentsProvider(widget.subjectAssignmentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: studentsAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: e.toString()),
        data: (students) {
          // Initialize statuses
          for (final s in students) {
            _statuses.putIfAbsent(s.id, () => 'present');
          }

          return Column(children: [
            // Date & Period selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _DateSelector(
                    date: _selectedDate,
                    onChanged: (d) => setState(() { _selectedDate = d; _geoVerified = false; _geoStatus = null; }),
                  )),
                  const SizedBox(width: 12),
                  _PeriodSelector(
                    value: _selectedPeriod,
                    onChanged: (p) => setState(() { _selectedPeriod = p; _geoVerified = false; _geoStatus = null; }),
                  ),
                ]),
                const SizedBox(height: 10),
                // Geofence verify row
                Row(children: [
                  Expanded(child: _geoStatus != null
                      ? Text(_geoStatus!, style: TextStyle(
                          fontSize: 12,
                          color: _geoVerified ? const Color(0xFF059669) : const Color(0xFFDC2626)))
                      : Text('Verify your classroom location before saving',
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _verifyLocation,
                    icon: Icon(_geoVerified ? Icons.check_circle_rounded : Icons.my_location_rounded,
                        size: 14, color: _geoVerified ? const Color(0xFF059669) : AppColors.primary),
                    label: Text(_geoVerified ? 'Verified' : 'Verify',
                        style: TextStyle(fontSize: 12, color: _geoVerified ? const Color(0xFF059669) : AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _geoVerified ? const Color(0xFF059669) : AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]),
              ]),
            ),
            // Quick mark all
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Text('${students.length} students', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('All Present'),
                  onPressed: () => setState(() {
                    for (final s in students) _statuses[s.id] = 'present';
                  }),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                  label: const Text('All Absent', style: TextStyle(color: AppColors.error)),
                  onPressed: () => setState(() {
                    for (final s in students) _statuses[s.id] = 'absent';
                  }),
                ),
              ]),
            ),
            const Divider(height: 1),
            // Student list
            Expanded(child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = students[i];
                final status = _statuses[s.id] ?? 'present';
                return _StudentAttendanceRow(
                  student: s,
                  status: status,
                  onStatusChanged: (newStatus) => setState(() => _statuses[s.id] = newStatus),
                );
              },
            )),
            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(students),
                child: _saving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Attendance'),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _save(List students) async {
    setState(() => _saving = true);
    try {
      final staff = ref.read(staffRecordProvider).valueOrNull;
      if (staff == null) throw Exception('Staff record not found');

      // Get subject_id from assignment
      final assignment = await SupabaseService.client
          .from('subject_assignments')
          .select('subject_id, semester_number')
          .eq('id', widget.subjectAssignmentId)
          .single();

      final records = students.map((s) => {
        'student_id':             s.id,
        'subject_id':             assignment['subject_id'],
        'subject_assignment_id':  widget.subjectAssignmentId,
        'date':                   DateFormat('yyyy-MM-dd').format(_selectedDate),
        'period_number':          _selectedPeriod,
        'status':                 _statuses[s.id] ?? 'present',
        'marked_by':              staff.id,
        'academic_year':          SupabaseConstants.currentAcademicYear,
        'semester_number':        assignment['semester_number'],
      }).toList();

      await SupabaseService.upsertAttendance(records);

      // Notify parents of absent students
      final absentIds = students
          .where((s) => (_statuses[s.id] ?? 'present') == 'absent')
          .map<String>((s) => s.id as String)
          .toList();
      if (absentIds.isNotEmpty) {
        final subjectName = assignment['subject_id'] as String;
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        NotificationService.notifyParentsForAbsent(
          absentStudentIds: absentIds,
          subjectName: subjectName,
          date: dateStr,
          periodNumber: _selectedPeriod,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(absentIds.isEmpty
                ? 'Attendance saved!'
                : 'Attendance saved! Parents of ${absentIds.length} absent student(s) notified.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DateSelector({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now(),
      );
      if (picked != null) onChanged(picked);
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontSize: 14)),
      ]),
    ),
  );
}

class _PeriodSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PeriodSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: value,
        items: List.generate(8, (i) => DropdownMenuItem(
          value: i + 1, child: Text('P${i + 1}'))),
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    ),
  );
}

class _StudentAttendanceRow extends StatelessWidget {
  final student;
  final String status;
  final ValueChanged<String> onStatusChanged;
  const _StudentAttendanceRow({required this.student, required this.status, required this.onStatusChanged});

  static const _statusColors = {
    'present': AppColors.attendanceGreen,
    'absent':  AppColors.attendanceRed,
    'late':    AppColors.attendanceYellow,
    'od':      AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryLight,
          child: Text(student.fullName[0], style: const TextStyle(color: AppColors.primary, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(student.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(student.registerNo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Row(children: [
          for (final s in ['present', 'absent', 'late', 'od'])
            GestureDetector(
              onTap: () => onStatusChanged(s),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: status == s ? _statusColors[s]! : _statusColors[s]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _statusColors[s]!,
                    width: status == s ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(s[0].toUpperCase(),
                    style: TextStyle(
                      color: status == s ? Colors.white : _statusColors[s],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
        ]),
      ]),
    );
  }
}
