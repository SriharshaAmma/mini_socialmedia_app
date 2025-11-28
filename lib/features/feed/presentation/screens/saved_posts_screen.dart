import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/saved_posts_repository.dart';

class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPostsAsync = ref.watch(savedPostsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💾 Saved Posts'),
      ),
      body: savedPostsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (savedPosts) {
          if (savedPosts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No saved posts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: savedPosts.length,
            itemBuilder: (context, index) {
              final saved = savedPosts[index];
              final post = saved['posts'];
              final imageUrl = post['image_url'];

              return GestureDetector(
                onTap: () {
                  // Navigate to post detail or show dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (imageUrl != null)
                            Image.network(imageUrl, fit: BoxFit.cover),
                          const SizedBox(height: 10),
                          Text(post['caption'] ?? 'No caption'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(savedPostsRepositoryProvider.notifier)
                                .unsavePost(post['id'].toString());
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text(
                            'Unsave',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      ),
                    // Bookmark indicator
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.bookmark,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 3,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}