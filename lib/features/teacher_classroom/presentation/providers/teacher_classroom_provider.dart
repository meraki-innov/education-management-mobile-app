// lib/features/teacher_classrooms/presentation/providers/teacher_classroom_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/teacher_classroom_repository.dart';
import '../../domain/entities/teacher_classroom.dart';

// Swap LocalTeacherClassroomRepository for the API one here when it exists.
final teacherClassroomRepositoryProvider = Provider<TeacherClassroomRepository>(
  (ref) => LocalTeacherClassroomRepository(),
);

final teacherClassroomsProvider = FutureProvider<List<TeacherClassroom>>((ref) {
  return ref.watch(teacherClassroomRepositoryProvider).getMyClassrooms();
});
