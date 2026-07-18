# Wake-on-LAN
# Single use case: send a WOL magic packet to wake one machine
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$MacAddress = "00-11-22-33-44-55"    # accepts : or - separators
$Broadcast  = "255.255.255.255"      # use the subnet broadcast for routed networks
$Port       = 9

$clean = $MacAddress -replace "[:-]", ""
if ($clean -notmatch "^[0-9A-Fa-f]{12}$") {
    Write-Log "Invalid MAC address: $MacAddress"
    return
}

$macBytes = for ($i = 0; $i -lt 12; $i += 2) { [Convert]::ToByte($clean.Substring($i, 2), 16) }

# magic packet = 6x 0xFF + 16x MAC
$packet = (,[byte]0xFF * 6) + ($macBytes * 16)

$udp = New-Object System.Net.Sockets.UdpClient
try {
    $udp.Connect($Broadcast, [int]$Port)
    [void]$udp.Send($packet, $packet.Length)
    Write-Log "Magic packet sent to $MacAddress via ${Broadcast}:${Port}."
    Write-Log "Note: the target needs WOL enabled in BIOS/NIC settings, and routed networks need the subnet broadcast address."
} catch {
    Write-Log "WARNING: failed to send packet: $($_.Exception.Message)"
} finally {
    $udp.Close()
}
