import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state.dart';
import 'auth_provider.dart';
import 'course_provider.dart';
import 'theme_provider.dart';
import 'premium_provider.dart';
import 'gamification_provider.dart';
import 'learning_path_provider.dart';
import 'notification_provider.dart';
import 'podcast_provider.dart';
import 'ai_tutor_provider.dart';

final themeNotifierProvider = ChangeNotifierProvider<ThemeProvider>((ref) => ThemeProvider());
final authNotifierProvider = ChangeNotifierProvider<AuthProvider>((ref) => AuthProvider());
final courseNotifierProvider = ChangeNotifierProvider<CourseProvider>((ref) => CourseProvider());
final premiumNotifierProvider = ChangeNotifierProvider<PremiumProvider>((ref) => PremiumProvider());
final gamificationNotifierProvider = ChangeNotifierProvider<GamificationProvider>((ref) => GamificationProvider());
final learningPathNotifierProvider = ChangeNotifierProvider<LearningPathProvider>((ref) => LearningPathProvider());
final notificationNotifierProvider = ChangeNotifierProvider<NotificationProvider>((ref) => NotificationProvider());
final podcastNotifierProvider = ChangeNotifierProvider<PodcastProvider>((ref) => PodcastProvider());
final appStateProvider = ChangeNotifierProvider<AppState>((ref) => AppState());
final aiTutorNotifierProvider = ChangeNotifierProvider<AITutorProvider>((ref) => AITutorProvider());
