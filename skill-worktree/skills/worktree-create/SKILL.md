---
name: worktree-create
description: Create git worktrees for parallel Claude Code sessions. Use when user wants to create a new worktree, set up isolated dev environments, or work on multiple features simultaneously. (project)
---

# Worktree Create Skill

This skill handles creating git worktrees optimized for parallel Claude Code sessions, with port isolation and optional project-specific hooks for databases, env files, and dependencies.

## Prerequisites

If your project uses a hooks file (`.worktree/hooks.sh`), ensure it defines a `wt_hook_validate_prereqs` function to verify runtimes, databases, or other prerequisites are available.

## Detecting Current Worktree Status

Before any worktree operation, detect if we're in a worktree or main repo:

```bash
./scripts/detect-worktree.sh
```

Returns JSON with:
- `is_worktree`: boolean
- `worktree_type`: "main" or "feature"
- `main_repo`: path to main repository
- `current_branch`: current git branch

## Creating a New Worktree

Run the setup script from the **main repository**:

```bash
./scripts/new-worktree.sh <branch>
```

Example:
```bash
./scripts/new-worktree.sh feat/authSystem
```

### Folder Naming Rules

Worktrees are stored as `../<prefix>-<shortDescriptor>` where the prefix defaults to `wt` (configurable via `WORKTREE_PREFIX`) and shortDescriptor is derived from the branch name:

| Branch | Worktree Folder |
|--------|-----------------|
| `feat/buildDatepicker` | `../wt-featBuildDatepicker` |
| `fix/auth-bug` | `../wt-fixAuthBug` |
| `chore/cleanup-260101` | `../wt-choreCleanup260101` |

Rules:
- Slashes (`/`) and dashes (`-`) become camelCase boundaries
- NO nested folders allowed

### What the Script Does

1. Generates folder name from branch using naming rules above
2. Creates worktree at `../<prefix>-<shortDescriptor>/`
3. Uses existing branch or creates new one
4. Allocates unique ID from registry (stored in `tmp/worktree-registry.json`)
5. Calculates ports from `WORKTREE_PORTS` spec (e.g., `server:0 frontend:1`)
6. Checks all allocated ports are free
7. Calls hook callbacks (if hooks file exists):
   - `wt_hook_validate_prereqs` -- check runtimes, databases available
   - `wt_hook_create_databases "$wt_id"` -- create project databases (returns JSON array)
   - `wt_hook_generate_env "$wt_path" "$wt_id" "$ports_json"` -- write .env files
   - `wt_hook_install_deps "$wt_path"` -- install dependencies
   - `wt_hook_post_setup "$wt_path" "$wt_id"` -- run migrations, seeds, etc.
8. Copies `.claude/settings.local.json` (Claude permissions)
9. Creates worktree-aware `CLAUDE.local.md` with ID, branch, and ports

### Port Allocation

Ports are calculated as: `WORKTREE_PORT_BASE + (ID * WORKTREE_PORT_OFFSET) + named_offset`

With defaults (`PORT_BASE=4000`, `PORT_OFFSET=10`, `PORTS="server:0"`):

| Environment | server port |
|-------------|-------------|
| Main repo | 4000 |
| Worktree 1 | 4010 |
| Worktree 2 | 4020 |
| Worktree N | 4000+(N*10) |

Multiple named ports (e.g., `WORKTREE_PORTS="server:0 frontend:1 admin:2"`):

| Environment | server | frontend | admin |
|-------------|--------|----------|-------|
| Worktree 1 | 4010 | 4011 | 4012 |
| Worktree 2 | 4020 | 4021 | 4022 |

### Configuration

All configuration is via environment variables with sensible defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKTREE_PREFIX` | `wt` | Folder prefix |
| `WORKTREE_PORT_BASE` | `4000` | Base port number |
| `WORKTREE_PORT_OFFSET` | `10` | Port gap between worktrees |
| `WORKTREE_PORTS` | `server:0` | Named ports as `name:offset` pairs |
| `WORKTREE_MAX_ID` | `20` | Max concurrent worktrees |
| `WORKTREE_HOOKS` | `.worktree/hooks.sh` | Path to hooks file |
| `WORKTREE_BASE_BRANCH` | `main` | Base branch for merges |

## Cleaning Up Worktrees

Use the `/worktree-remove` skill for interactive cleanup with rebase/merge:
```
/worktree-remove ../wt-featAuth
```

Or use the script directly:
```bash
# Remove worktree and clean registry
./scripts/cleanup-worktree.sh ../wt-featAuth

# Remove worktree, clean registry, and delete branch
./scripts/cleanup-worktree.sh ../wt-featAuth --delete-branch
```

## Registry

The worktree registry at `tmp/worktree-registry.json` tracks all worktrees and their assignments. If corrupted or lost, use:

```
/rebuild-worktree-registry
```

## Listing Active Worktrees

```bash
git worktree list
```

To see registry contents:
```bash
cat tmp/worktree-registry.json | jq .
```
