# Clear DNS Server Cache
# Single use case: purge cached records on a DNS server (stale external record fix)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

if (-not (Get-Module -ListAvailable -Name DnsServer)) {
    Write-Log "DnsServer module not available - is the DNS role installed on this host?"
    return
}

$svc = Get-Service -Name DNS -ErrorAction SilentlyContinue
if ($null -eq $svc -or $svc.Status -ne "Running") {
    Write-Log "DNS Server service is not running on this host!"
    return
}

Clear-DnsServerCache -Force -ErrorAction SilentlyContinue
Write-Log "DNS server cache cleared."

# Also clear the local client cache so this host resolves fresh immediately
Clear-DnsClientCache -ErrorAction SilentlyContinue
Write-Log "Local DNS client cache cleared as well."
