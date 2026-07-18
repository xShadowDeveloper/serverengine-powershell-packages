# Check AD Replication Health
# Single use case: report replication failures between domain controllers
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "ActiveDirectory module not available on this host!"
    return
}
Import-Module ActiveDirectory

Write-Log "Collecting replication status for all domain controllers..."

$failures = Get-ADReplicationFailure -Target * -Scope Domain -ErrorAction SilentlyContinue
$partners = Get-ADReplicationPartnerMetadata -Target * -Scope Domain -ErrorAction SilentlyContinue

if ($partners) {
    Write-Log "================ Replication Partners ================"
    foreach ($p in $partners) {
        $srcDC = ($p.Partner -split ",CN=")[1]
        $last  = if ($p.LastReplicationSuccess) { $p.LastReplicationSuccess.ToString('yyyy-MM-dd HH:mm') } else { "unknown" }
        Write-Log "[$($p.Server)] <- [$srcDC] last success: $last"
    }
} else {
    Write-Log "Could not read partner metadata (single-DC domain or insufficient rights)."
}

if ($failures -and @($failures).Count -gt 0) {
    Write-Log "================ Replication FAILURES ($(@($failures).Count)) ================"
    foreach ($f in $failures) {
        Write-Log "FAILURE: [$($f.Server)] partner [$($f.Partner)] count: $($f.FailureCount) first: $($f.FirstFailureTime)"
    }
    Write-Log "WARNING: Replication problems detected - investigate!"
} else {
    Write-Log "No replication failures reported. AD replication is healthy."
}
