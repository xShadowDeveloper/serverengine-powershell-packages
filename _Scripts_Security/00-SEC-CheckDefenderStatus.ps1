# Check Microsoft Defender Status
# Single use case: report AV engine, definitions and protection state
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$WarnDefinitionAgeDays = 3

$status = Get-MpComputerStatus -ErrorAction SilentlyContinue
if ($null -eq $status) {
    Write-Log "Microsoft Defender is not available on this host (3rd party AV or feature removed)."
    return
}

Write-Log "================ Defender Status ================"
Write-Log "Realtime protection: $($status.RealTimeProtectionEnabled)"
Write-Log "Antivirus enabled: $($status.AntivirusEnabled)"
Write-Log "Behavior monitoring: $($status.BehaviorMonitorEnabled)"
Write-Log "Tamper protection: $($status.IsTamperProtected)"
Write-Log "Engine version: $($status.AMEngineVersion)"
Write-Log "Definitions version: $($status.AntivirusSignatureVersion)"
Write-Log "Definitions updated: $($status.AntivirusSignatureLastUpdated)"
Write-Log "Last quick scan: $(if ($status.QuickScanEndTime) { $status.QuickScanEndTime } else { 'never' })"

$problems = 0
if (-not $status.RealTimeProtectionEnabled) { Write-Log "WARNING: realtime protection is OFF!"; $problems++ }
if (-not $status.AntivirusEnabled)          { Write-Log "WARNING: antivirus is DISABLED!"; $problems++ }

$sigAge = $status.AntivirusSignatureAge
if ($sigAge -gt [int]$WarnDefinitionAgeDays) {
    Write-Log "WARNING: definitions are $sigAge days old (threshold: $WarnDefinitionAgeDays)!"
    $problems++
}

if ($problems -eq 0) {
    Write-Log "Defender check complete: protection healthy."
} else {
    Write-Log "Defender check complete: $problems problem(s) found!"
}
