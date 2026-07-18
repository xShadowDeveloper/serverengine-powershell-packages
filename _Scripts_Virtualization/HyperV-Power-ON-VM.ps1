# Hyper-V Power ON VM
# Single use case: start one VM and wait until it is running
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$VMName = "MyVM"

if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    Write-Log "Hyper-V module not available - is the Hyper-V role installed on this host?"
    return
}

$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if ($null -eq $vm) { Write-Log "VM not found: $VMName"; return }

if ($vm.State -eq "Running") {
    Write-Log "VM $VMName is already running - nothing to do."
    return
}

Write-Log "Starting VM $VMName (current state: $($vm.State))..."
Start-VM -Name $VMName -ErrorAction SilentlyContinue

$timeout = 60
while ($timeout -gt 0) {
    Start-Sleep 5
    $timeout -= 5
    $vm = Get-VM -Name $VMName
    if ($vm.State -eq "Running") { break }
}

if ($vm.State -eq "Running") {
    Write-Log "VM $VMName is running."
} else {
    Write-Log "WARNING: VM $VMName is in state $($vm.State) after start attempt!"
}
