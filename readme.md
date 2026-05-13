# jcombine

PowerShell tool that bundles a git repository into a single text file or chunked prompt format for AI tools.

## Features

- Git-aware file selection (tracked, modified, untracked)
- Mode filtering (frontend, backend, mixed, full repo)
- Bundle output or chunked output
- AI prompt templates included
- Clipboard copy support
- TUI selection menu

## Requirements

- Windows
- PowerShell 5+ or PowerShell 7+
- Git installed and available in PATH

## Install

Run in PowerShell:

```powershell
irm https://raw.githubusercontent.com/Lonezsi/jcombine/main/install.ps1 | iex
```

Restart the terminal after install.

## Usage

Run inside any git repository:

```powershell
combine
```

You will be prompted to:

- Select git mode (changes only or full scan)
- Select project mode (front, back, mix, all)
- Select output mode (chunks, bundle, just bundle)

## Output modes

- `chunks` — Splits repository into multiple files with AI prompts per chunk.
- `bundle` — Creates a single bundled file with optional prompts.
- `just` — Creates only the bundle without prompts or chunking.

## Output location

- `chunks/project-bundle.txt`
- `chunks/chunk_*.txt`

## Copy tool

After generation, run:

```powershell
copy_chunks
```

This will copy each chunk to the clipboard one by one for pasting into an AI tool.

## Notes

- Large repos may take time to process.
- `node_modules`, `dist`, `.git` are ignored by default.
- Chunk size is fixed in script (20k chars).
