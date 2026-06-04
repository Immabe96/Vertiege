// Subscription receipt verification (scaffold).
// Default mode: stub — forwards to verify_subscription_purchase RPC (same as the app today).
// Live mode: reserved for Apple App Store Server API + Google Play Developer API (not implemented).

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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

function requiredEnvDocs(): Record<string, string> {
  return {
    STORE_RECEIPT_VERIFY_MODE:
      "stub (default) | live — stub uses RPC only; live requires Apple/Google implementation below",
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
    return json(
      {
        success: false,
        error: 'Live Apple/Google verification is not implemented yet',
        hint:
          'Implement App Store Server API and Play purchases.subscriptionsv2.get, then call verify_subscription_purchase on success.',
        env_documentation: requiredEnvDocs(),
      },
      501,
    )
  }

  return verifyViaRpc(authHeader, body)
})
