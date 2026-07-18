# Proxmox Remove Old Snapshots
# Single use case: delete snapshots older than N days for one VM
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$ProxmoxHost   = "pve.example.com"
$VMName        = "test-vm"
$OlderThanDays = 14

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

$cutoff = [DateTimeOffset]::Now.AddDays(-[int]$OlderThanDays).ToUnixTimeSeconds()
$snaps = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/snapshot" -Headers $headers).data |
         Where-Object { $_.name -ne "current" -and $_.snaptime -and $_.snaptime -lt $cutoff }

if (-not $snaps) {
    Write-Log "No snapshots older than $OlderThanDays days on VM $VMName - nothing to do."
    return
}

$removed = 0
foreach ($s in $snaps) {
    $age = [DateTimeOffset]::FromUnixTimeSeconds($s.snaptime).ToString("yyyy-MM-dd")
    Write-Log "Removing snapshot '$($s.name)' from $age..."
    $task = Invoke-RestMethod -Method Delete -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/snapshot/$($s.name)" -Headers $headers

    $upid = $task.data
    $waited = 0
    do {
        Start-Sleep 5
        $waited += 5
        $status = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/tasks/$upid/status" -Headers $headers).data
    } while ($status.status -eq "running" -and $waited -lt 600)

    if ($status.exitstatus -eq "OK") {
        Write-Log "Snapshot '$($s.name)' removed."
        $removed++
    } else {
        Write-Log "WARNING: removal of '$($s.name)' ended with: $($status.exitstatus)"
    }
}

Write-Log "Snapshot cleanup complete: $removed of $(@($snaps).Count) old snapshot(s) removed from $VMName."
