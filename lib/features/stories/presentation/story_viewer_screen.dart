import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/generated_classes.dart';
import '../data/story_repository.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final String userId;
  const StoryViewerScreen({super.key, required this.userId});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _progressController;
  List<Story> stories = [];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
    _loadStories();
  }

  Future<void> _loadStories() async {
    final repo = ref.read(storyRepositoryProvider.notifier);
    stories = await repo.getUserStories(widget.userId);
    if (stories.isNotEmpty) {
      _markViewed();
      _progressController.forward();
    }
    setState(() {});
  }

  void _markViewed() {
    if (stories.isNotEmpty) {
      ref.read(storyRepositoryProvider.notifier)
          .markAsViewed(stories[currentIndex].id);
    }
  }

  void _nextStory() {
    if (currentIndex < stories.length - 1) {
      setState(() => currentIndex++);
      _progressController.reset();
      _progressController.forward();
      _markViewed();
    } else {
      context.pop();
    }
  }

  void _prevStory() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final story = stories[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final third = MediaQuery.of(context).size.width / 3;
          if (details.globalPosition.dx < third) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Image
            Image.network(story.imageUrl, fit: BoxFit.contain),

            // Progress bars at top
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: List.generate(
                        stories.length,
                            (index) => Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: index < currentIndex
                                ? Container(color: Colors.white)
                                : index == currentIndex
                                ? AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return LinearProgressIndicator(
                                  value: _progressController.value,
                                  backgroundColor: Colors.white30,
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                );
                              },
                            )
                                : Container(color: Colors.white30),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // User info
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: story.avatarUrl != null
                          ? NetworkImage(story.avatarUrl!)
                          : null,
                      child: story.avatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      story.username ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _formatTime(story.createdAt),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}