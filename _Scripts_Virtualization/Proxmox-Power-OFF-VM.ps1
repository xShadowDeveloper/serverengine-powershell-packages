# Proxmox Power OFF VM
# Single use case: gracefully shut down one VM (guest shutdown, no hard stop)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$ProxmoxHost       = "pve.example.com"
$VMName            = "test-vm"
$TimeoutSeconds    = 120
$ForceAfterTimeout = $false   # $true = hard stop if the guest ignores shutdown

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

if ($vm.status -ne "running") {
    Write-Log "VM $VMName (ID $($vm.vmid)) is not running (status: $($vm.status)) - nothing to do."
    return
}

Write-Log "Sending guest shutdown to VM $VMName (ID $($vm.vmid), timeout ${TimeoutSeconds}s)..."
Invoke-RestMethod -Method Post -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/status/shutdown" -Headers $headers -Body @{ timeout = [int]$TimeoutSeconds } | Out-Null

$waited = 0
while ($waited -lt ([int]$TimeoutSeconds + 10)) {
    Start-Sleep 5
    $waited += 5
    $state = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/status/current" -Headers $headers).data.status
    if ($state -eq "stopped") { break }
}

if ($state -eq "stopped") {
    Write-Log "VM $VMName shut down gracefully after ${waited}s."
} elseif ($ForceAfterTimeout) {
    Write-Log "Guest did not shut down in time - forcing hard stop..."
    Invoke-RestMethod -Method Post -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/status/stop" -Headers $headers | Out-Null
    Start-Sleep 5
    $state = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/status/current" -Headers $headers).data.status
    Write-Log "VM $VMName state after force: $state"
} else {
    Write-Log "WARNING: VM $VMName still '$state' after ${TimeoutSeconds}s (guest agent missing or busy). Not forcing."
}
