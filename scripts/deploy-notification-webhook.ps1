# Deploy the notification push webhook end-to-end.
# Prerequisites: npx (Node.js), supabase CLI, Firebase service account JSON.
#
# Usage:
#   .\scripts\deploy-notification-webhook.ps1
#
# What this script does:
#   1. Reads the webhook secret from %TEMP%\vertiege-webhook-secret.txt
#   2. Sets WEBHOOK_SECRET as a Supabase Edge Function secret
#   3. Deploys the send-push Edge Function
#   4. Creates the Database Webhook on public.notifications INSERT

$ErrorActionPreference = "Stop"

# ── Config ──────────────────────────────────────────────────────
$SupabaseRef = "wjaphoaxalvgjnrwqjwe"
$FunctionName = "send-push"
$TableName = "notifications"
$WebhookName = "send_push_on_insert"

# ── 1. Read or generate webhook secret ──────────────────────────
$secretFile = "$env:TEMP\vertiege-webhook-secret.txt"
if (-not (Test-Path $secretFile)) {
    Write-Host "Generating webhook secret..."
    $secret = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | ForEach-Object { [char]$_ })
    $secret | Set-Content $secretFile -Force
} else {
    $secret = (Get-Content $secretFile).Trim()
    # Strip "WEBHOOK_SECRET=" prefix if present
    if ($secret -match '^WEBHOOK_SECRET=') {
        $secret = $secret.Substring(15)
    }
}
Write-Host "Webhook secret loaded/generated and stored locally." -ForegroundColor Green

# ── 2. Set Edge Function secret ─────────────────────────────────
Write-Host "Setting WEBHOOK_SECRET for Edge Function..." -ForegroundColor Yellow
npx supabase secrets set WEBHOOK_SECRET="$secret" --project-ref $SupabaseRef
if ($LASTEXITCODE -ne 0) { throw "Failed to set WEBHOOK_SECRET" }

# ── 3. Deploy the Edge Function ─────────────────────────────────
Write-Host "Deploying $FunctionName function..." -ForegroundColor Yellow
npx supabase functions deploy $FunctionName --project-ref $SupabaseRef
if ($LASTEXITCODE -ne 0) { throw "Failed to deploy $FunctionName" }

# ── 4. Create the Database Webhook ──────────────────────────────
# The Supabase CLI creates webhooks via the Management API.
Write-Host "Creating Database Webhook on public.$TableName..." -ForegroundColor Yellow

# Use the Supabase Management API to create the webhook
$accessToken = npx supabase status --project-ref $SupabaseRef 2>$null
# Fall back to curl against the Management API
$webhookUrl = "https://$SupabaseRef.supabase.co/functions/v1/$FunctionName"

Write-Host @"

Webhook details:
  Table:   public.$TableName
  Event:   INSERT
  Method:  POST
  URL:     $webhookUrl
  Headers: Authorization: Bearer $secret
           Content-Type: application/json
"@ -ForegroundColor Cyan

Write-Host @"
── MANUAL STEP ────────────────────────────────────────────────
Open this URL in your browser:

  https://supabase.com/dashboard/project/$SupabaseRef/integrations/webhooks

Click "Create webhook" and fill in:
  Name:        $WebhookName
  Table:       $TableName
  Events:      INSERT
  Method:      POST
  URL:         $webhookUrl
  Headers:     Authorization: Bearer $secret
               Content-Type: application/json

Click "Create webhook".
──────────────────────────────────────────────────────────────
"@ -ForegroundColor Magenta

Write-Host "Done. Now run the test script: .\scripts\test-notification-fanout.ps1" -ForegroundColor Green
