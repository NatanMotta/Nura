// Supabase Edge Function (template)
// Purpose: sync auth.users app_metadata.role from trusted backend flow
// Deploy after `supabase functions new sync-user-role` and set secrets.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const authHeader = req.headers.get('authorization')
    const internalSecret = Deno.env.get('INTERNAL_ADMIN_SECRET')
    if (!internalSecret || authHeader !== `Bearer ${internalSecret}`) {
      return new Response('Unauthorized', { status: 401 })
    }

    const { userId, role } = await req.json()
    if (!userId || !['user', 'artist', 'label'].includes(role)) {
      return new Response('Invalid payload', { status: 400 })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    const { error } = await admin.auth.admin.updateUserById(userId, {
      app_metadata: { role },
    })

    if (error) {
      return Response.json({ ok: false, error: error.message }, { status: 400 })
    }

    return Response.json({ ok: true })
  } catch (e) {
    return Response.json({ ok: false, error: String(e) }, { status: 500 })
  }
})
