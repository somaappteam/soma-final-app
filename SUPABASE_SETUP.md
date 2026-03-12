# Supabase Setup Guide - Soma

## ✅ Your Supabase Project is Connected!

**Project URL:** https://imyjjyhrqhgyvgpiccbv.supabase.co

## Step 1: Set Up Database Tables

You need to run the SQL schema in your Supabase project. Here's how:

### Method 1: SQL Editor (Recommended)

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Select your project (imyjjyhrqhgyvgpiccbv)
3. Go to **SQL Editor** (left sidebar)
4. Click **New query**
5. Copy and paste the entire SQL from `supabase/schema.sql`
6. Click **Run** button

### Method 2: Table Editor

If you prefer manual creation, create these tables one by one:

#### 1. Users Table (Handled by Supabase Auth)
Supabase Auth automatically creates the `users` table when someone signs up. However, you need to create a trigger to sync auth users with your public.users table.

Run this SQL in the SQL Editor:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS public.users (
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

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own data" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Auto-create user on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, username, native_language, learning_languages)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'native_language', 'en'),
    COALESCE(ARRAY(SELECT jsonb_array_elements_text(NEW.raw_user_meta_data->'learning_languages')), ARRAY['es'])
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

#### 2. Essential Tables (Run All at Once)

```sql
-- Competitions Table
CREATE TABLE IF NOT EXISTS public.competitions (
  id uuid default uuid_generate_v4() primary key,
  host_id uuid references public.users(id) on delete cascade,
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
  created_at timestamptz default now()
);

-- Competition Players Table
CREATE TABLE IF NOT EXISTS public.competition_players (
  competition_id uuid references public.competitions(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
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
  primary key (competition_id, user_id)
);

-- Friends Table
CREATE TABLE IF NOT EXISTS public.friends (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade,
  friend_id uuid references public.users(id) on delete cascade,
  friend_username text not null,
  friend_avatar_url text,
  created_at timestamptz default now(),
  status text default 'pending',
  accepted_at timestamptz,
  is_favorite boolean default false,
  is_muted boolean default false,
  unique(user_id, friend_id)
);

-- Friend Requests Table
CREATE TABLE IF NOT EXISTS public.friend_requests (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references public.users(id) on delete cascade,
  sender_username text not null,
  sender_avatar_url text,
  receiver_id uuid references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  status text default 'pending',
  message text,
  responded_at timestamptz
);

-- Conversations Table
CREATE TABLE IF NOT EXISTS public.conversations (
  id uuid default uuid_generate_v4() primary key,
  participant1_id uuid references public.users(id) on delete cascade,
  participant2_id uuid references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unread_count_p1 integer default 0,
  unread_count_p2 integer default 0,
  is_archived_p1 boolean default false,
  is_archived_p2 boolean default false,
  unique(participant1_id, participant2_id)
);

-- Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid default uuid_generate_v4() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id uuid references public.users(id) on delete cascade,
  sender_username text not null,
  content text not null,
  created_at timestamptz default now(),
  is_read boolean default false,
  is_deleted boolean default false
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  created_at timestamptz default now(),
  is_read boolean default false,
  data jsonb
);

-- Game Invites Table
CREATE TABLE IF NOT EXISTS public.game_invites (
  id uuid default uuid_generate_v4() primary key,
  competition_id uuid references public.competitions(id) on delete cascade,
  inviter_id uuid references public.users(id) on delete cascade,
  inviter_name text not null,
  invitee_id uuid references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  status text default 'pending',
  competition_title text
);

-- Enable RLS on all tables
ALTER TABLE public.competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.competition_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_invites ENABLE ROW LEVEL SECURITY;

-- Enable Realtime
ALTER TABLE public.competitions REPLICA IDENTITY FULL;
ALTER TABLE public.competition_players REPLICA IDENTITY FULL;
ALTER TABLE public.messages REPLICA IDENTITY FULL;
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
```

## Step 2: Configure Row Level Security (RLS) Policies

After creating tables, add these policies:

```sql
-- Competitions policies
CREATE POLICY "Competitions are viewable by everyone" ON public.competitions
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create competitions" ON public.competitions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Competition players policies
CREATE POLICY "Players can view competition data" ON public.competition_players
  FOR SELECT USING (true);

-- Friends policies
CREATE POLICY "Users can view their friends" ON public.friends
  FOR SELECT USING (auth.uid() = user_id);

-- Messages policies
CREATE POLICY "Users can view messages in their conversations" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
      AND (c.participant1_id = auth.uid() OR c.participant2_id = auth.uid())
    )
  );

-- Notifications policies
CREATE POLICY "Users can view their notifications" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());
```

## Step 3: Enable Realtime

1. Go to **Database** → **Replication**
2. Enable **Realtime** for these tables:
   - competitions
   - competition_players
   - messages
   - notifications

## Step 4: Configure Authentication

### Email Authentication (Already Enabled)
Your Supabase project has email authentication enabled by default.

### Google OAuth (Optional)
To enable Google Sign-In:

1. Go to **Authentication** → **Providers**
2. Find **Google** and enable it
3. Add your Google OAuth credentials (requires Google Cloud Console setup)

## Step 5: Test the Connection

Run this test query in SQL Editor:

```sql
-- Test if tables are created
SELECT table_name 
FROM information.tables 
WHERE table_schema = 'public';
```

You should see: users, competitions, competition_players, friends, etc.

## Step 6: Run the App

Now that Supabase is configured:

```bash
flutter clean
flutter pub get
flutter run
```

## 📱 App Features Enabled

With this setup, your app now supports:

✅ **Authentication**: Email/password and Google OAuth  
✅ **Guest Mode**: Offline play with local storage  
✅ **Online Competitions**: Create/join real-time games  
✅ **Friends System**: Add friends, send requests  
✅ **Messaging**: Real-time chat between friends  
✅ **Notifications**: Push and in-app notifications  
✅ **Leaderboards**: Global and friends rankings  
✅ **Premium Features**: Subscription tiers and benefits  

## 🔧 Troubleshooting

### "Failed to initialize Supabase"
- Check your internet connection
- Verify the credentials in `lib/config/environment.dart`
- Ensure your Supabase project is active

### "Table not found" errors
- Run the SQL schema in the SQL Editor
- Check that all tables were created successfully
- Verify RLS policies are set

### "Permission denied" errors
- Ensure RLS policies are properly configured
- Check that the user is authenticated
- Verify table permissions

## 🚀 Next Steps

1. **Test Authentication**: Try signing up with email
2. **Create First Competition**: Host a game to test competitions
3. **Add Friends**: Test the social features
4. **Send Messages**: Verify real-time messaging
5. **Check Notifications**: Test notification system

## 📞 Support

If you encounter issues:
1. Check Supabase Dashboard logs
2. Review the SQL schema in `supabase/schema.sql`
3. Check the app logs in Flutter console

**Your app is now ready to use with Supabase!** 🎉
