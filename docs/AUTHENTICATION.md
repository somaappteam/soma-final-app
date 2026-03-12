# Authentication System Documentation

## Overview

The Soma app now includes a complete authentication system with support for:
- **Email/Password Authentication**: Traditional sign in/sign up
- **Google OAuth**: One-click sign in with Google
- **Guest Mode**: Play offline without account, convert later
- **Password Reset**: Email-based password recovery

## Features

### 1. **Login Screen** (`lib/screens/auth/login_screen.dart`)
- Email and password fields with validation
- "Continue with Google" button
- **"Continue as Guest" button** for offline play
- "Forgot Password" link
- "Sign Up" link for new users
- Smooth animations and error handling

### 2. **Register Screen** (`lib/screens/auth/register_screen.dart`)
- Username, email, password fields
- Password confirmation
- Terms and conditions checkbox
- Google sign-up option
- **Guest Conversion**: If user is already in guest mode, shows banner and allows converting guest progress to full account

### 3. **Forgot Password Screen** (`lib/screens/auth/forgot_password_screen.dart`)
- Email input for reset link
- Success message after sending email
- Back to sign in option

### 4. **Guest Mode** (`lib/utils/guest_user.dart`)

**GuestUser Model Features:**
- Local storage using SharedPreferences
- Tracks all user progress: XP, level, streak, games played
- Saves language preferences
- **Convert to Full Account**: Seamlessly migrate all progress when creating account

**Guest User Capabilities:**
- ✅ Access all learning content offline
- ✅ Track XP and level progress
- ✅ View achievements
- ❌ Cannot join online competitions (requires account)
- ❌ Cannot use social features (friends, messaging)
- ❌ Cannot access premium features
- ❌ Progress not synced to cloud

**Full Account Benefits:**
- ✅ All guest features
- ✅ Online competitions with other players
- ✅ Friend system and messaging
- ✅ Cloud sync across devices
- ✅ Premium subscription options
- ✅ Global leaderboards
- ✅ Notifications

### 5. **AuthProvider Updates** (`lib/providers/auth_provider.dart`)

**New Methods:**
- `continueAsGuest()`: Create temporary guest session
- `convertGuestToUser()`: Migrate guest data to authenticated account
- `isGuest`: Check if currently in guest mode
- `guestUser`: Access guest user data

### 6. **Splash Screen Updates** (`lib/screens/splash_screen.dart`)
- Automatically routes based on auth state:
  - Authenticated → Main app
  - Guest → Main app (with guest banner)
  - Not logged in → Login screen

### 7. **Home Screen Guest Banner** (`lib/screens/home/home_screen.dart`)
- Shows prominent banner for guest users
- Explains limitations
- "Create Account" button to convert
- Displays guest progress data

## User Flow

### New User Flow:
```
Splash Screen → Login Screen → 
  ├─ Sign Up → Email Verification → Main App
  ├─ Continue with Google → Main App
  └─ Continue as Guest → Main App (Guest Mode)
```

### Guest User Flow:
```
Already Guest → Use App (Offline) → 
  ├─ Try Online Feature → Prompt to Create Account
  └─ Click "Create Account" Banner → Register Screen → 
      └─ Convert Guest Data → Full Account
```

### Returning User Flow:
```
Splash Screen → Auto Login → Main App
```

## Technical Implementation

### Guest User Persistence
```dart
// Guest data is saved locally
await GuestUser.save();     // Save progress
final guest = await GuestUser.load();  // Load on app start
await GuestUser.clear();    // Clear when converting
```

### Auth State Management
```dart
// Check current state
if (authProvider.isAuthenticated) {
  // Full access
} else if (authProvider.isGuest) {
  // Limited access, show conversion banner
} else {
  // Show login screen
}
```

### Converting Guest to User
```dart
await authProvider.convertGuestToUser(
  email: 'user@example.com',
  password: 'securepassword',
  username: 'newuser',
);
// All guest progress is transferred!
```

## UI Components

### Guest Banner
- Appears on home screen for guest users
- Orange gradient background
- Icon and explanatory text
- Prominent "Create Account" CTA button

### Auth Forms
- Form validation with error messages
- Password visibility toggle
- Loading states
- Success/error feedback via SnackBars

### Navigation
- Automatic routing based on auth state
- Smooth transitions between auth screens
- Back navigation properly handled

## Security

- ✅ Password minimum 6 characters
- ✅ Email validation
- ✅ Password confirmation matching
- ✅ Terms acceptance required
- ✅ Secure password reset flow
- ✅ Guest data stored locally only
- ✅ No sensitive data in SharedPreferences

## Testing Checklist

### Authentication:
- [ ] Sign up with email
- [ ] Sign in with email
- [ ] Sign in with Google
- [ ] Password reset flow
- [ ] Form validation
- [ ] Error handling

### Guest Mode:
- [ ] Continue as guest
- [ ] Progress persistence
- [ ] Guest banner display
- [ ] Feature restrictions
- [ ] Convert guest to user
- [ ] Data migration

### Navigation:
- [ ] Splash screen routing
- [ ] Auto-login on app start
- [ ] Guest routing
- [ ] Logout flow

## Next Steps

1. **Email Verification**: Add email verification step after registration
2. **Social Logins**: Add Apple Sign-In, Facebook login
3. **Biometric Auth**: Add fingerprint/Face ID login option
4. **Session Management**: Add session timeout and refresh
5. **Account Recovery**: Enhanced account recovery options
