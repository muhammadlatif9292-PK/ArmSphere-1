# Polls GitHub check-runs for the phase 11 commit; writes results to _p9_ci_status.txt
$outFile = "E:\Armsphere 1\_p9_ci_status.txt"
$sha = "ba04ee0"

try {
  $fillOut = "protocol=https`nhost=github.com`n" | git credential fill
  $token = $null
  foreach ($line in $fillOut) {
    if ($line -like 'password=*') { $token = $line.Substring('password='.Length); break }
  }
  if (-not $token) { Set-Content -Path $outFile -Value "ERROR: no token"; exit 1 }

  $headers = @{
    Authorization = "Bearer $token"
    Accept        = 'application/vnd.github+json'
    'User-Agent'  = 'armsphere-ci-diag'
  }

  $resp = Invoke-RestMethod -Uri "https://api.github.com/repos/muhammadlatif9292-PK/ArmSphere-1/commits/$sha/check-runs" -Headers $headers
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("total_count: $($resp.total_count)")
  foreach ($run in $resp.check_runs) {
    $lines.Add("$($run.name) | status=$($run.status) | conclusion=$($run.conclusion)")
  }
  Set-Content -Path $outFile -Value ($lines -join "`r`n")
  Write-Output "DONE"
} catch {
  Set-Content -Path $outFile -Value "FATAL: $($_.Exception.Message)"
  exit 1
}
