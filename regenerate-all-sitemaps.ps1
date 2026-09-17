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

# Sites that live outside the StateDoc-main tree but share this generator, so
# that one script owns every sitemap we publish. Paths are relative to this
# script's directory. OD is the OhanaDoc collections site, deployed from
# sites/od as its own Vercel project; it was previously hand-maintained and had
# drifted to a lastmod of 2026-01-11.
$ExternalSiteConfig = @{
    'OD' = @{
        RelativePath = '..\od'
        Domain = 'collections.ohanadoc.com'
    }
}

# Directories that never hold indexable collection pages. Any other directory
# containing .html is discovered automatically, so adding a new content category
# no longer requires editing this script. A hardcoded list is what hid the
# services/ pages from every sitemap for months.
#
# 'services' is denied deliberately. Those pages were ~230-character duplicates
# of the homepage treatment cards and shipped canonical="None"; the matching
# service_card rows are archived (non-routable under Rule 7) and /services/*
# now redirects to /.
$NonCollectionDirs = @(
    'assets',
    'blog',
    'css',
    'fonts',
    'images',
    'img',
    'js',
    'services',
    'static'
)

# Root-level pages are an explicit allowlist mapping file on disk -> clean URL.
# coming-soon.html is intentionally absent: it is a placeholder, not content.
$RootPages = @(
    @{ File = 'privacy.html'; Path = 'privacy'; Comment = 'Privacy Policy' },
    @{ File = 'terms.html';   Path = 'terms';   Comment = 'Terms of Service' }
)

function Get-CollectionDirs {
    param([string]$SitePath)

    Get-ChildItem -Path $SitePath -Directory |
        Where-Object { $_.Name -notmatch '^\.' } |
        Where-Object { $NonCollectionDirs -notcontains $_.Name } |
        Where-Object { @(Get-ChildItem -Path $_.FullName -Filter '*.html' -File).Count -gt 0 } |
        Select-Object -ExpandProperty Name |
        Sort-Object
}

function Get-PreferredBaseUrl {
    param([string]$Domain)

    # Mirrors preferred_base_url() in backend/utils/sitemap_urls.py so the XML,
    # GSC submissions, and drift checks all agree on one host spelling: apex
    # domains canonicalize to www, subdomains such as collections.ohanadoc.com
    # serve as-is.
    $d = "$Domain".Trim().ToLower()
    if ($d.StartsWith('www.')) { return "https://$d" }
    if ((($d -split '\.').Count - 1) -eq 1) { return "https://www.$d" }
    return "https://$d"
}

function Update-RobotsSitemapLine {
    <#
        .SYNOPSIS
        Point robots.txt at the sitemap this script just wrote.

        .DESCRIPTION
        robots.txt used to be maintained by scripts/fix-all-robots-txt.ps1, which
        carried its own hardcoded folder-to-domain map and repaired the Sitemap
        line with the pattern https?://[^\s/]+/sitemap\.xml. That pattern cannot
        match a host containing a space, so on the three files that were actually
        broken -- "https://New newnewNewMexicoDoc.com/sitemap.xml" and the two
        Carolinas -- it matched nothing, changed nothing, and reported them as
        already correct. Google could not discover those sitemaps for months.

        Deriving the line here instead means robots.txt and sitemap.xml always
        agree on the host, because both come from Get-PreferredBaseUrl, and there
        is no second domain map to drift.
    #>
    param(
        [string]$SitePath,
        [string]$BaseUrl
    )

    $robotsPath = Join-Path $SitePath 'robots.txt'
    if (-not (Test-Path $robotsPath)) { return $null }

    $content = Get-Content $robotsPath -Raw
    $desired = "Sitemap: $BaseUrl/sitemap.xml"

    # Match the whole line rather than the URL, so a malformed host with spaces
    # is still replaced instead of being silently skipped.
    $pattern = '(?im)^[ \t]*Sitemap:.*$'

    if ($content -match $pattern) {
        $updated = [regex]::Replace($content, $pattern, $desired)
    }
    else {
        $updated = $content.TrimEnd() + "`n`n$desired`n"
    }

    if ($updated -eq $content) { return $false }

    Set-Content -Path $robotsPath -Value $updated -NoNewline
    return $true
}

function New-Sitemap {
    param(
        [string]$StatePath,
        [string]$Domain
    )
    
    $Today = (Get-Date).ToString('yyyy-MM-dd')
    $BaseUrl = Get-PreferredBaseUrl -Domain $Domain
    
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
                loc = "$BaseUrl/blog"
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
    
    # Collection pages - categories are discovered from disk, not hardcoded
    foreach ($category in (Get-CollectionDirs -SitePath $StatePath)) {
        $catPath = Join-Path $StatePath $category
        $catFiles = Get-ChildItem -Path $catPath -Filter '*.html' -File
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
    
    # Root pages from the allowlist, included only when the file exists on disk.
    # OhanaDoc franchise sites use popups instead and have no standalone files.
    # Other tenants may still use standalone legal pages.
    foreach ($page in $RootPages) {
        if (Test-Path (Join-Path $StatePath $page.File)) {
            $urls += @{
                loc = "$BaseUrl/$($page.Path)"
                lastmod = $Today
                changefreq = 'yearly'
                priority = '0.3'
                type = 'root'
                comment = $page.Comment
            }
        }
    }
    
    # Generate XML
    $xml = @'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'@
    
    # Group URLs by type for nice formatting
    $blogArticles = $urls | Where-Object { $_.type -eq 'blog' }
    $collectionPages = $urls | Where-Object { $_.type -eq 'collection' }
    $legalPages = $urls | Where-Object { $_.type -eq 'root' }
    
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
    $blogUrl = "$BaseUrl/blog"
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

function Resolve-Site {
    param([string]$Name)

    if ($StateConfig.ContainsKey($Name)) {
        return [PSCustomObject]@{
            Name = $Name
            Domain = $StateConfig[$Name]
            Path = Join-Path $ScriptDir $Name
        }
    }
    if ($ExternalSiteConfig.ContainsKey($Name)) {
        $cfg = $ExternalSiteConfig[$Name]
        return [PSCustomObject]@{
            Name = $Name
            Domain = $cfg.Domain
            Path = Join-Path $ScriptDir $cfg.RelativePath
        }
    }
    return $null
}

if ($TargetState -eq "ALL") {
    $SitesToProcess = @($StateConfig.Keys) + @($ExternalSiteConfig.Keys)
} else {
    $SitesToProcess = @($TargetState)
}

$results = @()
$hadErrors = $false

foreach ($siteName in $SitesToProcess) {
    $site = Resolve-Site -Name $siteName
    if (-not $site) {
        Write-Host "Unknown site: $siteName" -ForegroundColor Red
        $hadErrors = $true
        continue
    }

    if (-not (Test-Path $site.Path)) {
        Write-Host "Site folder not found: $($site.Path)" -ForegroundColor Red
        $hadErrors = $true
        continue
    }

    Write-Host "Processing $($site.Name) ($($site.Domain))..." -ForegroundColor Cyan
    try {
        $result = New-Sitemap -StatePath $site.Path -Domain $site.Domain

        # Write sitemap
        $sitemapPath = Join-Path $site.Path 'sitemap.xml'
        $result.xml | Out-File -FilePath $sitemapPath -Encoding UTF8 -Force

        Write-Host "  - Generated sitemap: $($result.urlCount) URLs ($($result.blogCount) blogs, $($result.collectionCount) collections)" -ForegroundColor Green

        $robotsChanged = Update-RobotsSitemapLine -SitePath $site.Path -BaseUrl (Get-PreferredBaseUrl -Domain $site.Domain)
        if ($robotsChanged -eq $true) {
            Write-Host "  - Updated robots.txt Sitemap line" -ForegroundColor Green
        }
        elseif ($null -eq $robotsChanged) {
            Write-Host "  - No robots.txt in this folder" -ForegroundColor DarkGray
        }

        $results += [PSCustomObject]@{
            Site = $site.Name
            Domain = $site.Domain
            TotalUrls = $result.urlCount
            Blogs = $result.blogCount
            Collections = $result.collectionCount
        }
    }
    catch {
        Write-Host "Failed processing ${siteName}: $($_.Exception.Message)" -ForegroundColor Red
        $hadErrors = $true
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Yellow
$results | Format-Table -AutoSize

$totalUrls = ($results | Measure-Object -Property TotalUrls -Sum).Sum
Write-Host "Total URLs across all sitemaps: $totalUrls" -ForegroundColor Cyan

if ($hadErrors -or $results.Count -eq 0) {
    Write-Host "Sitemap regeneration completed with errors." -ForegroundColor Red
    exit 1
}

Write-Host "Sitemap regeneration completed successfully." -ForegroundColor Green
exit 0
