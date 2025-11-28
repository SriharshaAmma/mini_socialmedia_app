import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 📦 Repository Provider
final followRepositoryProvider = Provider((ref) => FollowRepository());

/// Repository for Follow Operations
class FollowRepository {
  final supabase = Supabase.instance.client;

  /// Follow a user
  Future<void> followUser(String followingId) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('follows').insert({
      'follower_id': userId,
      'following_id': followingId,
    });
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followingId) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('follows')
        .delete()
        .eq('follower_id', userId)
        .eq('following_id', followingId);
  }

  /// Check if following
  Future<bool> isFollowing(String profileId) async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('follows')
        .select()
        .eq('follower_id', userId)
        .eq('following_id', profileId)
        .maybeSingle();

    return res != null;
  }

  /// Get numbers (followers, following) - COMPLETELY FIXED
  Future<Map<String, int>> getFollowStats(String profileId) async {
    try {
      print('🔍 Getting follow stats for: $profileId');

      // Count followers - people who follow this profile
      final followersData = await supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', profileId);

      // Count following - people this profile follows
      final followingData = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', profileId);

      print('✅ Stats loaded: ${(followersData as List).length} followers, ${(followingData as List).length} following');

      return {
        'followers': (followersData as List).length,
        'following': (followingData as List).length,
      };
    } catch (e) {
      print('❌ ERROR in getFollowStats: $e');
      return {
        'followers': 0,
        'following': 0,
      };
    }
  }

  /// Get list of followers with profile data - MANUAL JOIN (FIXED)
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      print('🔍 Getting followers for: $userId');

      // Step 1: Get all follower IDs
      final followsData = await supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);

      if ((followsData as List).isEmpty) {
        print('✅ No followers found');
        return [];
      }

      // Step 2: Extract follower IDs
      final followerIds = followsData.map((item) => item['follower_id'] as String).toList();
      print('🔍 Found ${followerIds.length} follower IDs');

      // Step 3: Fetch profiles for those IDs
      final profilesData = await supabase
          .from('profiles')
          .select('id, username, avatar_url, bio')
          .inFilter('id', followerIds);

      print('✅ Loaded ${(profilesData as List).length} follower profiles');

      return (profilesData as List).map((profile) {
        return {
          'id': profile['id'],
          'username': profile['username'] ?? 'Unknown',
          'avatar_url': profile['avatar_url'],
          'bio': profile['bio'],
        };
      }).toList();
    } catch (e) {
      print('❌ ERROR in getFollowers: $e');
      return [];
    }
  }

  /// Get list of following with profile data - MANUAL JOIN (FIXED)
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      print('🔍 Getting following for: $userId');

      // Step 1: Get all following IDs
      final followsData = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      if ((followsData as List).isEmpty) {
        print('✅ Not following anyone');
        return [];
      }

      // Step 2: Extract following IDs
      final followingIds = followsData.map((item) => item['following_id'] as String).toList();
      print('🔍 Found ${followingIds.length} following IDs');

      // Step 3: Fetch profiles for those IDs
      final profilesData = await supabase
          .from('profiles')
          .select('id, username, avatar_url, bio')
          .inFilter('id', followingIds);

      print('✅ Loaded ${(profilesData as List).length} following profiles');

      return (profilesData as List).map((profile) {
        return {
          'id': profile['id'],
          'username': profile['username'] ?? 'Unknown',
          'avatar_url': profile['avatar_url'],
          'bio': profile['bio'],
        };
      }).toList();
    } catch (e) {
      print('❌ ERROR in getFollowing: $e');
      return [];
    }
  }
}

// 📋 Providers for Followers/Following Lists
final followersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final repo = ref.read(followRepositoryProvider);
  return await repo.getFollowers(userId);
});

final followingProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final repo = ref.read(followRepositoryProvider);
  return await repo.getFollowing(userId);
});

/// 👥 Follow List Screen - Shows Followers or Following
class FollowListScreen extends ConsumerWidget {
  final String userId;
  final bool showFollowers; // true = Followers, false = Following

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = showFollowers
        ? ref.watch(followersProvider(userId))
        : ref.watch(followingProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(showFollowers ? 'Followers' : 'Following'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '❌ Error: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    showFollowers ? Icons.people_outline : Icons.person_add_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    showFollowers ? 'No followers yet 😔' : 'Not following anyone 😔',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final avatar = user['avatar_url'] as String?;
              final hasAvatar = avatar != null && avatar.isNotEmpty;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                  child: !hasAvatar
                      ? Text(
                    (user['username'] as String)[0].toUpperCase(),
                    style: const TextStyle(fontSize: 20),
                  )
                      : null,
                ),
                title: Text(
                  user['username'] ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  user['bio'] ?? 'No bio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/user/${user['id']}');
                },
              );
            },
          );
        },
      ),
    );
  }
}