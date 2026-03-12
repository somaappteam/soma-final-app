import 'package:flutter/material.dart';
import 'social_feed_screen.dart';

/// Main Social Screen - Entry point to social features
/// Uses the premium SocialFeedScreen with activity feed, friends, and messages
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SocialFeedScreen();
  }
}
