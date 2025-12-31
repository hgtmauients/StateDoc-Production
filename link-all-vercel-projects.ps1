# Link All State Folders to Existing Vercel Projects
# Run this once to set up project linking for all states

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Link All States to Vercel Projects" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Read state configuration
$configFile = ".\NewYork\YOUR-20-STATES-CONFIG.json"
$config = Get-Content $configFile -Raw | ConvertFrom-Json

$successCount = 0
$errorCount = 0

Write-Host "Linking state folders to Vercel projects..." -ForegroundColor Green
Write-Host "Note: You may need to manually select projects during linking" -ForegroundColor Yellow
Write-Host ""

foreach ($state in $config.stateList) {
    $stateName = $state.name
    $folderName = if ($state.folder) { $state.folder } else { $stateName }
    $domain = $state.domain

    $stateFolder = Join-Path (Get-Location) $folderName

    Write-Host "[$stateName] Linking..." -ForegroundColor Cyan -NoNewline

    if (-not (Test-Path $stateFolder)) {
        Write-Host " ERROR - Folder doesn't exist" -ForegroundColor Red
        $errorCount++
        continue
    }

    try {
        Push-Location $stateFolder

        # Check if already linked
        $vercelConfig = ".vercel"
        if (Test-Path $vercelConfig) {
            Write-Host " ALREADY LINKED" -ForegroundColor Gray
            $successCount++
        } else {
            # Link to Vercel project
            Write-Host ""
            Write-Host "  Select project for: $domain" -ForegroundColor Yellow
            Write-Host "  (Use arrow keys and Enter to select)" -ForegroundColor White

            $output = vercel link 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "  SUCCESS - Linked to Vercel project" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  ERROR - Failed to link" -ForegroundColor Red
                Write-Host "  $output" -ForegroundColor Red
                $errorCount++
            }
        }

        Pop-Location
    }
    catch {
        Write-Host " ERROR - $_" -ForegroundColor Red
        $errorCount++
        Pop-Location
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LINKING SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Successfully linked: $successCount states" -ForegroundColor Green
Write-Host "Errors: $errorCount states" -ForegroundColor Red
Write-Host ""

if ($successCount -eq 20) {
    Write-Host "ALL PROJECTS LINKED!" -ForegroundColor Green
    Write-Host "Ready to deploy with: .\deploy-all-states-vercel.ps1" -ForegroundColor White
} else {
    Write-Host "LINKING INCOMPLETE" -ForegroundColor Yellow
    Write-Host "Manually link remaining projects, then deploy" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
