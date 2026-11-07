import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/class_repository_impl.dart';
import '../../domain/entities/class_list_result.dart';
import '../../domain/repositories/class_repository.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepositoryImpl();
});

class ClassListController extends StateNotifier<AsyncValue<ClassListResult>> {
  ClassListController(this._repository) : super(const AsyncValue.loading()) {
    loadClasses(); // fetch as soon as this controller is created
  }

  final ClassRepository _repository;
  String _search = '';
  int _page = 1;

  Future<void> loadClasses({String? search, int? page}) async {
    if (search != null) _search = search;
    if (page != null) _page = page;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getClasses(page: _page, search: _search),
    );
  }

  Future<void> addClass(String name) async {
    await _repository.createClass(name);
    await loadClasses(page: 1); // back to page 1 so the new class is visible
  }

  Future<void> editClass(String uid, String name) async {
    await _repository.updateClass(uid, name);
    await loadClasses(); // refresh current page with the updated name
  }

  Future<void> deleteClass(String uid) async {
    await _repository.deleteClasses([uid]);
    await loadClasses();
  }
}

final classListControllerProvider =
    StateNotifierProvider<ClassListController, AsyncValue<ClassListResult>>((
      ref,
    ) {
      final repository = ref.watch(classRepositoryProvider);
      return ClassListController(repository);
    });
