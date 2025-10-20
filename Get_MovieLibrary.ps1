<# 
Get_MovieLibrary.ps1
Lightweight bootstrapper that downloads and runs the full Movie Library Organizer builder.
After it finishes, open the new folder and double-click "Run Movie Manager.bat".
#>

param(
    [string]$InstallPath = "C:\MovieLibrary"
)

Write-Host "=== Movie Library Organizer Bootstrap ===" -ForegroundColor Cyan
Write-Host "This will create or update: $InstallPath" -ForegroundColor Yellow
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath | Out-Null
}

# URL of the hosted installer script
$builderUrl = "https://raw.githubusercontent.com/MarkMercurioTools/MovieLibraryInstaller/main/Create_MovieManager.ps1"

# Destination for the full installer
$builderFile = Join-Path $InstallPath "Create_MovieManager.ps1"

Write-Host "`nDownloading full installer script..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $builderUrl -OutFile $builderFile -UseBasicParsing
    Write-Host "✓ Download complete." -ForegroundColor Green
} catch {
    Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nRunning installer..." -ForegroundColor Cyan
try {
    & powershell -ExecutionPolicy Bypass -File $builderFile
    Write-Host "`nAll done!" -ForegroundColor Green
    Write-Host "Open $InstallPath and double-click Run Movie Manager.bat" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Installer execution failed: $($_.Exception.Message)" -ForegroundColor Red
}
