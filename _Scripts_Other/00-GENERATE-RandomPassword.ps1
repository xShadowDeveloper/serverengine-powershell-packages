# Generate a Random Password
# Single use case: create a strong password and hand it to the next
# runbook script via $store (ex. chain with 00-AD-USER-ResetPassword.ps1)
#-----------------------------------------------------------------

function Write-Log {
    param($Message)
    Write-Host "<WRITE-LOG = `"*$Message*`">"
}

# --- Parameters (replace via ServerEngine API parameters if needed) ---
$Length = 16

$lower   = "abcdefghijkmnopqrstuvwxyz"   # no l
$upper   = "ABCDEFGHJKLMNPQRSTUVWXYZ"    # no I/O
$digits  = "23456789"                    # no 0/1
$symbols = "!#%+-=?@"

$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
function Get-RandomChar([string]$set) {
    $bytes = New-Object byte[] 4
    $rng.GetBytes($bytes)
    $set[([BitConverter]::ToUInt32($bytes, 0) % $set.Length)]
}

# guarantee one of each class, fill the rest from the full set
$all = $lower + $upper + $digits + $symbols
$chars = @((Get-RandomChar $lower), (Get-RandomChar $upper), (Get-RandomChar $digits), (Get-RandomChar $symbols))
while ($chars.Count -lt [int]$Length) { $chars += Get-RandomChar $all }

# shuffle (Fisher-Yates with crypto RNG)
for ($i = $chars.Count - 1; $i -gt 0; $i--) {
    $bytes = New-Object byte[] 4
    $rng.GetBytes($bytes)
    $j = [BitConverter]::ToUInt32($bytes, 0) % ($i + 1)
    $tmp = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $tmp
}
$password = -join $chars
$rng.Dispose()

Write-Log "Generated a $Length character password (stored in `$store for the next script)."
# Deliberately NOT logged in clear text - it travels via $store only.
$store = $password
