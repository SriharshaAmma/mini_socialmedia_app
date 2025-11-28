import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String username;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.username,
    this.avatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _client = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? conversationId;
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sendingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Get or create conversation
      final convId = await _client.rpc(
        'get_or_create_conversation',
        params: {'other_user_id': widget.otherUserId},
      );

      setState(() => conversationId = convId.toString());

      // Subscribe to real-time messages
      _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', convId.toString())
          .order('created_at')
          .listen((data) {
        if (mounted) {
          setState(() {
            messages = data.map((e) => e as Map<String, dynamic>).toList();
            loading = false;
          });
          _scrollToBottom();
        }
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || conversationId == null) return;

    _messageController.clear();

    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _client.auth.currentUser!.id,
        'message_text': text,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendImage() async {
    if (conversationId == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => sendingImage = true);

    try {
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _client.storage.from('chat-images').upload(
        'public/$fileName',
        file,
        fileOptions: FileOptions(upsert: true),
      );

      final imageUrl = _client.storage
          .from('chat-images')
          .getPublicUrl('public/$fileName');

      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _client.auth.currentUser!.id,
        'image_url': imageUrl,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => sendingImage = false);
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isMe = message['sender_id'] == _client.auth.currentUser?.id;
    final messageText = message['message_text'];
    final imageUrl = message['image_url'];
    final timestamp = DateTime.parse(message['created_at']);
    final timeString = DateFormat('HH:mm').format(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.avatarUrl != null &&
                  widget.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(widget.username[0].toUpperCase())
                  : null,
              backgroundColor: Colors.deepPurple.shade100,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.deepPurple
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                    if (messageText != null) const SizedBox(height: 8),
                  ],
                  if (messageText != null)
                    Text(
                      messageText,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.avatarUrl != null &&
                  widget.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(
                widget.username[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
                  : null,
              backgroundColor: Colors.deepPurple.shade100,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Active now',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.waving_hand,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Say hi to ${widget.username}! 👋',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),

          if (sendingImage)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Sending image...'),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.image_rounded,
                      color: Colors.deepPurple.shade400,
                    ),
                    onPressed: sendingImage ? null : _sendImage,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sendMessage,
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}