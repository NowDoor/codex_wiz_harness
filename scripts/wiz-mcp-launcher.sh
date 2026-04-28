#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

find_wiz_mcp_index() {
    if [[ -n "${WIZ_MCP_INDEX:-}" && -f "$WIZ_MCP_INDEX" ]]; then
        printf '%s\n' "$WIZ_MCP_INDEX"
        return 0
    fi

    local roots=(
        "$HOME/.vscode-server/extensions"
        "$HOME/.vscode/extensions"
        "/root/.vscode-server/extensions"
        "/root/.vscode/extensions"
    )

    local root
    for root in "${roots[@]}"; do
        [[ -d "$root" ]] || continue
        find "$root" -maxdepth 4 -type f \
            -path '*/season-framework.wiz-vscode-*/src/mcp/index.js' \
            2>/dev/null
    done | sort -V | tail -n 1
}

WIZ_INDEX="$(find_wiz_mcp_index)"
if [[ -z "$WIZ_INDEX" || ! -f "$WIZ_INDEX" ]]; then
    cat >&2 <<'EOF'
WIZ MCP server was not found.

Install the WIZ VS Code extension first, or set WIZ_MCP_INDEX to the extension's
src/mcp/index.js path before starting Codex.
EOF
    exit 1
fi

EXTENSION_ROOT="$(cd "$(dirname "$WIZ_INDEX")/../.." && pwd)"

export NODE_PATH="${NODE_PATH:-$EXTENSION_ROOT/node_modules}"
export WIZ_WORKSPACE="${WIZ_WORKSPACE:-$WORKSPACE_ROOT}"

exec node "$WIZ_INDEX" "$@"
