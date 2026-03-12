# Soma App - Testing Guide

## ✅ Build Status
**Latest APK:** `build/app/outputs/flutter-apk/app-debug.apk`

## 📱 Device Testing Instructions

### Prerequisites
1. Android device with USB debugging enabled
2. USB cable
3. ADB installed (comes with Android Studio) or use Flutter's built-in tools

### Method 1: Using Flutter (Recommended)

```bash
# Connect your device via USB
# Verify device is detected
flutter devices

# Install and run
flutter run
```

### Method 2: Manual APK Installation

```bash
# Option A: Use ADB
adb install build/app/outputs/flutter-apk/app-debug.apk

# Option B: Transfer APK to device
# 1. Copy the APK to your device
# 2. Open file manager on device
# 3. Tap the APK to install
# 4. Allow installation from unknown sources if prompted
```

### Method 3: Build Release APK

```bash
# For testing release version
flutter build apk --release

# Install release APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 🔍 Testing Checklist

### Guest Mode Features (No login required)
- [ ] App launches successfully
- [ ] Home screen displays with practice modes
- [ ] **Falling Words** game works
  - [ ] Words fall correctly
  - [ ] Can tap correct translations
  - [ ] Score updates
  - [ ] Game ends properly
- [ ] **Word Match** game works
  - [ ] Can match words to translations
  - [ ] Progress tracking works
  - [ ] Completion screen shows
- [ ] **Vocabulary Quiz** works
  - [ ] Multiple choice questions display
  - [ ] Can select answers
  - [ ] Results screen shows score
- [ ] Settings screen opens
- [ ] Guest banner visible on home screen
- [ ] Locked features show upgrade prompts

### Auth Features (Requires account)
- [ ] Registration screen works
- [ ] Login screen works
- [ ] Flashcards mode works (auth only)
  - [ ] Cards flip with animation
  - [ ] "Know It" / "Learning" buttons work
  - [ ] Session stats display
- [ ] Fill in Blank mode shows (currently placeholder)
- [ ] Settings shows full options for auth users

### UI/UX
- [ ] App icon displays correctly on home screen
- [ ] Splash screen looks good
- [ ] Colors match Soma branding (teal/purple)
- [ ] Animations are smooth
- [ ] No crashes or freezes

### Performance
- [ ] App loads in under 3 seconds
- [ ] Games run at 60fps
- [ ] No memory leaks during extended play
- [ ] Works on different screen sizes

## 🐛 Known Issues

1. **Audio Features Disabled**
   - Pronunciation and listening modes are stubbed
   - Due to build issues with audio dependencies
   - Will be fixed in future update

2. **Placeholder Logos**
   - Currently using generated "S" logo
   - Replace with final logo before release

3. **Demo Vocabulary**
   - Uses demo data if no course selected
   - Connects to real Supabase data when configured

## 🚀 Quick Test Commands

```bash
# Hot reload during testing
flutter run --hot

# Run with verbose output
flutter run -v

# Check for errors
flutter analyze

# Run on specific device
flutter run -d <device-id>

# Build and install in one command
flutter build apk --debug && adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 📝 Reporting Issues

If you find bugs:
1. Note the exact steps to reproduce
2. Check `flutter doctor` output
3. Look at device logs: `adb logcat | grep flutter`
4. Take screenshots if UI related

## 🔧 Troubleshooting

### App won't install
- Enable "Install from unknown sources" in device settings
- Uninstall previous version first: `adb uninstall com.amoslanguages.soma`

### Build fails
```bash
# Clean build
flutter clean
flutter pub get
flutter build apk --debug
```

### Device not detected
```bash
# Check ADB devices
adb devices

# Restart ADB server
adb kill-server
adb start-server
```

## 📊 Performance Benchmarks

Expected performance on modern devices:
- Cold start: < 2 seconds
- Game frame rate: 60 fps
- Memory usage: < 150 MB
- APK size: ~25 MB

---

**Last Updated:** 2026-03-05  
**Version:** Development Build  
**Package:** com.amoslanguages.soma
