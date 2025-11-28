import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../data/story_repository.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  File? selectedImage;
  bool loading = false;

  Future<void> pickAndUpload() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      selectedImage = File(pickedFile.path);
      loading = true;
    });

    try {
      final repo = ref.read(storyRepositoryProvider.notifier);
      final imageUrl = await repo.uploadStoryImage(selectedImage!);
      await repo.createStory(imageUrl);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Story uploaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Story')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  selectedImage!,
                  height: 400,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(Icons.photo_library, size: 100, color: Colors.grey),

            const SizedBox(height: 30),

            if (loading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: pickAndUpload,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Select & Upload Story'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}