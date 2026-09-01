$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$base = 'https://armsphere2.netlify.app'
$script:out = New-Object System.Collections.Generic.List[string]
function Log($m) { $script:out.Add($m) }
function ErrDetail($e) {
  $code = ''
  $body = ''
  try { $code = $e.Exception.Response.StatusCode.value__ } catch {}
  try {
    $stream = $e.Exception.Response.GetResponseStream()
    if ($stream) { $sr = New-Object IO.StreamReader($stream); $body = $sr.ReadToEnd() }
  } catch {}
  return "status=$code body=$body"
}

Log "=== ArmSphere E2E vs Supabase $(Get-Date -Format o) ==="

# ---- STEP 1: register a brand-new account ----
$stamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$email = "e2e-supabase-$stamp@armsphere-test.com"
$username = "e2es$($stamp.ToString().Substring(6))"
$password = 'Str0ngPass!42'
$regBody = @{ email = $email; username = $username; password = $password; fullName = 'E2E Supabase Verify' } | ConvertTo-Json
try {
  $reg = Invoke-RestMethod -Method Post -Uri "$base/auth/register" -ContentType 'application/json' -Body $regBody -ErrorAction Stop
  Log "STEP1 REGISTER: OK id=$($reg.data.id) role=$($reg.data.role)"
} catch {
  Log "STEP1 REGISTER: FAIL $(ErrDetail $_)"
  $script:out | Set-Content -Path "_e2e_result.txt" -Encoding utf8
  exit 0
}

# ---- STEP 2: login (tokens issued) ----
$loginBody = @{ email = $email; password = $password } | ConvertTo-Json
try {
  $login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body $loginBody -ErrorAction Stop
  $token = $login.data.accessToken
  if (-not $token) { throw "no accessToken in login response: $($login | ConvertTo-Json -Compress -Depth 4)" }
  Log "STEP2 LOGIN: OK accessTokenLength=$($token.Length) hasRefreshToken=$([bool]$login.data.refreshToken) isOnboarded=$($login.data.user.isOnboarded)"
  $headers = @{ Authorization = "Bearer $token" }
} catch {
  Log "STEP2 LOGIN: FAIL $(ErrDetail $_)"
  $script:out | Set-Content -Path "_e2e_result.txt" -Encoding utf8
  exit 0
}

# ---- STEP 3: authenticated /auth/me ----
try {
  $me = Invoke-RestMethod -Method Get -Uri "$base/auth/me" -Headers $headers -ErrorAction Stop
  Log "STEP3 ME: OK role=$($me.data.role) email=$($me.data.email)"
} catch {
  Log "STEP3 ME: FAIL $(ErrDetail $_)"
}

# ---- STEP 4: onboarding - POST /athletes with Bearer ----
$profBody = @{
  displayName  = 'E2E Athlete'
  biography    = 'Professional Athlete'
  province     = 'Punjab'
  city         = 'Lahore'
  handedness   = 'RIGHT'
  dominantArm  = 'RIGHT'
  dateOfBirth  = '2000-01-01T00:00:00.000Z'
  gender       = 'MALE'
  weightClass  = '75kg'
  height       = 175.0
  weight       = 75.0
  reach        = 175.0
} | ConvertTo-Json
try {
  $prof = Invoke-RestMethod -Method Post -Uri "$base/athletes" -Headers $headers -ContentType 'application/json' -Body $profBody -ErrorAction Stop
  Log "STEP4 ATHLETE PROFILE: OK id=$($prof.data.id) displayName=$($prof.data.displayName)"
} catch {
  Log "STEP4 ATHLETE PROFILE: FAIL $(ErrDetail $_)"
}

# ---- STEP 5: re-login confirms persistence + isOnboarded flips ----
try {
  $again = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body $loginBody -ErrorAction Stop
  Log "STEP5 RELOGIN: OK tokenIssued=$([bool]$again.data.accessToken) isOnboarded=$($again.data.user.isOnboarded)"
} catch {
  Log "STEP5 RELOGIN: FAIL $(ErrDetail $_)"
}

# ---- STEP 6: refresh rotation ----
try {
  $rfBody = @{ refreshToken = $login.data.refreshToken } | ConvertTo-Json
  $rf = Invoke-RestMethod -Method Post -Uri "$base/auth/refresh" -ContentType 'application/json' -Body $rfBody -ErrorAction Stop
  Log "STEP6 REFRESH: OK newAccessLen=$($rf.data.accessToken.Length) rotated=$([bool]$rf.data.refreshToken)"
} catch {
  Log "STEP6 REFRESH: FAIL $(ErrDetail $_)"
}

Log "=== END ==="
$script:out | Set-Content -Path "_e2e_result.txt" -Encoding utf8
