import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/auth_repository.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<void> build() {}

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      await ref.read(authRepositoryProvider.notifier).login(email, password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // Let UI handle the error
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      await ref.read(authRepositoryProvider.notifier).signUp(email, password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider.notifier).logout();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}