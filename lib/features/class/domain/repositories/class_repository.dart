import '../entities/class_list_result.dart';

abstract class ClassRepository {
  Future<ClassListResult> getClasses({int page = 1, String search = ''});

  Future<void> createClass(String name);

  Future<void> updateClass(String uid, String name);

  Future<void> deleteClasses(List<String> uids);
}
