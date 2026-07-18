# Audit Local Administrators
# Single use case: list every member of the local Administrators group
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# SID S-1-5-32-544 = Administrators (name-independent, works on localized OS)
$group = Get-LocalGroup -SID "S-1-5-32-544" -ErrorAction SilentlyContinue
if ($null -eq $group) { Write-Log "Could not resolve the Administrators group!"; return }

$members = Get-LocalGroupMember -Group $group.Name -ErrorAction SilentlyContinue
if (-not $members) {
    Write-Log "Could not enumerate members (orphaned SIDs can break enumeration on some builds)."
    return
}

Write-Log "================ Local Administrators ($(@($members).Count)) ================"
foreach ($m in ($members | Sort-Object ObjectClass, Name)) {
    Write-Log "[$($m.ObjectClass)] $($m.Name) (source: $($m.PrincipalSource))"
}

$orphans = $members | Where-Object { $_.Name -match "^S-1-5-21-" }
if ($orphans) {
    Write-Log "WARNING: $(@($orphans).Count) orphaned SID(s) found - deleted accounts still in the group!"
}

Write-Log "Local administrator audit complete."

# Pass the member list to the next runbook script
$store = (($members | ForEach-Object { $_.Name }) -join ",")
