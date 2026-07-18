# Proxmox Clone VM
# Single use case: create a full clone of a template/VM (replaces the old
# untested 01-Deploy-VM-Proxmox.ps1)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$ProxmoxHost  = "pve.example.com"
$SourceVMName = "template-ubuntu"   # template or VM to clone from
$NewVMName    = "new-vm"
$NewVMID      = 0                   # 0 = next free ID from the cluster
$Storage      = ""                  # empty = same storage as source
$StartAfter   = $false

$Username = SE-CredentialsStore.Username.(pve.example.com)
$Password = SE-CredentialsStore.Password.(pve.example.com)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$api = "https://${ProxmoxHost}:8006/api2/json"

$auth = Invoke-RestMethod -Method Post -Uri "$api/access/ticket" -Body @{ username = $Username; password = $Password } -ErrorAction SilentlyContinue
if ($null -eq $auth) { Write-Log "Authentication failed against $ProxmoxHost!"; return }
$headers = @{ Cookie = "PVEAuthCookie=$($auth.data.ticket)"; CSRFPreventionToken = $auth.data.CSRFPreventionToken }

$all = (Invoke-RestMethod -Uri "$api/cluster/resources?type=vm" -Headers $headers).data
$src = $all | Where-Object { $_.name -eq $SourceVMName }
if ($null -eq $src) { Write-Log "Source VM/template not found: $SourceVMName"; return }
if (@($src).Count -gt 1) { Write-Log "Source name '$SourceVMName' is ambiguous!"; return }

if ($all | Where-Object { $_.name -eq $NewVMName }) {
    Write-Log "A VM named '$NewVMName' already exists - aborting."
    return
}

if ([int]$NewVMID -le 0) {
    $NewVMID = (Invoke-RestMethod -Uri "$api/cluster/nextid" -Headers $headers).data
}

Write-Log "Cloning '$SourceVMName' (ID $($src.vmid)) -> '$NewVMName' (ID $NewVMID) on node $($src.node)..."
$body = @{ newid = [int]$NewVMID; name = $NewVMName; full = 1 }
if (-not [string]::IsNullOrWhiteSpace($Storage)) { $body.storage = $Storage }
$task = Invoke-RestMethod -Method Post -Uri "$api/nodes/$($src.node)/qemu/$($src.vmid)/clone" -Headers $headers -Body $body

# Full clones copy disks - allow up to 30 minutes
$upid = $task.data
$waited = 0
do {
    Start-Sleep 10
    $waited += 10
    $status = (Invoke-RestMethod -Uri "$api/nodes/$($src.node)/tasks/$upid/status" -Headers $headers).data
    if ($waited % 60 -eq 0) { Write-Log "Cloning... (${waited}s elapsed)" }
} while ($status.status -eq "running" -and $waited -lt 1800)

if ($status.exitstatus -ne "OK") {
    Write-Log "WARNING: clone task ended with: $($status.exitstatus)"
    return
}
Write-Log "Clone completed: '$NewVMName' (ID $NewVMID)."

if ($StartAfter) {
    Write-Log "Starting '$NewVMName'..."
    Invoke-RestMethod -Method Post -Uri "$api/nodes/$($src.node)/qemu/$NewVMID/status/start" -Headers $headers | Out-Null
    Write-Log "Start requested."
}

# Pass the new VM name to the next runbook script
$store = $NewVMName
