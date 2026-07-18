# Unlock an AD User Account
# Single use case: unlock one user locked out by failed logon attempts
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$SamAccountName = "j.doe"

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "ActiveDirectory module not available on this host!"
    return
}
Import-Module ActiveDirectory

$user = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -Properties LockedOut, LockoutTime -ErrorAction SilentlyContinue
if ($null -eq $user) {
    Write-Log "User not found: $SamAccountName"
    return
}

if (-not $user.LockedOut) {
    Write-Log "User $SamAccountName is not locked out - nothing to do."
    return
}

Unlock-ADAccount -Identity $user.DistinguishedName
$user = Get-ADUser -Identity $user.DistinguishedName -Properties LockedOut

if (-not $user.LockedOut) {
    Write-Log "User $SamAccountName unlocked successfully."
} else {
    Write-Log "WARNING: User $SamAccountName is still locked out!"
}
