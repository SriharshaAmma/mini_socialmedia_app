import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../feed/data/feed_repository.dart';
import '../data/post_repository.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  File? selectedImage;
  final captionCtrl = TextEditingController();
  bool loading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> uploadPost() async {
    if (selectedImage == null) return;

    setState(() => loading = true);
    final repo = ref.read(postRepositoryProvider.notifier);

    try {
      // 🚀 Upload image first
      final imageUrl = await repo.uploadImage(selectedImage!);

      // 💾 Then save post
      await repo.createPost(captionCtrl.text.trim(), imageUrl);

      // ♻ Auto refresh feed
      ref.invalidate(feedRepositoryProvider);

      if (mounted) {
        context.go('/feed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Post uploaded successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Image Preview
            GestureDetector(
              onTap: pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: selectedImage != null
                    ? Image.file(selectedImage!, height: 250, width: double.infinity, fit: BoxFit.cover)
                    : Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Tap to select an image', style: TextStyle(color: Colors.black54)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ✏️ Caption Input
            TextField(
              controller: captionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Write a caption...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 15),

            // 🔘 Post Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : uploadPost,
                icon: loading
                    ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Icon(Icons.cloud_upload),
                label: Text(loading ? 'Uploading...' : 'Post'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
