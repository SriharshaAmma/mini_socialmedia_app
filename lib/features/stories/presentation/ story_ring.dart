import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../models/generated_classes.dart';

class StoryRing extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;

  const StoryRing({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.hasViewed
                    ? null
                    : const LinearGradient(
                  colors: [Colors.purple, Colors.orange, Colors.pink],
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: story.avatarUrl != null
                      ? NetworkImage(story.avatarUrl!)
                      : null,
                  child: story.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                story.username ?? 'User',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}