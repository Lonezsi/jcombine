$repo = "YOUR_GITHUB_USERNAME/combine-cli"

$installDir = "$env:USERPROFILE\combine-cli"

Write-Host "Installing combine..." -ForegroundColor Cyan

if (Test-Path $installDir) {
    Remove-Item $installDir -Recurse -Force
}

git clone "https://github.com/$repo.git" $installDir

$userPath = [Environment]::GetEnvironmentVariable(
    "Path",
    "User"
)

if ($userPath -notlike "*$installDir*") {

    [Environment]::SetEnvironmentVariable(
        "Path",
        "$userPath;$installDir",
        "User"
    )

    Write-Host "Added combine to PATH" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Restart terminal then run:" -ForegroundColor Yellow
Write-Host "combine" -ForegroundColor Cyan