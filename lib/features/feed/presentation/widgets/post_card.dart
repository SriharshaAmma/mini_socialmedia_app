import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:socialmedia_app/models/generated_classes.dart';

class PostCard extends StatefulWidget {
  final Posts post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;
  bool isSaved = false;

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    final post = widget.post;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 User Info
          ListTile(
            leading: GestureDetector(
              onTap: () => context.push('/user/${post.userId}'), // 🔥 FIXED
              child: CircleAvatar(
                backgroundImage: post.profiles?.avatarUrl != null
                    ? NetworkImage(post.profiles!.avatarUrl!)
                    : null,
                child: post.profiles?.avatarUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            title: GestureDetector(
              onTap: () => context.push('/user/${post.userId}'), // 🔥 FIXED
              child: Text(
                post.profiles?.username ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(_formatTimestamp(post.createdAt)),
            trailing: const Icon(Icons.more_vert),
          ),

          // 🖼 Post Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              post.imageUrl ?? '',
              fit: BoxFit.cover,
              height: 280,
              width: double.infinity,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 120),
            ),
          ),

          const SizedBox(height: 8),

          // ❤️ Like, 💬 Comment, 📤 Share, 🔖 Save
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // ❤️ Like Button
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                    size: 28,
                  ),
                  onPressed: () async {
                    if (userId == null) return;
                    setState(() => isLiked = !isLiked);
                    await client.from('likes').insert({
                      'post_id': post.id.toInt(),
                      'user_id': userId,
                    });
                  },
                ),

                // 💬 Comment Button
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 28),
                  onPressed: () => context.push('/comments/${post.id}'),
                ),

                // 📤 Share Button
                IconButton(
                  icon: const Icon(Icons.send, size: 28),
                  onPressed: () {
                    Share.share(
                      "Check out this post: ${post.imageUrl ?? ''}",
                    );
                  },
                ),

                const Spacer(),

                // 🔖 Save Button
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 28,
                  ),
                  onPressed: () async {
                    if (userId == null) return;
                    setState(() => isSaved = !isSaved);
                    await client.from('saved_posts').insert({
                      'post_id': post.id.toInt(),
                      'user_id': userId,
                    });
                  },
                ),
              ],
            ),
          ),

          // 📄 Caption
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 15, top: 5),
            child: Text(
              post.caption ?? '',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  /// 🕒 Format timestamp
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
