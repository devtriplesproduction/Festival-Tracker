# Sets up Google Drive OAuth for Festival Tracker Cloud Functions.
# Prerequisites: Firebase CLI logged in, Node.js, OAuth Web client created in GCP.
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\setup_drive_oauth.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$FunctionsDir = Join-Path $Root "functions"
$EnvFile = Join-Path $FunctionsDir ".env"

Write-Host ""
Write-Host "=== Festival Tracker · Drive OAuth setup ===" -ForegroundColor Cyan
Write-Host "Project: posterflow-6c0cb"
Write-Host "Redirect URI (must match Google Cloud OAuth client exactly):"
Write-Host "  https://us-central1-posterflow-6c0cb.cloudfunctions.net/oauth2callback" -ForegroundColor Yellow
Write-Host ""

$clientId = Read-Host "Paste OAuth Client ID"
$clientSecret = Read-Host "Paste OAuth Client Secret"

if ([string]::IsNullOrWhiteSpace($clientId) -or [string]::IsNullOrWhiteSpace($clientSecret)) {
  Write-Host "Client ID and Secret are required." -ForegroundColor Red
  exit 1
}

$redirect = "https://us-central1-posterflow-6c0cb.cloudfunctions.net/oauth2callback"

@"
DRIVE_CLIENT_ID=$clientId
DRIVE_CLIENT_SECRET=$clientSecret
DRIVE_REDIRECT_URI=$redirect
"@ | Set-Content -Path $EnvFile -Encoding UTF8

Write-Host "Wrote $EnvFile" -ForegroundColor Green

# Also set legacy config (harmless if unused)
try {
  Push-Location $Root
  firebase use posterflow-6c0cb | Out-Null
  firebase functions:config:set `
    "drive.client_id=$clientId" `
    "drive.client_secret=$clientSecret" `
    "drive.redirect_uri=$redirect"
} catch {
  Write-Host "Note: functions:config:set skipped or failed (OK if using .env only): $_" -ForegroundColor DarkYellow
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "Deploying Cloud Functions..." -ForegroundColor Cyan
Push-Location $FunctionsDir
npm install
Pop-Location

Push-Location $Root
firebase deploy --only functions
Pop-Location

Write-Host ""
Write-Host "Done. Next:" -ForegroundColor Green
Write-Host "  1. Confirm OAuth client has redirect URI above"
Write-Host "  2. Enable Drive API + Secret Manager API in GCP"
Write-Host "  3. Grant Functions SA Secret Manager Admin + Accessor"
Write-Host "  4. App: Admin login → Account → Connect Google Drive"
Write-Host "  5. Health check:"
Write-Host "     https://us-central1-posterflow-6c0cb.cloudfunctions.net/driveHealth"
Write-Host ""
