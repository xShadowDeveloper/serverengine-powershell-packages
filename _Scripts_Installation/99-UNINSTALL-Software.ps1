# Uninstall Software by Display Name
# Single use case: silently remove one MSI-installed application
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$DisplayName = "7-Zip*"   # wildcards allowed, matched against installed display names

$roots = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$apps = Get-ItemProperty $roots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like $DisplayName }

if (-not $apps) {
    Write-Log "No installed software matches '$DisplayName' - nothing to do."
    return
}
if (@($apps).Count -gt 1) {
    Write-Log "Multiple matches for '$DisplayName':"
    foreach ($a in $apps) { Write-Log " - $($a.DisplayName) $($a.DisplayVersion)" }
    Write-Log "Refusing to uninstall more than one product - make the pattern more specific."
    return
}

$app = $apps | Select-Object -First 1
Write-Log "Uninstalling: $($app.DisplayName) $($app.DisplayVersion)..."

if ($app.PSChildName -match "^\{[0-9A-F-]+\}$") {
    # MSI product code -> silent msiexec
    $proc = Start-Process msiexec.exe -ArgumentList "/x $($app.PSChildName) /qn /norestart" -Wait -PassThru
    if ($proc.ExitCode -in @(0, 3010)) {
        Write-Log "Uninstalled successfully (exit: $($proc.ExitCode))$(if ($proc.ExitCode -eq 3010) { ' - reboot required' })."
    } else {
        Write-Log "WARNING: msiexec exited with code $($proc.ExitCode)."
    }
} elseif ($app.QuietUninstallString) {
    Write-Log "Running quiet uninstall string..."
    cmd /c $app.QuietUninstallString
    Write-Log "Quiet uninstall command finished."
} else {
    Write-Log "No silent uninstall available. UninstallString: $($app.UninstallString)"
    Write-Log "Manual/interactive uninstall required - nothing was changed."
}
