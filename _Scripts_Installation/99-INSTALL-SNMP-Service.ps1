# Install SNMP Service
# Single use case: install the SNMP service for monitoring integrations
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$svc = Get-Service -Name SNMP -ErrorAction SilentlyContinue
if ($svc) {
    Write-Log "SNMP service is already installed ($($svc.Status)) - nothing to do."
    return
}

if (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue) {
    Write-Log "Installing SNMP-Service feature (Windows Server)..."
    $result = Install-WindowsFeature -Name SNMP-Service -IncludeManagementTools
    if (-not $result.Success) {
        Write-Log "WARNING: feature installation failed (exit: $($result.ExitCode))."
        return
    }
} else {
    Write-Log "Installing SNMP capability (Windows client)..."
    $cap = Get-WindowsCapability -Online -Name "SNMP.Client*" | Select-Object -First 1
    if ($null -eq $cap) { Write-Log "SNMP capability not found in this image."; return }
    Add-WindowsCapability -Online -Name $cap.Name | Out-Null
}

Start-Sleep 2
$svc = Get-Service -Name SNMP -ErrorAction SilentlyContinue
if ($svc) {
    Write-Log "SNMP service installed ($($svc.Status))."
    Write-Log "NOTE: configure community strings/permitted managers before use."
} else {
    Write-Log "WARNING: SNMP service not found after installation!"
}
