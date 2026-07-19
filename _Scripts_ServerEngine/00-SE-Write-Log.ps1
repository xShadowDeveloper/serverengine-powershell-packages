# Gather Useful Computer Information
#-----------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

Write-Log "Starting Computer Information Collection"

# OS Information
Write-Log "--- Operating System ---"
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Log "OS Name: $($osInfo.Caption)"
Write-Log "OS Version: $($osInfo.Version)"
Write-Log "OS Build: $($osInfo.BuildNumber)"
Write-Log "Architecture: $($osInfo.OSArchitecture)"
Write-Log "Install Date: $($osInfo.InstallDate)"
Write-Log "Last Boot Time: $($osInfo.LastBootUpTime)"
Write-Log "System Directory: $($osInfo.SystemDirectory)"

# System (Computer) Info
Write-Log "--- System ---"
$sysInfo = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Log "Computer Name: $($sysInfo.Name)"
Write-Log "Domain: $($sysInfo.Domain)"
Write-Log "Role: $($sysInfo.Roles -join ', ')"
Write-Log "System Type: $($sysInfo.SystemType)"
Write-Log "Manufacturer: $($sysInfo.Manufacturer)"
Write-Log "Model: $($sysInfo.Model)"

# BIOS Serial Number (separate query to ensure accuracy)
Write-Log "--- System Serial ---"
$serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
Write-Log "Serial Number: $serial"

# CPU
Write-Log "--- Processor ---"
$cpu = Get-CimInstance -ClassName Win32_Processor
Write-Log "Name: $($cpu.Name)"
Write-Log "Manufacturer: $($cpu.Manufacturer)"
Write-Log "Cores: $($cpu.NumberOfCores)"
Write-Log "Logical Processors: $($cpu.NumberOfLogicalProcessors)"
Write-Log "Max Clock Speed: $($cpu.MaxClockSpeed) MHz"

# Memory
Write-Log "--- Memory (RAM) ---"
$mem = Get-CimInstance -ClassName Win32_PhysicalMemory
$totalGB = ($mem | Measure-Object -Property Capacity -Sum).Sum / 1GB
Write-Log "Total RAM: $([math]::Round($totalGB, 1)) GB"
Write-Log "Modules Installed: $($mem.Count)"

# Disk (C: only, as representative)
Write-Log "--- Disk (C:) ---"
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
Write-Log "Drive: C:\"
Write-Log "Size: $([math]::Round($disk.Size / 1GB, 1)) GB"
Write-Log "Free Space: $([math]::Round($disk.FreeSpace / 1GB, 1)) GB"
Write-Log "File System: $($disk.FileSystem)"
Write-Log "Volume Label: $($disk.VolumeName)"

# BIOS Details
Write-Log "--- BIOS ---"
$bios = Get-CimInstance -ClassName Win32_BIOS
Write-Log "Vendor: $($bios.SMBIOSBIOSVendor)"
Write-Log "Version: $($bios.SMBIOSBIOSVersion)"
Write-Log "Release Date: $($bios.ReleaseDate)"

# Network (first enabled adapter)
Write-Log "--- Network (IPv4) ---"
$net = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } | Select-Object -First 1
if ($net) {
    Write-Log "MAC Address: $($net.MACAddress)"
    Write-Log "IP Address: $(if ($net.IPAddress) { $net.IPAddress -join ', ' } else { 'None' })"
    Write-Log "Default Gateway: $(if ($net.DefaultIPGateway) { $net.DefaultIPGateway -join ', ' } else { 'None' })"
} else {
    Write-Log "No active IPv4 network adapters found"
}

Write-Log "Computer Information Collection Complete"

# SIG # Begin signature block
# MIIc1QYJKoZIhvcNAQcCoIIcxjCCHMICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4/jiQ8sAEfDfMAgdDsSX3sdt
# 8mqgghdDMIIEBTCCAu2gAwIBAgITFAAAAAIukB1TwGOSTQAAAAAAAjANBgkqhkiG
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
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAhxJ857zGCz
# OPiGkxPKho6SH91dMA0GCSqGSIb3DQEBAQUABIIBAKBI2aLlQQSq1IWTCeg6ULV2
# HpcUFRwCFx8MBcSqKkV7aZAkZCtwNEgAWaf1BLS/0GkZJRjJDDbgVfVBw715D4NN
# NAUwW4nxxPTJKvSS+1NcFaqpeuWNABQfcY6c9QI+0m6tOh4sgih4OaNuTu2LspBs
# XkKmLKIkXhGuy/LkJ+tue3rlmqpzxmtbPos7kNp6c1+lQRAlQjX5oDtSxG8WVAaM
# WTBGJozNpHqOmH4Qfs4qC8unupW85XldxetOzs0n257zhGs4PE0tKJNd4/OCnMHY
# bcZQuQJtRKD3qB+4yzGDAecjKFvmb0wLwMrmQ+657VQBCgcTZZYMMgDYZtHoBZSh
# ggMmMIIDIgYJKoZIhvcNAQkGMYIDEzCCAw8CAQEwfTBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExAhAKgO8Y
# S43xBYLRxHanlXRoMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqG
# SIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjYwNzE5MDAyNjExWjAvBgkqhkiG9w0B
# CQQxIgQg0q6m14uEdc4vnyOAa7DuYE95OQcSOowwIxjLmpTlpgcwDQYJKoZIhvcN
# AQEBBQAEggIAqCWn3qzXgqObH4pDrgtKGbp1/3NhG/GGs9ktxqdVuGPK1B+lce1Y
# XoNshLnBSHgnifSazZC6R3KRZPuMM7AkYcYg/WLa1kMuAbNeKA+sPjIr94C8KS7o
# 2pY9PxEX0e5O1pnGmP2Bcfxuvee10ruv+ElbchbUdnuJw8cBmGwrdtnhAsHCV3Bg
# sbOUJhyO4Ril3P8Spm/al1IhWoM3GfgERSME+NXznMunXQD5UErJHv8Gn4NAYoUK
# OZiZ0du0JgBH/ho8MfjHPBUzlKl0cQcIWze7r/D6v/e+IZZHzpwas75+euzHxxXl
# axThm3uA0CCMnWCjDesSTVMviTpEyUo3viOzG82+Ehl8rLmMmqMNRTwGSJ1QMyBt
# ku9u/SvI+G1Sft8CrL/OPIDTfTbgwLG1ivtOVyLijpoWBbkmRkjRebKwXVQTwDHD
# 9dMRahflO9Hs3/Ng4Hco4LZI7oi/yDJd00gVxSCF3Q1vpdFbZRzz/gUGQIJSXsUS
# nJBHVuWIGa9jbdbTGiYc+fzAw12JtJAsUxRNo2vvOwgmTFwhUJq+4kASz0YzT7pz
# bNPbEBSpfvml2Dok2nA8t7OdutmtkB3l6DLVsoMEN8PwudlW3wNzFi6GX/6zw1QA
# UgxubCt5O/OLLbyGGjuT8Xfzi3X6uSagKghkI7J3SCinv1WDlzwiZc8=
# SIG # End signature block
