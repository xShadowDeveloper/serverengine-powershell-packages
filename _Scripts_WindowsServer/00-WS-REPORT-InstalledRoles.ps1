# Report Installed Server Roles and Features
# Single use case: list what this server actually does
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

if (-not (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)) {
    Write-Log "Get-WindowsFeature not available (client OS?)."
    return
}

$installed = Get-WindowsFeature | Where-Object { $_.Installed }
$roles     = $installed | Where-Object { $_.FeatureType -eq "Role" }
$features  = $installed | Where-Object { $_.FeatureType -eq "Feature" -and $_.Depth -le 2 }

Write-Log "================ Roles ($(@($roles).Count)) ================"
foreach ($r in $roles) {
    Write-Log "[$($r.Name)] $($r.DisplayName)"
}

Write-Log "================ Top-level Features ($(@($features).Count)) ================"
foreach ($f in $features) {
    Write-Log "[$($f.Name)] $($f.DisplayName)"
}

Write-Log "Role report complete: $(@($roles).Count) role(s), $(@($installed).Count) installed component(s) total."

# Pass role names to the next runbook script
$store = (($roles | ForEach-Object { $_.Name }) -join ",")
