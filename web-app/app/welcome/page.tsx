'use client';

import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function WelcomePage() {
  const router = useRouter();

  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <div className="w-32 h-32 mx-auto mb-8 relative">
            <div className="absolute inset-0 gradient-bg rounded-3xl blur-2xl opacity-40"></div>
            <div className="relative w-full h-full gradient-bg rounded-3xl flex items-center justify-center shadow-2xl shadow-primary/50">
              <svg className="w-16 h-16 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
          </div>

          <h1 className="text-4xl font-bold mb-4">
            <span className="gradient-text">Welcome to Mercurio</span>
          </h1>

          <p className="text-gray-400 text-lg mb-8">
            Private messaging that requires no personal information. Ever.
          </p>

          <div className="space-y-4 mb-12">
            <FeatureItem icon="🚫" text="No personal info" />
            <FeatureItem icon="🔒" text="End-to-end encrypted" />
            <FeatureItem icon="👤" text="Anonymous identity" />
          </div>
        </div>

        <div className="space-y-4">
          <Link
            href="/register"
            className="block w-full py-4 px-6 text-center font-semibold text-black gradient-bg rounded-xl hover:opacity-90 transition-opacity shadow-lg shadow-primary/30"
          >
            Create New Account
          </Link>

          <Link
            href="/restore"
            className="block w-full py-4 px-6 text-center font-semibold text-primary border-2 border-primary rounded-xl hover:bg-primary/10 transition-colors"
          >
            Restore from Phrase
          </Link>
        </div>

        <p className="text-center text-sm text-gray-500 mt-8">
          Privacy is a right, not a privilege.
        </p>
      </div>
    </div>
  );
}

function FeatureItem({ icon, text }: { icon: string; text: string }) {
  return (
    <div className="flex items-center gap-4 px-6">
      <span className="text-2xl">{icon}</span>
      <span className="text-lg text-gray-300">{text}</span>
    </div>
  );
}
