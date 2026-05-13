# =========================
# CLI PARAMS (top)
# =========================
param(
    [string]$arg
)

if ($arg -eq "--version") {
    $versionFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "version.txt"
    if (Test-Path $versionFile) {
        Get-Content $versionFile
    } else {
        "0.0.0"
    }
    exit 0
}

if ($arg -eq "--update") {
    Write-Host "Updating..." -ForegroundColor Yellow

    $installScript = "https://raw.githubusercontent.com/Lonezsi/jcombine/master/install.ps1"
    irm $installScript | iex

    exit 0
}

if ($arg -eq "--help") {
    Write-Host @"
jcombine

Usage:
  combine              Run interactive mode
  combine --version    Show version
  combine --help       Show help
  combine --update     Update jcombine

Output modes:
  chunks  -> chunked AI prompts
  bundle  -> single file bundle + prompts
  just    -> raw bundle only

Notes:
- Must run inside git repo
- Ignores node_modules, dist, .git
"@

    exit 0
}

# =========================
# SHORT & SAFE COLOR OUTPUT
# =========================
function say {
    param(
        [string]$m,

        [ValidateSet('info','success','error','warning','normal')]
        [string]$t = 'normal',

        [ConsoleColor]$Color,

        [switch]$NoNewLine
    )

    try {
        $params = @{}
        if ($NoNewLine) { $params["NoNewLine"] = $true }

        switch ($t) {

            'info' {
                Write-Host "[INFO] " -ForegroundColor Cyan -NoNewline
                Write-Host $m -ForegroundColor Gray @params
            }

            'success' {
                Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline
                Write-Host $m @params
            }

            'error' {
                Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
                Write-Host $m -ForegroundColor Red @params
            }

            'warning' {
                Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline
                Write-Host $m @params
            }

            default {
                if ($Color) {
                    Write-Host $m -ForegroundColor $Color @params
                } else {
                    Write-Host $m @params
                }
            }
        }
    }
    catch {
        Write-Host $m
    }
}

# =========================
# MODE OPTIONS (CONFIG)
# =========================
$modeOptions = @(
    @{
        key = "front"
        label = "[Front] - frontend only (.ts/.tsx/.js/.jsx/.css/.html/.md)"
        roots = @("telco-frontend")
        exts = @(".ts",".tsx",".js",".jsx",".css",".html",".md")
    },
    @{
        key = "back"
        label = "[Back] - backend only (.java/.xml)"
        roots = @("telco-backend")
        exts = @(".java",".xml")
    },
    @{
        key = "mix"
        label = "[Mix] - frontend + backend (code + docs)"
        roots = @("telco-frontend","telco-backend")
        exts = @(".ts",".tsx",".js",".jsx",".css",".html",".md",".java",".xml")
    },
    @{
        key = "all"
        label = "[All] - full repo (everything)"
        roots = @("")
        exts = @("*")
    }
)

# =========================
# TUI MENU
# =========================
function Show-TUIMenu {
    param (
        [string]$Title,
        [string[]]$Options
    )

    $selected = 0
    [Console]::CursorVisible = $false

    function Render-Option($text, $isSelected) {

        $main = $text
        $extra = ""

        if ($text -match "^(.*?)(\s*\(.*\))$") {
            $main = $matches[1]
            $extra = $matches[2]
        }

        if ($isSelected) {
            Write-Host "> " -NoNewline -ForegroundColor Green
            Write-Host $main -ForegroundColor Green -NoNewline
        } else {
            Write-Host "  " -NoNewline
            Write-Host $main -NoNewline
        }

        if ($extra) {
            Write-Host $extra -ForegroundColor DarkGray
        } else {
            Write-Host ""
        }
    }

    while ($true) {
        Clear-Host
        say -m $Title -Color Cyan
        say -m ""

        for ($i = 0; $i -lt $Options.Length; $i++) {
            Render-Option $Options[$i] ($i -eq $selected)
        }

        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            "UpArrow"   { if ($selected -gt 0) { $selected-- } }
            "DownArrow" { if ($selected -lt $Options.Length - 1) { $selected++ } }
            "Enter"     {
                [Console]::CursorVisible = $true
                return $Options[$selected]
            }
        }
    }
}

# =========================
# OUTPUT DIRECTORY
# =========================

$toolRoot = Split-Path -Parent $PSCommandPath
$outDir = Join-Path $toolRoot "output"

# =========================
# GIT ROOT
# =========================
$root = git rev-parse --show-toplevel 2>$null
if (-not $root) {
    say -m "Not a git repo!" error
    exit 1
}

Set-Location $root

# =========================
# GIT MODE MENU
# =========================
$gitRaw = Show-TUIMenu "Use git-aware filtering?" @(
    "[yes] - only changes (added/modified/untracked)",
    "[no] - full scan"
)

$useGit = $gitRaw.StartsWith("yes")

# =========================
# FILE COLLECTION (FIRST!)
# =========================
if ($useGit) {

    $tracked = git ls-files
    $modified = git diff --name-only
    $untracked = git ls-files --others --exclude-standard

    $allFiles = @()
    $allFiles += $tracked
    $allFiles += $modified
    $allFiles += $untracked

} else {

    $rootPath = Get-Location

    $allFiles = Get-ChildItem -Recurse -File | ForEach-Object {
        $_.FullName.Replace($rootPath.Path + "\", "")
    }
}

$allFiles = $allFiles | Sort-Object -Unique

# =========================
# MODE SELECTION (NOW SAFE)
# =========================
$modeRaw = Show-TUIMenu "Select mode:" ($modeOptions.label)

$selectedMode = $modeOptions | Where-Object {
    $modeRaw -eq $_.label
}

if (-not $selectedMode) {
    say -m "Invalid mode selection" error
    exit 1
}

# =========================
# FILTER
# =========================
$files = $allFiles | Where-Object {

    $p = $_

    # ignore tooling
    if ($p -match "combine\.ps1|COMBINER\.bat|Makefile") {
        return $false
    }

    # ignore junk
    if ($p -match "node_modules|dist|\.git|\.vs|\.vscode|\.idea|\.cache|\.next|\.nuxt|\.output|\.expo|\.expo-shared|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|\.log|\.env") {
        return $false
    }

    # root filter
    if ($selectedMode.roots.Count -gt 0 -and $selectedMode.roots[0] -ne "") {

        $matchRoot = $false

        foreach ($r in $selectedMode.roots) {
            if ($p -match "^$r") {
                $matchRoot = $true
            }
        }

        if (-not $matchRoot) { return $false }
    }

    # extension filter
    if ($selectedMode.exts[0] -ne "*") {

        $ext = [System.IO.Path]::GetExtension($p)

        if ($selectedMode.exts -notcontains $ext) {
            return $false
        }
    }

    return $true
}

# =========================
# FULL PATHS
# =========================
$rootPath = (Get-Location).Path

$files = $files | ForEach-Object {
    Join-Path $rootPath $_
}

# =========================
# NO CHANGES GUARD
# =========================
if (-not $files -or $files.Count -eq 0) {

    if (Test-Path $outDir) {
        Remove-Item $outDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $outDir -Force | Out-Null

    $emptyFile = Join-Path $outDir "EMPTY.txt"

    @"
No files matched the selected mode/filter.

Possible reasons:
- no git changes
- selected mode excludes files
- ignored directories removed everything
"@ | Set-Content $emptyFile

    say -m ""
    say -m "No changes detected in selected scope" info
    say -m "Created EMPTY.txt for tooling compatibility." -Color DarkGray

    exit 0
}

# =========================
# OUTPUT MODE
# =========================
$outputModeRaw = Show-TUIMenu "Select output mode:" @(
    "[chunks] - chunks + prompts",
    "[bundle] - bundle + prompts",
    "[just] - just bundle"
)

$outputMode = switch -Regex ($outputModeRaw) {
    "^\[chunks\]" { "chunks" }
    "^\[bundle\]" { "bundle" }
    "^\[just\]"   { "just" }
}

# =========================
# OUTPUT
# =========================

if (Test-Path $outDir) {
    Remove-Item $outDir -Recurse -Force
}

New-Item -ItemType Directory -Path $outDir | Out-Null

$outFile = Join-Path $outDir "project-bundle.txt"

$totalFiles = $files.Count
$currentFile = 0

say -m ""
say -m "Building bundle..." info

# ---- LOAD LOADING BAR CONFIG ----
$configPath = Join-Path $PSScriptRoot "config.txt"
$startString = "YIP"
$repeatingChar = "E"

if (Test-Path $configPath) {
    $configLines = Get-Content $configPath
    foreach ($line in $configLines) {
        $trimmed = $line.TrimStart()
        if ($trimmed -match '^#' -or $trimmed -eq '') { continue }
        if ($trimmed -match '^loadingbar:\s*(.+)$') {
            $rawValue = $matches[1].Trim()
            $spaceIndex = $rawValue.IndexOf(' ')
            if ($spaceIndex -gt 0) {
                $startString   = $rawValue.Substring(0, $spaceIndex)
                $repeatingChar = $rawValue.Substring($spaceIndex + 1).Trim()
            } else {
                $startString   = ""
                $repeatingChar = $rawValue
            }
            break
        }
    }
}

# ---- HIDE CURSOR & BUILD ----
$originalCursorVisible = [Console]::CursorVisible
[Console]::CursorVisible = $false

try {
    foreach ($file in $files) {
        $currentFile++

        $barWidthUnits = 20
        $filledUnits = [math]::Floor(($currentFile / $totalFiles) * $barWidthUnits)

        $barFill  = $startString + ($repeatingChar * $filledUnits)
        $barEmpty = " " * ($barWidthUnits - $filledUnits)

        Write-Host -NoNewline ("`rCreating bundle: [${barFill}${barEmpty}] $currentFile / $totalFiles files")

        if (!(Test-Path $file)) { continue }

        Add-Content $outFile "===================="
        Add-Content $outFile $file
        Add-Content $outFile "===================="

        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue

        if ([string]::IsNullOrWhiteSpace($content)) {
            Add-Content $outFile "[EMPTY FILE]"
        } else {
            Add-Content $outFile $content
        }

        Add-Content $outFile "`r`n"
    }
    Write-Host ""
}
finally {
    [Console]::CursorVisible = $originalCursorVisible
}

# =========================
# COPY TO CLIPBOARD
# =========================
try {

    Set-Clipboard -Path $outFile

    say -m ""
    say -m "Bundle copied to clipboard" success

}
catch {

    try {

        Get-Content $outFile -Raw | Set-Clipboard

        say -m ""
        say -m "Bundle content copied to clipboard" success

    }
    catch {

        say -m ""
        say -m "Failed to copy bundle to clipboard" warning
    }
}

say -m "Bundle created: $outFile" success

# =========================
# PROMPTS
# =========================
$startPrompt = @"
Here is my codebase. Please read it carefully.
Reply only with "OK".
I will send more parts after this.
"@

$middlePrompt = @"
Next part of the code. Reply only "OK".
"@

$endPrompt = @"
This is the full codebase.

Now:
- analyze architecture
- find logic issues
- suggest improvements
- point out edge cases

Ask questions if something is unclear.
"@

# =========================
# JUST BUNDLE
# =========================
if ($outputMode -eq "just") {

    say -m ""
    say -m "Bundle created only (no prompts/chunks)." success
    say -m "Ready to paste." -Color DarkGray

    exit 0
}

# =========================
# BUNDLE + PROMPTS
# =========================
if ($outputMode -eq "bundle") {

    Set-Content (Join-Path $outDir "prompt_start.txt") $startPrompt
    Set-Content (Join-Path $outDir "prompt_end.txt") $endPrompt

    say -m ""
    say -m "Bundle + prompts created." success
    exit 0
}

# =========================
# CHUNKING
# =========================
$chunkSize = 20000
$content = Get-Content $outFile -Raw

Get-ChildItem (Join-Path $outDir "chunk_*.txt") -ErrorAction SilentlyContinue | Remove-Item

$index = 0
$chunkNumber = 1

say -m ""
say -m "Creating chunks..." info
say -m "Total size: $($content.Length) chars | Chunk size: $chunkSize chars" -Color DarkGray
say -m "Chunks:" -Color DarkGray
say -m "[" -Color DarkGray -NoNewLine

while ($index -lt $content.Length) {

    $chunk = $content.Substring(
        $index,
        [Math]::Min($chunkSize, $content.Length - $index)
    )

    $chunkFile = Join-Path $outDir "chunk_$chunkNumber.txt"

    $fullChunk = if ($chunkNumber -eq 1) {
        $startPrompt + "`r`n`r`n" + $chunk
    } else {
        $middlePrompt + "`r`n`r`n" + $chunk
    }

    Set-Content $chunkFile $fullChunk

    say -m "chunk_$chunkNumber.txt | " -Color Green -NoNewLine

    $index += $chunkSize
    $chunkNumber++
}

Set-Content (Join-Path $outDir "chunk_end_prompt.txt") $endPrompt

say -m "chunk_end_prompt.txt" -Color Cyan -NoNewLine
say -m " ]" -Color DarkGray

say -m ""
say -m "All chunks created in: $outDir" success