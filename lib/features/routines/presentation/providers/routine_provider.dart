import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/routine_repository_impl.dart';
import '../../domain/entities/routine_item.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../../class/presentation/providers/class_provider.dart';
import '../../../class/domain/entities/class_item.dart';

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepositoryImpl(),
);

// The class currently shown on the Routines screen. A student never sets
// this themselves — the screen locks it to their own class as soon as it
// resolves. Staff (teacher/admin) pick it from the dropdown.
final selectedRoutineClassProvider = StateProvider<String?>((ref) => null);

final routinesProvider = FutureProvider<List<RoutineItem>>((ref) async {
  final classUid = ref.watch(selectedRoutineClassProvider);
  if (classUid == null || classUid.isEmpty) return [];
  return ref.watch(routineRepositoryProvider).getRoutines(classUid: classUid);
});

// Full branch class list, for the staff-only class dropdown and for
// resolving a class_uid to its display name. The classes list endpoint is
// public/unrestricted on the backend, so this is safe for any logged-in role.
final allClassesProvider = FutureProvider<List<ClassItem>>((ref) async {
  final repository = ref.watch(classRepositoryProvider);
  final result = await repository.getClasses(page: 1, search: '');
  return result.items;
});