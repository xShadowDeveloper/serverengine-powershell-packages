# Add a User to an AD Group
# Single use case: add one user to one security/distribution group
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$SamAccountName = "j.doe"
$GroupName      = "IT-Admins"

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "ActiveDirectory module not available on this host!"
    return
}
Import-Module ActiveDirectory

$user  = Get-ADUser  -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
$group = Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue

if ($null -eq $user)  { Write-Log "User not found: $SamAccountName"; return }
if ($null -eq $group) { Write-Log "Group not found: $GroupName"; return }

$isMember = Get-ADGroupMember -Identity $group.DistinguishedName -ErrorAction SilentlyContinue |
            Where-Object { $_.SamAccountName -eq $user.SamAccountName }
if ($isMember) {
    Write-Log "$SamAccountName is already a member of $GroupName."
    return
}

Add-ADGroupMember -Identity $group.DistinguishedName -Members $user.DistinguishedName
Write-Log "$SamAccountName added to group $GroupName."
