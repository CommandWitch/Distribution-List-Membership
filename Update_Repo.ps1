# Update-Repo.ps1 — Final Reliable Version
$org = "hukweb365"
$project = "DSS Scripts"
$repo = "DSS Scripts"
$branch = "main"
$targetFolder = "C:\DSS_SharedScripts"

# ==================================================
# Personal Access Token (PAT) — Create in Azure DevOps:
# Profile ? Personal Access Tokens ? New Token ? Code Read only
# ==================================================
$pat = "Dsj3zLSatYSLUhoVygaRazfRRpKa39fNM6PcRrHwHsHH9D4ogBlqJQQJ99CIACAAAAA8ScsCAAASAZDO28Pf"

Write-Host "`n=== Updating Scripts from Azure DevOps ===" -ForegroundColor Cyan
Write-Host "Source: $org / $project / $repo`n"

if ($pat -eq "PASTE-YOUR-TOKEN-HERE" -or $pat.Trim() -eq "") {
    Write-Host "?? No PAT set — using browser download method instead" -ForegroundColor Yellow
    goto BrowserMethod
}

# URL-encode names with spaces
$projectEncoded = [Uri]::EscapeDataString($project)
$repoEncoded = [Uri]::EscapeDataString($repo)

# Build correct API URL
$url = "https://dev.azure.com/$org/$projectEncoded/_apis/git/repositories/$repoEncoded/items"
$url += "?path=/&recursionLevel=full&`$format=zip&download=true&api-version=7.1"

$zipFile = Join-Path $env:TEMP "DSS-Scripts-Latest.zip"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "Downloading from Azure DevOps API..." -ForegroundColor Cyan

    # PAT auth header
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
    $headers = @{ Authorization = "Basic $base64Auth" }

    $response = Invoke-WebRequest -Uri $url -Headers $headers -Method Get -OutFile $zipFile -UseBasicParsing

    if (-not (Test-Path $zipFile)) {
        throw "No file downloaded"
    }

    # Verify ZIP signature
    $firstTwoBytes = Get-Content -Path $zipFile -Encoding Byte -TotalCount 2
    if ($firstTwoBytes[0] -ne 0x50 -or $firstTwoBytes[1] -ne 0x4B) {
        Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
        throw "Did not receive a valid ZIP file — check PAT permissions"
    }

    Write-Host "? Download verified — extracting..." -ForegroundColor Green

    # Prepare folders
    $tempExtract = Join-Path $env:TEMP "DSS-Extract-Temp"
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null
    if (-not (Test-Path $targetFolder)) { New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null }

    Expand-Archive -Path $zipFile -DestinationPath $tempExtract -Force

    # Copy files (strip top-level repo folder)
    $topFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
    $sourceRoot = if ($topFolder) { $topFolder.FullName } else { $tempExtract }
    
    $files = Get-ChildItem -Path $sourceRoot -Recurse -File
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
        $dest = Join-Path $targetFolder $rel
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -Path $f.FullName -Destination $dest -Force
    }

    Write-Host "`n? SUCCESS — $($files.Count) file(s) updated!" -ForegroundColor Green
    Write-Host "?? $targetFolder`n" -ForegroundColor Cyan
    goto Cleanup
}
catch {
    Write-Host "`n? Auto-update failed: $($_.Exception.Message)" -ForegroundColor Red
}

:BrowserMethod
Write-Host "`n?? Use this guaranteed method instead:" -ForegroundColor Yellow
Write-Host "   1. Open ? https://dev.azure.com/$org/$projectEncoded/_git/$repoEncoded"
Write-Host "   2. Click the 3 dots ? ? Download as ZIP"
Write-Host "   3. Extract all files to: $targetFolder"
Write-Host "   4. Overwrite when prompted ?`n"

:Cleanup
if (Test-Path $zipFile) { Remove-Item $zipFile -Force -ErrorAction SilentlyContinue }
$tempExtract = Join-Path $env:TEMP "DSS-Extract-Temp"
if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")