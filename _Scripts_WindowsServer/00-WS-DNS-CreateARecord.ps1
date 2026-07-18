# Create a DNS A Record
# Single use case: add one A record (with PTR if the reverse zone exists)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$RecordName = "newhost"
$ZoneName   = "example.local"
$IPAddress  = "10.0.0.50"

if (-not (Get-Module -ListAvailable -Name DnsServer)) {
    Write-Log "DnsServer module not available - is the DNS role installed on this host?"
    return
}

$zone = Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue
if ($null -eq $zone) { Write-Log "Zone not found on this server: $ZoneName"; return }

$existing = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $RecordName -RRType A -ErrorAction SilentlyContinue
if ($existing) {
    $ips = ($existing | ForEach-Object { $_.RecordData.IPv4Address.IPAddressToString }) -join ", "
    Write-Log "Record $RecordName.$ZoneName already exists -> $ips - nothing changed."
    return
}

Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name $RecordName -IPv4Address $IPAddress -CreatePtr -ErrorAction SilentlyContinue

$verify = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $RecordName -RRType A -ErrorAction SilentlyContinue
if ($verify) {
    Write-Log "A record created: $RecordName.$ZoneName -> $IPAddress (PTR requested where reverse zone exists)."
} else {
    Write-Log "WARNING: record was not created - check zone type (must be primary) and permissions."
}
