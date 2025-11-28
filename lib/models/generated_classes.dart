// ignore_for_file: non_constant_identifier_names, camel_case_types, file_names

import 'package:supabase_flutter/supabase_flutter.dart';

// 🔹 Profiles Table Model
class Profiles {
  final String id;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final DateTime? createdAt;
  final int? postCount;

  const Profiles({
    required this.id,
    this.username,
    this.bio,
    this.avatarUrl,
    this.createdAt,
    this.postCount,
  });

  factory Profiles.fromJson(Map<String, dynamic> json) {
    return Profiles(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'New User',
      bio: json['bio']?.toString() ?? 'No bio yet.',
      avatarUrl: json['avatar_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      postCount: json['post_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'bio': bio,
    'avatar_url': avatarUrl,
    'created_at': createdAt?.toIso8601String(),
    'post_count': postCount,
  };
}

// 🔹 Posts Table Model
class Posts {
  final BigInt id;
  final String? userId;
  final String? caption;
  final String? imageUrl;
  final DateTime? createdAt;
  final Profiles? profiles;

  const Posts({
    required this.id,
    this.userId,
    this.caption,
    this.imageUrl,
    this.createdAt,
    this.profiles,
  });

  factory Posts.fromJson(Map<String, dynamic> json) {
    return Posts(
      id: json['id'] != null
          ? BigInt.parse(json['id'].toString())
          : BigInt.zero,
      userId: json['user_id']?.toString(),
      caption: json['caption']?.toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      profiles: json['profiles'] != null
          ? Profiles.fromJson(json['profiles'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.toString(),
    'user_id': userId,
    'caption': caption,
    'image_url': imageUrl,
    'created_at': createdAt?.toIso8601String(),
  };
}

// 🔹 Comments Model
class Comments {
  final BigInt id;
  final String? postId;
  final String? userId;
  final String? commentText;
  final DateTime? createdAt;
  final Profiles? profiles;

  const Comments({
    required this.id,
    this.postId,
    this.userId,
    this.commentText,
    this.createdAt,
    this.profiles,
  });

  factory Comments.fromJson(Map<String, dynamic> json) {
    return Comments(
      id: json['id'] != null
          ? BigInt.parse(json['id'].toString())
          : BigInt.zero,
      postId: json['post_id']?.toString(),
      userId: json['user_id']?.toString(),
      commentText: json['comment_text']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      profiles: json['profiles'] != null
          ? Profiles.fromJson(json['profiles'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.toString(),
    'post_id': postId,
    'user_id': userId,
    'comment_text': commentText,
    'created_at': createdAt?.toIso8601String(),
  };
}

// 🔹 Saved Posts Model
class SavedPosts {
  final BigInt id;
  final String? userId;
  final String? postId;
  final DateTime? createdAt;
  final Posts? post;

  const SavedPosts({
    required this.id,
    this.userId,
    this.postId,
    this.createdAt,
    this.post,
  });

  factory SavedPosts.fromJson(Map<String, dynamic> json) {
    return SavedPosts(
      id: json['id'] != null
          ? BigInt.parse(json['id'].toString())
          : BigInt.zero,
      userId: json['user_id']?.toString(),
      postId: json['post_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      post: json['posts'] != null ? Posts.fromJson(json['posts']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.toString(),
    'user_id': userId,
    'post_id': postId,
    'created_at': createdAt?.toIso8601String(),
  };
}

// 🔹 Conversation Model
class Conversation {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatMessage? lastMessage;
  final Profiles? otherUser;

  const Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.otherUser,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      user1Id: json['user1_id']?.toString() ?? '',
      user2Id: json['user2_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      otherUser: json['other_user'] != null
          ? Profiles.fromJson(json['other_user'])
          : null,
    );
  }
}

class Story {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? username;
  final String? avatarUrl;
  final int viewCount;
  final bool hasViewed;

  Story({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.username,
    this.avatarUrl,
    this.viewCount = 0,
    this.hasViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      userId: json['user_id'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      username: json['profiles']?['username'],
      avatarUrl: json['profiles']?['avatar_url'],
      viewCount: json['view_count'] ?? 0,
      hasViewed: json['has_viewed'] ?? false,
    );
  }
}

// 🔹 Chat Message Model
class ChatMessage {
  final BigInt id;
  final String conversationId;
  final String senderId;
  final String? messageText;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;
  final Profiles? sender;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.messageText,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] != null
          ? BigInt.parse(json['id'].toString())
          : BigInt.zero,
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      messageText: json['message_text']?.toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      sender: json['sender'] != null
          ? Profiles.fromJson(json['sender'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.toString(),
    'conversation_id': conversationId,
    'sender_id': senderId,
    'message_text': messageText,
    'image_url': imageUrl,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
  };
}

// Supabase Client Extension
extension SupabaseTables on SupabaseClient {
  SupabaseQueryBuilder get profiles => from('profiles');
  SupabaseQueryBuilder get posts => from('posts');
  SupabaseQueryBuilder get comments => from('comments');
  SupabaseQueryBuilder get savedPosts => from('saved_posts');
  SupabaseQueryBuilder get conversations => from('conversations');
  SupabaseQueryBuilder get messages => from('messages');
}