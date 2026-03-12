import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'auth/register_screen.dart';
import 'ux_settings_screen.dart';
import 'debug/tts_debugger_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;
    final user = isGuest ? authProvider.guestUser : authProvider.currentUser;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(user, isGuest),
                ),
                if (isGuest)
                  SliverToBoxAdapter(
                    child: _buildGuestBanner(context),
                  ),
                // Account section - HIDDEN for guests
                if (!isGuest)
                  SliverToBoxAdapter(
                    child: _buildSettingsSection(
                      title: 'Account',
                      items: _buildAccountSettings(context, isGuest, authProvider),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _buildSettingsSection(
                    title: 'Preferences',
                    items: _buildPreferenceSettings(context, isGuest),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSettingsSection(
                    title: 'Learning',
                    items: _buildLearningSettings(context, isGuest),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSettingsSection(
                    title: 'Notifications',
                    items: _buildNotificationSettings(context, isGuest),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSettingsSection(
                    title: 'Support',
                    items: _buildSupportSettings(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSettingsSection(
                    title: 'Legal',
                    items: _buildLegalSettings(context),
                  ),
                ),
                // Danger Zone - HIDDEN for guests
                if (!isGuest)
                  SliverToBoxAdapter(
                    child: _buildDangerZone(context, authProvider),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(dynamic user, bool isGuest) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  image: user?.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user!.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user?.avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 35,
                        color: AppColors.primaryTeal,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? user?.username ?? 'Guest User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isGuest
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isGuest ? 'Guest Account' : 'Premium Member',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isGuest) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('${user?.totalXP ?? 0}', 'XP'),
                _buildStat('${user?.currentLevel ?? 1}', 'Level'),
                _buildStat('${user?.streakDays ?? 0}', 'Streak'),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFFF6E40)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guest Account',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your progress is saved locally on this device. Create an account to sync across devices and unlock all features!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF6E40),
              ),
              child: const Text('Create Account'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            children: items,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAccountSettings(
    BuildContext context,
    bool isGuest,
    AuthProvider authProvider,
  ) {
    // Account section is now completely hidden for guests
    // This method is only called for authenticated users
    return [
      _buildSettingsTile(
        icon: Icons.person,
        title: 'Edit Profile',
        subtitle: 'Change name, photo, bio',
        onTap: () => _showEditProfile(context),
      ),
      _buildSettingsTile(
        icon: Icons.email,
        title: 'Change Email',
        subtitle: 'Update email address',
        onTap: () => _showChangeEmail(context),
      ),
      _buildSettingsTile(
        icon: Icons.lock,
        title: 'Change Password',
        subtitle: 'Update your password',
        onTap: () => _showChangePassword(context),
      ),
      _buildSettingsTile(
        icon: Icons.language,
        title: 'Languages',
        subtitle: 'Native & learning languages',
        onTap: () => _showLanguageSettings(context),
      ),
    ];
  }

  List<Widget> _buildPreferenceSettings(BuildContext context, bool isGuest) {
    return [
      _buildSettingsTile(
        icon: Icons.palette,
        title: 'Appearance',
        subtitle: 'Theme: ${context.watch<ThemeProvider>().getThemeModeName()}',
        onTap: () => _showThemeSelector(context),
      ),
      _buildSettingsTile(
        icon: Icons.volume_up,
        title: 'Sound Effects',
        subtitle: 'Enable/disable sounds',
        trailing: Switch(
          value: true,
          onChanged: (value) {
            // Toggle sound
          },
        ),
      ),
      _buildSettingsTile(
        icon: Icons.vibration,
        title: 'Haptic Feedback',
        subtitle: 'Vibration on actions',
        trailing: Switch(
          value: true,
          onChanged: (value) {
            // Toggle haptics
          },
        ),
      ),
      _buildSettingsTile(
        icon: Icons.accessibility_new,
        title: 'UX & Accessibility',
        subtitle: 'Advanced UI settings',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UXSettingsScreen()),
          );
        },
      ),
    ];
  }

  void _showThemeSelector(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your preferred appearance',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _buildThemeOption(
                  context,
                  'Light',
                  'Clean and bright',
                  Icons.light_mode,
                  AppThemeMode.light,
                  themeProvider,
                ),
                const SizedBox(height: 12),
                _buildThemeOption(
                  context,
                  'Dark',
                  'Premium modern dark mode',
                  Icons.dark_mode,
                  AppThemeMode.dark,
                  themeProvider,
                ),
                const SizedBox(height: 12),
                _buildThemeOption(
                  context,
                  'System',
                  'Follow device settings',
                  Icons.brightness_auto,
                  AppThemeMode.system,
                  themeProvider,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    AppThemeMode mode,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    
    return GestureDetector(
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryTeal.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryTeal : AppColors.textMedium,
              size: 28,
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
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.textDark : AppColors.textMedium,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
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

  List<Widget> _buildLearningSettings(BuildContext context, bool isGuest) {
    final items = <Widget>[
      _buildSettingsTile(
        icon: Icons.timer,
        title: 'Daily Goal',
        subtitle: 'Set daily learning target',
        onTap: () => _showDailyGoalSettings(context),
      ),
      _buildSettingsTile(
        icon: Icons.notifications_active,
        title: 'Reminder Time',
        subtitle: 'When to remind you to practice',
        onTap: () => _showReminderSettings(context),
      ),
    ];

    if (!isGuest) {
      items.addAll([
        _buildSettingsTile(
          icon: Icons.download,
          title: 'Offline Content',
          subtitle: 'Download lessons for offline',
          onTap: () => _showOfflineContent(context),
        ),
        _buildSettingsTile(
          icon: Icons.speed,
          title: 'Difficulty',
          subtitle: 'Adjust learning difficulty',
          onTap: () => _showDifficultySettings(context),
        ),
      ]);
    }

    return items;
  }

  List<Widget> _buildNotificationSettings(BuildContext context, bool isGuest) {
    final items = <Widget>[
      _buildSettingsTile(
        icon: Icons.notifications,
        title: 'Push Notifications',
        subtitle: 'Enable push notifications',
        trailing: Switch(
          value: true,
          onChanged: (value) {
            // Toggle notifications
          },
        ),
      ),
    ];

    if (!isGuest) {
      items.addAll([
        _buildSettingsTile(
          icon: Icons.local_fire_department,
          title: 'Streak Reminders',
          subtitle: 'Don\'t break your streak!',
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // Toggle streak reminders
            },
          ),
        ),
        _buildSettingsTile(
          icon: Icons.emoji_events,
          title: 'Achievement Alerts',
          subtitle: 'Notify when earning achievements',
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // Toggle achievement alerts
            },
          ),
        ),
        _buildSettingsTile(
          icon: Icons.people,
          title: 'Friend Activity',
          subtitle: 'Friends\' progress updates',
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // Toggle friend activity
            },
          ),
        ),
      ]);
    }

    return items;
  }

  List<Widget> _buildSupportSettings(BuildContext context) {
    return [
      _buildSettingsTile(
        icon: Icons.help_outline,
        title: 'Help Center',
        subtitle: 'FAQs and tutorials',
        onTap: () => _openHelpCenter(context),
      ),
      _buildSettingsTile(
        icon: Icons.feedback,
        title: 'Send Feedback',
        subtitle: 'Help us improve',
        onTap: () => _showFeedbackDialog(context),
      ),
      _buildSettingsTile(
        icon: Icons.bug_report,
        title: 'Report a Bug',
        subtitle: 'Tell us about issues',
        onTap: () => _showBugReport(context),
      ),
      _buildSettingsTile(
        icon: Icons.bug_report_outlined,
        title: 'TTS Debugger',
        subtitle: 'Test Kinyarwanda & MMS models',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TtsDebuggerScreen()),
          );
        },
      ),
      _buildSettingsTile(
        icon: Icons.share,
        title: 'Share App',
        subtitle: 'Invite friends to learn',
        onTap: () => _shareApp(context),
      ),
      _buildSettingsTile(
        icon: Icons.star,
        title: 'Rate App',
        subtitle: 'Rate us on Play Store',
        onTap: () => _rateApp(context),
      ),
    ];
  }

  List<Widget> _buildLegalSettings(BuildContext context) {
    return [
      _buildSettingsTile(
        icon: Icons.privacy_tip,
        title: 'Privacy Policy',
        subtitle: 'How we handle your data',
        onTap: () => _showPrivacyPolicy(context),
      ),
      _buildSettingsTile(
        icon: Icons.description,
        title: 'Terms of Service',
        subtitle: 'App usage terms',
        onTap: () => _showTermsOfService(context),
      ),
      _buildSettingsTile(
        icon: Icons.info,
        title: 'About',
        subtitle: 'App version and info',
        onTap: () => _showAbout(context),
      ),
    ];
  }

  Widget _buildDangerZone(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Log out of your account',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => _showSignOutConfirmation(context, authProvider),
              ),
              Divider(height: 1, color: Colors.red.shade200),
              _buildSettingsTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => _showDeleteAccountConfirmation(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primaryTeal).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primaryTeal,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor ?? AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor?.withValues(alpha: 0.7) ?? AppColors.textMedium,
          fontSize: 12,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: textColor?.withValues(alpha: 0.5) ?? AppColors.textLight,
                )
              : null),
      onTap: onTap,
    );
  }

  // Action Methods
  void _showEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const EditProfileSheet(),
    );
  }

  void _showChangeEmail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'New Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackbar('Email updated successfully');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackbar('Password updated successfully');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Languages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('Native Language'),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
              title: const Text('Learning Language'),
              subtitle: const Text('Spanish'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyGoalSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Daily Learning Goal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildGoalOption('Casual', '10 min/day', Icons.coffee),
            _buildGoalOption('Regular', '20 min/day', Icons.schedule),
            _buildGoalOption('Serious', '30 min/day', Icons.trending_up),
            _buildGoalOption('Intense', '60 min/day', Icons.whatshot),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryTeal),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Radio<String>(
        value: title,
        groupValue: 'Regular',
        onChanged: (value) {
          if (!mounted) return;
          Navigator.pop(context);
          _showSuccessSnackbar('Daily goal set to $title');
        },
      ),
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
        _showSuccessSnackbar('Daily goal set to $title');
      },
    );
  }

  void _showReminderSettings(BuildContext context) {
    showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    ).then((time) {
      if (time != null && mounted) {
        _showSuccessSnackbar(
          'Reminder set for ${time.format(context)}',
        );
      }
    });
  }

  void _showOfflineContent(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Offline Content',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.download_done, color: Colors.green),
              title: Text('Downloaded'),
              subtitle: Text('156 MB • 24 lessons'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessSnackbar('Downloading new content...');
              },
              icon: const Icon(Icons.download),
              label: const Text('Download More'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Learning Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Beginner'),
              subtitle: const Text('Slower pace, more hints'),
              value: 'beginner',
              groupValue: 'intermediate',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Intermediate'),
              subtitle: const Text('Standard learning pace'),
              value: 'intermediate',
              groupValue: 'intermediate',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Advanced'),
              subtitle: const Text('Faster pace, fewer hints'),
              value: 'advanced',
              groupValue: 'intermediate',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackbar('Difficulty updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Help Center',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildHelpItem('How do I start learning?',
                        'Select a course and start with the first lesson. Complete lessons to earn XP and level up!'),
                    _buildHelpItem('What are streaks?',
                        'Streaks track consecutive days of learning. Keep your streak going by practicing every day!'),
                    _buildHelpItem('How do I earn XP?',
                        'Complete lessons, practice vocabulary, and play games to earn XP and level up.'),
                    _buildHelpItem('Can I learn offline?',
                        'Yes! Download content in Learning Settings to access lessons without internet.'),
                    _buildHelpItem('How do I add friends?',
                        'Go to the Social tab and search for friends by username or email.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: feedbackController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tell us what you think...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackbar('Thank you for your feedback!');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showBugReport(BuildContext context) {
    final bugController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please describe the issue you encountered:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bugController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the bug...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackbar('Bug report submitted. Thank you!');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    Share.share(
      'Check out Soma - the best way to learn languages! 🌍\n\n'
      'Download now: https://play.google.com/store/apps/details?id=com.amoslanguages.soma',
    );
  }

  void _rateApp(BuildContext context) {
    _showSuccessSnackbar('Opening Play Store...');
    // In production, use url_launcher to open Play Store
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            '1. Data Collection\n'
            'We collect information you provide directly, including your profile data and learning progress.\n\n'
            '2. Data Usage\n'
            'We use your data to personalize your learning experience and improve our services.\n\n'
            '3. Data Protection\n'
            'Your data is encrypted and stored securely. We never sell your personal information.\n\n'
            '4. Your Rights\n'
            'You can request deletion of your data at any time by contacting support.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
            '1. Acceptance of Terms\n'
            'By using Soma, you agree to these terms and conditions.\n\n'
            '2. User Accounts\n'
            'You are responsible for maintaining the security of your account.\n\n'
            '3. Acceptable Use\n'
            'Users must not abuse the service or engage in harmful behavior.\n\n'
            '4. Content\n'
            'All learning content is property of Soma and protected by copyright.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('About Soma')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Soma',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI-powered language learning with fun games and social features.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2025 Amos Languages',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              await authProvider.signOut();
              setState(() => _isLoading = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          '⚠️ This action cannot be undone!\n\n'
          'All your progress, achievements, and data will be permanently deleted.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Type "DELETE" to confirm',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackbar('Account deletion requested');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class EditProfileSheet extends StatelessWidget {
  const EditProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.primaryTeal,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
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
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell us about yourself',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

