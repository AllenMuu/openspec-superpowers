# openspec-schemas monorepo — design spec

> Validated design from brainstorming session, 2026-05-02.
> Source: [Fission-AI/OpenSpec PR #970](https://github.com/Fission-AI/OpenSpec/pull/970)
> See also: implementation plan at `~/.claude/plans/pr-quizzical-oasis.md`

---

## Context

[Fission-AI/OpenSpec PR #970](https://github.com/Fission-AI/OpenSpec/pull/970) proposed adding `schemas/sdd-plus-superpowers/` to OpenSpec core — a custom schema bridging OpenSpec's artifact governance with [obra/superpowers](https://github.com/obra/superpowers) execution skills (brainstorming, writing-plans, TDD-via-subagents, code review, finishing).

Maintainer `alfred-openspec` reviewed and raised three structural concerns:
1. **Strong coupling without capability detection** — schema hard-codes Superpowers skill names; no version check, install check, or fallback beyond prompt text. If Superpowers renames a skill, OpenSpec ships a stale built-in schema.
2. **`verify` artifact timing mismatch** — schema declares `requires: [plan]` but instruction states verify must run *after* apply completes. OpenSpec's filesystem-based artifact graph cannot enforce the timing rule; depends on the model obeying prompt text.
3. **`apply.instruction` Step 0 auto-commit** — schema instruction directs the agent to inspect git state and create a commit before worktree creation, which is more aggressive than OpenSpec's default and constitutes a real repository side effect inside a schema instruction.

Alfred's recommendation: keep this as community recipe / external package rather than built-in.

## Goals

- Move the `sdd-plus-superpowers` schema out of OpenSpec core into a community repository at `JiangWay/openspec-schemas`
- Address the three concerns concretely, not just rhetorically (i.e., real fixes for #1 and #3, documented limitation with named migration target for #2)
- Position the new repository as the OpenSpec equivalent of [`RbBtSn0w/spec-kit-extensions`](https://github.com/RbBtSn0w/spec-kit-extensions/tree/main/superpowers-bridge) — a community catalog hosting multiple schemas and bridges
- Set up the repository so future bridges (filling other Superpowers gaps, or integrating other systems) can be added without restructuring

## Non-Goals

- Reshape OpenSpec core (e.g., add `requires_skills:` field, `post_apply` phase). These are noted as future work that would obsolete some of our compromises but are out of scope here.
- Distribute `workflow-retrospective` as a Claude Code plugin in v1. The 6-step retrospective procedure is embedded directly in the `retrospective` artifact instruction; v1.1 may upgrade to plugin distribution if usage warrants.

## Decisions

### Decision 1: Repository structure — `openspec-schemas/` monorepo with flat per-bridge directories

**Decision**: Each bridge is a self-contained directory at the repository root; schema files (`schema.yaml`, `INTEGRATION.md`, `README.md`, `extension.yml`, `templates/`) live directly in the bridge directory, not nested under `schema/` and `skills/` subdirs.

**Why**: Mirrors the install path (`openspec/schemas/<bridge>/`) so users can `cp -R superpowers-bridge openspec/schemas/` in one step. Future bridges add as siblings (`openspec-schemas/<other-bridge>/`).

**Alternatives considered**:
- *Nested `schema/` + `skills/` subdirs per bridge* — rejected because it doubled install steps and we ultimately chose not to ship a Claude Code skill in v1 (Decision 3).
- *Multi-repo (one repo per bridge)* — rejected; speckit ecosystem evidence (RbBtSn0w monorepo) shows monorepo scales better for solo-maintained side projects.

### Decision 2: Naming — `openspec-schemas` (lowercase + hyphen + plural)

**Decision**: Repository named `openspec-schemas`. Each bridge uses lowercase + hyphen (`superpowers-bridge`). Schema's `name:` field matches its directory.

**Why**: Aligns with the OpenSpec install path (`openspec/schemas/`, plural lowercase), the OpenSpec CLI command (`openspec`, lowercase), and the npm package name (`@fission-ai/openspec`, lowercase). Upstream's PascalCase repo name (`Fission-AI/OpenSpec`) is a branding exception, not a convention.

### Decision 3: `workflow-retrospective` — embed procedure in schema, defer plugin packaging

**Decision**: The retrospective procedure (6 sections: Wins / Misses / Plan deviations / Skill compliance / Surprises / Promote candidates) is embedded directly in the `retrospective` artifact's `instruction` field in `schema.yaml`. No `SKILL.md`, no Claude Code plugin manifest, no marketplace.

**Why**: v1 ships a single artifact (the schema) with a single install step. Authoring a Claude Code plugin requires marketplace setup, plugin manifest format, and a separate install path — overhead unwarranted before evidence of demand. v1.1 can upgrade if users request `/workflow-retrospective` invocation.

**Migration path documented**: `INTEGRATION.md` and the v1.1 backlog (`pr-quizzical-oasis.md`) both note that converting to a plugin requires extracting the procedure into `SKILL.md` and adding `.claude-plugin/plugin.json` + a marketplace listing.

### Decision 4: Address concern #3 (auto-commit) by removal

**Decision**: Remove apply Step 0 entirely. Replace with a Pre-flight section that verifies required Superpowers skills (`using-git-worktrees`, `subagent-driven-development`, `finishing-a-development-branch`) are available before proceeding.

**Why**: Handling untracked change artifacts is the worktree skill's responsibility, not the schema's. If the worktree skill doesn't handle it, that's a Superpowers-side concern. A schema should not silently rewrite user git history.

### Decision 5: Address concern #1 (capability detection) at two layers

**Layer 1 (skill-name PRECHECK)**: Each artifact / apply step that invokes a Superpowers skill performs a PRECHECK at the start of its instruction:

> "Confirm `superpowers:<skill>` appears in your available skills list. If missing, STOP and inform the user that the Superpowers plugin must be installed."

**Layer 2 (evidence-based PRECHECK for verify and retrospective)**: For artifacts whose timing depends on runtime state (apply phase having produced commits, verify having passed), the PRECHECK uses observable shell evidence:

```bash
# verify PRECHECK
git log --oneline $(git merge-base HEAD origin/main)..HEAD | wc -l   # must > 0
grep -c '^\- \[x\]' openspec/changes/<name>/tasks.md                  # must > 0

# retrospective PRECHECK
test -f openspec/changes/<name>/verify.md
grep -q 'Pass Criteria.*✓' openspec/changes/<name>/verify.md
```

The LLM checks concrete observable state rather than interpreting abstract timing prose. Even if the LLM mis-reads the timing rule, `git log | wc -l` returning 0 is unambiguous.

**Why**: This is a real concrete fix for alfred's "depends on the model obeying a paragraph of prompt text" concern, not just rhetorical defense. Available *today* without OpenSpec core changes.

### Decision 6: Address concern #2 (verify timing) as documented limitation, with named migration target

**Decision**: `verify` remains an artifact with `requires: [plan]`. INTEGRATION.md documents this as a known limitation with the migration target named: when OpenSpec introduces a `post_apply` phase concept (analogous to spec-kit's `after_implement` hook), `verify` migrates from artifact to `post_apply` step.

The same applies to `retrospective`.

**Why**: As a community schema (opt-in per change), the failure cost is bounded — adopters accept the trade-off. The Layer-2 evidence-based PRECHECK (Decision 5) significantly mitigates the concern in practice. A complete fix requires OpenSpec engine support that we cannot ship from a community repository.

### Decision 7: Install UX — Claude Code prompt as primary, bash as fallback

**Decision**: `superpowers-bridge/README.md` puts a copy-paste Claude Code prompt as the primary install method; bash commands appear as a secondary "alternative for non-Claude / CI use".

**Why**: Target users are already in Claude Code. A prompt is shorter, self-explaining, handles cross-platform shell differences automatically, and can intelligently set up Superpowers if missing. Bash fallback covers CI and prefer-shell users.

### Decision 8: PR #970 endgame — convert to docs-only proposal

**Decision**: PR #970 will be reframed as a docs-only PR removing `schemas/sdd-plus-superpowers/` and adding a "Community schemas" section to `docs/customization.md` linking to the new external repository. We aim for merge but accept close.

**Why**: spec-kit's [community extension catalog](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md) provides established precedent that core repos link to community extensions. The external repository stands on its own if alfred prefers not to link.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Superpowers renames a skill → bridge breaks silently | Layer-1 skill-name PRECHECK fails loudly; release-notes communicate the breakage |
| LLM ignores PRECHECK | Layer-2 evidence-based PRECHECK is harder to ignore (must produce actual command output) |
| Repository becomes maintenance burden | Solo-maintained; if abandoned, schema continues to work for current adopters until Superpowers breaks something |
| alfred rejects docs-only PR | External repo is self-sufficient; PR can be closed with no functional loss |

## Migration Plan

Implementation proceeds in phases:

- **Phase 0** — Baseline import: `git init`, copy schema verbatim from PR #970 into `superpowers-bridge/`, commit.
- **Phase 1** — Modifications: per-step commits applying decisions 4-7 above (~9 commits total). Local-only; no external action.
- **Phase 2** — External actions (gated, per-action user confirmation): create GitHub repo, push, reframe PR #970, comment to alfred.

Detailed step-by-step in `~/.claude/plans/pr-quizzical-oasis.md`.

## Open Questions

- **Roadmap content** — `docs/roadmap.md` is currently a placeholder. What other Superpowers gaps does the maintainer want to fill next? (Out of scope for v1; tracked in v1.1 backlog C.)
- **End-to-end CI** — `validate-schemas` checks structure only. A round-trip test (`/opsx:new` through `/opsx:archive` on a sample change) would catch regressions but requires installable Superpowers in CI. (Out of scope for v1; tracked in v1.1 backlog C.)
