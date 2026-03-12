import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/competition_provider.dart';
import 'providers/course_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/message_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/theme_provider.dart';
// NEW: Import new providers
import 'providers/ai_tutor_provider.dart';
import 'providers/learning_path_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/app_state.dart';

import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';
import 'services/ai_tutor_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  
  // Initialize Supabase
  await SupabaseService().initialize();
  
  // NEW: Initialize AI Tutor service
  await AITutorService().initialize();
  
  await Future.delayed(const Duration(milliseconds: 100));
  
  runApp(const SomaApp());
}

class SomaApp extends StatelessWidget {
  const SomaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CompetitionProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        // NEW: AI and Learning features
        ChangeNotifierProvider(create: (_) => AITutorProvider()),
        ChangeNotifierProvider(create: (_) => LearningPathProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),

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
