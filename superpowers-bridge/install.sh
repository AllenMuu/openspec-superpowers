#!/usr/bin/env bash
#
# superpowers-bridge one-click installer
#
# Installs OpenSpec + Superpowers integration into the current repo:
#   1. openspec init --tools <tool>  -> tool-specific skills/commands (claude/codex/...)
#   2. superpowers-bridge schema     -> openspec/schemas/superpowers-bridge/
#   3. default schema                -> openspec/config.yaml (schema: superpowers-bridge)
#   4. workflow routing rule:
#        claude  -> .claude/rules/openspec-routing.md (auto-loaded by Claude Code)
#        other   -> openspec/routing.md + a bridge line in AGENTS.md
#   5. .claude/settings.local.json   -> gitignored (local-only, Claude Code)
#   6. openspec schema validate      -> verifies
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/AllenMuu/openspec-superpowers/main/superpowers-bridge/install.sh)
#   ./install.sh
#
# Idempotent: safe to re-run. Backs up (does NOT rm) any existing schema dir.
# Does NOT git commit (prints a suggested command at the end).
# Run from the TARGET repo root.
# RELEASE_TAG pins schema + script to a release tag (not main). Maintainers tag after merge:
#   git tag v1.1.0 && git push origin v1.1.0

set -euo pipefail

# --- config (overridable via env) -----------------------------------------------
RELEASE_TAG="${RELEASE_TAG:-v1.1.0}"
BASE_URL="${BASE_URL:-https://raw.githubusercontent.com/AllenMuu/openspec-superpowers/${RELEASE_TAG}/superpowers-bridge}"
SCHEMA_REPO="${SCHEMA_REPO:-https://github.com/AllenMuu/openspec-superpowers.git}"
DEFAULT_SCHEMA="superpowers-bridge"

usage() {
  cat <<EOF
Usage: $0 [--tool <name>] [-h|--help]
  --tool <name>   AI agent harness (default: claude). Sets openspec init
                  --tools <name> and where the routing rule lands:
                    claude  -> .claude/rules/openspec-routing.md (auto-loaded)
                    <other> -> openspec/routing.md + bridge line in AGENTS.md
                  Common values: claude, codex, cursor, gemini, github-copilot.
  -h, --help      Show this help

Installs superpowers-bridge into the current repo (run from repo root).
Idempotent. Does not commit.
EOF
}

TOOL="claude"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) TOOL="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

FRAGMENT_NAME="openspec-routing.md"

# --- temp cleanup ---------------------------------------------------------------
CLONE_DIR=""
FRAGMENT_FILE=""
cleanup() {
  [[ -n "$CLONE_DIR"   && -d "$CLONE_DIR"   ]] && rm -rf "$CLONE_DIR"
  [[ -n "$FRAGMENT_FILE" && -f "$FRAGMENT_FILE" ]] && rm -f "$FRAGMENT_FILE"
}
trap cleanup EXIT

# --- local-clone mode: prefer sibling files when run from a checkout ------------
SCRIPT_DIR=""
_src_dir="$(dirname "${BASH_SOURCE[0]:-}" 2>/dev/null || echo "")"
if [[ -n "$_src_dir" && -f "$_src_dir/templates/adopters/openspec-routing.md" ]]; then
  SCRIPT_DIR="$(cd "$_src_dir" && pwd)"
fi
local_fragment() { [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/templates/adopters/$FRAGMENT_NAME" ]]; }
local_schema()  { [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/schema.yaml" && -d "$SCRIPT_DIR/templates" ]]; }

# --- safety: refuse to run inside the bridge repo itself -----------------------
if [[ -f ./install.sh && -f ./schema.yaml && -d ./templates ]]; then
  echo "ERROR: cwd looks like the superpowers-bridge repo itself." >&2
  echo "       Run this installer from a TARGET repo root, not from the bridge directory." >&2
  exit 1
fi

# --- 1. precheck ----------------------------------------------------------------
echo "==> [1/6] Precheck"
command -v git >/dev/null  || { echo "ERROR: git not found." >&2; exit 1; }
if ! command -v openspec >/dev/null; then
  echo "ERROR: openspec CLI not found. Install with: brew install openspec" >&2
  exit 1
fi
# v1.5.0 command set (propose/apply/archive/explore/sync) requires openspec >= 1.5.0.
# On 1.4.x the CLI generates the old new/ff/continue/verify commands, which no longer
# match the routing fragment (already v1.5.0-aligned) this installer writes.
os_ver="$(openspec --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
if [[ -z "$os_ver" ]]; then
  echo "ERROR: cannot determine openspec version (expected >= 1.5.0)." >&2
  exit 1
fi
os_major="${os_ver%%.*}"
os_minor="${os_ver#*.}"; os_minor="${os_minor%%.*}"
if (( os_major < 1 || (os_major == 1 && os_minor < 5) )); then
  echo "ERROR: openspec >= 1.5.0 required (found $os_ver)." >&2
  echo "       v1.5.0 command set (propose/apply/archive/explore/sync) needs the v1.5.0 CLI." >&2
  echo "       Upgrade with: brew upgrade openspec" >&2
  exit 1
fi
case "$TOOL" in
  claude)
    if command -v claude >/dev/null; then
      if ! claude plugin list 2>/dev/null | grep -q 'superpowers'; then
        echo "WARN: superpowers plugin not detected in 'claude plugin list'." >&2
        echo "      Install with: claude plugin install superpowers@claude-plugins-official" >&2
      fi
    else
      echo "WARN: 'claude' not on PATH; cannot verify the superpowers plugin." >&2
    fi
    ;;
  codex)
    echo "NOTE: ensure the superpowers plugin is installed in Codex" >&2
    echo "      (run /plugins, search 'superpowers'; see https://github.com/obra/superpowers#codex-cli)." >&2
    ;;
  *)
    echo "NOTE: ensure the superpowers plugin is installed for your '$TOOL' agent" >&2
    echo "      (see https://github.com/obra/superpowers)." >&2
    ;;
esac

# --- 2. openspec init -----------------------------------------------------------
echo "==> [2/6] openspec init --tools $TOOL --force"
openspec init --tools "$TOOL" --force

# --- 3. install / refresh schema ------------------------------------------------
echo "==> [3/6] Install superpowers-bridge schema"
mkdir -p openspec/schemas
# Back up (not rm) any existing schema dir so adopter local customizations survive a re-run.
if [[ -d openspec/schemas/superpowers-bridge ]]; then
  bak="openspec/schemas/superpowers-bridge.bak.$(date +%Y%m%d-%H%M%S)"
  echo "    backing up existing superpowers-bridge -> $bak"
  mv openspec/schemas/superpowers-bridge "$bak"
fi
if local_schema; then
  echo "    (local-clone mode) copying from $SCRIPT_DIR"
  cp -R "$SCRIPT_DIR" openspec/schemas/superpowers-bridge
else
  CLONE_DIR="$(mktemp -d)"
  echo "    cloning $SCHEMA_REPO"
  git clone --depth 1 --branch "${RELEASE_TAG}" "$SCHEMA_REPO" "$CLONE_DIR/repo" >/dev/null
  cp -R "$CLONE_DIR/repo/superpowers-bridge" openspec/schemas/superpowers-bridge
fi
# Strip non-schema files (script + docs) pulled in by cp -R; keep VERSION, schema.yaml, templates/.
rm -f openspec/schemas/superpowers-bridge/install.sh openspec/schemas/superpowers-bridge/README.md

# --- 4. default schema ----------------------------------------------------------
echo "==> [4/6] Set default schema = $DEFAULT_SCHEMA"
cfg="openspec/config.yaml"
if [[ ! -f "$cfg" ]]; then
  printf 'schema: %s\n' "$DEFAULT_SCHEMA" > "$cfg"
elif grep -q '^schema:' "$cfg"; then
  sed -i.bak "s|^schema:.*|schema: $DEFAULT_SCHEMA|" "$cfg" && rm -f "$cfg.bak"
else
  printf 'schema: %s\n\n' "$DEFAULT_SCHEMA" | cat - "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
fi

# --- 5. Workflow routing rule ---------------------------------------------------
# Claude Code: write to .claude/rules/ (auto-loaded at launch).
# Other agents (Codex, etc.): write to openspec/routing.md + a bridge line in
# AGENTS.md (the agent's native instruction file), since .claude/ is not read.
echo "==> [5/6] Write workflow routing rule (tool=$TOOL)"
FRAGMENT_FILE="$(mktemp)"
if local_fragment; then
  cp "$SCRIPT_DIR/templates/adopters/$FRAGMENT_NAME" "$FRAGMENT_FILE"
else
  curl -fsSL "$BASE_URL/templates/adopters/$FRAGMENT_NAME" -o "$FRAGMENT_FILE"
fi
# strip template meta (HTML comment lines)
fragment_body="${FRAGMENT_FILE}.body"
grep -v '^<!--' "$FRAGMENT_FILE" > "$fragment_body"

# strip_workflow_section <file>: remove an existing "## Workflow routing" section.
strip_workflow_section() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  awk 'BEGIN{skip=0}
       /^##[[:space:]]+[Ww]orkflow[[:space:]]+[Rr]outing/{skip=1; next}
       skip==1 && /^## /{skip=0}
       skip==0{print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

if [[ "$TOOL" == "claude" ]]; then
  # Migrate: strip any legacy "## Workflow routing" section from CLAUDE.md
  # (older installers wrote it there; now it lives in .claude/rules/).
  if grep -qE '^##[[:space:]]+[Ww]orkflow[[:space:]]+[Rr]outing' CLAUDE.md 2>/dev/null; then
    echo "    migrating: removing legacy '## Workflow routing' section from CLAUDE.md"
    strip_workflow_section CLAUDE.md
  fi
  mkdir -p .claude/rules
  cp "$fragment_body" .claude/rules/openspec-routing.md
else
  # Non-Claude: routing body to openspec/routing.md + bridge line in AGENTS.md.
  mkdir -p openspec
  cp "$fragment_body" openspec/routing.md
  touch AGENTS.md
  # Idempotent: replace any existing bridge section before appending the fresh one.
  strip_workflow_section AGENTS.md
  cat >> AGENTS.md <<'BRIDGE'

## Workflow routing

On session start, read and follow [`openspec/routing.md`](./openspec/routing.md) for workflow routing (when to use OpenSpec changes vs a direct PR, and how to trigger propose/apply/archive/explore/sync).
BRIDGE
fi
rm -f "$fragment_body"

# --- 6. gitignore local settings ------------------------------------------------
echo "==> [6/6] Ensure .claude/settings.local.json is gitignored"
touch .gitignore
if ! grep -qxF '.claude/settings.local.json' .gitignore; then
  printf '\n# Claude Code (local-only)\n.claude/settings.local.json\n' >> .gitignore
fi

# --- validate -------------------------------------------------------------------
echo "==> Validate"
openspec schema validate superpowers-bridge

# --- done -----------------------------------------------------------------------
cat <<EOF

==> Done. superpowers-bridge installed (default schema = $DEFAULT_SCHEMA, tool = $TOOL).

Next:
  1. Restart your agent so the new skills/commands load.
EOF
if [[ "$TOOL" == "claude" ]]; then
  cat <<EOF
  2. Start a change:  /opsx:propose <name>
     v1.5.0 commands: propose / apply / archive / explore / sync
     (there is no /opsx:new, /opsx:ff, /opsx:continue, or /opsx:verify in v1.5.0)
EOF
else
  cat <<EOF
  2. Start a change:  trigger the openspec-propose skill, or run `openspec new change <name>`.
     See openspec/routing.md for the command map (propose/apply/archive/explore/sync).
EOF
fi
cat <<EOF

Uncommitted changes in this repo:
EOF
git status --short 2>/dev/null || echo "    (not a git repo)"
if [[ "$TOOL" == "claude" ]]; then
  cat <<EOF

When ready, commit (example):
  git add .claude/ openspec/ CLAUDE.md .gitignore
  git commit -m "chore(openspec): install superpowers-bridge"
EOF
else
  cat <<EOF

When ready, commit (example):
  git add .codex/ openspec/ AGENTS.md .gitignore
  git commit -m "chore(openspec): install superpowers-bridge"
EOF
fi
