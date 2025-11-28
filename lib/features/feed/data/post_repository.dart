import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

part 'post_repository.g.dart';

@riverpod
class PostRepository extends _$PostRepository {
  final _client = AppSupabase.client;

  @override
  void build() {}

  /// 📤 Upload Image to Supabase Storage
  Future<String> uploadImage(File file) async {
    final userId = _client.auth.currentUser!.id;
    final filePath = 'posts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('posts').upload(
      filePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _client.storage.from('posts').getPublicUrl(filePath);
  }

  /// 📝 Save Post to Supabase Database
  Future<void> createPost(String caption, String imageUrl) async {
    final userId = _client.auth.currentUser!.id;

    // ✅ ENSURE PROFILE EXISTS FIRST (fixes foreign key error)
    await _ensureProfileExists(userId);

    // Now insert the post
    await _client.from('posts').insert({
      'user_id': userId,
      'caption': caption,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 🛡️ Helper: Ensure profile exists before posting
  Future<void> _ensureProfileExists(String userId) async {
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      // Create a basic profile automatically
      final email = _client.auth.currentUser?.email ?? 'user';
      final username = email.split('@').first;

      await _client.from('profiles').insert({
        'id': userId,
        'username': username,
        'bio': 'New user 🌟',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
}