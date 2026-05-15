$repo = "Lonezsi/jcombine"
$installDir = "$env:USERPROFILE\jcombine"
$repoUrl = "https://github.com/$repo.git"

Write-Host "Installing / Updating jcombine..." -ForegroundColor Cyan

# =========================
# ENSURE INSTALL DIR EXISTS (IMPORTANT FIX)
# =========================
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

# =========================
# INSTALL OR UPDATE
# =========================
if (-not (Test-Path (Join-Path $installDir ".git"))) {

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
}

# =========================
# ENSURE ENTRYPOINT NAME
# =========================
$batOld = Join-Path $installDir "COMBINER.bat"
$batNew = Join-Path $installDir "combine.bat"

# FIX: no broken conditional logic
if (Test-Path $batOld) {
    Rename-Item $batOld "combine.bat" -Force -ErrorAction SilentlyContinue
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

# =========================
# ADD CONTEXT MENU ENTRIES
# =========================

$regPath = "HKCU:\Software\Classes\Directory\Background\shell\jcombine"
New-Item -Path $regPath -Force | Out-Null
Set-ItemProperty -Path $regPath -Name "(Default)" -Value "jcombine"
Set-ItemProperty -Path $regPath -Name "Icon" -Value "powershell.exe"
New-Item -Path "$regPath\command" -Force | Out-Null
Set-ItemProperty -Path "$regPath\command" -Name "(Default)" -Value "cmd /c cd /d `"%V`" && combine"

$regPath = "HKCU:\Software\Classes\*\shell\jpaste"
New-Item -Path $regPath -Force | Out-Null
Set-ItemProperty -Path $regPath -Name "(Default)" -Value "jpaste"
Set-ItemProperty -Path $regPath -Name "Icon" -Value "powershell.exe"
New-Item -Path "$regPath\command" -Force | Out-Null
$script = Join-Path $env:USERPROFILE "jcombine\jpaster.ps1"
Set-ItemProperty -Path "$regPath\command" -Name "(Default)" -Value "powershell -NoProfile -ExecutionPolicy Bypass -File `"$script`""


Write-Host "Installed / Updated successfully." -ForegroundColor Green
Write-Host "Restart terminal then run: combine" -ForegroundColor Yellow