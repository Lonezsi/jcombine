# jcombine

A PowerShell tool that packages a git repository into a single text file or chunked AI‑ready prompts – with full configurability and Windows context menu support.

## 🚀 Installation

Run this in PowerShell (admin not required):

```powershell
irm https://raw.githubusercontent.com/Lonezsi/jcombine/master/install.ps1 | iex
```

Restart your terminal afterward. The `combine` command will be available everywhere, and you'll also get two new right‑click options (see below).

## ✨ Features

- **Git‑aware** – collect only changed, tracked, and untracked files (or scan everything)
- **Mode filters** – `front`, `back`, `mix`, `all` with **configurable file extensions and root folders**
- **Three output styles**
  - `chunks` – split for LLMs with context limits
  - `bundle` – one file + start/end prompts
  - `just` – raw bundle, no prompts, no chunking
- **Interactive TUI** – arrow keys + Enter, or bypass with CLI flags
- **Customisable loading bar**, chunk size, ignore patterns, and **AI prompts** – all in `config.txt`
- **Local project overrides** – place a `.jcombine-config` in a repo to override the global `config.txt` values for that directory
- **Right‑click context menus**
  - Right‑click an **empty space in any folder** → `jcombine` runs the tool
  - Right‑click **any file** → `jpaste` lets you pick a chunk or bundle and copies it to the clipboard
- **Self‑update** – `combine --update` fetches the latest version

## 📋 Requirements

- Windows
- PowerShell 5.1+ or PowerShell 7+
- Git installed and available in `PATH`

## ⌨️ Usage

### Interactive mode

Navigate into any git repository and run:

```powershell
combine
```

Follow the menus to choose git filtering, project mode, and output style.

### CLI flags (skip the menus)

```powershell
combine --version                     Show version
combine --help                        Show this help
combine --update                      Download latest version
combine --gitfilter on|off            Force git‑aware filtering on/off
combine --mode front|back|mix|all     Preselect project mode
combine --outputmode chunks|bundle|just  Preselect output mode
combine --config                      Open config.txt in Notepad
combine --create-config               Generate a local .jcombine-config inferred from the project
```

Example – full repo, no prompts, directly:

```powershell
combine --gitfilter off --mode all --outputmode just
```

Flags may be combined (stacked) in any order, for example:

```powershell
combine --mode front --gitfilter on --outputmode chunks
```

## 📂 Output

Everything lands in the `output` folder (created next to `combine.ps1`).

| File                                  | Description                                     |
| ------------------------------------- | ----------------------------------------------- |
| `project-bundle.txt`                  | The combined file                               |
| `prompt_start.txt` / `prompt_end.txt` | AI prompt wrappers (`bundle` mode)              |
| `chunk_*.txt`                         | Each chunk with embedded prompt (`chunks` mode) |
| `chunk_end_prompt.txt`                | Final instruction after all chunks              |
| `EMPTY.txt`                           | Created when no files matched the filter        |

## 📋 Right‑click menus (Windows)

After installation, you'll have two new context menu entries:

- **`jcombine`** – right‑click an empty area inside any folder → starts `combine` in that directory.
- **`jpaste`** – right‑click **any file** → a small console menu lists all `.txt` files in `jcombine/output`. Select one with arrow keys and press Enter – its content is copied to the clipboard.

The helper script `jpaster.ps1` can also be run directly from the terminal.

## ⚙️ Configuration

Edit `config.txt` next to `combine.ps1`. All keys are optional – if omitted, sensible defaults are used.

| Key             | Example                                         | Description                                           |
| --------------- | ----------------------------------------------- | ----------------------------------------------------- |
| `loadingbar`    | `YIP E`                                         | Start string and repeating character for progress bar |
| `chunksize`     | `20000`                                         | Max characters per chunk                              |
| `ignore`        | `node_modules\|dist\|\.git`                     | Regex patterns to exclude (pipe‑separated)            |
| `mode_exts`     | `mode_exts:front\|.ts,.tsx,.js`                 | File extensions for `front` / `back` / `mix` / `all`  |
| `mode_roots`    | `mode_roots:front\|src/frontend,src/components` | Root folders for each mode                            |
| `prompt_start`  | `Here is my codebase...`                        | First prompt sent with chunk #1                       |
| `prompt_middle` | `Next part...`                                  | Prompt for subsequent chunks                          |
| `prompt_end`    | `This is the full codebase...`                  | Prompt after the last chunk (or with `bundle` mode)   |

Lines starting with `#` are comments and ignored.

Local overrides: if a `.jcombine-config` file exists in the directory where `combine` is run, its non-comment lines will override values from the global `config.txt` for that run.

## 🔔 Notes

- Must be run **inside** a git repository.
- Large repos may take a while – a progress bar keeps you informed.
- Clipboard copying from `combine` itself is temporarily disabled; use the `jpaste` right‑click menu instead for reliable clipboard access.
- The default ignore list already excludes `node_modules`, `dist`, `.git`, build folders, and IDE cache – you can extend it.

## 🛠️ Development

Clone the repo, make changes, and test locally by running `combine.ps1` directly.

Contributions and bug reports are welcome on GitHub.

---

Made with ❤️ for a smoother AI‑assisted workflow.
