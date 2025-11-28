import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'saved_posts_repository.g.dart';

@riverpod
class SavedPostsRepository extends _$SavedPostsRepository {
  final _client = Supabase.instance.client;

  @override
  Future<List<dynamic>> build() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('saved_posts')
        .select('id, post_id, created_at, posts(*, profiles(*))')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return data;
  }

  // Save a post
  Future<void> savePost(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('saved_posts').insert({
      'user_id': user.id,
      'post_id': postId,
    });

    ref.invalidateSelf();
  }

  // Unsave a post
  Future<void> unsavePost(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client
        .from('saved_posts')
        .delete()
        .eq('user_id', user.id)
        .eq('post_id', postId);

    ref.invalidateSelf();
  }

  // Check if post is saved
  Future<bool> isPostSaved(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final data = await _client
        .from('saved_posts')
        .select('id')
        .eq('user_id', user.id)
        .eq('post_id', postId)
        .maybeSingle();

    return data != null;
  }

  // Toggle save/unsave
  Future<void> toggleSave(String postId) async {
    final isSaved = await isPostSaved(postId);
    if (isSaved) {
      await unsavePost(postId);
    } else {
      await savePost(postId);
    }
  }
}