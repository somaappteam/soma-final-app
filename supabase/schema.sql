# Supabase Database Schema

This document describes the database tables required for the Soma app.

## Tables

### 1. users
Main user profile table managed by Supabase Auth.

```sql
create table users (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  username text unique not null,
  display_name text,
  avatar_url text,
  bio text,
  native_language text default 'en',
  learning_languages text[] default '{}',
  total_xp integer default 0,
  current_level integer default 1,
  streak_days integer default 0,
  subscription_tier text default 'free',
  subscription_expiry timestamptz,
  is_premium boolean default false,
  is_active boolean default true,
  privacy_level text default 'public',
  total_games_played integer default 0,
  total_games_won integer default 0,
  total_friends integer default 0,
  rank integer default 0,
  country text,
  last_active_at timestamptz,
  achievements text[],
  settings jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

### 2. competitions
Stores online competition/game sessions.

```sql
create table competitions (
  id uuid default uuid_generate_v4() primary key,
  host_id uuid references users(id) not null,
  host_name text not null,
  host_avatar_url text,
  title text not null,
  description text,
  game_type text not null,
  language text not null,
  difficulty text not null,
  max_players integer not null,
  current_players integer default 1,
  status text default 'waiting',
  scheduled_start timestamptz not null,
  started_at timestamptz,
  ended_at timestamptz,
  duration_minutes integer not null,
  is_private boolean default false,
  invite_code text,
  is_premium_only boolean default false,
  entry_fee integer default 0,
  prize_xp integer default 100,
  allowed_categories text[],
  game_settings jsonb,
  allow_spectators boolean default false,
  spectator_count integer default 0,
  chat_room_id uuid,
  created_at timestamptz default now()
);
```

### 3. competition_players
Links users to competitions they joined.

```sql
create table competition_players (
  competition_id uuid references competitions(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  username text not null,
  avatar_url text,
  joined_at timestamptz default now(),
  score integer default 0,
  correct_answers integer default 0,
  wrong_answers integer default 0,
  streak integer default 0,
  is_host boolean default false,
  is_ready boolean default false,
  is_active boolean default true,
  last_active_at timestamptz,
  status text,
  primary key (competition_id, user_id)
);
```

### 4. friends
Manages friend relationships.

```sql
create table friends (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references users(id) on delete cascade,
  friend_id uuid references users(id) on delete cascade,
  friend_username text not null,
  friend_display_name text,
  friend_avatar_url text,
  created_at timestamptz default now(),
  status text default 'pending',
  accepted_at timestamptz,
  is_favorite boolean default false,
  is_muted boolean default false,
  nickname text,
  last_interaction_at timestamptz,
  unique(user_id, friend_id)
);
```

### 5. friend_requests
Stores pending friend requests.

```sql
create table friend_requests (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references users(id) on delete cascade,
  sender_username text not null,
  sender_display_name text,
  sender_avatar_url text,
  receiver_id uuid references users(id) on delete cascade,
  created_at timestamptz default now(),
  status text default 'pending',
  message text,
  responded_at timestamptz
);
```

### 6. conversations
Manages direct message conversations.

```sql
create table conversations (
  id uuid default uuid_generate_v4() primary key,
  participant1_id uuid references users(id) on delete cascade,
  participant2_id uuid references users(id) on delete cascade,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  last_message_id uuid,
  unread_count_p1 integer default 0,
  unread_count_p2 integer default 0,
  is_archived_p1 boolean default false,
  is_archived_p2 boolean default false,
  is_muted_p1 boolean default false,
  is_muted_p2 boolean default false,
  participant1_deleted boolean default false,
  participant2_deleted boolean default false,
  unique(participant1_id, participant2_id)
);
```

### 7. messages
Stores chat messages.

```sql
create table messages (
  id uuid default uuid_generate_v4() primary key,
  conversation_id uuid references conversations(id) on delete cascade,
  sender_id uuid references users(id) on delete cascade,
  sender_username text not null,
  sender_avatar_url text,
  content text not null,
  created_at timestamptz default now(),
  is_read boolean default false,
  read_at timestamptz,
  is_deleted boolean default false,
  is_edited boolean default false,
  edited_at timestamptz,
  reply_to_message_id uuid references messages(id),
  reply_to_content text
);
```

### 8. notifications
User notification center.

```sql
create table notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  created_at timestamptz default now(),
  is_read boolean default false,
  read_at timestamptz,
  is_archived boolean default false,
  data jsonb,
  image_url text,
  action_url text,
  sender_id uuid references users(id),
  sender_name text,
  sender_avatar_url text
);
```

### 9. notification_preferences
User notification settings.

```sql
create table notification_preferences (
  user_id uuid references users(id) on delete cascade primary key,
  game_invites boolean default true,
  friend_requests boolean default true,
  messages boolean default true,
  game_started boolean default true,
  game_ended boolean default true,
  achievements boolean default true,
  leaderboard boolean default true,
  daily_reminders boolean default true,
  app_updates boolean default true,
  promotional boolean default true,
  email_notifications boolean default true,
  push_notifications boolean default true,
  in_app_notifications boolean default true,
  updated_at timestamptz default now()
);
```

### 10. subscriptions
Premium subscription management.

```sql
create table subscriptions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references users(id) on delete cascade,
  tier text not null,
  start_date timestamptz default now(),
  expiry_date timestamptz not null,
  is_active boolean default true,
  will_renew boolean default false,
  platform text,
  transaction_id text,
  created_at timestamptz default now()
);
```

### 11. game_invites
Stores game invitations between users.

```sql
create table game_invites (
  id uuid default uuid_generate_v4() primary key,
  competition_id uuid references competitions(id) on delete cascade,
  inviter_id uuid references users(id) on delete cascade,
  inviter_name text not null,
  inviter_avatar_url text,
  invitee_id uuid references users(id) on delete cascade,
  created_at timestamptz default now(),
  status text default 'pending',
  responded_at timestamptz,
  competition_title text
);
```

### 12. blocked_users
Manages blocked users.

```sql
create table blocked_users (
  id uuid default uuid_generate_v4() primary key,
  blocker_id uuid references users(id) on delete cascade,
  blocked_id uuid references users(id) on delete cascade,
  blocked_username text not null,
  blocked_avatar_url text,
  blocked_at timestamptz default now(),
  reason text,
  unique(blocker_id, blocked_id)
);
```

### 13. user_courses
Manages user language courses.

```sql
create table user_courses (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references users(id) on delete cascade,
  native_language text not null,
  native_language_name text not null,
  native_language_flag text not null,
  target_language text not null,
  target_language_name text not null,
  target_language_flag text not null,
  current_level integer default 1,
  total_xp integer default 0,
  progress double precision default 0.0,
  is_active boolean default false,
  created_at timestamptz default now(),
  last_accessed_at timestamptz default now(),
  unique(user_id, native_language, target_language)
);
```

## Row Level Security (RLS)

Enable RLS on all tables:

```sql
alter table users enable row level security;
alter table competitions enable row level security;
alter table competition_players enable row level security;
alter table friends enable row level security;
alter table friend_requests enable row level security;
alter table conversations enable row level security;
alter table messages enable row level security;
alter table notifications enable row level security;
alter table notification_preferences enable row level security;
alter table subscriptions enable row level security;
alter table game_invites enable row level security;
alter table blocked_users enable row level security;
alter table user_courses enable row level security;
```

## Indexes

```sql
create index idx_competitions_status on competitions(status);
create index idx_competitions_language on competitions(language);
create index idx_friends_user_id on friends(user_id);
create index idx_friend_requests_receiver on friend_requests(receiver_id);
create index idx_messages_conversation on messages(conversation_id);
create index idx_notifications_user on notifications(user_id, created_at desc);
create index idx_game_invites_invitee on game_invites(invitee_id, status);
create index idx_user_courses_user on user_courses(user_id, last_accessed_at desc);
```

## Row Level Security Policies

```sql
-- User Courses policies
CREATE POLICY "Users can view their own courses" ON public.user_courses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own courses" ON public.user_courses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own courses" ON public.user_courses
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own courses" ON public.user_courses
  FOR DELETE USING (auth.uid() = user_id);
```

## Functions

```sql
-- Auto-update updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Apply to tables
create trigger users_updated_at before update on users
  for each row execute function update_updated_at_column();

-- ============================================
-- LANGUAGE LEARNING EXTENSION
-- ============================================
-- Comprehensive schema for grammar, stories, AI conversations, 
-- community features, analytics, achievements, and 15+ practice modes

-- ============================================
-- CORE USER EXTENSIONS
-- ============================================

-- User Learning Statistics
CREATE TABLE user_learning_stats (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    -- Vocabulary Stats
    total_words_learned integer default 0,
    total_words_mastered integer default 0,
    words_in_review integer default 0,
    
    -- Time Stats
    total_study_time_minutes integer default 0,
    daily_average_minutes float default 0,
    
    -- Practice Stats
    total_sessions_completed integer default 0,
    correct_answer_rate float default 0,
    
    -- Grammar Stats
    grammar_skills_unlocked integer default 0,
    grammar_lessons_completed integer default 0,
    
    -- Reading Stats
    stories_completed integer default 0,
    total_words_read integer default 0,
    
    -- Listening Stats
    podcasts_completed integer default 0,
    total_listening_minutes integer default 0,
    
    updated_at timestamptz default now(),
    
    unique(user_id)
);

-- User Settings Extension
CREATE TABLE user_learning_settings (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    -- Study Settings
    daily_goal_minutes integer default 15,
    words_per_session integer default 10,
    auto_advance boolean default true,
    show_romanization boolean default false,
    font_size text default 'medium',
    
    -- Difficulty Settings
    difficulty_level text default 'adaptive',
    spaced_repetition_enabled boolean default true,
    
    -- Theme Settings
    theme_mode text default 'system',
    primary_color text default '#4DB6AC',
    
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    
    unique(user_id)
);

-- ============================================
-- VOCABULARY SYSTEM
-- ============================================

-- Vocabulary Words
CREATE TABLE vocabulary_words (
    id uuid default uuid_generate_v4() primary key,
    word text not null,
    translation text not null,
    pronunciation text,
    part_of_speech text,
    difficulty_level integer default 1,
    language text not null,
    
    -- Metadata
    example_sentence text,
    example_translation text,
    tags text[],
    topic text,
    
    -- Media
    audio_url text,
    image_url text,
    
    created_at timestamptz default now()
);

-- User Vocabulary Progress (Spaced Repetition)
CREATE TABLE user_vocabulary_progress (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    word_id uuid references vocabulary_words(id) on delete cascade,
    
    -- SRS Data
    status text default 'new',
    interval integer default 0,
    repetition_count integer default 0,
    ease_factor float default 2.5,
    
    -- Timing
    last_reviewed timestamptz,
    next_review timestamptz,
    first_seen timestamptz default now(),
    mastered_at timestamptz,
    
    -- Stats
    correct_count integer default 0,
    incorrect_count integer default 0,
    streak_count integer default 0,
    
    unique(user_id, word_id)
);

-- Courses
CREATE TABLE courses (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    description text,
    language text not null,
    difficulty_level text not null,
    category text,
    order_index integer default 0,
    is_premium boolean default false,
    thumbnail_url text,
    created_at timestamptz default now()
);

-- Lessons within Courses
CREATE TABLE lessons (
    id uuid default uuid_generate_v4() primary key,
    course_id uuid references courses(id) on delete cascade,
    title text not null,
    description text,
    order_index integer default 0,
    estimated_duration_minutes integer default 5,
    xp_reward integer default 10,
    content jsonb,
    created_at timestamptz default now()
);

-- User Lesson Progress
CREATE TABLE user_lesson_progress (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    lesson_id uuid references lessons(id) on delete cascade,
    status text default 'locked',
    progress_percent integer default 0,
    started_at timestamptz,
    completed_at timestamptz,
    xp_earned integer default 0,
    
    unique(user_id, lesson_id)
);

-- ============================================
-- GRAMMAR SYSTEM
-- ============================================

-- Grammar Skills/Topics
CREATE TABLE grammar_skills (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    description text,
    language text not null,
    difficulty_level integer default 1,
    category text,
    parent_skill_id uuid references grammar_skills(id),
    order_index integer default 0,
    xp_reward integer default 20,
    icon_name text,
    color_hex text,
    created_at timestamptz default now()
);

-- Grammar Lessons Content
CREATE TABLE grammar_lessons (
    id uuid default uuid_generate_v4() primary key,
    skill_id uuid references grammar_skills(id) on delete cascade,
    title text not null,
    content jsonb not null,
    order_index integer default 0,
    created_at timestamptz default now()
);

-- Grammar Exercises
CREATE TABLE grammar_exercises (
    id uuid default uuid_generate_v4() primary key,
    skill_id uuid references grammar_skills(id) on delete cascade,
    lesson_id uuid references grammar_lessons(id) on delete cascade,
    exercise_type text not null,
    question text not null,
    correct_answer text not null,
    options jsonb,
    explanation text,
    difficulty integer default 1,
    order_index integer default 0,
    created_at timestamptz default now()
);

-- User Grammar Progress
CREATE TABLE user_grammar_progress (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    skill_id uuid references grammar_skills(id) on delete cascade,
    
    status text default 'locked',
    progress_percent integer default 0,
    lessons_completed integer default 0,
    total_lessons integer default 0,
    exercises_completed integer default 0,
    correct_exercises integer default 0,
    
    unlocked_at timestamptz,
    started_at timestamptz,
    completed_at timestamptz,
    last_practiced timestamptz,
    
    unique(user_id, skill_id)
);

-- ============================================
-- STORIES & READING
-- ============================================

-- Stories
CREATE TABLE stories (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    author text,
    description text,
    language text not null,
    difficulty_level integer default 1,
    genre text,
    content jsonb not null,
    word_count integer default 0,
    estimated_reading_time integer default 5,
    thumbnail_url text,
    audio_url text,
    is_premium boolean default false,
    tags text[],
    created_at timestamptz default now()
);

-- User Story Progress
CREATE TABLE user_story_progress (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    story_id uuid references stories(id) on delete cascade,
    
    status text default 'not_started',
    progress_percent integer default 0,
    current_paragraph integer default 0,
    
    bookmarks jsonb default '[]',
    notes jsonb default '[]',
    
    started_at timestamptz,
    completed_at timestamptz,
    last_read_at timestamptz,
    
    comprehension_score integer,
    time_spent_minutes integer default 0,
    
    unique(user_id, story_id)
);

-- ============================================
-- PODCASTS & LISTENING
-- ============================================

-- Podcast Episodes
CREATE TABLE podcasts (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    description text,
    language text not null,
    difficulty_level integer default 1,
    category text,
    duration_seconds integer default 0,
    audio_url text not null,
    transcript jsonb,
    thumbnail_url text,
    is_premium boolean default false,
    published_at timestamptz,
    created_at timestamptz default now()
);

-- User Podcast Progress
CREATE TABLE user_podcast_progress (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    podcast_id uuid references podcasts(id) on delete cascade,
    
    status text default 'not_started',
    current_position_seconds integer default 0,
    completed boolean default false,
    
    playback_speed float default 1.0,
    listened_segments jsonb default '[]',
    
    started_at timestamptz,
    completed_at timestamptz,
    last_listened_at timestamptz,
    total_listening_time integer default 0,
    
    unique(user_id, podcast_id)
);

-- ============================================
-- AI CONVERSATION
-- ============================================

-- AI Conversation Sessions
CREATE TABLE ai_conversations (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    scenario text not null,
    difficulty_level text default 'intermediate',
    language text not null,
    
    messages jsonb default '[]',
    grammar_corrections jsonb default '[]',
    vocabulary_suggestions jsonb default '[]',
    
    voice_mode_enabled boolean default false,
    
    started_at timestamptz default now(),
    ended_at timestamptz,
    duration_seconds integer,
    
    user_satisfaction integer,
    notes text
);

-- ============================================
-- STUDY SCHEDULE & REMINDERS
-- ============================================

-- Study Schedules
CREATE TABLE study_schedules (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    name text default 'My Study Plan',
    description text,
    
    is_active boolean default true,
    start_date date not null,
    end_date date,
    
    daily_goal_minutes integer default 15,
    days_per_week integer default 5,
    focus_areas jsonb default '["vocabulary", "grammar", "reading"]',
    
    reminder_enabled boolean default true,
    reminder_time time default '09:00:00',
    reminder_days integer[] default ARRAY[1,2,3,4,5,6,0],
    
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Study Sessions (completed sessions)
CREATE TABLE study_sessions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    session_type text not null,
    activity_id uuid,
    
    started_at timestamptz not null,
    ended_at timestamptz,
    duration_minutes integer default 0,
    
    items_studied integer default 0,
    correct_count integer default 0,
    incorrect_count integer default 0,
    xp_earned integer default 0,
    
    notes text,
    created_at timestamptz default now()
);

-- Pomodoro Sessions
CREATE TABLE pomodoro_sessions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    work_duration_minutes integer default 25,
    break_duration_minutes integer default 5,
    
    started_at timestamptz not null,
    ended_at timestamptz,
    completed boolean default false,
    interruptions integer default 0,
    
    notes text,
    created_at timestamptz default now()
);

-- Study Streak History
CREATE TABLE study_streaks (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    date date not null,
    studied boolean default false,
    study_time_minutes integer default 0,
    sessions_count integer default 0,
    
    unique(user_id, date)
);

-- ============================================
-- ACHIEVEMENTS & BADGES
-- ============================================

-- Achievement Definitions
CREATE TABLE achievements (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    description text not null,
    category text not null,
    tier text not null,
    
    icon_name text,
    color_hex text,
    
    requirement_type text not null,
    requirement_value integer not null,
    requirement_context jsonb,
    
    xp_reward integer default 0,
    
    created_at timestamptz default now()
);

-- User Achievements
CREATE TABLE user_achievements (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    achievement_id uuid references achievements(id) on delete cascade,
    
    progress_current integer default 0,
    progress_target integer not null,
    
    unlocked boolean default false,
    unlocked_at timestamptz,
    
    unique(user_id, achievement_id)
);

-- Badges (Special Achievements)
CREATE TABLE badges (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    description text,
    rarity text default 'common',
    icon_name text,
    animation_url text,
    criteria text,
    limited_time boolean default false,
    available_until timestamptz,
    created_at timestamptz default now()
);

-- User Badges
CREATE TABLE user_badges (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    badge_id uuid references badges(id) on delete cascade,
    earned_at timestamptz default now(),
    equipped boolean default false,
    
    unique(user_id, badge_id)
);

-- ============================================
-- COMMUNITY FEATURES
-- ============================================

-- User-Created Decks
CREATE TABLE user_decks (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    title text not null,
    description text,
    language text not null,
    category text,
    
    is_public boolean default false,
    is_official boolean default false,
    
    cards_count integer default 0,
    downloads_count integer default 0,
    rating_average float default 0,
    rating_count integer default 0,
    
    tags text[],
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Deck Cards
CREATE TABLE deck_cards (
    id uuid default uuid_generate_v4() primary key,
    deck_id uuid references user_decks(id) on delete cascade,
    word_id uuid references vocabulary_words(id) on delete cascade,
    user_notes text,
    order_index integer default 0,
    created_at timestamptz default now()
);

-- User Study Notes
CREATE TABLE user_study_notes (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    title text not null,
    content text not null,
    
    related_type text,
    related_id uuid,
    
    tags text[],
    is_public boolean default false,
    likes_count integer default 0,
    
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Community Challenges
CREATE TABLE community_challenges (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    description text,
    
    challenge_type text not null,
    target_value integer not null,
    
    start_date timestamptz not null,
    end_date timestamptz not null,
    
    reward_xp integer default 0,
    reward_badge_id uuid references badges(id),
    
    participants_count integer default 0,
    created_at timestamptz default now()
);

-- Challenge Participants
CREATE TABLE challenge_participants (
    id uuid default uuid_generate_v4() primary key,
    challenge_id uuid references community_challenges(id) on delete cascade,
    user_id uuid references users(id) on delete cascade,
    
    current_progress integer default 0,
    target_value integer not null,
    
    rank integer,
    completed boolean default false,
    completed_at timestamptz,
    
    joined_at timestamptz default now(),
    
    unique(challenge_id, user_id)
);

-- ============================================
-- ANALYTICS & INSIGHTS
-- ============================================

-- User Activity Heatmap Data
CREATE TABLE user_activity_heatmap (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    date date not null,
    
    study_time_minutes integer default 0,
    sessions_count integer default 0,
    xp_earned integer default 0,
    
    unique(user_id, date)
);

-- Weak Areas Tracking
CREATE TABLE user_weak_areas (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    area_type text not null,
    area_id uuid,
    area_name text not null,
    
    accuracy_rate float default 0,
    attempts_count integer default 0,
    last_practiced timestamptz,
    
    priority_level integer default 1,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Practice Mode Performance
CREATE TABLE practice_mode_stats (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    mode_type text not null,
    
    sessions_count integer default 0,
    total_questions integer default 0,
    correct_answers integer default 0,
    average_time_per_question float,
    best_score integer,
    
    last_played timestamptz,
    updated_at timestamptz default now(),
    
    unique(user_id, mode_type)
);

-- ============================================
-- PRACTICE MODES
-- ============================================

-- Speed Review Sessions
CREATE TABLE speed_review_sessions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    duration_seconds integer default 60,
    words_reviewed integer default 0,
    correct_count integer default 0,
    streak_count integer default 0,
    
    started_at timestamptz default now(),
    ended_at timestamptz
);

-- Translation Challenge History
CREATE TABLE translation_challenge_history (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    challenge_type text not null,
    difficulty text not null,
    
    sentences_completed integer default 0,
    accuracy_rate float default 0,
    time_spent_seconds integer default 0,
    
    created_at timestamptz default now()
);

-- Writing Practice Submissions
CREATE TABLE writing_practice_submissions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references users(id) on delete cascade,
    
    prompt text not null,
    user_submission text not null,
    ai_feedback jsonb,
    
    word_count integer,
    grammar_errors_count integer,
    vocabulary_suggestions_count integer,
    overall_score integer,
    
    submitted_at timestamptz default now()
);

-- ============================================
-- INDEXES
-- ============================================

-- Vocabulary indexes
CREATE INDEX idx_vocab_words_language ON vocabulary_words(language);
CREATE INDEX idx_vocab_words_difficulty ON vocabulary_words(difficulty_level);
CREATE INDEX idx_user_vocab_progress_user ON user_vocabulary_progress(user_id);
CREATE INDEX idx_user_vocab_progress_next_review ON user_vocabulary_progress(next_review);
CREATE INDEX idx_user_vocab_progress_status ON user_vocabulary_progress(status);

-- Study session indexes
CREATE INDEX idx_study_sessions_user_date ON study_sessions(user_id, created_at);
CREATE INDEX idx_study_sessions_type ON study_sessions(session_type);

-- Grammar indexes
CREATE INDEX idx_grammar_skills_language ON grammar_skills(language);
CREATE INDEX idx_user_grammar_progress_user ON user_grammar_progress(user_id);

-- Story indexes
CREATE INDEX idx_stories_language_difficulty ON stories(language, difficulty_level);
CREATE INDEX idx_user_story_progress_user ON user_story_progress(user_id);

-- Achievement indexes
CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_unlocked ON user_achievements(unlocked) WHERE unlocked = true;

-- Analytics indexes
CREATE INDEX idx_user_activity_heatmap_user_date ON user_activity_heatmap(user_id, date);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on new tables
ALTER TABLE user_learning_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_learning_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_vocabulary_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_grammar_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_story_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_podcast_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pomodoro_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_study_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_heatmap ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_weak_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE practice_mode_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE speed_review_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE translation_challenge_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE writing_practice_submissions ENABLE ROW LEVEL SECURITY;

-- User learning stats
CREATE POLICY "Users can access own stats" ON user_learning_stats
  FOR ALL USING (auth.uid() = user_id);

-- User settings
CREATE POLICY "Users can access own settings" ON user_learning_settings
  FOR ALL USING (auth.uid() = user_id);

-- Vocabulary progress
CREATE POLICY "Users can access own vocab progress" ON user_vocabulary_progress
  FOR ALL USING (auth.uid() = user_id);

-- Lesson progress
CREATE POLICY "Users can access own lesson progress" ON user_lesson_progress
  FOR ALL USING (auth.uid() = user_id);

-- Grammar progress
CREATE POLICY "Users can access own grammar progress" ON user_grammar_progress
  FOR ALL USING (auth.uid() = user_id);

-- Story progress
CREATE POLICY "Users can access own story progress" ON user_story_progress
  FOR ALL USING (auth.uid() = user_id);

-- Podcast progress
CREATE POLICY "Users can access own podcast progress" ON user_podcast_progress
  FOR ALL USING (auth.uid() = user_id);

-- AI conversations
CREATE POLICY "Users can access own conversations" ON ai_conversations
  FOR ALL USING (auth.uid() = user_id);

-- Study schedules
CREATE POLICY "Users can access own schedules" ON study_schedules
  FOR ALL USING (auth.uid() = user_id);

-- Study sessions
CREATE POLICY "Users can access own sessions" ON study_sessions
  FOR ALL USING (auth.uid() = user_id);

-- Pomodoro sessions
CREATE POLICY "Users can access own pomodoro" ON pomodoro_sessions
  FOR ALL USING (auth.uid() = user_id);

-- Study streaks
CREATE POLICY "Users can access own streaks" ON study_streaks
  FOR ALL USING (auth.uid() = user_id);

-- User achievements
CREATE POLICY "Users can access own achievements" ON user_achievements
  FOR ALL USING (auth.uid() = user_id);

-- User badges
CREATE POLICY "Users can access own badges" ON user_badges
  FOR ALL USING (auth.uid() = user_id);

-- User decks
CREATE POLICY "Users can view public decks" ON user_decks
  FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY "Users can manage own decks" ON user_decks
  FOR ALL USING (auth.uid() = user_id);

-- Study notes
CREATE POLICY "Users can view public notes" ON user_study_notes
  FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY "Users can manage own notes" ON user_study_notes
  FOR ALL USING (auth.uid() = user_id);

-- Challenge participants
CREATE POLICY "Users can view challenge participants" ON challenge_participants
  FOR SELECT USING (true);
CREATE POLICY "Users can manage own participation" ON challenge_participants
  FOR ALL USING (auth.uid() = user_id);

-- Activity heatmap
CREATE POLICY "Users can access own heatmap" ON user_activity_heatmap
  FOR ALL USING (auth.uid() = user_id);

-- Weak areas
CREATE POLICY "Users can access own weak areas" ON user_weak_areas
  FOR ALL USING (auth.uid() = user_id);

-- Practice stats
CREATE POLICY "Users can access own practice stats" ON practice_mode_stats
  FOR ALL USING (auth.uid() = user_id);

-- Speed review sessions
CREATE POLICY "Users can access own speed reviews" ON speed_review_sessions
  FOR ALL USING (auth.uid() = user_id);

-- Translation history
CREATE POLICY "Users can access own translation history" ON translation_challenge_history
  FOR ALL USING (auth.uid() = user_id);

-- Writing practice
CREATE POLICY "Users can access own writing" ON writing_practice_submissions
  FOR ALL USING (auth.uid() = user_id);

-- Public tables (readable by all authenticated users)
CREATE POLICY "Authenticated users can view vocabulary" ON vocabulary_words FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view courses" ON courses FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view lessons" ON lessons FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view grammar skills" ON grammar_skills FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view grammar lessons" ON grammar_lessons FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view grammar exercises" ON grammar_exercises FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view stories" ON stories FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view podcasts" ON podcasts FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view achievements" ON achievements FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view badges" ON badges FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view challenges" ON community_challenges FOR SELECT USING (true);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Calculate streak function
CREATE OR REPLACE FUNCTION calculate_user_streak(user_uuid uuid)
RETURNS integer AS $$
DECLARE
    current_streak integer := 0;
    check_date date := CURRENT_DATE;
    has_studied boolean;
BEGIN
    LOOP
        SELECT studied INTO has_studied
        FROM study_streaks
        WHERE user_id = user_uuid AND date = check_date;
        
        IF has_studied IS NULL OR has_studied = false THEN
            EXIT;
        END IF;
        
        current_streak := current_streak + 1;
        check_date := check_date - INTERVAL '1 day';
    END LOOP;
    
    RETURN current_streak;
END;
$$ LANGUAGE plpgsql;

-- Update user streak after study session
CREATE OR REPLACE FUNCTION update_user_streak()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO study_streaks (user_id, date, studied, study_time_minutes, sessions_count)
    VALUES (NEW.user_id, CURRENT_DATE, true, NEW.duration_minutes, 1)
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        studied = true,
        study_time_minutes = study_streaks.study_time_minutes + NEW.duration_minutes,
        sessions_count = study_streaks.sessions_count + 1;
    
    -- Update user profile streak
    UPDATE users
    SET streak_days = calculate_user_streak(NEW.user_id),
        last_active_at = CURRENT_DATE
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_streak_after_session AFTER INSERT ON study_sessions
    FOR EACH ROW EXECUTE FUNCTION update_user_streak();

-- Update triggers
CREATE TRIGGER user_learning_stats_updated_at BEFORE UPDATE ON user_learning_stats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER user_learning_settings_updated_at BEFORE UPDATE ON user_learning_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER study_schedules_updated_at BEFORE UPDATE ON study_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER user_decks_updated_at BEFORE UPDATE ON user_decks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER user_study_notes_updated_at BEFORE UPDATE ON user_study_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER user_weak_areas_updated_at BEFORE UPDATE ON user_weak_areas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED DATA
-- ============================================

-- Sample Achievements
INSERT INTO achievements (title, description, category, tier, icon_name, color_hex, requirement_type, requirement_value, xp_reward) VALUES
('First Steps', 'Complete your first lesson', 'beginner', 'bronze', 'footprints', '#CD7F32', 'count', 1, 10),
('Week Warrior', 'Maintain a 7-day study streak', 'streak', 'bronze', 'fire', '#CD7F32', 'streak', 7, 50),
('Century Club', 'Learn 100 vocabulary words', 'vocabulary', 'silver', 'book', '#C0C0C0', 'count', 100, 100),
('Grammar Master', 'Complete 10 grammar lessons', 'grammar', 'silver', 'graduation-cap', '#C0C0C0', 'count', 10, 150),
('Speed Demon', 'Complete a speed review with 95% accuracy', 'explorer', 'gold', 'zap', '#FFD700', 'accuracy', 95, 200),
('Polyglot', 'Study for 30 days straight', 'streak', 'gold', 'globe', '#FFD700', 'streak', 30, 500),
('Bookworm', 'Read 50 stories to completion', 'explorer', 'platinum', 'book-open', '#E5E4E2', 'count', 50, 1000),
('Century Streak', 'Maintain a 100-day study streak', 'streak', 'platinum', 'flame', '#E5E4E2', 'streak', 100, 2000),
('Legendary Learner', 'Reach 10,000 XP', 'mastery', 'legendary', 'crown', '#B9F2FF', 'count', 10000, 5000);

-- Sample Badges
INSERT INTO badges (title, description, rarity, icon_name, criteria) VALUES
('Early Bird', 'Study before 8 AM', 'common', 'sunrise', 'Complete a study session before 8:00 AM'),
('Night Owl', 'Study after 10 PM', 'common', 'moon', 'Complete a study session after 10:00 PM'),
('Perfectionist', 'Get 100% on 10 lessons in a row', 'rare', 'target', 'Complete 10 lessons with perfect scores'),
('Social Butterfly', 'Add 5 language exchange partners', 'rare', 'users', 'Connect with 5 language partners'),
('Deck Creator', 'Create a deck with 50+ cards that gets 100+ downloads', 'epic', 'layers', 'Create a popular vocabulary deck'),
('Challenge Champion', 'Win first place in a community challenge', 'legendary', 'trophy', 'Rank #1 in any challenge');

-- Sample Courses
INSERT INTO courses (title, description, language, difficulty_level, category, order_index) VALUES
('Spanish Basics', 'Learn the fundamentals of Spanish', 'es', 'beginner', 'basics', 1),
('Spanish Grammar', 'Master Spanish grammar rules', 'es', 'intermediate', 'grammar', 2),
('Business Spanish', 'Professional Spanish vocabulary', 'es', 'advanced', 'business', 3),
('French Essentials', 'Essential French for beginners', 'fr', 'beginner', 'basics', 1),
('French Conversation', 'Practice everyday French', 'fr', 'intermediate', 'conversation', 2);
```
