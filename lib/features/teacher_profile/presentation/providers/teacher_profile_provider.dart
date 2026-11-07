import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/teacher_profile_repository.dart';
import '../../domain/entities/teacher_profile.dart';

final teacherProfileRepositoryProvider = Provider<TeacherProfileRepository>(
  (ref) => LocalTeacherProfileRepository(),
);

final teacherProfileProvider = FutureProvider<TeacherProfile>((ref) {
  return ref.watch(teacherProfileRepositoryProvider).getMyProfile();
});
