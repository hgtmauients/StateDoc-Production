# Deploy a single state to Vercel
# USAGE:
#   .\deploy-state-vercel.ps1 -State Ohio
#   .\deploy-state-vercel.ps1 -State Ohio -SkipLinking
#
# REQUIREMENTS:
#   - Vercel CLI installed: npm i -g vercel
#   - Logged in: vercel login
#
# The script will:
#   1. Sync index.html to StateVercel.html
#   2. Navigate to the state folder
#   3. Link to Vercel project if needed
#   4. Deploy with: vercel --prod --yes

param(
    [Parameter(Mandatory=$true)]
    [string]$State,
    [switch]$SkipLinking
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy $State to Vercel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# State folder mapping
$stateConfig = @{
    "Alaska" = @{ folder = "Alaska"; domain = "alaskadoc.com" }
    "Arizona" = @{ folder = "Arizona"; domain = "arizonadoc.com" }
    "Dakota" = @{ folder = "Dakota"; domain = "dakotadoc.com" }
    "Hawaii" = @{ folder = "Hawaii"; domain = "hawaiidoc.com" }
    "Illinois" = @{ folder = "Illinois"; domain = "illinoisdoc.com" }
    "Indiana" = @{ folder = "Indiana"; domain = "indianadoc.com" }
    "Louisiana" = @{ folder = "Louisiana"; domain = "louisianadoc.com" }
    "Michigan" = @{ folder = "Michigan"; domain = "michigandoc.com" }
    "Minnesota" = @{ folder = "Minnesota"; domain = "minnesotadoc.com" }
    "Mississippi" = @{ folder = "Mississippi"; domain = "mississippidoc.com" }
    "Nevada" = @{ folder = "Nevada"; domain = "nevadadoc.com" }
    "NewJersey" = @{ folder = "NewJersey"; domain = "newjerseydoc.com" }
    "NewYork" = @{ folder = "NewYork"; domain = "newyorkdoc.com" }
    "Ohio" = @{ folder = "Ohio"; domain = "ohiodoc.com" }
    "RhodeIsland" = @{ folder = "RhodeIsland"; domain = "rhodeislanddoc.com" }
    "Tennessee" = @{ folder = "Tennessee"; domain = "tennesseedoc.com" }
    "Texas" = @{ folder = "Texas"; domain = "texasdoc.com" }
    "Virginia" = @{ folder = "Virginia"; domain = "virginiadoc.com" }
    "WestVirginia" = @{ folder = "WestVirginia"; domain = "westvirginiadoc.com" }
    "Wisconsin" = @{ folder = "Wisconsin"; domain = "wisconsindoc.com" }
}

# Find the state (case-insensitive)
$matchedState = $stateConfig.Keys | Where-Object { $_ -ieq $State }

if (-not $matchedState) {
    Write-Host "ERROR: State '$State' not found." -ForegroundColor Red
    Write-Host "Available states:" -ForegroundColor Yellow
    $stateConfig.Keys | Sort-Object | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

$config = $stateConfig[$matchedState]
$folderName = $config.folder
$domain = $config.domain
$stateFolder = Join-Path (Get-Location) $folderName

Write-Host "State: $matchedState" -ForegroundColor Green
Write-Host "Folder: $folderName" -ForegroundColor Green
Write-Host "Domain: $domain" -ForegroundColor Green
Write-Host ""

# Check if folder exists
if (-not (Test-Path $stateFolder)) {
    Write-Host "ERROR: Folder doesn't exist: $stateFolder" -ForegroundColor Red
    exit 1
}

# Sync index.html to StateVercel.html before deployment
Write-Host "Syncing index.html to StateVercel.html..." -ForegroundColor Yellow
$indexFile = Join-Path $stateFolder "index.html"
if ($folderName -eq "WestVirginia") {
    $vercelFile = Join-Path $stateFolder "West VirginiaVercel.html"
} else {
    $vercelFile = Join-Path $stateFolder "${folderName}Vercel.html"
}

if (Test-Path $indexFile) {
    try {
        Copy-Item $indexFile $vercelFile -Force
        Write-Host "Synced successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "WARNING: Could not sync files: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: index.html not found, skipping sync" -ForegroundColor Yellow
}
Write-Host ""

try {
    Push-Location $stateFolder
    
    # Check if already linked to Vercel project
    $vercelConfig = Join-Path $stateFolder ".vercel"
    $isLinked = Test-Path $vercelConfig
    
    if (-not $SkipLinking -and -not $isLinked) {
        Write-Host "Linking to Vercel project..." -ForegroundColor Yellow
        
        # Try to link automatically
        $linkOutput = vercel link 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "MANUAL LINK REQUIRED for $domain" -ForegroundColor Yellow
            Write-Host "Run manually: vercel link" -ForegroundColor White
            Write-Host "Select project for domain: $domain" -ForegroundColor White
            Pop-Location
            exit 1
        } else {
            Write-Host "Linked successfully" -ForegroundColor Green
        }
    } elseif ($SkipLinking) {
        Write-Host "Skipping link check..." -ForegroundColor Gray
    } else {
        Write-Host "Already linked to Vercel" -ForegroundColor Green
    }
    
    # Deploy to Vercel
    Write-Host ""
    Write-Host "Deploying to production..." -ForegroundColor Cyan
    
    $output = vercel --prod --yes 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "SUCCESS!" -ForegroundColor Green
        Write-Host "Deployed to: https://$domain" -ForegroundColor White
        Write-Host ""
        # Extract deployment URL from output
        $deployUrl = $output | Select-String -Pattern "https://.*\.vercel\.app" | ForEach-Object { $_.Matches[0].Value }
        if ($deployUrl) {
            Write-Host "Vercel URL: $deployUrl" -ForegroundColor Gray
        }
    } else {
        Write-Host "ERROR: Deployment failed" -ForegroundColor Red
        Write-Host "Error: $output" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Pop-Location
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
