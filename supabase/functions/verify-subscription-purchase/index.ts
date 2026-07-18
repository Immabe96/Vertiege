// Subscription receipt verification (scaffold).
// Default mode: stub — forwards to verify_subscription_purchase RPC (same as the app today).
// Live mode: reserved for Apple App Store Server API + Google Play Developer API (not implemented).

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { verifyWithStoreApis } from './store_verify_live.ts'

type VerifyBody = {
  product_id?: string
  purchase_token?: string
  platform?: string
  store_payload?: string | null
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

const productTiers: Record<string, string> = {
  subscription_patrician: 'patrician',
  subscription_sovereign_elite: 'sovereign_elite',
}

const VERIFY_RATE_MAX = 30
const VERIFY_RATE_WINDOW_SEC = 3600

async function assertRateLimit(
  userId: string,
): Promise<Response | null> {
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim()
  if (!serviceKey) return null

  const admin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    serviceKey,
  )
  const { error } = await admin.rpc('assert_edge_rate_limit', {
    p_scope: 'verify_subscription_purchase',
    p_subject: userId,
    p_max: VERIFY_RATE_MAX,
    p_window_seconds: VERIFY_RATE_WINDOW_SEC,
  })
  if (error?.message?.includes('rate_limit_exceeded')) {
    return json(
      { success: false, error: 'Too many verification attempts. Try again later.' },
      429,
    )
  }
  return null
}

function requiredEnvDocs(): Record<string, string> {
  return {
    STORE_RECEIPT_VERIFY_MODE:
      "live (required for prod) | stub — stub only when ALLOW_STUB_RECEIPT_VERIFY=true",
    ALLOW_STUB_RECEIPT_VERIFY:
      "Set true only for local/dev; production must omit this and use live mode",
    SUPABASE_URL: 'Project URL (auto-injected)',
    SUPABASE_ANON_KEY: 'Anon key (auto-injected)',
    SUPABASE_SERVICE_ROLE_KEY:
      'Optional; not required in stub mode when caller JWT is used',
    APPLE_ISSUER_ID: 'App Store Connect issuer ID (live mode)',
    APPLE_KEY_ID: 'App Store Connect API key ID (live mode)',
    APPLE_PRIVATE_KEY:
      'App Store Connect API private key PEM, base64 or raw (live mode)',
    APPLE_BUNDLE_ID: 'iOS app bundle id, e.g. com.vertiege (live mode)',
    GOOGLE_PLAY_PACKAGE_NAME: 'Android applicationId (live mode)',
    GOOGLE_PLAY_SERVICE_ACCOUNT_JSON:
      'Google Play service account JSON string (live mode)',
  }
}

function validateBody(body: VerifyBody): string | null {
  const productId = body.product_id?.trim()
  const token = body.purchase_token?.trim()
  if (!productId || !productTiers[productId]) {
    return 'Unknown or missing product_id'
  }
  if (!token || token.length < 8) {
    return 'Invalid purchase_token'
  }
  const platform = (body.platform ?? 'unknown').toLowerCase()
  if (platform === 'ios' && token.length < 16) {
    return 'Invalid App Store receipt'
  }
  if (platform === 'android' && token.length < 12) {
    return 'Invalid Play purchase token'
  }
  return null
}

async function verifyViaRpc(
  authHeader: string,
  body: VerifyBody,
): Promise<Response> {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } },
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return json({ success: false, error: 'Not authenticated' }, 401)
  }

  const rateLimited = await assertRateLimit(user.id)
  if (rateLimited != null) return rateLimited

  const validationError = validateBody(body)
  if (validationError) {
    return json({ success: false, error: validationError }, 400)
  }

  const { data, error } = await supabase.rpc('verify_subscription_purchase', {
    p_product_id: body.product_id!.trim(),
    p_purchase_token: body.purchase_token!.trim(),
    p_platform: body.platform ?? 'unknown',
    p_store_payload: body.store_payload ?? null,
  })

  if (error) {
    return json({ success: false, error: error.message }, 500)
  }

  return json({
    ...(typeof data === 'object' && data !== null ? data : { success: false }),
    mode: 'stub',
    message:
      'Stub mode: store APIs not called. Configure STORE_RECEIPT_VERIFY_MODE=live when Apple/Google secrets are set.',
  })
}

function liveModeReadiness(): { ready: boolean; missing: string[] } {
  const required = [
    'APPLE_ISSUER_ID',
    'APPLE_KEY_ID',
    'APPLE_PRIVATE_KEY',
    'APPLE_BUNDLE_ID',
    'GOOGLE_PLAY_PACKAGE_NAME',
    'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON',
  ]
  const missing = required.filter((key) => !Deno.env.get(key)?.trim())
  return { ready: missing.length === 0, missing }
}

serve(async (req: Request) => {
  if (req.method === 'GET') {
    const mode = Deno.env.get('STORE_RECEIPT_VERIFY_MODE') ?? 'stub'
    const live = liveModeReadiness()
    return json({
      function: 'verify-subscription-purchase',
      mode,
      live_ready: live.ready,
      missing_live_secrets: live.missing,
      env_documentation: requiredEnvDocs(),
    })
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return json({ success: false, error: 'Authorization required' }, 401)
  }

  let body: VerifyBody
  try {
    body = await req.json()
  } catch {
    return json({ success: false, error: 'Invalid JSON body' }, 400)
  }

  const mode = (Deno.env.get('STORE_RECEIPT_VERIFY_MODE') ?? 'stub').toLowerCase()
  const allowStub =
    Deno.env.get('ALLOW_STUB_RECEIPT_VERIFY')?.trim().toLowerCase() === 'true'

  if (mode === 'live') {
    const live = liveModeReadiness()
    if (!live.ready) {
      return json(
        {
          success: false,
          error: 'Live receipt verify not configured',
          missing_secrets: live.missing,
          env_documentation: requiredEnvDocs(),
        },
        503,
      )
    }
    const liveResult = await verifyWithStoreApis({
      product_id: body.product_id!.trim(),
      purchase_token: body.purchase_token!.trim(),
      platform: body.platform ?? 'unknown',
      store_payload: body.store_payload ?? null,
    })

    if (!liveResult.ok) {
      return json({ success: false, error: liveResult.error, mode: 'live' }, 400)
    }

    const rpcResponse = await verifyViaRpc(authHeader, body)
    const rpcJson = await rpcResponse.json()
    return json({ ...rpcJson, mode: 'live' }, rpcResponse.status)
  }

  // Fail closed unless explicitly opted into stub (local/dev only).
  if (!allowStub) {
    return json(
      {
        success: false,
        error:
          'Receipt verification is not configured for production. Set STORE_RECEIPT_VERIFY_MODE=live (preferred) or ALLOW_STUB_RECEIPT_VERIFY=true for non-prod only.',
        mode: mode,
        env_documentation: requiredEnvDocs(),
      },
      503,
    )
  }

  return verifyViaRpc(authHeader, body)
})
