# Hyper-V Power OFF VM
# Single use case: gracefully shut down one VM (guest OS shutdown, no hard kill)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$VMName         = "MyVM"
$TimeoutSeconds = 120
$ForceAfterTimeout = $false   # $true = hard power-off if the guest ignores shutdown

if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    Write-Log "Hyper-V module not available - is the Hyper-V role installed on this host?"
    return
}

$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if ($null -eq $vm) { Write-Log "VM not found: $VMName"; return }

if ($vm.State -eq "Off") {
    Write-Log "VM $VMName is already off - nothing to do."
    return
}

Write-Log "Sending guest shutdown to VM $VMName (timeout ${TimeoutSeconds}s)..."
Stop-VM -Name $VMName -Force:$false -ErrorAction SilentlyContinue

$waited = 0
while ($waited -lt [int]$TimeoutSeconds) {
    Start-Sleep 5
    $waited += 5
    $vm = Get-VM -Name $VMName
    if ($vm.State -eq "Off") { break }
}

if ($vm.State -eq "Off") {
    Write-Log "VM $VMName shut down gracefully after ${waited}s."
} elseif ($ForceAfterTimeout) {
    Write-Log "Guest did not shut down within ${TimeoutSeconds}s - forcing power off..."
    Stop-VM -Name $VMName -TurnOff -Force -ErrorAction SilentlyContinue
    Start-Sleep 5
    $vm = Get-VM -Name $VMName
    Write-Log "VM $VMName state after force: $($vm.State)"
} else {
    Write-Log "WARNING: VM $VMName still $($vm.State) after ${TimeoutSeconds}s (integration services missing or guest busy). Not forcing."
}
