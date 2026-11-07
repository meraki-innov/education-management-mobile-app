import '../entities/routine_item.dart';

abstract class RoutineRepository {
  Future<List<RoutineItem>> getRoutines({required String classUid});
}
