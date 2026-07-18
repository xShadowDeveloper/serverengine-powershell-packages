# Windows License Activation Status
# Single use case: report activation state of the OS license
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# LicenseStatus: 0=Unlicensed 1=Licensed 2=OOBGrace 3=OOTGrace 4=NonGenuineGrace 5=Notification 6=ExtendedGrace
$statusNames = @{
    0 = "Unlicensed"; 1 = "Licensed (activated)"; 2 = "OOB grace period";
    3 = "OOT grace period"; 4 = "Non-genuine grace"; 5 = "Notification (NOT activated)"; 6 = "Extended grace"
}

$products = Get-CimInstance SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "Windows*" }

if (-not $products) {
    Write-Log "No Windows license with a product key found!"
    return
}

foreach ($p in $products) {
    $state = if ($statusNames.ContainsKey([int]$p.LicenseStatus)) { $statusNames[[int]$p.LicenseStatus] } else { "Unknown ($($p.LicenseStatus))" }
    Write-Log "Product: $($p.Name)"
    Write-Log "Channel: $($p.ProductKeyChannel) | Partial key: *$($p.PartialProductKey)"
    Write-Log "Status: $state"

    if ($p.LicenseStatus -eq 1) {
        if ($p.GracePeriodRemaining -gt 0) {
            $days = [math]::Round($p.GracePeriodRemaining / 1440, 0)
            Write-Log "Rearm/KMS window remaining: $days day(s)"
        }
        Write-Log "License check complete: Windows is activated."
    } else {
        Write-Log "WARNING: Windows is NOT properly activated!"
    }
}
