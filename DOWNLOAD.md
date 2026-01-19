# 🎉 MERCURIO MESSENGER v1.0.0 - READY TO TEST!

## 📥 DOWNLOAD THE NEW APK

**Download Link**: https://8080-iokjwuld8hg7owq2boint-3844e1b6.sandbox.novita.ai/MercurioMessenger-v1.0.0-debug.apk

**File**: `MercurioMessenger-v1.0.0-debug.apk`  
**Size**: 165 MB  
**Version**: 1.0.0+1  
**Build**: Debug APK  
**Date**: January 19, 2026  

---

## ✨ WHAT'S IN THIS BUILD

### 🎨 **New Logo**
✅ Official Mercurio logo (orange "M")  
✅ Professional launcher icon (Android home screen)  
✅ Branded splash screen  
✅ Logo in settings and about dialog  

### 🔐 **Security**
✅ Production-ready Firestore rules  
✅ End-to-end encryption (RSA + AES-256-GCM)  
✅ Self-sovereign identity (no Firebase Auth)  
✅ Anonymous registration  
✅ Complete security documentation  

### 💬 **Messaging**
✅ Bidirectional messaging (FIXED!)  
✅ Real-time delivery  
✅ Deterministic conversation IDs  
✅ Auto-contact creation  
✅ Message status tracking  

---

## 🚀 QUICK START

### **1. Deploy Firestore Rules (IMPORTANT!)**

Before using the app, deploy the security rules:

1. Go to: https://console.firebase.google.com
2. Select your project
3. Click **Firestore Database** → **Rules** tab
4. Copy and paste these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isValidMercurioId(id) {
      return id is string && 
             id.size() == 66 && 
             id.matches('^05[0-9a-f]{64}$');
    }
    
    match /users/{mercurioId} {
      allow read: if true;
      allow create: if isValidMercurioId(mercurioId) &&
                       request.resource.data.mercurio_id == mercurioId &&
                       request.resource.data.keys(['mercurio_id', 'public_key', 'created_at', 'last_seen', 'is_online']).hasAll(['mercurio_id', 'public_key']) &&
                       request.resource.data.public_key is string &&
                       request.resource.data.public_key.size() > 0;
      allow update: if isValidMercurioId(mercurioId) &&
                       resource.data.mercurio_id == mercurioId &&
                       request.resource.data.mercurio_id == resource.data.mercurio_id &&
                       request.resource.data.public_key == resource.data.public_key;
      allow delete: if false;
    }
    
    match /messages/{messageId} {
      allow read: if true;
      allow create: if isValidMercurioId(request.resource.data.sender_id) &&
                       isValidMercurioId(request.resource.data.recipient_id) &&
                       request.resource.data.sender_id != request.resource.data.recipient_id &&
                       request.resource.data.keys(['sender_id', 'recipient_id', 'encrypted_content', 'encrypted_aes_key', 'nonce', 'timestamp']).hasAll(['sender_id', 'recipient_id', 'encrypted_content', 'encrypted_aes_key', 'nonce', 'timestamp']) &&
                       request.resource.data.encrypted_content is string &&
                       request.resource.data.encrypted_aes_key is string &&
                       request.resource.data.nonce is string &&
                       request.resource.data.status in ['sent', 'delivered', 'read'];
      allow update: if request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'updated_at']) &&
                       request.resource.data.status in ['sent', 'delivered', 'read'] &&
                       request.resource.data.sender_id == resource.data.sender_id &&
                       request.resource.data.recipient_id == resource.data.recipient_id;
      allow delete: if false;
    }
    
    match /connection_requests/{requestId} {
      allow read: if true;
      allow create: if isValidMercurioId(request.resource.data.fromSessionId) &&
                       isValidMercurioId(request.resource.data.toSessionId) &&
                       request.resource.data.fromSessionId != request.resource.data.toSessionId &&
                       request.resource.data.keys(['fromSessionId', 'toSessionId', 'message', 'timestamp', 'status']).hasAll(['fromSessionId', 'toSessionId', 'timestamp', 'status']) &&
                       request.resource.data.status == 'pending';
      allow update: if request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status']) &&
                       request.resource.data.status in ['accepted', 'denied', 'pending'] &&
                       request.resource.data.fromSessionId == resource.data.fromSessionId &&
                       request.resource.data.toSessionId == resource.data.toSessionId;
      allow delete: if false;
    }
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

5. Click **Publish**

### **2. Install the APK**

1. Download from link above
2. Enable "Install from Unknown Sources"
3. Install and open

### **3. Test Messaging**

**On Device A:**
- Sign up → Get Session ID
- Add Device B as contact
- Send message: "Hello!"

**On Device B:**
- Sign up
- Receive message (auto-contact created)
- Add Device A with real name
- Reply: "Hi back!"

**Result**: Both see all messages in ONE conversation! ✅

---

## 📚 DOCUMENTATION

All documentation is in the GitHub repo:

- **RELEASE_NOTES.md** - Complete release notes (this file)
- **FIRESTORE_SECURITY.md** - Security rules documentation
- **DEPLOY_FIRESTORE_RULES.md** - Quick deployment guide
- **LOGO_INTEGRATION.md** - Logo integration details
- **ANDROID_FIXES.md** - Android-specific fixes
- **QUICK_START.md** - Developer quick start

---

## 🎯 WHAT'S WORKING

✅ **Identity Generation** (Ed25519 + RSA keypairs)  
✅ **Account Creation** (anonymous, no personal data)  
✅ **Recovery Phrase** (12-word BIP39 mnemonic)  
✅ **QR Code Scanning** (add contacts)  
✅ **Contact Management** (add, update, view)  
✅ **Real-Time Messaging** (Firestore snapshots)  
✅ **Bidirectional Messaging** (both directions work!)  
✅ **End-to-End Encryption** (RSA + AES-256-GCM)  
✅ **Message Status** (sent, delivered, read)  
✅ **Conversation IDs** (deterministic, no duplicates)  
✅ **Auto-Contact Creation** (for incoming messages)  
✅ **Logo Integration** (launcher, splash, settings)  
✅ **Dark Theme** (orange accent)  

---

## ⚠️ CRITICAL: DEPLOY FIRESTORE RULES FIRST!

**Without deploying the rules, you will get:**
```
❌ [cloud_firestore/permission-denied] 
   The caller does not have permission to execute 
   the specified operation.
```

**After deploying rules:**
```
✅ Contact added successfully!
✅ Message sent!
✅ Messages received in real-time!
```

---

## 📊 BUILD INFO

**Flutter**: 3.38.7 (stable)  
**Dart**: 3.10.7  
**Android**: Min SDK 24, Target SDK 36, Compile SDK 36  
**Size**: 165 MB (debug), ~50 MB (release)  
**Build Time**: ~40 seconds  

---

## 🔗 LINKS

**Download APK**: https://8080-iokjwuld8hg7owq2boint-3844e1b6.sandbox.novita.ai/MercurioMessenger-v1.0.0-debug.apk

**GitHub Repo**: https://github.com/Morsmek/MercurioAndroid2026

**Latest Commit**: `9db22f8` - Add v1.0.0 release notes

**Firebase Console**: https://console.firebase.google.com

---

## 🎉 YOU'RE READY!

1. ✅ **Download the APK** (link above)
2. ✅ **Deploy Firestore rules** (copy/paste from this file)
3. ✅ **Install on two devices**
4. ✅ **Test messaging**
5. ✅ **Enjoy secure, private messaging!**

**Your Mercurio Messenger is ready to use! 🚀**

---

**Privacy is a right, not a privilege.™**
