import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/my_subjects/presentation/providers/student_subjects_provider.dart';
import '../features/my_subjects/domain/entities/student_subject.dart';

// The student-facing "Class" screen (Academics > Class, same menu item the
// teacher sees class_list_screen.dart for) — a grid of the subjects in the
// student's own class this academic year, matching the web's "My Subjects" page.
class MySubjectsScreen extends ConsumerWidget {
  const MySubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(studentSubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Class',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: subjectsAsync.when(
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
                    onPressed: () => ref.invalidate(studentSubjectsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (subjects) {
            if (subjects.isEmpty) {
              return const Center(
                child: Text(
                  'No subjects found for your class yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(studentSubjectsProvider),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Header(count: subjects.length),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subjects.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                    itemBuilder: (context, index) =>
                        _SubjectCard(subject: subjects[index], index: index),
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

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(12),
        color: context.surfaceColor,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.iconBoxColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 18,
              color: context.brandColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Subjects',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Subjects of your current class this academic year.',
                  style: TextStyle(fontSize: 12, color: context.mutedText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.iconBoxColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: context.mutedText,
                ),
                const SizedBox(width: 4),
                Text(
                  '$count Subject${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.mutedText,
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

// Cycles through a fixed palette so neighboring cards don't repeat colors,
// same spirit as the web's per-subject gradient headers.
const _gradients = [
  [Color(0xFF7C3AED), Color(0xFF4F46E5)], // purple
  [Color(0xFF2563EB), Color(0xFF38BDF8)], // blue
  [Color(0xFF16A34A), Color(0xFF059669)], // green
  [Color(0xFFF59E0B), Color(0xFFEA580C)], // amber/orange
  [Color(0xFFE11D48), Color(0xFFBE123C)], // rose
  [Color(0xFF0D9488), Color(0xFF0891B2)], // teal
];

IconData _iconForSubject(String name) {
  final n = name.toLowerCase();
  if (n.contains('physical') || n.contains('health'))
    return Icons.directions_run_rounded;
  if (n.contains('science')) return Icons.science_outlined;
  if (n.contains('ict') || n.contains('information and communication'))
    return Icons.computer_rounded;
  if (n.contains('math')) return Icons.calculate_outlined;
  if (n.contains('islam') ||
      n.contains('hindu') ||
      n.contains('christian') ||
      n.contains('buddhist') ||
      n.contains('religion')) {
    return Icons.nightlight_round;
  }
  if (n.contains('agriculture')) return Icons.eco_outlined;
  if (n.contains('work and life')) return Icons.favorite_border_rounded;
  return Icons.menu_book_rounded;
}

Color _tagColor(String role) {
  switch (role) {
    case 'religion_moral':
      return const Color(0xFF059669);
    case 'gender_based':
      return const Color(0xFF2563EB);
    case 'group_subject':
      return const Color(0xFF7C3AED);
    case 'optional':
    case 'fourth_subject':
      return const Color(0xFFEA580C);
    default:
      return const Color(0xFF6B7280);
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.index});
  final StudentSubject subject;
  final int index;

  @override
  Widget build(BuildContext context) {
    final gradientColors = _gradients[index % _gradients.length];
    final tagColor = _tagColor(subject.effectiveRole);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
        color: context.surfaceColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 74,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _iconForSubject(subject.name),
                  color: Colors.white,
                  size: 20,
                ),
                if (subject.code != null && subject.code!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subject.code!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subject.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subject.tagLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: tagColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
