import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/widget/app_shell.dart';
import '../features/auth/presentation/providers/login_provider.dart';
import '../features/teacher_dashboard/domain/entities/teacher_dashboard.dart';
import '../features/teacher_dashboard/presentation/providers/teacher_dashboard_provider.dart';

// Teacher dashboard, same sections as the web: stat cards, Classes Assigned,
// Students Attendance, Weekly Attendance, Student List, Event Calendar and
// Notice Board. All numbers come from the TeacherDashboard entity.

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _fmtDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

const _gradient = LinearGradient(
  colors: [Color(0xFF4F3BD8), Color(0xFF7C6BFF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(teacherDashboardProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: const AppTopBar(),
      drawer: const AppSidebar(),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(teacherDashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(teacherDashboardProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  children: [
                    const TextSpan(text: 'Welcome back '),
                    TextSpan(text: user?.fullName ?? '', style: TextStyle(color: context.brandColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StatCards(d: d),
              const SizedBox(height: 16),
              _ClassesAssignedCard(d: d),
              const SizedBox(height: 16),
              _AttendanceCard(today: d.today),
              const SizedBox(height: 16),
              _WeeklyAttendanceCard(points: d.weekly),
              const SizedBox(height: 16),
              _StudentListCard(students: d.students),
              const SizedBox(height: 16),
              _EventCalendarCard(events: d.events),
              const SizedBox(height: 16),
              _NoticeBoardCard(notices: d.notices),
            ],
          ),
        ),
      ),
    );
  }
}

// The bordered box every section sits in.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = 16});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Top stat cards
// ---------------------------------------------------------------------------
class _StatCards extends StatelessWidget {
  const _StatCards({required this.d});
  final TeacherDashboard d;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatTile(
        label: 'ASSIGNED STUDENTS',
        value: '${d.studentCount}',
        subIcon: Icons.menu_book_outlined,
        sub: '${d.classCount} class • ${d.sectionCount} section',
        icon: Icons.groups_rounded,
        filled: true,
      ),
      _StatTile(
        label: 'ASSIGNED SUBJECTS',
        value: '${d.subjectCount}',
        subIcon: Icons.assignment_outlined,
        sub: '${d.assessmentCount} assessments',
        icon: Icons.auto_stories_rounded,
        filled: false,
      ),
      _StatTile(
        label: 'ATTENDANCE TODAY',
        value: '${d.today.present}/${d.today.total}',
        subIcon: Icons.check_circle_outline,
        sub: '${d.today.absent} absent • ${d.today.late} late',
        icon: Icons.event_available_rounded,
        filled: true,
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      // Phones: stacked. Wider screens (tablets): three across.
      if (c.maxWidth >= 640) {
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      }
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.subIcon,
    required this.icon,
    required this.filled,
  });
  final String label;
  final String value;
  final String sub;
  final IconData subIcon;
  final IconData icon;
  final bool filled; // gradient card (white text) vs plain card

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : null;
    final subColor = filled ? Colors.white.withValues(alpha: 0.9) : context.mutedText;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: filled ? _gradient : null,
        color: filled ? null : context.surfaceColor,
        border: filled ? null : Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: fg)),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: filled ? Colors.white.withValues(alpha: 0.2) : context.successColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: filled ? Colors.white : context.successColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(subIcon, size: 14, color: subColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Classes assigned
// ---------------------------------------------------------------------------
class _ClassesAssignedCard extends StatelessWidget {
  const _ClassesAssignedCard({required this.d});
  final TeacherDashboard d;

  @override
  Widget build(BuildContext context) {
    final count = d.assignments.length;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Classes Assigned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.iconBoxColor,
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count Assignments', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (d.assignments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: context.iconBoxColor,
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_busy_outlined),
                  ),
                  const SizedBox(height: 12),
                  const Text('No class schedule found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'No class section assignments are available for this teacher yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: context.mutedText),
                  ),
                ],
              ),
            )
          else
            for (final a in d.assignments)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.iconBoxColor,
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${a.className} • ${a.section}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Text(a.subject, style: TextStyle(color: context.mutedText)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Students attendance (today)
// ---------------------------------------------------------------------------
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.today});
  final TodayAttendance today;

  @override
  Widget build(BuildContext context) {
    final green = context.successColor;
    final red = context.dangerColor;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Students Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _RingPainter(
                      present: today.present,
                      absent: today.absent,
                      presentColor: green,
                      absentColor: red,
                      trackColor: context.borderColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Attendance', style: TextStyle(fontSize: 11, color: context.mutedText)),
                      Text('${today.presentPercent.round()}%',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: green, label: 'Present'),
              const SizedBox(width: 16),
              _LegendDot(color: red, label: 'Absent'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MiniTile(value: '${today.total}', label: 'Total Students', color: null)),
              const SizedBox(width: 8),
              Expanded(child: _MiniTile(value: '${today.present}', label: 'Total Present', color: green)),
              const SizedBox(width: 8),
              Expanded(child: _MiniTile(value: '${today.absent}', label: 'Total Absent', color: red)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.present,
    required this.absent,
    required this.presentColor,
    required this.absentColor,
    required this.trackColor,
  });
  final int present;
  final int absent;
  final Color presentColor;
  final Color absentColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final total = present + absent;
    if (total == 0) {
      // Nothing marked yet: neutral ring instead of a misleading split.
      canvas.drawArc(arcRect, 0, math.pi * 2, false, paint..color = trackColor);
      return;
    }
    final presentSweep = math.pi * 2 * present / total;
    canvas.drawArc(arcRect, -math.pi / 2, presentSweep, false, paint..color = presentColor);
    canvas.drawArc(arcRect, -math.pi / 2 + presentSweep, math.pi * 2 - presentSweep, false, paint..color = absentColor);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.present != present || old.absent != absent || old.presentColor != presentColor || old.trackColor != trackColor;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: (color ?? context.mutedText).withValues(alpha: 0.08),
        border: Border.all(color: (color ?? context.borderColor).withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly attendance overview (tap a bar to highlight it)
// ---------------------------------------------------------------------------
class _WeeklyAttendanceCard extends StatefulWidget {
  const _WeeklyAttendanceCard({required this.points});
  final List<WeeklyAttendancePoint> points;

  @override
  State<_WeeklyAttendanceCard> createState() => _WeeklyAttendanceCardState();
}

class _WeeklyAttendanceCardState extends State<_WeeklyAttendanceCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 150.0;
    final brand = context.isDark ? AppColors.darkAccent : AppColors.primary600;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Weekly Attendance Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.iconBoxColor,
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('This Month', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: chartHeight + 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < widget.points.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = _selected == i ? null : i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${widget.points[i].percent.round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _selected == i ? null : context.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 22,
                            height: chartHeight * widget.points[i].percent.clamp(0, 100) / 100,
                            decoration: BoxDecoration(
                              color: _selected == i ? brand.withValues(alpha: 0.55) : brand,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(widget.points[i].day, style: TextStyle(fontSize: 11, color: context.mutedText)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Student list: search + class/section filters + paging
// ---------------------------------------------------------------------------
class _StudentListCard extends StatefulWidget {
  const _StudentListCard({required this.students});
  final List<TeacherStudent> students;

  @override
  State<_StudentListCard> createState() => _StudentListCardState();
}

class _StudentListCardState extends State<_StudentListCard> {
  static const _pageSize = 5;
  String _query = '';
  String? _class; // null = all
  String? _section;
  int _page = 0;

  List<TeacherStudent> get _filtered {
    final q = _query.trim().toLowerCase();
    return widget.students.where((s) {
      if (_class != null && s.className != _class) return false;
      if (_section != null && s.section != _section) return false;
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.rollNo.toLowerCase().contains(q);
    }).toList();
  }

  void _resetPage() => _page = 0;

  @override
  Widget build(BuildContext context) {
    final classes = widget.students.map((s) => s.className).toSet().toList()..sort();
    final sections = widget.students.map((s) => s.section).toSet().toList()..sort();

    final filtered = _filtered;
    final pageCount = math.max(1, (filtered.length / _pageSize).ceil());
    final page = _page.clamp(0, pageCount - 1).toInt();
    final start = page * _pageSize;
    final end = math.min(start + _pageSize, filtered.length);
    final visible = filtered.sublist(start, end);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Student List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() {
              _query = v;
              _resetPage();
            }),
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.brandColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  hint: 'Classes',
                  value: _class,
                  options: classes,
                  onChanged: (v) => setState(() {
                    _class = v;
                    _resetPage();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterDropdown(
                  hint: 'Sections',
                  value: _section,
                  options: sections,
                  onChanged: (v) => setState(() {
                    _section = v;
                    _resetPage();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('No students found.', style: TextStyle(color: context.mutedText))),
            )
          else
            for (var i = 0; i < visible.length; i++) ...[
              _StudentRow(student: visible[i]),
              if (i != visible.length - 1) Divider(height: 1, color: context.borderColor),
            ],
          const SizedBox(height: 12),
          Text(
            'Showing ${filtered.isEmpty ? 0 : start + 1} to $end of ${filtered.length} entries',
            style: TextStyle(fontSize: 12, color: context.mutedText),
          ),
          if (pageCount > 1) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PageButton(icon: Icons.chevron_left, onTap: page > 0 ? () => setState(() => _page = page - 1) : null),
                for (var p = 0; p < pageCount; p++)
                  _PageButton(label: '${p + 1}', selected: p == page, onTap: () => setState(() => _page = p)),
                _PageButton(
                  icon: Icons.chevron_right,
                  onTap: page < pageCount - 1 ? () => setState(() => _page = page + 1) : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.hint, required this.value, required this.options, required this.onChanged});
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(hint)),
            for (final o in options) DropdownMenuItem<String?>(value: o, child: Text(o)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});
  final TeacherStudent student;

  @override
  Widget build(BuildContext context) {
    final statusColor = student.isActive ? context.successColor : context.mutedText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primary100.withValues(alpha: context.isDark ? 0.18 : 1),
            child: Text(
              student.initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.isDark ? Colors.white : AppColors.primary700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(student.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: context.mutedText)),
                const SizedBox(height: 3),
                Text('Roll ${student.rollNo}  ·  ${student.className} • ${student.section}',
                    style: TextStyle(fontSize: 12, color: context.mutedText)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              student.isActive ? 'Active' : 'Inactive',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({this.label, this.icon, this.selected = false, this.onTap});
  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary700 : context.iconBoxColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: label != null
            ? Text(label!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : null,
                ))
            : Icon(icon, size: 18, color: enabled ? null : context.mutedText.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event calendar: real month grid, holiday dots, events for the shown month
// ---------------------------------------------------------------------------
class _EventCalendarCard extends StatefulWidget {
  const _EventCalendarCard({required this.events});
  final List<CalendarEvent> events;

  @override
  State<_EventCalendarCard> createState() => _EventCalendarCardState();
}

class _EventCalendarCardState extends State<_EventCalendarCard> {
  static const _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int by) => setState(() => _month = DateTime(_month.year, _month.month + by));

  CalendarEvent? _eventOn(int day) {
    for (final e in widget.events) {
      if (e.date.year == _month.year && e.date.month == _month.month && e.date.day == day) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = DateTime(_month.year, _month.month, 1).weekday % 7; // Sunday = 0
    final cellCount = ((offset + daysInMonth) / 7).ceil() * 7;
    final red = context.dangerColor;
    final monthEvents = widget.events
        .where((e) => e.date.year == _month.year && e.date.month == _month.month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final cells = <Widget>[];
    for (var i = 0; i < cellCount; i++) {
      final day = i - offset + 1;
      if (day < 1 || day > daysInMonth) {
        cells.add(const SizedBox.shrink());
        continue;
      }
      final isToday = _month.year == now.year && _month.month == now.month && day == now.day;
      final isWeekend = i % 7 == 5 || i % 7 == 6; // Fri, Sat
      final event = _eventOn(day);
      final isHoliday = event?.isHoliday ?? false;

      cells.add(Center(
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday ? AppColors.primary600 : (isHoliday ? red.withValues(alpha: 0.14) : null),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: (isToday || isHoliday) ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? Colors.white : ((isHoliday || isWeekend) ? red : null),
            ),
          ),
        ),
      ));
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Event Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filled(
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              ),
              Expanded(
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.filled(
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _days.length; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: (i == 5 || i == 6) ? red : context.mutedText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: cells,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: red, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Holiday', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 12),
          const Text('Events', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (monthEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('No events this month.', style: TextStyle(color: context.mutedText)),
            )
          else
            for (final e in monthEvents) _EventTile(event: e),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All events page is not built yet')),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: context.isDark ? AppColors.darkButton : AppColors.primary700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View All Events'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final accent = event.isHoliday ? context.dangerColor : context.brandColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: context.iconBoxColor,
        border: Border(left: BorderSide(color: accent, width: 3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(event.description, style: TextStyle(fontSize: 12.5, color: context.mutedText)),
                const SizedBox(height: 2),
                Text(_fmtDate(event.date), style: TextStyle(fontSize: 11.5, color: context.mutedText)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(event.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.description),
                    const SizedBox(height: 8),
                    Text(_fmtDate(event.date), style: TextStyle(color: context.mutedText)),
                  ],
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
              ),
            ),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('View'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notice board
// ---------------------------------------------------------------------------
class _NoticeBoardCard extends StatelessWidget {
  const _NoticeBoardCard({required this.notices});
  final List<TeacherNotice> notices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: _gradient, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text('Notice Board', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          if (notices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.article_outlined, color: Colors.white, size: 30),
                  SizedBox(height: 8),
                  Text('No notices found', style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          else
            for (final n in notices)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(n.body, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('${_fmtDate(n.date)}  ·  ${n.priority}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(n.title),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.body),
                              const SizedBox(height: 8),
                              Text('${_fmtDate(n.date)}  ·  ${n.priority}', style: TextStyle(color: context.mutedText)),
                            ],
                          ),
                          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.18)),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notices page is not built yet')),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDark ? AppColors.darkBg : Colors.white,
                foregroundColor: context.isDark ? AppColors.darkAccent : AppColors.primary700,
              ),
              child: const Text('View All Notices'),
            ),
          ),
        ],
      ),
    );
  }
}