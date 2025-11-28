import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _client = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      final data = await _client
          .from('profiles')
          .select('*')
          .neq('id', currentUser.id)
          .order('username');

      setState(() {
        users = data;
        filteredUsers = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final username = user['username']?.toString().toLowerCase() ?? '';
          final bio = user['bio']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return username.contains(searchLower) || bio.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Search Users'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by username or bio...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterUsers('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),

          // Results Count
          if (!loading && _searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                '${filteredUsers.length} ${filteredUsers.length == 1 ? 'user' : 'users'} found',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),

          // Users List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchController.text.isEmpty
                        ? Icons.people_outline
                        : Icons.search_off,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No users available'
                        : 'No users found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Try searching with different keywords',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            )
                : ListView.separated(
              itemCount: filteredUsers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final username = user['username'] ?? 'Unknown';
                final bio = user['bio'] ?? 'No bio';
                final avatarUrl = user['avatar_url'];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: avatarUrl != null &&
                        avatarUrl.toString().isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null ||
                        avatarUrl.toString().isEmpty
                        ? Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                        : null,
                    backgroundColor: Colors.deepPurple.shade100,
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View Profile Button
                      IconButton(
                        icon: Icon(
                          Icons.person_outline,
                          color: Colors.grey.shade600,
                        ),
                        tooltip: 'View Profile',
                        onPressed: () {
                          // Navigate to user profile
                          context.push('/user-profile/${user['id']}');
                        },
                      ),
                      // Chat Button
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.deepPurple,
                        ),
                        tooltip: 'Send Message',
                        onPressed: () {
                          context.push('/chat/${user['id']}', extra: {
                            'username': username,
                            'avatarUrl': avatarUrl,
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}