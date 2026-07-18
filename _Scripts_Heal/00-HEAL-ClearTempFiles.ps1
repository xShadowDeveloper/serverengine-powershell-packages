# Clear Temp Files
# Single use case: delete old files from the system temp locations
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$OlderThanDays = 7

$cutoff = (Get-Date).AddDays(-[int]$OlderThanDays)
$targets = @("$env:SystemRoot\Temp", "$env:TEMP") | Select-Object -Unique

$totalFiles = 0
$totalMB = 0
foreach ($dir in $targets) {
    if (-not (Test-Path $dir)) { continue }

    $files = Get-ChildItem $dir -Recurse -File -Force -ErrorAction SilentlyContinue |
             Where-Object { $_.LastWriteTime -lt $cutoff }
    $sizeMB = [math]::Round((($files | Measure-Object Length -Sum).Sum) / 1MB, 1)
    Write-Log "[$dir] deleting $(@($files).Count) file(s) older than $OlderThanDays days ($sizeMB MB)..."

    $deleted = 0
    foreach ($f in $files) {
        try { Remove-Item $f.FullName -Force -ErrorAction Stop; $deleted++ } catch {}
    }
    Write-Log "[$dir] deleted: $deleted (locked files are skipped)"
    $totalFiles += $deleted
    $totalMB += $sizeMB
}

Write-Log "Temp cleanup complete: $totalFiles file(s), ~$totalMB MB reclaimed."
