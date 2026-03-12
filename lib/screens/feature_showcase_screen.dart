import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/study_models.dart';
import '../theme/app_theme.dart';

/// Comprehensive Feature Showcase Screen
/// Demonstrates: Study Reminders, Story Mode, Community, Analytics, AI Tutor
class FeatureShowcaseScreen extends StatefulWidget {
  const FeatureShowcaseScreen({super.key});

  @override
  State<FeatureShowcaseScreen> createState() => _FeatureShowcaseScreenState();
}

class _FeatureShowcaseScreenState extends State<FeatureShowcaseScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  
  // Demo data
  late PomodoroSession _demoPomodoro;
  Duration _pomodoroRemaining = const Duration(minutes: 25);
  bool _isPomodoroRunning = false;

  @override
  void initState() {
    super.initState();
    _demoPomodoro = PomodoroSession(
      id: 'demo',
      userId: 'demo_user',
      startTime: DateTime.now(),
      workDuration: 25,
      breakDuration: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Features Showcase',
          style: TextStyle(color: AppColors.textDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildCurrentTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      {'icon': Icons.access_time, 'label': 'Schedule'},
      {'icon': Icons.menu_book, 'label': 'Stories'},
      {'icon': Icons.people, 'label': 'Community'},
      {'icon': Icons.analytics, 'label': 'Analytics'},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _currentTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      color: isSelected ? Colors.white : AppColors.textMedium,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textMedium,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return _buildScheduleTab();
      case 1:
        return _buildStoriesTab();
      case 2:
        return _buildCommunityTab();
      case 3:
        return _buildAnalyticsTab();
      default:
        return _buildScheduleTab();
    }
  }

  // ==================== SCHEDULE TAB ====================

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPomodoroCard(),
          const SizedBox(height: 20),
          _buildRemindersCard(),
          const SizedBox(height: 20),
          _buildUpcomingSessionsCard(),
        ],
      ),
    );
  }

  Widget _buildPomodoroCard() {
    final minutes = _pomodoroRemaining.inMinutes;
    final seconds = _pomodoroRemaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Pomodoro Timer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPomodoroRunning ? 'Focus Time' : 'Ready to Start',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPomodoroButton(
                icon: _isPomodoroRunning ? Icons.pause : Icons.play_arrow,
                label: _isPomodoroRunning ? 'Pause' : 'Start',
                onTap: _togglePomodoro,
              ),
              const SizedBox(width: 16),
              _buildPomodoroButton(
                icon: Icons.stop,
                label: 'Stop',
                onTap: _stopPomodoro,
                isSecondary: true,
              ),
              const SizedBox(width: 16),
              _buildPomodoroButton(
                icon: Icons.skip_next,
                label: 'Skip',
                onTap: _skipPomodoroPhase,
                isSecondary: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _demoPomodoro.completedCycles
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildPomodoroButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSecondary
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSecondary ? Colors.white : const Color(0xFF667eea),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSecondary ? Colors.white : const Color(0xFF667eea),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePomodoro() {
    setState(() {
      _isPomodoroRunning = !_isPomodoroRunning;
    });
  }

  void _stopPomodoro() {
    setState(() {
      _isPomodoroRunning = false;
      _pomodoroRemaining = const Duration(minutes: 25);
    });
  }

  void _skipPomodoroPhase() {
    // Demo functionality
  }

  Widget _buildRemindersCard() {
    final reminders = [
      {
        'time': '09:00',
        'title': 'Daily Study Reminder',
        'enabled': true,
        'icon': Icons.access_time,
        'color': Colors.blue,
      },
      {
        'time': '20:00',
        'title': 'Streak Protection',
        'enabled': true,
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
      },
      {
        'time': '14:00',
        'title': 'Review Session',
        'enabled': false,
        'icon': Icons.refresh,
        'color': Colors.green,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Smart Reminders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reminders.map((reminder) => _buildReminderItem(reminder)),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder) {
    final isEnabled = reminder['enabled'] as bool;
    final color = reminder['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? color.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled ? color.withValues(alpha: 0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              reminder['icon'] as IconData,
              color: isEnabled ? color : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? AppColors.textDark : Colors.grey,
                  ),
                ),
                Text(
                  reminder['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled ? AppColors.textMedium : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {},
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSessionItem(
            title: 'Grammar Practice',
            time: 'Today, 3:00 PM',
            duration: '30 min',
            color: Colors.purple,
          ),
          _buildSessionItem(
            title: 'Vocabulary Review',
            time: 'Tomorrow, 9:00 AM',
            duration: '25 min',
            color: Colors.teal,
          ),
          _buildSessionItem(
            title: 'Story Reading',
            time: 'Wed, 7:00 PM',
            duration: '20 min',
            color: Colors.orange,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSessionItem({
    required String title,
    required String time,
    required String duration,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Text(
              duration,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STORIES TAB ====================

  Widget _buildStoriesTab() {
    final stories = [
      {
        'title': 'A Day in Madrid',
        'nativeTitle': 'Un Día en Madrid',
        'difficulty': 'Beginner',
        'color': Colors.green,
        'time': '5 min',
        'words': 150,
      },
      {
        'title': 'The Lost Key',
        'nativeTitle': 'La Llave Perdida',
        'difficulty': 'Intermediate',
        'color': Colors.orange,
        'time': '10 min',
        'words': 320,
      },
      {
        'title': 'The Art of Flamenco',
        'nativeTitle': 'El Arte del Flamenco',
        'difficulty': 'Advanced',
        'color': Colors.red,
        'time': '15 min',
        'words': 580,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '12 stories read this month',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '85%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recommended Stories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...stories.map((story) => _buildStoryCard(story)),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final color = story['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  story['difficulty'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.bookmark_border, color: AppColors.textMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            story['title'] as String,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            story['nativeTitle'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                story['time'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.format_list_numbered, size: 16, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                '${story['words']} words',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Read Story'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  // ==================== COMMUNITY TAB ====================

  Widget _buildCommunityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommunitySection(
            title: 'Community Challenges',
            icon: Icons.emoji_events,
            color: Colors.amber,
            child: _buildChallengesList(),
          ),
          const SizedBox(height: 20),
          _buildCommunitySection(
            title: 'Popular Decks',
            icon: Icons.style,
            color: Colors.blue,
            child: _buildDecksList(),
          ),
          const SizedBox(height: 20),
          _buildCommunitySection(
            title: 'Language Exchange',
            icon: Icons.people,
            color: Colors.green,
            child: _buildExchangeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildChallengesList() {
    return Column(
      children: [
        _buildChallengeCard(
          title: '7-Day Streak Challenge',
          participants: 1234,
          daysLeft: 3,
          progress: 0.7,
          color: Colors.orange,
        ),
        _buildChallengeCard(
          title: 'Vocabulary Sprint',
          participants: 892,
          daysLeft: 5,
          progress: 0.4,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required int participants,
    required int daysLeft,
    required double progress,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people, size: 14, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                '$participants participating',
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
              ),
              const Spacer(),
              const Icon(Icons.timer, size: 14, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                '$daysLeft days left',
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecksList() {
    return Column(
      children: [
        _buildDeckCard(
          title: 'Business Spanish',
          author: 'Maria L.',
          cards: 120,
          downloads: 543,
          rating: 4.8,
        ),
        _buildDeckCard(
          title: 'Travel Essentials',
          author: 'John D.',
          cards: 85,
          downloads: 892,
          rating: 4.6,
        ),
      ],
    );
  }

  Widget _buildDeckCard({
    required String title,
    required String author,
    required int cards,
    required int downloads,
    required double rating,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.style, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('by $author', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.style, size: 12, color: AppColors.textMedium),
                    const SizedBox(width: 4),
                    Text('$cards cards', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    const SizedBox(width: 12),
                    const Icon(Icons.download, size: 12, color: AppColors.textMedium),
                    const SizedBox(width: 4),
                    Text('$downloads', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    const SizedBox(width: 12),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('$rating', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeList() {
    return Column(
      children: [
        _buildExchangeCard(
          name: 'Carlos R.',
          nativeLang: 'Spanish',
          learningLang: 'English',
          level: 'Advanced',
          isOnline: true,
        ),
        _buildExchangeCard(
          name: 'Sofia M.',
          nativeLang: 'Spanish',
          learningLang: 'English',
          level: 'Intermediate',
          isOnline: false,
        ),
      ],
    );
  }

  Widget _buildExchangeCard({
    required String name,
    required String nativeLang,
    required String learningLang,
    required String level,
    required bool isOnline,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.person, color: Colors.green),
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
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  'Speaks: $nativeLang • Learning: $learningLang',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  // ==================== ANALYTICS TAB ====================

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeatmapCard(),
          const SizedBox(height: 20),
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildSkillRadarCard(),
          const SizedBox(height: 20),
          _buildWeakAreasCard(),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Study Streak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, 
                      color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '12 days',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeatmapGrid(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
              const SizedBox(width: 4),
              ...List.generate(5, (index) {
                final colors = [
                  const Color(0xFFE0E0E0),
                  const Color(0xFF9BE9A8),
                  const Color(0xFF40C463),
                  const Color(0xFF30A14E),
                  const Color(0xFF216E39),
                ];
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              const Text('More', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildHeatmapGrid() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(28, (index) {
        // Generate some sample data
        final intensity = (index % 5);
        final colors = [
          const Color(0xFFE0E0E0),
          const Color(0xFF9BE9A8),
          const Color(0xFF40C463),
          const Color(0xFF30A14E),
          const Color(0xFF216E39),
        ];
        
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors[intensity],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          title: 'Total XP',
          value: '2,450',
          subtitle: '+320 this week',
          icon: Icons.star,
          color: Colors.amber,
        ),
        _buildStatCard(
          title: 'Words Learned',
          value: '486',
          subtitle: '32 new this week',
          icon: Icons.translate,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Study Time',
          value: '48h',
          subtitle: '6.5h this week',
          icon: Icons.timer,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Accuracy',
          value: '87%',
          subtitle: '+5% improvement',
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRadarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSkillBars(),
        ],
      ),
    );
  }

  Widget _buildSkillBars() {
    final skills = [
      {'name': 'Vocabulary', 'value': 0.85, 'color': Colors.blue},
      {'name': 'Grammar', 'value': 0.72, 'color': Colors.purple},
      {'name': 'Reading', 'value': 0.68, 'color': Colors.green},
      {'name': 'Listening', 'value': 0.55, 'color': Colors.orange},
      {'name': 'Speaking', 'value': 0.45, 'color': Colors.red},
      {'name': 'Writing', 'value': 0.60, 'color': Colors.teal},
    ];

    return Column(
      children: skills.map((skill) {
        final color = skill['color'] as Color;
        final value = skill['value'] as double;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    skill['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${(value * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeakAreasCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Areas to Improve',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeakAreaItem(
            skill: 'Speaking Practice',
            description: 'Your speaking score is 20% below target',
            recommendation: 'Try conversation practice with AI tutor',
            color: Colors.red,
          ),
          _buildWeakAreaItem(
            skill: 'Past Tense Verbs',
            description: '72% accuracy - needs improvement',
            recommendation: 'Review "Past Tense" grammar lesson',
            color: Colors.orange,
          ),
          _buildWeakAreaItem(
            skill: 'Food Vocabulary',
            description: 'Words often forgotten in reviews',
            recommendation: 'Practice with Food category flashcards',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildWeakAreaItem({
    required String skill,
    required String description,
    required String recommendation,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                skill,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, size: 14, color: AppColors.textMedium),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
