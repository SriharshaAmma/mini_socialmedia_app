import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../stories/presentation/ story_ring.dart';
import '../data/feed_repository.dart';
import '../../stories/data/story_repository.dart';
import 'widgets/post_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedRepositoryProvider);
    final storiesAsync = ref.watch(storyRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📸 Mini Social',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/users-list'),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/create-story'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/conversations'),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedRepositoryProvider);
          ref.invalidate(storyRepositoryProvider);
        },
        child: CustomScrollView(
          slivers: [
            // 🔹 Stories Section
            SliverToBoxAdapter(
              child: storiesAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (stories) => stories.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return StoryRing(
                        story: story,
                        onTap: () => context.push('/story/${story.userId}'),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Divider(height: 1)),

            // 🔸 Posts Section
            postsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Error loading feed:\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (posts) => posts.isEmpty
                  ? const SliverFillRemaining(
                child: Center(child: Text('No posts yet 👀')),
              )
                  : SliverList.builder(
                itemCount: posts.length,
                itemBuilder: (_, i) => PostCard(post: posts[i]),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
