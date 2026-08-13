<#
.SYNOPSIS
    Test script for New-QRCode.ps1

.DESCRIPTION
    Tests QR code generation with sample URLs.
#>

$scriptPath = Join-Path $PSScriptRoot "New-QRCode.ps1"
$outputDir = Join-Path $PSScriptRoot "qrcodes"

# Create output directory
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "QR Code Generator Test Script" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Test URLs
$testCases = @(
    @{
        Name = "Printables Whistle Model"
        Url = "https://www.printables.com/model/1563396-compact-dual-chamber-whistle-v21"
        Output = "printables-whistle.png"
    },
    @{
        Name = "Linktree 3D Whistles"
        Url = "https://linktr.ee/3Dwhistles"
        Output = "linktree-3dwhistles.png"
    },
    @{
        Name = "Riot Grrrl Revolution Zines"
        Url = "https://www.riotgrrrlrevolution.org/zines"
        Output = "riotgrrrl-zines.png"
    },
    @{
        Name = "ILRC Red Cards"
        Url = "https://www.ilrc.org/redcards#print"
        Output = "ilrc-redcards.png"
    },
    @{
        Name = "WhistleCrew 38mm Micro Bitonal Half Height Hole"
        Url = "https://whistlecrew.samurailink3.com/wiki:models_38mm-micro-bitonal-half-height-hole"
        Output = "whistlecrew-38mm-micro-bitonal.png"
    },
    @{
        Name = "MakerWorld Heart Whistle 120dB"
        Url = "https://makerworld.com/en/models/1148955-heart-whistle-120-db"
        Output = "makerworld-heart-whistle.png"
    }
)

$passed = 0
$failed = 0

foreach ($test in $testCases) {
    Write-Host "Test: $($test.Name)" -ForegroundColor Yellow
    Write-Host "  URL: $($test.Url)" -ForegroundColor Gray

    $outputPath = Join-Path $outputDir $test.Output

    try {
        & $scriptPath -Content $test.Url -OutputPath $outputPath -Force

        if (Test-Path $outputPath) {
            $fileInfo = Get-Item $outputPath
            Write-Host "  Result: PASSED" -ForegroundColor Green
            Write-Host "  File: $outputPath" -ForegroundColor Gray
            Write-Host "  Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
            $passed++
        }
        else {
            Write-Host "  Result: FAILED - File not created" -ForegroundColor Red
            $failed++
        }
    }
    catch {
        Write-Host "  Result: FAILED - $_" -ForegroundColor Red
        $failed++
    }

    Write-Host ""
}

# Summary
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Summary: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "Output directory: $outputDir" -ForegroundColor Gray
Write-Host "=" * 60 -ForegroundColor Cyan

# Ask to open the generated images
if ($passed -gt 0) {
    Write-Host ""
    $response = Read-Host "Open generated QR codes? (Y/N)"
    if ($response -match '^[Yy]') {
        foreach ($test in $testCases) {
            $outputPath = Join-Path $outputDir $test.Output
            if (Test-Path $outputPath) {
                Start-Process $outputPath
            }
        }
    }
}
