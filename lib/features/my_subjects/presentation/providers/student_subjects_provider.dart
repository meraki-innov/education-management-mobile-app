import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/student_subjects_repository_impl.dart';
import '../../domain/entities/student_subject.dart';
import '../../domain/repositories/student_subjects_repository.dart';

final studentSubjectsRepositoryProvider = Provider<StudentSubjectsRepository>(
  (ref) => StudentSubjectsRepositoryImpl(),
);

final studentSubjectsProvider = FutureProvider<List<StudentSubject>>((
  ref,
) async {
  return ref.watch(studentSubjectsRepositoryProvider).getMySubjects();
});

// The student's own class_uid — used by the Routines screen to lock the
// class filter so a student can never browse another class's routine.
final studentClassUidProvider = FutureProvider<String>((ref) async {
  return ref.watch(studentSubjectsRepositoryProvider).getMyClassUid();
});
