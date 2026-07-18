# Set target VM name

$server = "esxi.CForce-IT.network"

Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Confirm:$false

$username = SE-CredentialsStore.Username.(esxi.CForce-IT.network)
$password = SE-CredentialsStore.Password.(esxi.CForce-IT.network)
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

Connect-VIServer -Server $server -Credential $credential

$vm = $targetVM = Get-VM | Where-Object { $_.Name -like "*$hostname*" }

if (-not $vm) {
    Write-Host "<WRITE-LOG = ""*ERROR: VM not found: $vmName*"">"
} elseif ($vm.PowerState -eq "PoweredOn") {
    Write-Host "<WRITE-LOG = ""*INFO: VM $vmName is already powered on.*"">"
} else {
    try {
        Start-VM -VM $vm -Confirm:$false | Out-Null
        Write-Host "<WRITE-LOG = ""*SUCCESS: VM $vmName powered on.*"">"
    } catch {
        Write-Host "<WRITE-LOG = ""*ERROR: Failed to power on VM $vmName - $($_.Exception.Message)*"">"
    }
}

Disconnect-VIServer -Server $server -Confirm:$false
