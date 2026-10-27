$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$hashFile = Join-Path $PSScriptRoot "SHA256SUMS.txt"

$failed = 0
$passed = 0

foreach ($line in Get-Content $hashFile) {

    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    $parts = $line -split "\s{2}", 2

    $expected = $parts[0].Trim().ToLower()
    $relative = $parts[1].Trim()

    $windowsRelative = $relative.Replace("/", "\")
    $full = Join-Path $root $windowsRelative

    if (-not (Test-Path $full)) {
        Write-Host "MISSING: $relative"
        $failed++
        continue
    }

    $actual = (
        Get-FileHash `
            -Path $full `
            -Algorithm SHA256
    ).Hash.ToLower()

    if ($actual -eq $expected) {
        Write-Host "PASS: $relative"
        $passed++
    }
    else {
        Write-Host "FAIL: $relative"
        $failed++
    }
}

Write-Host ""
Write-Host "Passed: $passed"
Write-Host "Failed: $failed"

if ($failed -eq 0) {
    Write-Host "INTEGRITY CHECK: PASS"
}
else {
    Write-Host "INTEGRITY CHECK: FAIL"
    exit 1
}
