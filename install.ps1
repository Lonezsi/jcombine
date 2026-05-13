$repo = "Lonezsi/jcombine"
$installDir = "$env:USERPROFILE\jcombine"
$repoUrl = "https://github.com/$repo.git"

Write-Host "Installing / Updating jcombine..." -ForegroundColor Cyan

# =========================
# INSTALL OR UPDATE
# =========================
if (-not (Test-Path $installDir)) {

    git clone $repoUrl $installDir

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Clone failed." -ForegroundColor Red
        exit 1
    }

} else {

    Write-Host "Updating existing install..." -ForegroundColor Yellow

    Set-Location $installDir

    git fetch origin

    $branch = git rev-parse --abbrev-ref HEAD

    git reset --hard "origin/$branch"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Update failed." -ForegroundColor Red
        exit 1
    }

    Set-Location $PSScriptRoot
}

# =========================
# ENSURE ENTRYPOINT NAME
# =========================
$batOld = Join-Path $installDir "COMBINER.bat"
$batNew = Join-Path $installDir "combine.bat"

if ((Test-Path $batOld) -and (-not (Test-Path $batNew))) {
    Rename-Item $batOld "combine.bat" -ErrorAction SilentlyContinue
}

# =========================
# VERSION FILE SAFETY
# =========================
$versionFile = Join-Path $installDir "version.txt"

if (-not (Test-Path $versionFile)) {
    "0.0.0" | Set-Content $versionFile
}

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

Write-Host "Installed / Updated successfully." -ForegroundColor Green
Write-Host "Restart terminal then run: combine" -ForegroundColor Yellow