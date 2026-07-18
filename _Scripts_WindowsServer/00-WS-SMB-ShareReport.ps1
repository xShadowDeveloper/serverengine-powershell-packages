# SMB Share Report
# Single use case: list all shares with their permissions (audit view)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$IncludeHidden = $false   # $true also lists admin shares (C$, ADMIN$, IPC$)

$shares = Get-SmbShare -ErrorAction SilentlyContinue
if (-not $IncludeHidden) {
    $shares = $shares | Where-Object { -not $_.Special }
}
if (-not $shares) { Write-Log "No shares found (hidden shares excluded)."; return }

Write-Log "================ SMB Shares ($(@($shares).Count)) ================"
foreach ($s in $shares) {
    Write-Log "[$($s.Name)] path: $($s.Path)"
    $access = Get-SmbShareAccess -Name $s.Name -ErrorAction SilentlyContinue
    foreach ($a in $access) {
        Write-Log "    $($a.AccessControlType): $($a.AccountName) -> $($a.AccessRight)"
    }
    $everyone = $access | Where-Object { $_.AccountName -match "Everyone|Jeder" -and $_.AccessControlType -eq "Allow" -and $_.AccessRight -ne "Read" }
    if ($everyone) {
        Write-Log "    WARNING: 'Everyone' has $($everyone.AccessRight) on this share!"
    }
}

Write-Log "Share report complete."
