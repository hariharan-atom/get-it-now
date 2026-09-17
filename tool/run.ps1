param(
  [string]$Device = 'chrome',
  [switch]$Demo
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$flutterArgs = @('run', '-d', $Device)
if ($Device -eq 'chrome' -or $Device -eq 'web-server') {
  $flutterArgs += '--web-port=8081'
}
if ($Demo) {
  $flutterArgs += '--dart-define=DEMO_MODE=true'
}
if (-not $Demo) {
  $configPath = Join-Path $projectRoot 'config/supabase.json'
  if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Copy config/supabase.example.json to config/supabase.json and fill in your project URL and publishable key. See docs/SUPABASE_SETUP.md.'
  }
  $config = Get-Content -Raw -Encoding utf8 -LiteralPath $configPath | ConvertFrom-Json
  $publicKey = $config.SUPABASE_PUBLISHABLE_KEY
  if (-not $publicKey) { $publicKey = $config.SUPABASE_ANON_KEY }
  if ($config.SUPABASE_URL -notmatch '^https://[^/]+\.supabase\.co/?$' -or $config.SUPABASE_URL -match 'YOUR_PROJECT' -or
      -not $publicKey -or $publicKey -match 'YOUR_|^sb_secret_') {
    throw 'Use your real project HTTPS URL and publishable/anon key. Secret and service-role keys must not be used in this app.'
  }
  if ($publicKey.StartsWith('eyJ')) {
    $parts = $publicKey.Split('.')
    if ($parts.Length -eq 3) {
      $payload = $parts[1].Replace('-', '+').Replace('_', '/')
      $payload = $payload.PadRight($payload.Length + (4 - $payload.Length % 4) % 4, '=')
      $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
      if ($claims.role -eq 'service_role') { throw 'A service-role key cannot be used in a mobile app. Use the anon or publishable key.' }
    }
  }
  $flutterArgs += '--dart-define-from-file=config/supabase.json'
}
& flutter @flutterArgs
exit $LASTEXITCODE
