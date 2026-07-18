# Report Expiring AD Passwords
# Single use case: list users whose password expires within N days
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$WarnDays = 14

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "ActiveDirectory module not available on this host!"
    return
}
Import-Module ActiveDirectory

$deadline = (Get-Date).AddDays([int]$WarnDays)
Write-Log "Searching passwords expiring before $($deadline.ToString('yyyy-MM-dd'))..."

$users = Get-ADUser -Filter { Enabled -eq $true -and PasswordNeverExpires -eq $false } `
                    -Properties "msDS-UserPasswordExpiryTimeComputed", EmailAddress |
    ForEach-Object {
        $raw = $_."msDS-UserPasswordExpiryTimeComputed"
        if ($raw -and $raw -gt 0 -and $raw -lt 9223372036854775807) {
            $expires = [datetime]::FromFileTime($raw)
            if ($expires -le $deadline -and $expires -gt (Get-Date).AddYears(-30)) {
                [pscustomobject]@{ Sam = $_.SamAccountName; Name = $_.Name; Expires = $expires }
            }
        }
    } | Sort-Object Expires

if (-not $users) {
    Write-Log "No passwords expire within $WarnDays days."
    return
}

Write-Log "================ Expiring Passwords ($(@($users).Count)) ================"
foreach ($u in $users) {
    $state = if ($u.Expires -lt (Get-Date)) { "EXPIRED" } else { "expires" }
    Write-Log "$state: [$($u.Expires.ToString('yyyy-MM-dd HH:mm'))] $($u.Sam)  ($($u.Name))"
}
Write-Log "Password expiry report complete: $(@($users).Count) account(s) within $WarnDays days."
