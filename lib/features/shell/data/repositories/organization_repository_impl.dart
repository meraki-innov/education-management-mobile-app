import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/organization_info.dart';
import '../../domain/repositories/organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  static String get _api => dotenv.env['API_BASE_URL']!;
  final _storage = const FlutterSecureStorage();

  @override
  Future<OrganizationInfo> getOrganization() async {
    final branchUid = await _storage.read(key: 'branch_uid');
    final token = await _storage.read(key: 'access_token');

    // Some roles (a system admin, for example) have no branch, so there is
    // nothing to show. The sidebar hides the card when names are empty.
    if (branchUid == null || branchUid.isEmpty || token == null) {
      return OrganizationInfo(schoolName: '', branchName: '');
    }

    // The branch endpoint gives the branch name and which school it belongs to.
    final branchRes = await http
        .get(Uri.parse('$_api/public/school-branches/$branchUid/'))
        .timeout(const Duration(seconds: 10));
    if (branchRes.statusCode != 200) throw Exception('Failed to load branch');
    final branch = jsonDecode(branchRes.body) as Map<String, dynamic>;

    // The school endpoint gives the school name.
    final schoolRes = await http
        .get(
          Uri.parse('$_api/protected/schools/${branch['school_uid']}/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    if (schoolRes.statusCode != 200) throw Exception('Failed to load school');
    final body = jsonDecode(schoolRes.body) as Map<String, dynamic>;
    // Accept either a plain object or one wrapped in "data".
    final school = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;

    return OrganizationInfo(
      schoolName: (school['name'] as String?) ?? '',
      branchName: (branch['name'] as String?) ?? '',
    );
  }
}