# Install a Windows Server Feature/Role
# Single use case: install one feature by name (ex. DNS, DHCP, Web-Server)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$FeatureName = "Telnet-Client"
$IncludeManagementTools = $true

if (-not (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue)) {
    Write-Log "Install-WindowsFeature not available (client OS?) - use Add-WindowsCapability instead."
    return
}

$feature = Get-WindowsFeature -Name $FeatureName -ErrorAction SilentlyContinue
if ($null -eq $feature) {
    Write-Log "Feature not found: $FeatureName"
    return
}
if ($feature.Installed) {
    Write-Log "Feature $FeatureName is already installed - nothing to do."
    return
}

Write-Log "Installing feature: $($feature.DisplayName) ($FeatureName)..."
if ($IncludeManagementTools) {
    $result = Install-WindowsFeature -Name $FeatureName -IncludeManagementTools
} else {
    $result = Install-WindowsFeature -Name $FeatureName
}

if ($result.Success) {
    Write-Log "Feature $FeatureName installed successfully."
    if ($result.RestartNeeded -eq "Yes") {
        Write-Log "NOTE: a reboot is required to finish (chain 02-SE-ManagedReboot.ps1 in a runbook)."
        $store = "RebootPending"
    } else {
        $store = "NoRebootPending"
    }
} else {
    Write-Log "WARNING: installation of $FeatureName did not succeed (exit: $($result.ExitCode))."
}
