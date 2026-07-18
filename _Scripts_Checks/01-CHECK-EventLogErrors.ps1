# Check Event Log Errors
# Single use case: summarize System/Application errors of the last N hours
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$LookbackHours = 24

$since = (Get-Date).AddHours(-[int]$LookbackHours)
$total = 0

foreach ($logName in @("System", "Application")) {
    $events = Get-WinEvent -FilterHashtable @{ LogName = $logName; Level = 1,2; StartTime = $since } -ErrorAction SilentlyContinue
    $count = @($events).Count
    $total += $count
    Write-Log "================ $logName ($count errors in ${LookbackHours}h) ================"
    if ($count -eq 0) { continue }

    # group by source, worst offenders first
    $groups = $events | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 10
    foreach ($g in $groups) {
        $newest = ($g.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1)
        $msg = if ($newest.Message) { ($newest.Message -split "`n")[0].Trim() } else { "(no message)" }
        if ($msg.Length -gt 100) { $msg = $msg.Substring(0, 100) + "..." }
        Write-Log "x$($g.Count.ToString().PadLeft(4))  [$($g.Name)] last: $msg"
    }
}

if ($total -eq 0) {
    Write-Log "Event log check complete: no errors in the last $LookbackHours hours."
} else {
    Write-Log "Event log check complete: $total error(s) found in the last $LookbackHours hours."
}
