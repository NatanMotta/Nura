import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.33.1"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Manca header Authorization')
    }

    // 1. Inizializza il client Supabase con i token dell'utente per validarlo
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Non autorizzato' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // 2. Inizializza l'Admin Client (Service Role) per bypassare RLS ed eliminare l'utente Auth
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // (Opzionale) 3. Pulizia dei file Supabase Storage. (Cloudflare R2 verrebbe pulito in una coda asincrona o qui)
    // Svuotiamo la cartella avatar dell'utente (formato: {uid}/* o simile, dipende dall'app)
    try {
      const { data: files } = await supabaseAdmin.storage.from('avatars').list(user.id);
      if (files && files.length > 0) {
        await supabaseAdmin.storage.from('avatars').remove(files.map(f => `${user.id}/${f.name}`));
      }
    } catch (e) {
      console.error('Errore pulizia storage avatars', e);
    }

    try {
      const { data: files } = await supabaseAdmin.storage.from('tracks_covers').list(user.id);
      if (files && files.length > 0) {
        await supabaseAdmin.storage.from('tracks_covers').remove(files.map(f => `${user.id}/${f.name}`));
      }
    } catch (e) {
      console.error('Errore pulizia storage tracks_covers', e);
    }

    // 4. ELIMINA UTENTE
    // Il DELETE su auth.users attiva ON DELETE CASCADE su profiles, tracks, follows, curator_pitches
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (deleteError) {
      throw new Error('Errore durante l\'eliminazione utente: ' + deleteError.message)
    }

    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
