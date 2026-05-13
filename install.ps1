$repo = "Lonezsi/jcombine"
$installDir = "$env:USERPROFILE\jcombine"
$repoUrl = "https://github.com/$repo.git"

Write-Host "Installing / Updating jcombine..." -ForegroundColor Cyan

# =========================
# VERSION
# =========================

$toolRoot = Split-Path $MyInvocation.MyCommand.Path
$versionFile = Join-Path $toolRoot "version.txt"

$VERSION = if (Test-Path $versionFile) {
    Get-Content $versionFile -Raw
} else {
    "unknown"
}

if ($args -contains "--version") {
    Write-Host "jcombine v$VERSION"
    exit 0
}

# =========================
# UPDATE
# =========================


if ($args -contains "update") {

    Write-Host "Updating jcombine..." -ForegroundColor Cyan

    $installDir = Split-Path $MyInvocation.MyCommand.Path

    Set-Location $installDir

    git fetch origin

    $branch = git rev-parse --abbrev-ref HEAD

    git reset --hard "origin/$branch"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Update failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "Updated successfully." -ForegroundColor Green
    exit 0
}

# =========================
# CASE 1: NOT INSTALLED
# =========================
if (-not (Test-Path $installDir)) {

    git clone $repoUrl $installDir

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Clone failed. Repo URL or access issue." -ForegroundColor Red
        exit 1
    }

} else {

    # =========================
    # CASE 2: UPDATE EXISTING
    # =========================

    Set-Location $installDir

    git fetch origin

    $local = git rev-parse HEAD
    $remote = git rev-parse origin/master

    if ($local -eq $remote) {
        Write-Host "Already up to date." -ForegroundColor Green
    }
    else {
        Write-Host "Updating jcombine..." -ForegroundColor Yellow

        git reset --hard origin/master

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Update failed." -ForegroundColor Red
            exit 1
        }

        Write-Host "Updated successfully." -ForegroundColor Green
    }

    Set-Location ..
}

# =========================
# FIX ENTRYPOINT NAME
# =========================
Rename-Item "$installDir\COMBINER.bat" "combine.bat" -ErrorAction SilentlyContinue

# =========================
# ADD TO USER PATH
# =========================
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$userPath;$installDir",
        "User"
    )
}

Write-Host "Ready." -ForegroundColor Green
Write-Host "Restart terminal if needed, then run: combine" -ForegroundColor Yellow