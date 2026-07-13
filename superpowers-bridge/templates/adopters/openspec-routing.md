<!-- Workflow routing rule for adopters. install.sh copies this (minus HTML comments) to .claude/rules/openspec-routing.md, auto-loaded by Claude Code at launch. -->
<!-- To customize routing in a target repo, edit its .claude/rules/openspec-routing.md. -->
<!-- v1.5.0-aligned: openspec v1.5.0 command set is propose/apply/archive/explore/sync (no new/ff/continue/verify). -->

## Workflow routing (read on session start)

This repo uses [`superpowers-bridge`](https://github.com/AllenMuu/openspec-superpowers/tree/main/superpowers-bridge) as the **default** workflow schema, integrating OpenSpec (what to do) with Superpowers (how to do it: brainstorming, writing-plans, git-worktrees, subagent-driven-development, TDD, code-review). Integration rules (language, artifact paths, PRECHECK) follow that bridge's README; this section is the routing guidance for Claude.

**Default schema = `superpowers-bridge`** (set in `openspec/config.yaml`). `/opsx:propose` therefore runs the full aggregated flow by default: `brainstorm -> proposal -> design -> specs -> tasks -> plan -> [apply] -> verify -> retrospective`. For lighter changes pass `--schema spec-driven` to `openspec new change`. Trivial fixes skip opsx entirely (direct PR).

### Entry routing

| Trigger you observe | What to do |
|---|---|
| User starts a narrative "design discussion / let's brainstorm" | Run verbal `superpowers:brainstorming`, but **do NOT** write to `docs/superpowers/specs/`. Once the conversation converges per the 5 criteria below, promote to `/opsx:propose` |
| User invokes `/opsx:propose` directly | Follow the schema's flow; artifact instructions inject at each step (default schema = superpowers-bridge) |
| User explicitly says bug fix / typo / config tweak / doc update | Direct PR - **do NOT** open a change (see skip rules below) |
| User is mid-change | Advance with `/opsx:apply` (worktree + subagent-driven-development) or `/opsx:archive`; use `/opsx:explore` to inspect, `/opsx:sync` to merge specs into main |

> v1.5.0 command set: `propose / apply / archive / explore / sync`. There is no `/opsx:new` / `/opsx:ff` / `/opsx:continue` / `/opsx:verify` in this version.

### When NOT to use opsx (direct PR)

| Scenario | Direct PR? |
|---|---|
| New feature / new capability / architectural change / breaking change | ❌ Use opsx |
| Bug fix (no contract change) / test backfill / linter tweak / non-breaking upgrade / typo / docs / config value tweak | ✅ Direct PR |

Principle: **process ceremony scales with risk**. External contracts / schema / cross-system integration / compliance -> opsx. Otherwise -> direct PR.

### Verbal brainstorm -> opsx promotion criteria

All 5 must hold before promoting (any missing -> keep brainstorming, **never** write to `docs/superpowers/specs/`):

1. **Scope locked** - one sentence describes what's in / out
2. **Major design forks resolved** - alternatives weighed; remaining TBDs have an owner and impact-scope statement
3. **Cross-system dependencies mapped** - ready / mockable / genuinely unknown - pick one per dep
4. **Acceptance criteria stateable** - concrete pass conditions (e.g., `./mvnw clean verify` passes + N deliverables)
5. **Conversation converging** - recent turns are confirmations, not new alternatives

When all 5 hold -> proactively suggest "ready to `/opsx:propose`?" - wait for user ack. Never auto-trigger.

### Front-door anti-patterns (don't do)

- Letting brainstorming write to `docs/superpowers/specs/`
- Letting writing-plans write to `docs/superpowers/plans/`
- Promoting to opsx with unresolved blocking TBDs
- Opening a change for bug fix / typo

Full detail: [superpowers-bridge README §Entry & exit gates](https://github.com/AllenMuu/openspec-superpowers/blob/main/superpowers-bridge/README.md#entry--exit-gates).
