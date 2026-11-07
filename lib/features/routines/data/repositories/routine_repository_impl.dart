import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/routine_item.dart';
import '../../domain/repositories/routine_repository.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  static String get _baseUrl => '${dotenv.env['API_BASE_URL']}/protected';
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<List<RoutineItem>> getRoutines({required String classUid}) async {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final branchUid = await _secureStorage.read(key: 'branch_uid');

    if (accessToken == null || branchUid == null || branchUid.isEmpty) {
      throw Exception('Missing login info — please log in again.');
    }

    // internal/domains/assessments: GET /by/branch/routine/{branch_uid}/
    // class_uid is optional server-side, but the app always sends one —
    // either picked by staff or locked to the student's own class.
    final uri = Uri.parse(
      '$_baseUrl/assessments/by/branch/routine/$branchUid/?class_uid=$classUid',
    );

    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        body['error'] ?? body['message'] ?? 'Failed to load routines',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = json['data'] as List<dynamic>? ?? [];

    return rawList.map((raw) {
      final r = raw as Map<String, dynamic>;
      return RoutineItem(
        uid: r['uid'] as String? ?? '',
        title: r['title'] as String? ?? '',
        classUid: r['class_uid'] as String? ?? '',
        routineType: r['routine_type'] as String? ?? '',
        publishDate:
            DateTime.tryParse(r['publish_date'] as String? ?? '') ??
            DateTime.now(),
        sizeBytes: (r['size'] as num?)?.toInt(),
        fileUrl: r['file_url'] as String? ?? '',
      );
    }).toList();
  }
}
