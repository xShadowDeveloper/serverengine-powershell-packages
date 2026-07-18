# Check Pending Reboot
# Single use case: report whether the server requires a restart and why
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$reasons = @()

if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
    $reasons += "Component Based Servicing (Windows features/updates)"
}
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
    $reasons += "Windows Update"
}
$pfro = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
if ($pfro -and $pfro.PendingFileRenameOperations) {
    $reasons += "Pending file rename operations"
}
$computerRename = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -ErrorAction SilentlyContinue
$pendingRename  = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -ErrorAction SilentlyContinue
if ($computerRename -and $pendingRename -and ($computerRename.ComputerName -ne $pendingRename.ComputerName)) {
    $reasons += "Computer rename pending"
}

if ($reasons.Count -eq 0) {
    Write-Log "No reboot pending - system is clean."
    $store = "NoRebootPending"
} else {
    Write-Log "REBOOT PENDING! Reasons:"
    foreach ($r in $reasons) { Write-Log " - $r" }
    # Next runbook script can react (ex. 02-SE-ManagedReboot.ps1)
    $store = "RebootPending"
}
