import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/card_gradients.dart';
import '../features/teacher_classroom/domain/entities/teacher_classroom.dart';
import '../features/teacher_classroom/presentation/providers/teacher_classroom_provider.dart';

// Academics > Class for teachers ("Classrooms" on the web). Cards are grouped
// by how the teacher is assigned: as class teacher, or as subject teacher.
// Banner colors live in core/theme/card_gradients.dart.

class TeacherClassroomsScreen extends ConsumerWidget {
  const TeacherClassroomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherClassroomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Classrooms',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: async.when(
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
                    onPressed: () => ref.invalidate(teacherClassroomsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (rooms) {
            if (rooms.isEmpty) {
              return Center(
                child: Text(
                  'No classrooms assigned yet.',
                  style: TextStyle(color: context.mutedText),
                ),
              );
            }
            final classTeacher = rooms
                .where((r) => r.role == ClassroomRole.classTeacher)
                .toList();
            final subjectTeacher = rooms
                .where((r) => r.role == ClassroomRole.subjectTeacher)
                .toList();

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(teacherClassroomsProvider),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (classTeacher.isNotEmpty)
                    _Group(
                      title: 'Assigned As Class Teacher',
                      subtitle: 'Classes where you are the class teacher.',
                      icon: Icons.co_present_outlined,
                      rooms: classTeacher,
                      colorOffset: 0,
                    ),
                  if (classTeacher.isNotEmpty && subjectTeacher.isNotEmpty)
                    const SizedBox(height: 20),
                  if (subjectTeacher.isNotEmpty)
                    _Group(
                      title: 'Assigned As Subject Teacher',
                      subtitle:
                          'Subject-based teaching responsibilities assigned separately.',
                      icon: Icons.menu_book_outlined,
                      rooms: subjectTeacher,
                      colorOffset: classTeacher.length,
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

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rooms,
    required this.colorOffset,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<TeacherClassroom> rooms;
  final int colorOffset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.iconBoxColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: context.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // One column on phones, two on wider screens (tablets).
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 640 ? 2 : 1;
            const gap = 14.0;
            final cardWidth = (c.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < rooms.length; i++)
                  SizedBox(
                    width: cardWidth,
                    child: _ClassroomCard(
                      room: rooms[i],
                      colors: CardGradients.bannerAt(colorOffset + i),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  const _ClassroomCard({required this.room, required this.colors});
  final TeacherClassroom room;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored banner: building icon top-left, role chip bottom-right.
          Container(
            height: 104,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          room.role.chipLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  room.subject,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Student Marks for ${room.title} is not built yet',
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.isDark
                          ? AppColors.darkAccent
                          : AppColors.primary700,
                      side: BorderSide(
                        color: context.isDark
                            ? AppColors.darkAccent
                            : AppColors.primary700,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Student Marks',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
