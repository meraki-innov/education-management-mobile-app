import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_profile.dart';

import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final currentUserProvider = FutureProvider<UserProfile>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
});

class LoginController extends StateNotifier<AsyncValue<String>> {
  LoginController(this._authRepository) : super(const AsyncValue.data(''));

  final AuthRepository _authRepository;

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () =>
          _authRepository.login(emailOrPhone: emailOrPhone, password: password),
    );
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<String>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return LoginController(repository);
    });
