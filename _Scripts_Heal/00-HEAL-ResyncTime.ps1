# Resync System Time
# Single use case: force an NTP resync (fix Kerberos/clock-skew issues)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$svc = Get-Service -Name W32Time -ErrorAction SilentlyContinue
if ($null -eq $svc) { Write-Log "W32Time service not found!"; return }

if ($svc.Status -ne "Running") {
    Write-Log "W32Time is $($svc.Status) - starting..."
    Start-Service -Name W32Time -ErrorAction SilentlyContinue
    Start-Sleep 2
}

Write-Log "Time before resync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$out = w32tm /resync /force 2>&1 | Out-String
if ($out -match "completed successfully") {
    Write-Log "Time resync completed successfully."
} else {
    Write-Log "Resync result: $($out.Trim())"
    Write-Log "If this failed, check the NTP source with 01-CHECK-TimeSync.ps1."
}

$source = (w32tm /query /source 2>&1 | Out-String).Trim()
Write-Log "Current time source: $source"
Write-Log "Time after resync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
