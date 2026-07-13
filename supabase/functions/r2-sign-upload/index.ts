import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const encoder = new TextEncoder()
const awsRegion = 'auto'
const awsService = 's3'
const maxAudioBytes = 25 * 1024 * 1024
const maxCoverBytes = 8 * 1024 * 1024

type UploadType = 'audio' | 'audio_raw' | 'cover'

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response('Missing authorization header', { status: 401 })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const authClient = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: authHeader } },
    })

    const {
      data: { user },
      error: userError,
    } = await authClient.auth.getUser()

    if (userError || !user) {
      return Response.json(
        { ok: false, error: userError?.message ?? 'Unauthorized' },
        { status: 401 },
      )
    }

    const { fileName, contentType, bytesLength, objectType } = await req.json()
    const normalizedType = normalizeObjectType(objectType)

    const validationError = validatePayload({
      fileName,
      contentType,
      bytesLength,
      objectType: normalizedType,
    })
    if (validationError) {
      return Response.json({ ok: false, error: validationError }, { status: 400 })
    }

    const accountId = Deno.env.get('R2_ACCOUNT_ID')!
    const accessKeyId = Deno.env.get('R2_ACCESS_KEY_ID')!
    const secretAccessKey = Deno.env.get('R2_SECRET_ACCESS_KEY')!
    const bucketName = Deno.env.get('R2_BUCKET_NAME')!
    const publicBaseUrl = Deno.env.get('R2_PUBLIC_BASE_URL')

    if (!accountId || !accessKeyId || !secretAccessKey || !bucketName) {
      return Response.json(
        { ok: false, error: 'Missing R2 environment configuration' },
        { status: 500 },
      )
    }

    const now = new Date()
    const amzDate = toAmzDate(now)
    const dateStamp = toDateStamp(now)
    const credentialScope = `${dateStamp}/${awsRegion}/${awsService}/aws4_request`
    const sanitizedFileName = sanitizeFileName(fileName)
    const storagePath = buildStoragePath(user.id, normalizedType, sanitizedFileName)
    const host = `${accountId}.r2.cloudflarestorage.com`
    const endpoint = `https://${host}/${bucketName}/${storagePath}`
    const expires = '900'

    const query = new URLSearchParams({
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': `${accessKeyId}/${credentialScope}`,
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': expires,
      'X-Amz-SignedHeaders': 'host',
    })

    const canonicalRequest = [
      'PUT',
      `/${bucketName}/${storagePath}`,
      query.toString(),
      `host:${host}\n`,
      'host',
      'UNSIGNED-PAYLOAD',
    ].join('\n')

    const stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      await sha256Hex(canonicalRequest),
    ].join('\n')

    const signingKey = await getSigningKey(secretAccessKey, dateStamp, awsRegion, awsService)
    const signature = await hmacHex(signingKey, stringToSign)
    query.set('X-Amz-Signature', signature)

    return Response.json({
      ok: true,
      uploadUrl: `${endpoint}?${query.toString()}`,
      storagePath,
      publicUrl: publicBaseUrl
        ? `${publicBaseUrl.replace(/\/$/, '')}/${storagePath}`
        : null,
      headers: {},
    })
  } catch (error) {
    return Response.json({ ok: false, error: String(error) }, { status: 500 })
  }
})

function validatePayload(payload: {
  fileName?: unknown
  contentType?: unknown
  bytesLength?: unknown
  objectType: UploadType
}) {
  const { fileName, contentType, bytesLength, objectType } = payload
  if (typeof fileName !== 'string' || fileName.trim().length === 0) {
    return 'fileName is required'
  }
  if (typeof contentType !== 'string' || contentType.trim().length === 0) {
    return 'contentType is required'
  }
  if (typeof bytesLength !== 'number' || !Number.isFinite(bytesLength) || bytesLength <= 0) {
    return 'bytesLength must be a positive number'
  }

  const maxBytes = objectType === 'cover' ? maxCoverBytes : maxAudioBytes
  if (bytesLength > maxBytes) {
    return `file too large for ${objectType}`
  }

  if (objectType === 'audio' && !contentType.toLowerCase().startsWith('audio/')) {
    return 'audio uploads require an audio/* content type'
  }

  if (objectType === 'audio_raw' && !contentType.toLowerCase().startsWith('audio/')) {
    return 'raw audio uploads require an audio/* content type'
  }

  if (objectType === 'cover' && !contentType.toLowerCase().startsWith('image/')) {
    return 'cover uploads require an image/* content type'
  }

  return null
}

function buildStoragePath(userId: string, objectType: UploadType, fileName: string) {
  const folder = objectType === 'cover'
    ? 'covers'
    : objectType === 'audio_raw'
    ? 'raw'
    : 'tracks'
  return `${folder}/${userId}/${crypto.randomUUID()}-${fileName}`
}

function normalizeObjectType(value: unknown): UploadType {
  if (value === 'cover') return 'cover'
  if (value === 'audio_raw') return 'audio_raw'
  return 'audio'
}

function sanitizeFileName(fileName: string) {
  const trimmed = fileName.trim().toLowerCase()
  return trimmed
    .replace(/[^a-z0-9.\-_]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
}

function toAmzDate(date: Date) {
  return date.toISOString().replace(/[:-]|\.\d{3}/g, '')
}

function toDateStamp(date: Date) {
  return date.toISOString().slice(0, 10).replace(/-/g, '')
}

async function sha256Hex(value: string) {
  const digest = await crypto.subtle.digest('SHA-256', encoder.encode(value))
  return toHex(digest)
}

async function hmac(key: BufferSource, value: string) {
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    key,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  return await crypto.subtle.sign('HMAC', cryptoKey, encoder.encode(value))
}

async function hmacHex(key: ArrayBuffer, value: string) {
  return toHex(await hmac(key, value))
}

async function getSigningKey(
  secretAccessKey: string,
  dateStamp: string,
  region: string,
  service: string,
) {
  const kDate = await hmac(encoder.encode(`AWS4${secretAccessKey}`), dateStamp)
  const kRegion = await hmac(kDate, region)
  const kService = await hmac(kRegion, service)
  return await hmac(kService, 'aws4_request')
}

function toHex(buffer: ArrayBuffer) {
  return Array.from(new Uint8Array(buffer))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}
