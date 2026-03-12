# Soma - New Features Integration Plan

## Overview
This document outlines the integration of 25+ new AI-powered features into the existing Soma Flutter app with Supabase backend.

## Current Architecture
- **Frontend**: Flutter 3.x with Provider state management
- **Backend**: Supabase (PostgreSQL + Realtime + Auth)
- **Notifications**: Firebase Cloud Messaging
- **Existing Features**: Competitions, Social, Leaderboards, Premium, Chat

## Integration Strategy

### Phase 1: Foundation (Week 1-2)
1. **Dependencies Update**
   - Speech recognition (speech_to_text)
   - Text-to-speech (flutter_tts)
   - Audio recording (record)
   - Video player (video_player)
   - AI/ML (google_generative_ai for Gemini API)
   - Charts (fl_chart already present)
   - Widgets (home_widget for Android/iOS)

2. **Database Schema Extensions**
   - Add tables for: lessons, vocabulary, grammar, stories, quests, achievements
   - Extend users table with: learning_style, streak_freeze_count, daily_quests
   - Add AI conversation history table

### Phase 2: Core AI Features (Week 3-5)

#### 1. AI-Powered Personalized Learning Path ⭐⭐⭐⭐⭐
**Integration Points:**
- Extend `UserModel` with `learningStyle`, `weakAreas`, `adaptiveDifficulty`
- Create `LearningPathService` with AI recommendation engine
- Add `Lesson` model with difficulty levels and prerequisites
- Create adaptive quiz algorithm based on user performance

**Key Components:**
- `lib/services/learning_path_service.dart`
- `lib/models/lesson_model.dart`
- `lib/screens/learning/learning_path_screen.dart`
- `lib/providers/learning_provider.dart`

#### 2. Voice Recognition & Pronunciation ⭐⭐⭐⭐⭐
**Integration Points:**
- Enhance existing `pronunciation_screen.dart`
- Add pronunciation scoring API integration
- Create voice recording and playback system

**Key Components:**
- `lib/services/pronunciation_service.dart`
- `lib/services/speech_recognition_service.dart`
- `lib/models/pronunciation_result.dart`
- `lib/screens/pronunciation/pronunciation_practice_screen.dart`

#### 3. AI Tutor (Premium) ⭐⭐⭐⭐⭐
**Integration Points:**
- Integrate with existing Premium system
- Add floating AI tutor button on all learning screens
- Create chat interface similar to existing messaging

**Key Components:**
- `lib/services/ai_tutor_service.dart`
- `lib/screens/ai_tutor/ai_tutor_chat_screen.dart`
- `lib/providers/ai_tutor_provider.dart`

### Phase 3: Learning Content (Week 6-8)

#### 4. Interactive Stories & Dialogues ⭐⭐⭐⭐
**Integration Points:**
- Create branching story system
- Add choice-based progression
- Cultural context integration

**Key Components:**
- `lib/models/story_model.dart`
- `lib/screens/stories/story_player_screen.dart`
- `lib/services/story_service.dart`

#### 5. Grammar Lessons with Visual Guides ⭐⭐⭐⭐
**Integration Points:**
- Visual sentence structure diagrams
- Interactive grammar exercises
- Animation integration

**Key Components:**
- `lib/models/grammar_lesson.dart`
- `lib/screens/grammar/grammar_lesson_screen.dart`
- `lib/widgets/grammar_visualizations.dart`

#### 6. Vocabulary Builder with Mnemonics ⭐⭐⭐⭐
**Integration Points:**
- Spaced repetition algorithm
- Memory palace technique
- Image-based flashcards

**Key Components:**
- `lib/models/vocabulary_item.dart`
- `lib/services/vocabulary_service.dart`
- `lib/screens/vocabulary/vocabulary_builder_screen.dart`
- `lib/services/spaced_repetition_service.dart`

### Phase 4: Gamification (Week 9-10)

#### 7. Streak Freeze & Recovery System ⭐⭐⭐⭐
**Integration Points:**
- Extend existing streak system in `UserModel`
- Add streak freeze inventory
- Recovery challenges

**Key Components:**
- `lib/services/streak_service.dart`
- `lib/models/streak_data.dart`
- `lib/screens/streak/streak_recovery_screen.dart`

#### 8. Daily Quests & Challenges ⭐⭐⭐⭐⭐
**Integration Points:**
- Daily quest rotation system
- Integration with XP system
- Special event calendar

**Key Components:**
- `lib/models/daily_quest.dart`
- `lib/services/quest_service.dart`
- `lib/screens/quests/daily_quests_screen.dart`

#### 9. Achievement System Expansion ⭐⭐⭐⭐
**Integration Points:**
- Extend existing achievements in `UserModel`
- Add achievement tiers (Bronze, Silver, Gold, Platinum)
- Achievement showcase on profile

**Key Components:**
- `lib/models/achievement.dart`
- `lib/services/achievement_service.dart`
- `lib/screens/achievements/achievements_screen.dart`

### Phase 5: Social Features (Week 11-12)

#### 10. Friend Activity Feed ⭐⭐⭐⭐
**Integration Points:**
- Extend existing friend system
- Activity timeline
- Like/comment functionality

**Key Components:**
- `lib/models/friend_activity.dart`
- `lib/services/activity_feed_service.dart`
- `lib/screens/social/activity_feed_screen.dart`

#### 11. Live Multiplayer Games ⭐⭐⭐⭐⭐
**Integration Points:**
- Extend existing competition system
- Real-time word races
- Speed vocabulary challenges

**Key Components:**
- `lib/services/live_game_service.dart`
- `lib/screens/competitions/live_games/` (new folder)
- WebSocket integration with existing Supabase realtime

### Phase 6: Content & Media (Week 13-14)

#### 12. Video Content Integration ⭐⭐⭐
**Integration Points:**
- Video player integration
- YouTube API integration
- Subtitle synchronization

**Key Components:**
- `lib/services/video_service.dart`
- `lib/screens/content/video_lessons_screen.dart`

#### 13. Real-World Practice Scenarios ⭐⭐⭐⭐
**Integration Points:**
- Scenario-based dialogues
- Restaurant, travel, job interview simulations
- Role-play conversations

**Key Components:**
- `lib/models/practice_scenario.dart`
- `lib/screens/practice/scenario_practice_screen.dart`

### Phase 7: Analytics & Insights (Week 15-16)

#### 14. Detailed Learning Statistics ⭐⭐⭐⭐
**Integration Points:**
- Extend existing stats tracking
- Weak areas heatmap
- Skill tree visualization

**Key Components:**
- `lib/models/learning_stats.dart`
- `lib/services/analytics_service.dart`
- `lib/screens/stats/learning_statistics_screen.dart`

#### 15. Learning Insights & Reports ⭐⭐⭐⭐
**Integration Points:**
- Weekly/monthly reports
- Progress summaries
- Personalized recommendations

**Key Components:**
- `lib/services/insights_service.dart`
- `lib/screens/insights/insights_screen.dart`

### Phase 8: UI/UX Enhancements (Week 17-18)

#### 16. Dark Mode Enhancement ⭐⭐⭐⭐
**Integration Points:**
- Extend existing `app_theme.dart`
- OLED black mode
- Custom color themes
- Seasonal themes

**Key Components:**
- `lib/theme/theme_provider.dart`
- `lib/screens/settings/theme_settings_screen.dart`

#### 17. Smart Notifications ⭐⭐⭐⭐
**Integration Points:**
- Extend existing `notification_service.dart`
- AI-based optimal study time
- Streak reminders

**Key Components:**
- `lib/services/smart_notification_service.dart`

#### 18. Data Sync & Widget Support ⭐⭐⭐⭐⭐
**Integration Points:**
- Cross-device synchronization
- Home screen widgets
- Lock screen widgets

**Key Components:**
- `lib/services/sync_service.dart`
- `lib/widgets/home_screen_widgets.dart`
- Platform-specific widget implementations

### Phase 9: Community (Week 19-20)

#### 19. Community Forums ⭐⭐⭐
**Integration Points:**
- Forum structure
- Q&A sections
- Cultural exchange

**Key Components:**
- `lib/models/forum_post.dart`
- `lib/screens/community/forums_screen.dart`
- `lib/services/forum_service.dart`

## Database Schema Additions

### New Tables

```sql
-- Learning Content
lessons (id, course_id, title, content, difficulty, prerequisites, estimated_duration, type)
vocabulary (id, word, translation, pronunciation, example_sentences, mnemonic, image_url, audio_url)
grammar_rules (id, title, explanation, visual_diagram, examples, exercises)
stories (id, title, content, difficulty, cultural_notes, choices, endings)

-- User Learning Data
user_lessons (id, user_id, lesson_id, progress, completed, score, attempts, last_accessed)
user_vocabulary (id, user_id, vocab_id, mastery_level, next_review, review_count, ease_factor)
user_progress (id, user_id, category, subcategory, score, total_questions, correct_answers)

-- Gamification
daily_quests (id, user_id, date, quests, completed_quests, claimed_rewards)
quests (id, title, description, type, requirement, reward_xp, reward_gems)
achievements (id, user_id, achievement_id, unlocked_at, tier)
achievement_definitions (id, title, description, category, tiers, icon)
streak_freezes (id, user_id, count, last_used)
streak_recovery (id, user_id, recovery_date, challenge_completed)

-- AI & Analytics
ai_conversations (id, user_id, session_id, message, response, context, timestamp)
learning_analytics (id, user_id, date, study_time, words_learned, accuracy_rate, weak_areas)
pronunciation_attempts (id, user_id, word, audio_url, score, feedback, timestamp)

-- Social Activity
friend_activities (id, user_id, activity_type, activity_data, timestamp)
activity_likes (id, activity_id, user_id, timestamp)
activity_comments (id, activity_id, user_id, comment, timestamp)

-- Practice Scenarios
scenarios (id, title, category, difficulty, dialogues, cultural_tips, vocabulary)
scenario_attempts (id, user_id, scenario_id, score, completed_at, feedback)

-- Content
videos (id, title, description, video_url, thumbnail, duration, difficulty, category)
video_progress (id, user_id, video_id, progress, completed, timestamp)

-- Forums
forum_categories (id, name, description, icon, language)
forum_posts (id, category_id, user_id, title, content, tags, likes_count, replies_count)
forum_replies (id, post_id, user_id, content, parent_id, likes_count)
```

## Dependencies to Add

```yaml
dependencies:
  # AI & ML
  google_generative_ai: ^0.4.0
  
  # Speech & Audio
  speech_to_text: ^6.6.0
  flutter_tts: ^4.0.0
  record: ^5.1.0
  just_audio: ^0.9.38
  audio_session: ^0.1.21
  
  # Video
  video_player: ^2.9.1
  chewie: ^1.8.1
  youtube_player_flutter: ^9.0.1
  
  # Widgets
  home_widget: ^0.6.0
  
  # Charts & Visualization
  fl_chart: ^0.65.0  # Already present
  graphview: ^1.2.0  # For skill trees
  
  # Calendar & Scheduling
  table_calendar: ^3.1.2
  
  # Rich Text & Markdown
  flutter_markdown: ^0.7.3
  flutter_html: ^3.0.0-beta.2
  
  # Date/Time utilities
  jiffy: ^6.3.1
```

## File Structure Additions

```
lib/
├── models/
│   ├── lesson_model.dart
│   ├── vocabulary_item.dart
│   ├── grammar_lesson.dart
│   ├── story_model.dart
│   ├── daily_quest.dart
│   ├── achievement.dart
│   ├── pronunciation_result.dart
│   ├── learning_stats.dart
│   ├── friend_activity.dart
│   ├── practice_scenario.dart
│   └── ai_conversation.dart
├── services/
│   ├── learning_path_service.dart
│   ├── ai_tutor_service.dart
│   ├── pronunciation_service.dart
│   ├── speech_recognition_service.dart
│   ├── vocabulary_service.dart
│   ├── spaced_repetition_service.dart
│   ├── quest_service.dart
│   ├── achievement_service.dart
│   ├── streak_service.dart
│   ├── activity_feed_service.dart
│   ├── live_game_service.dart
│   ├── story_service.dart
│   ├── grammar_service.dart
│   ├── analytics_service.dart
│   ├── insights_service.dart
│   ├── video_service.dart
│   ├── scenario_service.dart
│   ├── forum_service.dart
│   ├── theme_service.dart
│   ├── smart_notification_service.dart
│   └── sync_service.dart
├── providers/
│   ├── learning_provider.dart
│   ├── ai_tutor_provider.dart
│   ├── vocabulary_provider.dart
│   ├── quest_provider.dart
│   ├── achievement_provider.dart
│   ├── activity_feed_provider.dart
│   ├── analytics_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── learning/
│   │   ├── learning_path_screen.dart
│   │   ├── lesson_screen.dart
│   │   └── lesson_completion_screen.dart
│   ├── vocabulary/
│   │   ├── vocabulary_builder_screen.dart
│   │   ├── flashcard_screen.dart
│   │   └── vocabulary_review_screen.dart
│   ├── grammar/
│   │   ├── grammar_lesson_screen.dart
│   │   └── grammar_exercise_screen.dart
│   ├── stories/
│   │   ├── stories_library_screen.dart
│   │   └── story_player_screen.dart
│   ├── pronunciation/
│   │   ├── pronunciation_practice_screen.dart
│   │   └── pronunciation_results_screen.dart
│   ├── ai_tutor/
│   │   └── ai_tutor_chat_screen.dart
│   ├── quests/
│   │   └── daily_quests_screen.dart
│   ├── achievements/
│   │   ├── achievements_screen.dart
│   │   └── achievement_detail_screen.dart
│   ├── streak/
│   │   └── streak_recovery_screen.dart
│   ├── stats/
│   │   ├── learning_statistics_screen.dart
│   │   └── skill_tree_screen.dart
│   ├── insights/
│   │   └── insights_screen.dart
│   ├── practice/
│   │   ├── scenarios_screen.dart
│   │   └── scenario_practice_screen.dart
│   ├── content/
│   │   ├── video_lessons_screen.dart
│   │   └── video_player_screen.dart
│   ├── community/
│   │   ├── forums_screen.dart
│   │   ├── forum_posts_screen.dart
│   │   └── forum_post_detail_screen.dart
│   └── social/
│       └── activity_feed_screen.dart
├── widgets/
│   ├── learning/
│   ├── vocabulary/
│   ├── grammar/
│   ├── pronunciation/
│   ├── common/
│   ├── home_screen_widgets.dart
│   └── grammar_visualizations.dart
└── utils/
    ├── spaced_repetition_algorithm.dart
    ├── adaptive_difficulty_calculator.dart
    └── pronunciation_scorer.dart
```

## Implementation Timeline

**Week 1-2:** Foundation (Dependencies, Database Schema)
**Week 3-5:** Core AI Features (Learning Path, AI Tutor, Pronunciation)
**Week 6-8:** Learning Content (Stories, Grammar, Vocabulary)
**Week 9-10:** Gamification (Quests, Achievements, Streaks)
**Week 11-12:** Social Features (Activity Feed, Live Games)
**Week 13-14:** Content & Media (Videos, Scenarios)
**Week 15-16:** Analytics & Insights
**Week 17-18:** UI/UX (Dark Mode, Notifications, Widgets)
**Week 19-20:** Community & Forums
**Week 21-22:** Testing, Optimization, Bug Fixes
**Week 23-24:** Polish, Documentation, Deployment

## Success Metrics

- **User Engagement:** Daily active users increase by 40%
- **Retention:** 30-day retention rate improvement to 60%
- **Learning Effectiveness:** Average lesson completion rate of 85%
- **Gamification:** 70% of users participate in daily quests
- **AI Features:** 50% of premium users use AI tutor weekly
- **Social:** 40% of users connect with friends
- **Performance:** App launch time < 2 seconds, smooth 60fps animations

## Risk Mitigation

1. **AI API Costs:** Implement rate limiting and caching
2. **Audio/Video Storage:** Use CDN for media files
3. **Real-time Performance:** Optimize WebSocket connections
4. **Offline Support:** Implement robust caching strategy
5. **Privacy:** Ensure GDPR compliance for AI conversations
6. **Scalability:** Design database indexes for high query volumes

## Next Steps

1. Review and approve integration plan
2. Set up development environments
3. Begin Phase 1 implementation
4. Weekly progress reviews
5. User testing after each phase
6. Iterative improvements based on feedback
