import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/login_provider.dart';
import '../features/exam_result/domain/entities/exam_result_row.dart';
import '../features/exam_result/presentation/providers/exam_result_provider.dart';

// Students > Exam Result. Uses the same examResultProvider as the dashboard's
// Exam Result card, so the numbers always agree between the two screens.

// 73.75 -> "73.75", 78.1 -> "78.1", 74.0 -> "74"
String _trim(double v, [int decimals = 2]) {
  final s = v.toStringAsFixed(decimals);
  if (!s.contains('.')) return s;
  return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

// Same thresholds as the web's getGradeInfo().
String _gradeFor(double p) {
  if (p >= 80) return 'A+';
  if (p >= 70) return 'A';
  if (p >= 60) return 'A-';
  if (p >= 50) return 'B';
  if (p >= 40) return 'C';
  if (p >= 33) return 'D';
  return 'F';
}

class ExamResultScreen extends ConsumerWidget {
  const ExamResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(examResultProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exam Result',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: resultsAsync.when(
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
                    onPressed: () => ref.invalidate(examResultProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return const Center(
                child: Text(
                  'No exam results found.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            // Totals computed from the real rows — nothing hardcoded.
            final totalObtained = rows.fold<double>(
              0,
              (s, r) => s + r.marksObtained,
            );
            final totalFull = rows.fold<double>(0, (s, r) => s + r.fullMark);
            final totalWeighted = rows.fold<double>(
              0,
              (s, r) => s + r.weightedMarks,
            );
            // Each row's weightedMarks is already out of 100 (e.g. 73.75), so
            // the overall weighted score is simply their average.
            final percentage = rows.isEmpty ? 0.0 : totalWeighted / rows.length;
            final grade = _gradeFor(percentage);
            final allPassed = rows.every((r) => r.isPassed);

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(examResultProvider),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Filter chips (read-only for now — the app always shows
                  // the current year across all assessment groups).
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [_FilterChip(label: 'All Assessment Groups')],
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _SummaryTile(
                        label: 'TOTAL MARKS',
                        value: _trim(totalObtained, 1),
                        sub: 'out of ${_trim(totalFull, 0)}',
                      ),
                      _SummaryTile(
                        label: 'PERCENTAGE',
                        value: '${_trim(percentage)}%',
                        sub: 'weighted: ${_trim(percentage)} of 100',
                      ),
                      _SummaryTile(
                        label: 'GRADE',
                        badge: grade,
                        badgeColor: context.brandColor,
                      ),
                      _SummaryTile(
                        label: 'RESULT',
                        badge: allPassed ? 'Passed' : 'Failed',
                        badgeColor: allPassed
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user == null ? 'Results' : user.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < rows.length; i++) ...[
                          _SubjectRow(index: i + 1, row: rows[i]),
                          if (i != rows.length - 1)
                            Divider(height: 1, color: context.borderColor),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    this.value,
    this.sub,
    this.badge,
    this.badgeColor,
  });
  final String label;
  final String? value;
  final String? sub;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor!.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (sub != null)
            Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.mutedText),
            )
          else
            const SizedBox(height: 0),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.index, required this.row});
  final int index;
  final ExamResultRow row;

  @override
  Widget build(BuildContext context) {
    // Same formula as the dashboard donut and the web: obtained / full * 100.
    final percent = row.fullMark > 0
        ? (row.marksObtained / row.fullMark) * 100
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(fontSize: 12, color: context.mutedText),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.subjectName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_trim(row.marksObtained, 1)} / ${_trim(row.fullMark, 0)}  ·  ${_trim(percent)}%',
                  style: TextStyle(fontSize: 12, color: context.mutedText),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: row.assessments.isEmpty
                ? null
                : () => _showBreakdown(context, row),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('View'),
          ),
        ],
      ),
    );
  }
}

// Per-component marks for one subject (Class Test, CQ, MCQ, ...), same
// information as the web's marks-detail modal.
void _showBreakdown(BuildContext context, ExamResultRow row) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        row.subjectName,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final a in row.assessments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.weightage != null
                            ? '${a.title}  (${_trim(a.weightage!, 0)}%)'
                            : a.title,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      a.isAbsent
                          ? 'Absent'
                          : '${_trim(a.marksObtained, 1)} / ${_trim(a.fullMark, 0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Subject Total',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${_trim(row.marksObtained, 1)} / ${_trim(row.fullMark, 0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
