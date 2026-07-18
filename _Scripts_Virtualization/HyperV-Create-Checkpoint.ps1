# Hyper-V Create Checkpoint
# Single use case: create a named checkpoint for one VM (pre-change safety)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$VMName         = "MyVM"
$CheckpointName = "ServerEngine-PreChange"

if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    Write-Log "Hyper-V module not available - is the Hyper-V role installed on this host?"
    return
}

$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if ($null -eq $vm) { Write-Log "VM not found: $VMName"; return }

$stamp = Get-Date -Format "yyyyMMdd-HHmm"
$name = "$CheckpointName-$stamp"

Write-Log "Creating checkpoint '$name' for VM $VMName..."
Checkpoint-VM -Name $VMName -SnapshotName $name -ErrorAction SilentlyContinue

$snap = Get-VMSnapshot -VMName $VMName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $name }
if ($snap) {
    Write-Log "Checkpoint created: $name ($($snap.CreationTime))"
    $total = @(Get-VMSnapshot -VMName $VMName).Count
    Write-Log "VM $VMName now has $total checkpoint(s). Old ones cost disk + IO - clean up with HyperV-Remove-OldCheckpoints.ps1."
} else {
    Write-Log "WARNING: checkpoint was not created!"
}
