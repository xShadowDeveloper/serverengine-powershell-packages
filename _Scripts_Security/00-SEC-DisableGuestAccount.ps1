# Disable the Local Guest Account
# Single use case: ensure the built-in Guest account cannot log on
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# The Guest account SID always ends in -501 (name-independent, localized OS safe)
$guest = Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID.Value -like "S-1-5-21-*-501" }
if ($null -eq $guest) {
    Write-Log "Built-in Guest account not found on this host."
    return
}

Write-Log "Guest account: '$($guest.Name)' enabled: $($guest.Enabled)"

if (-not $guest.Enabled) {
    Write-Log "Guest account is already disabled - nothing to do."
    return
}

Disable-LocalUser -SID $guest.SID
$guest = Get-LocalUser -SID $guest.SID

if (-not $guest.Enabled) {
    Write-Log "Guest account disabled successfully."
} else {
    Write-Log "WARNING: Guest account is still enabled!"
}
