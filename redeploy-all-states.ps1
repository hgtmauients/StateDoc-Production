# Redeploy All States to Vercel
# Project names follow pattern: statedoc-statename

$states = @(
    @{folder='Alaska'; name='Alaska'},
    @{folder='Arizona'; name='Arizona'},
    @{folder='Dakota'; name='Dakota'},
    @{folder='Hawaii'; name='Hawaii'},
    @{folder='Illinois'; name='Illinois'},
    @{folder='Indiana'; name='Indiana'},
    @{folder='Louisiana'; name='Louisiana'},
    @{folder='Michigan'; name='Michigan'},
    @{folder='Minnesota'; name='Minnesota'},
    @{folder='Mississippi'; name='Mississippi'},
    @{folder='Nevada'; name='Nevada'},
    @{folder='NewJersey'; name='NewJersey'},
    @{folder='NewYork'; name='NewYork'},
    @{folder='Ohio'; name='Ohio'},
    @{folder='RhodeIsland'; name='RhodeIsland'},
    @{folder='Tennessee'; name='Tennessee'},
    @{folder='Texas'; name='Texas'},
    @{folder='Virginia'; name='Virginia'},
    @{folder='WestVirginia'; name='WestVirginia'},
    @{folder='Wisconsin'; name='Wisconsin'}
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Redeploying All States to Vercel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$errorCount = 0
$skippedCount = 0

foreach ($state in $states) {
    $stateFolder = $state.folder
    $stateName = $state.name
    
    Write-Host "[$stateName] Deploying..." -ForegroundColor Yellow
    
    if (-not (Test-Path $stateFolder)) {
        Write-Host "  ERROR: Folder doesn't exist" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    try {
        Push-Location $stateFolder
        
        # Sync index.html to StateVercel.html before deployment
        $indexFile = Join-Path $stateFolder "index.html"
        if ($state.folder -eq "WestVirginia") {
            $vercelFile = Join-Path $stateFolder "West VirginiaVercel.html"
        } else {
            $vercelFile = Join-Path $stateFolder "$($state.folder)Vercel.html"
        }
        
        if (Test-Path $indexFile) {
            Copy-Item $indexFile $vercelFile -Force -ErrorAction SilentlyContinue
        }
        
        # Deploy to Vercel
        $output = vercel --prod --yes 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  SUCCESS" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  ERROR - Deployment failed" -ForegroundColor Red
            $errorCount++
        }
        
        Pop-Location
    }
    catch {
        Write-Host "  ERROR - $_" -ForegroundColor Red
        $errorCount++
        if ((Get-Location).Path -ne (Get-Location | Split-Path -Parent)) {
            Pop-Location
        }
    }
    
    # Small delay between deployments
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Success: $successCount states" -ForegroundColor Green
Write-Host "Errors: $errorCount states" -ForegroundColor Red
Write-Host "Skipped: $skippedCount states" -ForegroundColor Yellow
Write-Host ""

if ($successCount -eq 20) {
    Write-Host "ALL STATES DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
} else {
    Write-Host "Deployment completed with some issues." -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan

