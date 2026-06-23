import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.33.1"
import { S3Client, PutObjectCommand } from "npm:@aws-sdk/client-s3@3.400.0"
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner@3.400.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Gestione preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Manca header Authorization')
    }

    // 1. Verifica utente tramite JWT
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

    // 2. Parsa la richiesta
    const { fileName, contentType, bytesLength } = await req.json()

    if (!fileName || !contentType) {
      throw new Error('Parametri fileName o contentType mancanti')
    }

    // Limite di grandezza (es: max 50MB per traccia/cover)
    const MAX_BYTES = 50 * 1024 * 1024
    if (bytesLength > MAX_BYTES) {
      throw new Error('File troppo grande (max 50MB)')
    }

    // 3. Configurazione Cloudflare R2
    const accountId = Deno.env.get('R2_ACCOUNT_ID')
    const accessKeyId = Deno.env.get('R2_ACCESS_KEY_ID')
    const secretAccessKey = Deno.env.get('R2_SECRET_ACCESS_KEY')
    const bucketName = Deno.env.get('R2_BUCKET_NAME')

    if (!accountId || !accessKeyId || !secretAccessKey || !bucketName) {
      throw new Error('Credenziali R2 non configurate nel backend')
    }

    const s3Client = new S3Client({
      region: 'auto',
      endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
    })

    // 4. Genera Path Univoco: folder utente + timestamp
    const ext = fileName.split('.').pop()
    const safeName = fileName.replace(/[^a-zA-Z0-9]/g, '_')
    const storagePath = `${user.id}/${Date.now()}_${safeName}.${ext}`

    // 5. Genera la Presigned URL
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: storagePath,
      ContentType: contentType,
      ContentLength: bytesLength,
    })

    const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 })

    return new Response(
      JSON.stringify({
        uploadUrl: signedUrl,
        storagePath: storagePath,
        headers: {
          'Content-Type': contentType,
        },
      }),
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
