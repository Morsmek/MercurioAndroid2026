# Mercurio iOS - Architecture

This document provides a deep dive into the architecture and design decisions of the Mercurio iOS app.

## Overview

Mercurio iOS is a native SwiftUI application that implements end-to-end encrypted messaging with self-sovereign identity. It's built on modern iOS technologies and follows Apple's best practices.

## Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Concurrency**: async/await, actors
- **Backend**: Supabase (PostgreSQL + Realtime)
- **Cryptography**: CryptoKit, CryptoSwift, Security framework
- **Package Manager**: Swift Package Manager (SPM)

## Architecture Pattern

The app follows a **Service-Oriented Architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│           SwiftUI Views                 │
│  (Presentation Layer)                   │
└─────────────┬───────────────────────────┘
              │
              ├── AppState (Observable)
              │
┌─────────────▼───────────────────────────┐
│           Services                      │
│  (Business Logic Layer)                 │
│                                         │
│  ┌──────────────┐  ┌─────────────┐    │
│  │CryptoService │  │SupabaseService│   │
│  │   (Actor)    │  │   (Actor)    │    │
│  └──────┬───────┘  └──────┬──────┘    │
│         │                  │            │
│  ┌──────▼──────────────────▼──────┐   │
│  │    KeychainService (Actor)     │   │
│  └────────────────────────────────┘   │
└─────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│           Models                        │
│  (Data Layer)                           │
│                                         │
│  User, Contact, Message, Conversation   │
└─────────────────────────────────────────┘
```

## Core Components

### 1. AppState

**Purpose**: Global application state management

**Type**: `@MainActor class ObservableObject`

**Responsibilities**:
- Track authentication state
- Store current user's Mercurio ID
- Coordinate app navigation flow
- Manage loading states

**Key Properties**:
- `isLoading: Bool` - App initialization state
- `hasIdentity: Bool` - Whether user is authenticated
- `mercurioId: String?` - Current user's Session ID

### 2. CryptoService

**Purpose**: All cryptographic operations

**Type**: `actor` (thread-safe)

**Responsibilities**:
- Identity generation and restoration
- Key management
- Message encryption/decryption
- Recovery phrase generation

**Key Methods**:
- `generateIdentity()` - Create new user identity
- `restoreFromPhrase(_:)` - Restore from recovery phrase
- `encryptMessage(_:recipientRSAPublicKey:)` - Encrypt message
- `decryptMessage(_:)` - Decrypt received message
- `hasIdentity()` - Check if identity exists
- `clearAllKeys()` - Logout

**Cryptographic Algorithms**:
- **Ed25519**: Identity keypair (32-byte public key)
- **RSA-2048**: Message key exchange (OAEP with SHA-256)
- **AES-256-GCM**: Symmetric message encryption
- **BIP39**: 12-word recovery phrase generation

**Security Considerations**:
- All private keys stored in Keychain
- Keys never transmitted over network
- Random number generation uses `SecRandomCopyBytes`
- Actor ensures thread-safe operations

### 3. KeychainService

**Purpose**: Secure storage for sensitive data

**Type**: `actor` (thread-safe)

**Stored Items**:
- Ed25519 private/public keys
- RSA private/public keys
- Mercurio ID (Session ID)
- Recovery phrase

**Security Level**: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`

**Key Methods**:
- `save(ed25519PublicKey:ed25519PrivateKey:...)` - Store all keys
- `getMercurioId()` - Retrieve Session ID
- `getRecoveryPhrase()` - Retrieve recovery phrase
- `getRSAPublicKey()` - Retrieve RSA public key
- `getRSAPrivateKey()` - Retrieve RSA private key
- `deleteAll()` - Clear all stored data

### 4. SupabaseService

**Purpose**: Backend communication

**Type**: `actor` (thread-safe)

**Responsibilities**:
- User registration (public key upload)
- Contact management
- Message sending/receiving
- Conversation management
- Real-time message synchronization

**Key Methods**:
- `uploadUserPublicKeys(user:)` - Register new user
- `fetchUserPublicKeys(mercurioId:)` - Get contact's keys
- `addContact(_:)` - Add new contact
- `fetchContacts(for:)` - Get user's contacts
- `sendMessage(_:)` - Send encrypted message
- `fetchMessages(for:)` - Get conversation messages
- `subscribeToMessages(conversationId:callback:)` - Real-time sync

**Database Schema**:
See database migrations for full schema details.

## Data Flow

### Message Sending Flow

```
User types message
       │
       ├──> ChatView captures text
       │
       ├──> Fetch recipient's RSA public key (SupabaseService)
       │
       ├──> Encrypt message (CryptoService)
       │    ├── Generate random AES-256 key
       │    ├── Encrypt message with AES-GCM
       │    ├── Encrypt AES key with recipient's RSA public key
       │    └── Return {encryptedContent, encryptedAesKey, nonce, mac}
       │
       ├──> Create Message model
       │
       ├──> Send to Supabase (SupabaseService)
       │    ├── Insert into messages table
       │    └── Update conversation metadata
       │
       └──> Update local UI
            └── Append to messages array
```

### Message Receiving Flow

```
Supabase Realtime event fires
       │
       ├──> SupabaseService receives event
       │
       ├──> Parse encrypted message
       │
       ├──> Decrypt message (CryptoService)
       │    ├── Decrypt AES key with own RSA private key (Keychain)
       │    ├── Decrypt message content with AES key
       │    └── Return plaintext
       │
       ├──> Create DecryptedMessage model
       │
       ├──> Update UI (ChatView)
       │    └── Append to messages array
       │
       └──> Mark as read (SupabaseService)
            └── Update read_at timestamp
```

### Identity Generation Flow

```
User taps "Create New Account"
       │
       ├──> RegisterView initiates generation
       │
       ├──> CryptoService.generateIdentity()
       │    │
       │    ├── Generate Ed25519 keypair
       │    │   └── Public key becomes Session ID ("05" + hex)
       │    │
       │    ├── Generate BIP39 recovery phrase (12 words)
       │    │
       │    ├── Generate RSA-2048 keypair
       │    │
       │    └── Store all keys (KeychainService)
       │        └── iOS Keychain (encrypted at rest)
       │
       ├──> Upload public keys (SupabaseService)
       │    └── Insert into users table
       │
       ├──> Display recovery phrase (RecoveryPhraseView)
       │
       └──> User confirms phrase saved
            └── Navigate to HomeView
```

## Security Architecture

### Threat Model

**Protected Against**:
- ✅ Server compromise (E2EE)
- ✅ Network eavesdropping (TLS + E2EE)
- ✅ Device theft (Keychain encryption)
- ✅ Man-in-the-middle (Public key exchange)

**Not Protected Against**:
- ❌ Device compromise (if attacker has device access + passcode)
- ❌ Supply chain attacks (trust in dependencies)
- ❌ Social engineering (user gives away recovery phrase)
- ❌ Quantum computers (RSA/ECC vulnerable)

### Encryption Details

#### Identity (Ed25519)
- **Key Size**: 256 bits
- **Purpose**: Session ID generation, identity verification
- **Algorithm**: Curve25519 (Edwards curve)
- **Security**: ~128-bit security level

#### Key Exchange (RSA-2048)
- **Key Size**: 2048 bits
- **Purpose**: Encrypt AES keys for message encryption
- **Padding**: OAEP with SHA-256
- **Security**: ~112-bit security level

#### Message Encryption (AES-256-GCM)
- **Key Size**: 256 bits
- **Mode**: Galois/Counter Mode (authenticated encryption)
- **Nonce**: 12 bytes (96 bits), randomly generated per message
- **Security**: ~256-bit security level

### Key Storage

All private keys are stored in **iOS Keychain** with:
- **Encryption**: AES-256 (hardware-backed on devices with Secure Enclave)
- **Access**: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Protection**: Requires device unlock to access
- **Backup**: Keys are NOT included in iCloud Keychain backup

## Performance Considerations

### Concurrency

All services are `actor`s, ensuring:
- Thread-safe access to shared state
- No data races
- Automatic synchronization
- Cooperative execution

### Memory Management

- **Models**: Value types (`struct`) - copied on assignment
- **Services**: Reference types (`actor`) - shared instances
- **Views**: Lightweight, recreated on state changes
- **Encrypted data**: Cleared from memory after decryption

### Network Optimization

- **Lazy loading**: Messages fetched per conversation
- **Real-time**: WebSocket for instant delivery
- **Batching**: Multiple operations combined when possible
- **Caching**: Public keys cached after first fetch

## Testing Strategy

### Unit Tests
- CryptoService encryption/decryption
- KeychainService storage/retrieval
- Model encoding/decoding
- Utility functions

### Integration Tests
- SupabaseService API calls
- End-to-end message flow
- Key exchange workflow
- Conversation management

### UI Tests
- User flows (registration, login, chat)
- Error handling
- Navigation
- Accessibility

## Future Improvements

### Planned Features
1. **Perfect Forward Secrecy** - Implement Signal Protocol
2. **Multi-device support** - Sync across devices
3. **Disappearing messages** - Automatic deletion
4. **Media encryption** - End-to-end encrypted images/files
5. **Group chats** - Multi-party encryption

### Performance Optimizations
1. **Key caching** - Reduce Keychain access
2. **Message pagination** - Load messages incrementally
3. **Background sync** - Fetch messages in background
4. **Push notifications** - APNs integration

### Security Enhancements
1. **Safety numbers** - Verify contact identity
2. **Key rotation** - Periodic key refresh
3. **Sealed sender** - Hide sender metadata
4. **Secure attachments** - Encrypted media storage

## Dependencies

### First-Party (Apple)
- **SwiftUI** - UI framework
- **CryptoKit** - Apple's crypto framework
- **Security** - Keychain and secure random

### Third-Party
- **supabase-swift** - Backend client (MIT License)
- **CryptoSwift** - Additional crypto (zlib License)
- **swift-bip39** - Mnemonic generation (MIT License)

All dependencies are managed via Swift Package Manager and regularly audited for security vulnerabilities.

## Design Decisions

### Why SwiftUI?
- Modern, declarative UI
- Native performance
- Automatic state management
- Future-proof

### Why Actors?
- Thread-safety without locks
- Compiler-enforced isolation
- Modern Swift concurrency
- Better than GCD/OperationQueue

### Why Supabase?
- Open-source PostgreSQL
- Real-time subscriptions
- RESTful API
- Row Level Security

### Why Hybrid Encryption?
- RSA for key exchange (public key crypto)
- AES for message content (faster symmetric crypto)
- Industry standard (used by Signal, WhatsApp, etc.)

### Why Ed25519?
- Faster than RSA for signing
- Smaller keys (32 bytes vs 256+ bytes)
- Secure (equivalent to 3072-bit RSA)
- Modern standard (SSH, Signal, etc.)

## Maintenance

### Code Quality
- SwiftLint for style consistency
- Code reviews required
- Documentation for public APIs
- Regular dependency updates

### Security
- Annual security audits
- Dependency vulnerability scanning
- Incident response plan
- Bug bounty program (future)

### Performance
- Profiling with Instruments
- Memory leak detection
- Network usage monitoring
- Battery impact optimization

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Maintained By**: Mercurio Team

For questions about architecture decisions, open an issue on GitHub.
