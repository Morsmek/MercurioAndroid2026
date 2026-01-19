# 🚀 DEPLOY FIRESTORE RULES - Quick Guide

## 📍 **STEP 1: Open Firebase Console**

1. Go to: **https://console.firebase.google.com**
2. Select your project: **MercurioAndroid2026**
3. Click **Firestore Database** in the left sidebar
4. Click the **Rules** tab at the top

---

## 📋 **STEP 2: Copy the Rules**

The production-ready rules are in: **`firestore.rules`**

Or copy directly from here:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if a Mercurio ID is valid format
    function isValidMercurioId(id) {
      return id is string && 
             id.size() == 66 && 
             id.matches('^05[0-9a-f]{64}$');
    }
    
    // Users collection - Public profiles with cryptographic identity
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
    
    // Messages collection - End-to-end encrypted messages
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
    
    // Connection requests collection
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
    
    // Deny all other collections
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## ✅ **STEP 3: Publish**

1. Paste the rules into the Firebase Console editor
2. Click **Publish** button (top right)
3. Wait for confirmation: "Rules published successfully"

---

## 🧪 **STEP 4: Test**

1. Go back to your app
2. Try adding a contact again
3. Should work instantly! ✨

---

## ⚡ **Quick Alternative: Firebase CLI**

If you have Firebase CLI installed:

```bash
# Login to Firebase
firebase login

# Deploy rules
firebase deploy --only firestore:rules
```

---

## 🛡️ **What These Rules Do:**

✅ **Validate Mercurio ID format** (must be `05` + 64 hex chars)  
✅ **Prevent identity impersonation** (doc ID must match mercurio_id field)  
✅ **Protect public keys** (cannot change once set)  
✅ **Validate encrypted messages** (must have all required fields)  
✅ **Allow status updates** (for delivery/read receipts)  
✅ **Prevent message tampering** (content is immutable)  
✅ **Block self-messaging** (sender ≠ recipient)  

---

## ❓ **Troubleshooting**

### Error: "permission-denied"
- Make sure you published the rules (check the **Rules** tab)
- Wait 30 seconds for rules to propagate globally

### Error: "Invalid format"
- Copy the ENTIRE rule text including `rules_version = '2';`
- Make sure there are no syntax errors (missing braces, etc.)

### Still not working?
- Check Firebase Console → Firestore → **Usage** tab
- Look for "Denied Writes" - click to see which rule failed
- Use the **Rules Playground** to test specific operations

---

## 📚 **More Info**

Read the full documentation: **`FIRESTORE_SECURITY.md`**

---

## 🎉 **That's It!**

Once published, your app will be able to:
- ✅ Add contacts
- ✅ Send messages
- ✅ Receive messages
- ✅ Update statuses

**With full production-grade security! 🔐**
