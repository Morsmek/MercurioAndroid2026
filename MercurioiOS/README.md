# Mercurio Messenger - iOS

A native iOS end-to-end encrypted messaging app built with SwiftUI and Supabase. This is a port of the Mercurio Messenger Flutter app, reimagined for iOS with native performance and design.

## Features

### Security & Privacy
- **End-to-end encryption** using hybrid RSA-2048 + AES-256-GCM
- **Anonymous registration** - no phone number, email, or personal information required
- **Self-sovereign identity** using Ed25519 keypairs
- **12-word recovery phrase** (BIP39 standard) for account backup
- **Local key storage** using iOS Keychain
- **Session IDs** in format "05" + 64 hex characters

### Messaging
- **Real-time encrypted messaging** via Supabase Realtime
- **Message status indicators** (sending, sent, delivered, read)
- **Conversation management** with contact list
- **QR code sharing** for easy contact addition
- **Contact verification** with display names

### User Interface
- **Native SwiftUI design** with dark theme
- **Orange accent color** matching Mercurio brand
- **Smooth animations** and transitions
- **iOS-native gestures** and navigation
- **Accessibility support** (VoiceOver ready)

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**
- **Supabase account** with configured project

## Architecture

### Models
- `User` - User identity with public keys
- `Contact` - Contact list entries
- `Message` - Encrypted messages
- `Conversation` - Chat threads
- `DecryptedMessage` - Decrypted message content (memory only)

### Services
- `CryptoService` - Handles all cryptographic operations
  - Ed25519 keypair generation and management
  - RSA-2048 keypair generation
  - AES-256-GCM encryption/decryption
  - BIP39 recovery phrase generation
  - Session ID generation

- `KeychainService` - Secure key storage
  - Ed25519 private/public keys
  - RSA private/public keys
  - Mercurio ID (Session ID)
  - Recovery phrase

- `SupabaseService` - Backend communication
  - User public key upload/fetch
  - Contact management
  - Message sending/receiving
  - Real-time message synchronization
  - Conversation management

### Views
- `SplashView` - App launch screen
- `WelcomeView` - Onboarding and authentication entry
- `RegisterView` - New account creation
- `RecoveryPhraseView` - Recovery phrase display
- `RestoreView` - Account restoration from phrase
- `HomeView` - Main app with tabs (Chats, Groups, Settings)
- `ChatView` - Individual conversation
- `AddContactView` - Add new contacts
- `QRScannerView` - Scan QR codes
- `SettingsView` - App settings and profile
- `QRCodeView` - Display your QR code

## Setup

### 1. Install Dependencies

The app uses Swift Package Manager. Dependencies are defined in `Package.swift`:

- `supabase-swift` - Supabase client for iOS
- `CryptoSwift` - Additional cryptographic functions
- `BIP39` - BIP39 mnemonic phrase generation

### 2. Configure Supabase

Create a `.env` file or set environment variables:

```bash
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Database Setup

The Supabase database schema is automatically created when you run the migration. The schema includes:

- `users` table - Store public keys and online status
- `contacts` table - User contact lists
- `messages` table - Encrypted messages
- `conversations` table - Conversation metadata

Row Level Security (RLS) is enabled on all tables with appropriate policies.

### 4. Build and Run

Open the project in Xcode:

```bash
cd MercurioiOS
xed .
```

Build and run on simulator or device (iOS 17.0+).

## How It Works

### Identity Generation

1. User taps "Create New Account"
2. App generates Ed25519 keypair for identity
3. App generates RSA-2048 keypair for message encryption
4. Session ID is created: "05" + hex(Ed25519PublicKey)
5. 12-word BIP39 recovery phrase is generated
6. All keys are stored in iOS Keychain
7. Public keys are uploaded to Supabase

### Message Encryption

1. Sender generates random 256-bit AES key
2. Message is encrypted with AES-256-GCM
3. AES key is encrypted with recipient's RSA public key
4. Encrypted message + encrypted key + nonce + MAC are sent
5. Recipient decrypts AES key with their RSA private key
6. Recipient decrypts message with AES key

### Adding Contacts

1. User scans QR code or enters Mercurio ID manually
2. App fetches contact's public keys from Supabase
3. Contact is saved locally with display name
4. Conversation ID is generated (sorted IDs joined with "_")

### Sending Messages

1. User types message in chat
2. App fetches recipient's RSA public key
3. Message is encrypted using hybrid encryption
4. Encrypted message is sent to Supabase
5. Conversation is updated with last message timestamp
6. Real-time listener notifies recipient

### Receiving Messages

1. Supabase Realtime sends new message event
2. App fetches encrypted message
3. App decrypts message using own RSA private key
4. Decrypted message is displayed in chat
5. Message status is updated to "read"

## Security Considerations

### What's Secure

✅ **Private keys never leave device** - Stored in iOS Keychain
✅ **End-to-end encryption** - Messages encrypted client-side
✅ **No metadata collection** - No phone numbers or emails
✅ **Self-sovereign identity** - You control your keys
✅ **Recovery phrase** - Backup without central authority

### What's Not Yet Implemented

⚠️ **Perfect forward secrecy** - Same keys used for all messages
⚠️ **Contact verification** - No safety numbers yet
⚠️ **Backup encryption** - Recovery phrase not encrypted at rest
⚠️ **Disappearing messages** - Messages persist indefinitely

### Best Practices

1. **Always save recovery phrase** - Write it down on paper
2. **Never share recovery phrase** - It gives full account access
3. **Verify contacts** - Confirm identity through another channel
4. **Keep app updated** - Security improvements are ongoing

## Roadmap

### v1.1 (Next)
- [ ] Safety numbers for contact verification
- [ ] Profile pictures
- [ ] Message search
- [ ] Contact nickname editing
- [ ] Conversation archiving

### v1.2
- [ ] Image/media sharing with encryption
- [ ] Voice messages
- [ ] File sharing
- [ ] Group chats (basic)
- [ ] Message deletion

### v2.0
- [ ] Perfect forward secrecy (Signal Protocol)
- [ ] Disappearing messages
- [ ] Video calls (WebRTC)
- [ ] Voice calls
- [ ] Multi-device support

## Development

### Project Structure

```
MercurioiOS/
├── Package.swift              # Swift Package Manager manifest
├── Sources/
│   ├── MercurioApp.swift     # App entry point
│   ├── Models/               # Data models
│   │   ├── User.swift
│   │   ├── Contact.swift
│   │   ├── Message.swift
│   │   └── Conversation.swift
│   ├── Services/             # Business logic
│   │   ├── CryptoService.swift
│   │   ├── KeychainService.swift
│   │   └── SupabaseService.swift
│   └── Views/                # SwiftUI views
│       ├── SplashView.swift
│       ├── WelcomeView.swift
│       ├── RegisterView.swift
│       ├── RecoveryPhraseView.swift
│       ├── RestoreView.swift
│       ├── HomeView.swift
│       ├── ChatView.swift
│       ├── AddContactView.swift
│       └── SettingsView.swift
└── README.md
```

### Code Style

- Use SwiftUI for all UI
- Use async/await for asynchronous operations
- Use actors for thread-safe services
- Follow Swift API Design Guidelines
- Document public APIs with doc comments

### Testing

Coming soon:
- Unit tests for CryptoService
- Integration tests for SupabaseService
- UI tests for critical flows

## Troubleshooting

### App Won't Build

**Error**: "Cannot find package"
**Solution**: File → Packages → Reset Package Caches

**Error**: "Target requires iOS 17.0"
**Solution**: Update deployment target in project settings

### Messages Not Sending

**Issue**: Messages stuck in "sending" state
**Solution**: Check Supabase connection and RLS policies

**Issue**: "Recipient public key not found"
**Solution**: Ensure recipient has uploaded their keys

### Keys Not Saving

**Issue**: "Keychain access denied"
**Solution**: Reset iOS Simulator or check keychain access groups

## License

MIT License - See main project repository

## Privacy

**Privacy is a right, not a privilege.**

Mercurio Messenger:
- Collects no personal information
- Stores no unencrypted messages
- Tracks no analytics or telemetry
- Shares no data with third parties

## Contributing

This is a demonstration iOS app. For production use:

1. Implement proper error handling
2. Add comprehensive tests
3. Perform security audit
4. Add crash reporting
5. Implement proper logging
6. Add analytics (privacy-preserving)

## Support

For issues or questions:
- Open an issue on GitHub
- Check existing documentation
- Review security considerations

---

**Version**: 1.0.0
**Platform**: iOS 17.0+
**Language**: Swift 5.9+
**Framework**: SwiftUI
**Backend**: Supabase

Built with privacy and security in mind. 🔐
