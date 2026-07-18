# Install PowerShell 7 (side by side with 5.1)
# Single use case: silent MSI install of the latest stable PowerShell 7
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$existing = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if ($existing) {
    $v = & $existing.Source -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
    Write-Log "PowerShell 7 is already installed (version $v) - nothing to do."
    return
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Log "Resolving latest stable release from GitHub..."
$release = Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -UseBasicParsing
$asset = $release.assets | Where-Object { $_.name -like "PowerShell-*-win-x64.msi" } | Select-Object -First 1
if ($null -eq $asset) { Write-Log "Could not find a win-x64 MSI in the latest release!"; return }

$msi = Join-Path $env:TEMP $asset.name
Write-Log "Downloading $($asset.name) ($([math]::Round($asset.size / 1MB, 1)) MB)..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $msi -UseBasicParsing

Write-Log "Installing silently..."
$proc = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart ADD_PATH=1" -Wait -PassThru
Remove-Item $msi -Force -ErrorAction SilentlyContinue

if ($proc.ExitCode -eq 0) {
    Write-Log "PowerShell 7 ($($release.tag_name)) installed successfully."
} elseif ($proc.ExitCode -eq 3010) {
    Write-Log "PowerShell 7 installed - reboot required to finish."
} else {
    Write-Log "WARNING: msiexec exited with code $($proc.ExitCode)."
}
