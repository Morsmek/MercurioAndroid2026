# Mercurio iOS - Quick Start

Get up and running with Mercurio iOS in 5 minutes!

## What You Need

- Mac with macOS Sonoma or later
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Supabase account (already configured)

## Step 1: Open the Project (30 seconds)

```bash
cd MercurioiOS
xed .
```

This opens the project in Xcode.

## Step 2: Wait for Dependencies (2 minutes)

Xcode will automatically download and resolve dependencies:
- supabase-swift
- CryptoSwift
- swift-bip39

Watch the progress in the top status bar.

## Step 3: Select a Device (10 seconds)

Click the device selector at the top of Xcode and choose:
- Your iPhone (if connected), or
- iPhone 15 Pro simulator (or any iOS 17+ simulator)

## Step 4: Run! (30 seconds)

Press `Cmd+R` or click the ▶️ Play button.

The app will build and launch on your selected device.

## Step 5: Create Your Account (2 minutes)

1. **Welcome Screen** - Tap "Create New Account"
2. **Generate Identity** - Tap "Generate Identity" button
3. **Save Recovery Phrase** - Write down your 12 words (very important!)
4. **Done!** - Tap "I've Saved My Recovery Phrase"

You're now in the app!

## What to Try Next

### Add a Contact

1. Tap the **+** button in the top right
2. Enter a Mercurio ID (66 chars, starts with "05")
3. Give them a display name
4. Tap "Add Contact"

### Send a Message

1. Tap on a conversation (or create one by adding a contact)
2. Type your message
3. Tap the send button (↑)
4. Message is encrypted and sent!

### View Your QR Code

1. Go to **Settings** tab
2. Tap "Show My QR Code"
3. Share with friends to add you

### Check Your Recovery Phrase

1. Go to **Settings** tab
2. Tap "Recovery Phrase"
3. Copy or view your 12 words

## Testing with Two Devices

Want to test messaging? You need two instances:

### Option 1: Simulator + Physical Device

1. Run on **Simulator** - Create account "Alice"
2. Copy Alice's Mercurio ID
3. Run on **iPhone** - Create account "Bob"
4. Bob adds Alice as contact using her ID
5. Bob sends message to Alice
6. Alice receives encrypted message!

### Option 2: Two Simulators

1. Run on **iPhone 15 Pro** simulator - Create "Alice"
2. Stop the app
3. Run on **iPhone 15** simulator - Create "Bob"
4. Add Alice's ID to Bob's contacts
5. Send messages between them

## Troubleshooting

### "Cannot find package 'supabase-swift'"

**Solution**:
```
File → Packages → Reset Package Caches
```

### "Target requires iOS 17.0"

**Solution**: Select an iOS 17+ simulator or update your device

### "Supabase configuration missing"

**Solution**: Check that `.env` file exists with:
```
VITE_SUPABASE_URL=https://...
VITE_SUPABASE_ANON_KEY=...
```

### Messages not sending

**Check**:
1. Internet connection
2. Supabase project is active
3. Both users have uploaded their public keys

## Architecture Overview

```
┌─────────────────────────────────────┐
│       SwiftUI Views                 │  ← What you see
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│       Services (Actors)             │  ← Business logic
│  • CryptoService                    │
│  • SupabaseService                  │
│  • KeychainService                  │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│       Supabase Backend              │  ← Database + Realtime
└─────────────────────────────────────┘
```

## Key Features

✅ **End-to-end encryption** - Messages encrypted on device
✅ **Anonymous registration** - No phone or email required
✅ **Recovery phrase** - 12 words to restore account
✅ **QR code sharing** - Easy contact addition
✅ **Real-time messaging** - Instant delivery
✅ **Native iOS** - SwiftUI, smooth and fast

## Important Security Notes

### ✅ DO:
- Save your recovery phrase safely (write it down!)
- Keep your device secure with a passcode
- Verify contacts through another channel
- Update the app regularly

### ❌ DON'T:
- Share your recovery phrase with anyone
- Take screenshots of recovery phrase
- Store recovery phrase digitally
- Reuse recovery phrases

## Next Steps

1. **Read full docs**: See `README.md` for complete documentation
2. **Architecture**: See `ARCHITECTURE.md` for technical details
3. **Setup guide**: See `SETUP.md` for detailed setup instructions
4. **Try all features**: Explore Settings, add contacts, send messages

## Getting Help

- **Build issues**: Check `SETUP.md`
- **Usage questions**: Check `README.md`
- **Architecture questions**: Check `ARCHITECTURE.md`
- **Bugs**: Open an issue on GitHub

## What's Different from Flutter Version?

- **Native iOS** - SwiftUI instead of Flutter
- **Better performance** - Native code, no bridge
- **iOS design** - Follows Apple Human Interface Guidelines
- **Modern Swift** - Uses async/await, actors
- **Supabase backend** - Instead of Firebase

## File Structure

```
MercurioiOS/
├── Sources/
│   ├── MercurioApp.swift          ← Entry point
│   ├── Models/                     ← Data structures
│   ├── Services/                   ← Business logic
│   │   ├── CryptoService.swift    ← Encryption
│   │   ├── KeychainService.swift  ← Secure storage
│   │   └── SupabaseService.swift  ← Backend API
│   └── Views/                      ← UI screens
│       ├── WelcomeView.swift
│       ├── RegisterView.swift
│       ├── HomeView.swift
│       ├── ChatView.swift
│       └── SettingsView.swift
├── Package.swift                   ← Dependencies
├── Info.plist                      ← App config
├── README.md                       ← Full docs
├── SETUP.md                        ← Detailed setup
├── ARCHITECTURE.md                 ← Technical details
└── QUICK_START.md                  ← This file
```

## Common Tasks

### Reset the App
```bash
# Reset simulator
Device → Erase All Content and Settings
```

### View Logs
```bash
# In Xcode console
# Or use Console app and filter by "Mercurio"
```

### Clean Build
```bash
# In Xcode
Product → Clean Build Folder (Shift+Cmd+K)
```

### Update Dependencies
```bash
# In Xcode
File → Packages → Update to Latest Package Versions
```

---

## Ready to Code?

Open `Sources/Views/WelcomeView.swift` and start customizing!

All views are in `Sources/Views/`, all logic in `Sources/Services/`.

**Happy coding!** 🚀

---

**Privacy is a right, not a privilege.** 🔐
