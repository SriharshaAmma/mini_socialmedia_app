import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/generated_classes.dart';
import '../../stories/data/follow_repository.dart';
import '../data/public_profile_repository.dart';
import '../../feed/presentation/widgets/post_card.dart';
import 'follow_list_screen.dart' hide followRepositoryProvider;

class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(publicProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Profile'),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('❌ Error: $e')),
        data: (data) {
          final profile = data['profile'] as Profiles?;
          final posts = data['posts'] as List<Posts>;
          final followRepo = ref.watch(followRepositoryProvider);

          if (profile == null) {
            return const Center(child: Text("User not found"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),

                const SizedBox(height: 12),

                // Username
                Text(
                  profile.username ?? 'Unknown User',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // Bio
                Text(
                  profile.bio ?? 'No bio added',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // Followers / Following / Posts
                FutureBuilder<Map<String, int>>(
                  future: followRepo.getFollowStats(profile.id!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final stats = snapshot.data!;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('Posts', posts.length.toString()),
                        _buildStat('Followers', stats['followers'].toString(), () {
                          context.push('/followers/${profile.id}');
                        }),
                        _buildStat('Following', stats['following'].toString(), () {
                          context.push('/following/${profile.id}');
                        }),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Follow / Unfollow Button
                FutureBuilder<bool>(
                  future: followRepo.isFollowing(profile.id!),
                  builder: (context, snapshot) {
                    final isFollowing = snapshot.data ?? false;

                    return ElevatedButton.icon(
                      onPressed: () async {
                        if (isFollowing) {
                          await followRepo.unfollowUser(profile.id!);
                        } else {
                          await followRepo.followUser(profile.id!);
                        }
                        ref.refresh(publicProfileProvider(userId));
                      },
                      icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
                      label: Text(isFollowing ? "Unfollow" : "Follow"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.red : Colors.green,
                      ),
                    );
                  },
                ),

                const Divider(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '📸 Posts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // User Posts
                posts.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No posts available"),
                )
                    : Column(
                  children: posts.map((post) => PostCard(post: post)).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Stats Widget
  Widget _buildStat(String label, String count, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
