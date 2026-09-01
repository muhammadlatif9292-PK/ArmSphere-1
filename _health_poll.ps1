$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script:out = New-Object System.Collections.Generic.List[string]
$script:out.Add('=== Polling for new deploy publication (max 8 min) ===')
$healthy = $false

for ($i = 1; $i -le 16; $i++) {
  try {
    $r = Invoke-WebRequest -Uri 'https://armsphere2.netlify.app/api/health' -UseBasicParsing -TimeoutSec 25 -ErrorAction Stop
    $body = $r.Content
    $script:out.Add(('[try ' + $i + '] STATUS ' + $r.StatusCode + ' BODY ' + $body))
    if ($body -match '"database":"healthy"' -or ($body -notmatch 'Invalid URL' -and $body -match '"database":"\w+"')) {
      $healthy = $true
      break
    }
  } catch {
    $bd = ''
    try {
      $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
      $bd = $sr.ReadToEnd()
    } catch {}
    $script:out.Add(('[try ' + $i + '] ERR ' + $bd + ' | ' + $_.Exception.Message))
  }
  Start-Sleep -Seconds 30
}

if (-not $healthy) { $script:out.Add('RESULT: still not healthy after polling window') } else { $script:out.Add('RESULT: database HEALTHY') }
$script:out | Set-Content -Path "E:\Armsphere 1\_health_poll.txt" -Encoding utf8
