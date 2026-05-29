# Creates quran_data.zip from the existing assets for first-launch download
# Run this from the project root directory before creating a GitHub Release
#
# Usage:
#   cd al_medynah
#   powershell -ExecutionPolicy Bypass -File scripts/create_zip.ps1

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

$zipPath = Join-Path -Path $projectRoot -ChildPath "quran_data.zip"
$tempDir = Join-Path -Path $env:TEMP -ChildPath "quran_data_zip"

# Clean up any previous temp
if (Test-Path -LiteralPath $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "Copying pages/ ..." -ForegroundColor Cyan
Copy-Item -Path "assets/quran_data/pages" -Destination $tempDir -Recurse -Force

Write-Host "Copying verses.json ..." -ForegroundColor Cyan
Copy-Item -Path "assets/quran_data/verses.json" -Destination $tempDir -Force

Write-Host "Copying fonts/ ..." -ForegroundColor Cyan
Copy-Item -Path "assets/quran_data/fonts" -Destination $tempDir -Recurse -Force

Write-Host "Creating quran_data.zip ..." -ForegroundColor Cyan
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force

$size = (Get-Item $zipPath).Length
Write-Host "Done! Zip created: $zipPath" -ForegroundColor Green
Write-Host "Size: $([math]::Round($size / 1MB, 1)) MB" -ForegroundColor Green
