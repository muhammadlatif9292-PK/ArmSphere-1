$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script:out = New-Object System.Collections.Generic.List[string]

# --- Health check ---
try {
  $r = Invoke-WebRequest -Uri 'https://armsphere2.netlify.app/api/health' -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
  $script:out.Add('HEALTH STATUS: ' + $r.StatusCode)
  $script:out.Add('HEALTH BODY: ' + $r.Content)
} catch {
  $bd = ''
  try {
    $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
    $bd = $sr.ReadToEnd()
  } catch {}
  $script:out.Add('HEALTH ERR: ' + $bd + ' | ' + $_.Exception.Message)
}

$script:out | Set-Content -Path "E:\Armsphere 1\_health_check.txt" -Encoding utf8
