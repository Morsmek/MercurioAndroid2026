# 🚀 Mercurio Messenger v1.0.0 - Release Notes

**Build Date**: January 19, 2026  
**Version**: 1.0.0+1  
**Build Type**: Debug APK  
**Size**: 165 MB  

---

## 📥 Download

**APK**: `MercurioMessenger-v1.0.0-debug.apk`

**Download Link**: https://8080-iokjwuld8hg7owq2boint-3844e1b6.sandbox.novita.ai/MercurioMessenger-v1.0.0-debug.apk

---

## ✨ What's New in v1.0.0

### 🎨 **Brand New Logo**
- **Official Mercurio logo** integrated throughout the app
- **Orange "M" lettermark** with gradient background
- **Professional launcher icon** in all Android resolutions
- **Consistent branding** across splash screen, settings, and dialogs

### 🔐 **Production-Ready Security**
- **Firestore security rules** ready to deploy
- **Self-sovereign identity** validation (no Firebase Auth needed)
- **E2EE message validation** (all encrypted fields required)
- **Immutable identities** (cannot change public keys)
- **Immutable messages** (content cannot be tampered)
- **Complete documentation** in `FIRESTORE_SECURITY.md`

### 💬 **Messaging Fixes**
- **✅ FIXED**: Bidirectional messaging now works perfectly
- **✅ FIXED**: Conversation ID regeneration (no more duplicate chats)
- **✅ FIXED**: Auto-contact creation for incoming messages
- **✅ FIXED**: Real-time message delivery via Firestore
- **✅ FIXED**: Firebase messaging initialization after login

### 🛠️ **Technical Improvements**
- **Deterministic conversation IDs** (sorted session IDs)
- **RSA keypair type casting** fixed (no more crashes)
- **Null-safe timestamp handling** in messages
- **Debug logging** for troubleshooting
- **Improved error handling** throughout

---

## 🎯 Core Features

### 🔒 **Security & Privacy**
- ✅ **End-to-end encryption** (RSA-2048 + AES-256-GCM)
- ✅ **Anonymous registration** (no phone, no email, no personal data)
- ✅ **Self-sovereign identity** (Ed25519 keypairs)
- ✅ **12-word recovery phrase** (BIP39 mnemonic)
- ✅ **Local key storage** (FlutterSecureStorage)
- ✅ **Public key infrastructure** (RSA for key exchange)

### 💬 **Messaging**
- ✅ **Real-time messaging** (Firestore snapshots)
- ✅ **Encrypted message delivery** (E2EE encrypted)
- ✅ **Message status** (sent, delivered, read)
- ✅ **Conversation management** (local storage)
- ✅ **Contact management** (add via QR or Session ID)
- ✅ **Auto-contact creation** (for incoming messages)

### 📱 **User Interface**
- ✅ **Dark theme** (orange accent color)
- ✅ **Material Design 3**
- ✅ **QR code scanning** (add contacts)
- ✅ **QR code display** (share your ID)
- ✅ **Settings screen** (profile, recovery phrase, about)
- ✅ **Splash screen** (branded with logo)
- ✅ **Welcome screen** (onboarding)

### 🔧 **Platform Support**
- ✅ **Android** (API 24+ / Android 7.0+)
- ✅ **Target SDK**: Android 15 (API 36)
- ✅ **Min SDK**: Android 7.0 (API 24)
- ✅ **MultiDex enabled** (for large apps)
- ✅ **ProGuard rules** (for release builds)

---

## 📋 Requirements

### **Device Requirements:**
- **Android 7.0** (Nougat) or higher
- **Minimum 2 GB RAM** (recommended 4 GB)
- **100 MB free storage** (for app installation)
- **Internet connection** (for Firebase backend)
- **Camera** (for QR code scanning - optional)

### **Permissions:**
- `INTERNET` - For Firebase connectivity
- `ACCESS_NETWORK_STATE` - Network status
- `CAMERA` - QR code scanning (optional)
- `READ_EXTERNAL_STORAGE` - Image picker (optional)
- `WRITE_EXTERNAL_STORAGE` - Image storage (optional)
- `READ_MEDIA_IMAGES` - Android 13+ media access
- `USE_BIOMETRIC` - Biometric login (optional)
- `POST_NOTIFICATIONS` - Push notifications (Android 13+)
- `WAKE_LOCK` - Background messaging
- `RECEIVE_BOOT_COMPLETED` - Start on boot
- `FOREGROUND_SERVICE` - Background sync
- `VIBRATE` - Notification vibration

---

## 🔥 Firebase Setup Required

**IMPORTANT**: Before using the app, you MUST deploy Firestore security rules!

### **Step 1: Copy the Rules**
Rules are in: `/home/user/webapp/firestore.rules`

Or use the rules from: `DEPLOY_FIRESTORE_RULES.md`

### **Step 2: Deploy to Firebase Console**
1. Go to: https://console.firebase.google.com
2. Select your project
3. Click **Firestore Database** → **Rules** tab
4. Paste the rules and click **Publish**

### **Step 3: Test**
1. Open the app
2. Try adding a contact
3. Should work without "permission-denied" errors!

**Without deploying rules, you will get:** ❌ `[cloud_firestore/permission-denied]`

---

## 🧪 Testing Checklist

### **Initial Setup:**
- [ ] Install APK on device
- [ ] Open app and see splash screen with logo
- [ ] Create new account (generates identity)
- [ ] Copy your Session ID (Settings → Your Mercurio ID)
- [ ] View recovery phrase (Settings → Recovery Phrase)
- [ ] Display QR code (Settings → Show My QR Code)

### **Messaging (Two Devices):**
- [ ] **Device A**: Add Device B as contact (via QR or Session ID)
- [ ] **Device A**: Send message "Hello from A"
- [ ] **Device B**: Receive message and see notification
- [ ] **Device B**: Auto-contact created as "User 05xxxxx..."
- [ ] **Device B**: Manually add Device A with real name "Alice"
- [ ] **Device B**: Reply "Hi back, Alice!"
- [ ] **Device A**: Receive reply in SAME conversation
- [ ] **Both**: All messages appear in ONE conversation thread

### **Features to Test:**
- [ ] QR code scanning (add contact)
- [ ] Image picker (send image - if implemented)
- [ ] Biometric authentication (if implemented)
- [ ] Push notifications (if FCM configured)
- [ ] Background messaging (app in background)
- [ ] Message status (sent → delivered → read)
- [ ] Conversation list (unread count, timestamps)

---

## 🐛 Known Issues

### **Expected Behaviors:**
1. **First contact add**: May show "User 05xxxxx..." name until manual rename
2. **Message delivery**: Requires both devices to be online
3. **Firestore rules**: MUST be deployed or you'll get permission errors
4. **Debug APK**: Larger file size than release build

### **Not Yet Implemented:**
- [ ] Group chats (UI placeholder exists)
- [ ] Image/media sharing (UI exists, backend not wired)
- [ ] Voice messages
- [ ] Video calls
- [ ] Message search
- [ ] Connection requests dialog (infrastructure exists)
- [ ] Logout functionality (placeholder exists)

---

## 📚 Documentation

### **Included Guides:**
- `README.md` - Main project documentation
- `ANDROID_FIXES.md` - Android-specific fixes and build config
- `QUICK_START.md` - Quick start guide for developers
- `FIRESTORE_SECURITY.md` - Complete security rules documentation
- `DEPLOY_FIRESTORE_RULES.md` - Quick deployment guide
- `LOGO_INTEGRATION.md` - Logo integration details
- `RELEASE_NOTES.md` - This file

### **Configuration Files:**
- `firestore.rules` - Production-ready security rules
- `android/app/build.gradle.kts` - Android build configuration
- `android/app/proguard-rules.pro` - ProGuard obfuscation rules
- `android/gradle.properties` - Gradle optimization settings

---

## 🔧 Build Information

### **Flutter & Dart:**
- **Flutter SDK**: 3.38.7 (stable)
- **Dart SDK**: 3.10.7
- **Framework**: revision 3b62efc2a3

### **Android:**
- **Compile SDK**: 36 (Android 15)
- **Target SDK**: 36 (Android 15)
- **Min SDK**: 24 (Android 7.0)
- **Build Tools**: 35.0.0
- **NDK**: flutter.ndkVersion
- **Gradle**: 8.0+
- **Kotlin**: JVM target 11
- **Java**: JDK 11 compatibility

### **Key Dependencies:**
- `firebase_core: 3.6.0`
- `cloud_firestore: 5.4.3`
- `cryptography: ^2.9.0`
- `pointycastle: ^3.9.0`
- `flutter_secure_storage: 9.2.2`
- `mobile_scanner: 5.2.3`
- `qr_flutter: 4.1.0`

---

## 🚀 Installation Instructions

### **Step 1: Download APK**
Download from: https://8080-iokjwuld8hg7owq2boint-3844e1b6.sandbox.novita.ai/MercurioMessenger-v1.0.0-debug.apk

### **Step 2: Enable Unknown Sources**
1. Go to **Settings** → **Security** (or **Apps**)
2. Enable **Install from Unknown Sources**
3. (Android 8+) Grant permission when prompted

### **Step 3: Install**
1. Tap the downloaded APK file
2. Tap **Install**
3. Wait for installation to complete
4. Tap **Open**

### **Step 4: Grant Permissions**
When the app requests permissions:
- **Camera**: Required for QR code scanning
- **Storage**: Optional for image sharing
- **Notifications**: Recommended for message alerts

### **Step 5: Deploy Firestore Rules**
**CRITICAL**: Deploy the security rules before using the app!
See `DEPLOY_FIRESTORE_RULES.md` for instructions.

---

## 🔐 Security Notes

### **What's Secure:**
✅ **E2EE encryption**: All messages encrypted client-side  
✅ **Key management**: Private keys never leave your device  
✅ **Self-sovereign**: You control your identity  
✅ **Anonymous**: No personal data required  
✅ **Local storage**: Encrypted secure storage  
✅ **Code obfuscation**: ProGuard for release builds  

### **What's NOT Secure (Debug Build):**
⚠️ **Debug APK**: Not optimized, includes debug symbols  
⚠️ **No code signing**: Uses debug keystore  
⚠️ **No obfuscation**: Code is readable  
⚠️ **Larger file size**: Includes debug info  

**For production, use:** `flutter build apk --release`

---

## 📊 File Sizes

- **Debug APK**: 165 MB (this build)
- **Release APK**: ~50 MB (estimated, with obfuscation)
- **Installed size**: ~200 MB
- **Data storage**: ~10-50 MB (messages, keys, contacts)

---

## 🎯 Roadmap (Future Versions)

### **v1.1.0** (Planned)
- [ ] Connection requests UI (dialog + notifications)
- [ ] Message search functionality
- [ ] Contact nickname editing
- [ ] Conversation archiving
- [ ] Message deletion (local only)

### **v1.2.0** (Planned)
- [ ] Image/media sharing (full implementation)
- [ ] Voice messages
- [ ] File sharing
- [ ] Group chats (basic)
- [ ] Contact verification (safety numbers)

### **v2.0.0** (Future)
- [ ] Video calls (WebRTC)
- [ ] Voice calls
- [ ] End-to-end encrypted backups
- [ ] Multi-device support
- [ ] Desktop apps (Windows, macOS, Linux)

---

## 🆘 Support & Troubleshooting

### **App Won't Install:**
- Check if you have 100 MB+ free storage
- Enable "Install from Unknown Sources"
- Try uninstalling any previous version first

### **Permission Denied Error:**
- Deploy Firestore security rules (see `DEPLOY_FIRESTORE_RULES.md`)
- Check Firebase console for rule deployment status
- Wait 30 seconds for rules to propagate globally

### **Messages Not Sending:**
- Check internet connection
- Verify both devices are online
- Check Firebase console for quota limits
- Review Android logs: `adb logcat | grep Mercurio`

### **App Crashes on Startup:**
- Clear app data: Settings → Apps → Mercurio → Clear Data
- Reinstall the app
- Check if device meets minimum requirements

### **QR Code Scanner Not Working:**
- Grant Camera permission
- Check if camera is working in other apps
- Try better lighting conditions

---

## 📞 Contact & Feedback

**GitHub Repository**: https://github.com/Morsmek/MercurioAndroid2026

**Issues**: https://github.com/Morsmek/MercurioAndroid2026/issues

**Latest Commit**: `43b64e5` - Logo integration documentation

**Branch**: `main`

---

## 📜 License

**License**: MIT (check repository for full license text)

**Privacy**: No data collection, no analytics, no telemetry

---

## 🎉 Thank You!

Thank you for using **Mercurio Messenger**! 

We're committed to:
- 🔐 **Privacy first**: Your data belongs to you
- 🔒 **Security always**: E2EE encryption by default
- 🚀 **Open source**: Transparent and auditable
- 💬 **User-focused**: Simple, secure messaging

**Privacy is a right, not a privilege.™**

---

**Version**: 1.0.0+1  
**Build**: Debug APK  
**Released**: January 19, 2026  
**Status**: ✅ Ready for Testing  

🚀 **Happy Messaging!**
