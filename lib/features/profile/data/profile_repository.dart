import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/generated_classes.dart'; // ⚠️ Adjust this import path to match your project

part 'profile_repository.g.dart';

@riverpod
class ProfileRepository extends _$ProfileRepository {
  @override
  Future<Map<String, dynamic>> build() async {
    // ⚠️ CRITICAL: This MUST return Future<Map<String, dynamic>>, NOT void!
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) throw Exception("User not logged in");

    // Fetch profile safely
    final profileData = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    // 🚀 If no profile exists, return NULL instead of crashing
    Profiles? profile = profileData != null ? Profiles.fromJson(profileData) : null;

    // Fetch posts with profile joins
    final postsData = await client
        .from('posts')
        .select('id, caption, image_url, created_at, user_id, profiles(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return {
      'profile': profile, // ⬅️ Can be null
      'posts': (postsData as List)
          .map((e) => Posts.fromJson(e as Map<String, dynamic>))
          .toList(),
    };
  }
}