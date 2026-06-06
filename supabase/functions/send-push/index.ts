// Supabase Database Webhook handler for INSERTs into public.notifications.
// Supabase remains the source of truth for notification rows and device tokens;
// Firebase Cloud Messaging is used only as the delivery transport.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type NotificationRecord = {
  id: string
  recipient_id: string
  type?: string
  message?: string
  world_id?: string | null
  post_id?: string | null
  channel_id?: string | null
  room_id?: string | null
}

type DeviceToken = {
  token: string
  platform?: string | null
}

type ServiceAccount = {
  client_email: string
  private_key: string
  project_id: string
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

serve(async (req: Request) => {
  try {
    const webhookSecret = Deno.env.get('WEBHOOK_SECRET')
    if (!webhookSecret) return json({ error: 'WEBHOOK_SECRET not set' }, 500)

    const authHeader = req.headers.get('Authorization')
    if (authHeader !== `Bearer ${webhookSecret}`) {
      return json({ error: 'Unauthorized' }, 401)
    }

    const payload = await req.json()
    const record = payload.record as NotificationRecord | undefined
    if (!record?.recipient_id) return json({ skipped: true })

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')

    if (!supabaseUrl || !serviceRoleKey || !serviceAccountJson) {
      return json(
        {
          error:
            'Missing SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, or FIREBASE_SERVICE_ACCOUNT_JSON',
        },
        500,
      )
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey)
    const { data, error } = await supabase
      .from('device_tokens')
      .select('token, platform')
      .eq('resident_id', record.recipient_id)

    if (error) return json({ error: error.message }, 500)

    const tokens = (data ?? []) as DeviceToken[]
    if (tokens.length === 0) return json({ delivered: 0, skipped: 'no_tokens' })

    const serviceAccount = JSON.parse(serviceAccountJson) as ServiceAccount
    const accessToken = await getFirebaseAccessToken(serviceAccount)
    const results = await Promise.allSettled(
      tokens.map((device) => sendFcmMessage(serviceAccount.project_id, accessToken, device.token, record)),
    )

    const invalidTokens = tokens
      .filter((_, index) => {
        const result = results[index]
        return (
          result.status === 'fulfilled' &&
          (result.value.errorCode === 'UNREGISTERED' ||
            result.value.errorCode === 'INVALID_ARGUMENT')
        )
      })
      .map((device) => device.token)

    if (invalidTokens.length > 0) {
      await supabase.from('device_tokens').delete().in('token', invalidTokens)
    }

    return json({
      delivered: results.filter((result) => result.status === 'fulfilled' && result.value.ok).length,
      failed: results.filter((result) => result.status === 'rejected' || !result.value.ok).length,
      invalid_removed: invalidTokens.length,
    })
  } catch (error) {
    console.error('[send-push] failed', error)
    return json({ error: 'Internal server error' }, 500)
  }
})

async function sendFcmMessage(
  projectId: string,
  accessToken: string,
  token: string,
  record: NotificationRecord,
): Promise<{ ok: boolean; errorCode?: string }> {
  const isDm = record.type === 'dmMessage' && !!record.room_id
  const data = compactStringMap({
    notification_id: record.id,
    type: record.type,
    world_id: record.world_id,
    post_id: record.post_id,
    channel_id: record.channel_id,
    room_id: record.room_id,
    route: routeFor(record),
    message: record.message,
    sender_name: dmSenderName(record.message),
  })

  const messageBody: Record<string, unknown> = {
    token,
    data,
    android: {
      priority: 'HIGH',
      ...(isDm && record.room_id
        ? { collapse_key: record.room_id }
        : {}),
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  }

  // DM: data-only so the app can show MessagingStyle + inline Reply action.
  if (!isDm) {
    messageBody.notification = {
      title: notificationTitle(record),
      body: record.message ?? 'You have a new Vertiege notification.',
    }
    ;(messageBody.android as Record<string, unknown>).notification = {
      channel_id: 'vertiege_notifications',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    }
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message: messageBody }),
    },
  )

  if (response.ok) return { ok: true }
  const body = await response.json().catch(() => ({}))
  const errorCode = body?.error?.details?.[0]?.errorCode ?? body?.error?.status
  console.warn('[send-push] FCM send failed', response.status, errorCode)
  return { ok: false, errorCode }
}

async function getFirebaseAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const assertion = await signJwt(
    {
      alg: 'RS256',
      typ: 'JWT',
    },
    {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    },
    serviceAccount.private_key,
  )

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  })

  if (!response.ok) {
    throw new Error(`Firebase token exchange failed: ${response.status}`)
  }
  const token = await response.json()
  return token.access_token
}

async function signJwt(
  header: Record<string, unknown>,
  payload: Record<string, unknown>,
  privateKeyPem: string,
) {
  const encodedHeader = base64UrlEncode(JSON.stringify(header))
  const encodedPayload = base64UrlEncode(JSON.stringify(payload))
  const data = `${encodedHeader}.${encodedPayload}`
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKeyPem),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(data),
  )
  return `${data}.${base64UrlEncode(signature)}`
}

function pemToArrayBuffer(pem: string) {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '')
  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
  return bytes.buffer
}

function base64UrlEncode(input: string | ArrayBuffer) {
  const bytes =
    typeof input === 'string'
      ? new TextEncoder().encode(input)
      : new Uint8Array(input)
  let binary = ''
  for (const byte of bytes) binary += String.fromCharCode(byte)
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '')
}

function compactStringMap(values: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(values)
      .filter(([, value]) => value != null && `${value}`.length > 0)
      .map(([key, value]) => [key, `${value}`]),
  )
}

function dmSenderName(message?: string) {
  if (!message) return 'Someone'
  const idx = message.indexOf(':')
  if (idx <= 0) return 'Someone'
  return message.slice(0, idx).trim() || 'Someone'
}

function notificationTitle(record: NotificationRecord) {
  switch (record.type) {
    case 'dmMessage':
      return dmSenderName(record.message)
    case 'comment':
      return 'New comment'
    case 'like':
      return 'New reaction'
    case 'mention':
      return 'You were mentioned'
    case 'worldUnlocked':
      return 'World unlocked'
    case 'allegianceRequest':
      return 'New alliance request'
    case 'achievementApproved':
      return 'Achievement verified'
    case 'achievementRejected':
      return 'Achievement review'
    case 'identityVerified':
      return 'Identity verified'
    case 'identityRejected':
      return 'Identity review'
    default:
      return 'Vertiege'
  }
}

function routeFor(record: NotificationRecord) {
  const type = record.type ?? ''

  if (type === 'dmMessage') {
    if (record.room_id) {
      return `/chat/${encodeURIComponent(record.room_id)}`
    }
    return '/chat'
  }

  if (
    type === 'achievementApproved' ||
    type === 'identityVerified' ||
    type === 'identityRejected'
  ) {
    return '/identity'
  }

  if (type === 'achievementRejected') {
    return '/achievements'
  }

  if (
    (type === 'like' || type === 'comment') &&
    record.world_id &&
    record.post_id
  ) {
    return `/explore/${encodeURIComponent(record.world_id)}?post=${encodeURIComponent(record.post_id)}`
  }

  if (record.room_id) return `/chat/${encodeURIComponent(record.room_id)}`
  if (record.post_id) return `/post/${record.post_id}`
  if (record.channel_id) return `/campfire/${record.channel_id}`
  if (record.world_id) return `/explore/${encodeURIComponent(record.world_id)}`
  return `/notifications/${encodeURIComponent(record.id)}`
}
