# Proxmox Create Snapshot
# Single use case: create a named snapshot for one VM (pre-change safety)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$ProxmoxHost  = "pve.example.com"
$VMName       = "test-vm"
$SnapshotName = "ServerEngine-PreChange"   # timestamp gets appended
$IncludeRAM   = $false                     # $true = vmstate snapshot of a running VM

$Username = SE-CredentialsStore.Username.(pve.example.com)
$Password = SE-CredentialsStore.Password.(pve.example.com)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$api = "https://${ProxmoxHost}:8006/api2/json"

$auth = Invoke-RestMethod -Method Post -Uri "$api/access/ticket" -Body @{ username = $Username; password = $Password } -ErrorAction SilentlyContinue
if ($null -eq $auth) { Write-Log "Authentication failed against $ProxmoxHost!"; return }
$headers = @{ Cookie = "PVEAuthCookie=$($auth.data.ticket)"; CSRFPreventionToken = $auth.data.CSRFPreventionToken }

$vm = (Invoke-RestMethod -Uri "$api/cluster/resources?type=vm" -Headers $headers).data | Where-Object { $_.name -eq $VMName }
if ($null -eq $vm) { Write-Log "VM not found: $VMName"; return }
if (@($vm).Count -gt 1) { Write-Log "VM name '$VMName' is ambiguous ($(@($vm).Count) matches)!"; return }

# Snapshot names must be alphanumeric + dash/underscore
$name = "$SnapshotName-$(Get-Date -Format 'yyyyMMdd-HHmm')" -replace "[^A-Za-z0-9_-]", ""

Write-Log "Creating snapshot '$name' for VM $VMName (ID $($vm.vmid))..."
$body = @{ snapname = $name; vmstate = if ($IncludeRAM) { 1 } else { 0 } }
$task = Invoke-RestMethod -Method Post -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/snapshot" -Headers $headers -Body $body

# Wait for the async task to finish
$upid = $task.data
$waited = 0
do {
    Start-Sleep 5
    $waited += 5
    $status = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/tasks/$upid/status" -Headers $headers).data
} while ($status.status -eq "running" -and $waited -lt 300)

if ($status.exitstatus -eq "OK") {
    Write-Log "Snapshot '$name' created successfully."
    $snaps = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/snapshot" -Headers $headers).data
    $count = @($snaps | Where-Object { $_.name -ne "current" }).Count
    Write-Log "VM $VMName now has $count snapshot(s). Clean old ones with Proxmox-Remove-OldSnapshots.ps1."
} else {
    Write-Log "WARNING: snapshot task ended with: $($status.exitstatus)"
}
