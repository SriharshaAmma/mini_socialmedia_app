import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final usernameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  File? pickedImage;
  bool _initialized = false;
  bool _isSaving = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => pickedImage = File(img.path));
  }

  Future<void> saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      String? avatarUrl;

      if (pickedImage != null) {
        final fileExt = pickedImage!.path.split('.').last;
        final fileName = '${user.id}.$fileExt';

        await client.storage.from('avatars').upload(
          'public/$fileName',
          pickedImage!,
          fileOptions: FileOptions(upsert: true),
        );

        avatarUrl = client.storage.from('avatars').getPublicUrl('public/$fileName');
      }

      final existingProfile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        await client.from('profiles').insert({
          'id': user.id,
          'username': usernameCtrl.text.trim().isEmpty
              ? 'User${user.id.substring(0, 6)}'
              : usernameCtrl.text.trim(),
          'bio': bioCtrl.text.trim().isEmpty
              ? 'Hey there! I am using Mini Social App.'
              : bioCtrl.text.trim(),
          'avatar_url': avatarUrl,
        });
      } else {
        await client.from('profiles').update({
          'username': usernameCtrl.text.trim(),
          'bio': bioCtrl.text.trim(),
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }).eq('id', user.id);
      }

      ref.invalidate(profileRepositoryProvider);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile saved successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/profile');
          },
        ),
      ),
      body: profileAsync.when(
        data: (data) {
          final profile = data['profile'];

          if (!_initialized) {
            usernameCtrl.text = profile?.username ?? '';
            bioCtrl.text = profile?.bio ?? '';
            _initialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isSaving ? null : pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: pickedImage != null
                            ? FileImage(pickedImage!)
                            : (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                            ? NetworkImage(profile.avatarUrl!)
                            : null) as ImageProvider?,
                        child: pickedImage == null &&
                            (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: usernameCtrl,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioCtrl,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      profile == null ? "Create Profile" : "Save Changes",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Error: $e"),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(profileRepositoryProvider);
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }
}