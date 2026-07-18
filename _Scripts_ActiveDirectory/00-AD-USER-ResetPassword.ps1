# Reset an AD User Password
# Single use case: set a new password and force change at next logon
# Tip: chain after 00-GENERATE-RandomPassword.ps1 in a runbook ($store)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$SamAccountName = "j.doe"
$NewPassword    = ""          # leave empty to use $store from a previous runbook script
$ForceChange    = $true       # user must change password at next logon

if ([string]::IsNullOrWhiteSpace($NewPassword)) { $NewPassword = "$store" }
if ([string]::IsNullOrWhiteSpace($NewPassword)) {
    Write-Log "No password provided (parameter empty and nothing in `$store)!"
    return
}

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "ActiveDirectory module not available on this host!"
    return
}
Import-Module ActiveDirectory

$user = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
if ($null -eq $user) {
    Write-Log "User not found: $SamAccountName"
    return
}

$secure = ConvertTo-SecureString $NewPassword -AsPlainText -Force
Set-ADAccountPassword -Identity $user.DistinguishedName -NewPassword $secure -Reset

if ($ForceChange) {
    Set-ADUser -Identity $user.DistinguishedName -ChangePasswordAtLogon $true
    Write-Log "Password reset for $SamAccountName - change enforced at next logon."
} else {
    Write-Log "Password reset for $SamAccountName."
}
