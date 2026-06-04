import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { AccessToken } from 'https://esm.sh/livekit-server-sdk@2'

const TOKEN_RATE_MAX = 60
const TOKEN_RATE_WINDOW_SEC = 3600
const CHANNEL_RATE_MAX = 12
const CHANNEL_RATE_WINDOW_SEC = 60

async function assertRateLimit(
  scope: string,
  subject: string,
  max: number,
  windowSeconds: number,
): Promise<Response | null> {
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim()
  if (!serviceKey) return null

  const admin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    serviceKey,
  )
  const { error } = await admin.rpc('assert_edge_rate_limit', {
    p_scope: scope,
    p_subject: subject,
    p_max: max,
    p_window_seconds: windowSeconds,
  })
  if (error?.message?.includes('rate_limit_exceeded')) {
    return new Response(
      JSON.stringify({ error: 'Too many voice token requests. Try again later.' }),
      { status: 429, headers: { 'Content-Type': 'application/json' } },
    )
  }
  return null
}

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    const { channelId, worldId, participantIdentity } = await req.json()

    if (!channelId || !worldId || !participantIdentity) {
      return new Response(
        JSON.stringify({ error: 'channelId, worldId and participantIdentity required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }
    if (participantIdentity !== user.id) {
      return new Response(JSON.stringify({ error: 'Participant mismatch' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const userLimited = await assertRateLimit(
      'livekit_token_user',
      user.id,
      TOKEN_RATE_MAX,
      TOKEN_RATE_WINDOW_SEC,
    )
    if (userLimited != null) return userLimited

    const channelLimited = await assertRateLimit(
      'livekit_token_channel',
      channelId,
      CHANNEL_RATE_MAX,
      CHANNEL_RATE_WINDOW_SEC,
    )
    if (channelLimited != null) return channelLimited

    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
        Deno.env.get('SUPABASE_ANON_KEY') ??
        '',
    )

    const { data: channel, error: channelError } = await admin
      .from('channels')
      .select('id, world_id, name, channel_type')
      .eq('id', channelId)
      .maybeSingle()
    if (channelError || !channel || channel.world_id !== worldId) {
      return new Response(JSON.stringify({ error: 'Voice channel not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      })
    }
    if (channel.channel_type !== 'voice') {
      return new Response(JSON.stringify({ error: 'Not a voice channel' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { data: world } = await admin
      .from('worlds')
      .select('id, prestige, sovereign_id')
      .eq('id', worldId)
      .maybeSingle()
    if (!world || Number(world.prestige ?? 0) < 25) {
      return new Response(JSON.stringify({ error: 'Audio rooms locked' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { data: membership } = await admin
      .from('world_members')
      .select('rep')
      .eq('world_id', worldId)
      .eq('resident_id', user.id)
      .maybeSingle()
    const isSovereign = world.sovereign_id === user.id
    const hasVeteranStanding = Number(membership?.rep ?? 0) >= 200
    if (!isSovereign && !hasVeteranStanding) {
      return new Response(JSON.stringify({ error: 'Veteran standing required' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const apiKey = Deno.env.get('LIVEKIT_API_KEY')
    const apiSecret = Deno.env.get('LIVEKIT_API_SECRET')
    const livekitUrl = Deno.env.get('LIVEKIT_URL')

    if (!apiKey || !apiSecret || !livekitUrl) {
      return new Response(
        JSON.stringify({ error: 'LiveKit not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const token = new AccessToken(apiKey, apiSecret, {
      identity: participantIdentity,
      name: user.user_metadata?.name ?? participantIdentity,
    })

    token.addGrant({
      roomJoin: true,
      room: `campfire_${channelId}`,
      canPublish: true,
      canSubscribe: true,
    })

    return new Response(JSON.stringify({ token: token.toJwt(), livekitUrl }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
