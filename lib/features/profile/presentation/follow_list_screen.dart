import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../stories/data/follow_repository.dart'; // 👈 Make sure this path is correct

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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '❌ Error: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
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
