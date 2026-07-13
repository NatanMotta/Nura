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

    const { trackId, rawStoragePath, storagePath, error } = await req.json()
    if (
      (typeof trackId !== 'string' || trackId.length === 0) &&
      (typeof rawStoragePath !== 'string' || rawStoragePath.length === 0)
    ) {
      return new Response('trackId or rawStoragePath is required', { status: 400 })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    let resolvedTrackId = typeof trackId === 'string' ? trackId : null
    if (!resolvedTrackId) {
      const { data: track, error: lookupError } = await admin
        .from('tracks')
        .select('id')
        .eq('raw_storage_path', rawStoragePath)
        .maybeSingle()

      if (lookupError) {
        return Response.json({ ok: false, error: lookupError.message }, { status: 400 })
      }
      if (!track) {
        return Response.json({ ok: false, error: 'Track not found' }, { status: 404 })
      }
      resolvedTrackId = track.id
    }

    const updatePayload =
      typeof error === 'string' && error.trim().length > 0
        ? {
            transcoding_status: 'failed',
            transcoding_error: error.trim(),
          }
        : {
            transcoding_status: 'ready',
            transcoding_error: null,
            storage_path:
              typeof storagePath === 'string' && storagePath.length > 0
                ? storagePath
                : rawStoragePath,
          }

    const { error: updateError } = await admin
        .from('tracks')
        .update(updatePayload)
        .eq('id', resolvedTrackId)

    if (updateError) {
      return Response.json({ ok: false, error: updateError.message }, { status: 400 })
    }

    return Response.json({ ok: true })
  } catch (e) {
    return Response.json({ ok: false, error: String(e) }, { status: 500 })
  }
})
