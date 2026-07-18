# Enable Windows Firewall (all profiles)
# Single use case: turn the firewall on for Domain, Private and Public
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
if (-not $profiles) { Write-Log "Could not read firewall profiles!"; return }

$changed = 0
foreach ($p in $profiles) {
    if ($p.Enabled -eq $true) {
        Write-Log "Profile $($p.Name): already enabled."
    } else {
        Set-NetFirewallProfile -Name $p.Name -Enabled True
        Write-Log "Profile $($p.Name): ENABLED (was off)."
        $changed++
    }
}

$after = Get-NetFirewallProfile | Where-Object { $_.Enabled -ne $true }
if ($after) {
    Write-Log "WARNING: $(@($after).Count) profile(s) still disabled!"
} else {
    Write-Log "Firewall active on all profiles ($changed changed)."
}
