# 📚 Course Management System

## Overview
A comprehensive course management system that allows users to learn multiple languages simultaneously, switch between courses, and track progress for each language.

## ✨ Features Added

### 1. **Course Selector on Home Screen** ✅
- Displays current active course with progress
- Shows course count badge
- "Change Course" button to open course list
- Visual progress indicator
- Course card with language flags and names

### 2. **Course List Bottom Sheet** ✅
- Slides up from bottom
- Search bar to filter courses
- Shows all user courses
- **Swipe to delete** with confirmation dialog
- Active course highlighted with teal border
- Shows XP, Level, and progress for each course
- "Add New Course" button at bottom

### 3. **Add New Course Screen** ✅
- **2-step wizard**:
  1. Select native language ("I speak...")
  2. Select target language ("I want to learn...")
- Search bar to filter languages
- Visual step indicator
- Shows 15 available languages with flags
- Prevents selecting same language as native and target
- **Confirmation dialog** before creating course
- Visual language cards with flags and native names

### 4. **Search Functionality** ✅
- Search courses in course list
- Search languages when adding new course
- Real-time filtering
- Clear search button

### 5. **Confirmation Dialogs** ✅
- **Delete Course**: "Are you sure you want to delete your [Language] course?"
- **Switch Course**: "Do you want to switch to learning [Language]?"
- **Add Course**: Shows summary before creating
- Visual warnings about data loss

### 6. **Data Model** (`lib/models/course_model.dart`)
```dart
CourseModel {
  id, userId,
  nativeLanguage, nativeLanguageName, nativeLanguageFlag,
  targetLanguage, targetLanguageName, targetLanguageFlag,
  currentLevel, totalXP, progress,
  isActive, createdAt, lastAccessedAt
}
```

### 7. **Backend Integration** (`lib/services/course_service.dart`)
- `getUserCourses()` - Load all courses
- `addCourse()` - Add new language course
- `deleteCourse()` - Delete with confirmation
- `setActiveCourse()` - Switch active course
- `getActiveCourse()` - Get currently learning
- `updateCourseProgress()` - Update XP/progress
- `searchCourses()` - Search courses

### 8. **State Management** (`lib/providers/course_provider.dart`)
- Manages course list state
- Handles active course
- Search query state
- Loading and error states
- Automatic reactivity

## 📁 Files Created/Modified

### New Files:
1. `lib/models/course_model.dart` - Course data model
2. `lib/services/course_service.dart` - Course API service
3. `lib/providers/course_provider.dart` - Course state management
4. `lib/screens/home/course_selector_sheet.dart` - Course list UI
5. `lib/screens/home/add_course_screen.dart` - Add course wizard

### Modified Files:
1. `lib/screens/home/home_screen.dart` - Added course section
2. `lib/main.dart` - Added CourseProvider
3. `supabase/schema.sql` - Added user_courses table + RLS policies

## 🗄️ Database Schema

### user_courses Table
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

**RLS Policies:**
- Users can only view/insert/update/delete their own courses

## 🎨 UI/UX Features

### Course Card Design
- Language flag in gradient container
- Language name in bold
- Native language shown as subtitle
- XP and Level badges
- Active indicator
- Progress bar on home screen

### Animations
- Fade-in animations for cards
- Slide transitions
- Shimmer effects on progress bars
- Smooth bottom sheet transitions

### Colors
- Primary: Teal (AppColors.primaryTeal)
- Active course: Teal border highlight
- Delete action: Red
- Progress: Coral (AppColors.accentCoral)

## 📱 User Flow

### Adding a New Course:
```
Home Screen → Click "Change Course" or "Select Course"
  ↓
Course List Bottom Sheet → Click "Add New Course"
  ↓
Add Course Screen (Step 1: Select Native Language)
  ↓
Search or select from list
  ↓
Add Course Screen (Step 2: Select Target Language)
  ↓
Search or select from list
  ↓
Confirmation Dialog → Click "Start Learning"
  ↓
Course created and set as active
```

### Switching Courses:
```
Home Screen → Click "Change Course"
  ↓
Course List Bottom Sheet
  ↓
Click on different course
  ↓
Confirmation Dialog
  ↓
Course switched, home screen updates
```

### Deleting a Course:
```
Home Screen → Click "Change Course"
  ↓
Course List Bottom Sheet
  ↓
Swipe course to left
  ↓
Click "Delete" button
  ↓
Confirmation Dialog (warns about data loss)
  ↓
Course deleted
```

## 🔍 Search Functionality

### Course Search:
- Searches course list in bottom sheet
- Filters by target language name
- Filters by native language name
- Real-time results
- Case-insensitive

### Language Search:
- Searches when adding new course
- Filters by language name
- Filters by native name
- 15 languages available:
  🇺🇸 English, 🇪🇸 Spanish, 🇫🇷 French, 🇩🇪 German, 
  🇮🇹 Italian, 🇧🇷 Portuguese, 🇷🇺 Russian, 🇯🇵 Japanese,
  🇰🇷 Korean, 🇨🇳 Chinese, 🇸🇦 Arabic, 🇮🇳 Hindi,
  🇹🇷 Turkish, 🇵🇱 Polish, 🇳🇱 Dutch

## ✅ Confirmation Dialogs Added

1. **Delete Course**: Warns about permanent data loss
2. **Switch Course**: Confirms course change
3. **Add Course**: Shows final summary
4. **Guest Mode**: Already had conversion banner
5. **Log Out**: Already had confirmation dialog

## 🚀 Next Steps to Use

1. **Run Database Migration**:
   ```sql
   -- Run this in Supabase SQL Editor
   CREATE TABLE user_courses (
     -- ... (see schema.sql)
   );
   ```

2. **Add CourseProvider** to main.dart (already done)

3. **Test Features**:
   - Add your first course
   - Add multiple courses
   - Switch between courses
   - Delete a course
   - Search courses and languages

## 📊 Statistics

- **15 Languages** available
- **Unlimited courses** per user
- **Progress tracking** per course (XP, Level, %)
- **Real-time** active course switching
- **Search** across courses and languages

## 🎉 Summary

The course management system is now complete with:
- ✅ Multi-language learning support
- ✅ Easy course switching
- ✅ Visual progress tracking
- ✅ Search functionality
- ✅ Confirmation dialogs
- ✅ Swipe-to-delete
- ✅ Beautiful UI/UX
- ✅ Full backend integration
- ✅ Real-time state management

**Users can now learn multiple languages and easily switch between them!** 🌟
