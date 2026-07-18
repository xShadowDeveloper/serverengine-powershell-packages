# Clear Stuck Print Queue
# Single use case: stop spooler, purge stuck jobs, start spooler
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
if ($null -eq $spooler) {
    Write-Log "Print Spooler service not found on this host."
    return
}

$queueDir = "$env:SystemRoot\System32\spool\PRINTERS"
$stuck = @(Get-ChildItem $queueDir -File -ErrorAction SilentlyContinue)
Write-Log "Stuck spool files found: $($stuck.Count)"

if ($stuck.Count -eq 0) {
    Write-Log "Print queue is already clean - spooler untouched."
    return
}

Write-Log "Stopping Print Spooler..."
Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
Start-Sleep 2

$stuck | Remove-Item -Force -ErrorAction SilentlyContinue
$left = @(Get-ChildItem $queueDir -File -ErrorAction SilentlyContinue).Count
Write-Log "Spool files removed: $($stuck.Count - $left) (remaining: $left)"

Write-Log "Starting Print Spooler..."
Start-Service -Name Spooler -ErrorAction SilentlyContinue
Start-Sleep 2

$spooler = Get-Service -Name Spooler
if ($spooler.Status -eq "Running") {
    Write-Log "Print queue cleared and spooler running again."
} else {
    Write-Log "WARNING: spooler is $($spooler.Status) after cleanup!"
}
