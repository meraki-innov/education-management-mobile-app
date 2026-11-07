import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/student_profile_repository_impl.dart';
import '../../domain/entities/student_profile_details.dart';
import '../../domain/repositories/student_profile_repository.dart';

final studentProfileRepositoryProvider = Provider<StudentProfileRepository>(
  (ref) => StudentProfileRepositoryImpl(),
);

final studentProfileProvider = FutureProvider<StudentProfileDetails>((
  ref,
) async {
  return ref.watch(studentProfileRepositoryProvider).getMyProfile();
});
