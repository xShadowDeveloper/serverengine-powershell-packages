$server = "esxi.CForce-IT.network"

$snapshotName = "PrePatch-Snapshot"
$snapshotDescription = "Snapshot before patch window - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$includeMemory = $false
$quiesce = $true

$vmNames = @(
    "VM01",
    "VM02",
    "VM03",
    "VM04"
)

Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Confirm:$false

$username = SE-CredentialsStore.Username.(esxi.CForce-IT.network)
$password = SE-CredentialsStore.Password.(esxi.CForce-IT.network)
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

Connect-VIServer -Server $server -Credential $credential

Write-Host "<WRITE-LOG = ""*================== Create Bulk Snapshots ==================*"">"

foreach ($vmName in $vmNames) {
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if ($vm) {
        try {
            New-Snapshot -VM $vm -Name $snapshotName -Description $snapshotDescription -Memory:$includeMemory -Quiesce:$quiesce -Confirm:$false
            Write-Host "<WRITE-LOG = ""*SUCCESS: Snapshot '$snapshotName' created on VM: $vmName*"">"
        } catch {
            Write-Host "<WRITE-LOG = ""*ERROR: Failed to create snapshot on VM: $vmName - $($_.Exception.Message)*"">"
        }
    } else {
        Write-Host "<WRITE-LOG = ""*WARNING: VM not found: $vmName*"">"
    }
}

Disconnect-VIServer -Server $server -Confirm:$false