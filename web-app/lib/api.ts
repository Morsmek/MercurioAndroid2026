// API client - connects to the local Express+SQLite backend

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

export interface User {
  mercurio_id: string;
  ed25519_public_key: string;
  rsa_public_key_modulus: string;
  rsa_public_key_exponent: string;
  created_at: string;
  last_seen: string;
  is_online: boolean;
}

export interface Contact {
  id: string;
  user_mercurio_id: string;
  contact_mercurio_id: string;
  display_name: string;
  verified: boolean;
  created_at: string;
}

export interface Message {
  id: string;
  conversation_id: string;
  sender_mercurio_id: string;
  recipient_mercurio_id: string;
  encrypted_content: string;
  encrypted_aes_key_for_recipient: string;
  encrypted_aes_key_for_sender: string | null;
  nonce: string;
  mac: string;
  created_at: string;
  read_at: string | null;
  status: string;
}

export interface Conversation {
  id: string;
  participant1_id: string;
  participant2_id: string;
  last_message: string | null;
  last_message_at: string | null;
  created_at: string;
  updated_at: string;
}

async function apiFetch(path: string, options?: RequestInit) {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options?.headers || {}),
    },
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(err.error || `API error ${res.status}`);
  }
  return res.json();
}

export async function uploadUserPublicKeys(user: Omit<User, 'created_at' | 'last_seen'>) {
  await apiFetch('/api/users', {
    method: 'POST',
    body: JSON.stringify(user),
  });
}

export async function fetchUserPublicKeys(mercurioId: string): Promise<User | null> {
  try {
    return await apiFetch(`/api/users/${mercurioId}`);
  } catch {
    return null;
  }
}

export async function addContact(contact: Omit<Contact, 'id' | 'created_at'>) {
  await apiFetch('/api/contacts', {
    method: 'POST',
    body: JSON.stringify(contact),
  });
}

export async function fetchContacts(mercurioId: string): Promise<Contact[]> {
  return await apiFetch(`/api/contacts/${mercurioId}`);
}

export async function sendMessage(message: {
  conversation_id: string;
  sender_mercurio_id: string;
  recipient_mercurio_id: string;
  encrypted_content: string;
  encrypted_aes_key_for_recipient: string;
  encrypted_aes_key_for_sender: string | null;
  nonce: string;
  mac: string;
  status: string;
}) {
  return await apiFetch('/api/messages', {
    method: 'POST',
    body: JSON.stringify(message),
  });
}

export async function fetchMessages(conversationId: string, since?: string): Promise<Message[]> {
  const url = since
    ? `/api/messages/${conversationId}?since=${encodeURIComponent(since)}`
    : `/api/messages/${conversationId}`;
  return await apiFetch(url);
}

export async function upsertConversation(conv: {
  id: string;
  participant1_id: string;
  participant2_id: string;
  last_message?: string;
  last_message_at?: string;
}) {
  await apiFetch('/api/conversations', {
    method: 'POST',
    body: JSON.stringify(conv),
  });
}

export async function fetchConversations(mercurioId: string): Promise<Conversation[]> {
  return await apiFetch(`/api/conversations/${mercurioId}`);
}

export function generateConversationId(id1: string, id2: string): string {
  const sorted = [id1, id2].sort();
  return `${sorted[0]}_${sorted[1]}`;
}
