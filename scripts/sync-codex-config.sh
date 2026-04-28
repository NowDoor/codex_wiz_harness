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

Copies project Codex agents, converts ECC Markdown agents into Codex TOML
wrappers, installs skills, command prompts, and ECC assets into
CODEX_HOME, then merges the project MCP, marketplace, and multi-agent baseline
into CODEX_HOME/config.toml.

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

if [[ -d "$ROOT_DIR/agents" ]]; then
    mkdir -p "$CODEX_HOME/agent-templates"
    rm -rf "$CODEX_HOME/agent-templates/ecc"
    mkdir -p "$CODEX_HOME/agent-templates/ecc"
    cp -a "$ROOT_DIR/agents/." "$CODEX_HOME/agent-templates/ecc/"
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
for asset in AGENTS.md .github agents commands contexts hooks mcp-configs rules scripts .codex-plugin .agents/plugins; do
    if [[ -e "$ROOT_DIR/$asset" ]]; then
        dest_name="${asset//\//-}"
        if [[ "$asset" == ".github" ]]; then
            dest_name="github"
        fi
        rm -rf "$CODEX_HOME/ecc-assets/$dest_name"
        cp -a "$ROOT_DIR/$asset" "$CODEX_HOME/ecc-assets/$dest_name"
    fi
done

UPDATE_MCP="$UPDATE_MCP" python3 - "$CONFIG_FILE" "$ROOT_DIR" "$CODEX_HOME" <<'PY'
import json
import os
import re
import shutil
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
root = Path(sys.argv[2]).resolve()
codex_home = Path(sys.argv[3]).resolve()
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


def remove_tables(predicate):
    idx = 0
    while idx < len(lines):
        stripped = lines[idx].strip()
        if not (stripped.startswith("[") and stripped.endswith("]")):
            idx += 1
            continue

        table = stripped[1:-1]
        end = len(lines)
        for next_idx in range(idx + 1, len(lines)):
            next_stripped = lines[next_idx].strip()
            if next_stripped.startswith("[") and next_stripped.endswith("]"):
                end = next_idx
                break

        body = lines[idx:end]
        if predicate(table, body):
            del lines[idx:end]
            continue
        idx = end


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


def render_native_agent_templates():
    agents_dir = codex_home / "agents"
    if not agents_dir.is_dir():
        return

    for agent_path in sorted(agents_dir.glob("*.toml")):
        text = agent_path.read_text(encoding="utf-8")
        rendered = text.replace("{{CODEX_HOME}}", str(codex_home))
        if rendered != text:
            agent_path.write_text(rendered, encoding="utf-8")


def parse_frontmatter(text):
    if not text.startswith("---\n"):
        return {}, text

    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text

    raw_meta = text[4:end].splitlines()
    body = text[end + len("\n---\n") :]
    meta = {}
    for line in raw_meta:
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        meta[key.strip()] = value.strip().strip('"').strip("'")
    return meta, body


def slugify_filename(value):
    slug = re.sub(r"[^A-Za-z0-9_-]+", "-", value.strip().lower())
    slug = re.sub(r"-+", "-", slug).strip("-_")
    return slug or "agent"


def slugify_table(value):
    slug = re.sub(r"[^A-Za-z0-9_]+", "_", value.strip().lower())
    slug = re.sub(r"_+", "_", slug).strip("_")
    return slug or "agent"


def collapse_description(value):
    return re.sub(r"\s+", " ", value.strip())


def generated_agent_sandbox(name):
    lowered = name.lower()
    write_keywords = (
        "resolver",
        "updater",
        "generator",
        "optimizer",
        "simplifier",
        "cleaner",
        "forker",
        "packager",
        "sanitizer",
        "operator",
        "runner",
    )
    if any(keyword in lowered for keyword in write_keywords):
        return "workspace-write"
    return "read-only"


def generated_agent_effort(name):
    lowered = name.lower()
    high_keywords = (
        "architect",
        "build",
        "performance",
        "reviewer",
        "security",
        "typescript",
        "flutter",
        "healthcare",
        "database",
    )
    if any(keyword in lowered for keyword in high_keywords):
        return "high"
    return "medium"


def generate_ecc_agent_wrappers():
    source_dir = root / "agents"
    if not source_dir.is_dir():
        return []

    output_dir = codex_home / "agents" / "ecc"
    shutil.rmtree(output_dir, ignore_errors=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    generated = []
    used_tables = set()
    used_files = set()

    for source_path in sorted(source_dir.glob("*.md")):
        text = source_path.read_text(encoding="utf-8")
        meta, body = parse_frontmatter(text)
        agent_name = meta.get("name") or source_path.stem
        file_slug = slugify_filename(agent_name)
        table_slug = slugify_table(agent_name)

        base_file_slug = file_slug
        file_counter = 2
        while file_slug in used_files:
            file_slug = f"{base_file_slug}-{file_counter}"
            file_counter += 1
        used_files.add(file_slug)

        base_table_slug = table_slug
        table_counter = 2
        while table_slug in used_tables:
            table_slug = f"{base_table_slug}_{table_counter}"
            table_counter += 1
        used_tables.add(table_slug)

        source_rel = source_path.relative_to(root)
        description = collapse_description(
            meta.get("description") or f"ECC agent converted from {source_rel}"
        )
        instructions = f"""This is an ECC Markdown agent converted for Codex.

Source: {source_rel}
ECC agent name: {agent_name}

Use the ECC role below as the task-specific operating guide. If it refers to
Claude-only tools such as Read, Grep, Glob, or Bash, use the closest Codex
capability available in this session. Follow higher-priority Codex system and
developer instructions first.

{body.strip()}
"""

        output_path = output_dir / f"{file_slug}.toml"
        output_path.write_text(
            "\n".join(
                [
                    f"# Generated by scripts/sync-codex-config.sh from {source_rel}.",
                    'model = "gpt-5.4"',
                    f'model_reasoning_effort = "{generated_agent_effort(agent_name)}"',
                    f'sandbox_mode = "{generated_agent_sandbox(agent_name)}"',
                    "",
                    f"developer_instructions = {toml_value(instructions)}",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        generated.append(
            {
                "table": f"agents.ecc_{table_slug}",
                "description": description,
                "config_file": f"agents/ecc/{file_slug}.toml",
            }
        )

    return generated


def is_generated_ecc_agent_table(table, body):
    if not table.startswith("agents.ecc_"):
        return False
    return any(
        "config_file" in line and ("\"agents/ecc/" in line or "'agents/ecc/" in line)
        for line in body
    )


render_native_agent_templates()

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
ensure_table(
    "agents.wiz_architect",
    {
        "description": "WIZ architecture planner for layer boundaries, MCP tool selection, and implementation routing.",
        "config_file": "agents/wiz-architect.toml",
    },
)
ensure_table(
    "agents.wiz_source_developer",
    {
        "description": "WIZ Source App specialist for src/app pages, layouts, components, Pug, Service, and frontend behavior.",
        "config_file": "agents/wiz-source-developer.toml",
    },
)
ensure_table(
    "agents.wiz_backend_developer",
    {
        "description": "WIZ backend specialist for controllers, routes, api.py, models, Struct patterns, and response/query rules.",
        "config_file": "agents/wiz-backend-developer.toml",
    },
)
ensure_table(
    "agents.wiz_package_developer",
    {
        "description": "WIZ Portal Package specialist for src/portal packages, package README authority, portal.json, libs, styles, and components.",
        "config_file": "agents/wiz-package-developer.toml",
    },
)
ensure_table(
    "agents.wiz_build_troubleshooter",
    {
        "description": "WIZ build and troubleshooting specialist for build modes, Pug/API/cache failures, logs, and framework-specific fixes.",
        "config_file": "agents/wiz-build-troubleshooter.toml",
    },
)
ensure_table(
    "agents.wiz_reviewer",
    {
        "description": "WIZ reviewer focused on framework-specific regressions, MCP boundaries, frontend/backend rules, and build requirements.",
        "config_file": "agents/wiz-reviewer.toml",
    },
)

generated_ecc_agents = generate_ecc_agent_wrappers()
remove_tables(is_generated_ecc_agent_table)
for agent in generated_ecc_agents:
    ensure_table(
        agent["table"],
        {
            "description": agent["description"],
            "config_file": agent["config_file"],
        },
        replace_existing_keys=True,
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

echo "Synced Codex config to $CONFIG_FILE"
echo "Copied agents to $CODEX_HOME/agents"
echo "Generated ECC Codex agents in $CODEX_HOME/agents/ecc"
echo "Copied project skills to $CODEX_HOME/skills"
echo "Copied ECC agent templates to $CODEX_HOME/agent-templates/ecc"
echo "Generated command prompts in $CODEX_HOME/prompts"
echo "Copied ECC assets to $CODEX_HOME/ecc-assets"
