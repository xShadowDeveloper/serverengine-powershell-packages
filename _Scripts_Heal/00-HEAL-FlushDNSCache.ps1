# Flush DNS Client Cache
# Single use case: clear the local DNS resolver cache (stale record fix)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$before = (Get-DnsClientCache -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Log "DNS cache entries before flush: $before"

Clear-DnsClientCache -ErrorAction SilentlyContinue

$after = (Get-DnsClientCache -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Log "DNS cache entries after flush: $after"
Write-Log "DNS client cache flushed."
