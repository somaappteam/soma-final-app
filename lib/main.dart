import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Consumer;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'providers/riverpod_providers.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';
import 'services/offline_sync_service.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  
  // Offline Sync Foundation (Hive & Workmanager)
  await OfflineSyncService.initialize();
  await SoundService().initialize();

  // Supabase and AI Tutor initializations
  final supabaseService = SupabaseService();
  await supabaseService.initialize();
  
  await Future.delayed(const Duration(milliseconds: 100));
  
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://example@sentry.io/1234567'; // Placeholder DSN
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: SomaApp(),
      ),
    ),
  );
}

class SomaApp extends ConsumerWidget {
  const SomaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ref.watch(themeNotifierProvider)),
        ChangeNotifierProvider.value(value: ref.watch(authNotifierProvider)),
        ChangeNotifierProvider.value(value: ref.watch(courseNotifierProvider)),
        ChangeNotifierProvider.value(value: ref.watch(premiumNotifierProvider)),
        ChangeNotifierProvider.value(value: ref.watch(gamificationNotifierProvider)),
        ChangeNotifierProvider.value(value: ref.watch(learningPathNotifierProvider)),
        ChangeNotifierProvider.value(value: ref.watch(notificationNotifierProvider)),
        ChangeNotifierProvider.value(value: ref.watch(podcastNotifierProvider)),
        ChangeNotifierProvider.value(value: ref.watch(appStateProvider)),
        ChangeNotifierProvider.value(value: ref.watch(aiTutorNotifierProvider)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Soma',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.flutterThemeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
