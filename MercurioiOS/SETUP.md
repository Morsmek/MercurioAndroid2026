# Mercurio iOS - Setup Guide

This guide will help you get the Mercurio iOS app up and running.

## Prerequisites

1. **macOS** with Xcode 15.0 or later
2. **iOS 17.0+** device or simulator
3. **Supabase account** (already configured in this project)
4. **Swift 5.9+**

## Quick Start

### 1. Open in Xcode

```bash
cd MercurioiOS
open Package.swift
```

Or use Xcode:
```bash
xed .
```

### 2. Configure Environment

The app reads Supabase configuration from environment variables. These should already be set in the project's `.env` file:

- `VITE_SUPABASE_URL` - Your Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Your Supabase anonymous key

### 3. Install Dependencies

Dependencies are managed via Swift Package Manager and will be automatically resolved when you open the project:

- **supabase-swift** (2.0.0+) - Supabase client for iOS
- **CryptoSwift** (1.8.0+) - Additional crypto functions
- **swift-bip39** (1.0.0+) - BIP39 mnemonic generation

If packages don't resolve automatically:
1. Go to **File → Packages → Resolve Package Versions**
2. Or **File → Packages → Reset Package Caches**

### 4. Build and Run

1. Select your target device or simulator (iOS 17.0+)
2. Press `Cmd+R` or click the "Run" button
3. App will build and launch

## Database Setup

The Supabase database schema is already created with the following tables:

### Tables

1. **users** - Public keys and user status
   - `mercurio_id` (primary key)
   - `ed25519_public_key`
   - `rsa_public_key_modulus`
   - `rsa_public_key_exponent`
   - `created_at`, `last_seen`, `is_online`

2. **contacts** - User contact lists
   - `id` (UUID)
   - `user_mercurio_id`, `contact_mercurio_id`
   - `display_name`, `verified`
   - `created_at`

3. **messages** - Encrypted messages
   - `id` (UUID)
   - `conversation_id`
   - `sender_mercurio_id`, `recipient_mercurio_id`
   - `encrypted_content`, `encrypted_aes_key`, `nonce`, `mac`
   - `created_at`, `read_at`, `status`

4. **conversations** - Conversation metadata
   - `id` (text, primary key)
   - `participant1_id`, `participant2_id`
   - `last_message`, `last_message_at`
   - `created_at`, `updated_at`

### Row Level Security (RLS)

RLS is enabled on all tables with policies:
- Users can read all public keys
- Users can only manage their own contacts
- Users can only read messages they sent or received
- Users can only access their own conversations

## Project Structure

```
MercurioiOS/
├── Package.swift              # SPM dependencies
├── Info.plist                 # App configuration
├── Sources/
│   ├── MercurioApp.swift     # App entry point
│   ├── Models/               # Data models (User, Contact, Message, Conversation)
│   ├── Services/             # Business logic (Crypto, Keychain, Supabase)
│   └── Views/                # SwiftUI views (all screens)
├── README.md                  # Full documentation
└── SETUP.md                   # This file
```

## First Run

1. **Launch app** - You'll see the splash screen, then welcome screen
2. **Create account** - Tap "Create New Account"
3. **Save recovery phrase** - Write down your 12-word phrase
4. **You're in!** - Start adding contacts and chatting

## Adding Contacts

### Method 1: QR Code

1. Go to Settings → Show My QR Code
2. Have friend scan your QR code
3. They'll add you with a display name

### Method 2: Manual Entry

1. Tap "+" button on Chats tab
2. Enter Mercurio ID (66 characters starting with "05")
3. Enter display name
4. Tap "Add Contact"

## Testing with Two Devices

1. Run app on Device A, create account, copy Mercurio ID
2. Run app on Device B (or simulator), create account
3. On Device B, add Device A as contact using their ID
4. Send message from Device B to Device A
5. Message appears on Device A (encrypted end-to-end)
6. Reply from Device A to Device B
7. Both devices should see messages in same conversation

## Troubleshooting

### Build Errors

**Issue**: "Cannot find package 'supabase-swift'"
**Fix**: File → Packages → Reset Package Caches

**Issue**: "Target requires iOS 17.0 or later"
**Fix**: Update deployment target in project settings to iOS 17.0+

### Runtime Errors

**Issue**: "Supabase configuration missing"
**Fix**: Ensure environment variables are set in `.env` file

**Issue**: "Keychain access denied"
**Fix**: Reset iOS Simulator (Device → Erase All Content and Settings)

**Issue**: Messages not sending
**Fix**:
1. Check internet connection
2. Verify Supabase project is active
3. Check RLS policies are deployed

### Database Issues

**Issue**: "Permission denied"
**Fix**: Verify RLS policies are correctly deployed in Supabase

**Issue**: "User not found"
**Fix**: Ensure user's public keys were uploaded during registration

## Development Tips

### Debug Mode

To enable verbose logging, add to your scheme:
1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add `DEBUG` = `1`

### Testing Encryption

The app uses:
- **Ed25519** for identity (Session ID generation)
- **RSA-2048** for key exchange (encrypting AES keys)
- **AES-256-GCM** for message encryption (actual message content)

All private keys are stored in iOS Keychain and never leave the device.

### Viewing Database

Use Supabase Dashboard:
1. Go to Supabase project
2. Click "Table Editor"
3. View users, contacts, messages, conversations tables
4. **Note**: Messages are encrypted, you'll only see ciphertext

## Next Steps

1. **Read full docs** - See `README.md` for complete documentation
2. **Test features** - Try all screens and functionality
3. **Check security** - Review crypto implementation
4. **Build for TestFlight** - Archive and distribute to testers

## Known Limitations

- QR scanner is a placeholder (needs camera implementation)
- No image/media sharing yet
- No push notifications configured
- Group chats not implemented
- Safety numbers not implemented

## Support

For issues:
1. Check this guide first
2. Review `README.md` for detailed documentation
3. Check Supabase logs for backend errors
4. Review Xcode console for iOS errors

---

**Ready to build?** Open `Package.swift` in Xcode and press Run!

🔐 **Privacy is a right, not a privilege.**
