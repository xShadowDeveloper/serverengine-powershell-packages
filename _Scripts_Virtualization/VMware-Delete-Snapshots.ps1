$server = "esxi.CForce-IT.network"
$maxAgeDays = 30
$whatIf = $true   # Set to $false to actually delete

Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Confirm:$false

$username = SE-CredentialsStore.Username.(esxi.CForce-IT.network)
$password = SE-CredentialsStore.Password.(esxi.CForce-IT.network)
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

Connect-VIServer -Server $server -Credential $credential

Write-Host "<WRITE-LOG = ""*================== Delete Snapshots Older Than $maxAgeDays Days ==================*"">"

$cutoffDate = (Get-Date).AddDays(-$maxAgeDays)
$snapshots = Get-VM | Get-Snapshot | Where-Object { $_.Created -lt $cutoffDate }

if ($snapshots) {
    foreach ($snap in $snapshots) {
        $ageDays = ((Get-Date) - $snap.Created).Days
        if ($whatIf) {
            Write-Host "<WRITE-LOG = ""*[WHATIF] Would delete snapshot: $($snap.Name) on VM: $($snap.VM.Name) | Age: $ageDays days | Size: $([math]::Round($snap.SizeGB,2)) GB*"">"
        } else {
            Write-Host "<WRITE-LOG = ""*Deleting snapshot: $($snap.Name) on VM: $($snap.VM.Name) | Age: $ageDays days*"">"
            Remove-Snapshot -Snapshot $snap -Confirm:$false -RunAsync
        }
    }
} else {
    Write-Host "<WRITE-LOG = ""*No snapshots older than $maxAgeDays days found.*"">"
}

Disconnect-VIServer -Server $server -Confirm:$false