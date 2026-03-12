import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GuestUser {
  final String id;
  String username;
  String? displayName;
  String? avatarUrl;
  String? bio;
  String nativeLanguage;
  List<String> learningLanguages;
  int totalXP;
  int currentLevel;
  int streakDays;
  int totalGamesPlayed;
  int totalGamesWon;
  String? country;
  DateTime createdAt;
  DateTime lastActiveAt;

  GuestUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.nativeLanguage = 'en',
    this.learningLanguages = const ['es'],
    this.totalXP = 0,
    this.currentLevel = 1,
    this.streakDays = 0,
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.country,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory GuestUser.create() {
    return GuestUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      username: 'Guest${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      nativeLanguage: 'en',
      learningLanguages: const ['es'],
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'native_language': nativeLanguage,
      'learning_languages': learningLanguages,
      'total_xp': totalXP,
      'current_level': currentLevel,
      'streak_days': streakDays,
      'total_games_played': totalGamesPlayed,
      'total_games_won': totalGamesWon,
      'country': country,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }

  factory GuestUser.fromJson(Map<String, dynamic> json) {
    return GuestUser(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      nativeLanguage: json['native_language'] ?? 'en',
      learningLanguages: List<String>.from(json['learning_languages'] ?? ['es']),
      totalXP: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
      streakDays: json['streak_days'] ?? 0,
      totalGamesPlayed: json['total_games_played'] ?? 0,
      totalGamesWon: json['total_games_won'] ?? 0,
      country: json['country'],
      createdAt: DateTime.parse(json['created_at']),
      lastActiveAt: DateTime.parse(json['last_active_at']),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guest_user', jsonEncode(toJson()));
    await prefs.setBool('is_guest', true);
  }

  static Future<GuestUser?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('is_guest') ?? false;
    
    if (!isGuest) return null;
    
    final userJson = prefs.getString('guest_user');
    if (userJson == null) return null;
    
    try {
      return GuestUser.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_user');
    await prefs.remove('is_guest');
  }

  GuestUser copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? nativeLanguage,
    List<String>? learningLanguages,
    int? totalXP,
    int? currentLevel,
    int? streakDays,
    int? totalGamesPlayed,
    int? totalGamesWon,
    String? country,
    DateTime? lastActiveAt,
  }) {
    return GuestUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      learningLanguages: learningLanguages ?? this.learningLanguages,
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      streakDays: streakDays ?? this.streakDays,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      country: country ?? this.country,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? DateTime.now(),
    );
  }
}
