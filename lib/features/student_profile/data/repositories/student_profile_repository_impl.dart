import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/student_profile_details.dart';
import '../../domain/repositories/student_profile_repository.dart';

class StudentProfileRepositoryImpl implements StudentProfileRepository {
  static String get _baseUrl => '${dotenv.env['API_BASE_URL']}/protected';
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<StudentProfileDetails> getMyProfile() async {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final branchUid = await _secureStorage.read(key: 'branch_uid');
    final userUid = await _secureStorage.read(key: 'user_uid');

    if (accessToken == null ||
        branchUid == null ||
        branchUid.isEmpty ||
        userUid == null ||
        userUid.isEmpty) {
      throw Exception('Missing login info — please log in again.');
    }

    // student_registrations: GET /branch/{branch_uid}/student-profile/{user_uid}/
    final uri = Uri.parse(
      '$_baseUrl/student_registrations/branch/$branchUid/student-profile/$userUid/',
    );

    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to load profile');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final d = json['data'] as Map<String, dynamic>;

    // Note: this endpoint uses camelCase for names (firstName/lastName)
    // but snake_case for everything else.
    return StudentProfileDetails(
      firstName: d['firstName'] as String? ?? '',
      lastName: d['lastName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      rollNumber: d['roll_number'] as String? ?? '',
      gender: d['gender'] as String?,
      dateOfBirth: d['date_of_birth'] as String?,
      bloodGroup: d['blood_group'] as String?,
      activityStatus: d['activity_status'] as String?,
      className: d['class_name'] as String?,
      sectionName: d['section_name'] as String?,
      academicYearName: d['academic_year_name'] as String?,
      roleName: d['role_name'] as String?,
      currentAddress: d['current_address'] as String?,
      permanentAddress: d['permanent_address'] as String?,
      imageUrl: d['image_url'] as String?,
    );
  }
}
