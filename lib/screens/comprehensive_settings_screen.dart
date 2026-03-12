import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ComprehensiveSettingsScreen extends StatefulWidget {
  const ComprehensiveSettingsScreen({super.key});

  @override
  State<ComprehensiveSettingsScreen> createState() => _ComprehensiveSettingsScreenState();
}

class _ComprehensiveSettingsScreenState extends State<ComprehensiveSettingsScreen> {
  // Learning Settings
  int _dailyGoalMinutes = 15;
  String _difficultyLevel = 'adaptive';
  bool _spacedRepetitionEnabled = true;
  bool _autoAdvance = true;
  bool _showRomanization = false;
  int _wordsPerSession = 10;
  
  // Audio Settings
  bool _soundEnabled = true;
  bool _autoPlayAudio = false;
  double _audioSpeed = 1.0;
  
  // Notification Settings
  bool _dailyReminders = true;
  bool _streakReminders = true;
  bool _achievementNotifications = true;
  bool _challengeNotifications = true;
  
  // Privacy Settings
  bool _profilePublic = false;
  bool _showActivityStatus = true;
  bool _allowFriendRequests = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // In a real app, load from shared preferences or backend
    // final prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _dailyGoalMinutes = prefs.getInt('daily_goal_minutes') ?? 15;
    //   _difficultyLevel = prefs.getString('difficulty_level') ?? 'adaptive';
    //   ...
    // });
  }

  Future<void> _saveSettings() async {
    // In a real app, save to shared preferences or backend
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setInt('daily_goal_minutes', _dailyGoalMinutes);
    // await prefs.setString('difficulty_level', _difficultyLevel);
    // ...
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Learning Settings',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Daily Goal Section
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              title: 'Daily Goal',
              icon: Icons.flag,
              color: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_dailyGoalMinutes minutes/day',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _dailyGoalMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: AppColors.primaryTeal,
                    label: '$_dailyGoalMinutes min',
                    onChanged: (value) {
                      setState(() {
                        _dailyGoalMinutes = value.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGoalChip(5, 'Casual'),
                      _buildGoalChip(15, 'Regular', isDefault: true),
                      _buildGoalChip(30, 'Serious'),
                      _buildGoalChip(60, 'Intense'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Difficulty Level
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              title: 'Difficulty',
              icon: Icons.trending_up,
              color: Colors.blue,
              child: Column(
                children: [
                  _buildDifficultyOption(
                    'adaptive',
                    'Adaptive',
                    'Adjusts to your performance automatically',
                    Icons.auto_awesome,
                  ),
                  _buildDifficultyOption(
                    'beginner',
                    'Beginner',
                    'Focus on basics and foundational vocabulary',
                    Icons.school,
                  ),
                  _buildDifficultyOption(
                    'intermediate',
                    'Intermediate',
                    'Balanced challenge with complex grammar',
                    Icons.trending_up,
                  ),
                  _buildDifficultyOption(
                    'advanced',
                    'Advanced',
                    'Native-level content and nuanced language',
                    Icons.workspace_premium,
                  ),
                ],
              ),
            ),
          ),
          
          // Study Preferences
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              title: 'Study Preferences',
              icon: Icons.psychology,
              color: Colors.purple,
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Spaced Repetition',
                    'Optimize review intervals for better retention',
                    _spacedRepetitionEnabled,
                    (value) => setState(() => _spacedRepetitionEnabled = value),
                  ),
                  _buildSwitchTile(
                    'Auto-advance',
                    'Automatically go to next item after answering',
                    _autoAdvance,
                    (value) => setState(() => _autoAdvance = value),
                  ),
                  _buildSwitchTile(
                    'Show Romanization',
                    'Display pronunciation guides for non-Latin scripts',
                    _showRomanization,
                    (value) => setState(() => _showRomanization = value),
                  ),
                  _buildNumberSelector(
                    'Words per Session',
                    _wordsPerSession,
                    [5, 10, 15, 20, 25, 30],
                    (value) => setState(() => _wordsPerSession = value),
                  ),
                ],
              ),
            ),
          ),
          
          // Audio Settings
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              title: 'Audio',
              icon: Icons.volume_up,
              color: Colors.green,
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Sound Effects',
                    'Play sounds for correct/incorrect answers',
                    _soundEnabled,
                    (value) => setState(() => _soundEnabled = value),
                  ),
                  _buildSwitchTile(
                    'Auto-play Audio',
                    'Automatically play pronunciation audio',
                    _autoPlayAudio,
                    (value) => setState(() => _autoPlayAudio = value),
                  ),
                  _buildSliderTile(
                    'Audio Speed',
                    '${(_audioSpeed * 100).round()}%',
                    _audioSpeed,
                    0.5,
                    1.5,
                    (value) => setState(() => _audioSpeed = value),
                  ),
                ],
              ),
            ),
          ),
          
          // Notifications
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              title: 'Notifications',
              icon: Icons.notifications,
              color: Colors.red,
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Daily Reminders',
                    'Remind me to practice every day',
                    _dailyReminders,
                    (value) => setState(() => _dailyReminders = value),
                  ),
                  _buildSwitchTile(
                    'Streak Reminders',
                    'Warn me before losing my streak',
                    _streakReminders,
                    (value) => setState(() => _streakReminders = value),
                  ),
                  _buildSwitchTile(
                    'Achievements',
                    'Notify when I unlock achievements',
                    _achievementNotifications,
                    (value) => setState(() => _achievementNotifications = value),
                  ),
                  _buildSwitchTile(
                    'Challenges',
                    'Updates about community challenges',
                    _challengeNotifications,
                    (value) => setState(() => _challengeNotifications = value),
                  ),
                ],
              ),
            ),
          ),
          
          // Privacy
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              title: 'Privacy',
              icon: Icons.privacy_tip,
              color: Colors.indigo,
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Public Profile',
                    'Allow others to see your profile',
                    _profilePublic,
                    (value) => setState(() => _profilePublic = value),
                  ),
                  _buildSwitchTile(
                    'Activity Status',
                    'Show when you\'re online',
                    _showActivityStatus,
                    (value) => setState(() => _showActivityStatus = value),
                  ),
                  _buildSwitchTile(
                    'Friend Requests',
                    'Allow others to send you friend requests',
                    _allowFriendRequests,
                    (value) => setState(() => _allowFriendRequests = value),
                  ),
                ],
              ),
            ),
          ),
          
          // Language Settings
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              title: 'Language',
              icon: Icons.language,
              color: Colors.teal,
              child: Column(
                children: [
                  _buildNavigationTile(
                    'Native Language',
                    'English',
                    Icons.arrow_forward_ios,
                    () => _showLanguagePicker(true),
                  ),
                  _buildNavigationTile(
                    'Learning Language',
                    'Spanish',
                    Icons.arrow_forward_ios,
                    () => _showLanguagePicker(false),
                  ),
                  _buildNavigationTile(
                    'Change Course',
                    'Current: Spanish Basics',
                    Icons.arrow_forward_ios,
                    () {
                      // Navigate to course selection
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Data Management
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              title: 'Data',
              icon: Icons.storage,
              color: Colors.grey,
              child: Column(
                children: [
                  _buildNavigationTile(
                    'Download My Data',
                    'Export your learning data',
                    Icons.download,
                    () {
                      // Download user data
                    },
                  ),
                  _buildNavigationTile(
                    'Clear Cache',
                    'Free up storage space',
                    Icons.cleaning_services,
                    () {
                      // Clear cache
                    },
                  ),
                  _buildNavigationTile(
                    'Reset Progress',
                    'Start over from the beginning',
                    Icons.restart_alt,
                    () => _showResetConfirmation(),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildGoalChip(int minutes, String label, {bool isDefault = false}) {
    final isSelected = _dailyGoalMinutes == minutes;
    
    return GestureDetector(
      onTap: () => setState(() => _dailyGoalMinutes = minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _difficultyLevel == value;
    
    return GestureDetector(
      onTap: () => setState(() => _difficultyLevel = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textMedium,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primaryTeal : AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryTeal,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMedium,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primaryTeal,
    );
  }

  Widget _buildNumberSelector(
    String label,
    int value,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options.map((option) {
              final isSelected = value == option;
              return ChoiceChip(
                label: Text('$option'),
                selected: isSelected,
                onSelected: (_) => onChanged(option),
                selectedColor: AppColors.primaryTeal,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String label,
    String valueText,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).round(),
          activeColor: AppColors.primaryTeal,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMedium,
        ),
      ),
      trailing: Icon(
        icon,
        size: 16,
        color: isDestructive ? Colors.red : AppColors.textLight,
      ),
      onTap: onTap,
    );
  }

  void _showLanguagePicker(bool isNative) {
    // Show language picker dialog
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNative ? 'Select Native Language' : 'Select Learning Language',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Language list would go here
            const Text('Language picker implementation'),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will delete all your learning progress and cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset progress logic
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
