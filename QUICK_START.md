# Quick Start Guide - Mercurio Android Fixed

## What Changed?
✅ Added 14 critical Android permissions  
✅ Fixed build configuration (minSdk=24, targetSdk=34)  
✅ Added MultiDex support  
✅ Created ProGuard rules for release builds  
✅ Added Firebase Cloud Messaging configuration  
✅ Optimized Gradle build settings  
✅ Created custom Application class  

## Build Now (3 Simple Steps)

1. **Clean and Get Dependencies**
   ```bash
   cd MercurioAndroid2026-main
   flutter clean
   flutter pub get
   ```

2. **Build APK**
   ```bash
   # For testing:
   flutter build apk --debug
   
   # For release:
   flutter build apk --release
   ```

3. **Install**
   ```bash
   flutter install
   # or find APK in: build/app/outputs/flutter-apk/
   ```

## Files Modified
- ✏️ `android/app/src/main/AndroidManifest.xml` - Added permissions
- ✏️ `android/app/build.gradle.kts` - Build config
- ✏️ `android/gradle.properties` - Performance tuning
- ➕ `android/app/proguard-rules.pro` - NEW: ProGuard rules
- ➕ `android/app/src/main/kotlin/com/mercurio/chat/MercurioApplication.kt` - NEW: App class

## Key Features Now Working
✅ Internet connectivity (Firebase)  
✅ QR code scanning (Camera)  
✅ Image sharing (Storage)  
✅ Biometric login (Fingerprint/Face)  
✅ Push notifications (FCM)  
✅ Background messaging  

## Troubleshooting
**Build error?** → Run `flutter clean` first  
**Permission denied?** → Check runtime permissions in code  
**Firebase error?** → Verify `google-services.json` is present  
**APK too large?** → Release build shrinks resources automatically  

For detailed information, see `ANDROID_FIXES.md`
