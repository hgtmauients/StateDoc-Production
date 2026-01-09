# Sync index.html to StateVercel.html for all states
# This ensures StateVercel.html files stay in sync with index.html
#
# USAGE:
#   .\sync-vercel-files.ps1                    # Sync all states
#   .\sync-vercel-files.ps1 -State Ohio       # Sync only Ohio
#
# Run this before deploying to ensure StateVercel.html matches index.html

param(
    [string]$State
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sync index.html to StateVercel.html" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory (where the script is located)
$scriptPath = $MyInvocation.MyCommand.Path
if ($scriptPath) {
    $scriptDir = Split-Path -Parent $scriptPath
    Push-Location $scriptDir
} else {
    $scriptDir = Get-Location
}

# Read state configuration
$configFile = Join-Path $scriptDir "NewYork\YOUR-20-STATES-CONFIG.json"
if (-not (Test-Path $configFile)) {
    Write-Host "ERROR: Config file not found: $configFile" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    if ($scriptPath) { Pop-Location }
    exit 1
}

$config = Get-Content $configFile -Raw | ConvertFrom-Json

$successCount = 0
$errorCount = 0

if ($State) {
    Write-Host "Syncing specific state: $State" -ForegroundColor Green
    $stateList = $config.stateList | Where-Object { $_.name -eq $State -or $_.folder -eq $State }
} else {
    Write-Host "Syncing all states..." -ForegroundColor Green
    $stateList = $config.stateList
}
Write-Host ""

foreach ($state in $stateList) {
    $stateName = $state.name
    $folderName = if ($state.folder) { $state.folder } else { $stateName }
    
    $stateFolder = Join-Path $scriptDir $folderName
    $indexFile = Join-Path $stateFolder "index.html"
    
    # Determine Vercel file name (special case for WestVirginia)
    if ($folderName -eq "WestVirginia") {
        $vercelFile = Join-Path $stateFolder "West VirginiaVercel.html"
    } else {
        $vercelFile = Join-Path $stateFolder "${folderName}Vercel.html"
    }
    
    Write-Host "[$stateName] " -ForegroundColor Cyan -NoNewline
    
    if (-not (Test-Path $indexFile)) {
        Write-Host "ERROR - index.html not found" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    try {
        Copy-Item $indexFile $vercelFile -Force
        Write-Host "Synced successfully" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "ERROR - $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SYNC SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Success: $successCount states" -ForegroundColor Green
Write-Host "Errors: $errorCount states" -ForegroundColor Red
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "All StateVercel.html files synced successfully!" -ForegroundColor Green
} else {
    Write-Host "Sync completed with some errors." -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
