import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/generated_classes.dart';

part 'story_repository.g.dart';

@riverpod
class StoryRepository extends _$StoryRepository {
  final _client = Supabase.instance.client;

  @override
  Future<List<Story>> build() async {
    return fetchStories();
  }

  /// Fetch all active stories (not expired, grouped by user)
  Future<List<Story>> fetchStories() async {
    final currentUserId = _client.auth.currentUser!.id;

    final data = await _client
        .from('stories')
        .select('''
          id, user_id, image_url, created_at, expires_at,
          profiles!inner(username, avatar_url),
          story_views!left(viewer_id)
        ''')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    final stories = (data as List).map((json) {
      final views = json['story_views'] as List;
      final hasViewed = views.any((v) => v['viewer_id'] == currentUserId);

      return Story(
        id: json['id'],
        userId: json['user_id'],
        imageUrl: json['image_url'],
        createdAt: DateTime.parse(json['created_at']),
        expiresAt: DateTime.parse(json['expires_at']),
        username: json['profiles']['username'],
        avatarUrl: json['profiles']['avatar_url'],
        viewCount: views.length,
        hasViewed: hasViewed,
      );
    }).toList();

    // Group by user, keep most recent per user
    final Map<String, Story> latestByUser = {};
    for (final story in stories) {
      if (!latestByUser.containsKey(story.userId) ||
          story.createdAt.isAfter(latestByUser[story.userId]!.createdAt)) {
        latestByUser[story.userId] = story;
      }
    }

    return latestByUser.values.toList();
  }

  /// Upload story image
  Future<String> uploadStoryImage(File file) async {
    final userId = _client.auth.currentUser!.id;
    final filePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('stories').upload(
      filePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _client.storage.from('stories').getPublicUrl(filePath);
  }

  /// Create a new story
  Future<void> createStory(String imageUrl) async {
    await _client.from('stories').insert({
      'user_id': _client.auth.currentUser!.id,
      'image_url': imageUrl,
    });
    ref.invalidateSelf();
  }

  /// Mark story as viewed
  Future<void> markAsViewed(String storyId) async {
    try {
      await _client.from('story_views').insert({
        'story_id': storyId,
        'viewer_id': _client.auth.currentUser!.id,
      });
    } catch (e) {
      // Ignore duplicate view errors
    }
  }

  /// Get all stories for a specific user
  Future<List<Story>> getUserStories(String userId) async {
    final data = await _client
        .from('stories')
        .select('*, profiles!inner(username, avatar_url), story_views(viewer_id)')
        .eq('user_id', userId)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (data as List).map((json) => Story.fromJson(json)).toList();
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    await _client.from('stories').delete().eq('id', storyId);
    ref.invalidateSelf();
  }
}