# Soma - Environment Configuration

## Setup Instructions

1. Create a `.env` file in the root directory with the following variables:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

2. For production builds, set these as environment variables:

```bash
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_ANON_KEY=your-anon-key-here
```

## Getting Supabase Credentials

1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project
3. Go to Project Settings > API
4. Copy the URL and anon/public key

## Features Enabled

- **Authentication**: Email/password, Google OAuth
- **Database**: PostgreSQL with real-time subscriptions
- **Storage**: For user avatars and attachments
- **Edge Functions**: For server-side logic

## Important Notes

- Never commit the `.env` file to version control
- Use different credentials for development and production
- Enable Row Level Security (RLS) on all tables
- Set up proper RLS policies for data protection
