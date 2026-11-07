import 'dart:convert';
import 'package:education_management_mobile_app1/features/auth/domain/entities/user_profile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static String get _baseUrl => '${dotenv.env['API_BASE_URL']}/public';
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<String> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final isEmail = emailOrPhone.contains('@');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': isEmail ? emailOrPhone : '',
            'phone_no': isEmail ? '' : emailOrPhone,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Login failed');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Tokens — needed to authenticate every future request.
    await _secureStorage.write(
      key: 'access_token',
      value: json['accessToken'] as String,
    );
    await _secureStorage.write(
      key: 'refresh_token',
      value: json['refreshToken'] as String,
    );

    // NEW: save the IDs the dashboard endpoint needs. These come from the
    // same login response — nullable fields use `?? ''` since not every
    // role has a studentUID, for example.
    await _secureStorage.write(key: 'user_uid', value: json['uid'] as String);
    await _secureStorage.write(
      key: 'branch_uid',
      value: (json['branch_uid'] as String?) ?? '',
    );
    await _secureStorage.write(
      key: 'student_uid',
      value: (json['studentUID'] as String?) ?? '',
    );
    await _secureStorage.write(
      key: 'first_name',
      value: json['firstName'] as String,
    );
    await _secureStorage.write(
      key: 'last_name',
      value: json['lastName'] as String,
    );
    await _secureStorage.write(
      key: 'image_url',
      value: (json['image_url'] as String?) ?? '',
    );
    final rawRole = (json['name'] as String).trim();
    final roleName = rawRole == 'teache' ? 'teacher' : rawRole;

    await _secureStorage.write(key: 'role_name', value: roleName);

    return roleName;
  }

  @override
  Future<UserProfile> getCurrentUser() async {
    final firstName = await _secureStorage.read(key: "first_name") ?? "";
    final lastName = await _secureStorage.read(key: "last_name") ?? "";
    final roleName = await _secureStorage.read(key: "role_name") ?? "";
    final imageUrl = await _secureStorage.read(key: "image_url") ?? "";

    return UserProfile(
      firstName: firstName,
      lastName: lastName,
      roleName: roleName,
      imageUrl: imageUrl,
    );
  }
}
