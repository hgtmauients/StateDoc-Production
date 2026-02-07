# Deploy All Franchise Sites to Vercel
# Deploys each franchise site's homepage to Vercel production
# NOTE: Franchise count is dynamic - see YOUR-20-STATES-CONFIG.json (deprecated) or query database
#
# USAGE:
#   .\deploy-all-states-vercel.ps1                    # Deploy all states
#   .\deploy-all-states-vercel.ps1 -SpecificState Texas  # Deploy only Texas
#   .\deploy-all-states-vercel.ps1 -SkipLinking     # Skip linking check (if already linked)
#
# REQUIREMENTS:
#   - Vercel CLI installed: npm i -g vercel
#   - Logged in: vercel login
#   - Existing Vercel projects for each state domain
#
# PROCESS:
#   1. Checks if state folder exists
#   2. Links to existing Vercel project (if not already linked)
#   3. Deploys with: vercel --prod --yes
#   4. Reports success/failure

param(
    [switch]$LinkProjects,
    [switch]$SkipLinking,
    [string]$SpecificState
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy All States to Vercel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Read state configuration from NewYork folder
$configFile = ".\NewYork\YOUR-20-STATES-CONFIG.json"
$config = Get-Content $configFile -Raw | ConvertFrom-Json

$successCount = 0
$errorCount = 0
$skippedCount = 0

if ($SpecificState) {
    Write-Host "Deploying specific state: $SpecificState" -ForegroundColor Green
    $stateList = $config.stateList | Where-Object { $_.name -eq $SpecificState -or $_.folder -eq $SpecificState }
} else {
    Write-Host "Deploying all states to Vercel..." -ForegroundColor Green
    $stateList = $config.stateList
}
Write-Host ""

foreach ($state in $stateList) {
    $stateName = $state.name
    $folderName = if ($state.folder) { $state.folder } else { $stateName }
    $domain = $state.domain

    # State folder is directly in current directory (StateDoc)
    $stateFolder = Join-Path (Get-Location) $folderName

    Write-Host "[$stateName] Processing..." -ForegroundColor Cyan -NoNewline

    # Check if folder exists
    if (-not (Test-Path $stateFolder)) {
        Write-Host " ERROR - Folder doesn't exist" -ForegroundColor Red
        $errorCount++
        continue
    }

    try {
        Push-Location $stateFolder

        # Sync index.html to StateVercel.html before deployment
        $indexFile = Join-Path $stateFolder "index.html"
        if ($folderName -eq "WestVirginia") {
            $vercelFile = Join-Path $stateFolder "West VirginiaVercel.html"
        } else {
            $vercelFile = Join-Path $stateFolder "${folderName}Vercel.html"
        }
        
        if (Test-Path $indexFile) {
            Copy-Item $indexFile $vercelFile -Force -ErrorAction SilentlyContinue
        }

        # Check if already linked to Vercel project
        $vercelConfig = Join-Path $stateFolder ".vercel"
        $isLinked = Test-Path $vercelConfig

        if (-not $SkipLinking -and -not $isLinked) {
            Write-Host ""
            Write-Host "  Linking to Vercel project..." -ForegroundColor Yellow

            # Try to link automatically - this may require manual selection
            $linkOutput = vercel link 2>&1

            if ($LASTEXITCODE -ne 0) {
                Write-Host "  MANUAL LINK REQUIRED for $domain" -ForegroundColor Yellow
                Write-Host "  Run manually: cd '$stateFolder'; vercel link" -ForegroundColor White
                Write-Host "  Select project for domain: $domain" -ForegroundColor White
                $skippedCount++
                Pop-Location
                continue
            } else {
                Write-Host "  Linked successfully" -ForegroundColor Green
            }
        } elseif ($SkipLinking) {
            Write-Host " (skipping link check)" -ForegroundColor Gray
        } else {
            Write-Host " (already linked)" -ForegroundColor Gray
        }

        # Deploy to Vercel
        Write-Host "  Deploying..." -ForegroundColor Cyan -NoNewline

        $output = vercel --prod --yes 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host " SUCCESS" -ForegroundColor Green
            Write-Host "  URL: https://$domain" -ForegroundColor White
            $successCount++
        } else {
            Write-Host " ERROR - Deployment failed" -ForegroundColor Red
            Write-Host "  Error: $output" -ForegroundColor Red
            $errorCount++
        }

        Pop-Location
    }
    catch {
        Write-Host " ERROR - $_" -ForegroundColor Red
        $errorCount++
        Pop-Location
    }

    # Small delay between deployments
    Start-Sleep -Seconds 3
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERCEL DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Success: $successCount states" -ForegroundColor Green
Write-Host "Errors: $errorCount states" -ForegroundColor Red
Write-Host "Skipped: $skippedCount states (manual linking required)" -ForegroundColor Yellow
Write-Host ""

if ($SpecificState) {
    Write-Host "DEPLOYMENT COMPLETED FOR: $SpecificState" -ForegroundColor Green
} elseif ($successCount -eq 20) {
    Write-Host "ALL 20 STATES DEPLOYED TO VERCEL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The 7-category homepage is now LIVE on all production domains!" -ForegroundColor White
} else {
    Write-Host "DEPLOYMENT COMPLETED WITH ISSUES" -ForegroundColor Yellow
    Write-Host "Successfully deployed: $successCount franchise sites" -ForegroundColor White
    if ($skippedCount -gt 0) {
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "1. Manually link skipped projects: vercel link" -ForegroundColor White
        Write-Host "2. Re-run deployment script" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

