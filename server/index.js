const express = require('express');
const Database = require('better-sqlite3');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const app = express();
const PORT = 4000;

// Enable CORS for the Next.js dev server
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));

// Initialize SQLite database
const db = new Database(path.join(__dirname, 'mercurio.db'));

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    mercurio_id TEXT PRIMARY KEY,
    ed25519_public_key TEXT NOT NULL,
    rsa_public_key_modulus TEXT NOT NULL,
    rsa_public_key_exponent TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    last_seen TEXT DEFAULT (datetime('now')),
    is_online INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS contacts (
    id TEXT PRIMARY KEY,
    user_mercurio_id TEXT NOT NULL,
    contact_mercurio_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    verified INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now')),
    UNIQUE(user_mercurio_id, contact_mercurio_id)
  );

  CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    sender_mercurio_id TEXT NOT NULL,
    recipient_mercurio_id TEXT NOT NULL,
    encrypted_content TEXT NOT NULL,
    encrypted_aes_key_for_recipient TEXT NOT NULL,
    encrypted_aes_key_for_sender TEXT,
    nonce TEXT NOT NULL,
    mac TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    read_at TEXT,
    status TEXT DEFAULT 'sent'
  );

  CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    participant1_id TEXT NOT NULL,
    participant2_id TEXT NOT NULL,
    last_message TEXT,
    last_message_at TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  CREATE INDEX IF NOT EXISTS idx_contacts_user ON contacts(user_mercurio_id);
  CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at);
  CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_mercurio_id, created_at);
  CREATE INDEX IF NOT EXISTS idx_conversations_p1 ON conversations(participant1_id);
  CREATE INDEX IF NOT EXISTS idx_conversations_p2 ON conversations(participant2_id);
`);

// ─── USERS ─────────────────────────────────────────────────────────────────────

// Upsert user (register / update public keys)
app.post('/api/users', (req, res) => {
  try {
    const { mercurio_id, ed25519_public_key, rsa_public_key_modulus, rsa_public_key_exponent, is_online } = req.body;
    if (!mercurio_id || !ed25519_public_key || !rsa_public_key_modulus || !rsa_public_key_exponent) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    const stmt = db.prepare(`
      INSERT INTO users (mercurio_id, ed25519_public_key, rsa_public_key_modulus, rsa_public_key_exponent, is_online, last_seen)
      VALUES (?, ?, ?, ?, ?, datetime('now'))
      ON CONFLICT(mercurio_id) DO UPDATE SET
        ed25519_public_key = excluded.ed25519_public_key,
        rsa_public_key_modulus = excluded.rsa_public_key_modulus,
        rsa_public_key_exponent = excluded.rsa_public_key_exponent,
        is_online = excluded.is_online,
        last_seen = datetime('now')
    `);
    stmt.run(mercurio_id, ed25519_public_key, rsa_public_key_modulus, rsa_public_key_exponent, is_online ? 1 : 0);
    res.json({ success: true });
  } catch (err) {
    console.error('POST /api/users error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get user by mercurio_id
app.get('/api/users/:id', (req, res) => {
  try {
    const user = db.prepare('SELECT * FROM users WHERE mercurio_id = ?').get(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    user.is_online = !!user.is_online;
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── CONTACTS ──────────────────────────────────────────────────────────────────

// Add contact
app.post('/api/contacts', (req, res) => {
  try {
    const { user_mercurio_id, contact_mercurio_id, display_name, verified } = req.body;
    const id = uuidv4();
    db.prepare(`
      INSERT INTO contacts (id, user_mercurio_id, contact_mercurio_id, display_name, verified)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(user_mercurio_id, contact_mercurio_id) DO UPDATE SET
        display_name = excluded.display_name
    `).run(id, user_mercurio_id, contact_mercurio_id, display_name, verified ? 1 : 0);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get contacts for a user
app.get('/api/contacts/:userId', (req, res) => {
  try {
    const contacts = db.prepare('SELECT * FROM contacts WHERE user_mercurio_id = ? ORDER BY created_at DESC').all(req.params.userId);
    contacts.forEach(c => c.verified = !!c.verified);
    res.json(contacts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── CONVERSATIONS ─────────────────────────────────────────────────────────────

// Upsert conversation
app.post('/api/conversations', (req, res) => {
  try {
    const { id, participant1_id, participant2_id, last_message, last_message_at } = req.body;
    db.prepare(`
      INSERT INTO conversations (id, participant1_id, participant2_id, last_message, last_message_at, updated_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'))
      ON CONFLICT(id) DO UPDATE SET
        last_message = excluded.last_message,
        last_message_at = excluded.last_message_at,
        updated_at = datetime('now')
    `).run(id, participant1_id, participant2_id, last_message || null, last_message_at || null);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get conversations for a user
app.get('/api/conversations/:userId', (req, res) => {
  try {
    const convs = db.prepare(`
      SELECT * FROM conversations
      WHERE participant1_id = ? OR participant2_id = ?
      ORDER BY updated_at DESC
    `).all(req.params.userId, req.params.userId);
    res.json(convs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── MESSAGES ──────────────────────────────────────────────────────────────────

// Send message
app.post('/api/messages', (req, res) => {
  try {
    const {
      conversation_id,
      sender_mercurio_id,
      recipient_mercurio_id,
      encrypted_content,
      encrypted_aes_key_for_recipient,
      encrypted_aes_key_for_sender,
      nonce,
      mac,
      status,
    } = req.body;

    const id = uuidv4();
    db.prepare(`
      INSERT INTO messages (id, conversation_id, sender_mercurio_id, recipient_mercurio_id,
        encrypted_content, encrypted_aes_key_for_recipient, encrypted_aes_key_for_sender,
        nonce, mac, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(id, conversation_id, sender_mercurio_id, recipient_mercurio_id,
      encrypted_content, encrypted_aes_key_for_recipient, encrypted_aes_key_for_sender || null,
      nonce, mac, status || 'sent');

    // Update conversation last message
    const now = new Date().toISOString();
    db.prepare(`
      UPDATE conversations SET last_message = 'Encrypted message', last_message_at = ?, updated_at = ?
      WHERE id = ?
    `).run(now, now, conversation_id);

    res.json({ id, success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get messages for a conversation (with optional since parameter for polling)
app.get('/api/messages/:conversationId', (req, res) => {
  try {
    const { since } = req.query;
    let messages;
    if (since) {
      messages = db.prepare(`
        SELECT * FROM messages
        WHERE conversation_id = ? AND created_at > ?
        ORDER BY created_at ASC
      `).all(req.params.conversationId, since);
    } else {
      messages = db.prepare(`
        SELECT * FROM messages
        WHERE conversation_id = ?
        ORDER BY created_at ASC
      `).all(req.params.conversationId);
    }
    res.json(messages);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Serve APK for download
app.get('/download/mercurio.apk', (req, res) => {
  const apkPath = path.join(__dirname, 'mercurio-messenger.apk');
  res.download(apkPath, 'mercurio-messenger-1.0.0.apk', (err) => {
    if (err) res.status(404).json({ error: 'APK not found' });
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Mercurio API server running on http://0.0.0.0:${PORT}`);
});
