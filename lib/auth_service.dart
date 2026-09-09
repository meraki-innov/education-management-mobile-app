import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'http://192.168.0.244:8080/api/public';
  final _secureStorage = const FlutterSecureStorage();

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final isEmail = emailOrPhone.contains('@');
    final response = await http
        .post(
          Uri.parse("$_baseUrl/auth/login/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": isEmail ? emailOrPhone : "",
            "phone_no": isEmail ? "" : emailOrPhone,
            "password": password,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body["error"] ?? "Login failed");
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    await _secureStorage.write(
      key: "access_token",
      value: json["accessToken"] as String,
    );
    await _secureStorage.write(
      key: "refresh_token",
      value: json["refreshToken"] as String,
    );
  }
}
