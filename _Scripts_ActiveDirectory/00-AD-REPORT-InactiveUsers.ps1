# Report Inactive AD Users
# Single use case: list enabled users with no logon for N days
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$InactiveDays = 90

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "ActiveDirectory module not available on this host!"
    return
}
Import-Module ActiveDirectory

$cutoff = (Get-Date).AddDays(-[int]$InactiveDays)
Write-Log "Searching enabled users with no logon since $($cutoff.ToString('yyyy-MM-dd'))..."

$users = Get-ADUser -Filter { Enabled -eq $true } -Properties LastLogonDate, whenCreated |
         Where-Object { ($_.LastLogonDate -lt $cutoff) -and ($_.whenCreated -lt $cutoff) } |
         Sort-Object LastLogonDate

if (-not $users) {
    Write-Log "No inactive users found - all enabled accounts logged on within $InactiveDays days."
    return
}

Write-Log "================ Inactive Users ($($users.Count)) ================"
foreach ($u in $users) {
    $last = if ($u.LastLogonDate) { $u.LastLogonDate.ToString('yyyy-MM-dd') } else { "never" }
    Write-Log "LastLogon: [$last] $($u.SamAccountName)  ($($u.Name))"
}
Write-Log "Inactive user report complete: $($users.Count) account(s) exceeded $InactiveDays days."

# Pass the list to the next runbook script (comma separated)
$store = ($users.SamAccountName -join ",")
