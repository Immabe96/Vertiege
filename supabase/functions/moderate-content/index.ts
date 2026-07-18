// Server-side content moderation for posts/messages.
// Always applies a local policy filter; optionally calls OpenAI Moderations when
// OPENAI_API_KEY is set. Clients cannot bypass this when create/send RPCs call it.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  })

const PROFANITY = new Set([
  'fuck',
  'shit',
  'damn',
  'ass',
  'bitch',
  'bastard',
  'crap',
  'dick',
  'piss',
  'cunt',
  'whore',
  'slut',
  'douche',
  'moron',
  'idiot',
])

const BLOCKED_PATTERNS = [
  /\b(hate\s*speech|slur|violence|threat)\b/i,
  /\b(kill|murder|attack)\s*(yourself|others|them|everyone)\b/i,
  /\b(d[o0]x|x[s$]s)\b/i,
  /https?:\/\/\S*\.(onion|bit)\b/i,
]

function normalizeLeet(text: string): string {
  return text
    .replaceAll('4', 'a')
    .replaceAll('3', 'e')
    .replaceAll('1', 'i')
    .replaceAll('0', 'o')
    .replaceAll('5', 's')
    .replaceAll('7', 't')
    .replaceAll('@', 'a')
    .replaceAll('$', 's')
    .replaceAll('!', 'i')
    .replaceAll('+', 't')
}

function localCheck(text: string): string | null {
  const trimmed = text.trim()
  if (!trimmed) return 'Content cannot be empty'
  if (trimmed.length > 8000) return 'Content is too long'

  const lower = trimmed.toLowerCase()
  const leet = normalizeLeet(lower)
  for (const word of PROFANITY) {
    const re = new RegExp(`\\b${word}\\b`)
    if (re.test(lower) || re.test(leet)) {
      return 'Content contains inappropriate language'
    }
  }
  for (const pattern of BLOCKED_PATTERNS) {
    if (pattern.test(lower) || pattern.test(leet)) {
      return 'Content may violate community guidelines'
    }
  }
  if (trimmed.length > 50) {
    const caps = [...trimmed].filter((c) => c >= 'A' && c <= 'Z').length
    if (caps / trimmed.length > 0.5) return 'Content appears to be spam'
  }
  if (/(.)\1{5,}/.test(trimmed)) return 'Content appears to be spam'
  return null
}

async function openAiModeration(text: string): Promise<string | null> {
  const key = Deno.env.get('OPENAI_API_KEY')?.trim()
  if (!key) return null

  const res = await fetch('https://api.openai.com/v1/moderations', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ input: text }),
  })
  if (!res.ok) {
    const failClosed =
      Deno.env.get('MODERATION_FAIL_CLOSED')?.trim().toLowerCase() === 'true'
    if (failClosed) return 'Moderation service unavailable'
    console.warn(`[moderate-content] OpenAI ${res.status}`)
    return null
  }
  const data = await res.json()
  const flagged = data?.results?.[0]?.flagged === true
  if (flagged) return 'Content may violate community guidelines'
  return null
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return json({ allowed: false, error: 'Method not allowed' }, 405)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return json({ allowed: false, error: 'Authorization required' }, 401)
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } },
  )
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser()
  if (authError || !user) {
    return json({ allowed: false, error: 'Not authenticated' }, 401)
  }

  let body: { text?: string; surface?: string }
  try {
    body = await req.json()
  } catch {
    return json({ allowed: false, error: 'Invalid JSON body' }, 400)
  }

  const text = body.text ?? ''
  const local = localCheck(text)
  if (local) {
    return json({ allowed: false, error: local, source: 'local' }, 200)
  }

  try {
    const remote = await openAiModeration(text)
    if (remote) {
      return json({ allowed: false, error: remote, source: 'openai' }, 200)
    }
  } catch (e) {
    const failClosed =
      Deno.env.get('MODERATION_FAIL_CLOSED')?.trim().toLowerCase() === 'true'
    if (failClosed) {
      return json(
        { allowed: false, error: 'Moderation service unavailable' },
        503,
      )
    }
    console.warn(`[moderate-content] remote error: ${e}`)
  }

  return json({ allowed: true, source: 'local' })
})
