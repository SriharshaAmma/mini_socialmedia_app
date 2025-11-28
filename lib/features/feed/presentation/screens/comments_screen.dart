import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController commentCtrl = TextEditingController();
  final client = Supabase.instance.client;
  List<dynamic> comments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _subscribeToComments();
  }

  // Load comments with JOIN to profiles
  Future<void> _loadComments() async {
    try {
      // First get comments
      final commentData = await client
          .from('comments')
          .select('*')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false);

      // Then get profile data for each comment
      final List<dynamic> enrichedComments = [];
      for (var comment in commentData) {
        final userId = comment['user_id'];

        // Fetch profile for this user
        final profile = await client
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', userId)
            .maybeSingle();

        enrichedComments.add({
          ...comment,
          'profile': profile ?? {'username': 'Unknown', 'avatar_url': null},
        });
      }

      setState(() {
        comments = enrichedComments;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    }
  }

  // Real-time subscription
  void _subscribeToComments() {
    client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', widget.postId)
        .order('created_at', ascending: false)
        .listen((data) async {
      if (!mounted) return;

      // Enrich with profile data
      final List<dynamic> enrichedComments = [];
      for (var comment in data) {
        final userId = comment['user_id'];

        final profile = await client
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', userId)
            .maybeSingle();

        enrichedComments.add({
          ...comment,
          'profile': profile ?? {'username': 'Unknown', 'avatar_url': null},
        });
      }

      if (mounted) {
        setState(() => comments = enrichedComments);
      }
    });
  }

  // Send comment
  Future<void> sendComment() async {
    if (commentCtrl.text.trim().isEmpty) return;

    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to comment')),
      );
      return;
    }

    try {
      await client.from('comments').insert({
        'post_id': int.parse(widget.postId),
        'user_id': user.id,
        'comment_text': commentCtrl.text.trim(),
      });

      commentCtrl.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Comments'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Comments List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No comments yet.\nBe the first to comment!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final comment = comments[i];
                final profile = comment['profile'];
                final username = profile['username'] ?? 'Unknown';
                final avatarUrl = profile['avatar_url'];
                final isMyComment = comment['user_id'] ==
                    client.auth.currentUser?.id;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: avatarUrl != null &&
                        avatarUrl.toString().isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null ||
                        avatarUrl.toString().isEmpty
                        ? Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                    backgroundColor: Colors.deepPurple.shade100,
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      comment['comment_text'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  trailing: isMyComment
                      ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Comment'),
                          content: const Text(
                              'Are you sure you want to delete this comment?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await client
                            .from('comments')
                            .delete()
                            .eq('id', comment['id']);
                      }
                    },
                  )
                      : null,
                );
              },
            ),
          ),

          // Comment Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: sendComment,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }
}