/*
  # Mercurio Messenger Database Schema
  
  Creates the core database structure for the Mercurio iOS messaging app.
  
  1. New Tables
    - `users`
      - `mercurio_id` (text, primary key) - Session ID (05 + 64 hex chars)
      - `ed25519_public_key` (text) - Ed25519 public key for identity
      - `rsa_public_key_modulus` (text) - RSA public key modulus
      - `rsa_public_key_exponent` (text) - RSA public key exponent
      - `created_at` (timestamptz) - Account creation timestamp
      - `last_seen` (timestamptz) - Last active timestamp
      - `is_online` (boolean) - Online status
    
    - `contacts`
      - `id` (uuid, primary key)
      - `user_mercurio_id` (text) - Owner's Mercurio ID
      - `contact_mercurio_id` (text) - Contact's Mercurio ID
      - `display_name` (text) - Contact's display name
      - `verified` (boolean) - Whether contact is verified
      - `created_at` (timestamptz) - When contact was added
    
    - `messages`
      - `id` (uuid, primary key)
      - `conversation_id` (text) - Conversation ID
      - `sender_mercurio_id` (text) - Sender's Mercurio ID
      - `recipient_mercurio_id` (text) - Recipient's Mercurio ID
      - `encrypted_content` (text) - Encrypted message content
      - `encrypted_aes_key` (text) - Encrypted AES key
      - `nonce` (text) - Encryption nonce
      - `mac` (text) - Message authentication code
      - `created_at` (timestamptz) - Message timestamp
      - `read_at` (timestamptz, nullable) - When message was read
      - `status` (text) - Message status (sending, sent, delivered, read, failed)
    
    - `conversations`
      - `id` (text, primary key) - Deterministic conversation ID
      - `participant1_id` (text) - First participant's Mercurio ID
      - `participant2_id` (text) - Second participant's Mercurio ID
      - `last_message` (text, nullable) - Last message preview
      - `last_message_at` (timestamptz, nullable) - Last message timestamp
      - `created_at` (timestamptz) - Conversation creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp
  
  2. Security
    - Enable RLS on all tables
    - Users can read their own user data and other users' public keys
    - Users can manage their own contacts
    - Users can send and receive encrypted messages
    - Conversations are accessible to both participants
*/

CREATE TABLE IF NOT EXISTS users (
  mercurio_id text PRIMARY KEY,
  ed25519_public_key text NOT NULL,
  rsa_public_key_modulus text NOT NULL,
  rsa_public_key_exponent text NOT NULL,
  created_at timestamptz DEFAULT now(),
  last_seen timestamptz DEFAULT now(),
  is_online boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_mercurio_id text NOT NULL,
  contact_mercurio_id text NOT NULL,
  display_name text NOT NULL,
  verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_mercurio_id, contact_mercurio_id)
);

CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id text NOT NULL,
  sender_mercurio_id text NOT NULL,
  recipient_mercurio_id text NOT NULL,
  encrypted_content text NOT NULL,
  encrypted_aes_key text NOT NULL,
  nonce text NOT NULL,
  mac text NOT NULL,
  created_at timestamptz DEFAULT now(),
  read_at timestamptz,
  status text DEFAULT 'sent'
);

CREATE TABLE IF NOT EXISTS conversations (
  id text PRIMARY KEY,
  participant1_id text NOT NULL,
  participant2_id text NOT NULL,
  last_message text,
  last_message_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_contacts_user ON contacts(user_mercurio_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_mercurio_id, created_at);
CREATE INDEX IF NOT EXISTS idx_conversations_participant1 ON conversations(participant1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participant2 ON conversations(participant2_id);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all public keys"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (mercurio_id = auth.jwt() ->> 'mercurio_id')
  WITH CHECK (mercurio_id = auth.jwt() ->> 'mercurio_id');

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (mercurio_id = auth.jwt() ->> 'mercurio_id');

CREATE POLICY "Users can view own contacts"
  ON contacts FOR SELECT
  TO authenticated
  USING (user_mercurio_id = auth.jwt() ->> 'mercurio_id');

CREATE POLICY "Users can insert own contacts"
  ON contacts FOR INSERT
  TO authenticated
  WITH CHECK (user_mercurio_id = auth.jwt() ->> 'mercurio_id');

CREATE POLICY "Users can update own contacts"
  ON contacts FOR UPDATE
  TO authenticated
  USING (user_mercurio_id = auth.jwt() ->> 'mercurio_id')
  WITH CHECK (user_mercurio_id = auth.jwt() ->> 'mercurio_id');

CREATE POLICY "Users can delete own contacts"
  ON contacts FOR DELETE
  TO authenticated
  USING (user_mercurio_id = auth.jwt() ->> 'mercurio_id');

CREATE POLICY "Users can read messages in their conversations"
  ON messages FOR SELECT
  TO authenticated
  USING (
    sender_mercurio_id = auth.jwt() ->> 'mercurio_id' OR
    recipient_mercurio_id = auth.jwt() ->> 'mercurio_id'
  );

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (sender_mercurio_id = auth.jwt() ->> 'mercurio_id');

CREATE POLICY "Users can update received messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (recipient_mercurio_id = auth.jwt() ->> 'mercurio_id')
  WITH CHECK (recipient_mercurio_id = auth.jwt() ->> 'mercurio_id');

CREATE POLICY "Users can read their conversations"
  ON conversations FOR SELECT
  TO authenticated
  USING (
    participant1_id = auth.jwt() ->> 'mercurio_id' OR
    participant2_id = auth.jwt() ->> 'mercurio_id'
  );

CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (
    participant1_id = auth.jwt() ->> 'mercurio_id' OR
    participant2_id = auth.jwt() ->> 'mercurio_id'
  );

CREATE POLICY "Users can update their conversations"
  ON conversations FOR UPDATE
  TO authenticated
  USING (
    participant1_id = auth.jwt() ->> 'mercurio_id' OR
    participant2_id = auth.jwt() ->> 'mercurio_id'
  )
  WITH CHECK (
    participant1_id = auth.jwt() ->> 'mercurio_id' OR
    participant2_id = auth.jwt() ->> 'mercurio_id'
  );