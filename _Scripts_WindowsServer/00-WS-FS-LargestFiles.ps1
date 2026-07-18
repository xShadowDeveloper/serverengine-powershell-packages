# Find Largest Files
# Single use case: list the top N biggest files under a path (disk space hunts)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$SearchPath = "C:\"
$TopCount   = 20

if (-not (Test-Path $SearchPath)) {
    Write-Log "Path not found: $SearchPath"
    return
}

Write-Log "Scanning $SearchPath for the $TopCount largest files (this can take a while)..."

$files = Get-ChildItem $SearchPath -Recurse -File -Force -ErrorAction SilentlyContinue |
         Sort-Object Length -Descending |
         Select-Object -First ([int]$TopCount)

if (-not $files) { Write-Log "No files found under $SearchPath."; return }

Write-Log "================ Top $TopCount Files ================"
foreach ($f in $files) {
    $gb = [math]::Round($f.Length / 1GB, 2)
    Write-Log "[$($gb.ToString().PadLeft(8)) GB] $($f.FullName)"
}

Write-Log "Largest-file scan complete."
