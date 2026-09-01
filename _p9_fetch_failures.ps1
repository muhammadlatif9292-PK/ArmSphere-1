# Downloads logs of FAILED CI jobs for the phase 10 commit into _p9_logs and extracts error lines
$outDir = "E:\Armsphere 1\_p9_logs"
$sha = "f0d9632"
$report = New-Object System.Collections.Generic.List[string]

function Save-Report { Set-Content -Path "$outDir\result.txt" -Value ($report -join "`r`n") }

try {
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  $fillOut = "protocol=https`nhost=github.com`n" | git credential fill
  $token = $null
  foreach ($line in $fillOut) {
    if ($line -like 'password=*') { $token = $line.Substring('password='.Length); break }
  }
  if (-not $token) { $report.Add("ERROR: no token"); Save-Report; exit 1 }

  $headers = @{
    Authorization = "Bearer $token"
    Accept        = 'application/vnd.github+json'
    'User-Agent'  = 'armsphere-ci-diag'
  }

  Add-Type -AssemblyName System.Net.Http
  $client = New-Object System.Net.Http.HttpClient
  $client.Timeout = [TimeSpan]::FromMinutes(5)
  foreach ($k in $headers.Keys) { $client.DefaultRequestHeaders.TryAddWithoutValidation($k, [string]$headers[$k]) | Out-Null }

  $resp = Invoke-RestMethod -Uri "https://api.github.com/repos/muhammadlatif9292-PK/ArmSphere-1/commits/$sha/check-runs" -Headers $headers
  foreach ($run in $resp.check_runs) {
    if ($run.conclusion -ne 'failure') { continue }
    $jobId = $run.id
    $report.Add("===== JOB $($run.name) (id=$jobId) =====")
    $url = "https://api.github.com/repos/muhammadlatif9292-PK/ArmSphere-1/actions/jobs/$jobId/logs"
    $httpResp = $client.GetAsync($url).GetAwaiter().GetResult()
    if (-not $httpResp.IsSuccessStatusCode) {
      $report.Add("log fetch status: $($httpResp.StatusCode)")
      continue
    }
    $bytes = $httpResp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    $safeName = ($run.name -replace '[^a-zA-Z0-9]+', '_')
    $path = Join-Path $outDir "$safeName.log"
    [System.IO.File]::WriteAllBytes($path, $bytes)
    $report.Add("saved: $path ($($bytes.Length) bytes)")

    # Extract error-ish lines
    $lines = Get-Content $path
    $errLines = $lines | Select-String -Pattern 'error TS|Error:|error|failed|FAIL' | Select-Object -First 60
    $report.Add("--- matched lines (first 60) ---")
    foreach ($m in $errLines) { $report.Add($m.Line) }
    $report.Add("")
  }
  Save-Report
  Write-Output "DONE"
} catch {
  $report.Add("FATAL: $($_.Exception.Message)")
  Save-Report
  exit 1
}
