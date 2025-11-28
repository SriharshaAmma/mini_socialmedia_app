import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'chat_repository.g.dart';

@riverpod
class ChatRepository extends _$ChatRepository {
  final _client = Supabase.instance.client;

  @override
  Future<List<dynamic>> build() async {
    return _loadConversations();
  }

  // Load all conversations for current user
  Future<List<dynamic>> _loadConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('conversations')
        .select('*')
        .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
        .order('updated_at', ascending: false);

    // Enrich with other user's profile and last message
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

    return enriched;
  }

  // Get or create conversation with a user
  Future<String> getOrCreateConversation(String otherUserId) async {
    final result = await _client.rpc('get_or_create_conversation',
        params: {'other_user_id': otherUserId});

    ref.invalidateSelf();
    return result.toString();
  }

  // Send text message
  Future<void> sendMessage(String conversationId, String text) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'message_text': text,
    });
  }

  // Send image message
  Future<void> sendImageMessage(String conversationId, File image) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Upload image
    final fileExt = image.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _client.storage.from('chat-images').upload(
      'public/$fileName',
      image,
      fileOptions: FileOptions(upsert: true),
    );

    final imageUrl = _client.storage
        .from('chat-images')
        .getPublicUrl('public/$fileName');

    // Send message with image
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'image_url': imageUrl,
    });
  }

  // Get messages for a conversation (returns stream)
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((e) => e as Map<String, dynamic>).toList());
  }

  // Mark message as read
  Future<void> markAsRead(BigInt messageId) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('id', messageId.toString());
  }
}