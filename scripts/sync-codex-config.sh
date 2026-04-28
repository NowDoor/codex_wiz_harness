#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME/config.toml"
UPDATE_MCP=0

for arg in "$@"; do
    case "$arg" in
        --update-mcp)
            UPDATE_MCP=1
            ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/sync-codex-config.sh [--update-mcp]

Copies project Codex agents, agent templates, skills, command prompts, and ECC
assets into CODEX_HOME, then merges the project MCP, marketplace, and
multi-agent baseline into CODEX_HOME/config.toml.

Options:
  --update-mcp  Replace managed MCP server blocks instead of only adding missing ones.
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

mkdir -p "$CODEX_HOME" "$CODEX_HOME/agents" "$CODEX_HOME/skills"
touch "$CONFIG_FILE"

if [[ -d "$ROOT_DIR/.codex/agents" ]]; then
    cp -a "$ROOT_DIR/.codex/agents/." "$CODEX_HOME/agents/"
fi

if [[ -d "$ROOT_DIR/.agents/skills" ]]; then
    for skill in "$ROOT_DIR"/.agents/skills/*; do
        [[ -d "$skill" ]] || continue
        name="$(basename "$skill")"
        rm -rf "$CODEX_HOME/skills/$name"
        cp -a "$skill" "$CODEX_HOME/skills/$name"
    done
fi

if [[ -d "$ROOT_DIR/.agents/ecc-agents" ]]; then
    mkdir -p "$CODEX_HOME/agent-templates"
    rm -rf "$CODEX_HOME/agent-templates/ecc"
    mkdir -p "$CODEX_HOME/agent-templates/ecc"
    cp -a "$ROOT_DIR/.agents/ecc-agents/." "$CODEX_HOME/agent-templates/ecc/"
fi

if [[ -d "$ROOT_DIR/.agents/kiro-agents" ]]; then
    mkdir -p "$CODEX_HOME/agent-templates"
    rm -rf "$CODEX_HOME/agent-templates/kiro"
    mkdir -p "$CODEX_HOME/agent-templates/kiro"
    cp -a "$ROOT_DIR/.agents/kiro-agents/." "$CODEX_HOME/agent-templates/kiro/"
fi

if [[ -d "$ROOT_DIR/commands" ]]; then
    mkdir -p "$CODEX_HOME/prompts"
    manifest="$CODEX_HOME/prompts/wiz-ecc-prompts-manifest.txt"
    : > "$manifest"
    while IFS= read -r -d '' command_file; do
        name="$(basename "$command_file" .md)"
        out="$CODEX_HOME/prompts/wiz-ecc-$name.md"
        {
            printf '# WIZ ECC Command Prompt: /%s\n\n' "$name"
            printf 'Source: %s\n\n' "$command_file"
            printf 'Use this prompt to run the WIZ ECC `%s` workflow in Codex.\n\n' "$name"
            awk '
              NR == 1 && $0 == "---" { fm = 1; next }
              fm == 1 && $0 == "---" { fm = 0; next }
              fm == 1 { next }
              { print }
            ' "$command_file"
        } > "$out"
        printf 'wiz-ecc-%s.md\n' "$name" >> "$manifest"
    done < <(find "$ROOT_DIR/commands" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)
    sort -u "$manifest" -o "$manifest"
fi

mkdir -p "$CODEX_HOME/ecc-assets"
for asset in agents commands contexts hooks mcp-configs rules scripts .claude-plugin .codex-plugin .agents/plugins; do
    if [[ -e "$ROOT_DIR/$asset" ]]; then
        dest_name="${asset//\//-}"
        rm -rf "$CODEX_HOME/ecc-assets/$dest_name"
        cp -a "$ROOT_DIR/$asset" "$CODEX_HOME/ecc-assets/$dest_name"
    fi
done

UPDATE_MCP="$UPDATE_MCP" python3 - "$CONFIG_FILE" "$ROOT_DIR" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
root = Path(sys.argv[2]).resolve()
update_mcp = os.environ.get("UPDATE_MCP") == "1"

lines = config_path.read_text(encoding="utf-8").splitlines(keepends=True)


def toml_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(item) for item in value) + "]"
    return json.dumps(str(value))


def table_bounds(table):
    header = f"[{table}]"
    start = None
    for idx, line in enumerate(lines):
        if line.strip() == header:
            start = idx
            break
    if start is None:
        return None
    end = len(lines)
    for idx in range(start + 1, len(lines)):
        stripped = lines[idx].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            end = idx
            break
    return start, end


def remove_table(table):
    bounds = table_bounds(table)
    if not bounds:
        return
    start, end = bounds
    del lines[start:end]


def ensure_table(table, values, replace_existing_keys=False):
    bounds = table_bounds(table)
    if not bounds:
        if lines and lines[-1].strip():
            lines.append("\n")
        lines.append(f"[{table}]\n")
        for key, value in values.items():
            lines.append(f"{key} = {toml_value(value)}\n")
        return

    start, end = bounds
    existing = {}
    key_re = re.compile(r"^\s*([A-Za-z0-9_-]+)\s*=")
    for idx in range(start + 1, end):
        match = key_re.match(lines[idx])
        if match:
            existing[match.group(1)] = idx

    insert_at = end
    for key, value in values.items():
        rendered = f"{key} = {toml_value(value)}\n"
        if key in existing:
            if replace_existing_keys:
                lines[existing[key]] = rendered
        else:
            lines.insert(insert_at, rendered)
            insert_at += 1


def ensure_mcp(table, values):
    full_table = f"mcp_servers.{table}"
    if update_mcp:
        remove_table(full_table)
    ensure_table(full_table, values)


ensure_table("features", {"multi_agent": True}, replace_existing_keys=True)
ensure_table("agents", {"max_threads": 6, "max_depth": 1})

ensure_table(
    "agents.explorer",
    {
        "description": "Read-only codebase explorer for gathering evidence before changes are proposed.",
        "config_file": "agents/explorer.toml",
    },
)
ensure_table(
    "agents.reviewer",
    {
        "description": "PR reviewer focused on correctness, security, and missing tests.",
        "config_file": "agents/reviewer.toml",
    },
)
ensure_table(
    "agents.docs_researcher",
    {
        "description": "Documentation specialist that verifies APIs, framework behavior, and release notes.",
        "config_file": "agents/docs-researcher.toml",
    },
)

managed_mcp = {
    "github": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-github"],
        "startup_timeout_sec": 30,
    },
    "context7": {
        "command": "npx",
        "args": ["-y", "@upstash/context7-mcp@latest"],
        "startup_timeout_sec": 30,
    },
    "exa": {
        "url": "https://mcp.exa.ai/mcp",
    },
    "memory": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-memory"],
        "startup_timeout_sec": 30,
    },
    "playwright": {
        "command": "npx",
        "args": ["-y", "@playwright/mcp@latest", "--extension"],
        "startup_timeout_sec": 30,
    },
    "sequential-thinking": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
        "startup_timeout_sec": 30,
    },
    "wiz": {
        "command": "bash",
        "args": [str(root / "scripts" / "wiz-mcp-launcher.sh")],
        "startup_timeout_sec": 30,
    },
}

for name, values in managed_mcp.items():
    ensure_mcp(name, values)

ensure_table(
    "marketplaces.wiz-ecc",
    {
        "source_type": "local",
        "source": str(root),
    },
    replace_existing_keys=True,
)
ensure_table(
    'plugins."wiz-ecc-codex@wiz-ecc"',
    {
        "enabled": True,
    },
    replace_existing_keys=True,
)

config_path.write_text("".join(lines), encoding="utf-8")
PY

chmod +x "$ROOT_DIR/scripts/wiz-mcp-launcher.sh"

echo "Synced Codex config to $CONFIG_FILE"
echo "Copied agents to $CODEX_HOME/agents"
echo "Copied project skills to $CODEX_HOME/skills"
echo "Copied agent templates to $CODEX_HOME/agent-templates"
echo "Generated command prompts in $CODEX_HOME/prompts"
echo "Copied ECC assets to $CODEX_HOME/ecc-assets"
