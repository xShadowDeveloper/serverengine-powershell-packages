# Force Group Policy Update
# Single use case: gpupdate /force and report the applied policy state
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

Write-Log "Running gpupdate /force..."
$out = & gpupdate.exe /force 2>&1 | Out-String

if ($out -match "Computer Policy update has completed successfully") {
    Write-Log "Computer policy updated successfully."
} else {
    Write-Log "Computer policy update output: $((($out -split "`n") | Where-Object { $_.Trim() } | Select-Object -First 3) -join ' | ')"
}

# Report last policy application from the OS
$rsop = & gpresult.exe /r /scope:computer 2>&1 | Out-String
$applied = ($rsop -split "`n" | Select-String "Last time Group Policy was applied" | Select-Object -First 1)
if ($applied) { Write-Log $applied.ToString().Trim() }

$gpos = $false
$lines = $rsop -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "Applied Group Policy Objects") {
        Write-Log "================ Applied GPOs ================"
        for ($j = $i + 2; $j -lt $lines.Count; $j++) {
            $entry = $lines[$j].Trim()
            if ([string]::IsNullOrWhiteSpace($entry) -or $entry.StartsWith("The following")) { break }
            if ($entry -match "^-+$") { continue }
            Write-Log " - $entry"
            $gpos = $true
        }
        break
    }
}
if (-not $gpos) { Write-Log "Could not parse applied GPO list from gpresult." }

Write-Log "Group policy update complete."
