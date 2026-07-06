# Claude Working Agreement — DPU

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
