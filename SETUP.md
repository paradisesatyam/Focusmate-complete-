# FocusMate — One-Time Setup Guide

Follow these steps in order exactly once. After this the app runs with `flutter run`.

---

## Step 1 — Install Flutter (if not done)
Download from https://docs.flutter.dev/get-started/install  
Add `C:\flutter\bin` to your system PATH.  
Run: `flutter doctor` — fix any red items before continuing.

---

## Step 2 — Open the project
```
Open VS Code → File → Open Folder → select the focusmate folder
```

---

## Step 3 — Install dependencies
```bash
flutter pub get
```

---

## Step 4 — Firebase setup

### 4a. Create Firebase project
- Go to https://console.firebase.google.com
- Click Add project → name it `focusmate` → disable Analytics → Create

### 4b. Enable Authentication
- Left sidebar → Authentication → Get started
- Email/Password → Enable → Save

### 4c. Enable Firestore
- Left sidebar → Firestore Database → Create database
- Choose **Start in test mode** → pick a server location near you → Done

### 4d. Generate firebase_options.dart
In VS Code terminal:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
- Select your `focusmate` Firebase project
- Check both **Android** and **Web**
- This will **replace** `lib/firebase_options.dart` with your real credentials

### 4e. Register Android app (for APK builds)
- Firebase console → Project settings (gear icon) → Your apps → Android icon
- Android package name: `com.focusmate.app`
- Download `google-services.json` → place in `android/app/google-services.json`

---

## Step 5 — Get Gemini API key (for AI Chat)
- Go to https://aistudio.google.com → Sign in → Get API key → Create API key
- Open `lib/services/gemini_service.dart`
- Replace `YOUR_GEMINI_API_KEY` with your actual key

---

## Step 6 — Android notification permissions
Open `android/app/src/main/AndroidManifest.xml`  
Add these lines inside the `<manifest>` tag (before `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

---

## Step 7 — Run the app

**Web (for Vercel):**
```bash
flutter run -d chrome
```

**Android (phone):**
```bash
flutter run
```
Make sure your Android device is connected with USB debugging ON, or start an emulator from Android Studio first.

---

## Step 8 — Build for production

**Web build (for Vercel):**
```bash
flutter build web --release
```
Output is in `build/web/` — upload this folder to Vercel.

**Android APK:**
```bash
flutter build apk --release
```
APK is at `build/app/outputs/flutter-apk/app-release.apk`  
Transfer this to your phone and install it.

---

## Step 9 — Deploy to Vercel

1. Go to https://vercel.com → Sign up with GitHub
2. Import your `focusmate` GitHub repo
3. Framework: **Other**
4. Root Directory: `.` (default)
5. Build Command: `flutter build web --release`
6. Output Directory: `build/web`
7. Click Deploy

---

## Step 10 — Push to GitHub
```bash
git add .
git commit -m "Complete FocusMate app"
git push
```

---

## Firestore Security Rules (before publishing)
Replace test mode rules in Firebase console → Firestore → Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tasks/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /diary/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /expenses/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /focus/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
