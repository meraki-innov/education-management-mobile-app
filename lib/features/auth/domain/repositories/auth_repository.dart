import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<String> login({
    required String emailOrPhone,
    required String password,
  });
  Future<UserProfile> getCurrentUser();
}
