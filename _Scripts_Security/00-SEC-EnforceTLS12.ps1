# Enforce TLS 1.2+ (disable SSL 2.0/3.0, TLS 1.0/1.1)
# Single use case: schannel protocol hardening for server + client roles
# NOTE: changes take effect after the next reboot.
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

$base = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"

function Set-Protocol {
    param($Protocol, [bool]$Enable)
    foreach ($role in @("Server", "Client")) {
        $path = "$base\$Protocol\$role"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        if ($Enable) {
            Set-ItemProperty -Path $path -Name "Enabled" -Value 1 -Type DWord
            Set-ItemProperty -Path $path -Name "DisabledByDefault" -Value 0 -Type DWord
        } else {
            Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $path -Name "DisabledByDefault" -Value 1 -Type DWord
        }
    }
}

foreach ($old in @("SSL 2.0", "SSL 3.0", "TLS 1.0", "TLS 1.1")) {
    Set-Protocol -Protocol $old -Enable $false
    Write-Log "$old disabled (server + client)."
}
foreach ($new in @("TLS 1.2", "TLS 1.3")) {
    Set-Protocol -Protocol $new -Enable $true
    Write-Log "$new enabled (server + client)."
}

# Make .NET Framework applications use the OS defaults (strong crypto)
foreach ($net in @("HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319",
                   "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319")) {
    if (Test-Path $net) {
        Set-ItemProperty -Path $net -Name "SchUseStrongCrypto" -Value 1 -Type DWord
        Set-ItemProperty -Path $net -Name "SystemDefaultTlsVersions" -Value 1 -Type DWord
    }
}
Write-Log ".NET Framework strong crypto enforced."

Write-Log "TLS hardening written - a REBOOT is required to apply (chain 02-SE-ManagedReboot.ps1)."
Write-Log "WARNING: legacy clients that only speak TLS 1.0/1.1 will fail to connect afterwards."
$store = "RebootPending"
