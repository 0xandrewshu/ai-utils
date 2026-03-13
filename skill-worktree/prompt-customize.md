# Generate worktree hooks for this project

I've installed the skill-worktree system into this repo (see `scripts/new-worktree.sh`, `scripts/cleanup-worktree.sh`, and the skills in `.claude/skills/`). These scripts manage git worktrees for parallel development -- each worktree gets isolated ports and a registry entry.

The scripts delegate all project-specific setup to hook callbacks in `.worktree/hooks.sh`. I need you to **generate that file** for this project.

## What to do

1. **Read the worktree system** to understand the hook contract:
   - `scripts/new-worktree.sh` -- see which hooks it calls and with what arguments
   - `scripts/cleanup-worktree.sh` -- see cleanup hooks
   - Check the `examples/` directory for reference implementations

2. **Explore this project** to understand the stack:
   - What language/framework? (package.json, Gemfile, mix.exs, requirements.txt, go.mod, etc.)
   - What databases? (docker-compose.yml, database config files, .env files)
   - How are dependencies installed? (npm, yarn, bundle, mix, pip, etc.)
   - How are migrations run?
   - How does the dev server start? What ports does it use?
   - Are there multiple services (api + frontend, monorepo, etc.)?

3. **Generate `.worktree/hooks.sh`** implementing these hooks (all are optional -- skip any that don't apply):

   | Hook | Called by | Arguments | Purpose |
   |------|-----------|-----------|---------|
   | `wt_hook_validate_prereqs` | new-worktree.sh | (none) | Check that runtimes and databases are available |
   | `wt_hook_create_databases` | new-worktree.sh | `$wt_id` | Create isolated databases. **Must print a JSON array of database names to stdout** (e.g., `["myapp_dev_wt1", "myapp_test_wt1"]`). Status messages go to stderr. |
   | `wt_hook_generate_env` | new-worktree.sh | `$wt_path $wt_id $ports_json` | Write .env files with worktree-specific ports and database URLs. `$ports_json` is like `{"server":4010,"frontend":4011}`. |
   | `wt_hook_install_deps` | new-worktree.sh | `$wt_path` | Install dependencies (npm install, bundle install, etc.) |
   | `wt_hook_post_setup` | new-worktree.sh | `$wt_path $wt_id` | Run migrations, seeds, compile, etc. |
   | `wt_hook_pre_cleanup` | cleanup-worktree.sh | `$wt_path` | Stop running servers, release resources |
   | `wt_hook_drop_databases` | cleanup-worktree.sh | `$wt_id $databases_json` | Drop databases. `$databases_json` is the JSON array returned by `wt_hook_create_databases`. |

4. **Set configuration env vars** if the defaults don't fit. Add them to the top of `.worktree/hooks.sh` or suggest a `.worktree/config.sh`:

   | Variable | Default | What to check |
   |----------|---------|---------------|
   | `WORKTREE_PORTS` | `server:0` | Does the project have multiple services? e.g., `"api:0 frontend:1"` |
   | `WORKTREE_PORT_BASE` | `4000` | What port does the dev server normally run on? Match it. |
   | `WORKTREE_PORT_OFFSET` | `10` | Need more than 10 ports per worktree? Increase this. |
   | `WORKTREE_BASE_BRANCH` | `main` | Does the project use `develop`, `dev`, or `master` instead? |

## Important details

- Database names should include the worktree ID to avoid collisions (e.g., `myapp_dev_wt${wt_id}`)
- `wt_hook_create_databases` must print its JSON array to **stdout** -- use `>&2` for status messages
- The hooks file is `source`d by the scripts, so it runs in the same shell -- don't `exit` on non-fatal errors, use `return 1`
- Look at the existing `.env`, `.env.example`, `docker-compose.yml`, or framework config to find the right env var names for this project
- If the project uses Docker for databases, the hooks should work with that (not assume bare-metal installs)
