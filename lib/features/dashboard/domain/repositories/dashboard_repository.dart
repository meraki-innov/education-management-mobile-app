import '../entities/student_dashboard.dart';

abstract class DashboardRepository {
  Future<StudentDashboard> getStudentDashboard();
}
