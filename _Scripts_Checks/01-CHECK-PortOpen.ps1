# Check Remote Port
# Single use case: test TCP reachability of one port on one host
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$TargetHost = "127.0.0.1"
$TargetPort = 443
$TimeoutMs  = 3000

Write-Log "Testing TCP ${TargetHost}:${TargetPort} (timeout ${TimeoutMs}ms)..."

$client = New-Object System.Net.Sockets.TcpClient
try {
    $async = $client.BeginConnect($TargetHost, [int]$TargetPort, $null, $null)
    $connected = $async.AsyncWaitHandle.WaitOne([int]$TimeoutMs, $false)

    if ($connected -and $client.Connected) {
        Write-Log "OK: ${TargetHost}:${TargetPort} is reachable."
        $store = "PortOpen"
    } else {
        Write-Log "CLOSED: ${TargetHost}:${TargetPort} did not answer within ${TimeoutMs}ms."
        $store = "PortClosed"
    }
} catch {
    Write-Log "CLOSED: ${TargetHost}:${TargetPort} - $($_.Exception.Message)"
    $store = "PortClosed"
} finally {
    $client.Close()
}
