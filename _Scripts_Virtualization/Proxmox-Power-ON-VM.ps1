# Proxmox Power ON VM
# Single use case: start one VM by name and wait until it is running
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$ProxmoxHost = "pve.example.com"
$VMName      = "test-vm"

$Username = SE-CredentialsStore.Username.(pve.example.com)
$Password = SE-CredentialsStore.Password.(pve.example.com)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$api = "https://${ProxmoxHost}:8006/api2/json"

$auth = Invoke-RestMethod -Method Post -Uri "$api/access/ticket" -Body @{ username = $Username; password = $Password } -ErrorAction SilentlyContinue
if ($null -eq $auth) { Write-Log "Authentication failed against $ProxmoxHost!"; return }
$headers = @{ Cookie = "PVEAuthCookie=$($auth.data.ticket)"; CSRFPreventionToken = $auth.data.CSRFPreventionToken }

# --- Find the VM (cluster-wide) ---
$vm = (Invoke-RestMethod -Uri "$api/cluster/resources?type=vm" -Headers $headers).data | Where-Object { $_.name -eq $VMName }
if ($null -eq $vm) { Write-Log "VM not found: $VMName"; return }
if (@($vm).Count -gt 1) { Write-Log "VM name '$VMName' is ambiguous ($(@($vm).Count) matches)!"; return }

if ($vm.status -eq "running") {
    Write-Log "VM $VMName (ID $($vm.vmid)) is already running - nothing to do."
    return
}

Write-Log "Starting VM $VMName (ID $($vm.vmid)) on node $($vm.node)..."
Invoke-RestMethod -Method Post -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/status/start" -Headers $headers | Out-Null

$timeout = 60
while ($timeout -gt 0) {
    Start-Sleep 5
    $timeout -= 5
    $state = (Invoke-RestMethod -Uri "$api/nodes/$($vm.node)/qemu/$($vm.vmid)/status/current" -Headers $headers).data.status
    if ($state -eq "running") { break }
}

if ($state -eq "running") {
    Write-Log "VM $VMName is running."
} else {
    Write-Log "WARNING: VM $VMName is in state '$state' after start attempt!"
}
