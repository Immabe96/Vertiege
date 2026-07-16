// Authenticated account deletion: best-effort user-owned row cleanup, then auth user removal.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

const DELETE_RATE_MAX = 5
const DELETE_RATE_WINDOW_SEC = 3600

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  })

async function assertRateLimit(userId: string): Promise<Response | null> {
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim()
  if (!serviceKey) return null

  const admin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    serviceKey,
  )
  const { error } = await admin.rpc('assert_edge_rate_limit', {
    p_scope: 'delete_account',
    p_subject: userId,
    p_max: DELETE_RATE_MAX,
    p_window_seconds: DELETE_RATE_WINDOW_SEC,
  })
  if (error?.message?.includes('rate_limit_exceeded')) {
    return json(
      { success: false, error: 'Too many delete attempts. Try again later.' },
      429,
    )
  }
  return null
}

function isMissingTableError(message?: string): boolean {
  if (!message) return false
  const lower = message.toLowerCase()
  return (
    lower.includes('does not exist') ||
    lower.includes('could not find') ||
    lower.includes('schema cache')
  )
}

async function deleteBestEffort(
  admin: SupabaseClient,
  table: string,
  column: string,
  userId: string,
): Promise<void> {
  const { error } = await admin.from(table).delete().eq(column, userId)
  if (!error) return

  if (isMissingTableError(error.message)) {
    console.warn(`[delete-account] skip ${table}: ${error.message}`)
    return
  }

  console.warn(`[delete-account] ${table} delete failed: ${error.message}`)
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return json({ success: false, error: 'Method not allowed' }, 405)
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim()
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')?.trim()
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim()

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return json(
        {
          success: false,
          error: 'Missing SUPABASE_URL, SUPABASE_ANON_KEY, or SUPABASE_SERVICE_ROLE_KEY',
        },
        500,
      )
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ success: false, error: 'Authorization required' }, 401)
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) {
      return json({ success: false, error: 'Not authenticated' }, 401)
    }

    const userId = user.id

    const rateLimited = await assertRateLimit(userId)
    if (rateLimited != null) return rateLimited

    const admin = createClient(supabaseUrl, serviceRoleKey)

    await deleteBestEffort(admin, 'device_tokens', 'resident_id', userId)
    await deleteBestEffort(admin, 'notifications', 'recipient_id', userId)
    await deleteBestEffort(admin, 'profiles', 'id', userId)

    const { error: deleteUserError } = await admin.auth.admin.deleteUser(userId)
    if (deleteUserError) {
      console.error('[delete-account] auth.admin.deleteUser failed', deleteUserError)
      return json({ success: false, error: deleteUserError.message }, 500)
    }

    return json({ success: true })
  } catch (error) {
    console.error('[delete-account] failed', error)
    return json({ success: false, error: 'Internal server error' }, 500)
  }
})
