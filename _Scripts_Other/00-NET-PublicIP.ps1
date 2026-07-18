# Get Public IP Address
# Single use case: report the WAN IP this server egresses from
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ip = $null
foreach ($endpoint in @("https://api.ipify.org", "https://ifconfig.me/ip", "https://icanhazip.com")) {
    try {
        $ip = (Invoke-RestMethod -Uri $endpoint -TimeoutSec 10 -UseBasicParsing).ToString().Trim()
        if ($ip -match "^\d{1,3}(\.\d{1,3}){3}$") {
            Write-Log "Public IPv4: $ip (via $endpoint)"
            break
        }
        $ip = $null
    } catch { continue }
}

if ($null -eq $ip) {
    Write-Log "Could not determine the public IP - no lookup endpoint reachable (proxy/firewall?)."
    return
}

# Pass to the next runbook script (ex. compare against expected egress IP)
$store = $ip
