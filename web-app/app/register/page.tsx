'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { cryptoService } from '@/lib/crypto';
import { uploadUserPublicKeys } from '@/lib/supabase';

export default function RegisterPage() {
  const router = useRouter();
  const [isGenerating, setIsGenerating] = useState(false);
  const [showRecoveryPhrase, setShowRecoveryPhrase] = useState(false);
  const [recoveryPhrase, setRecoveryPhrase] = useState('');
  const [mercurioId, setMercurioId] = useState('');
  const [error, setError] = useState('');
  const [isCopied, setIsCopied] = useState(false);

  const generateIdentity = async () => {
    setIsGenerating(true);
    setError('');

    try {
      const id = await cryptoService.generateIdentity();
      const phrase = cryptoService.getRecoveryPhrase();

      if (!phrase) throw new Error('Failed to generate recovery phrase');

      setMercurioId(id);
      setRecoveryPhrase(phrase);

      const publicKeys = await cryptoService.getPublicKeys();
      await uploadUserPublicKeys({
        mercurio_id: id,
        ed25519_public_key: publicKeys.ed25519,
        rsa_public_key_modulus: publicKeys.rsa.modulus,
        rsa_public_key_exponent: publicKeys.rsa.exponent,
        is_online: true,
      });

      setShowRecoveryPhrase(true);
    } catch (err: any) {
      setError(err.message || 'Failed to generate identity');
    } finally {
      setIsGenerating(false);
    }
  };

  const copyPhrase = () => {
    navigator.clipboard.writeText(recoveryPhrase);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  const continueToHome = () => {
    router.push('/home');
  };

  const words = recoveryPhrase.split(' ');

  if (showRecoveryPhrase) {
    return (
      <div className="min-h-screen flex items-center justify-center p-6">
        <div className="max-w-2xl w-full space-y-6">
          <div className="text-center mb-8">
            <div className="w-16 h-16 mx-auto mb-4 gradient-bg rounded-2xl flex items-center justify-center">
              <svg className="w-8 h-8 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
            <h1 className="text-3xl font-bold gradient-text mb-2">Recovery Phrase</h1>
            <p className="text-gray-400">Write down these words in order. This is the ONLY way to recover your account.</p>
          </div>

          <div className="bg-primary/10 border border-primary/30 rounded-xl p-6 mb-6">
            <p className="text-primary font-semibold mb-2">⚠️ Write down these words</p>
            <p className="text-sm text-gray-400">
              Store it safely and never share it with anyone. Without this phrase, you cannot recover your account.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-3 mb-6">
            {words.map((word, index) => (
              <div key={index} className="flex items-center gap-3 p-4 bg-white/5 rounded-lg">
                <span className="text-gray-500 text-sm w-8">{index + 1}.</span>
                <span className="text-white font-medium">{word}</span>
              </div>
            ))}
          </div>

          <button
            onClick={copyPhrase}
            className="w-full py-3 px-6 text-primary border border-primary rounded-xl hover:bg-primary/10 transition-colors flex items-center justify-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              {isCopied ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
              )}
            </svg>
            {isCopied ? 'Copied!' : 'Copy to Clipboard'}
          </button>

          <div className="bg-white/5 rounded-xl p-4">
            <p className="text-sm text-gray-400 mb-1">Your Mercurio ID</p>
            <p className="text-xs text-gray-500 font-mono break-all">{mercurioId}</p>
          </div>

          <button
            onClick={continueToHome}
            className="w-full py-4 px-6 font-semibold text-black gradient-bg rounded-xl hover:opacity-90 transition-opacity"
          >
            I've Saved My Recovery Phrase
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <div className="w-20 h-20 mx-auto mb-6 gradient-bg rounded-2xl flex items-center justify-center">
            <svg className="w-10 h-10 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
            </svg>
          </div>

          <h1 className="text-3xl font-bold gradient-text mb-4">Create Your Identity</h1>

          <p className="text-gray-400 mb-8">
            Your identity will be created locally in your browser. You'll receive a 12-word recovery phrase to backup your account.
          </p>
        </div>

        {error && (
          <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4">
            <p className="text-red-400 text-sm">{error}</p>
          </div>
        )}

        <button
          onClick={generateIdentity}
          disabled={isGenerating}
          className="w-full py-4 px-6 font-semibold text-black gradient-bg rounded-xl hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
        >
          {isGenerating ? (
            <>
              <svg className="animate-spin h-5 w-5 text-black" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Generating...
            </>
          ) : (
            'Generate Identity'
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
  );
}
