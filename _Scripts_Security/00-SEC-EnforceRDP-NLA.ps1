# Enforce Network Level Authentication for RDP
# Single use case: require NLA so unauthenticated sessions never reach logon UI
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$tsPath  = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
$rdpPath = "$tsPath\WinStations\RDP-Tcp"

$rdpEnabled = (Get-ItemProperty $tsPath -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections -eq 0
Write-Log "RDP enabled on this host: $rdpEnabled"
if (-not $rdpEnabled) {
    Write-Log "RDP is disabled - NLA setting written anyway for when it gets enabled."
}

$current = (Get-ItemProperty $rdpPath -Name UserAuthentication -ErrorAction SilentlyContinue).UserAuthentication
if ($current -eq 1) {
    Write-Log "NLA is already enforced - nothing to do."
    return
}

Set-ItemProperty -Path $rdpPath -Name "UserAuthentication" -Value 1 -Type DWord
# Also require TLS security layer for the RDP transport
Set-ItemProperty -Path $rdpPath -Name "SecurityLayer" -Value 2 -Type DWord

$verify = (Get-ItemProperty $rdpPath -Name UserAuthentication).UserAuthentication
if ($verify -eq 1) {
    Write-Log "NLA enforced (UserAuthentication=1, SecurityLayer=TLS)."
    Write-Log "Existing sessions are not affected; new connections must support NLA (all supported Windows versions do)."
} else {
    Write-Log "WARNING: failed to write the NLA setting!"
}
