'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { cryptoService } from '@/lib/crypto';
import { addContact, fetchUserPublicKeys, upsertConversation, generateConversationId } from '@/lib/api';

export default function AddContactPage() {
  const router = useRouter();
  const [mercurioId, setMercurioId] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [isAdding, setIsAdding] = useState(false);
  const [error, setError] = useState('');

  const isValidMercurioId = (id: string) => {
    return id.length === 66 && id.startsWith('05');
  };

  const handleAddContact = async () => {
    if (!mercurioId.trim() || !displayName.trim()) return;

    setIsAdding(true);
    setError('');

    try {
      await cryptoService.ensureLoaded();
      const myId = cryptoService.getMercurioId();
      if (!myId) throw new Error('Not authenticated');

      const trimmedId = mercurioId.trim();

      if (!isValidMercurioId(trimmedId)) {
        throw new Error('Invalid Mercurio ID format (must start with 05 and be 66 chars)');
      }

      if (trimmedId === myId) {
        throw new Error('You cannot add yourself as a contact');
      }

      // Verify the user exists
      const user = await fetchUserPublicKeys(trimmedId);
      if (!user) {
        throw new Error('User not found. Make sure they have registered first.');
      }

      // Add contact entry
      await addContact({
        user_mercurio_id: myId,
        contact_mercurio_id: trimmedId,
        display_name: displayName.trim(),
        verified: false,
      });

      // Create/ensure conversation exists
      const conversationId = generateConversationId(myId, trimmedId);
      const sorted = [myId, trimmedId].sort();
      await upsertConversation({
        id: conversationId,
        participant1_id: sorted[0],
        participant2_id: sorted[1],
      });

      // Navigate directly to the chat
      router.push(`/chat/${conversationId}`);
    } catch (err: any) {
      setError(err.message || 'Failed to add contact');
    } finally {
      setIsAdding(false);
    }
  };

  return (
    <div className="min-h-screen p-6">
      <div className="max-w-md mx-auto space-y-8 py-8">
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={() => router.back()}
            className="text-primary hover:text-primary-light"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <h1 className="text-2xl font-bold gradient-text">Add Contact</h1>
        </div>

        <div className="flex flex-col items-center mb-6">
          <div className="w-20 h-20 gradient-bg rounded-2xl flex items-center justify-center">
            <svg className="w-10 h-10 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
            </svg>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Mercurio ID
              <span className="text-gray-500 font-normal ml-2">(starts with 05, 66 characters)</span>
            </label>
            <input
              type="text"
              value={mercurioId}
              onChange={(e) => setMercurioId(e.target.value)}
              placeholder="05..."
              className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors font-mono text-sm"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Display Name</label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="e.g., Alice"
              className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors"
              onKeyPress={(e) => e.key === 'Enter' && handleAddContact()}
            />
          </div>

          {error && (
            <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4">
              <p className="text-red-400 text-sm">{error}</p>
            </div>
          )}

          <div className="bg-white/5 border border-white/10 rounded-xl p-4">
            <p className="text-xs text-gray-400">
              💡 Ask the other person to open <strong className="text-gray-300">Settings → Show My QR Code</strong> to find their Mercurio ID.
            </p>
          </div>

          <button
            onClick={handleAddContact}
            disabled={isAdding || !mercurioId.trim() || !displayName.trim()}
            className="w-full py-4 px-6 font-semibold text-black gradient-bg rounded-xl hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {isAdding ? (
              <>
                <svg className="animate-spin h-5 w-5 text-black" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Adding...
              </>
            ) : (
              'Add Contact & Open Chat'
            )}
          </button>

          <button
            onClick={() => router.back()}
            className="w-full py-3 px-6 text-gray-400 hover:text-white transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}
