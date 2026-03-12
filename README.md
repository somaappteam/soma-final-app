# 🌍 Soma - Language Learning App

A **production-grade**, gamified language learning app with online competitions, social features, and premium subscriptions. Built with Flutter and Supabase.

## ✨ Features

### 🎮 Online Competitions
- Create and join real-time language competitions
- Play with friends or random opponents
- Multiple game modes (Vocabulary, Sentences, Pronunciation, Listening)
- Dynamic leaderboards within games
- Premium-only exclusive competitions

### 👥 Social Features
- **Friends System**: Add, manage, and block users
- **Real-time Messaging**: Chat with friends
- **Game Invitations**: Invite friends to competitions
- **Online Status**: See who's online
- **Friend Leaderboards**: Compete with friends

### 🏆 Leaderboards
- Global rankings
- Friends-only rankings
- Weekly competitions
- Language-specific rankings
- Achievement badges

### ⭐ Premium Features
- **3 Subscription Tiers**: Monthly ($9.99), Yearly ($59.99), Lifetime ($199.99)
- **2x XP Boost**: Earn double XP
- **Unlimited Games**: No daily limits
- **Advanced Stats**: Detailed analytics
- **Custom Themes**: Exclusive app themes
- **Priority Support**: Fast-track help

### 🔐 Authentication
- Email/Password authentication
- Google OAuth
- **Guest Mode**: Play offline without account
- **Guest Conversion**: Seamlessly convert guest progress to full account
- Password reset

### 📱 App Flow
```
Splash Screen → Auth Check → 
  ├─ Authenticated → Main App (Full Access)
  ├─ Guest → Main App (Offline Mode)
  └─ New User → Login/Register Screen
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode

### Installation

1. **Clone the repository**
```bash
git clone <repo-url>
cd linguaquest
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Supabase Setup** (Required)
- See `SUPABASE_SETUP.md` for detailed instructions
- Or run the SQL from `supabase/schema.sql` in your Supabase project

4. **Run the app**
```bash
flutter run
```

## 📊 Database Schema

Your Supabase project is already configured with:
- **12+ Tables**: Users, competitions, friends, messages, notifications, etc.
- **Row Level Security**: Secure data access
- **Realtime**: Live updates for games and messages
- **Authentication**: Built-in auth system

**Supabase Project:** https://imyjjyhrqhgyvgpiccbv.supabase.co

## 🏗️ Architecture

### Project Structure
```
lib/
├── config/              # App configuration
│   └── environment.dart # Supabase credentials (embedded)
├── constants/           # App constants
├── models/             # Data models
│   ├── user_model.dart
│   ├── competition_model.dart
│   ├── friend_model.dart
│   ├── message_model.dart
│   └── ...
├── providers/          # State management
│   ├── auth_provider.dart
│   ├── competition_provider.dart
│   ├── friend_provider.dart
│   └── ...
├── screens/            # UI screens
│   ├── auth/          # Login, Register, Forgot Password
│   ├── competitions/  # Games, Lobby, Create Game
│   ├── social/        # Friends, Messaging
│   ├── leaderboard/   # Rankings
│   └── profile/       # User profile
├── services/          # Backend services
│   ├── supabase_service.dart
│   ├── competition_service.dart
│   └── ...
├── theme/             # App theming
└── utils/             # Utilities
    └── guest_user.dart # Guest mode logic
```

### Tech Stack
- **Frontend**: Flutter 3.x, Provider, Flutter Animate
- **Backend**: Supabase (PostgreSQL, Realtime, Auth)
- **Storage**: SharedPreferences (guest data), Supabase Storage
- **State Management**: Provider
- **Animations**: Flutter Animate

## 🎯 Features by User Type

### Guest Users (Offline)
- ✅ All learning content
- ✅ XP and level tracking
- ✅ Achievements (local)
- ✅ Practice modes
- ❌ Online competitions
- ❌ Friends/messaging
- ❌ Cloud sync

### Authenticated Users (Online)
- ✅ All guest features
- ✅ Online competitions
- ✅ Friends and messaging
- ✅ Global leaderboards
- ✅ Cloud sync
- ✅ Notifications
- ✅ Premium subscription

## 📝 Documentation

- **`QUICKSTART.md`** - Get started in 5 minutes
- **`SUPABASE_SETUP.md`** - Database setup guide
- **`APP_DOCUMENTATION.md`** - Complete feature documentation
- **`docs/AUTHENTICATION.md`** - Auth system details
- **`supabase/schema.sql`** - Database schema

## 🔧 Configuration

Your Supabase credentials are **securely embedded** in:
```dart
lib/config/environment.dart
```

No additional configuration needed - the app will connect automatically!

## 🎨 UI Screens

### Authentication
- **Login**: Email/password, Google, Guest mode
- **Register**: New account creation
- **Forgot Password**: Password reset via email

### Main App
- **Home**: Dashboard, daily quests, practice modes
- **Competitions**: Active games, create game, game lobby
- **Social**: Friends list, messaging inbox
- **Leaderboard**: Global and friends rankings
- **Profile**: User stats, settings, premium status

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ✅ Web (Experimental)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is proprietary software. All rights reserved.

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Supabase for the open-source backend
- Google Fonts for typography
- All open-source contributors

## 📞 Support

For support, please refer to the documentation files or contact the development team.

---

**Built with ❤️ for language learners worldwide**

**Version:** 1.0.0  
**Flutter:** 3.x  
**Supabase:** Connected ✅

🚀 **Ready to launch!** 🚀
