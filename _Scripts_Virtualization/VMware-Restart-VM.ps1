# Set target VM name
$vmName = "VM01"

$server = "esxi.CForce-IT.network"

Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Confirm:$false

$username = SE-CredentialsStore.Username.(esxi.CForce-IT.network)
$password = SE-CredentialsStore.Password.(esxi.CForce-IT.network)
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

Connect-VIServer -Server $server -Credential $credential

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue

if (-not $vm) {
    Write-Host "<WRITE-LOG = ""*ERROR: VM not found: $vmName*"">"
} else {
    try {
        Restart-VM -VM $vm -Confirm:$false | Out-Null
        Write-Host "<WRITE-LOG = ""*SUCCESS: VM $vmName restarted.*"">"
    } catch {
        Write-Host "<WRITE-LOG = ""*ERROR: Failed to restart VM $vmName - $($_.Exception.Message)*"">"
    }
}

Disconnect-VIServer -Server $server -Confirm:$false