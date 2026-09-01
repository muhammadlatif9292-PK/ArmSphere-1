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
    if ($stream) {
      $sr = New-Object IO.StreamReader($stream)
      $raw = $sr.ReadToEnd()
      if ($raw.Length -gt 400) { $body = $raw.Substring(0, 400) } else { $body = $raw }
    }
  } catch {}
  return "status=$code body=$body"
}

Log "=== STEP4/5 retry via /api prefix $(Get-Date -Format o) ==="

$email = 'e2e-supabase-1787634253@armsphere-test.com'
$password = 'Str0ngPass!42'
$loginBody = @{ email = $email; password = $password } | ConvertTo-Json

try {
  $login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body $loginBody -ErrorAction Stop
  $token = $login.data.accessToken
  Log "LOGIN OK isOnboardedBeforeProfile=$($login.data.user.isOnboarded)"
  $headers = @{ Authorization = "Bearer $token" }
} catch {
  Log "LOGIN FAIL $(ErrDetail $_)"
  $script:out | Set-Content -Path "_e2e_step4.txt" -Encoding utf8
  exit 0
}

$profBody = @{
  displayName = 'E2E Athlete'
  biography   = 'Professional Athlete'
  province    = 'Punjab'
  city        = 'Lahore'
  handedness  = 'RIGHT'
  dominantArm = 'RIGHT'
  dateOfBirth = '2000-01-01T00:00:00.000Z'
  gender      = 'MALE'
  weightClass = '75kg'
  height      = 175.0
  weight      = 75.0
  reach       = 175.0
} | ConvertTo-Json

try {
  $prof = Invoke-RestMethod -Method Post -Uri "$base/api/v1/athletes" -Headers $headers -ContentType 'application/json' -Body $profBody -ErrorAction Stop
  Log "STEP4 ATHLETE PROFILE (POST /api/v1/athletes): OK id=$($prof.data.id) displayName=$($prof.data.displayName)"
} catch {
  Log "STEP4 ATHLETE PROFILE: FAIL $(ErrDetail $_)"
}

try {
  $again = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body $loginBody -ErrorAction Stop
  Log "STEP5 RELOGIN: OK isOnboardedAfterProfile=$($again.data.user.isOnboarded)"
} catch {
  Log "STEP5 RELOGIN: FAIL $(ErrDetail $_)"
}

Log "=== END ==="
$script:out | Set-Content -Path "E:\Armsphere 1\_e2e_step4.txt" -Encoding utf8
