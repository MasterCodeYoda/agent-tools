# Dependency Establishment

Restore project dependencies in a new worktree by copying caches from the source repo and running a fast sync.

Git worktrees do not include gitignored files (`node_modules/`, `.venv/`), so a fresh worktree has no installed dependencies. This procedure copies applicable caches and runs the native sync command to restore them near-instantly.

## Prerequisites

Before running this procedure:

1. **`REPO_ROOT` is captured** — resolved via `git rev-parse --show-toplevel` *before* entering the worktree (once inside, `--show-toplevel` returns the worktree root, not the source repo).
2. **CWD is inside the worktree** — the session has already `cd`'d into or entered the worktree directory.

## Step 1: Detect Project Tooling

Check for lock files in the worktree root to determine which package managers are in use. Check **both** ecosystems independently — a project may use Node.js and Python simultaneously.

### Node.js (check in priority order — use first match)

| Lock File | Tool | Copy `node_modules/`? | Sync Command |
|-----------|------|----------------------|--------------|
| `pnpm-lock.yaml` | pnpm | **No** (hardlink-based global store; copy would break links) | `pnpm install --frozen-lockfile` |
| `bun.lockb` or `bun.lock` | bun | Yes | `bun install --frozen-lockfile` |
| `yarn.lock` | yarn | Yes | `yarn install --frozen-lockfile` |
| `package-lock.json` | npm | Yes | `npm ci` |

### Python (check in priority order — use first match)

| Lock File | Tool | Copy `.venv/`? | Sync Command |
|-----------|------|---------------|--------------|
| `uv.lock` | uv | **No** (shebangs contain absolute paths; `uv sync` is fast from cache) | `uv sync --frozen` |
| `poetry.lock` | poetry | **No** | `poetry install --no-interaction` |
| `Pipfile.lock` | pipenv | **No** | `pipenv install` |
| `requirements.txt` (with `.venv/` or `venv/` in source repo) | pip | **No** | `pip install -r requirements.txt` |

**If no lock files are found** for an ecosystem, skip that ecosystem entirely — no action needed.

## Step 2: Copy Dependency Caches

**Node.js only, non-pnpm.** If Step 1 detected bun, yarn, or npm:

```bash
# Only if source node_modules exists and destination does not
if [ -d "$REPO_ROOT/node_modules" ] && [ ! -d "./node_modules" ]; then
  # Use COW clones where available (near-instant, no extra disk)
  if [[ "$(uname)" == "Darwin" ]]; then
    cp -Rc "$REPO_ROOT/node_modules" ./node_modules
  else
    cp -R --reflink=auto "$REPO_ROOT/node_modules" ./node_modules
  fi
fi
```

**Copy-on-write (COW) clones**: The copy uses COW where the filesystem supports it — near-instant and no additional disk space until files diverge.
- **macOS (APFS)**: `cp -Rc` — the `-c` flag triggers APFS clones
- **Linux (Btrfs/XFS)**: `cp -R --reflink=auto` — gracefully falls back to a regular copy on filesystems without reflink support
- On other platforms, the copy is a standard recursive copy (slower but functionally identical)

**Never copy for**:
- **pnpm** — uses hardlinks to a global content-addressable store; copying `node_modules/` would create broken regular files instead of hardlinks
- **Python venvs** — shebangs (`#!/path/to/venv/bin/python`) and the `VIRTUAL_ENV` variable contain absolute paths that break on relocation

## Step 3: Run Sync Command

Run the sync command identified in Step 1 for each detected ecosystem:

```bash
# Node.js example (bun detected)
bun install --frozen-lockfile

# Python example (uv detected)
uv sync --frozen
```

The sync command reconciles the lock file against whatever is in the dependency directory:
- **With cache copy** (bun/yarn/npm): The sync is a fast no-op or minor patch — most packages are already present from the copy.
- **Without cache copy** (pnpm/Python): The sync installs from scratch but leverages the tool's own caching (pnpm's global store, uv's download cache, etc.).

## Error Handling

Dependency establishment must **never block worktree entry**. Apply these rules:

1. **Missing source directory**: If `$REPO_ROOT/node_modules` does not exist, skip the copy silently — the source repo may not have had deps installed either.
2. **Copy failure**: If the copy command fails, warn and continue — the sync command will install from scratch.
3. **Sync command failure**: Warn the user with the error output, but **do not stop**. The worktree is still usable; the user can manually install dependencies later.
4. **Tool not installed**: If the detected tool (e.g., `bun`, `uv`) is not on `PATH`, warn and skip that ecosystem.

### Warning Format

```
Note: Dependency sync failed for [tool]. You may need to run `[sync command]` manually.
[error output]
```

## Multiple Ecosystems

When both Node.js and Python tooling are detected, handle them independently and sequentially:

1. Run Node.js steps (copy + sync)
2. Run Python steps (sync only)

A failure in one ecosystem does not affect the other.
