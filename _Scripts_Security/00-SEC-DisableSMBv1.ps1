# Disable SMBv1 Protocol
# Single use case: remove the legacy SMBv1 attack surface (WannaCry vector)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$server = Get-SmbServerConfiguration -ErrorAction SilentlyContinue
if ($null -eq $server) { Write-Log "Could not read SMB server configuration!"; return }

if (-not $server.EnableSMB1Protocol) {
    Write-Log "SMBv1 server protocol is already disabled."
} else {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Confirm:$false
    Write-Log "SMBv1 server protocol DISABLED."
}

# Remove the optional feature as well (server + client components)
$feature = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
if ($feature -and $feature.State -eq "Enabled") {
    Write-Log "Removing SMB1Protocol optional feature..."
    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Write-Log "SMB1Protocol feature disabled (a reboot completes the removal)."
} elseif ($feature) {
    Write-Log "SMB1Protocol optional feature already $($feature.State)."
}

$server = Get-SmbServerConfiguration
Write-Log "Verification - EnableSMB1Protocol: $($server.EnableSMB1Protocol)"
Write-Log "SMBv1 hardening complete. Note: verify no legacy devices (old NAS/printers/scanners) still need SMBv1."
