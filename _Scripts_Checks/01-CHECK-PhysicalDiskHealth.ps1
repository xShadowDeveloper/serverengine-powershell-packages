# Check Physical Disk Health
# Single use case: report health status of all physical disks (SMART summary)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
if (-not $disks) {
    Write-Log "Get-PhysicalDisk returned nothing (no storage subsystem access?)."
    return
}

$unhealthy = 0
Write-Log "================ Physical Disks ================"
foreach ($d in $disks) {
    $sizeGB = [math]::Round($d.Size / 1GB, 0)
    $line = "[$($d.DeviceId)] $($d.FriendlyName) ($($d.MediaType), $sizeGB GB) Health: $($d.HealthStatus) Status: $($d.OperationalStatus)"
    if ($d.HealthStatus -ne "Healthy") {
        Write-Log "WARNING: $line"
        $unhealthy++
    } else {
        Write-Log "OK: $line"
    }
}

# Wear + temperature where the hardware exposes it
foreach ($d in $disks) {
    $rel = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
    if ($rel -and ($rel.Wear -or $rel.Temperature)) {
        Write-Log "[$($d.DeviceId)] Wear: $($rel.Wear)% Temperature: $($rel.Temperature)C ReadErrors: $($rel.ReadErrorsTotal)"
    }
}

if ($unhealthy -eq 0) {
    Write-Log "Disk health check complete: all $(@($disks).Count) disk(s) healthy."
} else {
    Write-Log "Disk health check complete: $unhealthy disk(s) NOT healthy - check hardware!"
}
