# Getting Started with Mercurio Messenger

Choose your platform and get started in minutes!

## 🌐 Web App (Instant Preview!)

**Best for**: Quick testing, multi-platform access, instant preview

### Start in 3 Steps

```bash
# 1. Navigate to web app
cd web-app

# 2. Install dependencies
npm install

# 3. Run development server
npm run dev
```

**Open**: http://localhost:3000

That's it! The app is now running in your browser.

### First Time Setup

1. **Create Account** → Click "Create New Account"
2. **Save Recovery Phrase** → Write down your 12 words
3. **Start Chatting** → Add contacts and send messages

---

## 📱 iOS App (Native Performance!)

**Best for**: Native iOS experience, Keychain security, App Store distribution

### Start in 3 Steps

```bash
# 1. Navigate to iOS app
cd MercurioiOS

# 2. Open in Xcode
open Package.swift
# or: xed .

# 3. Run (Cmd+R)
# Select iOS 17+ simulator or device
```

**Requirements**: Mac with Xcode 15+

### First Time Setup

1. **Wait for dependencies** → SPM will download packages automatically
2. **Select device** → Choose iPhone 15 Pro simulator (or any iOS 17+)
3. **Run** → Press Cmd+R or click the Play button

---

## ⚡ Quick Feature Test

### Test Web App (5 minutes)

```bash
cd web-app
npm install && npm run dev
```

1. Open http://localhost:3000
2. Click "Create New Account"
3. Generate identity and save recovery phrase
4. Explore the app (home, settings, QR code)

### Test iOS App (5 minutes)

```bash
cd MercurioiOS && open Package.swift
```

1. Press Cmd+R to run
2. Create new account in simulator
3. Generate identity and view recovery phrase
4. Browse the app interface

---

## 🔄 Test Cross-Platform Messaging

Want to see iOS and Web apps communicate? Follow this:

### Step 1: Run Both Apps

**Terminal 1** (Web App):
```bash
cd web-app
npm run dev
```

**Terminal 2/Xcode** (iOS App):
```bash
cd MercurioiOS
open Package.swift
# Press Cmd+R
```

### Step 2: Create Accounts

**Web App** (Browser):
1. Go to http://localhost:3000
2. Create account as "Alice"
3. Copy Mercurio ID from settings

**iOS App** (Simulator):
1. Create account as "Bob"
2. Copy Mercurio ID from settings

### Step 3: Add Contacts

**Bob (iOS) adds Alice (Web)**:
1. Tap + button
2. Paste Alice's Mercurio ID
3. Enter display name "Alice"

### Step 4: Send Messages!

1. Bob sends message to Alice on iOS
2. Alice receives it on Web in real-time
3. Alice replies on Web
4. Bob sees it on iOS instantly

**They're chatting across platforms!** 🎉

---

## 📋 What You Need

### For Web App
- **Node.js 18+** (check: `node --version`)
- **npm or yarn** (check: `npm --version`)
- **Modern browser** (Chrome, Firefox, Safari, Edge)

### For iOS App
- **macOS** (Sonoma or later)
- **Xcode 15+** (download from App Store)
- **iOS 17+ simulator** (included with Xcode)

### For Both
- **Internet connection** (for Supabase backend)
- **Supabase account** (already configured in `.env` files)

---

## 🆘 Troubleshooting

### Web App Issues

**"Cannot find module"**
```bash
rm -rf node_modules package-lock.json
npm install
```

**"Environment variables not found"**
```bash
# Check .env.local exists in web-app/
cat web-app/.env.local
```

**Port already in use**
```bash
# Use different port
npm run dev -- -p 3001
```

### iOS App Issues

**"Package dependencies not resolved"**
```
File → Packages → Reset Package Caches
File → Packages → Update to Latest Package Versions
```

**"Target requires iOS 17.0"**
```
Select iOS 17+ simulator from device menu
```

**Build errors**
```
Product → Clean Build Folder (Shift+Cmd+K)
Then rebuild (Cmd+B)
```

---

## 📚 Next Steps

### Learn More

**Web App**:
- Read `web-app/README.md`
- Explore `web-app/lib/crypto.ts` for encryption
- Check `web-app/app/` for all pages

**iOS App**:
- Read `MercurioiOS/README.md`
- Read `MercurioiOS/ARCHITECTURE.md`
- Explore `MercurioiOS/Sources/` for code

### Key Files to Explore

```
project/
├── web-app/
│   ├── README.md                     ← Start here for web
│   ├── lib/crypto.ts                 ← Encryption service
│   ├── lib/supabase.ts               ← Backend client
│   └── app/*/page.tsx                ← All pages
│
├── MercurioiOS/
│   ├── README.md                     ← Start here for iOS
│   ├── ARCHITECTURE.md               ← Technical details
│   ├── Sources/Services/             ← Business logic
│   └── Sources/Views/                ← UI screens
│
├── BOTH_APPS_SUMMARY.md              ← Complete overview
└── GETTING_STARTED.md                ← This file
```

---

## 🎯 Choose Your Path

### I Want to Test Quickly
→ **Use Web App** (no Xcode needed, runs in browser)
```bash
cd web-app && npm install && npm run dev
```

### I Want Native iOS Experience
→ **Use iOS App** (requires Mac + Xcode)
```bash
cd MercurioiOS && open Package.swift
```

### I Want to See Cross-Platform
→ **Run Both!** (web in browser + iOS in simulator)
```bash
# Terminal 1
cd web-app && npm run dev

# Terminal 2 / Xcode
cd MercurioiOS && open Package.swift
```

---

## 💡 Pro Tips

### Web App Tips
1. **Use Chrome DevTools** - Inspect crypto operations
2. **Check localStorage** - See stored keys
3. **Network tab** - Watch API calls
4. **Console** - View encryption logs

### iOS App Tips
1. **Use Xcode Console** - See debug prints
2. **Instruments** - Profile performance
3. **Network Link Conditioner** - Test on slow network
4. **Multiple simulators** - Test messaging

### General Tips
1. **Save recovery phrases** - Write them down!
2. **Test on real device** - Better performance
3. **Clear data** - Reset app for fresh start
4. **Read console** - Useful debug info

---

## 🚀 You're Ready!

Both apps are fully functional and ready to use.

**Web App**: Instant browser preview
**iOS App**: Native iPhone/iPad experience
**Backend**: Shared Supabase database

**Choose your platform and start building!** 🔐

---

**Questions?** Check the README files in each app directory.

**Privacy is a right, not a privilege.**
