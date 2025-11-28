import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🔐 Auth Screens
import 'features/auth/presentation/login_screen.dart';

// 🏠 Feed & Posts
import 'features/chat/presentation/chat_sreen.dart';
import 'features/feed/presentation/create_post_screen.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'features/feed/presentation/screens/saved_posts_screen.dart';
import 'features/feed/presentation/screens/comments_screen.dart';

// 👤 Profile
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'features/profile/presentation/public_profile_screen.dart';
import 'features/profile/presentation/follow_list_screen.dart';

// 📖 Stories
import 'features/stories/presentation/create_story_screen.dart';
import 'features/stories/presentation/story_viewer_screen.dart';

// 💬 Chat
import 'features/chat/presentation/conversations_screen.dart';
import 'features/chat/presentation/user_list_screen.dart';

/// PROVIDER — Global Router
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',

    // 🔐 Auth redirect logic
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final loggingIn = state.matchedLocation == '/login';

      if (user == null && !loggingIn) return '/login';
      if (user != null && loggingIn) return '/feed';
      return null;
    },

    routes: [
      // 🔹 Authentication Routes (no bottom nav)
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // 🔸 Main App Layout with Bottom Navigation
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/create-post', builder: (_, __) => const CreatePostScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()), // 👤 Own profile
          GoRoute(path: '/users-list', builder: (_, __) => const UsersListScreen()),
          GoRoute(path: '/conversations', builder: (_, __) => const ConversationsScreen()),
          GoRoute(path: '/saved-posts', builder: (_, __) => const SavedPostsScreen()),

          // 👥 Followers List
          GoRoute(
            path: '/followers/:userId',
            builder: (context, state) => FollowListScreen(
              userId: state.pathParameters['userId']!,
              showFollowers: true,
            ),
          ),

          // 👥 Following List
          GoRoute(
            path: '/following/:userId',
            builder: (context, state) => FollowListScreen(
              userId: state.pathParameters['userId']!,
              showFollowers: false,
            ),
          ),

          // 👤 Public Profile — OTHER users
          GoRoute(
            path: '/user/:userId',
            builder: (_, state) => PublicProfileScreen(
              userId: state.pathParameters['userId']!,
            ),
          ),

          // 💬 Comments Screen
          GoRoute(
            path: '/comments/:postId',
            builder: (_, state) => CommentsScreen(
              postId: state.pathParameters['postId']!,
            ),
          ),

          // 📖 Story Viewer
          GoRoute(
            path: '/story/:userId',
            builder: (_, state) => StoryViewerScreen(
              userId: state.pathParameters['userId']!,
            ),
          ),
        ],
      ),

      // ✏️ Edit Profile (full screen)
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),

      // 📤 Create Story (full screen)
      GoRoute(path: '/create-story', builder: (_, __) => const CreateStoryScreen()),

      // 💬 Chat Screen (full screen, no bottom nav)
      GoRoute(
        path: '/chat/:userId',
        builder: (_, state) {
          final userId = state.pathParameters['userId']!;
          final extra = state.extra as Map<String, dynamic>?;

          return ChatScreen(
            otherUserId: userId,
            username: extra?['username'] ?? 'User',
            avatarUrl: extra?['avatarUrl'],
          );
        },
      ),
    ],

    // 🔴 Error Route Handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/feed'),
              child: const Text('Go to Feed'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// 🎯 Bottom Navigation Wrapper (Shell)
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/feed');
              break;
            case 1:
              context.go('/create-post');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.add_box), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/feed')) return 0;
    if (location.startsWith('/create-post')) return 1;
    return 2; // Profile
  }
}
