import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/friend_provider.dart';
import '../profile/public_profile_screen.dart';
import 'chat_screen.dart';
import 'user_search_delegate.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().loadFriends();
      context.read<FriendProvider>().loadPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = context.watch<FriendProvider>();
    final friends = friendProvider.friends;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            readOnly: true,
            onTap: () => showSearch(context: context, delegate: UserSearchDelegate()),
            decoration: InputDecoration(
              hintText: 'Search for users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primaryTeal),
                onPressed: () => showSearch(context: context, delegate: UserSearchDelegate()),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              if (friendProvider.pendingRequests.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Friend Requests',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMedium),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final request = friendProvider.pendingRequests[index];
                      return _buildRequestTile(request);
                    },
                    childCount: friendProvider.pendingRequests.length,
                  ),
                ),
                const SliverToBoxAdapter(child: Divider(height: 32)),
              ],
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Your Friends',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMedium),
                  ),
                ),
              ),
              if (friends.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildFriendTile(friends[index]);
                    },
                    childCount: friends.length,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // TODO: Open search
            },
            child: const Text('Find friends'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(dynamic request) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PublicProfileScreen(userId: request.senderId)),
        ),
        child: CircleAvatar(
          backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
          child: Text(
            request.senderUsername.isNotEmpty ? request.senderUsername[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: Text(request.senderDisplayName ?? request.senderUsername),
      subtitle: const Text('wants to be your friend'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => context.read<FriendProvider>().acceptFriendRequest(request.id),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => context.read<FriendProvider>().rejectFriendRequest(request.id),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(dynamic friend) {
    // Assuming friend is a FriendModel-like object from FriendProvider
    final username = friend.friendUsername;
    final displayName = friend.friendDisplayName;
    final userId = friend.friendId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicProfileScreen(
                  userId: userId,
                ),
              ),
            );
          },
          child: CircleAvatar(
            backgroundColor: AppColors.primaryTeal,
            child: Text(username[0].toUpperCase()),
          ),
        ),
        title: Text(displayName ?? username),
        subtitle: const Text(
          'Active learner', // Could be real status if available
          style: TextStyle(color: AppColors.textMedium),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.message, color: AppColors.primaryTeal),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      userName: displayName ?? username,
                      userId: userId,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show options (unfriend, block)
              },
            ),
          ],
        ),
      ),
    );
  }
}
