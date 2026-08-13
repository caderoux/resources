<#
.SYNOPSIS
    Generates a QR code image from a URL or text.

.DESCRIPTION
    Creates a QR code PNG image file from the provided URL or text content.
    Uses the QRCoder .NET library for generation.

.PARAMETER Content
    The URL or text to encode in the QR code.

.PARAMETER OutputPath
    The output file path for the QR code image. Defaults to 'qrcode.png' in current directory.

.PARAMETER Size
    The size of each QR code module in pixels. Higher values create larger images. Default is 10.

.PARAMETER Open
    If specified, opens the generated image file after creation.

.PARAMETER Force
    If specified, overwrites existing output file without prompting.

.EXAMPLE
    .\New-QRCode.ps1 -Content "https://example.com"
    Creates qrcode.png in the current directory.

.EXAMPLE
    .\New-QRCode.ps1 -Content "https://example.com" -OutputPath "mycode.png" -Open
    Creates mycode.png and opens it in the default image viewer.

.EXAMPLE
    .\New-QRCode.ps1 "https://example.com" -Size 20 -Open
    Creates a larger QR code and opens it immediately.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "URL or text to encode")]
    [ValidateNotNullOrEmpty()]
    [string]$Content,

    [Parameter(Position = 1, HelpMessage = "Output file path (PNG)")]
    [string]$OutputPath = "qrcode.png",

    [Parameter(HelpMessage = "Size of each QR module in pixels (1-50)")]
    [ValidateRange(1, 50)]
    [int]$Size = 10,

    [Parameter(HelpMessage = "Open the image after generation")]
    [switch]$Open,

    [Parameter(HelpMessage = "Overwrite existing file without prompting")]
    [switch]$Force
)

# Ensure output path is absolute
if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path (Get-Location) $OutputPath
}

# Ensure .png extension
if (-not $OutputPath.EndsWith(".png", [System.StringComparison]::OrdinalIgnoreCase)) {
    $OutputPath = "$OutputPath.png"
}

# Check if file exists
if ((Test-Path $OutputPath) -and -not $Force) {
    $response = Read-Host "File '$OutputPath' already exists. Overwrite? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 1
    }
}

# NuGet package details
$packageName = "QRCoder"
$packageVersion = "1.4.3"
$nugetUrl = "https://www.nuget.org/api/v2/package/$packageName/$packageVersion"
$packagesDir = Join-Path $env:LOCALAPPDATA "QRCodeGenerator\packages"
$packageDir = Join-Path $packagesDir "$packageName.$packageVersion"
$dllPath = Join-Path $packageDir "lib\net40\QRCoder.dll"

# Download and extract QRCoder if not present
if (-not (Test-Path $dllPath)) {
    Write-Host "Downloading QRCoder library..." -ForegroundColor Cyan

    try {
        # Create packages directory
        if (-not (Test-Path $packagesDir)) {
            New-Item -ItemType Directory -Path $packagesDir -Force | Out-Null
        }

        # Download the package
        $zipPath = Join-Path $packagesDir "$packageName.$packageVersion.zip"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $nugetUrl -OutFile $zipPath -UseBasicParsing

        # Extract the package
        Expand-Archive -Path $zipPath -DestinationPath $packageDir -Force
        Remove-Item $zipPath -Force

        Write-Host "QRCoder library installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download QRCoder library: $_"
        exit 1
    }
}

# Load the assembly
try {
    Add-Type -Path $dllPath
    Add-Type -AssemblyName System.Drawing
}
catch {
    Write-Error "Failed to load QRCoder library: $_"
    exit 1
}

# Generate QR code
try {
    Write-Host "Generating QR code..." -ForegroundColor Cyan

    # Create QR code generator
    $qrGenerator = New-Object QRCoder.QRCodeGenerator
    $qrData = $qrGenerator.CreateQrCode($Content, [QRCoder.QRCodeGenerator+ECCLevel]::Q)
    $qrCode = New-Object QRCoder.QRCode($qrData)

    # Generate bitmap
    $bitmap = $qrCode.GetGraphic($Size)

    # Ensure output directory exists
    $outputDir = Split-Path $OutputPath -Parent
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Save to file
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    # Clean up
    $bitmap.Dispose()
    $qrCode.Dispose()
    $qrGenerator.Dispose()

    Write-Host "QR code saved to: $OutputPath" -ForegroundColor Green

    # Open if requested
    if ($Open) {
        Write-Host "Opening image..." -ForegroundColor Cyan
        Start-Process $OutputPath
    }
}
catch {
    Write-Error "Failed to generate QR code: $_"
    exit 1
}
