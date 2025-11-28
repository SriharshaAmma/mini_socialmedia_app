import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

part 'auth_repository.g.dart';

@riverpod
class AuthRepository extends _$AuthRepository {
  final _client = AppSupabase.client;

  @override
  Stream<User?> build() {
    return _client.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  // 🔹 Get current user synchronously
  User? get currentUser => _client.auth.currentUser;

  // 🔹 Login (with profile auto-creation)
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw Exception('Login failed: No user returned');
      }

      // Check if profile exists, create if missing
      await _ensureProfileExists(user.id, email);

      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // Re-throw so UI can handle it
    }
  }

  // 🔹 Signup (with email verification support)
  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Signup failed: No user returned');
      }

      // Create profile immediately
      await _createProfile(user.id, email);

      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _client.auth.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // 🔹 Helper: Ensure profile exists
  Future<void> _ensureProfileExists(String userId, String email) async {
    try {
      final existing = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        await _createProfile(userId, email);
      }
    } catch (e) {
      // Log error but don't fail login
      print('Profile check/creation error: $e');
    }
  }

  // 🔹 Helper: Create new profile
  Future<void> _createProfile(String userId, String email) async {
    await _client.from('profiles').insert({
      'id': userId,
      'email': email,
      'username': email.split('@')[0],
      'avatar_url': null,
      'bio': 'Hey there! I am using Mini Social App.',
    });
  }

  // 🔹 Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // 🔹 Update password
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}