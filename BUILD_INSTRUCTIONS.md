# Mercurio Android App - Build Instructions

## Prerequisites

### 1. Install Flutter SDK
```bash
# Download Flutter SDK (3.35.4 or later)
# https://docs.flutter.dev/get-started/install

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor -v
```

### 2. Install Android Studio
- Download from: https://developer.android.com/studio
- Install Android SDK Platform 34 (Android 14)
- Install Android SDK Build-Tools
- Install Android SDK Command-line Tools

### 3. Install Java JDK
```bash
# Install Java JDK 11 or higher
# Ubuntu/Debian:
sudo apt install openjdk-11-jdk

# macOS:
brew install openjdk@11

# Verify installation
java -version
```

### 4. Set Environment Variables
```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

---

## Build Process

### Step 1: Clone Repository (if not already done)
```bash
git clone https://github.com/Morsmek/MercurioAndroid2026.git
cd MercurioAndroid2026
```

### Step 2: Install Dependencies
```bash
# Clean any previous builds
flutter clean

# Get Flutter dependencies
flutter pub get

# Verify no issues
flutter doctor -v
```

### Step 3: Build Debug APK (for testing)
```bash
# Build debug APK
flutter build apk --debug

# Output location:
# build/app/outputs/flutter-apk/app-debug.apk
```

### Step 4: Build Release APK (for production)
```bash
# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Step 5: Install on Device
```bash
# Connect Android device via USB
# Enable USB debugging on device

# Install debug build
flutter install

# Or run directly
flutter run --release
```

---

## Build Variants

### Build for Specific Architecture
```bash
# ARM64 only (most modern devices, smaller APK)
flutter build apk --release --target-platform android-arm64

# ARM32 only (older devices)
flutter build apk --release --target-platform android-arm

# x86_64 (emulators)
flutter build apk --release --target-platform android-x64
```

### Build Split APKs (recommended for Play Store)
```bash
# Creates separate APKs for each architecture
flutter build apk --release --split-per-abi

# Output files:
# app-armeabi-v7a-release.apk (ARM 32-bit)
# app-arm64-v8a-release.apk (ARM 64-bit)
# app-x86_64-release.apk (x86 64-bit)
```

### Build App Bundle (for Play Store)
```bash
# Build Android App Bundle (AAB)
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

---

## Testing

### Run on Emulator
```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>

# Run app
flutter run
```

### Run on Physical Device
```bash
# Connect device via USB
# Enable USB debugging

# Check device is connected
flutter devices

# Run app
flutter run --release
```

### Run Tests
```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

---

## Troubleshooting

### Issue: "Flutter command not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or add to ~/.bashrc permanently
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "Android SDK not found"
```bash
# Set ANDROID_HOME
export ANDROID_HOME=$HOME/Android/Sdk

# Or install via Android Studio:
# Tools > SDK Manager > Install Android SDK Platform 34
```

### Issue: "Gradle build failed"
```bash
# Clean and rebuild
flutter clean
cd android && ./gradlew clean
cd ..
flutter pub get
flutter build apk --release
```

### Issue: "Out of memory"
```bash
# The gradle.properties already allocates 8GB
# If still failing, increase heap size:
# Edit android/gradle.properties
org.gradle.jvmargs=-Xmx12G -XX:MaxMetaspaceSize=4G
```

### Issue: "Duplicate class errors"
```bash
# Clean everything
flutter clean
rm -rf build/
rm -rf android/.gradle/
rm -rf android/app/build/
flutter pub get
flutter build apk
```

### Issue: "Firebase initialization failed"
```bash
# Verify google-services.json exists
ls -la android/app/google-services.json

# Verify package name matches
grep "package_name" android/app/google-services.json
# Should show: "com.mercurio.chat"
```

---

## Build Configuration

### Current Settings
- **Min SDK:** 24 (Android 7.0)
- **Target SDK:** 34 (Android 14)
- **Compile SDK:** 34 (Android 14)
- **Package Name:** com.mercurio.chat
- **Version:** 1.0.0+1

### Supported Devices
- Android 7.0 (Nougat) and above
- ARM and ARM64 architectures
- Minimum 2GB RAM recommended
- Camera required for QR scanning
- Internet connection required

---

## Release Signing (for Play Store)

### Step 1: Create Keystore
```bash
keytool -genkey -v -keystore mercurio-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mercurio
```

### Step 2: Create key.properties
```bash
# Create android/key.properties
cat > android/key.properties << EOF
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=mercurio
storeFile=<path-to-mercurio-release.jks>
EOF
```

### Step 3: Update build.gradle.kts
```kotlin
// Add before android block
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ... rest of config ...
        }
    }
}
```

### Step 4: Build Signed Release
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

---

## Performance Optimization

### Reduce APK Size
```bash
# Build with split ABIs
flutter build apk --release --split-per-abi

# Enable ProGuard (after testing)
# Edit android/app/build.gradle.kts:
isMinifyEnabled = true
isShrinkResources = true
```

### Improve Build Speed
```bash
# Use Gradle daemon (already enabled)
# Use parallel builds (already enabled)
# Use build cache (already enabled)

# Clear cache if builds are slow
flutter clean
cd android && ./gradlew clean
```

---

## Deployment Checklist

Before deploying to production:

- [ ] Test on multiple Android versions (7-14)
- [ ] Test on different screen sizes
- [ ] Test all permissions (camera, storage, notifications)
- [ ] Test offline functionality
- [ ] Test Firebase connectivity
- [ ] Test message encryption/decryption
- [ ] Test QR code scanning
- [ ] Test image picker
- [ ] Test push notifications
- [ ] Configure release signing
- [ ] Update version number
- [ ] Create release notes
- [ ] Test on physical devices
- [ ] Verify Firebase security rules
- [ ] Check for memory leaks
- [ ] Test app startup time
- [ ] Verify all assets load correctly

---

## Support

### Flutter Issues
- Flutter Doctor: `flutter doctor -v`
- Flutter Logs: `flutter logs`
- Verbose Build: `flutter build apk --verbose`

### Android Issues
- Logcat: `adb logcat`
- Device Info: `adb devices -l`
- Install APK: `adb install -r app-release.apk`

### Firebase Issues
- Check Firebase Console
- Verify google-services.json
- Check Firestore rules
- Monitor Firebase logs

---

## Additional Resources

- Flutter Documentation: https://docs.flutter.dev
- Android Developer Guide: https://developer.android.com
- Firebase Documentation: https://firebase.google.com/docs
- Play Store Publishing: https://play.google.com/console

---

**Last Updated:** January 27, 2025
**App Version:** 1.0.0+1
**Target SDK:** Android 14 (API 34)