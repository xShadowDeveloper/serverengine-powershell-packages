# Proxmox Revert Snapshot
# Single use case: roll one VM back to a named snapshot
# WARNING: the current VM state is lost - everything since the snapshot!
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$ProxmoxHost  = "pve.example.com"
$VMName       = "test-vm"
$SnapshotName = ""        # exact name; empty = newest snapshot
$StartAfter   = $true     # start the VM again after rollback

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

$snaps = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/snapshot" -Headers $headers).data |
         Where-Object { $_.name -ne "current" }
if (-not $snaps) { Write-Log "VM $VMName has no snapshots to revert to!"; return }

if ([string]::IsNullOrWhiteSpace($SnapshotName)) {
    $snap = $snaps | Sort-Object snaptime -Descending | Select-Object -First 1
    Write-Log "No snapshot named - using the newest: '$($snap.name)'"
} else {
    $snap = $snaps | Where-Object { $_.name -eq $SnapshotName }
    if ($null -eq $snap) {
        Write-Log "Snapshot '$SnapshotName' not found. Available: $(($snaps | ForEach-Object { $_.name }) -join ', ')"
        return
    }
}

$taken = [DateTimeOffset]::FromUnixTimeSeconds($snap.snaptime).ToString("yyyy-MM-dd HH:mm")
Write-Log "Rolling VM $VMName (ID $($vm.vmid)) back to '$($snap.name)' from $taken..."
$task = Invoke-RestMethod -Method Post -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/snapshot/$($snap.name)/rollback" -Headers $headers

$upid = $task.data
$waited = 0
do {
    Start-Sleep 5
    $waited += 5
    $status = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/tasks/$upid/status" -Headers $headers).data
} while ($status.status -eq "running" -and $waited -lt 600)

if ($status.exitstatus -ne "OK") {
    Write-Log "WARNING: rollback ended with: $($status.exitstatus)"
    return
}
Write-Log "Rollback to '$($snap.name)' completed."

if ($StartAfter) {
    $state = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/status/current" -Headers $headers).data.status
    if ($state -ne "running") {
        Write-Log "Starting VM $VMName..."
        Invoke-RestMethod -Method Post -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/status/start" -Headers $headers | Out-Null
        Write-Log "Start requested."
    } else {
        Write-Log "VM is already running (vmstate snapshot restored a live VM)."
    }
}
