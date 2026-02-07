# Regenerate Sitemaps for All StateDoc Sites
# This script scans actual HTML files and generates accurate sitemaps

param(
    [string]$TargetState = "ALL"  # Pass state name or "ALL" for all states
)

$StateConfig = @{
    'Alaska' = 'alaskadoc.com'
    'Arizona' = 'arizonadoc.com'
    'Colorado' = 'coloradodoc.com'
    'Hawaii' = 'hawaiidoc.com'
    'Illinois' = 'illinoisdoc.com'
    'Indiana' = 'indianadoc.com'
    'Louisiana' = 'louisianadoc.com'
    'Maryland' = 'marylanddoc.com'
    'Michigan' = 'michigandoc.com'
    'Minnesota' = 'minnesotadoc.com'
    'Mississippi' = 'mississippidoc.com'
    'Montana' = 'montanadoc.com'
    'NorthCarolina' = 'northcarolinadoc.com'
    'NorthDakota' = 'northdakotadoc.com'
    'Nebraska' = 'nebraskadoc.com'
    'NewJersey' = 'newjerseydoc.com'
    'NewMexico' = 'newmexicodoc.com'
    'Nevada' = 'nevadadoc.com'
    'NewYork' = 'newyorkdoc.com'
    'Ohio' = 'ohiodoc.com'
    'Pennsylvania' = 'pennsylvaniadoc.com'
    'RhodeIsland' = 'rhodeislanddoc.com'
    'SouthCarolina' = 'southcarolinadoc.com'
    'SouthDakota' = 'dakotadoc.com'
    'Tennessee' = 'tennesseedoc.com'
    'Texas' = 'texasdoc.com'
    'Virginia' = 'virginiadoc.com'
    'Wisconsin' = 'wisconsindoc.com'
    'WestVirginia' = 'westvirginiadoc.com'
}

# Collection categories to scan
$CollectionDirs = @(
    'weight-loss',
    'mens-health',
    'womens-health',
    'dermatology',
    'primary-care',
    'mental-health',
    'chronic-disease-management',
    'cardiovascular-health',
    'digestive-health',
    'pain-management',
    'preventive-care'
)

function Generate-Sitemap {
    param(
        [string]$StatePath,
        [string]$Domain
    )
    
    $Today = (Get-Date).ToString('yyyy-MM-dd')
    $BaseUrl = "https://www.$Domain"
    
    $urls = @()
    
    # Homepage
    $urls += @{
        loc = "$BaseUrl/"
        lastmod = $Today
        changefreq = 'weekly'
        priority = '1.0'
        comment = 'Homepage'
    }
    
    # Blog pages
    $blogPath = Join-Path $StatePath 'blog'
    if (Test-Path $blogPath) {
        # Blog index
        if (Test-Path (Join-Path $blogPath 'index.html')) {
            $urls += @{
                loc = "$BaseUrl/blog/"
                lastmod = $Today
                changefreq = 'weekly'
                priority = '0.9'
                comment = 'Blog Index'
            }
        }
        
        # Blog articles
        $blogFiles = Get-ChildItem -Path $blogPath -Filter '*.html' | Where-Object { $_.Name -ne 'index.html' }
        foreach ($file in $blogFiles) {
            $slug = $file.BaseName
            $urls += @{
                loc = "$BaseUrl/blog/$slug"
                lastmod = $Today
                changefreq = 'monthly'
                priority = '0.8'
                type = 'blog'
            }
        }
    }
    
    # Collection pages
    foreach ($category in $CollectionDirs) {
        $catPath = Join-Path $StatePath $category
        if (Test-Path $catPath) {
            $catFiles = Get-ChildItem -Path $catPath -Filter '*.html'
            foreach ($file in $catFiles) {
                $slug = $file.BaseName
                $urls += @{
                    loc = "$BaseUrl/$category/$slug"
                    lastmod = $Today
                    changefreq = 'weekly'
                    priority = '0.9'
                    type = 'collection'
                    category = $category
                }
            }
        }
    }
    
    # Legal pages (only included if files exist on disk)
    # OhanaDoc franchise sites use popups instead and have no standalone files.
    # Other tenants may still use standalone legal pages.
    if (Test-Path (Join-Path $StatePath 'privacy.html')) {
        $urls += @{
            loc = "$BaseUrl/privacy"
            lastmod = $Today
            changefreq = 'yearly'
            priority = '0.3'
            comment = 'Privacy Policy'
        }
    }
    if (Test-Path (Join-Path $StatePath 'terms.html')) {
        $urls += @{
            loc = "$BaseUrl/terms"
            lastmod = $Today
            changefreq = 'yearly'
            priority = '0.3'
            comment = 'Terms of Service'
        }
    }
    
    # Generate XML
    $xml = @'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'@
    
    # Group URLs by type for nice formatting
    $homepage = $urls | Where-Object { $_.comment -eq 'Homepage' }
    $blogIndex = $urls | Where-Object { $_.comment -eq 'Blog Index' }
    $blogArticles = $urls | Where-Object { $_.type -eq 'blog' }
    $collectionPages = $urls | Where-Object { $_.type -eq 'collection' }
    $legalPages = $urls | Where-Object { $_.comment -like '*Policy*' -or $_.comment -like '*Terms*' }
    
    # Homepage - use the stored values directly
    $homeUrl = "$BaseUrl/"
    $xml += "`n    <!-- Homepage -->"
    $xml += "`n    <url>"
    $xml += "`n        <loc>$homeUrl</loc>"
    $xml += "`n        <lastmod>$Today</lastmod>"
    $xml += "`n        <changefreq>weekly</changefreq>"
    $xml += "`n        <priority>1.0</priority>"
    $xml += "`n    </url>"
    
    # Blog section
    $blogUrl = "$BaseUrl/blog/"
    $blogIndexPath = Join-Path (Join-Path $StatePath 'blog') 'index.html'
    if (Test-Path $blogIndexPath) {
        $xml += "`n    "
        $xml += "`n    <!-- Blog Index -->"
        $xml += "`n    <url>"
        $xml += "`n        <loc>$blogUrl</loc>"
        $xml += "`n        <lastmod>$Today</lastmod>"
        $xml += "`n        <changefreq>weekly</changefreq>"
        $xml += "`n        <priority>0.9</priority>"
        $xml += "`n    </url>"
    }
    
    if ($blogArticles) {
        $xml += "`n    "
        $xml += "`n    <!-- Blog Articles ($($blogArticles.Count) total) -->"
        foreach ($url in $blogArticles) {
            $xml += "`n    <url><loc>$($url.loc)</loc><lastmod>$($url.lastmod)</lastmod><changefreq>$($url.changefreq)</changefreq><priority>$($url.priority)</priority></url>"
        }
    }
    
    # Collection pages by category
    $categories = $collectionPages | Group-Object -Property category
    foreach ($cat in $categories) {
        $catName = $cat.Name -replace '-', ' '
        $catName = (Get-Culture).TextInfo.ToTitleCase($catName)
        $xml += "`n    "
        $xml += "`n    <!-- $catName Collection ($($cat.Count) pages) -->"
        foreach ($url in $cat.Group) {
            $xml += "`n    <url><loc>$($url.loc)</loc><lastmod>$($url.lastmod)</lastmod><changefreq>$($url.changefreq)</changefreq><priority>$($url.priority)</priority></url>"
        }
    }
    
    # Legal pages (only rendered if files exist on disk)
    if ($legalPages) {
        $xml += "`n    "
        $xml += "`n    <!-- Legal Pages -->"
        foreach ($url in $legalPages) {
            $xml += "`n    <url><loc>$($url.loc)</loc><lastmod>$($url.lastmod)</lastmod><changefreq>$($url.changefreq)</changefreq><priority>$($url.priority)</priority></url>"
        }
    }
    
    $xml += "`n</urlset>"
    
    return @{
        xml = $xml
        urlCount = $urls.Count
        blogCount = $blogArticles.Count
        collectionCount = $collectionPages.Count
    }
}

# Main execution
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($TargetState -eq "ALL") {
    $StatesToProcess = $StateConfig.Keys
} else {
    $StatesToProcess = @($TargetState)
}

$results = @()

foreach ($state in $StatesToProcess) {
    if (-not $StateConfig.ContainsKey($state)) {
        Write-Host "Unknown state: $state" -ForegroundColor Red
        continue
    }
    
    $domain = $StateConfig[$state]
    $statePath = Join-Path $ScriptDir $state
    
    if (-not (Test-Path $statePath)) {
        Write-Host "State folder not found: $statePath" -ForegroundColor Red
        continue
    }
    
    Write-Host "Processing $state ($domain)..." -ForegroundColor Cyan
    
    $result = Generate-Sitemap -StatePath $statePath -Domain $domain
    
    # Write sitemap
    $sitemapPath = Join-Path $statePath 'sitemap.xml'
    $result.xml | Out-File -FilePath $sitemapPath -Encoding UTF8 -Force
    
    Write-Host "  - Generated sitemap: $($result.urlCount) URLs ($($result.blogCount) blogs, $($result.collectionCount) collections)" -ForegroundColor Green
    
    $results += [PSCustomObject]@{
        State = $state
        Domain = $domain
        TotalUrls = $result.urlCount
        Blogs = $result.blogCount
        Collections = $result.collectionCount
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Yellow
$results | Format-Table -AutoSize

$totalUrls = ($results | Measure-Object -Property TotalUrls -Sum).Sum
Write-Host "Total URLs across all sitemaps: $totalUrls" -ForegroundColor Cyan
