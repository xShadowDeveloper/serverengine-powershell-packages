# VMware VM Inventory
# Single use case: list all VMs on the vCenter/ESXi host with state and resources
# Credentials come from the ServerEngine store: SE-CredentialsStore.Username.(FQDN)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# Connection settings
$server = "esxi.CForce-IT.network"

# PowerCLI configuration
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Confirm:$false

# Retrieve credentials and convert password to SecureString
$username = SE-CredentialsStore.Username.(esxi.CForce-IT.network)
$password = SE-CredentialsStore.Password.(esxi.CForce-IT.network)
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

# Connect to vCenter/ESXi using credential object
Connect-VIServer -Server $server -Credential $credential

$vms = Get-VM | Sort-Object PowerState, Name
if (-not $vms) {
    Write-Log "No VMs found on $server."
    Disconnect-VIServer -Server $server -Confirm:$false
    return
}

Write-Log "================== VMware VMs ($(@($vms).Count)) =================="
foreach ($vm in $vms) {
    $memGB  = [math]::Round($vm.MemoryGB, 1)
    $usedGB = [math]::Round($vm.UsedSpaceGB, 0)
    $provGB = [math]::Round($vm.ProvisionedSpaceGB, 0)
    $guest  = if ($vm.Guest.OSFullName) { $vm.Guest.OSFullName } else { $vm.GuestId }
    $ip     = if ($vm.Guest.IPAddress) { ($vm.Guest.IPAddress | Where-Object { $_ -match "^\d" } | Select-Object -First 1) } else { "-" }
    Write-Log "[$($vm.PowerState.ToString().PadRight(10))] vCPU: $($vm.NumCpu.ToString().PadLeft(2)) RAM: $($memGB.ToString().PadLeft(5)) GB Disk: $($usedGB.ToString().PadLeft(5))/$($provGB.ToString().PadLeft(5)) GB IP: $($ip.PadRight(15)) $($vm.Name) ($guest)"
}

$on = @($vms | Where-Object { $_.PowerState -eq "PoweredOn" }).Count
Write-Log "Inventory complete: $on of $(@($vms).Count) VM(s) powered on."

# Disconnect
Disconnect-VIServer -Server $server -Confirm:$false

# Pass VM names to the next runbook script
$store = (($vms | ForEach-Object { $_.Name }) -join ",")
