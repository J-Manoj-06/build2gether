# Firebase Setup Guide

## Current Status
Firebase configuration is needed for full app functionality. The automatic setup with `flutterfire configure` failed.

## Manual Setup Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: **build2gether**
4. Enable Google Analytics (optional)
5. Click "Create Project"

### 2. Add Android App
1. In Firebase Console, click "Add App" → Android
2. Android package name: `com.example.build2gether` (check `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### 3. Add iOS App
1. In Firebase Console, click "Add App" → iOS
2. iOS bundle ID: Check `ios/Runner.xcodeproj/project.pbxproj`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

### 4. Add Web App
1. In Firebase Console, click "Add App" → Web
2. Register app with nickname: "build2gether-web"
3. **Copy the Web Client ID** (looks like: `xxxxx.apps.googleusercontent.com`)
4. Update `web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
   ```
5. Copy the Firebase config object
6. Run: `flutterfire configure` (it should work now with existing project)

### 5. Enable Authentication Methods
1. In Firebase Console → Authentication → Sign-in method
2. Enable **Email/Password**
3. Enable **Google Sign-In**
   - Add support email
   - Copy the Web client ID to `web/index.html` (step 4 above)

### 6. Setup Firestore Database
1. In Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose location closest to your users

### 7. Setup Storage
1. In Firebase Console → Storage
2. Click "Get started"
3. Start in **test mode** (for development)

### 8. Generate firebase_options.dart
After completing steps 1-4, run:
```bash
flutterfire configure --project=build2gether
```

This will generate `lib/firebase_options.dart` with all platform configurations.

## Testing After Setup

1. **Flutter Analyze**:
   ```bash
   flutter analyze
   ```

2. **Run on Chrome** (Web):
   ```bash
   flutter run -d chrome
   ```

3. **Run on Android**:
   ```bash
   flutter run -d android
   ```

## Common Issues

### Issue: Google Sign-In Error on Web
**Error**: `ClientID not set. Either set it on a <meta name="google-signin-client_id"...`

**Solution**: 
- Get Web Client ID from Firebase Console → Authentication → Sign-in method → Google
- Add to `web/index.html`:
  ```html
  <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
  ```

### Issue: Firebase not initialized
**Error**: `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution**:
- Make sure `firebase_options.dart` exists in `lib/`
- Check `lib/main.dart` has:
  ```dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ```

### Issue: Permission Denied (Firestore/Storage)
**Solution**:
- Update Firestore/Storage rules to allow read/write during development:
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /{document=**} {
        allow read, write: if request.auth != null;
      }
    }
  }
  ```

## Current Files Status
✅ All UI pages created and working
✅ Authentication flow implemented
✅ TextFormField web compatibility fixed
❌ Firebase configuration needed (follow steps above)
❌ Google Sign-In client ID needed for web (step 4)

## Next Steps
1. Follow steps 1-8 above to complete Firebase setup
2. Run `flutter run -d chrome` to test on web
3. Test login/register flows
4. Test Google Sign-In after adding client ID
