# Soma - Complete App Documentation

## Overview

Soma is a premium, production-grade gamified language learning app with comprehensive online competitions, social features, AI-powered tutoring, and real-time multiplayer capabilities built with Flutter and Supabase.

## 🚀 Features

### 1. **Online Competitions** 🎮
- **Active Games Discovery**: Browse and filter live competitions
- **Create Competitions**: Host private or public games with custom settings
- **Real-time Game Lobby**: Join games, invite friends, ready-up system
- **Premium-only Games**: Exclusive competitions for premium users
- **Dynamic Leaderboard**: Real-time rankings within games
- **Invite System**: Send game invitations to friends

### 2. **Social Features** 👥
- **Friends System**: Add, manage, and block users
- **Friend Requests**: Send and accept friend requests with messages
- **Direct Messaging**: Real-time chat with friends
- **Inbox**: Conversation list with unread indicators
- **Online Status**: See when friends are online
- **Message History**: Full conversation history (premium feature)

### 3. **Leaderboard System** 🏆
- **Global Rankings**: Compete with players worldwide
- **Friends Leaderboard**: Private rankings among friends
- **Weekly Rankings**: Time-based competitions
- **Language-specific**: Rankings by target language
- **Seasonal Events**: Special tournaments and rewards
- **Achievement Badges**: Unlockable achievements

### 4. **Premium Features** ⭐
- **Subscription Tiers**: Monthly, Yearly, Lifetime plans
- **XP Boost**: 2x XP multiplier for all activities
- **Unlimited Games**: No daily game limits
- **Advanced Stats**: Detailed analytics and insights
- **Custom Themes**: Exclusive app themes
- **Priority Support**: Fast-track customer support
- **Premium Badge**: Exclusive profile badge
- **Ad-free Experience**: Clean, uninterrupted learning

### 5. **Notifications** 🔔
- **Push Notifications**: Game invites, friend requests, messages
- **In-app Notifications**: Real-time updates
- **Email Notifications**: Important account updates
- **Custom Preferences**: Control notification types
- **Game Alerts**: Game start/end notifications
- **Achievement Unlocks**: Instant achievement notifications

### 6. **Profile & Settings** 👤
- **Profile Management**: Edit bio, avatar, display name
- **Privacy Settings**: Control profile visibility
- **Language Settings**: Native and learning languages
- **Notification Preferences**: Granular control
- **Account Security**: Password reset, 2FA
- **Data Export**: Download your data

## 📱 App Structure

```
lib/
├── core/                   # Core utilities
├── models/                 # Data models
│   ├── user_model.dart
│   ├── competition_model.dart
│   ├── friend_model.dart
│   ├── message_model.dart
│   ├── notification_model.dart
│   ├── leaderboard_model.dart
│   └── premium_model.dart
├── services/              # Backend services
│   ├── supabase_service.dart
│   ├── user_service.dart
│   ├── competition_service.dart
│   ├── friend_service.dart
│   ├── message_service.dart
│   ├── notification_service.dart
│   └── premium_service.dart
├── providers/             # State management
│   ├── auth_provider.dart
│   ├── competition_provider.dart
│   ├── friend_provider.dart
│   ├── message_provider.dart
│   ├── notification_provider.dart
│   └── premium_provider.dart
├── screens/               # UI screens
│   ├── home/
│   ├── competitions/
│   ├── social/
│   ├── leaderboard/
│   ├── profile/
│   └── settings/
├── theme/                 # App theming
└── constants/             # App constants
```

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.x**: Cross-platform UI framework
- **Provider**: State management
- **Flutter Animate**: Smooth animations
- **Google Fonts**: Typography
- **Cached Network Image**: Image caching

### Backend
- **Supabase**: PostgreSQL + Realtime + Auth
- **Firebase**: Push notifications, analytics
- **Row Level Security**: Data protection
- **Real-time Subscriptions**: Live updates

### Features
- **Real-time**: WebSocket-based live updates
- **Offline Support**: Local caching
- **Push Notifications**: Firebase Cloud Messaging
- **Deep Linking**: Universal links
- **Social Auth**: Google Sign-In
- **In-app Purchases**: RevenueCat integration ready

## 📊 Database Schema

See `supabase/schema.sql` for complete database schema including:
- 12+ tables for all features
- Row Level Security policies
- Indexes for performance
- Database functions

### Key Tables
1. **users**: User profiles
2. **competitions**: Game sessions
3. **competition_players**: Player links
4. **friends**: Friend relationships
5. **conversations**: DM threads
6. **messages**: Chat messages
7. **notifications**: User notifications
8. **subscriptions**: Premium subscriptions

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Supabase account
- Firebase account (for notifications)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/linguaquest.git
cd linguaquest
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure environment**
Create `.env` file:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

4. **Run database migrations**
Execute SQL from `supabase/schema.sql` in your Supabase SQL editor.

5. **Run the app**
```bash
flutter run
```

## 📱 Screenshots

[To be added]

## 🔐 Security

- **Row Level Security**: All tables protected
- **Authentication**: Supabase Auth with JWT
- **Data Encryption**: Encrypted at rest
- **Rate Limiting**: API rate limits enforced
- **Input Validation**: Server-side validation

## 🎯 Roadmap

### Phase 1: Core Features ✅
- [x] User authentication
- [x] Basic language learning
- [x] Profile management

### Phase 2: Social & Competitions ✅
- [x] Friends system
- [x] Online competitions
- [x] Real-time games
- [x] Leaderboards

### Phase 3: Premium Features ✅
- [x] Subscription tiers
- [x] XP boost
- [x] Advanced stats
- [x] Premium games

### Phase 4: Enhanced Features (Next)
- [ ] Voice chat in games
- [ ] Tournament mode
- [ ] Clan system
- [ ] Trading cards
- [ ] Seasonal events

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software. All rights reserved.

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Supabase for the open-source Firebase alternative
- All contributors and testers

## 📞 Support

For support, email support@linguaquest.com or join our Discord community.

---

**Built with ❤️ by the Soma Team**
