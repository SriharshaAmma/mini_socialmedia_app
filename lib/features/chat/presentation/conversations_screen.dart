import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final _client = Supabase.instance.client;
  List<dynamic> conversations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final data = await _client
          .from('conversations')
          .select('*')
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
          .order('updated_at', ascending: false);

      final List<dynamic> enriched = [];
      for (var conv in data) {
        final otherUserId = conv['user1_id'] == user.id
            ? conv['user2_id']
            : conv['user1_id'];

        final otherUser = await _client
            .from('profiles')
            .select('*')
            .eq('id', otherUserId)
            .single();

        final lastMsg = await _client
            .from('messages')
            .select('*')
            .eq('conversation_id', conv['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        enriched.add({
          ...conv,
          'other_user': otherUser,
          'last_message': lastMsg,
        });
      }

      setState(() {
        conversations = enriched;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.black),
            onPressed: () => context.push('/users-list'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with someone',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/users-list'),
              icon: const Icon(Icons.add),
              label: const Text('New Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadConversations,
        child: ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conv = conversations[index];
            final otherUser = conv['other_user'];
            final lastMessage = conv['last_message'];
            final username = otherUser['username'] ?? 'Unknown';
            final avatarUrl = otherUser['avatar_url'];
            final updatedAt = DateTime.parse(conv['updated_at']);

            String preview = 'Start chatting';
            if (lastMessage != null) {
              if (lastMessage['image_url'] != null) {
                preview = '📷 Photo';
              } else if (lastMessage['message_text'] != null) {
                preview = lastMessage['message_text'];
              }
            }

            return InkWell(
              onTap: () {
                context.push('/chat/${otherUser['id']}', extra: {
                  'username': username,
                  'avatarUrl': avatarUrl,
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: avatarUrl != null &&
                              avatarUrl.toString().isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null ||
                              avatarUrl.toString().isEmpty
                              ? Text(
                            username[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                          backgroundColor: Colors.deepPurple.shade100,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(updatedAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}