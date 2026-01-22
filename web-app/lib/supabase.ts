import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseKey);

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
  encrypted_aes_key: string;
  nonce: string;
  mac: string;
  created_at: string;
  read_at: string | null;
  status: 'sending' | 'sent' | 'delivered' | 'read' | 'failed';
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

export async function uploadUserPublicKeys(user: Omit<User, 'created_at' | 'last_seen'>) {
  const { error } = await supabase.from('users').upsert({
    mercurio_id: user.mercurio_id,
    ed25519_public_key: user.ed25519_public_key,
    rsa_public_key_modulus: user.rsa_public_key_modulus,
    rsa_public_key_exponent: user.rsa_public_key_exponent,
    is_online: user.is_online,
    last_seen: new Date().toISOString(),
  });

  if (error) throw error;
}

export async function fetchUserPublicKeys(mercurioId: string): Promise<User | null> {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('mercurio_id', mercurioId)
    .single();

  if (error) return null;
  return data;
}

export async function addContact(contact: Omit<Contact, 'id' | 'created_at'>) {
  const { error } = await supabase.from('contacts').insert({
    user_mercurio_id: contact.user_mercurio_id,
    contact_mercurio_id: contact.contact_mercurio_id,
    display_name: contact.display_name,
    verified: contact.verified || false,
  });

  if (error) throw error;
}

export async function fetchContacts(mercurioId: string): Promise<Contact[]> {
  const { data, error } = await supabase
    .from('contacts')
    .select('*')
    .eq('user_mercurio_id', mercurioId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

export async function sendMessage(message: Omit<Message, 'id' | 'created_at'>) {
  const { error } = await supabase.from('messages').insert({
    conversation_id: message.conversation_id,
    sender_mercurio_id: message.sender_mercurio_id,
    recipient_mercurio_id: message.recipient_mercurio_id,
    encrypted_content: message.encrypted_content,
    encrypted_aes_key: message.encrypted_aes_key,
    nonce: message.nonce,
    mac: message.mac,
    status: message.status,
  });

  if (error) throw error;

  await updateConversation(
    message.conversation_id,
    'Encrypted message',
    message.sender_mercurio_id,
    message.recipient_mercurio_id
  );
}

export async function fetchMessages(conversationId: string): Promise<Message[]> {
  const { data, error } = await supabase
    .from('messages')
    .select('*')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true });

  if (error) throw error;
  return data || [];
}

export async function updateConversation(
  conversationId: string,
  lastMessage: string,
  participant1: string,
  participant2: string
) {
  const sorted = [participant1, participant2].sort();
  const { error } = await supabase.from('conversations').upsert({
    id: conversationId,
    participant1_id: sorted[0],
    participant2_id: sorted[1],
    last_message: lastMessage,
    last_message_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });

  if (error) throw error;
}

export async function fetchConversations(mercurioId: string): Promise<Conversation[]> {
  const { data, error } = await supabase
    .from('conversations')
    .select('*')
    .or(`participant1_id.eq.${mercurioId},participant2_id.eq.${mercurioId}`)
    .order('updated_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

export function generateConversationId(id1: string, id2: string): string {
  const sorted = [id1, id2].sort();
  return `${sorted[0]}_${sorted[1]}`;
}
