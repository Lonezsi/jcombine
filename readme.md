# jcombine

A PowerShell tool that packages a git repository into a single text file or chunked AI‑ready prompts, right from your terminal.

## 🚀 Installation

Run this in PowerShell (admin not required):

```powershell
irm https://raw.githubusercontent.com/Lonezsi/jcombine/master/install.ps1 | iex
```

## ✨ Features

- **Git‑aware** – collect only changed, tracked, and untracked files (or scan everything)
- **Mode filters** – `front`, `back`, `mix`, `all` to target specific parts of your repo
- **Three output styles**
  - `chunks` – split for LLMs with context limits
  - `bundle` – one file plus start/end prompts
  - `just` – raw bundle, no prompts, no chunking
- **Interactive TUI** – select options with arrow keys and Enter, or use **CLI flags** for scripting
- **Customisable loading bar** and **chunk size** via `config.txt`
- **Configurable ignore patterns** – exclude any files or folders you want
- **Self‑update** – `combine --update` fetches the latest version

## 📋 Requirements

- Windows
- PowerShell 5.1+ or PowerShell 7+
- Git installed and available in `PATH`

Then restart your terminal. The `combine` command will be available everywhere.

## ⌨️ Usage

Interactive mode

Navigate into any git repository and run:

```powershell
combine
```

Follow the menus to choose:

- Git‑aware filtering (yes/no)
- Project mode (front, back, mix, all)
- Output mode (chunks, bundle, just)

CLI flags (no menus):

```powershell
combine --version            # Show version
combine --help               # Show help
combine --update             # Download latest version
combine --gitfilter on|off   # Force git‑aware filtering on/off
combine --mode front|back|mix|all
combine --outputmode chunks|bundle|just
```

Example — directly create a full-repo bundle without any prompts:

```powershell
combine --gitfilter off --mode all --outputmode just
```

## 📂 Output

Everything lands in the `output` folder (created next to `combine.ps1`). Typical files:

- `project-bundle.txt` — the combined file
- `prompt_start.txt` / `prompt_end.txt` — AI prompt wrappers (when using `bundle`)
- `chunk_*.txt` — each chunk with an embedded prompt (when using `chunks`)
- `chunk_end_prompt.txt` — the final instruction after all chunks

If no files match your selection, an `EMPTY.txt` is created to signal tooling compatibility.

## ⚙️ Configuration

The file `config.txt` sits next to `combine.ps1`. You can edit these values:

| Key          | Example        | Description                                           |
| ------------ | -------------- | ----------------------------------------------------- |
| `loadingbar` | `YIP E`        | Start string and repeating character for progress bar |
| `chunksize`  | `20000`        | Max characters per chunk                              |
| `ignore`     | `node_modules` | Will ignore matching files                            |

Lines starting with `#` are comments and are ignored.

## 🔔 Notes

- Must be run inside a git repository.
- Large repos may take a while — the progress bar shows current status.
- Clipboard copying is temporarily disabled due to random issues; it will be re‑enabled in a future release.
- `node_modules`, `dist`, `.git`, and common build/cache folders are ignored by default, but you can change this in `config.txt`.

## 🛠️ Development

Clone the repo, make changes, and test locally by running `combine.ps1` directly.

Contributions and bug reports are welcome on GitHub.

Made with ❤️ for a smoother AI‑assisted workflow.
