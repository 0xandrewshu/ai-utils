#!/bin/bash
# scripts/detect-worktree.sh
# Detects if current directory is a worktree vs main repo
# Returns JSON for easy parsing by Claude or other tools

CURRENT_PATH=$(pwd)

# Get worktree info
WORKTREE_LIST=$(git worktree list --porcelain 2>/dev/null)

if [ -z "$WORKTREE_LIST" ]; then
    echo '{"is_worktree": false, "error": "Not a git repository"}'
    exit 1
fi

# Find the main worktree (first one listed)
MAIN_WORKTREE=$(echo "$WORKTREE_LIST" | grep "^worktree " | head -1 | cut -d' ' -f2)

# Check if we're in the main repo or a worktree
if [ "$CURRENT_PATH" = "$MAIN_WORKTREE" ]; then
    IS_WORKTREE=false
    WORKTREE_TYPE="main"
else
    IS_WORKTREE=true
    WORKTREE_TYPE="feature"
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")

# Count total worktrees
WORKTREE_COUNT=$(echo "$WORKTREE_LIST" | grep -c "^worktree " || echo "1")

# Output JSON
cat << EOF
{
  "is_worktree": $IS_WORKTREE,
  "worktree_type": "$WORKTREE_TYPE",
  "current_path": "$CURRENT_PATH",
  "main_repo": "$MAIN_WORKTREE",
  "current_branch": "$CURRENT_BRANCH",
  "total_worktrees": $WORKTREE_COUNT
}
EOF
