# DHCP Scope Statistics
# Single use case: report utilization of every scope on this DHCP server
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$WarnPercentUsed = 90

if (-not (Get-Module -ListAvailable -Name DhcpServer)) {
    Write-Log "DhcpServer module not available - is the DHCP role installed on this host?"
    return
}

$scopes = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue
if (-not $scopes) { Write-Log "No IPv4 scopes found on this DHCP server."; return }

$warnings = 0
Write-Log "================ DHCP Scopes ($(@($scopes).Count)) ================"
foreach ($s in $scopes) {
    $stats = Get-DhcpServerv4ScopeStatistics -ScopeId $s.ScopeId -ErrorAction SilentlyContinue
    if ($null -eq $stats) { continue }
    $pct = [math]::Round($stats.PercentageInUse, 1)
    $line = "[$($s.ScopeId)] '$($s.Name)' ($($s.State)) in use: $($stats.AddressesInUse)/$($stats.AddressesInUse + $stats.AddressesFree) ($pct%)"
    if ($pct -ge [double]$WarnPercentUsed -and $s.State -eq "Active") {
        Write-Log "WARNING: $line - scope nearly exhausted!"
        $warnings++
    } else {
        Write-Log $line
    }
}

if ($warnings -eq 0) {
    Write-Log "DHCP scope check complete: all scopes below $WarnPercentUsed% utilization."
} else {
    Write-Log "DHCP scope check complete: $warnings scope(s) above $WarnPercentUsed%!"
}
