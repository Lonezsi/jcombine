# jpaster.ps1 – copy a jcombine output file to clipboard
$outDir = Join-Path $PSScriptRoot "output"
if (-not (Test-Path $outDir)) {
    Write-Host "Output folder not found. Run jcombine first." -ForegroundColor Red
    pause
    exit 1
}

$files = Get-ChildItem -Path $outDir -Filter "*.txt" | ForEach-Object { $_.FullName }
if (-not $files) {
    Write-Host "No output files found." -ForegroundColor Red
    pause
    exit 1
}

# Build a simple console menu (arrow keys, enter)
$selected = 0
[Console]::CursorVisible = $false
while ($true) {
    Clear-Host
    Write-Host "Choose file to copy to clipboard:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $files.Count; $i++) {
        $name = Split-Path $files[$i] -Leaf
        if ($i -eq $selected) {
            Write-Host "> $name" -ForegroundColor Green
        } else {
            Write-Host "  $name"
        }
    }
    $key = [Console]::ReadKey($true)
    switch ($key.Key) {
        "UpArrow"   { if ($selected -gt 0) { $selected-- } }
        "DownArrow" { if ($selected -lt $files.Count - 1) { $selected++ } }
        "Enter"     {
            [Console]::CursorVisible = $true
            $content = Get-Content $files[$selected] -Raw
            Set-Clipboard -Value $content
            Write-Host "`nCopied $(Split-Path $files[$selected] -Leaf) to clipboard." -ForegroundColor Green
            pause
            exit 0
        }
        "Escape"    {
            [Console]::CursorVisible = $true
            exit 0
        }
    }
}