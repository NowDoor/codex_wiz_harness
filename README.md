# WIZ ECC Codex Bundle

Standalone Codex/ECC/WIZ harness bundle.

## Apply

```bash
scripts/sync-codex-config.sh
```

This copies skills, command prompts, plugin metadata, bundled WIZ docs, WIZ
native agents, and MCP configuration into `~/.codex`. It also converts every ECC
Markdown agent in `agents/*.md` into a Codex TOML wrapper under
`~/.codex/agents/ecc/` and registers those wrappers in `~/.codex/config.toml` as
`agents.ecc_*`.

The bundle is path-independent: each user can clone it anywhere, then run the
sync script. WIZ docs are installed under `${CODEX_HOME:-~/.codex}/ecc-assets/github/`,
and the WIZ MCP launcher path is written from that user's clone location.

WIZ native sub-agents are installed as `agents.wiz_*`:

- `wiz_architect`
- `wiz_source_developer`
- `wiz_backend_developer`
- `wiz_package_developer`
- `wiz_build_troubleshooter`
- `wiz_reviewer`

## WIZ MCP

The WIZ MCP launcher uses the installed `season-framework.wiz-vscode` extension.
If the extension is not installed, set `WIZ_MCP_INDEX` to the WIZ MCP
`src/mcp/index.js` path before starting Codex.

## Contents

- `.codex/`: Codex config baseline and native TOML agents, including WIZ sub-agents
- `.agents/`: Codex skills and local marketplace catalog
- `.codex-plugin/`: Codex plugin manifest
- `AGENTS.md`: Generic WIZ project agent instructions suitable for future WIZ project roots
- `agents/`: Canonical ECC Markdown agents; sync converts these into Codex TOML wrappers
- `skills/`, `commands/`, `rules/`, `hooks/`, `scripts/`: ECC-compatible layout
- `.github/`: Generic WIZ instructions and docs bundled for installation
