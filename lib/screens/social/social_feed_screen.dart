import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/friend_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../profile/public_profile_screen.dart';
import 'friends_screen.dart';
import 'chat_screen.dart';
import 'inbox_screen.dart';

/// Premium Social Feed Screen - Activity posts from friends
/// Features: Posts, likes, comments, real-time updates, stories
class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  final SupabaseService _supabase = SupabaseService();
  
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _friends = [];
  int _pendingRequestsCount = 0;
  
  StreamSubscription? _activitySubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadActivities(),
        _loadFriends(),
        _loadPendingRequests(),
      ]);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActivities() async {
    try {
      final userId = _supabase.currentUser?.id;
      if (userId == null) return;

      // Load friend activities from database
      final response = await _supabase.client
          .from('friend_activities')
          .select('*, user: user_id(id, username, avatar_url)')
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _activities = List<Map<String, dynamic>>.from(response);
      });
        } catch (e) {
      // Use sample data for demo
      setState(() {
        _activities = _getSampleActivities();
      });
    }
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendService.getFriends();
      setState(() {
        _friends = friends.map<Map<String, dynamic>>((f) {
          return {
            'id': f.friendId,
            'username': f.friendUsername,
            'display_name': f.friendDisplayName,
            'avatar_url': f.friendAvatarUrl,
            'is_online': true,
          };
        }).toList();
      });
    } catch (e) {
      // Use sample data
      setState(() {
        _friends = _getSampleFriends();
      });
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      final requests = await _friendService.getPendingRequests();
      setState(() {
        _pendingRequestsCount = requests.length;
      });
    } catch (e) {
      // Error handled silently
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to new activities
    _activitySubscription = _supabase.client
        .from('friend_activities')
        .stream(primaryKey: ['id'])
        .listen((data) {
          _loadActivities();
        });
  }

  List<Map<String, dynamic>> _getSampleActivities() {
    return [
      {
        'id': '1',
        'type': 'achievement',
        'content': '🏆 Earned the "Week Warrior" badge!',
        'user': {'id': 'user-1', 'username': 'Sarah', 'avatar_url': null},
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'likes_count': 12,
        'comments_count': 3,
        'is_liked': false,
      },
      {
        'id': '2',
        'type': 'streak',
        'content': '🔥 Just completed a 30-day streak in Spanish!',
        'user': {'id': 'user-2', 'username': 'Mike', 'avatar_url': null},
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'likes_count': 24,
        'comments_count': 7,
        'is_liked': true,
      },
      {
        'id': '3',
        'type': 'game',
        'content': '🎮 Won first place in Word Race! +500 XP',
        'user': {'id': 'user-3', 'username': 'Emma', 'avatar_url': null},
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'likes_count': 8,
        'comments_count': 2,
        'is_liked': false,
      },
      {
        'id': '4',
        'type': 'level_up',
        'content': '📈 Reached Level 25 in French! Très bien!',
        'user': {'id': 'user-4', 'username': 'Alex', 'avatar_url': null},
        'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        'likes_count': 15,
        'comments_count': 4,
        'is_liked': false,
      },
    ];
  }

  List<Map<String, dynamic>> _getSampleFriends() {
    return [
      {'id': '1', 'username': 'Sarah', 'display_name': 'Sarah L.', 'avatar_url': null, 'is_online': true},
      {'id': '2', 'username': 'Mike', 'display_name': 'Mike T.', 'avatar_url': null, 'is_online': true},
      {'id': '3', 'username': 'Emma', 'display_name': 'Emma W.', 'avatar_url': null, 'is_online': false},
      {'id': '4', 'username': 'Alex', 'display_name': 'Alex K.', 'avatar_url': null, 'is_online': true},
      {'id': '5', 'username': 'Lisa', 'display_name': 'Lisa M.', 'avatar_url': null, 'is_online': false},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryTeal,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primaryTeal,
                tabs: [
                  const Tab(text: 'Feed'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Friends'),
                        if (_pendingRequestsCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_pendingRequestsCount',
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
                  const Tab(text: 'Messages'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedTab(),
            _buildFriendsTab(),
            _buildMessagesTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(),
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add),
        label: const Text('Share'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.1),
            AppColors.darkTeal.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Connect with fellow learners',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, color: AppColors.primaryTeal, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${_friends.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stories Row
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _friends.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStoryButton();
                }
                return _buildStoryAvatar(_friends[index - 1]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryTeal, width: 2),
            ),
            child: const Icon(
              Icons.add,
              color: AppColors.primaryTeal,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your Story',
            style: TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryAvatar(Map<String, dynamic> friend) {
    final isOnline = friend['is_online'] ?? false;
    
    return GestureDetector(
      onTap: () {
        if (friend['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProfileScreen(
                userId: friend['id'],
              ),
            ),
          );
        }
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryTeal, AppColors.darkTeal],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: Text(
                        (friend['username'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              friend['display_name'] ?? friend['username'] ?? 'Unknown',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(_activities[index]);
        },
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final user = activity['user'] ?? {};
    final isLiked = activity['is_liked'] ?? false;
    final likesCount = activity['likes_count'] ?? 0;
    final commentsCount = activity['comments_count'] ?? 0;
    final createdAt = DateTime.tryParse(activity['created_at'] ?? '') ?? DateTime.now();
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GestureDetector(
              onTap: () {
                if (user['id'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfileScreen(
                        userId: user['id'],
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryTeal,
                    child: Text(
                      (user['username'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Content
            Text(
              activity['content'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : AppColors.textMedium,
                  count: likesCount,
                  onTap: () => _toggleLike(activity['id']),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: commentsCount,
                  onTap: () => _showComments(activity['id']),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  onTap: () => _shareActivity(activity['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50).ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.textMedium, size: 22),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color ?? AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return const FriendsScreen();
  }

  Widget _buildMessagesTab() {
    return const InboxScreen();
  }

  Widget _buildFriendsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final isOnline = friend['is_online'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () => _openChat(friend),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryTeal,
              child: Text(
                (friend['username'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          friend['display_name'] ?? friend['username'] ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          isOnline ? 'Online' : 'Last seen recently',
          style: TextStyle(
            color: isOnline ? Colors.green : AppColors.textMedium,
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.message, color: AppColors.primaryTeal),
              onPressed: () => _openChat(friend),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showFriendOptions(friend),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _toggleLike(String activityId) {
    HapticFeedback.lightImpact();
    // TODO: Implement like toggle
  }

  void _showComments(String activityId) {
    // TODO: Show comments bottom sheet
  }

  void _shareActivity(String activityId) {
    // TODO: Implement share
  }  void _openChat(Map<String, dynamic> friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userName: friend['username'] ?? 'Unknown',
          userId: friend['id'] ?? 'unknown',
        ),
      ),
    );
  }

  void _showFriendOptions(Map<String, dynamic> friend) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicProfileScreen(
                      userId: friend['id'],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.gamepad),
              title: const Text('Invite to Game'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show game invite
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation(friend);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User?'),
        content: Text('Are you sure you want to block ${friend['username']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement block
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Share Your Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('Post creation coming soon!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
