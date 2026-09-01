# Severity breakdown of flutter analyze output (bullet built via [char] to avoid encoding issues)
$logPath = "_p8_logs\job_log.txt"
$bullet = [string][char]0x2022

$lines = [System.IO.File]::ReadAllLines($logPath, [System.Text.Encoding]::UTF8)

$errorLines = New-Object System.Collections.Generic.List[string]
$warnCount = 0
$infoCount = 0
$errCount = 0
$otherCount = 0

foreach ($line in $lines) {
  if ($line.Contains(" error $bullet ")) {
    $errCount++
    $errorLines.Add($line)
  } elseif ($line.Contains(" warning $bullet ")) {
    $warnCount++
  } elseif ($line.Contains(" info $bullet ")) {
    $infoCount++
  } elseif ($line.Contains("$bullet") -and $line -match '\.dart:\d+') {
    $otherCount++
    $errorLines.Add("OTHER: $line")
  }
}

$report = New-Object System.Collections.Generic.List[string]
$report.Add("error-severity: $errCount")
$report.Add("warning-severity: $warnCount")
$report.Add("info-severity: $infoCount")
$report.Add("other-dart-bullet-lines: $otherCount")
$report.Add("")
if ($errorLines.Count -gt 0) {
  $report.Add("=== NON-INFO/WARNING LINES (first 60) ===")
  $errorLines | Select-Object -First 60 | ForEach-Object { $report.Add($_) }
}
[System.IO.File]::WriteAllLines("_p8_logs\severity.txt", $report)
Write-Output "DONE"
