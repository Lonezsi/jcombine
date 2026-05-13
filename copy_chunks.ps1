if (!(Test-Path "chunks")) {
    Write-Host "No output folder found" -ForegroundColor Red
    exit 1
}

Set-Location "chunks"

function Set-ClipboardUtf8 {
    param([string]$Path)

    $text = Get-Content $Path -Raw -Encoding UTF8
    Set-Clipboard -Value $text
}

# =========================
# EMPTY MODE
# =========================
if (Test-Path "EMPTY.txt") {

    Set-ClipboardUtf8 "EMPTY.txt"

    Write-Host ""
    Write-Host "Copied EMPTY RESULT" -ForegroundColor Yellow

    exit 0
}

# =========================
# JUST BUNDLE MODE
# =========================
if ((Test-Path "project-bundle.txt") -and !(Test-Path "chunk_1.txt")) {

    Set-ClipboardUtf8 "project-bundle.txt"

    Write-Host ""
    Write-Host "Copied FULL BUNDLE" -ForegroundColor Green
    Write-Host "Ready to paste." -ForegroundColor DarkGray

    exit 0
}

# =========================
# CHUNK MODE
# =========================
$files = Get-ChildItem chunk_*.txt -ErrorAction SilentlyContinue |
    Sort-Object {
        [int]($_.BaseName -replace "[^\d]", "")
    }

if (-not $files -or $files.Count -eq 0) {
    Write-Host "No chunks found" -ForegroundColor Yellow
    exit 0
}

$total = $files.Count
$current = 0

foreach ($f in $files) {

    $current++

    Write-Progress `
        -Activity "Copying chunks" `
        -Status "$current / $total" `
        -PercentComplete (($current / $total) * 100)

    Set-ClipboardUtf8 $f.FullName

    Write-Host ""
    Write-Host ("Copied " + $f.Name) -ForegroundColor Green

    Read-Host "Press ENTER for next"
}

Write-Progress `
    -Activity "Copying chunks" `
    -Completed

if (Test-Path "chunk_end_prompt.txt") {

    Set-ClipboardUtf8 "chunk_end_prompt.txt"

    Write-Host ""
    Write-Host "Copied FINAL PROMPT" -ForegroundColor Cyan
}