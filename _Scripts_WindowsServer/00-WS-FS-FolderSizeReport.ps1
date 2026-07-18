# Folder Size Report
# Single use case: report the size of each first-level folder under a path
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$SearchPath = "C:\"

if (-not (Test-Path $SearchPath)) {
    Write-Log "Path not found: $SearchPath"
    return
}

Write-Log "Measuring first-level folders under $SearchPath (this can take a while)..."

$results = foreach ($dir in (Get-ChildItem $SearchPath -Directory -Force -ErrorAction SilentlyContinue)) {
    $bytes = (Get-ChildItem $dir.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
              Measure-Object Length -Sum).Sum
    [pscustomobject]@{ Folder = $dir.FullName; GB = [math]::Round(($bytes / 1GB), 2) }
}

if (-not $results) { Write-Log "No folders found under $SearchPath."; return }

Write-Log "================ Folder Sizes ================"
foreach ($r in ($results | Sort-Object GB -Descending)) {
    Write-Log "[$($r.GB.ToString().PadLeft(9)) GB] $($r.Folder)"
}

$total = [math]::Round(($results | Measure-Object GB -Sum).Sum, 2)
Write-Log "Folder size report complete: $total GB in $(@($results).Count) folder(s)."
