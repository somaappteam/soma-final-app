import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../profile/public_profile_screen.dart';

class UserSearchDelegate extends SearchDelegate<String> {
  final UserService _userService = UserService();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(child: Text('Type at least 2 characters to search...'));
    }

    return FutureBuilder<List<UserModel>>(
      future: _userService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryTeal,
                child: Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.displayName ?? user.username),
              subtitle: Text('@${user.username}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicProfileScreen(
                      userId: user.id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
