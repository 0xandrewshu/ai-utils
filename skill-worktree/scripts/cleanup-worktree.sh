#!/bin/bash
# scripts/cleanup-worktree.sh
# Removes a worktree, cleans registry, and delegates resource cleanup to hooks.

set -e

WORKTREE_PATH=$1
DELETE_BRANCH=${2:-false}

# --- Configuration ---
WORKTREE_HOOKS="${WORKTREE_HOOKS:-.worktree/hooks.sh}"

# Find actual main repo (first entry in worktree list, handles running from worktree)
MAIN_REPO=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')
REGISTRY="$MAIN_REPO/tmp/worktree-registry.json"

if [ -z "$WORKTREE_PATH" ]; then
    echo "Usage: cleanup-worktree.sh <worktree-path> [--delete-branch]"
    echo "Example: cleanup-worktree.sh ../wt-featAuth --delete-branch"
    echo ""
    echo "This will:"
    echo "  - Call cleanup hooks (drop databases, stop servers, etc.)"
    echo "  - Remove worktree from registry"
    echo "  - Remove git worktree"
    echo "  - Optionally delete the branch"
    exit 1
fi

# --- Source hooks file if it exists ---
if [ -f "$MAIN_REPO/$WORKTREE_HOOKS" ]; then
    # shellcheck source=/dev/null
    source "$MAIN_REPO/$WORKTREE_HOOKS"
elif [ -f "$WORKTREE_HOOKS" ]; then
    # shellcheck source=/dev/null
    source "$WORKTREE_HOOKS"
fi

# --- Helper functions ---

# Normalize worktree path for registry lookup
normalize_path() {
    local path="$1"
    if [[ "$path" == /* ]]; then
        local dirname
        dirname=$(basename "$path")
        echo "../$dirname"
    elif [[ "$path" == ../* ]]; then
        echo "$path"
    else
        echo "../$path"
    fi
}

# Find worktree entry in registry by path
find_in_registry() {
    local search_path="$1"
    local normalized
    normalized=$(normalize_path "$search_path")

    if [ ! -f "$REGISTRY" ]; then
        echo ""
        return
    fi

    jq -r --arg path "$normalized" \
        'if .worktrees then .worktrees | to_entries[] | select(.value.path == $path) | .key else empty end' \
        "$REGISTRY" 2>/dev/null | head -1
}

# Get registry entry field
get_registry_field() {
    local id="$1"
    local field="$2"
    jq -r --arg id "$id" ".worktrees[\$id].$field // empty" "$REGISTRY"
}

# Get registry entry field as JSON
get_registry_json() {
    local id="$1"
    local field="$2"
    jq --arg id "$id" ".worktrees[\$id].$field // empty" "$REGISTRY"
}

# Remove entry from registry
remove_from_registry() {
    local id="$1"
    jq --arg id "$id" 'del(.worktrees[$id])' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
}

# --- Main flow ---

# Get branch name before removing
BRANCH_NAME=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || echo "")

echo "Worktree: $WORKTREE_PATH"
echo "Branch:   $BRANCH_NAME"
echo ""

# Look up in registry
WORKTREE_ID=$(find_in_registry "$WORKTREE_PATH")

if [ -n "$WORKTREE_ID" ]; then
    echo "Found in registry (ID: $WORKTREE_ID)"

    # Run pre-cleanup hook
    if type -t wt_hook_pre_cleanup &>/dev/null; then
        echo ""
        echo "Running pre-cleanup tasks..."
        wt_hook_pre_cleanup "$WORKTREE_PATH"
    fi

    # Get databases from registry and run drop hook
    DATABASES_JSON=$(get_registry_json "$WORKTREE_ID" "databases")
    if [ -n "$DATABASES_JSON" ] && [ "$DATABASES_JSON" != "empty" ] && [ "$DATABASES_JSON" != "null" ] && [ "$DATABASES_JSON" != "[]" ]; then
        if type -t wt_hook_drop_databases &>/dev/null; then
            echo ""
            echo "Dropping databases..."
            wt_hook_drop_databases "$WORKTREE_ID" "$DATABASES_JSON"
            echo "Databases dropped"
        else
            echo ""
            echo "Warning: Databases recorded in registry but no wt_hook_drop_databases hook defined"
            echo "Databases: $DATABASES_JSON"
        fi
    fi

    # Remove from registry
    echo ""
    echo "Removing from registry..."
    remove_from_registry "$WORKTREE_ID"
    echo "Registry updated"
    echo ""
else
    echo "Not found in registry (may be a manually created worktree)"
    echo ""

    # Still run pre-cleanup hook if available
    if type -t wt_hook_pre_cleanup &>/dev/null; then
        echo "Running pre-cleanup tasks..."
        wt_hook_pre_cleanup "$WORKTREE_PATH"
        echo ""
    fi
fi

# Remove the worktree
echo "Removing worktree..."
git worktree remove "$WORKTREE_PATH"
echo "Worktree removed"

# Optionally delete the branch
if [ "$2" = "--delete-branch" ] && [ -n "$BRANCH_NAME" ]; then
    echo ""
    echo "Deleting branch $BRANCH_NAME..."
    git branch -d "$BRANCH_NAME" 2>/dev/null || git branch -D "$BRANCH_NAME"
    echo "Branch deleted"
fi

# Prune stale worktree refs
git worktree prune

echo ""
echo "=========================================="
echo "Cleanup complete!"
echo "=========================================="
