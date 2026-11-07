import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/login_provider.dart';
import '../features/routines/presentation/providers/routine_provider.dart';
import '../features/routines/domain/entities/routine_item.dart';
import '../features/class/domain/entities/class_item.dart';
import '../features/my_subjects/presentation/providers/student_subjects_provider.dart';

const _staffRoles = {'teacher', 'school_admin', 'branch_admin', 'employee'};

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserProvider).valueOrNull?.roleName;
    final isStaff = role != null && _staffRoles.contains(role);

    // A student can never pick a class — lock it to their own as soon as
    // it resolves. Runs once; after that selectedRoutineClassProvider
    // already holds a value so this is a no-op.
    if (!isStaff) {
      ref.listen<AsyncValue<String>>(studentClassUidProvider, (previous, next) {
        next.whenData((classUid) {
          if (classUid.isNotEmpty &&
              ref.read(selectedRoutineClassProvider) == null) {
            ref.read(selectedRoutineClassProvider.notifier).state = classUid;
          }
        });
      });
      // Kick the fetch off even before the listener above has a chance to fire.
      ref.watch(studentClassUidProvider);
    }

    // Staff get a usable default: the first class in the branch, until they
    // pick a different one themselves.
    if (isStaff) {
      ref.listen<AsyncValue<List<ClassItem>>>(allClassesProvider, (
        previous,
        next,
      ) {
        next.whenData((classes) {
          if (classes.isNotEmpty &&
              ref.read(selectedRoutineClassProvider) == null) {
            ref.read(selectedRoutineClassProvider.notifier).state =
                classes.first.uid;
          }
        });
      });
    }

    final classesAsync = ref.watch(allClassesProvider);
    final selectedClassUid = ref.watch(selectedRoutineClassProvider);
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Routines',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: context.surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                      ),
                      // Routines has no server-side search — this filters the
                      // already-loaded list by title as the user types.
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  isStaff
                      ? _ClassDropdown(
                          classesAsync: classesAsync,
                          selectedClassUid: selectedClassUid,
                        )
                      : _LockedClassField(
                          classesAsync: classesAsync,
                          classUid: selectedClassUid,
                        ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: routinesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (routines) {
                    final filtered = _query.isEmpty
                        ? routines
                        : routines
                              .where(
                                (r) => r.title.toLowerCase().contains(_query),
                              )
                              .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 48,
                              color: context.mutedText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No routine has been uploaded for this class yet.',
                              style: TextStyle(color: context.mutedText),
                            ),
                          ],
                        ),
                      );
                    }

                    final classes =
                        classesAsync.valueOrNull ?? const <ClassItem>[];
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final routine = filtered[index];
                        final className = classes
                            .firstWhere(
                              (c) => c.uid == routine.classUid,
                              orElse: () => ClassItem(
                                uid: routine.classUid,
                                name: '—',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            )
                            .name;
                        return _RoutineCard(
                          routine: routine,
                          className: className,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassDropdown extends ConsumerWidget {
  const _ClassDropdown({
    required this.classesAsync,
    required this.selectedClassUid,
  });
  final AsyncValue<List<ClassItem>> classesAsync;
  final String? selectedClassUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return classesAsync.when(
      loading: () => const SizedBox(
        width: 120,
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (classes) {
        final validValue = classes.any((c) => c.uid == selectedClassUid)
            ? selectedClassUid
            : null;
        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(10),
            color: context.surfaceColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: validValue,
              hint: const Text('Select class'),
              items: [
                for (final c in classes)
                  DropdownMenuItem(value: c.uid, child: Text(c.name)),
              ],
              onChanged: (value) =>
                  ref.read(selectedRoutineClassProvider.notifier).state = value,
            ),
          ),
        );
      },
    );
  }
}

// A student sees their own class here, but it's read-only — no dropdown,
// nothing to tap. Only teachers/admins can switch classes.
class _LockedClassField extends StatelessWidget {
  const _LockedClassField({required this.classesAsync, required this.classUid});
  final AsyncValue<List<ClassItem>> classesAsync;
  final String? classUid;

  @override
  Widget build(BuildContext context) {
    final classes = classesAsync.valueOrNull ?? const <ClassItem>[];
    final name = classUid == null
        ? '...'
        : classes
              .firstWhere(
                (c) => c.uid == classUid,
                orElse: () => ClassItem(
                  uid: '',
                  name: 'Your Class',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              )
              .name;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
        color: context.iconBoxColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: context.mutedText),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: context.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.className});
  final RoutineItem routine;
  final String className;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final isExam = routine.routineType == 'exam_routine';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(12),
        color: context.surfaceColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  routine.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isExam ? Colors.orange : context.brandColor)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  routine.routineTypeLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isExam ? Colors.orange.shade800 : context.brandColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$className  ·  Published ${dateFormat.format(routine.publishDate)}  ·  ${routine.sizeLabel}',
            style: TextStyle(fontSize: 12, color: context.mutedText),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: routine.fileUrl.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: routine.fileUrl),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'File link copied — paste it in your browser to view it.',
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('View File'),
            ),
          ),
        ],
      ),
    );
  }
}
