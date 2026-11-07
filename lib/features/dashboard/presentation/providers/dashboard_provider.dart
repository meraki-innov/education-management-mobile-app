import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/student_dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl();
});

final studentDashboardProvider = FutureProvider<StudentDashboard>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getStudentDashboard();
});
