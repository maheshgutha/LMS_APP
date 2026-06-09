# AOTMS LMS Flutter App

Mobile app for the AOTMS LMS platform. Mirrors the web app with real data from the backend.

**Backend:** `https://aotms-lms-new.onrender.com`

## Roles Supported
- Admin / Super Admin
- Manager
- Instructor
- Student
- Intern

---

## Build Instructions (Windows)

### Prerequisites
- Flutter SDK installed (3.x recommended): https://docs.flutter.dev/get-started/install/windows
- Android Studio with Android SDK (API 34)
- Java 17+

### ⚠️ IMPORTANT: Place this project at `C:\AOTMS_LMS_Flutter\`
Do NOT place in OneDrive/Documents — Gradle will fail due to path issues.

### Steps

1. **Open terminal at project root:**
   ```
   cd C:\AOTMS_LMS_Flutter
   ```

2. **Set up local.properties** (inside `android/` folder):
   ```
   sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk
   flutter.sdk=C:\\flutter
   flutter.versionName=1.0.0
   flutter.versionCode=1
   ```
   Replace `YourName` and paths to match your machine.

3. **Get packages:**
   ```
   flutter pub get
   ```

4. **Build APK:**
   ```
   flutter build apk --release
   ```

5. **APK location:**
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```
   Transfer this file to your Android device and install.

### Run on Emulator
```
flutter run
```

---

## Module Coverage

### Admin
User Management, Student Enrollments, Academic Scores, Leaderboard, Resume Scans,
Instructor List, All Courses, Chat Monitoring, Live Monitoring, Quality Assurance,
Notifications, Profile

### Manager
All Admin modules + Submission Grading

### Instructor
Dashboard, My Profile, My Courses, Student Roster, Notifications, Messages, Live Broadcast

### Student / Intern
Dashboard, My Profile, Messages, My Courses, Video Lessons, Live Classes, Resources,
Resume ATS, Mock Papers (Student), Attendance, History, Notifications, Settings,
Leaderboard, Interview Exam, Certification (Intern)
