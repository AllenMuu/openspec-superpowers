# openspec-superpowers

[![CI](https://github.com/AllenMuu/openspec-superpowers/actions/workflows/validate-schemas.yml/badge.svg?branch=main)](https://github.com/AllenMuu/openspec-superpowers/actions/workflows/validate-schemas.yml)
[![Release](https://img.shields.io/badge/release-v1.1.0-brightgreen)](https://github.com/AllenMuu/openspec-superpowers/releases)
[![OpenSpec](https://img.shields.io/badge/OpenSpec-1.5.0-0277bd)](https://github.com/Fission-AI/OpenSpec)
[![Superpowers](https://img.shields.io/badge/Superpowers-v5.1.0-0277bd)](https://github.com/obra/superpowers)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

**English** · [简体中文](./README.zh-CN.md)

> Community-contributed [OpenSpec](https://github.com/Fission-AI/OpenSpec) schemas that bridge OpenSpec's artifact governance (the **what**) with [obra/superpowers](https://github.com/obra/superpowers) execution skills (the **how**) - one self-contained bundle you install with a single command.

---

## 🚀 Quick install

From your **target repo root** (the project you want to add OpenSpec + Superpowers to), run:

```bash
# Claude Code (default)
bash <(curl -fsSL https://raw.githubusercontent.com/AllenMuu/openspec-superpowers/main/superpowers-bridge/install.sh)

# Codex CLI (or other agents: codex, cursor, gemini, ...)
bash <(curl -fsSL https://raw.githubusercontent.com/AllenMuu/openspec-superpowers/main/superpowers-bridge/install.sh) --tool codex
```

`--tool` (default `claude`) sets the agent harness. Claude Code writes the routing rule to `.claude/rules/` (auto-loaded); other agents write it to `openspec/routing.md` + a bridge line in `AGENTS.md`.

> The script is pinned internally to release tag `v1.1.0`, so the schema + routing rule it writes stay reproducible even when you fetch the script from `main`. To pin the script itself, swap `main` for `v1.1.0` in the URL.

### Prerequisites

| Requirement | Install | Notes |
|-------------|---------|-------|
| `openspec` CLI ≥ 1.5.0 | `brew install openspec` | Script hard-stops if missing or < 1.5.0 (needs the v1.5.0 command set: `propose` / `apply` / `archive` / `explore` / `sync`) |
| Superpowers plugin | Claude: `claude plugin install superpowers@claude-plugins-official`; Codex: `/plugins` → "superpowers"; others: see [obra/superpowers](https://github.com/obra/superpowers) | Script warns (does not stop) if absent |
| `git` | — | Required for the schema clone |

### What the installer does

[`install.sh`](./superpowers-bridge/install.sh) is idempotent and **does not commit** - safe to re-run. It performs six steps:

| # | Step | Result |
|---|------|--------|
| 1 | Precheck | Verifies `git`, `openspec ≥ 1.5.0`, and warns if the Superpowers plugin is missing |
| 2 | `openspec init --tools <tool> --force` | Creates tool-specific skills/commands (Claude: `.claude/commands/opsx/*` + `.claude/skills/openspec-*/*`; Codex: `.codex/skills/openspec-*/*`) |
| 3 | Install schema | Copies `superpowers-bridge/` into `openspec/schemas/` (backs up any existing copy instead of deleting it) |
| 4 | Set default schema | Writes `schema: superpowers-bridge` to `openspec/config.yaml` |
| 5 | Workflow routing rule | Claude: writes to `.claude/rules/openspec-routing.md` (auto-loaded); other agents: writes to `openspec/routing.md` + a bridge line in `AGENTS.md` |
| 6 | Gitignore + validate | Ensures `.claude/settings.local.json` is gitignored, then runs `openspec schema validate` |

### After install

1. **Restart your agent** so the new skills/commands load.
2. Start a change. Claude Code: `/opsx:propose <name>`. Codex/other: trigger the `openspec-propose` skill, or run `openspec new change <name>` (see `openspec/routing.md` for the command map).
3. v1.5.0 command set: `propose` / `apply` / `archive` / `explore` / `sync` (there is no `/opsx:new`, `/opsx:ff`, `/opsx:continue`, or `/opsx:verify` in v1.5.0)
4. When ready, commit the generated files:
   ```bash
   git add .claude/ openspec/ AGENTS.md CLAUDE.md .gitignore
   git commit -m "chore(openspec): install superpowers-bridge"
   ```

> Prefer a guided install, or need to upgrade an existing install? See the full guide in [`superpowers-bridge/README.md`](./superpowers-bridge/README.md) (one-shot Claude Code prompts, manual bash, and upgrade paths).

---

## 🧩 Bridges

| Bridge | Purpose | Status |
|--------|---------|--------|
| [`superpowers-bridge`](./superpowers-bridge/) | Bridges OpenSpec's artifact governance with [obra/superpowers](https://github.com/obra/superpowers) execution skills (brainstorming, writing-plans, TDD-via-subagents, code review, finishing). Adds an evidence-first `retrospective` artifact filling a gap Superpowers does not natively cover. | v1 |

> Adding a new bridge? Drop a `<new-bridge>/` subdirectory mirroring the `superpowers-bridge/` structure, then add one line to `matrix.bridge` in [`.github/workflows/validate-schemas.yml`](./.github/workflows/validate-schemas.yml).

---

## ❓ Why a separate repository?

[OpenSpec PR #970](https://github.com/Fission-AI/OpenSpec/pull/970) originally proposed `sdd-plus-superpowers` as a built-in schema. After maintainer review, the integration moved to a community repository - the same pattern [github/spec-kit's community extension catalog](https://speckit-community.github.io/extensions/) uses to keep third-party tool integrations out of core.

Benefits:

- **OpenSpec core stays decoupled** from Superpowers' release cadence
- **The bridge iterates independently** and ships on its own schedule
- **Other community schemas can join** this repository as siblings

---

## 🛣️ Roadmap

See [`docs/roadmap.md`](./docs/roadmap.md) for what's planned (v1 shipped, v1.x backlog, and items awaiting OpenSpec core).

---

## 📄 License

MIT - see [LICENSE](./LICENSE).
