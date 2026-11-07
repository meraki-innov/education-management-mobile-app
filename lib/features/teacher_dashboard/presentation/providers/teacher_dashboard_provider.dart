import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/teacher_dashboard_repository.dart';
import '../../domain/entities/teacher_dashboard.dart';

final TeacherDashboardRespositoryProvider =
    Provider<TeacherDashboardRespository>(
      (ref) => LocalTeacherDashboardRepository(),
    );

final teacherDashboardProvider = FutureProvider<TeacherDashboard>((ref) {
  return ref.watch(TeacherDashboardRespositoryProvider).getDashboard();
});
