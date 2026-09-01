# Downloads CI job logs using locally stored git credentials (token never printed)
$outDir = "E:\Armsphere 1\_p8_logs"
$report = New-Object System.Collections.Generic.List[string]

function Save-Report {
  Set-Content -Path "$outDir\result.txt" -Value ($report -join "`r`n")
}

try {
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  $report.Add("step: dir ready")

  $fillOut = "protocol=https`nhost=github.com`n" | git credential fill
  $report.Add("step: credential fill done")
  $tokenLine = $null
  foreach ($line in $fillOut) {
    if ($line -like 'password=*') { $tokenLine = $line; break }
  }
  if (-not $tokenLine) {
    $report.Add("ERROR: no token found in credential output")
    Save-Report
    exit 1
  }
  $token = $tokenLine.Substring('password='.Length)
  $report.Add("step: token extracted")

  $headers = @{
    Authorization = "Bearer $token"
    Accept        = 'application/vnd.github+json'
    'User-Agent'  = 'armsphere-ci-diag'
  }

  $url = "https://api.github.com/repos/muhammadlatif9292-PK/ArmSphere-1/actions/jobs/97807889898/logs"
  $zipPath = "$outDir\logs.zip"

  Add-Type -AssemblyName System.Net.Http
  $client = New-Object System.Net.Http.HttpClient
  $client.Timeout = [TimeSpan]::FromMinutes(5)
  foreach ($k in $headers.Keys) { $client.DefaultRequestHeaders.TryAddWithoutValidation($k, [string]$headers[$k]) | Out-Null }

  $resp = $client.GetAsync($url).GetAwaiter().GetResult()
  $report.Add("step: http status $($resp.StatusCode)")
  if (-not $resp.IsSuccessStatusCode) {
    $report.Add("ERROR: body $($resp.Content.ReadAsStringAsync().GetAwaiter().GetResult().Substring(0, 300))")
    Save-Report
    exit 1
  }
  # Follow redirect manually to avoid leaking auth headers
  if ([int]$resp.StatusCode -eq 302 -or [int]$resp.StatusCode -eq 301) {
    $blobUrl = $resp.Headers.Location.AbsoluteUri
    $report.Add("step: redirect to blob")
    $resp2 = $client.GetAsync($blobUrl).GetAwaiter().GetResult()
    $report.Add("step: blob status $($resp2.StatusCode)")
    $bytes = $resp2.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
  } else {
    $bytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
  }
  [System.IO.File]::WriteAllBytes($zipPath, $bytes)
  $report.Add("step: zip downloaded ($($bytes.Length) bytes)")

  if (Test-Path "$outDir\extracted") { Remove-Item -Recurse -Force "$outDir\extracted" }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, "$outDir\extracted")
  $report.Add("step: extracted")

  $logFiles = Get-ChildItem -Path "$outDir\extracted" -Filter "*.txt" -Recurse
  $report.Add("JOB LOG FILES:")
  foreach ($f in $logFiles) { $report.Add("  $($f.Name)") }

  $analyzeFile = $logFiles | Where-Object { $_.Name -like '*analyze*' -or $_.Name -like '*Flutter*' } | Select-Object -First 1
  if ($analyzeFile) {
    $report.Add("")
    $report.Add("=== ANALYZE STEP: lines containing 'error' ===")
    Get-Content $analyzeFile.FullName | Select-String -Pattern 'error' | ForEach-Object { $report.Add($_.Line) }
    $report.Add("")
    $report.Add("=== ANALYZE STEP: last 40 lines ===")
    Get-Content $analyzeFile.FullName -Tail 40 | ForEach-Object { $report.Add($_) }
  } else {
    # Fallback: dump every file's matching lines
    foreach ($f in $logFiles) {
      $report.Add("")
      $report.Add("=== $($f.Name): lines containing 'error •' ===")
      Get-Content $f.FullName | Select-String -Pattern 'error' | Select-Object -First 50 | ForEach-Object { $report.Add($_.Line) }
    }
  }
  Save-Report
  Write-Output "DONE"
} catch {
  $report.Add("FATAL: $($_.Exception.ToString())")
  Save-Report
  exit 1
}
