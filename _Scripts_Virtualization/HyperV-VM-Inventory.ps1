# Hyper-V VM Inventory
# Single use case: list all VMs on this host with state and resources
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    Write-Log "Hyper-V module not available - is the Hyper-V role installed on this host?"
    return
}

$vms = Get-VM -ErrorAction SilentlyContinue
if (-not $vms) { Write-Log "No VMs found on this host."; return }

Write-Log "================ Hyper-V VMs ($(@($vms).Count)) ================"
foreach ($vm in ($vms | Sort-Object State, Name)) {
    $memGB = [math]::Round($vm.MemoryAssigned / 1GB, 1)
    $up = if ($vm.State -eq "Running") { " uptime: $($vm.Uptime.Days)d $($vm.Uptime.Hours)h" } else { "" }
    Write-Log "[$($vm.State.ToString().PadRight(9))] vCPU: $($vm.ProcessorCount.ToString().PadLeft(2)) RAM: $($memGB.ToString().PadLeft(5)) GB $($vm.Name)$up"
}

$running = @($vms | Where-Object { $_.State -eq "Running" }).Count
Write-Log "Inventory complete: $running of $(@($vms).Count) VM(s) running."

# Pass VM names to the next runbook script
$store = (($vms | ForEach-Object { $_.Name }) -join ",")
