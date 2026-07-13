# Verification Report

> This file is produced by the `verify` artifact (via `openspec instructions
> verify`) after apply completes, to confirm the implementation is consistent
> with specs / design / tasks. Failed checks must return to the corresponding
> artifact to fix, then re-run verify.

**Change**: `<change-name>`
**Verified at**: `YYYY-MM-DD HH:mm`
**Verifier**: `<who / which agent>`

---

## 1. Structural Validation (`openspec validate --all --json`)

- [ ] All items have `"valid": true`

**Result**:

```text
<paste summary of `openspec validate --all` output>
```

If any item failed, list id + issues:

| Item | Type | Issues |
|---|---|---|
| - | - | - |

---

## 2. Task Completion (`tasks.md`)

- [ ] All `- [ ]` have become `- [x]`

**Incomplete tasks** (if any):

| Task | Reason incomplete | Blocks archive? |
|---|---|---|
| - | - | - |

---

## 3. Delta Spec Sync State

For each capability directory under `openspec/changes/<name>/specs/`,
compare against `openspec/specs/<capability>/spec.md`:

| Capability | Sync state | Notes |
|---|---|---|
| - | synced / pending / N/A | - |

---

## 4. Design / Specs Coherence Spot Check

Sample-check whether `design.md` decisions are reflected in the Requirements
and Scenarios of `specs/*.md`:

| Sample item | design description | specs counterpart | Gap |
|---|---|---|---|
| - | - | - | - |

**Drift warnings** (non-blocking):

- <list if any; otherwise write "none">

---

## 5. Implementation Signal

- [ ] No unstaged files in the worktree
- [ ] All relevant commits pushed

**Commit range** (if known): `<from-sha>..<to-sha>`

---

## 6. Front-Door Routing Leak Detector (warning, non-blocking)

Design output should not land in `docs/superpowers/specs/` (the brainstorm
artifact's output redirection routes it to `openspec/changes/<name>/brainstorm.md`).

Detection:

```bash
ls docs/superpowers/specs/*.md 2>/dev/null
```

- [ ] No files, or any files present are legitimate leftovers from before schema install

**Leak list** (if any):

| File | Content captured into change? | Suggested action |
|---|---|---|
| - | - | - |

> Does not block archive. Leaks produced by a new schema-installed cycle should
> be moved into `openspec/changes/<name>/brainstorm.md` or `design.md`, then the
> original file deleted.

---

## 7. Deferred Manual Dogfood vs Automated Test Equivalence

For each manual dogfood / smoke task marked `[~]` deferred in plan.md, list
the equivalent automated test coverage. If there is no equivalent automated
test, that item should be treated as a **real gap** rather than a legitimate
deferral, and should be recorded in retrospective Misses.

| Deferred dogfood (plan §) | Equivalent automated test | Coverage assessment | Real gap? |
|---|---|---|---|
| e.g. §11.3 `compose up + curl /actuator/health` | `LinebcIntegrationApplicationTests` (Testcontainers, 24s) | Spring context boot + Flyway complete + main beans wired | already equivalently covered |
| - | - | - | - |

> **Interpretation rules**:
> - "Equivalent" = the automated test's assertion set is a superset of the manual dogfood's expected assertions
> - "Coverage assessment" = list the layers actually exercised (context / DB schema / wiring / HTTP path / etc.)
> - Any row with "real gap = yes" may still yield an Overall Decision of PASS, but must leave a follow-up entry in the retrospective

> **When this section may be left blank**: when plan.md has no rows marked `[~]`,
> this section need not be filled (blank = PASS). As soon as any `[~]` appears in
> plan.md, this section must list each item, otherwise Overall Decision drops to FAIL.

---

## Overall Decision

- [ ] PASS - may proceed to finishing-a-development-branch and archive
- [ ] PASS WITH WARNINGS - may proceed but note: `<explanation>`
- [ ] FAIL - return to the failed artifact to fix, then re-run verify

**Next step**:

<describe the next action>
