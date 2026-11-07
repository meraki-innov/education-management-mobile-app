import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/student_dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  // Protected endpoints live under /protected, not /public like login.
  static String get _baseUrl => '${dotenv.env['API_BASE_URL']}/protected';
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<StudentDashboard> getStudentDashboard() async {
    // Pull everything this request needs from what login already saved —
    // this class doesn't know or care HOW those got there.
    final accessToken = await _secureStorage.read(key: 'access_token');
    final branchUid = await _secureStorage.read(key: 'branch_uid');
    final userUid = await _secureStorage.read(key: 'user_uid');
    final studentUid = await _secureStorage.read(key: 'student_uid');

    if (accessToken == null || branchUid == null || branchUid.isEmpty) {
      throw Exception('Missing login info — please log in again.');
    }

    // Backend accepts EITHER user_uid or student_profile_uid — prefer the
    // student-specific one when we have it.
    final queryParam = (studentUid != null && studentUid.isNotEmpty)
        ? 'student_profile_uid=$studentUid'
        : 'user_uid=$userUid';

    final response = await http
        .get(
          Uri.parse('$_baseUrl/dashboard/$branchUid/student/?$queryParam'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to load dashboard');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final attendance = json['attendance_summary'] as Map<String, dynamic>;

    return StudentDashboard(
      totalAttendance: attendance['total_count'] as int,
      presentCount: attendance['present_count'] as int,
      absentCount: attendance['absent_count'] as int,
      totalTasks: json['total_tasks'] as int,
      pendingTasks: json['pending_tasks'] as int,
      totalAssessments: json['total_assessments'] as int,
      marksEntered: json['marks_entered'] as int,
      averagePercentage: (json['average_percentage'] as num).toDouble(),
      unpaidInvoices: json['unpaid_invoices'] as int,
      paidInvoices: json['paid_invoices'] as int,
      totalDueAmount: (json['total_due_amount'] as num).toDouble(),
    );
  }
}
