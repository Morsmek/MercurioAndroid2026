# Mercurio Android App - Fixed Version

## What Was Fixed

### 1. Critical Permissions Added (AndroidManifest.xml)
The following permissions were missing and have been added:

**Network & Connectivity:**
- `INTERNET` - Required for Firebase and all network operations
- `ACCESS_NETWORK_STATE` - Check network connectivity

**Camera & QR Code:**
- `CAMERA` - Required for QR code scanning feature
- Hardware camera features marked as optional

**Storage & Media:**
- `READ_EXTERNAL_STORAGE` - For image picker (Android 12 and below)
- `WRITE_EXTERNAL_STORAGE` - For saving images (Android 12 and below)
- `READ_MEDIA_IMAGES` - For Android 13+ media access

**Biometric Authentication:**
- `USE_BIOMETRIC` - For fingerprint/face authentication
- `USE_FINGERPRINT` - Legacy fingerprint support

**Push Notifications:**
- `POST_NOTIFICATIONS` - Required for Android 13+ notifications
- `WAKE_LOCK` - Keep device awake for messages
- `RECEIVE_BOOT_COMPLETED` - Restart services after device boot
- `VIBRATE` - Notification vibration

**Background Services:**
- `FOREGROUND_SERVICE` - For Firebase Cloud Messaging background tasks

### 2. Build Configuration Updates (build.gradle.kts)

**Explicit SDK Versions:**
- `minSdk = 24` - Set to Android 7.0 (compatible with all your dependencies)
- `targetSdk = 34` - Latest stable Android version
- `compileSdk = 34` - Android 14 compilation

**MultiDex Support:**
- Enabled `multiDexEnabled = true` to handle 65k+ method limit
- Added `androidx.multidex:multidex:2.0.1` dependency

**Release Build Optimization:**
- Enabled code shrinking (`isMinifyEnabled = true`)
- Enabled resource shrinking (`isShrinkResources = true`)
- Added ProGuard configuration for code obfuscation

### 3. ProGuard Rules (NEW FILE: proguard-rules.pro)
Created comprehensive ProGuard rules to protect:
- Flutter framework code
- Firebase services
- Cryptography libraries (BouncyCastle)
- Hive database
- Image picker
- Biometric authentication
- QR code libraries
- All model classes

### 4. Custom Application Class (NEW FILE: MercurioApplication.kt)
- Created `MercurioApplication` extending `MultiDexApplication`
- Configured in AndroidManifest.xml for proper multidex initialization

### 5. Firebase Cloud Messaging Configuration
Added to AndroidManifest.xml:
- Firebase Messaging Service declaration
- Default notification channel ID: `mercurio_default_channel`
- Default notification icon configuration

### 6. Gradle Performance Optimization (gradle.properties)
Enhanced build configuration:
- Enabled Gradle caching
- Enabled parallel builds
- Optimized R8 compiler settings
- Increased JVM heap to 8GB for large builds

## How to Build the App

### Prerequisites
1. Install Flutter SDK (3.35.4 or later)
2. Install Android Studio with:
   - Android SDK Platform 34
   - Android Build Tools
   - NDK (if needed)
3. Set up Java JDK 11 or higher

### Build Commands

**Debug Build (for testing):**
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

**Release Build (for production):**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

**Build for specific architecture:**
```bash
# ARM64 only (most modern devices)
flutter build apk --release --target-platform android-arm64

# Multiple architectures
flutter build apk --release --split-per-abi
```

**Install to connected device:**
```bash
flutter install
# or
flutter run --release
```

### Build Output Locations
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split ABIs: `build/app/outputs/flutter-apk/app-*-release.apk`

## Important Notes

### Firebase Configuration
Ensure your `google-services.json` file is properly configured with:
- Your Firebase project ID
- Correct package name: `com.mercurio.chat`
- All required Firebase services enabled

### Signing for Production
The current configuration uses debug signing. For production:

1. Create a keystore:
```bash
keytool -genkey -v -keystore mercurio-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mercurio
```

2. Create `android/key.properties`:
```
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=mercurio
storeFile=<path-to-mercurio-release.jks>
```

3. Update `android/app/build.gradle.kts` to use release signing config

### Testing Checklist
Before deploying, test these features:
- ✅ QR code scanning
- ✅ Image picker functionality
- ✅ Biometric authentication
- ✅ Push notifications
- ✅ Message sending/receiving
- ✅ Background Firebase sync
- ✅ Camera permissions
- ✅ Storage permissions

### Troubleshooting

**"Duplicate class" errors:**
- Run `flutter clean` then `flutter pub get`
- Ensure no conflicting dependencies

**Firebase initialization errors:**
- Check `google-services.json` is in `android/app/`
- Verify package name matches in all configuration files

**Permission denied errors:**
- Request runtime permissions for Android 6.0+
- Check permission handling in Flutter code

**Build fails with OutOfMemoryError:**
- Increase Gradle JVM args in `gradle.properties`
- Close other applications during build

**APK crashes on startup:**
- Check ProGuard rules if using release build
- Test with debug build first
- Check LogCat for crash logs: `adb logcat`

## Security Considerations

The app now includes:
- Code obfuscation via ProGuard
- Resource shrinking to reduce APK size
- Proper permission scoping (maxSdkVersion for storage)
- Secure Firebase configuration
- MultiDex for handling large dependency set

## Performance Optimizations

- R8 full mode enabled for better optimization
- Gradle caching enabled for faster builds
- Parallel build execution
- Resource shrinking to reduce APK size
- Proper use of hardware acceleration

## Next Steps

1. **Test thoroughly** on multiple Android devices (Android 7.0 - 14)
2. **Set up release signing** for Play Store deployment
3. **Configure Firebase** for production environment
4. **Test all permissions** at runtime on different Android versions
5. **Optimize app size** by reviewing dependencies
6. **Set up CI/CD** for automated builds and testing

## Support

For issues or questions:
- Check Flutter doctor: `flutter doctor -v`
- View build logs: `flutter build apk --verbose`
- Check Android logs: `adb logcat`
- Review Firebase console for backend issues

---

**Version:** 1.0.0+1  
**Package:** com.mercurio.chat  
**Min Android:** 7.0 (API 24)  
**Target Android:** 14 (API 34)
