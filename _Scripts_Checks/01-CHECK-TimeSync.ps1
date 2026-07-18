# Check Time Synchronization
# Single use case: report NTP source and clock offset of the server
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$WarnOffsetSeconds = 5

$svc = Get-Service -Name W32Time -ErrorAction SilentlyContinue
if ($null -eq $svc) { Write-Log "W32Time service not found!"; return }
Write-Log "W32Time service: $($svc.Status)"

$status = w32tm /query /status 2>&1
$source = ($status | Select-String "^Source:").ToString() -replace "^Source:\s*", ""
$stratumLine = ($status | Select-String "^Stratum:").ToString() -replace "^Stratum:\s*", ""
if ($source)      { Write-Log "Time source: $source" }
if ($stratumLine) { Write-Log "Stratum: $stratumLine" }

# Measure offset against the configured peer
$strip = w32tm /stripchart /computer:$source /samples:1 /dataonly 2>&1 | Select-Object -Last 1
if ($strip -match "([-+]\d+\.\d+)s") {
    $offset = [math]::Abs([double]$Matches[1])
    Write-Log "Clock offset: $offset seconds"
    if ($offset -gt [double]$WarnOffsetSeconds) {
        Write-Log "WARNING: clock offset exceeds $WarnOffsetSeconds seconds - resync recommended (see 00-HEAL-ResyncTime.ps1)."
    } else {
        Write-Log "Time synchronization is healthy."
    }
} else {
    Write-Log "Could not measure offset (source '$source' not reachable) - check NTP configuration."
}
