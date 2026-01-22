'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { cryptoService } from '@/lib/crypto';
import { fetchMessages, sendMessage, fetchUserPublicKeys, type Message } from '@/lib/supabase';

interface DecryptedMessage {
  id: string;
  content: string;
  senderMercurioId: string;
  createdAt: string;
  isSentByMe: boolean;
}

export default function ChatPage() {
  const router = useRouter();
  const params = useParams();
  const conversationId = params.id as string;
  const [messages, setMessages] = useState<DecryptedMessage[]>([]);
  const [messageText, setMessageText] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [contactName, setContactName] = useState('User');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const loadMessages = async () => {
      const myId = cryptoService.getMercurioId();
      if (!myId) {
        router.push('/welcome');
        return;
      }

      try {
        const msgs = await fetchMessages(conversationId);
        const decrypted: DecryptedMessage[] = [];

        for (const msg of msgs) {
          try {
            const plaintext = await cryptoService.decryptMessage({
              encryptedContent: msg.encrypted_content,
              encryptedAesKey: msg.encrypted_aes_key,
              nonce: msg.nonce,
              mac: msg.mac,
            });

            decrypted.push({
              id: msg.id,
              content: plaintext,
              senderMercurioId: msg.sender_mercurio_id,
              createdAt: msg.created_at,
              isSentByMe: msg.sender_mercurio_id === myId,
            });
          } catch (error) {
            console.error('Failed to decrypt message:', error);
          }
        }

        setMessages(decrypted);
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      } catch (error) {
        console.error('Failed to load messages:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadMessages();
  }, [conversationId, router]);

  const handleSendMessage = async () => {
    if (!messageText.trim() || isSending) return;

    const myId = cryptoService.getMercurioId();
    if (!myId) return;

    const text = messageText;
    setMessageText('');
    setIsSending(true);

    try {
      const [participant1, participant2] = conversationId.split('_');
      const recipientId = participant1 === myId ? participant2 : participant1;

      const recipientUser = await fetchUserPublicKeys(recipientId);
      if (!recipientUser) throw new Error('Recipient not found');

      const encryptedMsg = await cryptoService.encryptMessage(text, {
        modulus: recipientUser.rsa_public_key_modulus,
        exponent: recipientUser.rsa_public_key_exponent,
      });

      await sendMessage({
        conversation_id: conversationId,
        sender_mercurio_id: myId,
        recipient_mercurio_id: recipientId,
        encrypted_content: encryptedMsg.encryptedContent,
        encrypted_aes_key: encryptedMsg.encryptedAesKey,
        nonce: encryptedMsg.nonce,
        mac: encryptedMsg.mac,
        status: 'sent',
        read_at: null,
      });

      setMessages((prev) => [
        ...prev,
        {
          id: Date.now().toString(),
          content: text,
          senderMercurioId: myId,
          createdAt: new Date().toISOString(),
          isSentByMe: true,
        },
      ]);

      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    } catch (error) {
      console.error('Failed to send message:', error);
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
    <div className="min-h-screen flex flex-col">
      <header className="bg-dark-lighter border-b border-white/10 px-6 py-4">
        <div className="flex items-center gap-4">
          <button onClick={() => router.back()} className="text-primary hover:text-primary-light">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div className="w-10 h-10 gradient-bg rounded-full flex items-center justify-center">
            <span className="text-black font-bold">{contactName[0]}</span>
          </div>
          <div className="flex-1">
            <h1 className="font-semibold text-white">{contactName}</h1>
            <p className="text-xs text-primary">Encrypted</p>
          </div>
        </div>
      </header>

      <main className="flex-1 overflow-y-auto p-6 space-y-4">
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <svg className="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
        ) : messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12">
            <p className="text-gray-400">No messages yet</p>
            <p className="text-sm text-gray-500">Send a message to start the conversation</p>
          </div>
        ) : (
          messages.map((msg) => (
            <div
              key={msg.id}
              className={`flex ${msg.isSentByMe ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[70%] rounded-2xl px-4 py-2 ${
                  msg.isSentByMe
                    ? 'bg-primary text-black rounded-br-sm'
                    : 'bg-white/10 text-white rounded-bl-sm'
                }`}
              >
                <p className="break-words">{msg.content}</p>
                <p
                  className={`text-xs mt-1 ${
                    msg.isSentByMe ? 'text-black/60' : 'text-white/50'
                  }`}
                >
                  {formatTime(msg.createdAt)}
                </p>
              </div>
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </main>

      <footer className="bg-dark-lighter border-t border-white/10 p-4">
        <div className="flex items-center gap-2">
          <button className="text-primary hover:text-primary-light">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </button>
          <input
            type="text"
            value={messageText}
            onChange={(e) => setMessageText(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
            placeholder="Type a message..."
            className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-full text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors"
          />
          <button
            onClick={handleSendMessage}
            disabled={!messageText.trim() || isSending}
            className="w-12 h-12 gradient-bg rounded-full flex items-center justify-center hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <svg className="w-5 h-5 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
            </svg>
          </button>
        </div>
      </footer>
    </div>
  );
}
