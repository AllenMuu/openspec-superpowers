#!/usr/bin/env bash
#
# superpowers-bridge one-click installer
#
# Installs OpenSpec + Superpowers integration into the current repo:
#   1. openspec init --tools claude  -> .claude/commands/opsx/* + .claude/skills/openspec-*/*
#   2. superpowers-bridge schema     -> openspec/schemas/superpowers-bridge/
#   3. default schema                -> openspec/config.yaml (schema: superpowers-bridge)
#   4. .claude/rules/openspec-routing.md -> auto-loaded routing rule (v1.5.0-aligned)
#   5. .claude/settings.local.json   -> gitignored (local-only)
#   6. openspec schema validate      -> verifies
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/AllenMuu/openspec-superpowers/main/superpowers-bridge/install.sh)
#   ./install.sh [--locale zh-TW]
#
# Idempotent: safe to re-run. Backs up (does NOT rm) any existing schema dir.
# Does NOT git commit (prints a suggested command at the end).
# Run from the TARGET repo root.

set -euo pipefail

# --- config (overridable via env) -----------------------------------------------
BASE_URL="${BASE_URL:-https://raw.githubusercontent.com/AllenMuu/openspec-superpowers/main/superpowers-bridge}"
SCHEMA_REPO="${SCHEMA_REPO:-https://github.com/AllenMuu/openspec-superpowers.git}"
DEFAULT_SCHEMA="superpowers-bridge"
LOCALE="en"

usage() {
  cat <<EOF
Usage: $0 [--locale zh-TW]
  --locale zh-TW   Use the Traditional Chinese routing rule (default: en)
  -h, --help       Show this help

Installs superpowers-bridge into the current repo (run from repo root).
Idempotent. Does not commit.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --locale) LOCALE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

case "$LOCALE" in
  en)    FRAGMENT_NAME="openspec-routing.md" ;;
  zh-TW) FRAGMENT_NAME="openspec-routing.zh-TW.md" ;;
  *) echo "ERROR: unsupported --locale '$LOCALE' (use 'en' or 'zh-TW')" >&2; exit 1 ;;
esac

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
if command -v claude >/dev/null; then
  if ! claude plugin list 2>/dev/null | grep -q 'superpowers'; then
    echo "WARN: superpowers plugin not detected in 'claude plugin list'." >&2
    echo "      Install with: claude plugin install superpowers@claude-plugins-official" >&2
  fi
else
  echo "WARN: 'claude' not on PATH; cannot verify the superpowers plugin." >&2
fi

# --- 2. openspec init -----------------------------------------------------------
echo "==> [2/6] openspec init --tools claude --force"
openspec init --tools claude --force

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
  git clone --depth 1 "$SCHEMA_REPO" "$CLONE_DIR/repo" >/dev/null
  cp -R "$CLONE_DIR/repo/superpowers-bridge" openspec/schemas/superpowers-bridge
fi

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

# --- 5. Workflow routing rule (auto-loaded by Claude Code from .claude/rules/) -
echo "==> [5/6] Write .claude/rules/openspec-routing.md (locale=$LOCALE)"
FRAGMENT_FILE="$(mktemp)"
if local_fragment; then
  cp "$SCRIPT_DIR/templates/adopters/$FRAGMENT_NAME" "$FRAGMENT_FILE"
else
  curl -fsSL "$BASE_URL/templates/adopters/$FRAGMENT_NAME" -o "$FRAGMENT_FILE"
fi
# strip template meta (HTML comment lines)
fragment_body="${FRAGMENT_FILE}.body"
grep -v '^<!--' "$FRAGMENT_FILE" > "$fragment_body"

# Migrate: strip any legacy "## Workflow routing" section previously written
# into CLAUDE.md by older installers. New installs write a rule file instead
# (auto-loaded from .claude/rules/, so CLAUDE.md no longer needs the section).
if [[ -f CLAUDE.md ]] && grep -q '^## Workflow routing' CLAUDE.md; then
  echo "    migrating: removing legacy '## Workflow routing' section from CLAUDE.md"
  awk 'BEGIN{skip=0}
       /^## Workflow routing/{skip=1; next}
       skip==1 && /^## /{skip=0}
       skip==0{print}' CLAUDE.md > CLAUDE.md.tmp && mv CLAUDE.md.tmp CLAUDE.md
fi

# Write the rule file (installer-owned; safe to overwrite on upgrade).
mkdir -p .claude/rules
cp "$fragment_body" .claude/rules/openspec-routing.md
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

==> Done. superpowers-bridge installed (default schema = $DEFAULT_SCHEMA, locale = $LOCALE).

Next:
  1. Restart Claude Code so the /opsx:* slash commands load.
  2. Start a change:  /opsx:propose <name>
     v1.5.0 commands: propose / apply / archive / explore / sync
     (there is no /opsx:new, /opsx:ff, /opsx:continue, or /opsx:verify in v1.5.0)

Uncommitted changes in this repo:
EOF
git status --short 2>/dev/null || echo "    (not a git repo)"
cat <<EOF

When ready, commit (example):
  git add .claude/ openspec/ CLAUDE.md .gitignore
  git commit -m "chore(openspec): install superpowers-bridge"
EOF
