'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { cryptoService } from '@/lib/crypto';
import { uploadUserPublicKeys } from '@/lib/supabase';

export default function RestorePage() {
  const router = useRouter();
  const [phrase, setPhrase] = useState('');
  const [isRestoring, setIsRestoring] = useState(false);
  const [error, setError] = useState('');

  const restoreIdentity = async () => {
    setIsRestoring(true);
    setError('');

    try {
      const trimmedPhrase = phrase.trim().toLowerCase();
      const id = await cryptoService.restoreFromPhrase(trimmedPhrase);

      const publicKeys = await cryptoService.getPublicKeys();
      await uploadUserPublicKeys({
        mercurio_id: id,
        ed25519_public_key: publicKeys.ed25519,
        rsa_public_key_modulus: publicKeys.rsa.modulus,
        rsa_public_key_exponent: publicKeys.rsa.exponent,
        is_online: true,
      });

      router.push('/home');
    } catch (err: any) {
      setError(err.message || 'Failed to restore account');
    } finally {
      setIsRestoring(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <div className="w-20 h-20 mx-auto mb-6 gradient-bg rounded-2xl flex items-center justify-center">
            <svg className="w-10 h-10 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </div>

          <h1 className="text-3xl font-bold gradient-text mb-4">Restore Your Account</h1>

          <p className="text-gray-400 mb-8">
            Enter your 12-word recovery phrase to restore your identity.
          </p>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Recovery Phrase</label>
            <textarea
              value={phrase}
              onChange={(e) => setPhrase(e.target.value)}
              placeholder="word1 word2 word3..."
              rows={4}
              className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors"
            />
          </div>

          {error && (
            <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4">
              <p className="text-red-400 text-sm">{error}</p>
            </div>
          )}

          <button
            onClick={restoreIdentity}
            disabled={isRestoring || !phrase.trim()}
            className="w-full py-4 px-6 font-semibold text-black gradient-bg rounded-xl hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {isRestoring ? (
              <>
                <svg className="animate-spin h-5 w-5 text-black" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Restoring...
              </>
            ) : (
              'Restore Account'
            )}
          </button>

          <button
            onClick={() => router.back()}
            className="w-full py-3 px-6 text-gray-400 hover:text-white transition-colors"
          >
            Back
          </button>
        </div>
      </div>
    </div>
  );
}
