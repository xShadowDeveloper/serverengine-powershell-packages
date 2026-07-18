# Audit Failed Logons
# Single use case: summarize failed logon attempts (event 4625) of the last N hours
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$LookbackHours = 24
$WarnThreshold = 20   # warn when one account/source exceeds this many failures

$since = (Get-Date).AddHours(-[int]$LookbackHours)
$events = Get-WinEvent -FilterHashtable @{ LogName = "Security"; Id = 4625; StartTime = $since } -ErrorAction SilentlyContinue

if (-not $events) {
    Write-Log "No failed logons (4625) in the last $LookbackHours hours."
    return
}

Write-Log "Failed logons in the last ${LookbackHours}h: $(@($events).Count)"

$parsed = foreach ($e in $events) {
    $xml = [xml]$e.ToXml()
    $data = @{}
    foreach ($d in $xml.Event.EventData.Data) { $data[$d.Name] = $d.'#text' }
    [pscustomobject]@{
        Account = "$($data['TargetDomainName'])\$($data['TargetUserName'])"
        Source  = if ($data['IpAddress'] -and $data['IpAddress'] -ne "-") { $data['IpAddress'] } else { $data['WorkstationName'] }
    }
}

Write-Log "================ By Account (top 10) ================"
$parsed | Group-Object Account | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    $flag = if ($_.Count -ge [int]$WarnThreshold) { "WARNING: " } else { "" }
    Write-Log "$flag x$($_.Count.ToString().PadLeft(5))  $($_.Name)"
}

Write-Log "================ By Source (top 10) ================"
$parsed | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    $flag = if ($_.Count -ge [int]$WarnThreshold) { "WARNING: " } else { "" }
    Write-Log "$flag x$($_.Count.ToString().PadLeft(5))  $($_.Name)"
}

Write-Log "Failed logon audit complete. Sources above $WarnThreshold attempts may indicate brute force."
