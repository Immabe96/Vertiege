# Test notification push fanout end-to-end.
#
# Prerequisites: deploy-notification-webhook.ps1 completed.
#                App running on device with valid device_tokens row.
#
# Usage:
#   .\scripts\test-notification-fanout.ps1

$ErrorActionPreference = "Continue"

$SupabaseRef = "wjaphoaxalvgjnrwqjwe"
$SupabaseUrl = "https://$SupabaseRef.supabase.co"

Write-Host "=== Notification Fanout Test ===" -ForegroundColor Cyan

# ── 1. Check device_tokens ─────────────────────────────────────
Write-Host "`n1. Checking device_tokens table..." -ForegroundColor Yellow
Write-Host "   Run this SQL in the Supabase Dashboard SQL Editor:"
Write-Host @"
   SELECT * FROM public.device_tokens ORDER BY updated_at DESC LIMIT 5;
"@ -ForegroundColor Gray
Write-Host "   Expected: At least one row with your resident_id and a valid FCM token."
Write-Host "   If empty: Open the app on device and log in. The app registers its token on startup."

# ── 2. Insert test notification ────────────────────────────────
Write-Host "`n2. Insert test notification..." -ForegroundColor Yellow
Write-Host "   Run this SQL in the Supabase Dashboard SQL Editor (replace RESIDENT_ID with yours):"
Write-Host @"
   INSERT INTO public.notifications (recipient_id, type, message, read)
   VALUES (
     '<YOUR_RESIDENT_ID>',
     'welcome',
     'Test push notification from Vertiege',
     false
   )
   RETURNING *;
"@ -ForegroundColor Gray

# ── 3. Check Edge Function logs ────────────────────────────────
Write-Host "`n3. Check Edge Function logs..." -ForegroundColor Yellow
Write-Host "   Run this in PowerShell:"
Write-Host @"
   npx supabase functions logs send-push --project-ref $SupabaseRef
"@ -ForegroundColor Gray

# ── 4. Verify on device ────────────────────────────────────────
Write-Host "`n4. Verify on device:" -ForegroundColor Yellow
Write-Host "   - Push notification should appear with title 'Vertiege' and message 'Test push notification from Vertiege'"
Write-Host "   - Tapping the notification should open the app"
Write-Host "   - It should navigate to /notifications/<id>"

# ── 5. Route verification ──────────────────────────────────────
Write-Host "`n5. Route verification:" -ForegroundColor Yellow
Write-Host "   - Like notification → taps to /post/<id>"
Write-Host "   - Comment notification → taps to /post/<id>"
Write-Host "   - World unlocked → taps to /explore/<worldId>"
Write-Host "   - Default → taps to /notifications/<id>"

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
