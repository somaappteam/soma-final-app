import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../social/chat_screen.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';

enum FriendRelationship { none, friend, pendingSent, pendingReceived, blocked }

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UserService _userService = UserService();
  final CourseService _courseService = CourseService();
  UserModel? _user;
  UserStats? _stats;
  CourseModel? _activeCourse;
  // Removed _relationship and _requestId as they are now calculated in build
  bool _isLoading = true;
  bool _isError = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final user = await _userService.getUserById(widget.userId);
      final stats = await _userService.getUserStats(widget.userId);
      CourseModel? activeCourse;
      try {
        activeCourse = await _courseService.getUserActiveCourse(widget.userId);
      } catch (e) {
        debugPrint('Error loading course: $e');
      }
      
      if (mounted) {
        setState(() {
          _user = user;
          _stats = stats;
          _activeCourse = activeCourse;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    }
  }

  // Helper to get relationship and request ID reactively
  (FriendRelationship, String?) _getRelationshipInfo() {
    final friendProvider = context.watch<FriendProvider>();
    
    // Check if friends
    if (friendProvider.friends.any((f) => f.friendId == widget.userId)) {
      return (FriendRelationship.friend, null);
    }

    // Check if received request
    final received = friendProvider.pendingRequests.where((r) => r.senderId == widget.userId);
    if (received.isNotEmpty) {
      return (FriendRelationship.pendingReceived, received.first.id);
    }

    // Check if sent request
    final sent = friendProvider.sentRequests.where((r) => r.receiverId == widget.userId);
    if (sent.isNotEmpty) {
      return (FriendRelationship.pendingSent, sent.first.id);
    }

    // Check if blocked
    if (friendProvider.blockedUsers.any((u) => u.blockedId == widget.userId)) {
      return (FriendRelationship.blocked, null);
    }

    return (FriendRelationship.none, null);
  }

  void _sendFriendRequest() async {
    setState(() => _isActionLoading = true);
    try {
      await context.read<FriendProvider>().sendFriendRequest(receiverId: widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _acceptFriendRequest(String requestId) async {
    setState(() => _isActionLoading = true);
    try {
      await context.read<FriendProvider>().acceptFriendRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _rejectFriendRequest(String requestId) async {
    setState(() => _isActionLoading = true);
    try {
      await context.read<FriendProvider>().rejectFriendRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _cancelFriendRequest(String requestId) async {
    setState(() => _isActionLoading = true);
    try {
      await context.read<FriendProvider>().cancelFriendRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request canceled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _removeFriend() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${_user?.username ?? 'this user'} from your friends?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await context.read<FriendProvider>().removeFriend(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove friend: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _blockUser() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${_user?.username ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<FriendProvider>().blockUser(blockedId: widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User blocked')),
          );
          Navigator.pop(context); // Go back after blocking
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to block user: $e')),
          );
        }
      }
    }
  }

  void _reportUser() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for reporting...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              
              Navigator.pop(context); // close dialog immediately

              try {
                await _userService.reportUser(widget.userId, reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted. Thank you.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error submitting report: $e')),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Could not load user profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final currentUser = context.watch<AuthProvider>().currentUser;
    final isSelf = currentUser?.id == widget.userId;
    final (relationship, requestId) = _getRelationshipInfo();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(_user!),
            ),
            actions: [
              if (!isSelf)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'report') {
                      _reportUser();
                    } else if (value == 'block') {
                      _blockUser();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, size: 20),
                          SizedBox(width: 8),
                          Text('Report User'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Block User', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSelf) _buildActionButtons(relationship, requestId),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildLanguagesSection(_user!),
                  const SizedBox(height: 24),
                  if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                    _buildBioSection(_user!.bio!),
                    const SizedBox(height: 24),
                  ],
                  if (_user!.achievements != null && _user!.achievements!.isNotEmpty)
                    _buildAchievementsSection(_user!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.tealGradient,
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'avatar_${user.id}',
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? user.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (user.displayName != null && user.displayName != user.username) ...[
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.country != null) ...[
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    user.country!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                ],
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Level ${user.currentLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_activeCourse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_activeCourse!.targetLanguageFlag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Learning ${_activeCourse!.targetLanguageName}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
    );
  }

  Widget _buildActionButtons(FriendRelationship relationship, String? requestId) {
    if (_isActionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget primaryButton;
    Widget? secondaryButton;

    switch (relationship) {
      case FriendRelationship.friend:
        primaryButton = _buildButton(
          label: 'Unfriend',
          icon: Icons.person_remove,
          onPressed: _removeFriend,
          isOutlined: true,
          color: Colors.red,
        );
        secondaryButton = _buildButton(
          label: 'Message',
          icon: Icons.message,
          onPressed: _navigateToChat,
          color: AppColors.primaryTeal,
        );
        break;
      case FriendRelationship.pendingSent:
        primaryButton = _buildButton(
          label: 'Request Sent',
          icon: Icons.hourglass_empty,
          onPressed: requestId != null ? () => _cancelFriendRequest(requestId) : null,
          isOutlined: true,
          color: Colors.grey,
        );
        secondaryButton = _buildButton(
          label: 'Message',
          icon: Icons.message,
          onPressed: _navigateToChat,
          color: AppColors.primaryTeal,
        );
        break;
      case FriendRelationship.pendingReceived:
        primaryButton = _buildButton(
          label: 'Accept',
          icon: Icons.check,
          onPressed: requestId != null ? () => _acceptFriendRequest(requestId) : null,
          color: AppColors.primaryTeal,
        );
        secondaryButton = _buildButton(
          label: 'Reject',
          icon: Icons.close,
          onPressed: requestId != null ? () => _rejectFriendRequest(requestId) : null,
          isOutlined: true,
          color: Colors.red,
        );
        break;
      case FriendRelationship.blocked:
        primaryButton = _buildButton(
          label: 'Blocked',
          icon: Icons.block,
          onPressed: null,
          color: Colors.grey,
        );
        break;
      default:
        primaryButton = _buildButton(
          label: 'Add Friend',
          icon: Icons.person_add,
          onPressed: _sendFriendRequest,
          color: AppColors.primaryTeal,
        );
        secondaryButton = _buildButton(
          label: 'Message',
          icon: Icons.message,
          onPressed: _navigateToChat,
          isOutlined: true,
          color: AppColors.primaryTeal,
        );
    }

    return Row(
      children: [
        Expanded(child: primaryButton),
        if (secondaryButton != null) ...[
          const SizedBox(width: 12),
          Expanded(child: secondaryButton),
        ],
      ],
    ).animate().slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400));
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isOutlined = false,
    Color color = AppColors.primaryTeal,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToChat() {
    if (_user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userName: _user!.displayName ?? _user!.username,
            userId: _user!.id,
          ),
        ),
      );
    }
  }

  Widget _buildStatsSection() {
    final stats = [
      {
        'label': 'Total XP',
        'value': _stats?.totalXP.toString() ?? _user?.totalXP.toString() ?? '0',
        'icon': Icons.star
      },
      {
        'label': 'Streak',
        'value': _stats?.streakDays.toString() ?? _user?.streakDays.toString() ?? '0',
        'icon': Icons.local_fire_department
      },
      {
        'label': 'Games Won',
        'value': _stats?.totalGamesWon.toString() ?? _user?.totalGamesWon.toString() ?? '0',
        'icon': Icons.emoji_events
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.map((stat) => _buildStatItem(stat)).toList(),
    ).animate().fadeIn(delay: const Duration(milliseconds: 200));
  }

  Widget _buildStatItem(Map<String, dynamic> stat) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(stat['icon'] as IconData, color: AppColors.primaryTeal),
        ),
        const SizedBox(height: 8),
        Text(
          stat['value'] as String,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          stat['label'] as String,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Languages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Text('🗣️'), // Could replace with flag emoji based on language code
              label: Text('Speaks ${user.nativeLanguage}'),
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              labelStyle: const TextStyle(color: Colors.blue),
            ),
            ...user.learningLanguages.map((lang) => Chip(
              avatar: const Text('📚'),
              label: Text('Learning $lang'),
              backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
              labelStyle: const TextStyle(color: AppColors.primaryTeal),
            )),
          ],
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 300));
  }

  Widget _buildBioSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bio,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 400));
  }

  Widget _buildAchievementsSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: user.achievements!.length,
            itemBuilder: (context, index) {
              final achievement = user.achievements![index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      achievement,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 500));
  }
}

