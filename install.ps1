$repo = "Lonezsi/jcombine"
$installDir = "$env:USERPROFILE\jcombine"

Write-Host "Installing jcombine..." -ForegroundColor Cyan

if (Test-Path $installDir) {
    Remove-Item $installDir -Recurse -Force
}

git clone "https://github.com/$repo.git" $installDir

if ($LASTEXITCODE -ne 0) {
    Write-Host "Clone failed. Repo URL or access issue." -ForegroundColor Red
    exit 1
}

# IMPORTANT: enforce correct command name
Rename-Item "$installDir\COMBINER.bat" "combine.bat" -ErrorAction SilentlyContinue

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$userPath;$installDir",
        "User"
    )
}

Write-Host "Installed." -ForegroundColor Green
Write-Host "Restart terminal and run: combine" -ForegroundColor Yellow