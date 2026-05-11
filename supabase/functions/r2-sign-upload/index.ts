// Supabase Edge Function (template)
// Purpose: return signed R2 upload URL and storage path for client upload.
// This is a template placeholder. Implement Cloudflare signing logic server-side.

Deno.serve(async (_req) => {
  return Response.json(
    {
      ok: false,
      error: 'Not implemented: add Cloudflare R2 signing logic here',
    },
    { status: 501 },
  )
})
