---
name: worktree-remove
description: Remove and clean up a git worktree. Verifies the worktree exists, rebases onto base branch, merges (ff-only), backs up to remote, then removes worktree, resources, registry entry, and local branch (keeps remote as backup). Use when done with a feature worktree. (project)
allowed-tools: Bash, Read, Glob, AskUserQuestion
---

# Worktree Remove Skill

This skill safely removes a git worktree by rebasing onto the base branch, merging (fast-forward only), backing up to remote, then removing the worktree along with its resources and registry entry. Remote branches are kept as soft backups.

---

## Configuration

The base branch defaults to `main`. Override with:
```bash
export WORKTREE_BASE_BRANCH=develop
```

---

## PHASE 0: Verify Main Repository State

**This phase must pass before proceeding.**

### Step 1: Check if running from main repo

```bash
./scripts/detect-worktree.sh
```

- If `worktree_type` is NOT "main", stop with error:
  ```
  ERROR: Must run /worktree-remove from the main repository, not from a worktree.
  Current location appears to be a worktree.
  ```

### Step 2: Check current branch is the base branch

```bash
git branch --show-current
```

Read the base branch from the environment:
```bash
BASE_BRANCH="${WORKTREE_BASE_BRANCH:-main}"
```

- If NOT on the base branch, stop with error:
  ```
  ERROR: Must be on '<base-branch>' branch to remove a worktree.
  Current branch: <branch-name>
  Run: git checkout <base-branch>
  ```

### Step 3: Sync local base branch with remote

1. Fetch latest from origin:
   ```bash
   git fetch origin $BASE_BRANCH
   ```

2. Check if local and remote are in sync:
   ```bash
   git rev-parse $BASE_BRANCH
   git rev-parse origin/$BASE_BRANCH
   ```

3. If they differ, pull to sync:
   ```bash
   git pull origin $BASE_BRANCH
   ```

4. Verify sync succeeded. If still out of sync, stop with error.

---

## PHASE 1: Identify Target Worktree

### Option A: User provides path
If user specifies a path (e.g., `/worktree-remove ../wt-featAuth`), use that path.

### Option B: No path provided
1. List all worktrees:
   ```bash
   git worktree list
   ```

2. If multiple worktrees exist (besides main), ask user which one to remove.

3. If only one feature worktree exists, use that one (still confirm in Phase 3).

---

## PHASE 2: Validate Worktree

1. Check if the worktree path exists.

2. Get the branch name:
   ```bash
   git -C "<worktree-path>" branch --show-current
   ```

3. Check for uncommitted changes:
   ```bash
   git -C "<worktree-path>" status --porcelain
   ```

4. If there are uncommitted changes, warn the user and ask whether to abort or continue.

---

## PHASE 3: Confirm with User

Use AskUserQuestion to confirm:

```
You are about to remove this worktree:

  Path:   <worktree-path>
  Branch: <branch-name>

This will:
  1. Push branch to remote (backup pre-rebase state)
  2. Remove the worktree, resources, and registry entry
  3. Rebase <branch-name> onto <base-branch> (in main repo)
  4. Merge into <base-branch> (fast-forward only)
  5. Push <base-branch> to remote
  6. Delete the local feature branch (remote kept as backup)

Proceed?
```

Options:
- "Yes, remove worktree" (proceed)
- "No, cancel" (abort)

---

## PHASE 4: Backup to Remote

1. Push branch to remote:
   ```bash
   git -C "<worktree-path>" push -u origin <branch-name>
   ```

2. If push fails, ask user whether to abort or continue without backup.

---

## PHASE 5: Remove Worktree and Clean Up Resources

Remove the worktree first so the branch is no longer checked out (required for rebase).

1. Run the cleanup script:
   ```bash
   ./scripts/cleanup-worktree.sh "<worktree-path>"
   ```

   This script will:
   - Call `wt_hook_pre_cleanup` (stop servers, etc.)
   - Call `wt_hook_drop_databases` with database list from registry
   - Remove the entry from `tmp/worktree-registry.json`
   - Remove the git worktree
   - Prune stale worktree refs

2. If cleanup fails, try force removal:
   ```bash
   git worktree remove --force "<worktree-path>"
   git worktree prune
   ```

3. Verify the folder is removed.

---

## PHASE 6: Rebase and Merge

### Step 1: Rebase onto base branch

```bash
git rebase $BASE_BRANCH <branch-name>
```

If rebase fails (conflicts):
- Abort the rebase: `git rebase --abort`
- Ask user whether to cancel or continue without rebase

### Step 2: Show commits to be merged

```bash
git log $BASE_BRANCH..<branch-name> --oneline --format="%s"
```

Present to user and confirm merge.

### Step 3: Merge (fast-forward only)

```bash
git checkout $BASE_BRANCH
git merge --ff-only <branch-name>
```

### Step 4: Push and cleanup local branch

```bash
git push origin $BASE_BRANCH
git branch -D <branch-name>
```

Remote branch is intentionally kept as a soft backup.

---

## PHASE 7: Report Summary

```
Worktree removed successfully:
  - Worktree removed: <path>
  - Resources cleaned up (via hooks)
  - Registry entry removed
  - Branch rebased and merged into <base-branch>
  - <base-branch> pushed to origin
  - Local branch deleted: <branch-name>
  - Remote backup kept: origin/<branch-name>
```

---

## ERROR HANDLING

| Error | Action |
|-------|--------|
| Not in main repo | Stop with error message |
| Not on base branch | Stop with instructions to checkout base branch |
| Local/remote out of sync | Pull, retry, stop if still out of sync |
| Path doesn't exist | Show available worktrees, stop |
| Uncommitted changes | Warn user, ask to proceed or abort |
| Push fails | Ask to continue without backup or abort |
| Rebase conflicts | Ask to abort rebase or continue without rebase |
| Merge not fast-forward | Stop with error, preserve rebased branch locally |

---

## SAFETY NOTES

- Never remove the main worktree
- Must be on base branch in main repo before removing
- Always sync base branch with remote before rebasing
- Pre-rebase state is pushed to remote before worktree deletion (backup)
- Worktree is removed before rebase (branch must not be checked out)
- Merge uses --ff-only to ensure clean linear history
- Only local branch is deleted; remote branch kept as soft backup
