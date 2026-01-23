# Upgrade Blog Articles to Match Collection Page SEO Standards
# Adds Open Graph, Twitter Cards, Schema.org JSON-LD, and updated header/footer

param(
    [string]$TargetState = "ALL"
)

$StateConfig = @{
    'Alaska' = @{ domain = 'alaskadoc.com'; name = 'Alaska'; code = 'AK' }
    'Arizona' = @{ domain = 'arizonadoc.com'; name = 'Arizona'; code = 'AZ' }
    'Colorado' = @{ domain = 'coloradodoc.com'; name = 'Colorado'; code = 'CO' }
    'Hawaii' = @{ domain = 'hawaiidoc.com'; name = 'Hawaii'; code = 'HI' }
    'Illinois' = @{ domain = 'illinoisdoc.com'; name = 'Illinois'; code = 'IL' }
    'Indiana' = @{ domain = 'indianadoc.com'; name = 'Indiana'; code = 'IN' }
    'Louisiana' = @{ domain = 'louisianadoc.com'; name = 'Louisiana'; code = 'LA' }
    'Maryland' = @{ domain = 'marylanddoc.com'; name = 'Maryland'; code = 'MD' }
    'Michigan' = @{ domain = 'michigandoc.com'; name = 'Michigan'; code = 'MI' }
    'Minnesota' = @{ domain = 'minnesotadoc.com'; name = 'Minnesota'; code = 'MN' }
    'Mississippi' = @{ domain = 'mississippidoc.com'; name = 'Mississippi'; code = 'MS' }
    'Montana' = @{ domain = 'montanadoc.com'; name = 'Montana'; code = 'MT' }
    'NorthCarolina' = @{ domain = 'northcarolinadoc.com'; name = 'North Carolina'; code = 'NC' }
    'NorthDakota' = @{ domain = 'northdakotadoc.com'; name = 'North Dakota'; code = 'ND' }
    'Nebraska' = @{ domain = 'nebraskadoc.com'; name = 'Nebraska'; code = 'NE' }
    'NewJersey' = @{ domain = 'newjerseydoc.com'; name = 'New Jersey'; code = 'NJ' }
    'NewMexico' = @{ domain = 'newmexicodoc.com'; name = 'New Mexico'; code = 'NM' }
    'Nevada' = @{ domain = 'nevadadoc.com'; name = 'Nevada'; code = 'NV' }
    'NewYork' = @{ domain = 'newyorkdoc.com'; name = 'New York'; code = 'NY' }
    'Ohio' = @{ domain = 'ohiodoc.com'; name = 'Ohio'; code = 'OH' }
    'Pennsylvania' = @{ domain = 'pennsylvaniadoc.com'; name = 'Pennsylvania'; code = 'PA' }
    'RhodeIsland' = @{ domain = 'rhodeislanddoc.com'; name = 'Rhode Island'; code = 'RI' }
    'SouthCarolina' = @{ domain = 'southcarolinadoc.com'; name = 'South Carolina'; code = 'SC' }
    'SouthDakota' = @{ domain = 'dakotadoc.com'; name = 'South Dakota'; code = 'SD' }
    'Tennessee' = @{ domain = 'tennesseedoc.com'; name = 'Tennessee'; code = 'TN' }
    'Texas' = @{ domain = 'texasdoc.com'; name = 'Texas'; code = 'TX' }
    'Virginia' = @{ domain = 'virginiadoc.com'; name = 'Virginia'; code = 'VA' }
    'Wisconsin' = @{ domain = 'wisconsindoc.com'; name = 'Wisconsin'; code = 'WI' }
    'WestVirginia' = @{ domain = 'westvirginiadoc.com'; name = 'West Virginia'; code = 'WV' }
}

function Get-BlogTitle {
    param([string]$content)
    if ($content -match '<title>([^<]+)</title>') {
        return $matches[1] -replace '\s*\|.*$', ''
    }
    return "Blog Article"
}

function Get-MetaDescription {
    param([string]$content)
    if ($content -match '<meta\s+name="description"\s+content="([^"]+)"') {
        return $matches[1]
    }
    return "Read this comprehensive guide on healthcare topics."
}

function Get-Keywords {
    param([string]$content)
    if ($content -match '<meta\s+name="keywords"\s+content="([^"]+)"') {
        return $matches[1]
    }
    return ""
}

function Upgrade-BlogArticle {
    param(
        [string]$FilePath,
        [string]$Domain,
        [string]$StateName,
        [string]$StateCode
    )
    
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $slug = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $Today = (Get-Date).ToString('yyyy-MM-dd')
    $BaseUrl = "https://www.$Domain"
    $PageUrl = "$BaseUrl/blog/$slug"
    
    # Extract existing metadata
    $title = Get-BlogTitle $content
    $description = Get-MetaDescription $content
    $keywords = Get-Keywords $content
    
    # Check if already upgraded (has og:title)
    if ($content -match 'og:title') {
        return @{ upgraded = $false; reason = "Already has Open Graph" }
    }
    
    # Build new head section
    $newHead = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title | ${StateName}Doc</title>
    <meta name="description" content="$description">
    $(if ($keywords) { "<meta name=`"keywords`" content=`"$keywords`">" } else { "" })
    <meta name="author" content="${StateName} Telemedicine">
    <link rel="canonical" href="$PageUrl">
    
    <!-- Open Graph / Social Media -->
    <meta property="og:title" content="$title">
    <meta property="og:description" content="$description">
    <meta property="og:type" content="article">
    <meta property="og:url" content="$PageUrl">
    <meta property="og:site_name" content="${StateName}Doc">
    
    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="$title">
    <meta name="twitter:description" content="$description">
    
    <!-- Schema.org JSON-LD for BlogPosting -->
    <script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "$title",
  "description": "$description",
  "url": "$PageUrl",
  "datePublished": "$Today",
  "dateModified": "$Today",
  "inLanguage": "en-US",
  "author": {
    "@type": "Organization",
    "name": "${StateName}Doc",
    "url": "$BaseUrl"
  },
  "publisher": {
    "@type": "Organization",
    "name": "${StateName}Doc",
    "url": "$BaseUrl"
  },
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "$PageUrl"
  }
}
    </script>
    
    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    
"@

    # Extract existing style block
    if ($content -match '(<style>[\s\S]*?</style>)') {
        $existingStyle = $matches[1]
        $newHead += "    $existingStyle`n"
    }
    
    $newHead += "</head>"
    
    # Build new header
    $newHeader = @"
<body>
<header class="header" id="header">
    <nav class="nav">
        <a href="$BaseUrl/" class="logo">
            <img src="/assets/ohanaDoc-logo.png" alt="${StateName}Doc" class="logo-symbol" style="height:45px;width:45px;object-fit:contain">
            <div style="display:flex;flex-direction:column;gap:0.2rem">
                <span style="font-family:'Poppins','Inter',sans-serif;font-size:1.4rem;font-weight:700"><span style="color:#25D366;">${StateName}</span><span style="color:#009DDD;">Doc</span></span>
                <span style="background:linear-gradient(90deg,#F98A33 0%,#25D366 50%,#009DDD 100%);-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent;font-weight:600;font-size:0.65rem">Powered by OhanaDoc</span>
            </div>
        </a>
        <div class="nav-links" style="display:flex;gap:2rem;align-items:center">
            <a href="$BaseUrl/" style="color:#fff;text-decoration:none;font-weight:500">Home</a>
            <a href="$BaseUrl/blog/" style="color:#009DDD;text-decoration:none;font-weight:600">Blog</a>
            <a href="https://ohanadoc.com/login" style="background:#25D366;color:#013759;padding:0.75rem 1.5rem;border-radius:8px;text-decoration:none;font-weight:600">Patient Login</a>
        </div>
    </nav>
</header>
"@

    # Build new footer
    $newFooter = @"
<footer class="footer" style="background:#013759;padding:3rem 0;border-top:1px solid rgba(255,255,255,0.1);margin-top:4rem">
    <div style="max-width:1200px;margin:0 auto;padding:0 2rem">
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:2rem;margin-bottom:2rem">
            <div>
                <h4 style="color:#fff;margin-bottom:1rem;font-size:1.1rem">Services</h4>
                <a href="$BaseUrl/weight-loss/best-glp1-options" style="display:block;color:#9ca3af;text-decoration:none;margin-bottom:0.5rem">Weight Loss</a>
                <a href="$BaseUrl/mental-health/anxiety-medication-management" style="display:block;color:#9ca3af;text-decoration:none;margin-bottom:0.5rem">Mental Health</a>
                <a href="$BaseUrl/mens-health/best-ed-treatments" style="display:block;color:#9ca3af;text-decoration:none;margin-bottom:0.5rem">Men's Health</a>
            </div>
            <div>
                <h4 style="color:#fff;margin-bottom:1rem;font-size:1.1rem">Resources</h4>
                <a href="$BaseUrl/blog/" style="display:block;color:#9ca3af;text-decoration:none;margin-bottom:0.5rem">Health Blog</a>
                <a href="$BaseUrl/privacy" style="display:block;color:#9ca3af;text-decoration:none;margin-bottom:0.5rem">Privacy Policy</a>
                <a href="$BaseUrl/terms" style="display:block;color:#9ca3af;text-decoration:none;margin-bottom:0.5rem">Terms of Service</a>
            </div>
            <div>
                <h4 style="color:#fff;margin-bottom:1rem;font-size:1.1rem">${StateName}Doc</h4>
                <p style="color:#9ca3af;font-size:0.9rem;margin:0">Licensed telemedicine serving ${StateName} patients. Powered by OhanaDoc.</p>
            </div>
        </div>
        <div style="text-align:center;padding-top:2rem;border-top:1px solid rgba(255,255,255,0.1)">
            <p style="color:#6b7280;font-size:0.9rem;margin:0">Copyright 2026 Harrington Maui Enterprises LLC. All rights reserved.</p>
        </div>
    </div>
</footer>
</body>
</html>
"@

    # Extract body content (between container div)
    if ($content -match '<div class="container">([\s\S]*?)(</div>\s*</body>|<footer)') {
        $bodyContent = $matches[1]
        
        # Remove old footer if embedded
        $bodyContent = $bodyContent -replace '<footer[\s\S]*?</footer>', ''
        $bodyContent = $bodyContent -replace '<div[^>]*Medical Disclaimer[\s\S]*?</div>', ''
        
        # Add medical disclaimer
        $disclaimer = @"

<div style="margin-top:3rem;padding:2rem;background:rgba(0,157,221,0.05);border-left:4px solid #009DDD;border-radius:0 8px 8px 0">
    <p style="color:#9ca3af;font-size:0.9rem;margin:0"><strong style="color:#fff">Medical Disclaimer:</strong> This content is for informational purposes only and does not constitute medical advice. Always consult with a licensed healthcare provider before starting any treatment. Individual results may vary.</p>
</div>
"@
        
        $newContent = "$newHead`n$newHeader`n<main class=`"main-content`" style=`"min-height:calc(100vh - 200px);background:#013759`">`n<div class=`"container`" style=`"max-width:800px;margin:0 auto;padding:3rem 1.5rem`">$bodyContent$disclaimer`n</div>`n</main>`n$newFooter"
        
        # Write updated content
        $newContent | Out-File -FilePath $FilePath -Encoding UTF8 -Force
        
        return @{ upgraded = $true; title = $title }
    }
    
    return @{ upgraded = $false; reason = "Could not parse content" }
}

# Main execution
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($TargetState -eq "ALL") {
    $StatesToProcess = $StateConfig.Keys
} else {
    $StatesToProcess = @($TargetState)
}

$totalUpgraded = 0
$totalSkipped = 0

foreach ($state in $StatesToProcess) {
    if (-not $StateConfig.ContainsKey($state)) {
        Write-Host "Unknown state: $state" -ForegroundColor Red
        continue
    }
    
    $config = $StateConfig[$state]
    $blogPath = Join-Path (Join-Path $ScriptDir $state) 'blog'
    
    if (-not (Test-Path $blogPath)) {
        Write-Host "$state has no blog folder" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Processing $state..." -ForegroundColor Cyan
    
    $blogFiles = Get-ChildItem -Path $blogPath -Filter '*.html' | Where-Object { $_.Name -ne 'index.html' }
    
    foreach ($file in $blogFiles) {
        $result = Upgrade-BlogArticle -FilePath $file.FullName -Domain $config.domain -StateName $config.name -StateCode $config.code
        
        if ($result.upgraded) {
            Write-Host "  + Upgraded: $($file.Name)" -ForegroundColor Green
            $totalUpgraded++
        } else {
            Write-Host "  - Skipped: $($file.Name) ($($result.reason))" -ForegroundColor DarkGray
            $totalSkipped++
        }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Yellow
Write-Host "Upgraded: $totalUpgraded articles" -ForegroundColor Green
Write-Host "Skipped: $totalSkipped articles" -ForegroundColor DarkGray
