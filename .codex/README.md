# Codex Setup

This directory is the project-local Codex baseline.

Run this from the repository root after cloning:

```bash
scripts/sync-codex-config.sh
```

That command:

- copies `.codex/agents/*` into `~/.codex/agents/`
- copies `.agents/skills/*` into `~/.codex/skills/`
- copies `.agents/ecc-agents/*` into `~/.codex/agent-templates/ecc/`
- copies `.agents/kiro-agents/*` into `~/.codex/agent-templates/kiro/`
- generates `commands/*.md` as `~/.codex/prompts/wiz-ecc-*.md`
- copies `agents/`, `commands/`, `rules/`, `hooks/`, `scripts/`,
  `contexts/`, and `mcp-configs/` into `~/.codex/ecc-assets/`
- merges the project MCP baseline into `~/.codex/config.toml`
- registers the local `wiz-ecc` plugin marketplace in `~/.codex/config.toml`
- adds the WIZ MCP server through `scripts/wiz-mcp-launcher.sh`

Use `--update-mcp` when you want to replace managed MCP server blocks with the
project baseline:

```bash
scripts/sync-codex-config.sh --update-mcp
```

The WIZ MCP launcher resolves the installed WIZ VS Code extension at runtime.
If it cannot find the extension, install `season-framework.wiz-vscode` or set
`WIZ_MCP_INDEX=/path/to/src/mcp/index.js` before launching Codex.

Notes:

- `.agents/skills/` is a full snapshot of the installed non-system Codex skills.
- `.codex/agents/` contains Codex-native TOML roles that Codex can load directly.
- `.agents/ecc-agents/` and `.agents/kiro-agents/` preserve the upstream ECC/Kiro
  Markdown agent templates. They are copied for reuse, but they are not enabled as
  Codex TOML roles until converted.
- Claude-style slash commands, hooks, and rules are preserved as assets. Codex
  does not execute Claude hooks directly; command files are converted to prompt
  shims under `~/.codex/prompts/`.
