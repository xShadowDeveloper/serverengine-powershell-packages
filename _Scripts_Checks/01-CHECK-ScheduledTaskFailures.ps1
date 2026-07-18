# Check Scheduled Task Failures
# Single use case: list enabled scheduled tasks whose last run failed
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$IgnorePaths = "\Microsoft\Windows\"   # comma separated path prefixes to skip

$ignoreList = $IgnorePaths -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -ne "Disabled" }

$failedCount = 0
$checked = 0
foreach ($t in $tasks) {
    $skip = $false
    foreach ($prefix in $ignoreList) { if ($t.TaskPath.StartsWith($prefix)) { $skip = $true; break } }
    if ($skip) { continue }

    $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
    if ($null -eq $info) { continue }
    $checked++

    # 0 = success, 0x41303 = never run, 0x41301 = currently running
    if ($info.LastTaskResult -notin @(0, 0x41303, 0x41301) -and $info.LastRunTime) {
        Write-Log "FAILED: [$($t.TaskPath)$($t.TaskName)] result 0x$($info.LastTaskResult.ToString('X')) last run $($info.LastRunTime.ToString('yyyy-MM-dd HH:mm'))"
        $failedCount++
    }
}

if ($failedCount -eq 0) {
    Write-Log "Scheduled task check complete: no failures among $checked task(s)."
} else {
    Write-Log "Scheduled task check complete: $failedCount of $checked task(s) failed on last run!"
}
