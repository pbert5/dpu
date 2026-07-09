need to resolve dups # Claude Working Agreement — DPU

## Required First Steps

1. Call `mcp__plugin_claude-code-home-manager_serena__initial_instructions` and follow the Serena manual.
2. Activate the project: `mcp__plugin_claude-code-home-manager_serena__activate_project` with path `/home/ash/Documents/work/evolver_code`.
3. Read `mem:core` then `mem:dpu/core` for DPU-specific context. See `mem:tech_stack` for version constraints.

## Serena Tool Usage

Use Serena's semantic tools for all code navigation and editing:
- Prefer `get_symbols_overview` → `find_symbol` over reading whole files.
- `search_for_pattern` for locating event names or socket.io emit calls.

## Commits

Commit completed changes after each feature or fix before moving on to the next task.

## Important Constraints

- Python must stay at **3.9.x** (`>3.9, <3.10`).
- `socketIO_client` (import name) is the legacy `socketIO-client 0.7.2` — **not** `python-socketio`.
- After changing `pyproject.toml`, run `poetry lock` then verify `nix develop` still builds.
# Claude Working Agreement — evolver-dpu

## Scope

This repo is the eVOLVER Data Processing Unit (DPU): Python scripts that connect
to the eVOLVER server via socket.io, run experiment feedback loops, handle
calibration, and drive the miniEvolver from the host side.

Parent workspace: `../evolver/` — the top-level flake pulls this repo in as an input.

## Required First Steps

1. Call `mcp__serena__initial_instructions` and follow the Serena manual.
2. Activate the project: `mcp__serena__activate_project` with path
   `/home/ash/Documents/work/evolver-dpu`.
3. Use `mcp__mcp-nixos__nix` when working on `flake.nix`, Python package
   versions, devShell packages, or `nix build` failures — do not guess package
   availability from memory.

## Serena Tool Usage

Use Serena's semantic tools for all code navigation and editing.  
Prefer `get_symbols_overview` → `find_symbol(include_body=True)` over reading
whole files. Use `replace_symbol_body` or `replace_content` for edits.

## Python Environment

DPU depends on Python >=3.9,<3.10 (pinned in poetry.lock). Modern nixpkgs
does not carry these exact old versions; the devShell provides `python3 + poetry`
and the user runs `poetry install` to create the virtualenv.

Do NOT add pip-install instructions or requirements.txt — all deps flow through
`poetry.lock`. When adding a new dependency, update pyproject.toml and run
`poetry update <pkg>`, then commit both files together.

## Architecture

```
experiment/template/
  eVOLVER.py          main socket.io client loop
  custom_script.py    user experiment logic (edit per experiment)
  nbstreamreader.py   non-blocking stdin reader
calibration/
  calibrate.py        calibration CLI
  2dcalibrationdata.json
graphing/             Django-based visualization server
```

## DPU ↔ Server Protocol

The DPU connects to `evolver-server` (the sibling `evolver/` repo) via socket.io
on port 8081. Commands/data flow: DPU sends `setParam`, server broadcasts sensor
readings back. The server handles serial communication with miniEvolver hardware;
the DPU never talks to serial ports directly.

## Commits

Commit completed changes after each feature or fix. When deps change, commit
`pyproject.toml` + `poetry.lock` together. Push before updating the parent
`evolver/` flake lock.

## Nix Check

After changing `flake.nix`, run `nix flake check` in this directory.
