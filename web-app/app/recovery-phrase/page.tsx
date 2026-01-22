'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { cryptoService } from '@/lib/crypto';

export default function RecoveryPhrasePage() {
  const router = useRouter();
  const [phrase, setPhrase] = useState('');
  const [isCopied, setIsCopied] = useState(false);
  const [showWarning, setShowWarning] = useState(true);

  useEffect(() => {
    const loadPhrase = async () => {
      const recoveryPhrase = cryptoService.getRecoveryPhrase();
      if (!recoveryPhrase) {
        router.push('/welcome');
        return;
      }

      setPhrase(recoveryPhrase);
    };

    loadPhrase();
  }, [router]);

  const words = phrase.split(' ');

  const copyPhrase = () => {
    navigator.clipboard.writeText(phrase);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  return (
    <div className="min-h-screen p-6">
      <div className="max-w-2xl mx-auto space-y-6 py-8">
        <div className="flex items-center justify-between mb-6">
          <button onClick={() => router.back()} className="text-primary hover:text-primary-light">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <h1 className="text-xl font-bold text-white">Recovery Phrase</h1>
          <div className="w-6"></div>
        </div>

        {showWarning && (
          <div className="bg-primary/10 border border-primary/30 rounded-xl p-6">
            <div className="flex items-start gap-3">
              <svg className="w-6 h-6 text-primary flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              <div className="flex-1">
                <p className="text-primary font-semibold mb-2">⚠️ Keep This Secret</p>
                <p className="text-sm text-gray-400">
                  This is the ONLY way to recover your account. Store it safely and never share it with anyone. Anyone with this phrase can access your account.
                </p>
              </div>
              <button
                onClick={() => setShowWarning(false)}
                className="text-gray-500 hover:text-white"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        )}

        <div className="grid grid-cols-2 gap-3">
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

        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4">
          <p className="text-red-400 text-sm">
            <strong>Important:</strong> Write this phrase down on paper and store it in a safe place. Do not store it digitally or take screenshots.
          </p>
        </div>
      </div>
    </div>
  );
}
