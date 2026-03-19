import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/premium_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'settings/storage_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _appVersion = '1.0.0+1';

  bool _notificationsEnabled = true;
  bool _hapticsEnabled = true;
  bool _soundEffectsEnabled = true;
  bool _streakProtectionReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  String _uiLanguage = 'System';
  Set<int> _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7};

  final PremiumService _premiumService = PremiumService();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isRestoringPurchases = false;

  static const _languageOptions = [
    'System',
    'English',
    'Spanish',
    'French',
    'German',
    'Portuguese',
    'Arabic',
    'Japanese',
  ];

  static const _weekdayLabels = {
    1: 'M',
    2: 'T',
    3: 'W',
    4: 'T',
    5: 'F',
    6: 'S',
    7: 'S',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool('settings_notifications_enabled') ?? true;
      _hapticsEnabled = prefs.getBool('settings_haptics_enabled') ?? true;
      _soundEffectsEnabled = prefs.getBool('settings_sound_effects_enabled') ?? true;
      _streakProtectionReminder = prefs.getBool('settings_streak_protection_reminder') ?? true;
      _uiLanguage = prefs.getString('settings_ui_language') ?? 'System';

      final reminderHour = prefs.getInt('settings_reminder_hour') ?? 19;
      final reminderMinute = prefs.getInt('settings_reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);

      final quietStartHour = prefs.getInt('settings_quiet_start_hour') ?? 22;
      final quietStartMinute = prefs.getInt('settings_quiet_start_minute') ?? 0;
      _quietHoursStart = TimeOfDay(hour: quietStartHour, minute: quietStartMinute);

      final quietEndHour = prefs.getInt('settings_quiet_end_hour') ?? 7;
      final quietEndMinute = prefs.getInt('settings_quiet_end_minute') ?? 0;
      _quietHoursEnd = TimeOfDay(hour: quietEndHour, minute: quietEndMinute);

      final weekdaysRaw = prefs.getStringList('settings_reminder_weekdays');
      if (weekdaysRaw != null && weekdaysRaw.isNotEmpty) {
        _selectedWeekdays = weekdaysRaw
            .map((day) => int.tryParse(day))
            .whereType<int>()
            .toSet();
      }
    });
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_notifications_enabled', _notificationsEnabled);
    await prefs.setBool('settings_haptics_enabled', _hapticsEnabled);
    await prefs.setBool('settings_sound_effects_enabled', _soundEffectsEnabled);
    await prefs.setBool('settings_streak_protection_reminder', _streakProtectionReminder);
    await prefs.setString('settings_ui_language', _uiLanguage);
    await prefs.setInt('settings_reminder_hour', _reminderTime.hour);
    await prefs.setInt('settings_reminder_minute', _reminderTime.minute);
    await prefs.setInt('settings_quiet_start_hour', _quietHoursStart.hour);
    await prefs.setInt('settings_quiet_start_minute', _quietHoursStart.minute);
    await prefs.setInt('settings_quiet_end_hour', _quietHoursEnd.hour);
    await prefs.setInt('settings_quiet_end_minute', _quietHoursEnd.minute);
    await prefs.setStringList(
      'settings_reminder_weekdays',
      _selectedWeekdays.map((e) => e.toString()).toList()..sort(),
    );
  }

  Future<void> _updateSettings(VoidCallback update) async {
    setState(update);
    await _persistSettings();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isSignedIn = authProvider.isAuthenticated;
    final isGuest = authProvider.isGuest || !isSignedIn;
    final user = isSignedIn ? authProvider.currentUser : authProvider.guestUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader(user, isGuest)),
          if (isGuest) SliverToBoxAdapter(child: _buildOfflineBanner(context)),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Premium Subscription',
              items: [
                _buildTile(
                  icon: Icons.workspace_premium,
                  title: (isSignedIn && authProvider.isPremium)
                      ? 'Premium Active'
                      : 'Upgrade to Premium',
                  subtitle: (isSignedIn && authProvider.isPremium)
                      ? 'Manage your current subscription and benefits.'
                      : 'See pricing, what you get today, and what is coming soon.',
                  trailing: (isSignedIn && authProvider.isPremium)
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(Icons.chevron_right),
                  onTap: () => _showPremiumSheet(context, isSignedIn),
                ),
                _buildTile(
                  icon: Icons.restore,
                  title: 'Restore Purchases',
                  subtitle: 'Recover your premium access from previous purchases',
                  onTap: _isRestoringPurchases ? null : _restorePurchases,
                  trailing: _isRestoringPurchases
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'App Preferences',
              items: [
                _buildTile(
                  icon: themeProvider.getThemeModeIcon(),
                  title: 'Theme',
                  subtitle: themeProvider.getThemeModeName(),
                  onTap: () => _showThemePicker(context, themeProvider),
                ),
                _buildTile(
                  icon: Icons.language,
                  title: 'App Language',
                  subtitle: _uiLanguage,
                  onTap: _showLanguagePicker,
                ),
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (value) => _updateSettings(() => _notificationsEnabled = value),
                  title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Daily reminders and learning updates'),
                  secondary: _buildLeadingIcon(Icons.notifications),
                ),
                SwitchListTile(
                  value: _hapticsEnabled,
                  onChanged: (value) => _updateSettings(() => _hapticsEnabled = value),
                  title: const Text('Haptics', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Vibration feedback during interactions'),
                  secondary: _buildLeadingIcon(Icons.vibration),
                ),
                SwitchListTile(
                  value: _soundEffectsEnabled,
                  onChanged: (value) => _updateSettings(() => _soundEffectsEnabled = value),
                  title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('UI and gameplay feedback sounds'),
                  secondary: _buildLeadingIcon(Icons.volume_up),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Data & Storage',
              items: [
                _buildTile(
                  icon: Icons.storage,
                  title: 'Storage Management',
                  subtitle: 'Manage downloaded TTS voices for offline learning',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StorageManagementScreen()),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Reminder Scheduling',
              items: [
                _buildTile(
                  icon: Icons.alarm,
                  title: 'Reminder Time',
                  subtitle: _formatTime(_reminderTime),
                  onTap: () => _pickTime(
                    initial: _reminderTime,
                    onPicked: (time) => _updateSettings(() => _reminderTime = time),
                  ),
                ),
                _buildWeekdaySelector(),
                SwitchListTile(
                  value: _streakProtectionReminder,
                  onChanged: (value) => _updateSettings(() => _streakProtectionReminder = value),
                  title: const Text('Streak Protection Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Extra nudge when your streak is at risk'),
                  secondary: _buildLeadingIcon(Icons.local_fire_department),
                ),
                _buildTile(
                  icon: Icons.nights_stay,
                  title: 'Quiet Hours Start',
                  subtitle: _formatTime(_quietHoursStart),
                  onTap: () => _pickTime(
                    initial: _quietHoursStart,
                    onPicked: (time) => _updateSettings(() => _quietHoursStart = time),
                  ),
                ),
                _buildTile(
                  icon: Icons.wb_sunny,
                  title: 'Quiet Hours End',
                  subtitle: _formatTime(_quietHoursEnd),
                  onTap: () => _pickTime(
                    initial: _quietHoursEnd,
                    onPicked: (time) => _updateSettings(() => _quietHoursEnd = time),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Support & About',
              items: [
                _buildTile(
                  icon: Icons.support_agent,
                  title: 'Support',
                  subtitle: 'Get help, report an issue, or request account changes',
                  onTap: _showSupportSheet,
                ),
                _buildTile(
                  icon: Icons.info_outline,
                  title: 'About App',
                  subtitle: 'Learn about Soma and current release details',
                  onTap: _showAboutSheet,
                ),
                _buildTile(
                  icon: Icons.new_releases,
                  title: 'App Version / Build',
                  subtitle: _appVersion,
                ),
              ],
            ),
          ),
          if (isSignedIn)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Account',
                items: [
                  _buildTile(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Use app offline and sign in again any time',
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () => _confirmSignOut(context, authProvider),
                  ),
                  _buildTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Request permanent account and cloud data deletion',
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () => _confirmDeleteAccount(context, authProvider),
                  ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primaryTeal),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Text(
              (user?.displayName ?? user?.username ?? 'G').toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? user?.username ?? 'Offline User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isGuest ? 'Offline Mode' : 'Signed In',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.coralGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offline first',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Continue learning without an account. Sign in only for sync and subscription.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.accentCoral,
                  ),
                  child: const Text('Create Account'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
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
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
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
        child: Icon(icon, color: iconColor ?? AppColors.primaryTeal),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor ?? AppColors.textDark),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textColor?.withValues(alpha: 0.7) ?? AppColors.textMedium, fontSize: 12),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight)
              : null),
      onTap: onTap,
    );
  }

  Widget _buildWeekdaySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reminder weekdays', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1;
              final selected = _selectedWeekdays.contains(day);
              return ChoiceChip(
                label: Text(_weekdayLabels[day]!),
                selected: selected,
                onSelected: (_) {
                  _updateSettings(() {
                    if (selected) {
                      _selectedWeekdays.remove(day);
                      if (_selectedWeekdays.isEmpty) _selectedWeekdays.add(day);
                    } else {
                      _selectedWeekdays.add(day);
                    }
                  });
                },
                selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primaryTeal : AppColors.textMedium,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime({required TimeOfDay initial, required Future<void> Function(TimeOfDay) onPicked}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (time != null) {
      await onPicked(time);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  void _showThemePicker(BuildContext context, ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () {
                provider.setThemeMode(AppThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () {
                provider.setThemeMode(AppThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System Default'),
              onTap: () {
                provider.setThemeMode(AppThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _languageOptions
              .map(
                (language) => RadioListTile<String>.adaptive(
                  value: language,
                  groupValue: _uiLanguage,
                  title: Text(language),
                  onChanged: (value) async {
                    if (value == null) return;
                    await _updateSettings(() => _uiLanguage = value);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('UI language preference saved.')),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureMatrix() {
    Widget row(String feature, String free, String premium) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(feature, style: const TextStyle(color: AppColors.textDark))),
            Expanded(child: Text(free, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMedium))),
            Expanded(child: Text(premium, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(flex: 3, child: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Free', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Premium', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal))),
            ],
          ),
          const SizedBox(height: 8),
          row('Offline Practice', '✓', '✓'),
          row('Cloud Sync', '—', '✓'),
          row('Cross-device backup', '—', '✓'),
          row('Weekly insights depth', 'Basic', 'Advanced'),
          row('Priority new modes', '—', '✓'),
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    Widget card({
      required String title,
      required String price,
      required String description,
      bool highlighted = false,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.primaryTeal.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted ? AppColors.primaryTeal : AppColors.neutralMid,
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryTeal)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(title: 'Monthly', price: r'$6.99/mo', description: 'Flexible billing'),
        const SizedBox(width: 10),
        card(title: 'Yearly', price: r'$49.99/yr', description: 'Best value (save ~40%)', highlighted: true),
      ],
    );
  }

  Widget _buildTagList(String title, List<String> items, {Color? accent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: accent ?? AppColors.textDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (accent ?? AppColors.primaryTeal).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _showPremiumSheet(BuildContext context, bool isSignedIn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Premium Plans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Choose a plan and unlock advanced sync, deeper analytics, and premium practice experiences.'),
              const SizedBox(height: 14),
              _buildPricingCards(),
              const SizedBox(height: 14),
              _buildPremiumFeatureMatrix(),
              const SizedBox(height: 14),
              _buildTagList(
                'What\'s included today',
                const ['Cloud sync', 'Cross-device backup', 'Priority features', 'Advanced analytics'],
              ),
              const SizedBox(height: 12),
              _buildTagList(
                'Coming soon',
                const ['Family plan', 'Coach insights', 'Expanded AI speaking drills'],
                accent: AppColors.accentOrange,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSignedIn
                      ? () => _openSubscriptionManagement()
                      : () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isSignedIn ? 'Manage Subscription' : 'Create Account to Subscribe'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _restorePurchases,
                  child: const Text('Restore Purchases'),
                ),
              ),
              if (!isSignedIn) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Sign In'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Offline mode stays available for everyone. Premium adds sync and account-connected benefits.',
                style: TextStyle(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    if (_isRestoringPurchases) return;

    setState(() => _isRestoringPurchases = true);
    try {
      final storeAvailable = await InAppPurchase.instance.isAvailable();
      if (storeAvailable) {
        await InAppPurchase.instance.restorePurchases();
      }

      await _premiumService.restorePurchases();

      // Immediately refresh the subscription badge in the UI
      if (mounted) {
        await context.read<AuthProvider>().refreshSubscriptionStatus();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchases restored. Your premium status has been refreshed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to restore purchases: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoringPurchases = false);
      }
    }
  }

  void _openSubscriptionManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Subscription'),
        content: const Text(
          'Use your platform subscription settings to manage or cancel.\n\n'
          'iOS: Settings > Apple ID > Subscriptions\n'
          'Android: Play Store > Payments & subscriptions',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'https://play.google.com/store/account/subscriptions'));
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Subscription management link copied.')),
              );
            },
            child: const Text('Copy Link'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Need help? Reach out to support and include your app version for faster troubleshooting.'),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: AppColors.primaryTeal),
                title: const Text('support@soma.app'),
                subtitle: const Text('Support email'),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'support@soma.app'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Support email copied.')),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bug_report_outlined, color: AppColors.primaryTeal),
                title: const Text('Report a bug'),
                subtitle: const Text('Include screenshots and steps to reproduce'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Please email support with issue details and screenshots.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutSheet() {
    showAboutDialog(
      context: context,
      applicationName: 'Soma',
      applicationVersion: _appVersion,
      applicationLegalese: '© Soma Learning',
      children: const [
        SizedBox(height: 8),
        Text('Soma helps you learn languages through interactive, gamified practice with offline-first support.'),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('You can continue using the app offline after signing out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will sign you out and submit a deletion request for your account data. This action is irreversible once processed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = authProvider.currentUser?.id;
                if (userId != null) {
                  await _supabaseService.client.from('account_deletion_requests').insert({
                    'user_id': userId,
                    'status': 'requested',
                    'requested_at': DateTime.now().toIso8601String(),
                  });
                }
              } catch (_) {
                // Fallback handled below with support guidance
              }

              await authProvider.signOut();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deletion request submitted. If needed, contact support@soma.app.'),
                ),
              );
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
