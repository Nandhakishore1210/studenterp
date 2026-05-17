import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../data/services/supabase_service.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  late int _selectedDay;

  static const _dayFull  = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    final wd = DateTime.now().weekday;
    _selectedDay = wd <= 6 ? wd : 1;
  }

  bool get _isToday => _selectedDay == DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final ttAsync = ref.watch(studentTimetableProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Text('Timetable', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _DaySelector(selected: _selectedDay, onSelect: (d) => setState(() => _selectedDay = d)),
        ),
      ),
      body: ttAsync.when(
        loading: () => const ShimmerList(count: 6, itemHeight: 82),
        error: (e, _) => Center(child: Text(e.toString(),
            style: GoogleFonts.inter(color: AppColors.textSecondary))),
        data: (data) {
          final entries = data
              .where((e) => e['day_of_week'] == _selectedDay)
              .toList()
            ..sort((a, b) => (a['period_number'] as int).compareTo(b['period_number'] as int));

          final studentRecord = ref.watch(studentRecordProvider).valueOrNull;

          return Column(children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              width: double.infinity,
              child: Text(
                _dayFull[_selectedDay - 1],
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.event_busy_outlined, size: 48, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 12),
                      Text('No classes today', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      itemBuilder: (_, i) => _PeriodCard(
                        entry: entries[i],
                        index: i,
                        showMarkPresent: _isToday,
                        studentRecord: studentRecord,
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  const _DaySelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        final day = i + 1;
        final sel = day == selected;
        final isToday = day == DateTime.now().weekday;
        return GestureDetector(
          onTap: () => onSelect(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 42,
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_days[i], style: GoogleFonts.inter(
                color: sel ? Colors.white : const Color(0xFF6B7280),
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              )),
              if (isToday)
                Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                    color: sel ? Colors.white : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ]),
          ),
        );
      }),
    ),
  );
}

class _PeriodCard extends StatefulWidget {
  final Map<String, dynamic> entry;
  final int index;
  final bool showMarkPresent;
  final dynamic studentRecord;

  static const _colors = [
    Color(0xFF1A73E8), Color(0xFF7C3AED), Color(0xFF059669),
    Color(0xFFDC2626), Color(0xFFD97706), Color(0xFF0891B2),
  ];

  const _PeriodCard({
    required this.entry,
    required this.index,
    required this.showMarkPresent,
    this.studentRecord,
  });

  @override
  State<_PeriodCard> createState() => _PeriodCardState();
}

class _PeriodCardState extends State<_PeriodCard> {
  bool _marking = false;
  bool _marked = false;
  String? _statusMsg;

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _markPresent() async {
    if (_marking) return;
    setState(() { _marking = true; _statusMsg = null; });

    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission perm = permission;
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _statusMsg = 'Location permission denied'; _marking = false; });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final classLat = widget.entry['classroom_lat'] as double?;
      final classLng = widget.entry['classroom_lng'] as double?;
      final radius   = (widget.entry['geofence_radius_m'] as int? ?? 100).toDouble();

      if (classLat == null || classLng == null) {
        setState(() { _statusMsg = 'Classroom location not set'; _marking = false; });
        return;
      }

      final dist = _haversineDistance(pos.latitude, pos.longitude, classLat, classLng);

      if (dist > radius) {
        setState(() {
          _statusMsg = 'You are ${dist.toStringAsFixed(0)}m away (need <${radius.toStringAsFixed(0)}m)';
          _marking = false;
        });
        return;
      }

      // Inside geofence — mark present
      final assignment = widget.entry['subject_assignments'] as Map?;
      final subjectId = (assignment?['subjects'] as Map?)?['id'] as String? ??
          assignment?['subject_id'] as String?;
      final studentId = widget.studentRecord?['id'] as String?;

      if (subjectId == null || studentId == null) {
        setState(() { _statusMsg = 'Missing data'; _marking = false; });
        return;
      }

      final err = await SupabaseService.markGeofenceAttendance(
        studentId:            studentId,
        subjectId:            subjectId,
        subjectAssignmentId:  widget.entry['subject_assignment_id'] as String,
        academicYear:         SupabaseConstants.currentAcademicYear,
        periodNumber:         widget.entry['period_number'] as int,
        date:                 DateTime.now().toIso8601String().split('T')[0],
      );

      if (err != null) {
        setState(() { _statusMsg = 'Error: $err'; _marking = false; });
      } else {
        setState(() { _marked = true; _marking = false; _statusMsg = 'Marked present!'; });
      }
    } catch (e) {
      setState(() { _statusMsg = e.toString(); _marking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment   = widget.entry['subject_assignments'] as Map?;
    final subject      = assignment?['subjects'] as Map?;
    final staff        = assignment?['staff'] as Map?;
    final staffProfile = staff?['profiles'] as Map?;

    final period  = (widget.entry['period_number'] as int? ?? 0);
    final start   = (widget.entry['start_time'] as String? ?? '').replaceAll(':00', '');
    final end     = (widget.entry['end_time']   as String? ?? '').replaceAll(':00', '');
    final room    = widget.entry['room'] as String?;
    final subName = subject?['name'] as String? ?? 'Subject';
    final subCode = subject?['code'] as String? ?? '';
    final faculty = staffProfile?['full_name'] as String?;
    final color   = _PeriodCard._colors[widget.index % _PeriodCard._colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 5,
            height: widget.showMarkPresent ? 110 : 86,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(start, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              Container(height: 14, width: 1, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(vertical: 2)),
              Text(end, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          Container(width: 1, height: 60, color: const Color(0xFFF3F4F6)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(subName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1C1C1E)),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('P$period', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text(subCode, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  if (room != null) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.room_outlined, size: 11, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text(room, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ]),
                if (faculty != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 11, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Expanded(child: Text(faculty,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
                if (widget.showMarkPresent) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: _marked
                        ? Row(children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                            const SizedBox(width: 6),
                            Text('Present marked', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF059669), fontWeight: FontWeight.w600)),
                          ])
                        : ElevatedButton.icon(
                            onPressed: _marking ? null : _markPresent,
                            icon: _marking
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.my_location_rounded, size: 14),
                            label: Text(_marking ? 'Checking...' : 'Mark Present',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                  ),
                ],
              ]),
            ),
          ),
        ]),
        if (_statusMsg != null && !_marked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Text(_statusMsg!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF856404))),
          ),
      ]),
    );
  }
}
