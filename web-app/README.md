# Mercurio Messenger - Web App

A modern web-based end-to-end encrypted messaging application built with Next.js, TypeScript, and Supabase.

## Features

- **End-to-end encryption** using Web Crypto API (RSA-2048 + AES-256-GCM)
- **Anonymous registration** - no phone number or email required
- **Self-sovereign identity** with Ed25519 keypairs
- **12-word recovery phrase** (BIP39) for account backup
- **Real-time messaging** via Supabase Realtime
- **Contact management** with QR code support
- **Dark theme** with orange accents
- **Responsive design** - works on desktop and mobile

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: TailwindCSS
- **Backend**: Supabase (PostgreSQL + Realtime)
- **Encryption**: Web Crypto API
- **State**: Zustand (optional)
- **QR Codes**: qrcode library

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Supabase account (already configured)

### Installation

```bash
cd web-app
npm install
```

### Environment Setup

Create `.env.local` file (already created with credentials):

```bash
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build for Production

```bash
npm run build
npm start
```

## Project Structure

```
web-app/
├── app/                          # Next.js App Router
│   ├── page.tsx                 # Landing/routing page
│   ├── welcome/page.tsx         # Welcome screen
│   ├── register/page.tsx        # Account creation
│   ├── restore/page.tsx         # Account restoration
│   ├── home/page.tsx            # Main app (tabs)
│   ├── chat/[id]/page.tsx       # Chat interface
│   ├── add-contact/page.tsx     # Add new contacts
│   ├── qr-code/page.tsx         # Display QR code
│   ├── recovery-phrase/page.tsx # View recovery phrase
│   ├── layout.tsx               # Root layout
│   └── globals.css              # Global styles
├── lib/
│   ├── crypto.ts                # Cryptography service
│   └── supabase.ts              # Supabase client
├── package.json
├── tsconfig.json
├── tailwind.config.ts
└── README.md
```

## How It Works

### Identity Generation

1. User clicks "Create New Account"
2. Ed25519 keypair generated for identity
3. RSA-2048 keypair generated for encryption
4. Session ID created: "05" + hex(Ed25519PublicKey)
5. 12-word BIP39 recovery phrase generated
6. Keys stored in localStorage
7. Public keys uploaded to Supabase

### Message Encryption

1. Generate random AES-256 key
2. Encrypt message with AES-GCM
3. Encrypt AES key with recipient's RSA public key
4. Send {encryptedContent, encryptedAesKey, nonce, mac}
5. Recipient decrypts AES key with their RSA private key
6. Recipient decrypts message with AES key

### Data Flow

```
User Input → Web Crypto API → Encrypted Data → Supabase → Real-time → Recipient
                   ↓                                              ↓
            localStorage (keys)                          Web Crypto API (decrypt)
```

## Security

### What's Secure

✅ End-to-end encryption (RSA + AES hybrid)
✅ Private keys stored in browser localStorage
✅ Messages encrypted before sending to server
✅ No personal information required
✅ Self-sovereign identity

### Important Notes

⚠️ **localStorage security**: Keys stored in browser localStorage are accessible to any script on the same domain. For production, consider:
- IndexedDB with encryption
- Web Crypto API's non-extractable keys
- Hardware security modules

⚠️ **No perfect forward secrecy**: Same RSA keys used for all messages

⚠️ **Browser-based**: Keys can be lost if browser data is cleared

### Best Practices

1. **Save recovery phrase** - Write it down offline
2. **HTTPS only** - Always use secure connections
3. **Trusted devices** - Only use on devices you control
4. **Regular backups** - Save recovery phrase securely

## API Routes

The app uses client-side routing with Next.js App Router:

- `/` - Landing page (auto-routes to welcome or home)
- `/welcome` - Onboarding screen
- `/register` - Create new account
- `/restore` - Restore from recovery phrase
- `/home` - Main app with tabs (chats, groups, settings)
- `/chat/[id]` - Individual conversation
- `/add-contact` - Add new contact
- `/qr-code` - Display your QR code
- `/recovery-phrase` - View recovery phrase

## Database Schema

Uses the same Supabase schema as the iOS app:

- `users` - Public keys and status
- `contacts` - Contact lists
- `messages` - Encrypted messages
- `conversations` - Chat metadata

## Features

### Implemented

✅ Anonymous registration
✅ Recovery phrase generation/restoration
✅ Contact management
✅ End-to-end encrypted messaging
✅ QR code generation
✅ Conversation list
✅ Settings page
✅ Logout

### Not Yet Implemented

⏳ QR code scanning (requires camera access)
⏳ Push notifications
⏳ Image/media sharing
⏳ Group chats
⏳ Message search
⏳ Read receipts
⏳ Typing indicators

## Development

### Adding New Features

1. Create new page in `app/` directory
2. Use `cryptoService` for encryption
3. Use `supabase` client for backend
4. Follow existing patterns for UI

### Testing

```bash
# Run in development
npm run dev

# Test with two browsers/tabs
# Create account in Browser A
# Create account in Browser B
# Add contacts and send messages
```

### Debugging

```bash
# Enable verbose logging
# Check browser console for errors
# Inspect Network tab for API calls
# Use React DevTools for state
```

## Deployment

### Vercel (Recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables in Vercel dashboard
```

### Other Platforms

Works on any platform that supports Next.js:
- Netlify
- Railway
- AWS Amplify
- Cloudflare Pages

## Troubleshooting

### Messages Not Sending

- Check browser console for errors
- Verify Supabase credentials in `.env.local`
- Ensure RLS policies are deployed
- Check internet connection

### Keys Not Saving

- Check browser localStorage is enabled
- Try incognito/private mode
- Clear browser data and try again

### Cannot Decrypt Messages

- Ensure both users have uploaded public keys
- Check RSA key format in database
- Verify message format matches expected structure

## Contributing

This is a demonstration app. For production use:

1. Implement proper error handling
2. Add comprehensive tests
3. Security audit
4. Performance optimization
5. Accessibility improvements
6. Internationalization

## License

MIT License

## Privacy

**Privacy is a right, not a privilege.**

Mercurio Messenger:
- Collects no personal information
- Stores no unencrypted messages
- No analytics or telemetry
- No third-party trackers

---

**Version**: 1.0.0
**Platform**: Web (Browser)
**Framework**: Next.js 14
**Language**: TypeScript

Built with privacy and security in mind. 🔐
