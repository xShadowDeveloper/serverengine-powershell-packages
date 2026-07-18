# Disable an AD User Account
# Single use case: disable one user account (offboarding, security incident)
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

$user = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -Properties Enabled -ErrorAction SilentlyContinue
if ($null -eq $user) {
    Write-Log "User not found: $SamAccountName"
    return
}

if (-not $user.Enabled) {
    Write-Log "User $SamAccountName is already disabled."
    return
}

Disable-ADAccount -Identity $user.DistinguishedName
$user = Get-ADUser -Identity $user.DistinguishedName -Properties Enabled

if (-not $user.Enabled) {
    Write-Log "User $SamAccountName disabled successfully."
} else {
    Write-Log "WARNING: User $SamAccountName is still enabled!"
}
