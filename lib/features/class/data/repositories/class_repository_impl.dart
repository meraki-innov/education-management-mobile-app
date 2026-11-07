import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/class_item.dart';
import '../../domain/entities/class_list_result.dart';
import '../../domain/repositories/class_repository.dart';

class ClassRepositoryImpl implements ClassRepository {
  static String get _baseUrl =>
      '${dotenv.env['API_BASE_URL']}/protected/classes';
  final _secureStorage = const FlutterSecureStorage();

  // Every request here needs the same two things — the token to prove
  // who's asking, and the branch this admin manages. Small helper so the
  // 4 methods below don't each repeat this.
  Future<Map<String, String>> _authAndBranch() async {
    final token = await _secureStorage.read(key: 'access_token');
    final branchUid = await _secureStorage.read(key: 'branch_uid');
    if (token == null || branchUid == null || branchUid.isEmpty) {
      throw Exception('Missing login info — please log in again.');
    }
    return {'token': token, 'branchUid': branchUid};
  }

  @override
  Future<ClassListResult> getClasses({int page = 1, String search = ''}) async {
    final auth = await _authAndBranch();

    final uri = Uri.parse('$_baseUrl/${auth['branchUid']}/').replace(
      queryParameters: {
        'page': '$page',
        'page_size': '10',
        if (search.isNotEmpty) 'search': search,
      },
    );

    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${auth['token']}'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load classes');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;

    return ClassListResult(
      items: data.map((raw) {
        final item = raw as Map<String, dynamic>;
        return ClassItem(
          uid: item['uid'] as String,
          name: (item['name'] as String?) ?? '',
          createdAt: DateTime.parse(item['created_at'] as String),
          updatedAt: DateTime.parse(item['updated_at'] as String),
        );
      }).toList(),
      page: json['page'] as int,
      totalPages: json['total_pages'] as int,
      total: json['total'] as int,
    );
  }

  @override
  Future<void> createClass(String name) async {
    final auth = await _authAndBranch();

    final response = await http
        .post(
          Uri.parse('$_baseUrl/${auth['branchUid']}/'),
          headers: {
            'Authorization': 'Bearer ${auth['token']}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create class');
    }
  }

  @override
  Future<void> updateClass(String uid, String name) async {
    final auth = await _authAndBranch();

    final response = await http
        .patch(
          Uri.parse('$_baseUrl/${auth['branchUid']}/$uid/'),
          headers: {
            'Authorization': 'Bearer ${auth['token']}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to update class');
    }
  }

  @override
  Future<void> deleteClasses(List<String> uids) async {
    final auth = await _authAndBranch();

    final response = await http
        .post(
          Uri.parse('$_baseUrl/${auth['branchUid']}/delete-multiple/'),
          headers: {
            'Authorization': 'Bearer ${auth['token']}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'uids': uids}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete class');
    }
  }
}
