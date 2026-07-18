# Hyper-V Remove Old Checkpoints
# Single use case: delete checkpoints older than N days (all VMs)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$OlderThanDays = 14

if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    Write-Log "Hyper-V module not available - is the Hyper-V role installed on this host?"
    return
}

$cutoff = (Get-Date).AddDays(-[int]$OlderThanDays)
$snaps = Get-VMSnapshot -VMName * -ErrorAction SilentlyContinue | Where-Object { $_.CreationTime -lt $cutoff }

if (-not $snaps) {
    Write-Log "No checkpoints older than $OlderThanDays days found - nothing to do."
    return
}

Write-Log "Removing $(@($snaps).Count) checkpoint(s) older than $($cutoff.ToString('yyyy-MM-dd'))..."
$removed = 0
foreach ($s in $snaps) {
    Write-Log "Removing: [$($s.VMName)] '$($s.Name)' from $($s.CreationTime.ToString('yyyy-MM-dd'))..."
    Remove-VMSnapshot -VMName $s.VMName -Name $s.Name -ErrorAction SilentlyContinue
    $removed++
}

Write-Log "Waiting for disk merges to settle..."
Start-Sleep 5
$merging = Get-VM | Where-Object { $_.Status -match "Merge" }
if ($merging) {
    Write-Log "Note: $(@($merging).Count) VM(s) still merging disks in the background - IO load until finished."
}

Write-Log "Checkpoint cleanup complete: $removed checkpoint(s) removed."
