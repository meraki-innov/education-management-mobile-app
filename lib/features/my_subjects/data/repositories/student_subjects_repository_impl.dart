import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/student_subject.dart';
import '../../domain/repositories/student_subjects_repository.dart';

class StudentSubjectsRepositoryImpl implements StudentSubjectsRepository {
  static String get _baseUrl => '${dotenv.env['API_BASE_URL']}/protected';
  final _secureStorage = const FlutterSecureStorage();

  // Both getMySubjects() and getMyClassUid() read off the same endpoint —
  // this is the one place that calls it and parses the response body.
  Future<Map<String, dynamic>> _fetchEnrollment() async {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final branchUid = await _secureStorage.read(key: 'branch_uid');
    final studentUid = await _secureStorage.read(key: 'student_uid');

    if (accessToken == null || branchUid == null || branchUid.isEmpty) {
      throw Exception('Missing login info — please log in again.');
    }
    if (studentUid == null || studentUid.isEmpty) {
      throw Exception('No student profile found for this account.');
    }

    // Backend resolves the student's active enrollment itself and returns
    // its effective subject list (student_registrations/student_subjects.go).
    // No academic_year_uid passed — the backend defaults to the latest one.
    final uri = Uri.parse(
      '$_baseUrl/student_registrations/branch/$branchUid/students/$studentUid/subjects/',
    );

    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to load subjects');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<StudentSubject>> getMySubjects() async {
    final data = await _fetchEnrollment();
    final rawSubjects = data['subjects'] as List<dynamic>? ?? [];

    return rawSubjects.map((raw) {
      final s = raw as Map<String, dynamic>;
      return StudentSubject(
        subjectUid: s['subject_uid'] as String? ?? '',
        name: s['subject_name'] as String? ?? '',
        code: s['subject_code'] as String?,
        subjectType: s['subject_type'] as String? ?? '',
        effectiveRole: s['effective_subject_role'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<String> getMyClassUid() async {
    final data = await _fetchEnrollment();
    return data['class_uid'] as String? ?? '';
  }
}
