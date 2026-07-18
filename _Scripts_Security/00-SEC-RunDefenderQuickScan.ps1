# Run Microsoft Defender Quick Scan
# Single use case: trigger a quick scan and report the findings
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

if (-not (Get-Command Start-MpScan -ErrorAction SilentlyContinue)) {
    Write-Log "Microsoft Defender cmdlets not available on this host."
    return
}

Write-Log "Updating definitions..."
Update-MpSignature -ErrorAction SilentlyContinue
$status = Get-MpComputerStatus
Write-Log "Definitions version: $($status.AntivirusSignatureVersion) ($($status.AntivirusSignatureLastUpdated))"

Write-Log "Starting quick scan (this can take several minutes)..."
Start-MpScan -ScanType QuickScan
Write-Log "Quick scan finished."

$threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
if ($threats) {
    $recent = $threats | Where-Object { $_.InitialDetectionTime -gt (Get-Date).AddHours(-1) }
    if ($recent) {
        Write-Log "WARNING: $(@($recent).Count) threat(s) detected during this scan!"
        foreach ($t in $recent) {
            $threat = Get-MpThreat -ThreatID $t.ThreatID -ErrorAction SilentlyContinue
            Write-Log "THREAT: $(if ($threat) { $threat.ThreatName } else { $t.ThreatID }) - resources: $($t.Resources -join '; ')"
        }
        return
    }
}
Write-Log "No threats detected."
