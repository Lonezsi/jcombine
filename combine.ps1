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
# config
# =========================

$configPath = Join-Path $PSScriptRoot "config.txt"
$startString = "YIP"
$repeatingChar = "E"

$chunkSize = 20000

$ignorePatterns = "\.env"

$customExts        = @{}         # e.g. $customExts["front"] = @(".ts", ...)
$customRoots = @{}         # e.g. $customRoots["front"] = @("src/frontend", ...)
$promptStart       = $null
$promptMiddle      = $null
$promptEnd         = $null

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
            continue
        }

        # chunk size
        if ($trimmed -match '^chunksize:\s*(\d+)$') {
            $chunkSize = [int]$matches[1]
            continue
        }

        # ignore patterns (regex)
        if ($trimmed -match '^ignore:\s*(.+)$') {
            $ignorePatterns = $matches[1].Trim()
            continue
        }

        # Custom extensions per mode
        if ($trimmed -match '^mode_exts:\s*([^|]+)\|(.+)$') {
            $modeKey = $matches[1].Trim().ToLower()
            $extsRaw = $matches[2].Trim()
            # Empty or just whitespace → no filtering (like '*')
            if ([string]::IsNullOrWhiteSpace($extsRaw) -or $extsRaw -eq '*') {
                $customExts[$modeKey] = @('*')
            } else {
                $exts = $extsRaw -split ',' | ForEach-Object { $_.Trim() }
                $exts = $exts | ForEach-Object { if ($_ -ne '*') { if ($_ -notmatch '^\.') { ".$_" } else { $_ } } else { $_ } }
                $customExts[$modeKey] = $exts
            }
            continue
        }

        # Custom roots per mode
        if ($trimmed -match '^mode_roots:\s*([^|]+)\|(.*)$') {
            $modeKey = $matches[1].Trim().ToLower()
            $rootsRaw = $matches[2].Trim()
            if ($rootsRaw -eq '') {
                $customRoots[$modeKey] = @('')
            } else {
                $roots = $rootsRaw -split ',' | ForEach-Object { $_.Trim() }
                # Ensure empty entries become empty string (for 'all')
                $roots = $roots | ForEach-Object { if ($_ -eq '') { '' } else { $_ } }
                $customRoots[$modeKey] = $roots
            }
            continue
        }

        # Custom prompts (replace \n with actual newlines)
        if ($trimmed -match '^prompt_start:\s*(.*)$') {
            $promptStart = $matches[1].Trim() -replace '\\n', "`r`n"
            continue
        }
        if ($trimmed -match '^prompt_middle:\s*(.*)$') {
            $promptMiddle = $matches[1].Trim() -replace '\\n', "`r`n"
            continue
        }
        if ($trimmed -match '^prompt_end:\s*(.*)$') {
            $promptEnd = $matches[1].Trim() -replace '\\n', "`r`n"
            continue
        }
    }
}

# Check for local override config in current working directory
$localConfigPath = Join-Path (Get-Location) ".jcombine-config"
if (Test-Path $localConfigPath) {
    $localConfigLines = Get-Content $localConfigPath
    foreach ($line in $localConfigLines) {
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
            continue
        }

        if ($trimmed -match '^chunksize:\s*(\d+)$') {
            $chunkSize = [int]$matches[1]
            continue
        }

        if ($trimmed -match '^ignore:\s*(.+)$') {
            $ignorePatterns = $matches[1].Trim()
            continue
        }

        if ($trimmed -match '^mode_exts:\s*([^|]+)\|(.+)$') {
            $modeKey = $matches[1].Trim().ToLower()
            $extsRaw = $matches[2].Trim()
            if ([string]::IsNullOrWhiteSpace($extsRaw) -or $extsRaw -eq '*') {
                $customExts[$modeKey] = @('*')
            } else {
                $exts = $extsRaw -split ',' | ForEach-Object { $_.Trim() }
                $exts = $exts | ForEach-Object { if ($_ -ne '*') { if ($_ -notmatch '^\.') { ".$_" } else { $_ } } else { $_ } }
                $customExts[$modeKey] = $exts
            }
            continue
        }

        if ($trimmed -match '^mode_roots:\s*([^|]+)\|(.*)$') {
            $modeKey = $matches[1].Trim().ToLower()
            $rootsRaw = $matches[2].Trim()
            if ($rootsRaw -eq '') {
                $customRoots[$modeKey] = @('')
            } else {
                $roots = $rootsRaw -split ',' | ForEach-Object { $_.Trim() }
                $roots = $roots | ForEach-Object { if ($_ -eq '') { '' } else { $_ } }
                $customRoots[$modeKey] = $roots
            }
            continue
        }

        if ($trimmed -match '^prompt_start:\s*(.*)$') {
            $promptStart = $matches[1].Trim() -replace '\\n', "`r`n"
            continue
        }
        if ($trimmed -match '^prompt_middle:\s*(.*)$') {
            $promptMiddle = $matches[1].Trim() -replace '\\n', "`r`n"
            continue
        }
        if ($trimmed -match '^prompt_end:\s*(.*)$') {
            $promptEnd = $matches[1].Trim() -replace '\\n', "`r`n"
            continue
        }
    }
    say -m "Loaded local config: $localConfigPath" info -Color Cyan
}

# =========================
# DEFAULTS FOR CUSTOM EXTS
# =========================
$defaultExts = @{
    front = @(".ts", ".tsx", ".js", ".jsx", ".css", ".html", ".md")
    back  = @(".java", ".xml")
    all   = @("*")
}

# =========================
# DEFAULTS FOR CUSTOM ROOTS
# =========================
$defaultRoots = @{
    front = @("frontend")
    back  = @("backend")
    all   = @("")
}

foreach ($key in @("front", "back", "all")) {
    if (-not $customRoots.ContainsKey($key) -or -not $customRoots[$key]) {
        $customRoots[$key] = $defaultRoots[$key]
    }
}

# If mix not explicitly defined, create it from front + back
if (-not $customRoots.ContainsKey("mix") -or -not $customRoots["mix"]) {
    $customRoots["mix"] = ($customRoots["front"] + $customRoots["back"]) | Sort-Object -Unique
}

# =========================
# VERSION
# =========================

$versionFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "version.txt"
if (Test-Path $versionFile) {
    $version = Get-Content $versionFile
} else {
    $version = "0.0.0"
}

# Ensure each known mode has a definition
foreach ($key in @("front", "back", "all")) {
    if (-not $customExts.ContainsKey($key) -or -not $customExts[$key]) {
        $customExts[$key] = $defaultExts[$key]
    }
}

# If mix not explicitly defined, create it from front + back
if (-not $customExts.ContainsKey("mix") -or -not $customExts["mix"]) {
    $customExts["mix"] = ($customExts["front"] + $customExts["back"]) | Sort-Object -Unique
}


# =========================
# ARG PARSING (supports multiple flags)
# =========================

$useGit = $null
$mode = $null
$outputMode = $null
$cliArgs = $args

$targetDir = $null

$useGit = $null
$mode = $null
$outputMode = $null

if (-not $cliArgs) { $cliArgs = @() }

$i = 0
while ($i -lt $cliArgs.Count) {
    $a = $cliArgs[$i]
    # If the argument does not start with a dash, treat it as the target directory
    if ($a -notlike '-*') {
        if (-not $targetDir) {
            $targetDir = $a
            $i += 1
            continue
        } else {
            say -m "Multiple directories provided: $a" error -Color Red
            exit 1
        }
    }
    switch ($a) {
        '--version' {
            say -m "v$version" info -Color Cyan
            exit 0
        }
        '--update' {
            $currentDir = Get-Location
            say -m "Updating jcombine..." info -Color Yellow
            $installScript = "https://raw.githubusercontent.com/Lonezsi/jcombine/master/install.ps1"
            irm $installScript | iex
            set-location $currentDir
            exit 0
        }
        '--gitfilter' {
            if ($i + 1 -ge $cliArgs.Count) { say -m "Missing value for --gitfilter" error -Color Red; exit 1 }
            $val = $cliArgs[$i + 1]
            if ($val -eq 'on') { $useGit = $true; say -m "Git-aware filtering enabled." success -Color Green }
            elseif ($val -eq 'off') { $useGit = $false; say -m "Git-aware filtering disabled." warning -Color Yellow }
            else { say -m "Unknown gitfilter option: $val" error -Color Red; exit 1 }
            $i += 1
        }
        '--mode' {
            if ($i + 1 -ge $cliArgs.Count) { say -m "Missing value for --mode" error -Color Red; exit 1 }
            $val = $cliArgs[$i + 1]
            switch ($val) {
                'front' { $mode = 'front' }
                'back'  { $mode = 'back' }
                'mix'   { $mode = 'mix' }
                'all'   { $mode = 'all' }
                default { say -m "Unknown mode: $val" error -Color Red; exit 1 }
            }
            $i += 1
        }
        '--outputmode' {
            if ($i + 1 -ge $cliArgs.Count) { say -m "Missing value for --outputmode" error -Color Red; exit 1 }
            $val = $cliArgs[$i + 1]
            switch ($val) {
                'chunks' { $outputMode = 'chunks' }
                'bundle' { $outputMode = 'bundle' }
                'just'   { $outputMode = 'just' }
                default { say -m "Unknown output mode: $val" error -Color Red; exit 1 }
            }
            $i += 1
        }
        '--config' {
            try { notepad $configPath; exit 0 } catch { say -m "Failed to open config file: $configPath" error -Color Red; exit 1 }
        }
        '--create-config' {
            $outPath = Join-Path (Get-Location) ".jcombine-config"
            if (Test-Path $outPath) { say -m "Local config already exists: $outPath" warning -Color Yellow; exit 1 }

            # Detect candidate root folders
            $dirs = Get-ChildItem -Directory -Name -ErrorAction SilentlyContinue
            $frontDirs = $dirs | Where-Object { $_ -match '(?i)front|frontend|front-end' }
            $backDirs  = $dirs | Where-Object { $_ -match '(?i)back|backend|back-end' }

            # Detect file extensions in the project
            $files = Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue
            $exts = $files | ForEach-Object { $_.Extension.ToLower() } | Where-Object { $_ -ne '' } | Sort-Object -Unique
            $extsList = $exts -join '|'

            $lines = @()
            $lines += '# This is a local .jcombine-config generated by `combine --create-config`'
            $lines += '# You can edit these values to customise jcombine for this project.'
            $lines += ''
            $lines += '# ----- Loading bar -----'
            $lines += '#loadingbar:YIP E'
            $lines += ''
            $lines += '#size of a chunk when chunking (default 20000)'
            $lines += '#chunksize:20000'
            $lines += ''
            $lines += '#allows you to customise what to ignore (ignore:<pattern1>|<pattern2>...)'
            if ($ignorePatterns) { $lines += '#ignore:' + $ignorePatterns } else { $lines += '#ignore:node_modules|dist|\.git' }
            $lines += ''
            $lines += '#detected extensions in your project:'
            if ($extsList) { $lines += '#' + $extsList } else { $lines += '#.txt' }
            $lines += ''
            $lines += '# ----- Roots -----'
            $lines += '# root types: front, back, mix, all'

            if ($frontDirs) {
                foreach ($d in $frontDirs) { $lines += "mode_roots:front|$d" }
            }
            if ($backDirs) {
                foreach ($d in $backDirs) { $lines += "mode_roots:back|$d" }
            }
            if ($frontDirs -and $backDirs) {
                $mix = ($frontDirs + $backDirs) | Sort-Object -Unique
                $lines += "mode_roots:mix|$($mix -join ',')"
            }
            $lines += 'mode_roots:all|'
            $lines += ''
            $lines += '# ----- Custom file extensions per mode -----'
            $lines += '# modes: front, back, mix, all'
            $lines += '# Format: mode_exts:<mode>|<ext1>,<ext2>,...'
            if ($extsList) { $lines += '#mode_exts:all|' + ($exts -join ',') }
            $lines += ''
            $lines += '# ----- Custom AI prompts -----'
            $lines += '#prompt_start:...'
            $lines += '#prompt_middle:...'
            $lines += '#prompt_end:...'

            $lines | Out-File -FilePath $outPath -Encoding utf8
            say -m "Created local config: $outPath" success -Color Green
            exit 0
        }
        '--help' {
            say -m ""
            say -m "jcombine" -Color Cyan
            say -m ""
            say -m "Usage:" -Color Yellow
            say -m "    combine              Run interactive mode" -Color Gray
            say -m "    combine --version    Show version (current: $version)" -Color Gray
            say -m "    combine --help       Show this help" -Color Gray
            say -m "    combine --update     Update jcombine" -Color Gray
            say -m "    combine --config     Open global config file" -Color Gray
            say -m "    combine --create-config   Create a local config file in current directory with project-specific settings" -Color Gray
            say -m "    possible flags:" -Color Yellow
            say -m "    combine --gitfilter <on|off>     Enable/disable git-aware filtering" -Color Gray
            say -m "    combine --mode <front|back|mix|all>   Select file filtering mode" -Color Gray
            say -m "    combine --outputmode <chunks|bundle|just>   Select output mode" -Color Gray
            say -m ""   
            say -m "Modes:" -Color Yellow
            say -m "    front -> frontend files only ($($customExts['front'] -join ', ')) from $($customRoots['front'] -join ', ')" -Color DarkGray
            say -m "    back  -> backend files only ($($customExts['back'] -join ', ')) from $($customRoots['back'] -join ', ')" -Color DarkGray
            say -m "    mix   -> frontend + backend ($($customExts['mix'] -join ', ')) from $($customRoots['mix'] -join ', ')" -Color DarkGray
            say -m "    all   -> everything (no filtering) from command run location (no filtering)" -Color DarkGray
            say -m "" -Color Gray
            say -m "Output modes:" -Color Yellow
            say -m "    chunks  -> chunked AI prompts (splits into $chunkSize-character segments (configurable))" -Color DarkGray
            say -m "    bundle  -> single file bundle + prompts (prompts configurable)" -Color DarkGray
            say -m "    just    -> raw bundle only" -Color DarkGray
            say -m "" -Color Gray
            say -m "Notes:" -Color Yellow
            say -m "    - Must run inside a git repo" -Color DarkGray
            say -m "    - Ignored files are configurable (config.txt)" -Color DarkGray
            say -m "    - Loading bar style and chunk size are configurable" -Color DarkGray
            say -m "    - Local config (.jcombine-config) can override global config.txt for project-specific settings" -Color DarkGray
            say -m "    - Custom file extensions can be defined for each mode" -Color DarkGray
            say -m "    - Custom AI prompts can be defined in config (prompt_start, prompt_middle, prompt_end)" -Color DarkGray
            say -m "    - Output is saved to the 'output' folder in the tool directory" -Color DarkGray
            say -m "" -Color Gray
            say -m "Config path: $configPath" -Color Magenta
            say -m "" 
            exit 0
        }
        Default {
            say -m "Unknown argument: $a" error -Color Red
            say -m "Use --help for usage info." warning -Color Yellow
            exit 1
        }
    }
    $i += 1
}

if ($targetDir) {
    try {
        $resolved = Resolve-Path -Path $targetDir -ErrorAction Stop
        $targetPath = $resolved.Path
        if (-not (Test-Path $targetPath -PathType Container)) {
            say -m "Not a directory: $targetDir" error -Color Red
            exit 1
        }
        Set-Location $targetPath
        say -m "Running in directory: $targetPath" info -Color Cyan
    }
    catch {
        say -m "Invalid directory: $targetDir" error -Color Red
        exit 1
    }
}

    

# =========================
# MODE OPTIONS (CONFIG)
# =========================
$modeOptions = @(
    @{
        key = "front"
        label = "[Front] - frontend only ($($customExts['front'] -join ', ')) from $($customRoots['front'] -join ', ')"
        roots = $customRoots['front']
        exts = $customExts['front']
    },
    @{
        key = "back"
        label = "[Back] - backend only ($($customExts['back'] -join ', ')) from $($customRoots['back'] -join ', ')"
        roots = $customRoots['back']
        exts = $customExts['back']
    },
    @{
        key = "mix"
        label = "[Mix] - frontend + backend ($($customExts['mix'] -join ', ')) from $($customRoots['mix'] -join ', ')"
        roots = $customRoots['mix']
        exts = $customExts['mix']
    },
    @{
        key = "all"
        label = "[All] - full repo (everything) from command run location (no filtering)"
        roots = $customRoots['all']
        exts = $customExts['all']
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
            "Escape"    {
                [Console]::CursorVisible = $true
                return $null
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
if ($useGit -eq $null) {
    $gitRaw = Show-TUIMenu "Use git-aware filtering?" @(
        "[yes] - only changes (added/modified/untracked)",
        "[no] - full scan"
    )
    if (-not $gitRaw) {
        say -m "Selection shut down by user. Exiting..." error
        exit 1
    }

    $useGit = $gitRaw.StartsWith("yes")
}

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
# MODE SELECTION
# =========================
$selectedMode = $null

if ($mode) {
    $selectedMode = $modeOptions | Where-Object { $mode -eq $_.key }
} else {
    $modeRaw = Show-TUIMenu "Select mode:" ($modeOptions.label)
    $selectedMode = $modeOptions | Where-Object { $modeRaw -eq $_.label }
}

if (-not $selectedMode) {
    say -m "Selection shut down by user. Exiting..." error
    exit 1
}

# =========================
# FILTER
# =========================
$filtered = 0
$files = $allFiles | Where-Object {

    $p = $_

    #ignore from config
    if ($p -match $ignorePatterns) {
        $filtered++
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
if (-not $outputMode) {
    $outputModeRaw = Show-TUIMenu "Select output mode:" @(
        "[chunks] - chunks + prompts (ideal for LLMs with context limits | chunksize: $chunkSize chars (configurable))",
        "[bundle] - bundle + prompts (ideal for human review)",
        "[just] - just bundle (no prompts, no chunking, raw output - ideal for pasting into code editors or sharing as file)"
    )

    $outputMode = switch -Regex ($outputModeRaw) {
        "^\[chunks\]" { "chunks" }
        "^\[bundle\]" { "bundle" }
        "^\[just\]"   { "just" }
    }
}

if (-not $outputMode) {
    say -m "Selection shut down by user. Exiting..." error
    exit 1
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
<# temporarily disabled due to random clipboard issues - will re-enable in future
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
}#>
say -m ""
say -m "(Filtered out: $filtered ) (Clipboard copy temporarily disabled)"-Color DarkGray
say -m "files config can be found here: $configPath" -Color DarkGray
say -m ""
say -m "Bundle created: $outFile" success

# =========================
# PROMPTS
# =========================
if ($promptStart) {
    $startPrompt = $promptStart
} else { 
    $startPrompt = @"
Here is my codebase. Please read it carefully.
Reply only with "OK".
I will send more parts after this.
"@
}

if ($promptMiddle) {
    $middlePrompt = $promptMiddle
} else {
    $middlePrompt = @"
Next part of the code. Reply only "OK".
"@
}

if ($promptEnd) {
    $endPrompt = $promptEnd
} else {
    $endPrompt = @"
This is the full codebase.

Now:
- analyze architecture
- find logic issues
- suggest improvements
- point out edge cases

Ask questions if something is unclear.
"@
}

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