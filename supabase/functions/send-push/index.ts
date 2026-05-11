// Supabase Database Webhook handler for notifications
// Triggered on INSERT into the 'notifications' table
// Delivers push via Supabase Realtime channels (the web/app client subscribes)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req: Request) => {
  try {
    const payload = await req.json()
    const record = payload.record

    if (!record || !record.recipient_id) {
      return new Response(JSON.stringify({ skipped: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Log for audit — the real delivery happens via Supabase Realtime
    // which the Flutter client subscribes to in notification_provider.dart
    console.log(
      `[push] type=${record.type} recipient=${record.recipient_id} message=${record.message}`,
    )

    return new Response(JSON.stringify({ delivered: true }), {
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
