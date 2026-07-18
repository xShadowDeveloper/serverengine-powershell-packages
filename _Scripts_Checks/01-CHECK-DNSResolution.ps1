# Check DNS Resolution
# Single use case: verify the server can resolve internal and external names
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$TestNames = "$env:USERDNSDOMAIN,microsoft.com,dns.google"

$dnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
               Where-Object { $_.ServerAddresses } | Select-Object -First 1).ServerAddresses
Write-Log "Configured DNS servers: $(if ($dnsServers) { $dnsServers -join ', ' } else { 'none found' })"

$failed = 0
foreach ($name in ($TestNames -split ",")) {
    $name = $name.Trim()
    if ([string]::IsNullOrWhiteSpace($name)) { continue }

    $result = Resolve-DnsName -Name $name -Type A -ErrorAction SilentlyContinue
    if ($result) {
        $ips = ($result | Where-Object { $_.IPAddress } | Select-Object -First 3).IPAddress -join ", "
        Write-Log "OK: $name -> $ips"
    } else {
        Write-Log "FAILED: $name did not resolve!"
        $failed++
    }
}

if ($failed -eq 0) {
    Write-Log "DNS check complete: all names resolved."
} else {
    Write-Log "DNS check complete: $failed name(s) failed to resolve - check DNS configuration!"
}
