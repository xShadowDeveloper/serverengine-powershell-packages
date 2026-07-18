# Install RSAT Active Directory PowerShell Tools
# Single use case: make the ActiveDirectory module available on this host
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Write-Log "ActiveDirectory module is already available - nothing to do."
    return
}

if (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue) {
    # Windows Server
    Write-Log "Installing feature RSAT-AD-PowerShell (Windows Server)..."
    $result = Install-WindowsFeature -Name RSAT-AD-PowerShell
    if ($result.Success) {
        Write-Log "RSAT-AD-PowerShell installed successfully."
    } else {
        Write-Log "WARNING: feature installation failed (exit: $($result.ExitCode))."
        return
    }
} else {
    # Windows 10/11 client: capability on demand
    Write-Log "Installing capability Rsat.ActiveDirectory (Windows client)..."
    $cap = Get-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools*" | Select-Object -First 1
    if ($null -eq $cap) { Write-Log "RSAT AD capability not found in this image."; return }
    if ($cap.State -eq "Installed") {
        Write-Log "Capability already installed."
    } else {
        Add-WindowsCapability -Online -Name $cap.Name | Out-Null
        Write-Log "Capability $($cap.Name) installed."
    }
}

if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Write-Log "ActiveDirectory PowerShell module is now available."
} else {
    Write-Log "WARNING: module still not found after installation!"
}
