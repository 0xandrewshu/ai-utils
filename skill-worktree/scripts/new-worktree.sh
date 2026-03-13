#!/bin/bash
# scripts/new-worktree.sh
# Creates a new git worktree with port allocation and registry tracking.
# Delegates project-specific setup (databases, env files, deps) to hook callbacks.

set -e

BRANCH=$1

# --- Configuration (override via env vars) ---
WORKTREE_PREFIX="${WORKTREE_PREFIX:-wt}"
WORKTREE_PORT_BASE="${WORKTREE_PORT_BASE:-4000}"
WORKTREE_PORT_OFFSET="${WORKTREE_PORT_OFFSET:-10}"
WORKTREE_PORTS="${WORKTREE_PORTS:-server:0}"
WORKTREE_MAX_ID="${WORKTREE_MAX_ID:-20}"
WORKTREE_HOOKS="${WORKTREE_HOOKS:-.worktree/hooks.sh}"
WORKTREE_BASE_BRANCH="${WORKTREE_BASE_BRANCH:-main}"

# Find actual main repo (first entry in worktree list, handles running from worktree)
MAIN_REPO=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')
REGISTRY="$MAIN_REPO/tmp/worktree-registry.json"

if [ -z "$BRANCH" ]; then
    echo "Usage: new-worktree.sh <branch>"
    echo "Example: new-worktree.sh feat/authSystem"
    echo ""
    echo "Creates an isolated worktree with:"
    echo "  - Unique port allocation per named port"
    echo "  - Registry tracking in tmp/worktree-registry.json"
    echo "  - Hook callbacks for project-specific setup"
    echo ""
    echo "Folder naming rules:"
    echo "  - Stored as ../${WORKTREE_PREFIX}-<shortDescriptor>"
    echo "  - Branch slashes/dashes become camelCase: fix/foo-bar -> fixFooBar"
    echo "  - Examples:"
    echo "      feat/buildDatepicker -> ../${WORKTREE_PREFIX}-featBuildDatepicker"
    echo "      fix/auth-bug        -> ../${WORKTREE_PREFIX}-fixAuthBug"
    echo ""
    echo "Configuration (env vars):"
    echo "  WORKTREE_PREFIX       Folder prefix (default: wt)"
    echo "  WORKTREE_PORT_BASE    Base port number (default: 4000)"
    echo "  WORKTREE_PORT_OFFSET  Port gap between worktrees (default: 10)"
    echo "  WORKTREE_PORTS        Named ports as 'name:offset' pairs (default: server:0)"
    echo "  WORKTREE_MAX_ID       Max concurrent worktrees (default: 20)"
    echo "  WORKTREE_HOOKS        Path to hooks file (default: .worktree/hooks.sh)"
    echo "  WORKTREE_BASE_BRANCH  Base branch for merges (default: main)"
    exit 1
fi

# --- Source hooks file if it exists ---
HOOKS_LOADED=false
if [ -f "$MAIN_REPO/$WORKTREE_HOOKS" ]; then
    # shellcheck source=/dev/null
    source "$MAIN_REPO/$WORKTREE_HOOKS"
    HOOKS_LOADED=true
    echo "Loaded hooks from $WORKTREE_HOOKS"
elif [ -f "$WORKTREE_HOOKS" ]; then
    # shellcheck source=/dev/null
    source "$WORKTREE_HOOKS"
    HOOKS_LOADED=true
    echo "Loaded hooks from $WORKTREE_HOOKS"
fi

# --- Helper functions ---

# Generate shortDescriptor from branch name (camelCase from slashes/dashes)
generate_descriptor() {
    local branch="$1"
    local result=""
    local first=true
    IFS='/-' read -ra PARTS <<< "$branch"
    for part in "${PARTS[@]}"; do
        if [ -z "$part" ]; then continue; fi
        if $first; then
            result="${part,,}"
            first=false
        else
            result="${result}$(echo "${part:0:1}" | tr '[:lower:]' '[:upper:]')${part:1}"
        fi
    done
    echo "$result"
}

# Initialize registry if it doesn't exist
init_registry() {
    mkdir -p "$(dirname "$REGISTRY")"
    if [ ! -f "$REGISTRY" ]; then
        jq -n \
            --argjson port_base "$WORKTREE_PORT_BASE" \
            --argjson port_offset "$WORKTREE_PORT_OFFSET" \
            --arg prefix "$WORKTREE_PREFIX" \
            '{version:1, config:{port_base:$port_base, port_offset:$port_offset, prefix:$prefix}, worktrees:{}}' \
            > "$REGISTRY"
        echo "Initialized worktree registry"
    fi
}

# Calculate ports JSON from WORKTREE_PORTS spec and worktree ID
# WORKTREE_PORTS="server:0 frontend:1" with base=4000, offset=10, id=2
# -> {"server":4020,"frontend":4021}
calculate_ports() {
    local wt_id="$1"
    local base_port=$(( WORKTREE_PORT_BASE + wt_id * WORKTREE_PORT_OFFSET ))
    local ports_json="{"
    local first=true

    for entry in $WORKTREE_PORTS; do
        local name="${entry%%:*}"
        local offset="${entry##*:}"
        local port=$(( base_port + offset ))

        if $first; then
            first=false
        else
            ports_json+=","
        fi
        ports_json+="\"$name\":$port"
    done

    ports_json+="}"
    echo "$ports_json"
}

# Find first available ID in range 1..MAX_ID
# Scans for gaps and reclaims stale entries (worktrees that no longer exist)
find_available_id() {
    for id in $(seq 1 "$WORKTREE_MAX_ID"); do
        local path
        path=$(jq -r --arg id "$id" '.worktrees[$id].path // empty' "$REGISTRY" 2>/dev/null)

        if [ -z "$path" ]; then
            echo "$id"
            return 0
        fi

        # Check if worktree directory actually exists
        local fullpath="$MAIN_REPO/$path"
        if [ ! -d "$fullpath" ]; then
            echo "Note: Reclaiming stale slot $id (worktree $path no longer exists)" >&2
            jq --arg id "$id" 'del(.worktrees[$id])' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
            echo "$id"
            return 0
        fi
    done

    echo ""
    return 1
}

# Add worktree entry to registry
add_to_registry() {
    local id="$1"
    local path="$2"
    local branch="$3"
    local ports_json="$4"
    local databases_json="$5"
    local created_at
    created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq --arg id "$id" \
       --arg path "$path" \
       --arg branch "$branch" \
       --argjson ports "$ports_json" \
       --argjson databases "${databases_json:-[]}" \
       --arg created_at "$created_at" \
       '.worktrees[$id] = {
           path: $path,
           branch: $branch,
           ports: $ports,
           databases: $databases,
           created_at: $created_at
       }' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
}

# Check if port is in use
check_port() {
    local port="$1"
    if lsof -i ":$port" >/dev/null 2>&1; then
        return 0  # Port is in use
    fi
    return 1  # Port is free
}

# --- Main flow ---

SHORT_DESC=$(generate_descriptor "$BRANCH")
WORKTREE_PATH="../${WORKTREE_PREFIX}-${SHORT_DESC}"
WORKTREE_ABS_PATH="$(cd "$MAIN_REPO/.." && pwd)/${WORKTREE_PREFIX}-${SHORT_DESC}"

echo "Branch:    $BRANCH"
echo "Worktree:  $WORKTREE_PATH"
echo ""

# Check if worktree already exists
if [ -d "$WORKTREE_ABS_PATH" ]; then
    echo "Error: Directory $WORKTREE_PATH already exists"
    exit 1
fi

# Initialize and read registry
init_registry
WORKTREE_ID=$(find_available_id)

if [ -z "$WORKTREE_ID" ]; then
    echo "Error: All worktree slots (1-$WORKTREE_MAX_ID) are in use."
    echo ""
    echo "Clean up unused worktrees to free a slot:"
    echo ""
    jq -r '.worktrees | to_entries[] | "  \(.value.path) (ID \(.key), branch: \(.value.branch))"' "$REGISTRY"
    echo ""
    echo "To remove: cleanup-worktree.sh <path>"
    exit 1
fi

# Calculate ports
PORTS_JSON=$(calculate_ports "$WORKTREE_ID")

echo "Worktree ID: $WORKTREE_ID"
echo "Ports:       $PORTS_JSON"
echo ""

# Check for port collisions
echo "Checking ports..."
ALL_PORTS_FREE=true
for entry in $WORKTREE_PORTS; do
    local_name="${entry%%:*}"
    local_offset="${entry##*:}"
    local_port=$(( WORKTREE_PORT_BASE + WORKTREE_ID * WORKTREE_PORT_OFFSET + local_offset ))
    if check_port "$local_port"; then
        echo "Error: Port $local_port ($local_name) is already in use"
        ALL_PORTS_FREE=false
    fi
done
if [ "$ALL_PORTS_FREE" = false ]; then
    exit 1
fi
echo "Ports are available"

# Run prereq validation hook
if type -t wt_hook_validate_prereqs &>/dev/null; then
    echo ""
    echo "Running prerequisite checks..."
    wt_hook_validate_prereqs
fi

# Create worktree
echo ""
echo "Creating worktree..."
cd "$MAIN_REPO"
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git worktree add "$WORKTREE_PATH" "$BRANCH"
else
    git worktree add "$WORKTREE_PATH" -b "$BRANCH"
fi

# Track databases created by hooks (hooks append to this)
DATABASES_JSON="[]"

# Run database creation hook
if type -t wt_hook_create_databases &>/dev/null; then
    echo ""
    echo "Creating databases..."
    DATABASES_JSON=$(wt_hook_create_databases "$WORKTREE_ID")
    echo "Databases created"
fi

# Run env generation hook
if type -t wt_hook_generate_env &>/dev/null; then
    echo ""
    echo "Generating environment files..."
    wt_hook_generate_env "$WORKTREE_ABS_PATH" "$WORKTREE_ID" "$PORTS_JSON"
    echo "Environment files generated"
fi

# Copy Claude permissions and settings
if [ -d "$MAIN_REPO/.claude" ]; then
    mkdir -p "$WORKTREE_ABS_PATH/.claude"
    if [ -f "$MAIN_REPO/.claude/settings.local.json" ]; then
        cp "$MAIN_REPO/.claude/settings.local.json" "$WORKTREE_ABS_PATH/.claude/"
        echo "Copied Claude permissions"
    fi
fi

# Create worktree-specific CLAUDE.local.md
cat > "$WORKTREE_ABS_PATH/.claude/CLAUDE.local.md" << EOF
# Worktree Context

This is an **isolated feature worktree** with its own ports and environment.

## Worktree Info
- **ID**: $WORKTREE_ID
- **Branch**: $BRANCH
- **Path**: $WORKTREE_PATH

## Ports
$(echo "$PORTS_JSON" | jq -r 'to_entries[] | "- \(.key): \(.value)"')
EOF
echo "Created worktree-aware CLAUDE.local.md"

# Update registry
add_to_registry "$WORKTREE_ID" "$WORKTREE_PATH" "$BRANCH" "$PORTS_JSON" "$DATABASES_JSON"
echo "Updated worktree registry"

# Run dependency installation hook
if type -t wt_hook_install_deps &>/dev/null; then
    echo ""
    echo "Installing dependencies..."
    wt_hook_install_deps "$WORKTREE_ABS_PATH"
fi

# Run post-setup hook (migrations, seeds, etc.)
if type -t wt_hook_post_setup &>/dev/null; then
    echo ""
    echo "Running post-setup tasks..."
    wt_hook_post_setup "$WORKTREE_ABS_PATH" "$WORKTREE_ID"
fi

echo ""
echo "=========================================="
echo "Worktree ready!"
echo ""
echo "  cd $WORKTREE_PATH && claude"
echo ""
echo "=========================================="
