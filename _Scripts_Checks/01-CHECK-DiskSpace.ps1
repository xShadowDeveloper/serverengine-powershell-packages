# Check Disk Space
# Single use case: report free space on all fixed volumes, warn below threshold
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$WarnPercentFree = 15

$volumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
if (-not $volumes) {
    Write-Log "No fixed volumes found!"
    return
}

$warnings = 0
Write-Log "================ Disk Space ================"
foreach ($v in $volumes) {
    if ($v.Size -eq 0) { continue }
    $freeGB  = [math]::Round($v.FreeSpace / 1GB, 1)
    $sizeGB  = [math]::Round($v.Size / 1GB, 1)
    $freePct = [math]::Round(($v.FreeSpace / $v.Size) * 100, 1)

    if ($freePct -lt [double]$WarnPercentFree) {
        Write-Log "WARNING: [$($v.DeviceID)] $freeGB GB free of $sizeGB GB ($freePct% - below $WarnPercentFree%)"
        $warnings++
    } else {
        Write-Log "OK: [$($v.DeviceID)] $freeGB GB free of $sizeGB GB ($freePct%)"
    }
}

if ($warnings -gt 0) {
    Write-Log "Disk space check complete: $warnings volume(s) below threshold!"
} else {
    Write-Log "Disk space check complete: all volumes healthy."
}
