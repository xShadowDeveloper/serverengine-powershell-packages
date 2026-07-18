# Repair System Files (SFC + DISM)
# Single use case: verify and repair OS integrity (can take 15+ minutes)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

Write-Log "Running DISM RestoreHealth (this can take a while)..."
$dism = & dism.exe /Online /Cleanup-Image /RestoreHealth /NoRestart 2>&1
$dismResult = ($dism | Select-String "The operation completed successfully|The restore operation completed" | Select-Object -First 1)
if ($dismResult) {
    Write-Log "DISM: component store repaired/verified successfully."
} else {
    $err = ($dism | Select-String "Error" | Select-Object -First 1)
    Write-Log "DISM finished with issues: $(if ($err) { $err.ToString().Trim() } else { 'see CBS.log' })"
}

Write-Log "Running SFC /scannow..."
$sfc = & sfc.exe /scannow 2>&1
$sfcText = ($sfc -join " ") -replace "\x00", ""   # sfc output is UTF-16 mangled when piped

if ($sfcText -match "did not find any integrity violations") {
    Write-Log "SFC: no integrity violations found."
} elseif ($sfcText -match "successfully repaired") {
    Write-Log "SFC: corrupt files found and repaired (details in CBS.log)."
} elseif ($sfcText -match "unable to fix") {
    Write-Log "WARNING: SFC found corrupt files it could NOT fix - check $env:SystemRoot\Logs\CBS\CBS.log"
} else {
    Write-Log "SFC finished - could not parse result, check CBS.log."
}

Write-Log "System file repair sequence complete."
