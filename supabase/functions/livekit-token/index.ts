import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { AccessToken } from 'https://esm.sh/livekit-server-sdk@2'

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    const { roomName, participantIdentity } = await req.json()

    if (!roomName || !participantIdentity) {
      return new Response(
        JSON.stringify({ error: 'roomName and participantIdentity required' }),
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
      room: roomName,
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
