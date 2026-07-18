# Kill a Hung Process
# Single use case: force-terminate all instances of one named process
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$ProcessName = "notepad"        # without .exe
$OnlyIfNotResponding = $false   # $true = only kill UI processes marked not responding

$procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
if (-not $procs) {
    Write-Log "No running process named '$ProcessName' found - nothing to do."
    return
}

$killed = 0
foreach ($p in $procs) {
    if ($OnlyIfNotResponding -and $p.Responding) {
        Write-Log "Skipping PID $($p.Id) - still responding."
        continue
    }
    $mem = [math]::Round($p.WorkingSet64 / 1MB, 0)
    try {
        Stop-Process -Id $p.Id -Force -ErrorAction Stop
        Write-Log "Killed: $ProcessName PID $($p.Id) (RAM: $mem MB)"
        $killed++
    } catch {
        Write-Log "WARNING: could not kill PID $($p.Id): $($_.Exception.Message)"
    }
}

Write-Log "Process cleanup complete: $killed instance(s) of '$ProcessName' terminated."
