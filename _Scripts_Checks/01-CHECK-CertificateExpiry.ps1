# Check Certificate Expiry
# Single use case: list machine certificates expiring within N days
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$WarnDays = 30

$deadline = (Get-Date).AddDays([int]$WarnDays)
$certs = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue

if (-not $certs) {
    Write-Log "No certificates found in LocalMachine\My."
    return
}

Write-Log "Checking $(@($certs).Count) certificate(s) in LocalMachine\My..."
$expiring = 0
foreach ($c in ($certs | Sort-Object NotAfter)) {
    $subject = if ($c.Subject) { $c.Subject } else { "(no subject)" }
    if ($c.NotAfter -lt (Get-Date)) {
        Write-Log "EXPIRED: [$($c.NotAfter.ToString('yyyy-MM-dd'))] $subject (thumbprint $($c.Thumbprint))"
        $expiring++
    } elseif ($c.NotAfter -le $deadline) {
        $left = [int]($c.NotAfter - (Get-Date)).TotalDays
        Write-Log "WARNING: expires in $left days [$($c.NotAfter.ToString('yyyy-MM-dd'))] $subject"
        $expiring++
    }
}

if ($expiring -eq 0) {
    Write-Log "Certificate check complete: nothing expires within $WarnDays days."
} else {
    Write-Log "Certificate check complete: $expiring certificate(s) expired or expiring within $WarnDays days!"
}
