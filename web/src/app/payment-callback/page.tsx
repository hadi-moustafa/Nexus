'use client';

import { Suspense, useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';

function DeepLinkRedirect() {
  const params = useSearchParams();
  const [timedOut, setTimedOut] = useState(false);
  const [deepLink, setDeepLink] = useState('');

  useEffect(() => {
    const status = params.get('status') ?? 'canceled';
    const sessionId = params.get('session_id');

    let link = `com.example.nexus://payment-callback?status=${status}`;
    if (sessionId) link += `&session_id=${encodeURIComponent(sessionId)}`;

    setDeepLink(link);
    window.location.href = link;

    // If the app doesn't catch the deep link within 2s, show a manual button
    const timer = setTimeout(() => setTimedOut(true), 2000);
    return () => clearTimeout(timer);
  }, [params]);

  return (
    <div style={{
      fontFamily: 'sans-serif',
      textAlign: 'center',
      padding: '48px 24px',
      maxWidth: 400,
      margin: '0 auto',
    }}>
      <p style={{ fontSize: 18, fontWeight: 600, marginBottom: 8 }}>
        Redirecting back to the app…
      </p>
      <p style={{ fontSize: 14, color: '#666', marginBottom: 32 }}>
        If the app doesn&apos;t open automatically, tap the button below.
      </p>
      {timedOut && (
        <a
          href={deepLink}
          style={{
            display: 'inline-block',
            padding: '14px 32px',
            background: '#00BCD4',
            color: '#fff',
            borderRadius: 10,
            textDecoration: 'none',
            fontWeight: 700,
            fontSize: 15,
          }}
        >
          Open Nexus App
        </a>
      )}
    </div>
  );
}

export default function PaymentCallbackPage() {
  return (
    <Suspense>
      <DeepLinkRedirect />
    </Suspense>
  );
}
