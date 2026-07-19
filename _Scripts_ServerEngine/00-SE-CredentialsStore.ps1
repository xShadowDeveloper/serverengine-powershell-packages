# ServerEngine Credentials Store - Access Username and Password
# How to access credentials: SE-CredentialsStore.Username.(YOUR_CREDENTIAL_FQDN)
# or for the password: SE-CredentialsStore.Password.(YOUR_CREDENTIAL_FQDN)
# ---------------------------------------------------------------------

# Connection settings
$server = "esxi.CForce-IT.network"

# PowerCLI configuration
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Confirm:$false

# Retrieve credentials and convert password to SecureString
$username = SE-CredentialsStore.Username.(esxi.CForce-IT.network)
$password = SE-CredentialsStore.Password.(esxi.CForce-IT.network)
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

# Connect to vCenter/ESXi using credential object
Connect-VIServer -Server $server -Credential $credential

# Get host and its view
$esx     = Get-VMHost
$esxView = Get-View $esx.ID

# --------------------
# Host physical resources
# --------------------
$cpuCores   = $esxView.Hardware.CpuInfo.NumCpuCores
$cpuThreads = $esxView.Hardware.CpuInfo.NumCpuThreads
$memTotalGB = [math]::Round($esx.MemoryTotalMB / 1024, 1)

# --------------------
# VM assigned resources
# --------------------
$vms              = Get-VM | Where-Object { $_.PowerState -eq "PoweredOn" }
$totalCpuAssigned = ($vms | Measure-Object -Property NumCpu -Sum).Sum
$totalMemAssigned = ($vms | Measure-Object -Property MemoryGB -Sum).Sum

# --------------------
# Free resources (can be negative for CPU overcommit)
# --------------------
$cpuFree = $cpuThreads - $totalCpuAssigned
$memFree = $memTotalGB - $totalMemAssigned

# Check provisioning status
$cpuProvisioning = if ($totalCpuAssigned -gt $cpuThreads) { "Overprovisioned" } else { "OK" }
$ramProvisioning = if ($totalMemAssigned -gt $memTotalGB) { "Overprovisioned" } else { "OK" }

# --------------------
# Output Host Summary
# --------------------
Write-Host ""
Write-Host "<WRITE-LOG = ""*================== Host Resource Summary ==================*"">"
Write-Host "<WRITE-LOG = ""*Host: $($esx.Name)*"">"
Write-Host "<WRITE-LOG = ""*CPU: State: $($cpuProvisioning.PadRight(15)) *"">"
Write-Host "<WRITE-LOG = ""*RAM: State: $($ramProvisioning.PadRight(15)) *"">"
Write-Host "<WRITE-LOG = ""*Available:[$($cpuThreads.ToString().PadLeft(3)) vCPUs ] Assigned:[$($totalCpuAssigned.ToString().PadLeft(3)) vCPUs ] Free:[$($cpuFree.ToString().PadLeft(3)) vCPUs ]*"">"
Write-Host "<WRITE-LOG = ""*Available:[$($memTotalGB.ToString().PadLeft(6)) GB ] Assigned:[$($totalMemAssigned.ToString().PadLeft(6)) GB ] Free:[$($memFree.ToString().PadLeft(6)) GB ]*"">"

# --------------------
# Per-VM Assigned Resources
# --------------------
Write-Host "<WRITE-LOG = ""*================== VM Assigned Resources ==================*"">"
$vms | ForEach-Object {
    Write-Host "<WRITE-LOG = ""*vCPUs: [$($_.NumCpu.ToString().PadLeft(2)) ] RAM: [$($_.MemoryGB.ToString().PadLeft(3)) GB ] VM: $($_.Name)*"">"
}

# --------------------
# Disconnect
# --------------------
Disconnect-VIServer -Server $server -Confirm:$false

# SIG # Begin signature block
# MIIc1QYJKoZIhvcNAQcCoIIcxjCCHMICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6LR4eGGtFAj3HC2FEmB8pqXU
# sZqgghdDMIIEBTCCAu2gAwIBAgITFAAAAAIukB1TwGOSTQAAAAAAAjANBgkqhkiG
# 9w0BAQsFADAaMRgwFgYDVQQDEw9TZXJ2ZXJFbmdpbmUtQ0EwHhcNMjYwMzIxMTAw
# NDU4WhcNMjcwMzIxMTAxNDU4WjA/MRkwFwYDVQQDExBTZXJ2ZXJFbmdpbmUgTExD
# MSIwIAYJKoZIhvcNAQkBFhNjZW9Ac2VydmVyZW5naW5lLmNvMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs0CxL4QDnvoOI5CnSDWEYLe8WdMUb6lrJ7XM
# aCDo4F7X8qDT+1w9hQrh4kNljlbowSS1jlEwK3to75fpRljDzDGN6a6cm0WUW49c
# dL8iK3U/ryrBUjbf2Ln8o1Gs7wcwabK1c28u1p9TJBrNgkd4RImnlHoysOS5RbdS
# 2aakN+nrAa9K70ak72MSZVM9DMe1tzeWBs1LZ78hA8MC3KncRn6HpqrMvPz5gUZm
# 2SQJ/LEwrdjI4mVUX9P7CGkipfGJiWMDzh5cM1wf1/QhoGvr8sCjy5Y67HaA/cOD
# TU1yN5QUn5VH9kGAD9/JDG64CyI1GNVrjsCGXhXaT4llm53tIQIDAQABo4IBHTCC
# ARkwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMDMB0GA1Ud
# DgQWBBTi3EGZG11SOoD+soLbyLIqMnOwUzAfBgNVHSMEGDAWgBStSs/V0ivjZHyV
# iFt4ptEbhKzQhTBEBgNVHR8EPTA7MDmgN6A1hjNmaWxlOi8vLy9XSU4tU1JWLUFa
# MS9DZXJ0RW5yb2xsL1NlcnZlckVuZ2luZS1DQS5jcmwwWwYIKwYBBQUHAQEETzBN
# MEsGCCsGAQUFBzAChj9maWxlOi8vLy9XSU4tU1JWLUFaMS9DZXJ0RW5yb2xsL1dJ
# Ti1TUlYtQVoxX1NlcnZlckVuZ2luZS1DQS5jcnQwDAYDVR0TAQH/BAIwADANBgkq
# hkiG9w0BAQsFAAOCAQEAV+xG1rHc8K79QN7jQZviYjgj8/Ca7S/htlJ5PCZYFEkZ
# nmALbuIbgFB4QQXwaCy9CxwJpsI0LQQIWNc27c1xuteuHIFIMdC5NPQ8ENR+n0h/
# 7T3Xtr/poGgOO6na7vGHKKZioXGhzM0pqurXK2rbyaKCwjxP1KRSri0IzDzRA/k4
# zbeBHNxIGpvSYK+eQWd7fbhY9U8fIO412YB0/0RheNg5qwfyTPNR3GPj0AkXTYLq
# GuKZW798r//N8iSHeS0B8ODOS8Q7g+TZUO/FGGjpdwIcLjpTGxzIWXVMaklUx7Mw
# 33TClGHbymLXZPo3ORlqrWe5Ii2h+245H5Qx7HN+nzCCBY0wggR1oAMCAQICEA6b
# GI750C3n79tQ4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEk
# MCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAw
# MDAwMFoXDTMxMTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERp
# Z2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMY
# RGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAv+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2u
# exuEDcQwH/MbpDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKv
# aJNwwrK6dZlqczKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/gh
# YZs06wXGXuxbGrzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOt
# yU9e5TXnMcvak17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCR
# cKtVgkEy19sEcypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8
# oU85tRFYF/ckXEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m
# 1O+SkjqePdwA5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y
# 1YxwLEFgqrFjGESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkl
# iWzlDlJRR3S+Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/E
# IFFrb7GrhotPwtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOC
# ATowggE2MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/n
# upiuHA9PMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB
# /wQEAwIBhjB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqg
# OKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEA
# cKC/Q1xV5zhfoKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU
# 9BNKei8ttzjv9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0Sb
# QyHrlnKhSLSZy51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1Rmpp
# VLC4oVaO7KTVPeix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxY
# oA5AY8WYIsGyWfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0Vys
# GMNNn3O3AamfV6peKOK5lDCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYw
# DQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNl
# cnQgVHJ1c3RlZCBSb290IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1
# OVowaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYD
# VQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNI
# QTI1NiAyMDI1IENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4
# MdMKmEFyvjxGwBysddujRmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6
# c+Gh/qm8Xi4aPCOo2N8S9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3
# SYDEAd4dg2dDGpeZGKe+42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVST
# EG8yAR2CQWIM1iI5PHg62IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpq
# umzTCNSOxm+SAWSuIr21Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJ
# yUXzdtFUUt4aS4CEeIY8y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/Gcal
# NeJQ55IuwnKCgs+nrpuQNfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8A
# w4wJkhU1JrPsFfxW1gaou30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/n
# J0+k6MvqzfpzPDOy5y6gqztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA
# 6tQbZl1KhBtTasySkuJDpsZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2ba
# oD6x0VR4RjSpWM8o5a6D8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNV
# HRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAf
# BgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMG
# A1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG
# /WwHATANBgkqhkiG9w0BAQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCH
# xYgaMH9Pw5tcBnPw6O6FTGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdh
# OP4hCFATuNT+ReOPK0mCefSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDC
# vwzJv2sRUoKEfJ+nN57mQfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B
# 0ba2H3LUiwDRAXx1Neq9ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWG
# NqNX+DF0SQzHU0pTi4dBwp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRN
# ivYuve3L2oiKNqetRHdqfMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02Oo
# XN4bFzK0vlNMsvhlqgF2puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy
# 4kbu4QFhOm0xJuF2EZAOk5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2w
# L40mm53+/j7tFaxYKIqL0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQt
# yRN62JK4S1C8uw3PdBunvAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2
# zNaQ9k+5t1wwggbtMIIE1aADAgECAhAKgO8YS43xBYLRxHanlXRoMA0GCSqGSIb3
# DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5
# NiBTSEEyNTYgMjAyNSBDQTEwHhcNMjUwNjA0MDAwMDAwWhcNMzYwOTAzMjM1OTU5
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNV
# BAMTMkRpZ2lDZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFtcCBSZXNwb25kZXIg
# MjAyNSAxMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0EasLRLGntDq
# rmBWsytXum9R/4ZwCgHfyjfMGUIwYzKomd8U1nH7C8Dr0cVMF3BsfAFI54um8+dn
# xk36+jx0Tb+k+87H9WPxNyFPJIDZHhAqlUPt281mHrBbZHqRK71Em3/hCGC5Kyyn
# eqiZ7syvFXJ9A72wzHpkBaMUNg7MOLxI6E9RaUueHTQKWXymOtRwJXcrcTTPPT2V
# 1D/+cFllESviH8YjoPFvZSjKs3SKO1QNUdFd2adw44wDcKgH+JRJE5Qg0NP3yiSy
# i5MxgU6cehGHr7zou1znOM8odbkqoK+lJ25LCHBSai25CFyD23DZgPfDrJJJK77e
# pTwMP6eKA0kWa3osAe8fcpK40uhktzUd/Yk0xUvhDU6lvJukx7jphx40DQt82yep
# yekl4i0r8OEps/FNO4ahfvAk12hE5FVs9HVVWcO5J4dVmVzix4A77p3awLbr89A9
# 0/nWGjXMGn7FQhmSlIUDy9Z2hSgctaepZTd0ILIUbWuhKuAeNIeWrzHKYueMJtIt
# nj2Q+aTyLLKLM0MheP/9w6CtjuuVHJOVoIJ/DtpJRE7Ce7vMRHoRon4CWIvuiNN1
# Lk9Y+xZ66lazs2kKFSTnnkrT3pXWETTJkhd76CIDBbTRofOsNyEhzZtCGmnQigpF
# Hti58CSmvEyJcAlDVcKacJ+A9/z7eacCAwEAAaOCAZUwggGRMAwGA1UdEwEB/wQC
# MAAwHQYDVR0OBBYEFOQ7/PIx7f391/ORcWMZUEPPYYzoMB8GA1UdIwQYMBaAFO9v
# U0rp5AZ8esrikFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAK
# BggrBgEFBQcDCDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5
# NlNIQTI1NjIwMjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQw
# OTZTSEEyNTYyMDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgB
# hv1sBwEwDQYJKoZIhvcNAQELBQADggIBAGUqrfEcJwS5rmBB7NEIRJ5jQHIh+OT2
# Ik/bNYulCrVvhREafBYF0RkP2AGr181o2YWPoSHz9iZEN/FPsLSTwVQWo2H62yGB
# vg7ouCODwrx6ULj6hYKqdT8wv2UV+Kbz/3ImZlJ7YXwBD9R0oU62PtgxOao872bO
# ySCILdBghQ/ZLcdC8cbUUO75ZSpbh1oipOhcUT8lD8QAGB9lctZTTOJM3pHfKBAE
# cxQFoHlt2s9sXoxFizTeHihsQyfFg5fxUFEp7W42fNBVN4ueLaceRf9Cq9ec1v5i
# QMWTFQa0xNqItH3CPFTG7aEQJmmrJTV3Qhtfparz+BW60OiMEgV5GWoBy4RVPRwq
# xv7Mk0Sy4QHs7v9y69NBqycz0BZwhB9WOfOu/CIJnzkQTwtSSpGGhLdjnQ4eBpjt
# P+XB3pQCtv4E5UCSDag6+iX8MmB10nfldPF9SVD7weCC3yXZi/uuhqdwkgVxuiMF
# zGVFwYbQsiGnoa9F5AaAyBjFBtXVLcKtapnMG3VH3EmAp/jsJ3FVF3+d1SVDTmjF
# jLbNFZUWMXuZyvgLfgyPehwJVxwC+UpX2MSey2ueIu9THFVkT+um1vshETaWyQo8
# gmBto/m3acaP9QsuLj3FNwFlTxq25+T4QwX9xa6ILs84ZPvmpovq90K8eWyG2N01
# c4IhSOxqt81nMYIE/DCCBPgCAQEwMTAaMRgwFgYDVQQDEw9TZXJ2ZXJFbmdpbmUt
# Q0ECExQAAAACLpAdU8Bjkk0AAAAAAAIwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcC
# AQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYB
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLxcjR/VU+AF
# 3CBswPfPkPsUL0EbMA0GCSqGSIb3DQEBAQUABIIBACKCL7ccc51oMD1CxqjwIvOO
# 0+p5oDnL0LrXql+EhHlGgKr1S4hU8QutXtPXcMWwsd2X5hGKIvzY+szc0J6OPWtN
# uQofg/ce7rreBYQSV2SU8FhkdoTB7aN5DUF9bWnpMcyEXQEzm/9ykJ1TXSv+c3eT
# XeKcH4sFrRf7UQ2ffX0AOHPcztyyNGzCQ01SOjViq+YdXEFjw5mVZ5jXr0rRGN+3
# BTJeiDLVqo9EI55sOPj+Drcab5WkkaJv8hs7IaIGECeX/1aFBtICmMI+NZJj9qbW
# NFpcK+4WLeSoQqbDa/lg5tyJBNZXQJpbK51+wPoOksu6FpMiGx/YViMAwVtCsiWh
# ggMmMIIDIgYJKoZIhvcNAQkGMYIDEzCCAw8CAQEwfTBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExAhAKgO8Y
# S43xBYLRxHanlXRoMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqG
# SIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjYwNzE5MDAyNjI4WjAvBgkqhkiG9w0B
# CQQxIgQgr3Ogqvirpw+MksR0s4qDansh61IPIVibEeoP/Jp70x4wDQYJKoZIhvcN
# AQEBBQAEggIArBXDLE+LHOGrN8GzC9XvLrN5/4huJ0OLRXqWNn/+3Od4NeNTlxlC
# 7D3u6uk+pmuGiH+zJq6sUGKiRhYoVdSD20YaTef6sJq3xP9XDVV23R254qUN4hQ0
# mMrNSBYXUVJ5divKUyaePibsnyG2iRGft4xwzYrE+Gb0IpVITz7q1vvP4mYam7NP
# TSyl+ENK+kP8v2zPTveH2ubLKCrDZZRaVPIDeGkw5CgOiDylxjodQ73T8hKqrXbN
# 0oSE9LkV1E7fRf6EZrL/UR0X/noHFb18XcPjsguEgvsavgCivGOp70Hm7EUgJzeU
# cZc7aM/JkELxeqA4nGs2sKvCVmkb3puzB6tVbUyQWYLk5aPrYrCEAilhP3cS5Fsl
# QjjGNYKsXvarQkw+45nGgyn1vuXp/OkEq25LEmxiHor6Y2KzdI6Zs1IjGnRGobLE
# mvoqPBpRKRMuuqO8rnrj1ura4wWzfHG3eeKdn83MqyJO+lxXdcgOF1eO4ldO1BnW
# O9xQc7qMuGiUoCuje6BK7ochWuBAhQHR+pngjaVU+18aE44VOtFpZLMB9b3nbGiF
# VYUZZnd0WbVoE9SsBIk9Zv3ObhS+uTm2nVAl5XugWqWF7OzSGZGyCtXN5DkIZ/Oh
# 5usxj5npn5dAXuruy/+HWCtBL/ma/C7JNn80vZM9kY+ZJyYSFH3U3oY=
# SIG # End signature block
