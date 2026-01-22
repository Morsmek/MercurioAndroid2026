'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { cryptoService } from '@/lib/crypto';
import QRCode from 'qrcode';

export default function QRCodePage() {
  const router = useRouter();
  const [qrCodeUrl, setQrCodeUrl] = useState('');
  const [mercurioId, setMercurioId] = useState('');

  useEffect(() => {
    const generateQR = async () => {
      const id = cryptoService.getMercurioId();
      if (!id) {
        router.push('/welcome');
        return;
      }

      setMercurioId(id);

      try {
        const url = await QRCode.toDataURL(id, {
          width: 300,
          margin: 2,
          color: {
            dark: '#000000',
            light: '#FFFFFF',
          },
        });
        setQrCodeUrl(url);
      } catch (error) {
        console.error('Failed to generate QR code:', error);
      }
    };

    generateQR();
  }, [router]);

  return (
    <div className="min-h-screen p-6">
      <div className="max-w-md mx-auto space-y-8 py-8">
        <div className="flex items-center justify-between mb-6">
          <button onClick={() => router.back()} className="text-primary hover:text-primary-light">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <h1 className="text-xl font-bold text-white">Your QR Code</h1>
          <div className="w-6"></div>
        </div>

        <div className="text-center">
          <p className="text-gray-400 mb-8">
            Share this QR code with others to let them add you as a contact
          </p>

          <div className="bg-white p-8 rounded-3xl inline-block mb-8">
            {qrCodeUrl ? (
              <img src={qrCodeUrl} alt="QR Code" className="w-64 h-64" />
            ) : (
              <div className="w-64 h-64 flex items-center justify-center">
                <svg className="animate-spin h-12 w-12 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              </div>
            )}
          </div>

          <div className="bg-white/5 rounded-xl p-4 mb-4">
            <p className="text-sm text-gray-400 mb-2">Your Mercurio ID</p>
            <p className="text-xs text-gray-500 font-mono break-all">{mercurioId}</p>
          </div>

          <button
            onClick={() => {
              navigator.clipboard.writeText(mercurioId);
            }}
            className="w-full py-3 px-6 text-primary border border-primary rounded-xl hover:bg-primary/10 transition-colors flex items-center justify-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
            Copy Mercurio ID
          </button>
        </div>
      </div>
    </div>
  );
}
