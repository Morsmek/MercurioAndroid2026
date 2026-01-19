# 🔥 URGENT: Deploy Updated Firestore Rules

## The Issue You're Experiencing

You're getting Firebase errors when adding users because your **Firestore security rules don't match the data structure** your app is sending.

## ✅ What Was Fixed

Updated `firestore.rules` to accept **both** public key formats:
- Old format: single `public_key` field
- New format: `ed25519_public_key` + `rsa_public_key` (what your app actually sends)

## 📋 Deploy Instructions (3 Simple Steps)

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com

### Step 2: Navigate to Firestore Rules
1. Select your project
2. Click **"Firestore Database"** in the left sidebar
3. Click the **"Rules"** tab at the top

### Step 3: Deploy the Rules
1. Copy the **entire contents** of `firestore.rules` file
2. Paste into the Firebase console (replace everything)
3. Click **"Publish"** button
4. Wait 30 seconds for rules to propagate globally

## 🧪 Test It Works

1. Create a new user in your app
2. Try to add another user as a contact
3. Should now work without permission errors!

## 🔍 What Changed in the Rules

**Before:**
```javascript
allow create: if ... &&
  request.resource.data.public_key is string &&
  request.resource.data.public_key.size() > 0;
```

**After:**
```javascript
allow create: if ... &&
  (
    // Old schema with single public_key
    (request.resource.data.keys().hasAny(['public_key']) && ...) ||
    // New schema with separate ed25519 and rsa keys
    (request.resource.data.keys().hasAny(['ed25519_public_key', 'rsa_public_key']) && ...)
  );
```

## ⚠️ Common Errors & Solutions

### "permission-denied"
**Cause:** Security rules not deployed or wrong format
**Solution:** Deploy the updated `firestore.rules` file

### "PERMISSION_DENIED: Missing or insufficient permissions"
**Cause:** Old rules still active
**Solution:** Wait 30-60 seconds after publishing, then try again

### "User already exists"
**Cause:** User document already created with old schema
**Solution:** Delete the user document in Firebase console and re-register

## 📞 Still Having Issues?

1. **Check Firebase Console:**
   - Firestore Database → Rules → Make sure new rules are published
   - Check "Last published" timestamp

2. **Clear App Data:**
   - Settings → Apps → Mercurio → Clear Data
   - Re-register with a fresh identity

3. **Check Logs:**
   - Look for specific error messages in the app
   - The app now shows more detailed error messages

## ✅ Verification Checklist

- [ ] Firestore rules copied from `firestore.rules`
- [ ] Rules published in Firebase Console
- [ ] Waited 30 seconds for propagation
- [ ] Tested creating new user
- [ ] Tested adding contact
- [ ] No more "permission-denied" errors

---

**Updated:** January 19, 2026
**Status:** ✅ Rules Fixed - Ready to Deploy
