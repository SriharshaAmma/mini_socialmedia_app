import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../../stories/data/follow_repository.dart';
import '../../feed/presentation/widgets/post_card.dart';
import '../../auth/presentation/controllers/login_controller.dart';
import 'package:go_router/go_router.dart';

import 'follow_list_screen.dart' hide followRepositoryProvider;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(loginControllerProvider.notifier).logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 My Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/saved-posts'),
            icon: const Icon(Icons.bookmark),
          ),
          IconButton(
            onPressed: () => _handleLogout(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("❌ Error: $e")),
        data: (data) {
          final profile = data['profile'];
          final posts = data['posts'] ?? [];

          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text("You don't have a profile yet."),
                  ElevatedButton(
                    onPressed: () => context.go('/edit-profile'),
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          final avatarUrl = profile.avatarUrl;
          final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: !hasAvatar ? const Icon(Icons.person, size: 50) : null,
                ),
                const SizedBox(height: 10),
                Text(
                  profile.username ?? 'New User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.bio ?? 'No bio added',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),

                // Stats Section
                FutureBuilder<Map<String, int>>(
                  future: ref.read(followRepositoryProvider).getFollowStats(profile.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final stats = snapshot.data!;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('Posts', posts.length.toString()),
                        _buildStat(
                          'Followers',
                          stats['followers'].toString(),
                              () => context.push('/followers/${profile.id}'),
                        ),
                        _buildStat(
                          'Following',
                          stats['following'].toString(),
                              () => context.push('/following/${profile.id}'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 15),

                // Edit Profile Button
                ElevatedButton.icon(
                  onPressed: () => context.go('/edit-profile'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
                const Divider(),

                // Posts Section Header
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '📸 My Posts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // Posts List - FIXED TYPE ISSUE
            posts.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(30),
              child: Text('No posts yet 😔'),
            )
                : Column(
              children: posts.map<Widget>((post) => PostCard(post: post)).toList(),
            ),


              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String count, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}