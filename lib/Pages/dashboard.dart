import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/widget/app_shell.dart';
import '../features/auth/presentation/providers/login_provider.dart';
import '../features/dashboard/domain/entities/student_dashboard.dart';
import '../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../features/exam_result/domain/entities/exam_result_row.dart';
import '../features/exam_result/domain/entities/subject_performance_slice.dart';
import '../features/exam_result/presentation/providers/exam_result_provider.dart';
import 'dart:math' as math;

// Status colors that stay readable in both themes (same values as the web CSS).
Color _green(BuildContext c) =>
    c.isDark ? const Color(0xFF6EE7B7) : const Color(0xFF1E9E3E);
Color _red(BuildContext c) =>
    c.isDark ? const Color(0xFFFCA5A5) : const Color(0xFFE5484D);
const _amber = Color(0xFFF5A42B);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const AppTopBar(),
      drawer: const AppSidebar(),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(studentDashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        // Pull down to reload the numbers.
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(studentDashboardProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WelcomeHeader(name: userAsync.valueOrNull?.fullName ?? ''),
              const SizedBox(height: 16),
              _StatGrid(d: d),
              const SizedBox(height: 16),
              _AttendanceCard(d: d),
              const SizedBox(height: 16),
              const _SubjectPerformanceCard(),
              const SizedBox(height: 16),
              const _ExamResultCard(),
              const SizedBox(height: 16),
              _FeesStatusCard(d: d),
              const SizedBox(height: 16),
              const _CalendarCard(),
              const SizedBox(height: 16),
              const _NoticeBoardCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        children: [
          const TextSpan(text: 'Welcome back '),
          TextSpan(
            text: name,
            style: TextStyle(color: context.brandColor),
          ),
        ],
      ),
    );
  }
}

// The bordered box every section sits in. Change the card look here once.
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

// A card with a title and one centered message, for sections with no data yet.
class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(
            height: 110,
            child: Center(
              child: Text(message, style: TextStyle(color: context.mutedText)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The four numbers at the top.
// ---------------------------------------------------------------------------
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.d});
  final StudentDashboard d;

  @override
  Widget build(BuildContext context) {
    final total = d.presentCount + d.absentCount;
    final pct = total == 0 ? 0 : (d.presentCount / total * 100).round();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _StatCard(
          label: 'ATTENDANCE',
          value: '$pct%',
          subtitle: '${d.presentCount} present • ${d.absentCount} absent',
          icon: Icons.how_to_reg_outlined,
          iconColor: _green(context),
          highlighted: true,
        ),
        _StatCard(
          label: 'TASKS',
          value: '${d.totalTasks - d.pendingTasks}/${d.totalTasks}',
          valueColor: context.brandColor,
          subtitle: '${d.pendingTasks} pending tasks',
          subtitleColor: context.brandColor,
          icon: Icons.checklist_rounded,
          iconColor: context.brandColor,
        ),
        _StatCard(
          label: 'ASSESSMENTS',
          value: '${d.marksEntered}/${d.totalAssessments}',
          subtitle: '${d.averagePercentage.toStringAsFixed(1)}% average',
          icon: Icons.assignment_outlined,
          iconColor: context.brandColor,
          highlighted: true,
        ),
        _StatCard(
          label: 'FEES DUE',
          value: d.totalDueAmount.toStringAsFixed(0),
          subtitle: '${d.unpaidInvoices} unpaid • ${d.paidInvoices} paid',
          subtitleColor: _red(context),
          icon: Icons.payments_outlined,
          iconColor: _red(context),
        ),
      ],
    );
  }
}

// The purple gradient used by the two "highlight" stat cards, matching the
// web dashboard's Attendance and Assessments cards.
const _statGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF6D5BFF), Color(0xFF4A3FE0)],
);

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
    this.subtitle,
    this.subtitleColor,
    this.progress,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  final String? subtitle;
  final Color? subtitleColor;
  final double? progress; // when set, shows a thin bar instead of a subtitle
  final bool highlighted; // true = purple gradient card, white text

  @override
  Widget build(BuildContext context) {
    final labelColor = highlighted
        ? Colors.white.withValues(alpha: 0.85)
        : null;
    final valueTextColor = highlighted ? Colors.white : valueColor;
    final subtitleTextColor = highlighted
        ? Colors.white.withValues(alpha: 0.85)
        : subtitleColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: highlighted ? _statGradient : null,
        color: highlighted ? null : context.surfaceColor,
        border: highlighted ? null : Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: labelColor,
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: highlighted
                    ? Colors.white.withValues(alpha: 0.22)
                    : iconColor.withValues(alpha: 0.16),
                child: Icon(
                  icon,
                  size: 16,
                  color: highlighted ? Colors.white : iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: valueTextColor,
            ),
          ),
          const SizedBox(height: 6),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  color: highlighted ? Colors.white : context.brandColor,
                  backgroundColor: highlighted
                      ? Colors.white.withValues(alpha: 0.3)
                      : context.borderColor,
                ),
              ),
            )
          else if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: subtitleTextColor),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance pie chart and the three counts under it.
// ---------------------------------------------------------------------------
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.d});
  final StudentDashboard d;

  @override
  Widget build(BuildContext context) {
    final total = d.presentCount + d.absentCount;
    final fraction = total == 0 ? 0.0 : d.presentCount / total;
    final green = _green(context);
    final red = _red(context);

    final pct = total == 0 ? 0 : (fraction * 100).round();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Attendance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _AttendanceRingPainter(
                      fraction: fraction,
                      present: const Color(0xFF26B67A),
                      absent: const Color(0xFFE65956),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.mutedText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFF26B67A), label: 'Present'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFE65956), label: 'Absent'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  value: '$total',
                  label: 'Total Attendance',
                  color: null,
                  tint: context.brandColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  value: '${d.presentCount}',
                  label: 'Total Present',
                  color: green,
                  tint: green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  value: '${d.absentCount}',
                  label: 'Total Absent',
                  color: red,
                  tint: red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceRingPainter extends CustomPainter {
  _AttendanceRingPainter({
    required this.fraction,
    required this.present,
    required this.absent,
  });
  final double fraction;
  final Color present;
  final Color absent;

  static const _strokeWidth = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -3.14159265 / 2; // 12 o'clock

    // Full background ring first (the "absent" portion), then the
    // "present" arc drawn on top — so a 100% value shows a solid ring.
    canvas.drawArc(
      rect,
      0,
      2 * 3.14159265,
      false,
      Paint()
        ..color = absent
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        start,
        2 * 3.14159265 * fraction,
        false,
        Paint()
          ..color = present
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AttendanceRingPainter old) =>
      old.fraction != fraction;
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
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.tint,
    this.color,
  });
  final String value;
  final String label;
  final Color tint; // background wash
  final Color? color; // number color, null = normal text color

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exam Result: layout only. The dashboard endpoint returns no exam rows, and
// the filters need a results API, so this is the empty state for now.
// ---------------------------------------------------------------------------
// Each subject row from the real API: name, marks, a grade chip, a
// status chip. A full table (like the web's) doesn't fit a phone width,
// so this is a stacked list instead — same information, different layout.
// ---------------------------------------------------------------------------
// Subject Performance donut chart — same colors and slice-sizing logic as
// the web's subject-performance.jsx (echarts), redrawn with CustomPaint
// since echarts has no Flutter equivalent.
// ---------------------------------------------------------------------------
const _subjectColors = [
  Color(0xFF5F4AFF),
  Color(0xFF6B76ED),
  Color(0xFF4497D9),
  Color(0xFF26A572),
  Color(0xFFE6A326),
  Color(0xFFE65956),
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
];

class _SubjectPerformanceCard extends ConsumerStatefulWidget {
  const _SubjectPerformanceCard();

  @override
  ConsumerState<_SubjectPerformanceCard> createState() =>
      _SubjectPerformanceCardState();
}

class _SubjectPerformanceCardState
    extends ConsumerState<_SubjectPerformanceCard> {
  static const _perPage = 3;
  static const _chartSize = 220.0;
  int _page = 0;
  int? _selectedIndex;

  void _handleTap(Offset local, List<SubjectPerformanceSlice> slices) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    final center = const Offset(_chartSize / 2, _chartSize / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    const radius = 75.0;
    const strokeWidth = 50.0;
    const popOffset = 14.0;
    final innerEdge = radius - strokeWidth / 2;
    final outerEdge = radius + strokeWidth / 2 + popOffset;
    if (distance < innerEdge || distance > outerEdge) {
      setState(() => _selectedIndex = null);
      return;
    }

    var angle = math.atan2(dy, dx) + math.pi / 2; // 0 = 12 o'clock, clockwise
    if (angle < 0) angle += 2 * math.pi;

    var cursor = 0.0;
    for (var i = 0; i < slices.length; i++) {
      final value = slices[i].value;
      if (value <= 0) continue;
      final sweep = (value / total) * 2 * math.pi;
      if (angle >= cursor && angle < cursor + sweep) {
        setState(() => _selectedIndex = _selectedIndex == i ? null : i);
        return;
      }
      cursor += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sliceAsync = ref.watch(subjectPerformanceProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          sliceAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.mutedText),
                ),
              ),
            ),
            data: (slices) {
              if (slices.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No subject performance data found.',
                      style: TextStyle(color: context.mutedText),
                    ),
                  ),
                );
              }

              final totalPages = (slices.length / _perPage).ceil();
              final safePage = _page.clamp(0, totalPages - 1);
              final start = safePage * _perPage;
              final end = (start + _perPage).clamp(0, slices.length);
              final pageIndices = List.generate(end - start, (i) => start + i);

              return Column(
                children: [
                  GestureDetector(
                    onTapUp: (details) =>
                        _handleTap(details.localPosition, slices),
                    child: SizedBox(
                      width: _chartSize,
                      height: _chartSize,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          slices: slices,
                          selectedIndex: _selectedIndex,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedIndex != null) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final i = _selectedIndex!;
                        // slices[i].value IS the subject's own score
                        // percentage already (from getSubjectPerformance()),
                        // so show it directly — don't divide by the sum of
                        // every subject's percentage, that gives each
                        // slice's "share of the pie" instead of its score.
                        final percent = slices[i].value;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: context.iconBoxColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color:
                                      _subjectColors[i % _subjectColors.length],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  slices[i].subjectName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${percent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: context.brandColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: safePage > 0
                            ? () => setState(() => _page = safePage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        iconSize: 20,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            for (final i in pageIndices)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color:
                                            _subjectColors[i %
                                                _subjectColors.length],
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        slices[i].subjectName,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: safePage < totalPages - 1
                            ? () => setState(() => _page = safePage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        iconSize: 20,
                      ),
                    ],
                  ),
                  if (totalPages > 1)
                    Text(
                      '${safePage + 1}/$totalPages',
                      style: TextStyle(fontSize: 11, color: context.mutedText),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, this.selectedIndex});

  final List<SubjectPerformanceSlice> slices;
  final int? selectedIndex;

  static const _radius = 75.0;
  static const _strokeWidth = 50.0;
  static const _popOffset = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    final center = Offset(size.width / 2, size.height / 2);

    if (total <= 0) {
      final paint = Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 50;
      canvas.drawCircle(center, 70, paint);
      return;
    }

    final baseRect = Rect.fromCircle(center: center, radius: _radius);
    var startAngle = -math.pi / 2;

    // First pass: draw every slice except the selected one, so the popped
    // slice always paints on top (not covered by its neighbors).
    for (var pass = 0; pass < 2; pass++) {
      var angle = -math.pi / 2;
      for (var i = 0; i < slices.length; i++) {
        final value = slices[i].value;
        if (value <= 0) continue;
        final sweep = (value / total) * 2 * math.pi;
        final isSelected = i == selectedIndex;

        if ((pass == 0 && !isSelected) || (pass == 1 && isSelected)) {
          var rect = baseRect;
          if (isSelected) {
            final mid = angle + sweep / 2;
            final offset = Offset(math.cos(mid), math.sin(mid)) * _popOffset;
            rect = baseRect.shift(offset);
          }
          final paint = Paint()
            ..color = _subjectColors[i % _subjectColors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? _strokeWidth + 4 : _strokeWidth;
          canvas.drawArc(rect, angle, sweep - 0.03, false, paint);
        }
        angle += sweep;
      }
    }
    startAngle; // unused, kept for clarity of the loop above
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _ExamResultCard extends ConsumerStatefulWidget {
  const _ExamResultCard();

  @override
  ConsumerState<_ExamResultCard> createState() => _ExamResultCardState();
}

class _ExamResultCardState extends ConsumerState<_ExamResultCard> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(examResultProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exam Result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'View Result',
                style: TextStyle(
                  color: context.brandColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by subject, grade, status...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: context.iconBoxColor,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null, // TODO: export report card
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Export Report Card'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _amber,
              disabledForegroundColor: _amber,
              side: BorderSide(color: _amber.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(height: 16),
          resultAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.mutedText),
                ),
              ),
            ),
            data: (rows) {
              final filtered = _query.isEmpty
                  ? rows
                  : rows
                        .where(
                          (r) =>
                              r.subjectName.toLowerCase().contains(_query) ||
                              r.grade.toLowerCase().contains(_query) ||
                              r.statusLabel.toLowerCase().contains(_query),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return Column(
                  children: [
                    Center(
                      child: Icon(
                        Icons.find_in_page_outlined,
                        size: 40,
                        color: context.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        rows.isEmpty
                            ? 'No exam result found for this assessment category'
                            : 'No results match your search',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.mutedText),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  for (final row in filtered) ...[
                    _ExamResultRowTile(row: row),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExamResultRowTile extends StatelessWidget {
  const _ExamResultRowTile({required this.row});
  final ExamResultRow row;

  @override
  Widget build(BuildContext context) {
    final statusColor = row.isPassed ? _green(context) : _red(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.iconBoxColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.subjectName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${row.marksObtained.toStringAsFixed(0)} / ${row.fullMark.toStringAsFixed(0)} marks  ·  weighted ${row.weightedMarks.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 12, color: context.mutedText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  row.grade,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  row.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (row.assessments.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _AssessmentBreakdownDialog(row: row),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: context.brandColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// The "View" popup — a subject's total broken back down into the individual
// assessments (Class Test, CQ (Final Exam), Mid Exam, ...) that were summed
// to make it, matching the web's marks-detail modal.
class _AssessmentBreakdownDialog extends StatelessWidget {
  const _AssessmentBreakdownDialog({required this.row});
  final ExamResultRow row;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${row.subjectName} Marks Details'),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final a in row.assessments) ...[
                _BreakdownRow(
                  label: a.title.isEmpty ? '—' : a.title,
                  marks: a.isAbsent
                      ? 'Absent'
                      : '${a.marksObtained.toStringAsFixed(1)} / ${a.fullMark.toStringAsFixed(0)}',
                  weightage: a.weightage != null
                      ? '${a.weightage!.toStringAsFixed(0)}%'
                      : '—',
                ),
                Divider(height: 16, color: context.borderColor),
              ],
              _BreakdownRow(
                label: 'Subject Total',
                marks:
                    '${row.marksObtained.toStringAsFixed(1)} / ${row.fullMark.toStringAsFixed(0)}',
                weightage: row.weightedMarks.toStringAsFixed(1),
                bold: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.marks,
    required this.weightage,
    this.bold = false,
  });
  final String label;
  final String marks;
  final String weightage;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: bold ? 14 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: style)),
          Expanded(
            flex: 2,
            child: Text(marks, style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(weightage, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fees status. The endpoint gives invoice counts and the amount due, but no
// paid amount, so paid/due show invoice counts only.
// ---------------------------------------------------------------------------
class _FeesStatusCard extends StatelessWidget {
  const _FeesStatusCard({required this.d});
  final StudentDashboard d;

  @override
  Widget build(BuildContext context) {
    final fullyPaid = d.unpaidInvoices == 0;
    final chipColor = fullyPaid ? _green(context) : _red(context);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fees status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  fullyPaid ? 'Fully paid' : 'Payment due',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'TOTAL DUE AMOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '৳${d.totalDueAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.brandColor,
            ),
          ),
          const SizedBox(height: 16),
          _FeeRow(color: _green(context), label: 'Paid', count: d.paidInvoices),
          const SizedBox(height: 10),
          _FeeRow(color: _red(context), label: 'Due', count: d.unpaidInvoices),
          Divider(height: 28, color: context.borderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total invoices',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${d.paidInvoices + d.unpaidInvoices}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.brandColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.color,
    required this.label,
    required this.count,
  });
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text(
          '($count invoices)',
          style: TextStyle(fontSize: 12, color: context.mutedText),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Month calendar with previous / today / next. Week and Day views from the
// web are not included. Events are not loaded (no calendar API wired yet).
// ---------------------------------------------------------------------------
class _CalendarCard extends StatefulWidget {
  const _CalendarCard();

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset =
        DateTime(_month.year, _month.month, 1).weekday % 7; // Sunday = 0
    final daysInPrevMonth = DateTime(_month.year, _month.month, 0).day;
    final cellCount = ((offset + daysInMonth) / 7).ceil() * 7;

    final cells = <Widget>[];
    for (var i = 0; i < cellCount; i++) {
      final day = i - offset + 1;
      final inMonth = day >= 1 && day <= daysInMonth;
      final shown = day < 1
          ? daysInPrevMonth + day
          : (day > daysInMonth ? day - daysInMonth : day);
      final isToday =
          inMonth &&
          _month.year == now.year &&
          _month.month == now.month &&
          day == now.day;

      cells.add(
        Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  )
                : null,
            child: Text(
              '$shown',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday
                    ? Theme.of(context).colorScheme.onPrimary
                    : (inMonth
                          ? Theme.of(context).colorScheme.onSurface
                          : context.mutedText.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_months[_month.month - 1]} ${_month.year}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            'Academic Calendar & Reminders',
            style: TextStyle(fontSize: 12, color: context.mutedText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () =>
                    setState(() => _month = DateTime(now.year, now.month)),
                child: const Text('Today'),
              ),
              const Spacer(),
              IconButton.filled(
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in _days)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (d == 'FRI' || d == 'SAT')
                            ? _red(context)
                            : context.mutedText,
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notice board. No notices API is wired yet, so this is the empty state.
// ---------------------------------------------------------------------------
class _NoticeBoardCard extends StatelessWidget {
  const _NoticeBoardCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Notice Board',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: open the full notices list
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDark
                    ? AppColors.darkBg
                    : Colors.white,
                foregroundColor: context.isDark
                    ? AppColors.darkAccent
                    : primary,
              ),
              child: const Text('View All Notices'),
            ),
          ),
        ],
      ),
    );
  }
}
