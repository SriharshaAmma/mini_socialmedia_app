import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/generated_classes.dart';

part 'public_profile_repository.g.dart';

@riverpod
Future<Map<String, dynamic>> publicProfile(PublicProfileRef ref, String userId) async {
  final client = Supabase.instance.client;

  // Fetch profile (No embedding, clean query)
  final profileData = await client
      .from('profiles')
      .select('id, username, avatar_url, bio')
      .eq('id', userId)
      .maybeSingle();

  Profiles? profile =
  profileData != null ? Profiles.fromJson(profileData) : null;

  // Fetch posts for this user
  final postsData = await client
      .from('posts')
      .select('id, caption, image_url, created_at, user_id')
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return {
    'profile': profile,
    'posts': (postsData as List)
        .map((e) => Posts.fromJson(e as Map<String, dynamic>))
        .toList(),
  };
}
