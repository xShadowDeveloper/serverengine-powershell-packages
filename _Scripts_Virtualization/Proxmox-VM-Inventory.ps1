# Proxmox VM Inventory
# Single use case: list all VMs in the cluster with state and resources
# Uses the Proxmox REST API (add the PVE host to ServerEngine credentials)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$ProxmoxHost = "pve.example.com"

# Credentials from the ServerEngine store (user format: root@pam or user@pve)
$Username = SE-CredentialsStore.Username.(pve.example.com)
$Password = SE-CredentialsStore.Password.(pve.example.com)

# PVE uses a self-signed certificate by default (PowerShell 5.1 compatible bypass)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$api = "https://${ProxmoxHost}:8006/api2/json"

# --- Authenticate ---
$auth = Invoke-RestMethod -Method Post -Uri "$api/access/ticket" -Body @{ username = $Username; password = $Password } -ErrorAction SilentlyContinue
if ($null -eq $auth) { Write-Log "Authentication failed against $ProxmoxHost!"; return }
$headers = @{ Cookie = "PVEAuthCookie=$($auth.data.ticket)" }

# --- Inventory (cluster-wide, includes all nodes) ---
$vms = (Invoke-RestMethod -Uri "$api/cluster/resources?type=vm" -Headers $headers).data
if (-not $vms) { Write-Log "No VMs found on $ProxmoxHost."; return }

Write-Log "================ Proxmox VMs ($(@($vms).Count)) ================"
foreach ($vm in ($vms | Sort-Object status, name)) {
    $memGB = [math]::Round($vm.maxmem / 1GB, 1)
    $diskGB = [math]::Round($vm.maxdisk / 1GB, 0)
    $up = if ($vm.status -eq "running") { " uptime: $([math]::Round($vm.uptime / 86400, 1))d" } else { "" }
    Write-Log "[$($vm.status.PadRight(7))] ID: $($vm.vmid.ToString().PadLeft(4)) vCPU: $($vm.maxcpu.ToString().PadLeft(2)) RAM: $($memGB.ToString().PadLeft(5)) GB Disk: $($diskGB.ToString().PadLeft(5)) GB node: $($vm.node) $($vm.name)$up"
}

$running = @($vms | Where-Object { $_.status -eq "running" }).Count
Write-Log "Inventory complete: $running of $(@($vms).Count) VM(s) running."

# Pass VM names to the next runbook script
$store = (($vms | ForEach-Object { $_.name }) -join ",")
