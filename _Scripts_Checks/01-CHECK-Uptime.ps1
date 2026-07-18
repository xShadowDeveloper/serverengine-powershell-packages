# Check System Uptime
# Single use case: report time since last boot, warn above threshold
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$WarnUptimeDays = 45

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$days = [math]::Round($uptime.TotalDays, 1)

Write-Log "Last boot: $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm'))"
Write-Log "Uptime: $days days ($($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m)"

if ($days -gt [double]$WarnUptimeDays) {
    Write-Log "WARNING: uptime exceeds $WarnUptimeDays days - consider a maintenance reboot (pending updates may be waiting)."
} else {
    Write-Log "Uptime is within the $WarnUptimeDays day threshold."
}
