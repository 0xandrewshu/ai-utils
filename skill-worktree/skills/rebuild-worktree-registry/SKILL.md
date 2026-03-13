---
name: rebuild-worktree-registry
description: Rebuild the worktree registry from existing worktrees. Use when the registry is lost, corrupted, or out of sync. Scans worktrees, reads their config, and reconstructs the registry. (project)
---

# Rebuild Worktree Registry Skill

This skill audits and repairs worktree state across multiple sources. It detects inconsistencies between git worktrees, filesystem, and the registry, then proposes fixes for user approval.

Database and resource auditing is delegated to project-specific hooks.

## When to Use

- Registry file is missing or corrupted
- Registry is out of sync with actual worktrees
- After interrupted worktree creation/deletion
- General health check of worktree infrastructure

## Prerequisites

Ensure you're in the **main repository** (not a worktree):
```bash
./scripts/detect-worktree.sh
```

## Configuration

Read configuration from environment or registry:
```bash
PREFIX="${WORKTREE_PREFIX:-wt}"
```

## Step 1: Gather State From All Sources

Run these checks **in parallel** to collect current state:

### 1a. Git Worktrees
```bash
git worktree list
```
Parse to identify:
- Main repo path and branch
- Feature worktree paths and branches (matching `<prefix>-*` pattern)

### 1b. Current Registry
```bash
cat tmp/worktree-registry.json 2>/dev/null | jq . || echo "Registry missing or invalid"
```

### 1c. Filesystem Folders
```bash
ls -d ../${PREFIX}-* 2>/dev/null || echo "No worktree folders found"
```

### 1d. Project-Specific Resources (if hooks available)

If the project has a hooks file, check for a `wt_hook_audit_resources` function. If it exists, call it to get resource state (databases, etc.). If not, skip resource auditing.

## Step 2: Build Consolidated View

Create a table showing state across all sources:

| ID | Git Worktree | Folder | Registry | Resources | Status |
|----|--------------|--------|----------|-----------|--------|
| 1  | Yes          | Yes    | Yes      | N/A       | OK     |
| 2  | Yes          | Yes    | No       | N/A       | Registry missing entry |
| 3  | No           | No     | Yes      | N/A       | Stale registry |

For each worktree found, try to infer its ID:
- From registry entry
- From port numbers in CLAUDE.local.md
- From folder position in sorted list

## Step 3: Identify Inconsistencies

Categorize issues found:

### Category A: Missing Registry Entries
Git worktree and folder exist but not in registry.
**Fix**: Add entry to registry with inferred or new ID

### Category B: Stale Registry Entries
Registry has entry but worktree/folder doesn't exist.
**Fix**: Remove entry from registry

### Category C: Partial State
Some but not all components exist (e.g., folder but no git worktree).
**Fix**: Complete cleanup or complete setup

### Category D: Port Conflicts
Multiple entries claim the same port.
**Fix**: Reassign ports

## Step 4: Propose Fixes

Present findings to user with clear summary:

```
=== Worktree Registry Audit ===

Healthy worktrees (no action needed):
  ID 1: wt-featAuth (feat/auth) - all systems OK

Issues found:

1. STALE REGISTRY ENTRY (ID 5)
   - Registry references ../wt-featOldFeature
   - Folder and git worktree don't exist
   Proposed fix: Remove from registry

2. MISSING REGISTRY ENTRY
   - Git worktree: ../wt-featNewWork (feat/newWork)
   - Not in registry
   Proposed fix: Add to registry with next available ID
```

## Step 5: Ask for Confirmation

Use AskUserQuestion tool to get approval:

```
Which fixes should I apply?
- [ ] Remove stale registry entry (ID 5)
- [ ] Add missing registry entry
- [ ] Apply all fixes
- [ ] Cancel - make no changes
```

## Step 6: Apply Approved Fixes

Only after user confirmation, execute the approved fixes:

### Update Registry
Read current registry, apply changes, write back:
```bash
cat tmp/worktree-registry.json | jq '
  # Remove stale entries
  del(.worktrees["5"]) |
  # Add missing entries
  .worktrees["3"] = {
    "path": "../wt-featNewWork",
    "branch": "feat/newWork",
    "ports": {"server": 4030},
    "databases": [],
    "created_at": "2026-03-12T10:00:00Z"
  }
' > tmp/worktree-registry.json.tmp && mv tmp/worktree-registry.json.tmp tmp/worktree-registry.json
```

## Step 7: Verify and Report

After applying fixes, re-run the audit to confirm clean state:

```
=== Fixes Applied ===

- Removed 1 stale registry entry (ID 5)
- Added 1 missing registry entry (ID 3)

=== Final State ===

Registry: tmp/worktree-registry.json
Worktrees: 2
  ID 1: wt-featAuth (feat/auth) - ports: {"server":4010}
  ID 3: wt-featNewWork (feat/newWork) - ports: {"server":4030}

All systems consistent.
```

## Important Notes

- **Never auto-fix without confirmation** -- always present findings and ask
- **Be conservative** -- if uncertain about an inconsistency, ask the user
- **Preserve data** -- when in doubt about resources, don't delete them
- **Delegate resource auditing** -- database/resource checks belong in project hooks, not here
