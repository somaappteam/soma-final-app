import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../profile/public_profile_screen.dart';
import '../../providers/message_provider.dart';
import '../../models/message_model.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        if (messageProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messageProvider.error != null) {
          return Center(
            child: Text(
              'Error loading conversations:\n${messageProvider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final conversations = messageProvider.conversations;

        if (conversations.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet. Start a conversation\nwith your friends!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMedium),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final otherUser = conversation.otherUser;
            final lastMessage = conversation.lastMessage;
            final hasUnread = conversation.unreadCount > 0;

            if (otherUser == null) return const SizedBox.shrink();

            return _buildConversationTile(
              context,
              otherUser: otherUser,
              lastMessage: lastMessage?.content ?? 'Started a conversation',
              lastActiveAt: conversation.updatedAt,
              hasUnread: hasUnread,
              unreadCount: conversation.unreadCount,
            );
          },
        );
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context, {
    required UserInfo otherUser,
    required String lastMessage,
    required DateTime lastActiveAt,
    required bool hasUnread,
    required int unreadCount,
  }) {
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt);
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userName: otherUser.displayName ?? otherUser.username,
                userId: otherUser.id,
              ),
            ),
          );
        },
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicProfileScreen(
                  userId: otherUser.id,
                ),
              ),
            );
          },
          child: Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryTeal,
                backgroundImage: otherUser.avatarUrl != null
                    ? NetworkImage(otherUser.avatarUrl!)
                    : null,
                child: otherUser.avatarUrl == null
                    ? Text(otherUser.username.isNotEmpty ? otherUser.username.substring(0, 1).toUpperCase() : '?')
                    : null,
              ),
              if (otherUser.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          otherUser.displayName ?? otherUser.username,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeAgo,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accentCoral,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
