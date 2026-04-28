# WIZ ECC Codex Bundle

Standalone Codex/ECC/WIZ harness bundle.

## Apply

```bash
scripts/sync-codex-config.sh
```

This copies skills, agent templates, command prompts, plugin metadata, and MCP
configuration into `~/.codex`.

## WIZ MCP

The WIZ MCP launcher uses the installed `season-framework.wiz-vscode` extension.
If the extension is not installed, set `WIZ_MCP_INDEX` to the WIZ MCP
`src/mcp/index.js` path before starting Codex.

## Contents

- `.codex/`: Codex config baseline and native TOML agents
- `.agents/`: Codex skills, upstream ECC/Kiro agent templates, marketplace catalog
- `.codex-plugin/`: Codex plugin manifest
- `agents/`, `skills/`, `commands/`, `rules/`, `hooks/`, `scripts/`: ECC-compatible layout
- `.github/`: WIZ project instructions and docs
