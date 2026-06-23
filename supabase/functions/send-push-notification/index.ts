import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.6';
import { initializeApp, cert } from 'npm:firebase-admin@11.11.0/app';
import { getMessaging } from 'npm:firebase-admin@11.11.0/messaging';

// Inizializza l'app Firebase
// Il service account va inserito nei segreti di Supabase:
// supabase secrets set FIREBASE_SERVICE_ACCOUNT='{ "type": "service_account", ... }'
let firebaseApp;
try {
  const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (serviceAccountRaw) {
    const serviceAccount = JSON.parse(serviceAccountRaw);
    firebaseApp = initializeApp({
      credential: cert(serviceAccount),
    });
    console.log('Firebase Admin initialized successfully');
  } else {
    console.warn('FIREBASE_SERVICE_ACCOUNT non trovato. Firebase non è stato inizializzato.');
  }
} catch (e) {
  console.error('Errore durante l\'inizializzazione di Firebase:', e);
}

serve(async (req) => {
  try {
    // 1. Parsing del payload dal Trigger (in_app_notifications)
    const payload = await req.json();
    console.log('Payload ricevuto:', payload);

    // Gestione del payload inviato dal trigger SQL
    // La nostra funzione trigger in SQL imposta la struttura: { record: { ... } }
    const record = payload.record;

    if (!record || !record.profile_id) {
      return new Response(JSON.stringify({ error: 'Payload invalido, profile_id mancante' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (!firebaseApp) {
      return new Response(JSON.stringify({ error: 'Firebase non è configurato (manca FIREBASE_SERVICE_ACCOUNT)' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 2. Inizializza il client Supabase con la Service Role Key per bypassare l'RLS
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 3. Recupera tutti i token FCM registrati per quell'utente
    const { data: devices, error: deviceError } = await supabaseClient
      .from('user_devices')
      .select('fcm_token, platform')
      .eq('profile_id', record.profile_id);

    if (deviceError) {
      console.error('Errore nel recupero dei dispositivi:', deviceError);
      throw deviceError;
    }

    if (!devices || devices.length === 0) {
      console.log('Nessun dispositivo registrato per l\'utente:', record.profile_id);
      return new Response(JSON.stringify({ message: 'Nessun dispositivo, notifica non inviata' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const tokens = devices.map((d) => d.fcm_token);

    // 4. Prepara il payload del messaggio FCM
    // Nota: I dati "record.data" possono contenere attributi utili (es. track_id)
    const message = {
      notification: {
        title: record.title,
        body: record.body,
      },
      data: {
        // I dati aggiuntivi devono essere tutti stringhe su FCM
        type: record.type,
        notification_id: record.id,
        ...Object.fromEntries(
          Object.entries(record.data || {}).map(([key, value]) => [key, String(value)])
        ),
      },
      tokens: tokens,
    };

    // 5. Invia la Push Notification tramite Firebase Cloud Messaging
    const response = await getMessaging().sendEachForMulticast(message);
    
    console.log('Risultato invio FCM:', response.successCount, 'successi,', response.failureCount, 'fallimenti');

    // Opzionale: pulizia dei token non più validi se failureCount > 0
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            failedTokens.push(tokens[idx]);
          }
        }
      });
      
      if (failedTokens.length > 0) {
        console.log('Rimozione di', failedTokens.length, 'token FCM non più validi.');
        await supabaseClient
          .from('user_devices')
          .delete()
          .in('fcm_token', failedTokens);
      }
    }

    return new Response(JSON.stringify({ 
      message: 'Notifiche Push processate', 
      successCount: response.successCount,
      failureCount: response.failureCount
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Errore fatale nell\'Edge Function:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
