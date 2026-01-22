'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { cryptoService } from '@/lib/crypto';
import { addContact, fetchUserPublicKeys } from '@/lib/supabase';

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
    if (!mercurioId || !displayName) return;

    setIsAdding(true);
    setError('');

    try {
      const myId = cryptoService.getMercurioId();
      if (!myId) throw new Error('Not authenticated');

      if (!isValidMercurioId(mercurioId)) {
        throw new Error('Invalid Mercurio ID format');
      }

      const user = await fetchUserPublicKeys(mercurioId);
      if (!user) {
        throw new Error('User not found');
      }

      await addContact({
        user_mercurio_id: myId,
        contact_mercurio_id: mercurioId,
        display_name: displayName,
        verified: false,
      });

      router.push('/home');
    } catch (err: any) {
      setError(err.message || 'Failed to add contact');
    } finally {
      setIsAdding(false);
    }
  };

  return (
    <div className="min-h-screen p-6">
      <div className="max-w-md mx-auto space-y-8 py-8">
        <div className="text-center">
          <div className="w-20 h-20 mx-auto mb-6 gradient-bg rounded-2xl flex items-center justify-center">
            <svg className="w-10 h-10 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
            </svg>
          </div>

          <h1 className="text-3xl font-bold gradient-text mb-4">Add Contact</h1>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Mercurio ID</label>
            <div className="flex gap-2">
              <input
                type="text"
                value={mercurioId}
                onChange={(e) => setMercurioId(e.target.value)}
                placeholder="05..."
                className="flex-1 px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors font-mono text-sm"
              />
              <button
                className="w-12 h-12 gradient-bg rounded-xl flex items-center justify-center hover:opacity-90 transition-opacity"
                title="Scan QR Code"
              >
                <svg className="w-6 h-6 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                </svg>
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Display Name</label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="e.g., John from work"
              className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors"
            />
          </div>

          {error && (
            <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4">
              <p className="text-red-400 text-sm">{error}</p>
            </div>
          )}

          <button
            onClick={handleAddContact}
            disabled={isAdding || !mercurioId || !displayName}
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
              'Add Contact'
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
