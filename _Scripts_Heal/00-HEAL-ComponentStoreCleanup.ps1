# Component Store Cleanup (WinSxS)
# Single use case: reclaim disk space from superseded update components
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$sysDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"
$freeBefore = [math]::Round($sysDrive.FreeSpace / 1GB, 2)
Write-Log "Free space on $env:SystemDrive before cleanup: $freeBefore GB"

Write-Log "Analyzing component store..."
$analysis = & dism.exe /Online /Cleanup-Image /AnalyzeComponentStore 2>&1
$recommended = ($analysis | Select-String "Component Store Cleanup Recommended" | Select-Object -First 1)
if ($recommended) { Write-Log $recommended.ToString().Trim() }

Write-Log "Running StartComponentCleanup (this can take several minutes)..."
$cleanup = & dism.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart 2>&1
if ($cleanup | Select-String "The operation completed successfully") {
    Write-Log "Component store cleanup completed successfully."
} else {
    $err = ($cleanup | Select-String "Error" | Select-Object -First 1)
    Write-Log "Cleanup finished with issues: $(if ($err) { $err.ToString().Trim() } else { 'see DISM log' })"
}

$sysDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"
$freeAfter = [math]::Round($sysDrive.FreeSpace / 1GB, 2)
Write-Log "Free space on $env:SystemDrive after cleanup: $freeAfter GB (reclaimed: $([math]::Round($freeAfter - $freeBefore, 2)) GB)"
