'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { cryptoService } from '@/lib/crypto';
import { fetchMessages, sendMessage, fetchUserPublicKeys, fetchContacts, type Message } from '@/lib/api';

interface DecryptedMessage {
  id: string;
  content: string;
  senderMercurioId: string;
  createdAt: string;
  isSentByMe: boolean;
  failed?: boolean;
}

export default function ChatPage() {
  const router = useRouter();
  const params = useParams();
  const conversationId = params.id as string;
  const [messages, setMessages] = useState<DecryptedMessage[]>([]);
  const [messageText, setMessageText] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [contactName, setContactName] = useState('...');
  const [recipientId, setRecipientId] = useState<string | null>(null);
  const [error, setError] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const lastMessageTimeRef = useRef<string | null>(null);
  const pollingRef = useRef<NodeJS.Timeout | null>(null);
  const myIdRef = useRef<string | null>(null);

  // Derive participant IDs from conversation ID
  // Conversation IDs are "sortedId1_sortedId2" where IDs can contain underscores
  // IDs are 66 chars starting with "05", so we split smartly
  const parseConversationId = useCallback((convId: string): [string, string] | null => {
    // Each mercurio ID is exactly 66 characters
    if (convId.length < 66 * 2 + 1) return null;
    const p1 = convId.substring(0, 66);
    const p2 = convId.substring(67); // skip the underscore separator
    if (p1.startsWith('05') && p2.startsWith('05')) {
      return [p1, p2];
    }
    return null;
  }, []);

  const decryptMessageForUser = useCallback(async (msg: Message, myId: string): Promise<string | null> => {
    try {
      const isSender = msg.sender_mercurio_id === myId;
      let encryptedAesKey: string;

      if (isSender) {
        // Use the sender's copy of the AES key
        if (!msg.encrypted_aes_key_for_sender) {
          // Legacy message without sender copy — try recipient key (won't work but attempt)
          encryptedAesKey = msg.encrypted_aes_key_for_recipient;
        } else {
          encryptedAesKey = msg.encrypted_aes_key_for_sender;
        }
      } else {
        encryptedAesKey = msg.encrypted_aes_key_for_recipient;
      }

      return await cryptoService.decryptMessage({
        encryptedContent: msg.encrypted_content,
        encryptedAesKey,
        nonce: msg.nonce,
        mac: msg.mac,
      });
    } catch {
      return null;
    }
  }, []);

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  // Load initial messages and set up contact name
  useEffect(() => {
    const initialize = async () => {
      await cryptoService.ensureLoaded();
      const myId = cryptoService.getMercurioId();
      if (!myId) {
        router.push('/welcome');
        return;
      }
      myIdRef.current = myId;

      // Parse participant IDs
      const participants = parseConversationId(conversationId);
      if (!participants) {
        setError('Invalid conversation ID');
        setIsLoading(false);
        return;
      }

      const [p1, p2] = participants;
      const otherId = p1 === myId ? p2 : p1;
      setRecipientId(otherId);

      // Get contact name
      try {
        const contacts = await fetchContacts(myId);
        const contact = contacts.find(c => c.contact_mercurio_id === otherId);
        if (contact) {
          setContactName(contact.display_name);
        } else {
          setContactName(`${otherId.substring(0, 12)}...`);
        }
      } catch {
        setContactName(`${otherId.substring(0, 12)}...`);
      }

      // Load messages
      try {
        const msgs = await fetchMessages(conversationId);
        const decrypted: DecryptedMessage[] = [];

        for (const msg of msgs) {
          const plaintext = await decryptMessageForUser(msg, myId);
          decrypted.push({
            id: msg.id,
            content: plaintext ?? '[Could not decrypt]',
            senderMercurioId: msg.sender_mercurio_id,
            createdAt: msg.created_at,
            isSentByMe: msg.sender_mercurio_id === myId,
            failed: plaintext === null,
          });
          lastMessageTimeRef.current = msg.created_at;
        }

        setMessages(decrypted);
        setTimeout(scrollToBottom, 100);
      } catch (err: any) {
        setError('Failed to load messages: ' + err.message);
      } finally {
        setIsLoading(false);
      }
    };

    initialize();
  }, [conversationId, router, parseConversationId, decryptMessageForUser, scrollToBottom]);

  // Poll for new messages every 2 seconds
  useEffect(() => {
    const poll = async () => {
      const myId = myIdRef.current;
      if (!myId) return;

      try {
        const since = lastMessageTimeRef.current;
        const newMsgs = await fetchMessages(conversationId, since || undefined);

        if (newMsgs.length > 0) {
          const decrypted: DecryptedMessage[] = [];
          for (const msg of newMsgs) {
            // Skip if we already have this message (optimistic update)
            setMessages(prev => {
              if (prev.some(m => m.id === msg.id)) return prev;
              return prev; // will add below
            });

            const plaintext = await decryptMessageForUser(msg, myId);
            decrypted.push({
              id: msg.id,
              content: plaintext ?? '[Could not decrypt]',
              senderMercurioId: msg.sender_mercurio_id,
              createdAt: msg.created_at,
              isSentByMe: msg.sender_mercurio_id === myId,
              failed: plaintext === null,
            });
            lastMessageTimeRef.current = msg.created_at;
          }

          if (decrypted.length > 0) {
            setMessages(prev => {
              const existingIds = new Set(prev.map(m => m.id));
              const truly_new = decrypted.filter(m => !existingIds.has(m.id));
              if (truly_new.length === 0) return prev;
              setTimeout(scrollToBottom, 50);
              return [...prev, ...truly_new];
            });
          }
        }
      } catch {
        // Silently fail polling — don't disrupt UI
      }
    };

    pollingRef.current = setInterval(poll, 2000);
    return () => {
      if (pollingRef.current) clearInterval(pollingRef.current);
    };
  }, [conversationId, decryptMessageForUser, scrollToBottom]);

  const handleSendMessage = async () => {
    if (!messageText.trim() || isSending) return;

    await cryptoService.ensureLoaded();
    const myId = cryptoService.getMercurioId();
    if (!myId || !recipientId) return;

    const text = messageText;
    setMessageText('');
    setIsSending(true);

    // Optimistic UI update
    const tempId = `temp_${Date.now()}`;
    const tempMsg: DecryptedMessage = {
      id: tempId,
      content: text,
      senderMercurioId: myId,
      createdAt: new Date().toISOString(),
      isSentByMe: true,
    };
    setMessages(prev => [...prev, tempMsg]);
    setTimeout(scrollToBottom, 50);

    try {
      const recipientUser = await fetchUserPublicKeys(recipientId);
      if (!recipientUser) throw new Error('Recipient not found — they may have unregistered');

      const encryptedMsg = await cryptoService.encryptMessage(text, {
        modulus: recipientUser.rsa_public_key_modulus,
        exponent: recipientUser.rsa_public_key_exponent,
      });

      const result = await sendMessage({
        conversation_id: conversationId,
        sender_mercurio_id: myId,
        recipient_mercurio_id: recipientId,
        encrypted_content: encryptedMsg.encryptedContent,
        encrypted_aes_key_for_recipient: encryptedMsg.encryptedAesKeyForRecipient,
        encrypted_aes_key_for_sender: encryptedMsg.encryptedAesKeyForSender,
        nonce: encryptedMsg.nonce,
        mac: encryptedMsg.mac,
        status: 'sent',
      });

      // Replace temp message with real one
      setMessages(prev => prev.map(m =>
        m.id === tempId ? { ...m, id: result.id, createdAt: new Date().toISOString() } : m
      ));
      lastMessageTimeRef.current = new Date().toISOString();
    } catch (err: any) {
      console.error('Failed to send message:', err);
      // Mark temp message as failed
      setMessages(prev => prev.map(m =>
        m.id === tempId ? { ...m, content: `[Failed: ${err.message}]`, failed: true } : m
      ));
      setMessageText(text);
    } finally {
      setIsSending(false);
    }
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="min-h-screen flex flex-col max-h-screen">
      <header className="bg-dark-lighter border-b border-white/10 px-4 py-3 flex-shrink-0">
        <div className="flex items-center gap-3">
          <button onClick={() => router.push('/home')} className="text-primary hover:text-primary-light p-1">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div className="w-10 h-10 gradient-bg rounded-full flex items-center justify-center flex-shrink-0">
            <span className="text-black font-bold text-sm">
              {contactName && contactName !== '...' ? contactName[0].toUpperCase() : '?'}
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <h1 className="font-semibold text-white truncate">{contactName}</h1>
            <div className="flex items-center gap-1">
              <div className="w-1.5 h-1.5 bg-primary rounded-full"></div>
              <p className="text-xs text-primary">End-to-end encrypted</p>
            </div>
          </div>
        </div>
      </header>

      <main className="flex-1 overflow-y-auto p-4 space-y-3 min-h-0">
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <svg className="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-12">
            <p className="text-red-400 text-sm">{error}</p>
          </div>
        ) : messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 gap-2">
            <div className="w-16 h-16 gradient-bg rounded-full flex items-center justify-center opacity-30">
              <svg className="w-8 h-8 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
            </div>
            <p className="text-gray-400">No messages yet</p>
            <p className="text-sm text-gray-500">Say hello to {contactName}!</p>
          </div>
        ) : (
          messages.map((msg) => (
            <div
              key={msg.id}
              className={`flex ${msg.isSentByMe ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[75%] rounded-2xl px-4 py-2 ${
                  msg.failed
                    ? 'bg-red-500/20 text-red-300 rounded-br-sm border border-red-500/30'
                    : msg.isSentByMe
                    ? 'bg-primary text-black rounded-br-sm'
                    : 'bg-white/10 text-white rounded-bl-sm'
                }`}
              >
                <p className="break-words text-sm leading-relaxed">{msg.content}</p>
                <p
                  className={`text-xs mt-1 ${
                    msg.failed ? 'text-red-400' : msg.isSentByMe ? 'text-black/60' : 'text-white/50'
                  }`}
                >
                  {formatTime(msg.createdAt)}
                  {msg.isSentByMe && !msg.failed && (
                    <span className="ml-1">✓</span>
                  )}
                </p>
              </div>
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </main>

      <footer className="bg-dark-lighter border-t border-white/10 p-3 flex-shrink-0">
        <div className="flex items-center gap-2">
          <input
            type="text"
            value={messageText}
            onChange={(e) => setMessageText(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
            placeholder={`Message ${contactName}...`}
            className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-full text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors text-sm"
            disabled={isLoading}
          />
          <button
            onClick={handleSendMessage}
            disabled={!messageText.trim() || isSending || isLoading}
            className="w-11 h-11 gradient-bg rounded-full flex items-center justify-center hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex-shrink-0"
          >
            {isSending ? (
              <svg className="animate-spin h-4 w-4 text-black" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            ) : (
              <svg className="w-5 h-5 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
              </svg>
            )}
          </button>
        </div>
      </footer>
    </div>
  );
}
