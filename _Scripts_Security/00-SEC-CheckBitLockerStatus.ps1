# Check BitLocker Status
# Single use case: report encryption state of all fixed volumes
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

if (-not (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue)) {
    Write-Log "BitLocker cmdlets not available (feature not installed on this server)."
    return
}

$volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue
if (-not $volumes) { Write-Log "No BitLocker volumes found."; return }

$unencrypted = 0
Write-Log "================ BitLocker Volumes ================"
foreach ($v in $volumes) {
    $line = "[$($v.MountPoint)] Status: $($v.VolumeStatus) Protection: $($v.ProtectionStatus) ($($v.EncryptionPercentage)% encrypted)"
    if ($v.ProtectionStatus -eq "On") {
        $protectors = ($v.KeyProtector | ForEach-Object { $_.KeyProtectorType }) -join ", "
        Write-Log "OK: $line - protectors: $protectors"
    } else {
        Write-Log "UNPROTECTED: $line"
        $unencrypted++
    }
}

if ($unencrypted -eq 0) {
    Write-Log "BitLocker check complete: all volumes protected."
} else {
    Write-Log "BitLocker check complete: $unencrypted volume(s) without active protection."
}
