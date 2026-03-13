# Skill: Worktree provisioning to enable parallel, isolated applications.

A generic worktree management system for running parallel Claude Code sessions on the same repository. Each worktree gets isolated ports, an optional database setup, and its own Claude context.

The scripts handle the git worktree lifecycle. Project-specific setup (databases, env files, dependencies) is delegated to hook callbacks you define, so the system works with any stack.

## How to use this

  - This is primarily meant for applications that can be run locally, in particular full-stack applications (db, api, ui)
    - Given the various lifecycle points, this could theoretically be run for remote / cloud environments. But I haven't tested it out.
  - This folder contains multiple skills and scripts that work together
    - You'll copy it into your project to "install" it
    - But to make it work, you'll also need to customize the application setup / teardown logic
  - Consider pointing your AI agent at this readme and these files, and your project to automatically "fill in the customization".
    - As a sample prompt, see `./prompt-customize.md`

# Security

  - These skills interact with secrets via `.env` files and in the environments, which is common practice but I wanted to call out.
    - As input, the scripts in `examples/worktree-hooks.*.sh` read passwords from the environment
    - As output, the scripts in `examples/worktree-hooks.*.sh` writes the passwords to `.env` files on disk
  - Optionally, you could consider extending this script so the passwords are read from password managers / vaults instead of the environment
  - The scripts `source` your hooks file (`.worktree/hooks.sh`), which means it runs arbitrary code with your user's full privileges. This is the same trust model as Makefiles, `.envrc`, or git hooks -- but be aware that a malicious commit adding code to your hooks file would execute on the next worktree operation.

## Quick Start

### 1. Copy scripts and skills into your project

```bash
# From your project root
cp -r path/to/ai-utils/skill-worktree/scripts/ ./scripts/
cp -r path/to/ai-utils/skill-worktree/skills/ ./.claude/skills/
chmod +x scripts/*.sh
```

### 2. Create a worktree

```bash
./scripts/new-worktree.sh feat/my-feature
```

This creates `../wt-featMyFeature/` with a unique ID and allocated ports.

### 4. Work in the worktree

```bash
cd ../wt-featMyFeature
claude
```

### 5. Clean up when done

```bash
# From main repo
./scripts/cleanup-worktree.sh ../wt-featMyFeature

# Or use the skill for interactive rebase/merge workflow
/worktree-remove ../wt-featMyFeature
```

## How It Works

### Port Allocation

Each worktree gets a unique ID (1, 2, 3...) and ports are calculated from it:

```
port = WORKTREE_PORT_BASE + (ID * WORKTREE_PORT_OFFSET) + named_offset
```

With defaults (`PORT_BASE=4000`, `PORT_OFFSET=10`, `PORTS="server:0"`):

| Worktree | ID | server port |
|----------|----|-------------|
| Main | 0 | 4000 |
| wt-featAuth | 1 | 4010 |
| wt-fixBug | 2 | 4020 |

For multiple ports (e.g., `WORKTREE_PORTS="server:0 frontend:1"`):

| Worktree | server | frontend |
|----------|--------|----------|
| wt-featAuth | 4010 | 4011 |
| wt-fixBug | 4020 | 4021 |

### Registry

Active worktrees are tracked in `tmp/worktree-registry.json`:

```json
{
  "version": 1,
  "config": { "port_base": 4000, "port_offset": 10, "prefix": "wt" },
  "worktrees": {
    "1": {
      "path": "../wt-featAuth",
      "branch": "feat/auth",
      "ports": { "server": 4010 },
      "databases": ["myapp_dev_wt1", "myapp_test_wt1"],
      "created_at": "2026-03-12T10:00:00Z"
    }
  }
}
```

The registry is gitignored (lives in `tmp/`). If lost, use `/rebuild-worktree-registry` to reconstruct it.

### Folder Naming

Branch names are converted to camelCase folder names:

| Branch | Folder |
|--------|--------|
| `feat/build-datepicker` | `wt-featBuildDatepicker` |
| `fix/auth-bug` | `wt-fixAuthBug` |
| `chore/cleanup` | `wt-choreCleanup` |

## Customization: Hook Callbacks

For project-specific setup (databases, env files, dependencies), create a hooks file at `.worktree/hooks.sh` (or set `WORKTREE_HOOKS` to a custom path).

The scripts source this file and call hook functions if they exist. All hooks are optional -- if a function isn't defined, that step is skipped.

### Hooks called by `new-worktree.sh`

| Hook | Arguments | Purpose |
|------|-----------|---------|
| `wt_hook_validate_prereqs` | (none) | Check runtimes, databases are available |
| `wt_hook_create_databases` | `$wt_id` | Create databases; print JSON array of names to stdout |
| `wt_hook_generate_env` | `$wt_path $wt_id $ports_json` | Write .env files |
| `wt_hook_install_deps` | `$wt_path` | Install dependencies |
| `wt_hook_post_setup` | `$wt_path $wt_id` | Run migrations, seeds, etc. |

### Hooks called by `cleanup-worktree.sh`

| Hook | Arguments | Purpose |
|------|-----------|---------|
| `wt_hook_pre_cleanup` | `$wt_path` | Stop servers, release resources |
| `wt_hook_drop_databases` | `$wt_id $databases_json` | Drop databases listed in registry |

### Writing `wt_hook_create_databases`

This hook must print a JSON array to stdout with the names of databases it created. This array is stored in the registry and passed to `wt_hook_drop_databases` during cleanup.

```bash
wt_hook_create_databases() {
    local wt_id="$1"
    createdb "myapp_dev_wt${wt_id}"
    createdb "myapp_test_wt${wt_id}"
    # JSON array on stdout (status messages go to stderr)
    echo "[\"myapp_dev_wt${wt_id}\", \"myapp_test_wt${wt_id}\"]"
}
```

### Example hooks files

See the `examples/` directory for complete hooks files:

- `worktree-hooks.phoenix.sh` -- Elixir/Phoenix with PostgreSQL
- `worktree-hooks.rails.sh` -- Ruby on Rails with PostgreSQL
- `worktree-hooks.django.sh` -- Django with PostgreSQL
- `worktree-hooks.express.sh` -- Express/Node.js with PostgreSQL

## Configuration

All configuration is via environment variables. Set them in your shell profile, a `.worktree/config.sh`, or inline:

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKTREE_PREFIX` | `wt` | Folder prefix: `../<prefix>-<descriptor>` |
| `WORKTREE_PORT_BASE` | `4000` | Base port number |
| `WORKTREE_PORT_OFFSET` | `10` | Port gap between worktrees |
| `WORKTREE_PORTS` | `server:0` | Named ports as space-separated `name:offset` pairs |
| `WORKTREE_MAX_ID` | `20` | Max concurrent worktrees |
| `WORKTREE_HOOKS` | `.worktree/hooks.sh` | Path to hooks file (relative to repo root) |
| `WORKTREE_BASE_BRANCH` | `main` | Base branch for rebase/merge operations |

### Example: Rails with frontend

```bash
export WORKTREE_PORTS="server:0 frontend:1"
export WORKTREE_PORT_BASE=3000
export WORKTREE_PORT_OFFSET=10
export WORKTREE_BASE_BRANCH=develop
```

Worktree 1 gets server:3010, frontend:3011. Worktree 2 gets server:3020, frontend:3021.

## Claude Skills

Three Claude Code skills are included for interactive worktree management:

| Skill | Purpose |
|-------|---------|
| `/worktree-create` | Create a new worktree (wraps `new-worktree.sh` with guidance) |
| `/worktree-remove` | Remove a worktree with rebase/merge workflow and safety checks |
| `/rebuild-worktree-registry` | Audit and repair the registry when it's out of sync |

Install them by copying the `skills/` directory into `.claude/skills/`.

## Files

```
scripts/
  new-worktree.sh              # Create worktree with port allocation + hooks
  cleanup-worktree.sh          # Remove worktree with cleanup hooks
  detect-worktree.sh           # Detect worktree vs main repo (JSON output)
skills/
  worktree-create/SKILL.md     # Claude skill: create worktree
  worktree-remove/SKILL.md     # Claude skill: remove with rebase/merge
  rebuild-worktree-registry/   # Claude skill: audit & repair registry
examples/
  worktree-hooks.phoenix.sh    # Phoenix/Elixir example hooks
  worktree-hooks.rails.sh      # Rails example hooks
  worktree-hooks.django.sh     # Django example hooks
  worktree-hooks.express.sh    # Express/Node.js example hooks
```

## Dependencies

- `git` (worktree support, included in git 2.5+)
- `jq` (JSON processing for registry)
- `lsof` (port checking)
- Project-specific tools are only needed if your hooks use them
