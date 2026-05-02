# openspec-schemas Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 9 commits to `~/side_project/openspec-schemas/` that transform the imported PR #970 schema into a community schema bundle addressing alfred-openspec's three concerns.

**Architecture:** Per-commit modifications to one schema bundle (`superpowers-bridge/`). Each commit is independently reviewable, and `openspec schema validate` is run as a regression check after every commit. No code changes — only YAML schema edits, markdown docs, and a CI workflow.

**Tech Stack:** OpenSpec CLI 1.3.0, GitHub Actions YAML, Markdown, Claude Code skill prompts.

---

## File Structure

Files modified or created across the 9 commits:

| File | Status | Tasks |
|------|--------|-------|
| `LICENSE` | new | T1 |
| `.gitignore` | new | T1 |
| `superpowers-bridge/extension.yml` | new | T2 |
| `superpowers-bridge/schema.yaml` | modified | T3 / T4 / T5 / T6 / T7 |
| `superpowers-bridge/INTEGRATION.md` | modified | T7 |
| `superpowers-bridge/README.md` | modified | T7 / T8 |
| `superpowers-bridge/templates/retrospective.md` | new | T5 |
| `README.md` (top-level) | new | T8 |
| `docs/install.md` | new | T8 |
| `docs/roadmap.md` | new | T8 |
| `.github/workflows/validate-schemas.yml` | new | T9 |

After every Task, **regression check:** copy current `superpowers-bridge/` to a temp project, run `openspec schema validate <name>`, expect ✓.

---

## Conventions used throughout this plan

- **CWD assumption:** All `git` commands run from `~/side_project/openspec-schemas`. Re-cd if the shell resets.
- **Schema name during T1-T6:** still `sdd-plus-superpowers` (renamed in T7). All `openspec schema validate <name>` commands during these tasks use `sdd-plus-superpowers`. From T7 onwards, use `superpowers-bridge`.
- **Regression test wrapper:** Each "Step N: regression validate" reuses the temp project at `/tmp/oss-test-<task>/`. Cleared and re-populated each time so it's hermetic.
- **TDD pattern adapted for schema editing:** Each task starts with a `grep`/`test -f` assertion that should FAIL before the change, then PASS after.

---

## Task 0: Verify baseline state

Confirm the workspace matches expectations before starting.

- [ ] **Step 1: Verify cwd and current commits**

```bash
cd ~/side_project/openspec-schemas && git log --oneline
```

Expected:
```
3255710 docs: add brainstorming design spec for openspec-schemas monorepo
558efe9 chore: initial import — schema as-is from PR #970
```

If the SHAs differ but the messages match, OK.
If anything else, STOP and inform the user.

- [ ] **Step 2: Verify baseline schema validates**

```bash
rm -rf /tmp/oss-test-baseline && mkdir -p /tmp/oss-test-baseline/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge \
      /tmp/oss-test-baseline/openspec/schemas/sdd-plus-superpowers
cd /tmp/oss-test-baseline && openspec schema validate sdd-plus-superpowers
```

Expected: `✓ Schema 'sdd-plus-superpowers' is valid`.

If it fails, STOP and inform the user.

---

## Task 1: Add LICENSE and .gitignore

**Files:**
- Create: `~/side_project/openspec-schemas/LICENSE`
- Create: `~/side_project/openspec-schemas/.gitignore`

- [ ] **Step 1: Pre-test (assertions should FAIL)**

```bash
cd ~/side_project/openspec-schemas
test -f LICENSE && echo "fail" || echo "expected: missing"
test -f .gitignore && echo "fail" || echo "expected: missing"
```
Expected: both lines print `expected: missing`.

- [ ] **Step 2: Create LICENSE (MIT, copyright 2026 JiangWay)**

Use Write tool to create `~/side_project/openspec-schemas/LICENSE`:

```
MIT License

Copyright (c) 2026 JiangWay

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Create .gitignore**

Use Write tool to create `~/side_project/openspec-schemas/.gitignore`:

```
# OS
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
*.swp
*.swo

# Node (in case anyone runs commands locally)
node_modules/
npm-debug.log*

# Local test scratch
/tmp-test/
```

- [ ] **Step 4: Post-test (assertions should PASS)**

```bash
cd ~/side_project/openspec-schemas
test -f LICENSE && echo PASS || echo FAIL
test -f .gitignore && echo PASS || echo FAIL
wc -l LICENSE  # Expect ~21 lines
```

Expected: both PASS, LICENSE around 21 lines.

- [ ] **Step 5: Regression validate (schema still valid)**

```bash
rm -rf /tmp/oss-test-t1 && mkdir -p /tmp/oss-test-t1/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t1/openspec/schemas/sdd-plus-superpowers
cd /tmp/oss-test-t1 && openspec schema validate sdd-plus-superpowers
```
Expected: `✓ Schema 'sdd-plus-superpowers' is valid`.

- [ ] **Step 6: Commit**

```bash
cd ~/side_project/openspec-schemas
git add LICENSE .gitignore
git commit -m "chore: add LICENSE and .gitignore"
git log --oneline -1
```

Expected: latest commit message starts with `chore: add LICENSE and .gitignore`.

---

## Task 2: Add extension.yml documentation manifest

**Files:**
- Create: `~/side_project/openspec-schemas/superpowers-bridge/extension.yml`

This is a documentation contract (speckit-style manifest) — OpenSpec doesn't read it; it documents the bridge's dependency surface for future readers and the alfred message.

- [ ] **Step 1: Pre-test**

```bash
test -f ~/side_project/openspec-schemas/superpowers-bridge/extension.yml && echo "fail" || echo "expected: missing"
```
Expected: `expected: missing`.

- [ ] **Step 2: Create extension.yml**

Use Write tool. Adapted from spec-kit `EXTENSION-PUBLISHING-GUIDE.md` schema, kind set to `openspec-schema`. Includes `requires.skills[]` declarations matching the schema's PRECHECK list (which T4 will add). Mark this file with a header explaining OpenSpec doesn't currently read it.

```yaml
# Speckit-style extension manifest for the superpowers-bridge schema
#
# OpenSpec does NOT currently read this file. It is intentionally provided
# as a documentation contract showing the dependency surface of this schema
# in a structured, machine-readable form. If OpenSpec adds schema-level
# capability detection (modeled after spec-kit's `extension.yml`), this
# manifest can be migrated directly.
#
# References:
#   - spec-kit Extension Publishing Guide:
#     https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md
#   - RbBtSn0w/spec-kit-extensions superpowers-bridge:
#     https://github.com/RbBtSn0w/spec-kit-extensions/tree/main/superpowers-bridge
#   - Original PR thread (Fission-AI/OpenSpec#970) where the rationale lives.

schema_version: "1.0"

extension:
  id: superpowers-bridge
  name: Superpowers Bridge
  version: 1.0.0
  description: >
    Spec-driven workflow integrated with Superpowers skills.
    brainstorm → proposal → specs → tasks → plan → verify → retrospective,
    with apply delegated to git worktrees + subagent-driven-development
    (carrying TDD and code-review transitively).
  author: JiangWay
  repository: https://github.com/JiangWay/openspec-schemas
  license: MIT

requires:
  openspec_version: ">=1.3.0"

  skills:
    - name: superpowers:brainstorming
      required: true
      used_by: [artifacts.brainstorm]
    - name: superpowers:writing-plans
      required: true
      used_by: [artifacts.plan]
    - name: superpowers:using-git-worktrees
      required: true
      used_by: [apply.step_1_workspace]
    - name: superpowers:subagent-driven-development
      required: true
      used_by: [apply.step_2a_executor]
      transitive:
        - superpowers:test-driven-development
        - superpowers:requesting-code-review
    - name: superpowers:finishing-a-development-branch
      required: true
      used_by: [apply.step_4_completion]

# Notes on safe behavior — items intentionally NOT performed.
non_actions:
  - description: |
      This schema does NOT auto-commit user git history. The previously
      proposed "Step 0: pre-flight commit change artifacts" (see PR #970
      review) was removed. Handling of untracked change artifacts is the
      worktree skill's responsibility.
  - description: |
      This schema does NOT silently fall back when a required skill is
      missing. Each artifact / apply step that invokes a Superpowers
      skill performs a PRECHECK and STOPs with a clear error if the
      skill is unavailable.
```

- [ ] **Step 3: Post-test**

```bash
test -f ~/side_project/openspec-schemas/superpowers-bridge/extension.yml && echo PASS || echo FAIL
grep -q "id: superpowers-bridge" ~/side_project/openspec-schemas/superpowers-bridge/extension.yml && echo PASS || echo FAIL
grep -c "name: superpowers:" ~/side_project/openspec-schemas/superpowers-bridge/extension.yml
```
Expected: both PASS, count = 5 (5 declared skills).

- [ ] **Step 4: Regression validate**

```bash
rm -rf /tmp/oss-test-t2 && mkdir -p /tmp/oss-test-t2/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t2/openspec/schemas/sdd-plus-superpowers
cd /tmp/oss-test-t2 && openspec schema validate sdd-plus-superpowers
```
Expected: ✓ valid (extension.yml is ignored by openspec, doesn't break anything).

- [ ] **Step 5: Commit**

```bash
cd ~/side_project/openspec-schemas
git add superpowers-bridge/extension.yml
git commit -m "feat(superpowers-bridge): add extension.yml documentation manifest"
```

---

## Task 3: Remove apply Step 0 auto-commit

Addresses **alfred concern #3**.

**Files:**
- Modify: `~/side_project/openspec-schemas/superpowers-bridge/schema.yaml` (delete L219-252)

- [ ] **Step 1: Pre-test (asserting Step 0 currently exists)**

```bash
grep -q "0\. \*\*Pre-flight — commit change artifacts" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml && echo "PRE: present (will remove)" || echo "FAIL: should be present"
grep -c "git add openspec/changes/<name>/" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
```
Expected: prints `PRE: present (will remove)` and count = 1.

- [ ] **Step 2: Make the edit**

Use Edit tool on `~/side_project/openspec-schemas/superpowers-bridge/schema.yaml`.

Find this block (L219-252 in baseline):

```
    0. **Pre-flight — commit change artifacts to current branch**:

       Before creating the worktree, verify that the change directory
       `openspec/changes/<name>/` is committed on the current branch.
       This prevents drift between the main checkout and the worktree
       during implementation, and avoids "untracked files would be
       overwritten by merge" errors when later integrating the worktree
       back into the main branch.

       Steps:
       a. Run `git status --porcelain openspec/changes/<name>/` to
          inspect state.
       b. If the output contains untracked entries (lines starting
          with `??`), stage and commit ONLY this change's directory
          (do NOT use `git add -A`):

          ```
          git add openspec/changes/<name>/
          git commit -m "docs(openspec): scaffold <name> change

          Captures pre-implementation artifacts (brainstorm/proposal/
          specs/tasks/plan) so the implementation worktree starts
          with the change directory already tracked."
          ```

       c. If the output is empty (everything committed) or contains
          only modifications (`M`) without untracked entries, skip
          the commit — the change directory is already tracked.

       d. If on a detached HEAD or a branch that is not the project's
          integration branch (typically `main` or `master`), warn the
          user but still proceed — the commit lands on the current
          branch and will be merged later as usual.

    1. **Workspace**: Use the Skill tool to invoke
```

Replace with (only the renumber-to-Step-1 stays; Step 0 entirely deleted):

```
    1. **Workspace**: Use the Skill tool to invoke
```

(In the Edit tool: `old_string` is the entire block above starting from `    0. **Pre-flight — commit change artifacts...` ending at `    1. **Workspace**: Use the Skill tool to invoke`. `new_string` is just `    1. **Workspace**: Use the Skill tool to invoke`.)

- [ ] **Step 3: Post-test (Step 0 should be gone)**

```bash
grep -q "0\. \*\*Pre-flight — commit change artifacts" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml && echo FAIL || echo PASS
grep -c "git add openspec/changes/<name>/" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
grep -c "1\. \*\*Workspace\*\*: Use the Skill tool to invoke" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
```
Expected: PASS, count = 0, count = 1.

- [ ] **Step 4: Regression validate**

```bash
rm -rf /tmp/oss-test-t3 && mkdir -p /tmp/oss-test-t3/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t3/openspec/schemas/sdd-plus-superpowers
cd /tmp/oss-test-t3 && openspec schema validate sdd-plus-superpowers
```
Expected: ✓ valid.

- [ ] **Step 5: Commit**

```bash
cd ~/side_project/openspec-schemas
git add superpowers-bridge/schema.yaml
git commit -m "refactor(superpowers-bridge): remove apply Step 0 auto-commit

Addresses alfred-openspec's concern #3 from PR #970 review.
Handling untracked change artifacts is the worktree skill's
responsibility, not the schema's. The schema should not
silently rewrite user git history."
```

---

## Task 4: Add Superpowers skill PRECHECK to brainstorm/plan/apply

Addresses **alfred concern #1, layer 1** (skill-name PRECHECK).

**Files:**
- Modify: `~/side_project/openspec-schemas/superpowers-bridge/schema.yaml` (3 sites)

- [ ] **Step 1: Pre-test**

```bash
grep -c "PRECHECK — required skill availability" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
```
Expected: 0.

- [ ] **Step 2: Add PRECHECK to brainstorm artifact instruction**

Edit on schema.yaml.

`old_string`:
```
    instruction: |
      Use the Skill tool to invoke **superpowers:brainstorming**.

      IMPORTANT output redirection:
```

`new_string`:
```
    instruction: |
      PRECHECK — required skill availability:
      Before invoking, confirm `superpowers:brainstorming` appears in
      your available skills list. If missing, STOP and inform the user
      that the Superpowers plugin must be installed (or that they can
      explicitly opt to write brainstorm.md manually using the template
      below). Do NOT silently fall back.

      Use the Skill tool to invoke **superpowers:brainstorming**.

      IMPORTANT output redirection:
```

- [ ] **Step 3: Add PRECHECK to plan artifact instruction**

Edit on schema.yaml.

`old_string`:
```
    instruction: |
      Use the Skill tool to invoke **superpowers:writing-plans**.

      IMPORTANT output redirection:
      - Do NOT write to `docs/superpowers/plans/`. Instead, write
        the plan directly to this change's `plan.md`.
```

`new_string`:
```
    instruction: |
      PRECHECK — required skill availability:
      Before invoking, confirm `superpowers:writing-plans` appears in
      your available skills list. If missing, STOP and inform the user
      that the Superpowers plugin must be installed (or that they can
      explicitly opt to write plan.md manually using the template
      below). Do NOT silently fall back.

      Use the Skill tool to invoke **superpowers:writing-plans**.

      IMPORTANT output redirection:
      - Do NOT write to `docs/superpowers/plans/`. Instead, write
        the plan directly to this change's `plan.md`.
```

- [ ] **Step 4: Add new Step 0 (verify-skills) in apply.instruction**

Edit on schema.yaml. (Step 0 was deleted in T3, leaving the apply.instruction starting directly with "Step 1". Now we add a new Step 0 that does skill verification, not git side effects.)

`old_string`:
```
    Before implementing, set up an isolated workspace and executor:

    1. **Workspace**: Use the Skill tool to invoke
```

`new_string`:
```
    Before implementing, set up an isolated workspace and executor:

    0. **Pre-flight — verify required Superpowers skills**:

       This schema's apply phase requires the following skills.
       Confirm each appears in your available skills list before
       proceeding:

       - superpowers:using-git-worktrees
       - superpowers:subagent-driven-development
         (transitively: superpowers:test-driven-development,
                        superpowers:requesting-code-review)
       - superpowers:finishing-a-development-branch

       If any required skill is missing, STOP and inform the user —
       do NOT proceed and do NOT silently fall back to manual
       implementation. The user can install the Superpowers plugin,
       or explicitly opt into the manual fallback path described at
       the end of this instruction.

    1. **Workspace**: Use the Skill tool to invoke
```

- [ ] **Step 5: Post-test**

```bash
grep -c "PRECHECK — required skill availability" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
grep -q "0\. \*\*Pre-flight — verify required Superpowers skills" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml && echo PASS || echo FAIL
grep -c "do NOT silently fall back" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
```
Expected: count = 2 (brainstorm + plan), PASS, count >= 3 (one per PRECHECK + one in Step 0).

- [ ] **Step 6: Regression validate**

```bash
rm -rf /tmp/oss-test-t4 && mkdir -p /tmp/oss-test-t4/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t4/openspec/schemas/sdd-plus-superpowers
cd /tmp/oss-test-t4 && openspec schema validate sdd-plus-superpowers
```
Expected: ✓ valid.

- [ ] **Step 7: Commit**

```bash
cd ~/side_project/openspec-schemas
git add superpowers-bridge/schema.yaml
git commit -m "feat(superpowers-bridge): add Superpowers skill PRECHECK to brainstorm/plan/apply

Addresses alfred-openspec's concern #1 (capability detection)
at layer 1 — skill-name presence check before invocation.

Each artifact / apply step that invokes a Superpowers skill now
performs a PRECHECK against the LLM's available skills list and
STOPs with a clear error if missing, rather than silently falling
back. Apply phase gains a new Step 0 listing all required skills
upfront."
```

---

## Task 5: Promote retro to retrospective artifact + 6-step embedded procedure + template

Implements **Decision 3** (workflow-retrospective embedded, not plugin).

**Files:**
- Modify: `~/side_project/openspec-schemas/superpowers-bridge/schema.yaml` (remove retro from apply.instruction末段; add new `retrospective` artifact)
- Create: `~/side_project/openspec-schemas/superpowers-bridge/templates/retrospective.md`

- [ ] **Step 1: Pre-test**

```bash
grep -q "Recommended — Retrospective before archive" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml && echo "old retro present (will remove)" || echo FAIL
grep -q "id: retrospective" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml && echo FAIL || echo "no retro artifact yet"
test -f ~/side_project/openspec-schemas/superpowers-bridge/templates/retrospective.md && echo FAIL || echo "no template yet"
```
Expected: `old retro present (will remove)`, `no retro artifact yet`, `no template yet`.

- [ ] **Step 2: Remove the old retro section from apply.instruction**

Find this block (currently at L312-339 area in schema.yaml):

`old_string`:
```
    **Recommended — Retrospective before archive (non-blocking)**:

    Before archiving the change, it is strongly recommended (but not
    required) to write a short retrospective at `retrospective.md` in
    the change directory. A good retrospective raises the quality of
    every subsequent change because it captures what the diff alone
    cannot: why decisions were made, what surprised you, and which
    learnings deserve to be promoted to long-term memory.

    Evidence first, opinion second — every claim should cite a
    commit, file, or measurable fact. Suggested sections:

    - **Wins** — what worked well (with commit / test evidence)
    - **Misses** — what didn't work (🔴 blocking / 🟡 painful / 📌 nit)
    - **Plan deviations** — tasks whose scope changed, and why
    - **Skill / workflow compliance** — skills invoked vs. deliberately
      skipped (and the reason)
    - **Surprises** — assumptions that turned out wrong
    - **Promote candidates** — learnings to move into long-term memory,
      CLAUDE.md, or schema/skill updates (classify each candidate so
      insights don't die silently in the archive)

    If a `workflow-retrospective` skill is available in the environment,
    it can automate evidence collection; otherwise write the six
    sections manually. Skipping is acceptable for trivial changes
    (single-commit fixes) where the overhead exceeds the value.

    If any skill is unavailable, fall back to manual implementation
    using the standard task-by-task loop from tasks.md.
```

`new_string`:
```
    If any skill is unavailable, fall back to manual implementation
    using the standard task-by-task loop from tasks.md.
```

(The retro guidance is now relocated to its own `retrospective` artifact below; the trailing fallback line is preserved.)

- [ ] **Step 3: Add the new `retrospective` artifact**

Find the `verify` artifact's closing requires block:

`old_string`:
```
      If `openspec-verify-change` skill is unavailable, fall back to
      running the 5 checks manually and recording results in verify.md.
    requires:
      - plan

apply:
```

`new_string`:
```
      If `openspec-verify-change` skill is unavailable, fall back to
      running the 5 checks manually and recording results in verify.md.
    requires:
      - plan

  - id: retrospective
    generates: retrospective.md
    description: Evidence-first retrospective of completed change
    template: retrospective.md
    instruction: |
      Write a retrospective of this change with evidence-first analysis.

      IMPORTANT timing note:
      - retrospective.md is produced AFTER apply phase completes and
        verify.md shows no blocking issues. The `requires: [verify]`
        edge exists only for schema graph purposes; the actual
        retrospective MUST run on a completed, verified implementation.

      Process (follow these 3 steps):

      1. **Gather evidence**
         - Run `git log --oneline <base>..HEAD` in the change worktree
           (or main checkout if the worktree was already merged) to
           get the commit range
         - Read brainstorm.md, plan.md, tasks.md in this change
           directory for plan-vs-actual comparison
         - If verify.md contains failing items, address them BEFORE
           writing the retro

      2. **Write the 6 sections** — each claim cites a commit hash,
         file path, test name, or measurable fact:

         a) **Wins** — what worked well (with evidence)
         b) **Misses** — what didn't, marked by severity:
            - 🔴 blocking
            - 🟡 painful
            - 📌 nit
         c) **Plan deviations** — tasks whose scope changed, and why
         d) **Skill / workflow compliance** — list each skill in this
            schema's apply phase; mark whether it was actually used,
            and the reason if skipped
         e) **Surprises** — assumptions that turned out wrong
         f) **Promote candidates** — learnings worth moving to
            long-term memory / CLAUDE.md / schema or skill updates

      3. **Skipping policy**
         - Trivial single-commit fixes: OK to skip the retrospective
           entirely. Write a one-liner reason in retrospective.md
           (e.g. "Skipped: single-commit linter fix, no insights").
         - Anything else: produce all 6 sections (a placeholder
           "(none observed)" is fine if a section truly has nothing).

      Write output to retrospective.md using the template structure.
    requires:
      - verify

apply:
```

- [ ] **Step 4: Create the retrospective.md template**

Use Write tool to create `~/side_project/openspec-schemas/superpowers-bridge/templates/retrospective.md`:

```markdown
# Retrospective: <change-name>

> Written: <YYYY-MM-DD> (after verify passed)
> Commit range: `<base-sha>..<head-sha>`
> Worktree: <path or "merged to main">

---

## 1. Wins

- [evidence: <commit/file/test>] <description>

## 2. Misses

- 🔴 [blocking | evidence: ...] <description>
- 🟡 [painful  | evidence: ...] <description>
- 📌 [nit      | evidence: ...] <description>

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| 1.2       | ...          | ... |

## 4. Skill / workflow compliance

| Skill                                            | Used | Reason if skipped |
|--------------------------------------------------|------|-------------------|
| superpowers:brainstorming                        |      |                   |
| superpowers:writing-plans                        |      |                   |
| superpowers:using-git-worktrees                  |      |                   |
| superpowers:subagent-driven-development          |      |                   |
| (transitive) superpowers:test-driven-development |      |                   |
| (transitive) superpowers:requesting-code-review  |      |                   |
| superpowers:finishing-a-development-branch       |      |                   |

## 5. Surprises

- <assumption that turned out wrong>

## 6. Promote candidates

| Learning | Promote to | Notes |
|----------|------------|-------|
|          | CLAUDE.md / long-term memory / schema / skill |  |
```

- [ ] **Step 5: Post-test**

```bash
grep -q "Recommended — Retrospective before archive" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml && echo FAIL || echo PASS
grep -q "id: retrospective" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml && echo PASS || echo FAIL
grep -q "requires:" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml && grep -A2 "id: retrospective" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml | grep verify && echo PASS || echo FAIL
test -f ~/side_project/openspec-schemas/superpowers-bridge/templates/retrospective.md && echo PASS || echo FAIL
grep -c "^## " ~/side_project/openspec-schemas/superpowers-bridge/templates/retrospective.md
```
Expected: PASS, PASS, PASS, PASS, count = 6 (six section headers).

- [ ] **Step 6: Regression validate (now should list `retrospective` artifact)**

```bash
rm -rf /tmp/oss-test-t5 && mkdir -p /tmp/oss-test-t5/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t5/openspec/schemas/sdd-plus-superpowers
cd /tmp/oss-test-t5 && openspec schema validate sdd-plus-superpowers && openspec schemas | grep -A2 sdd-plus
```
Expected: ✓ valid; `Artifacts: brainstorm → proposal → design → specs → tasks → plan → verify → retrospective`.

- [ ] **Step 7: Commit**

```bash
cd ~/side_project/openspec-schemas
git add superpowers-bridge/schema.yaml superpowers-bridge/templates/retrospective.md
git commit -m "feat(superpowers-bridge): promote retro to retrospective artifact

Removes the old apply.instruction末段 'Recommended — Retrospective
before archive' guidance and replaces it with a proper retrospective
artifact (requires: [verify]).

Embeds the full 6-step retrospective procedure (gather evidence,
write 6 sections, skipping policy) directly in the artifact's
instruction. No external skill dependency — Decision 3 in the design
spec defers Claude Code plugin packaging to v1.1.

Adds templates/retrospective.md skeleton with 6 sections.

Note: retrospective shares the verify timing-mismatch limitation
(requires: [verify] in graph, but actually runs after apply
completes). Documented as known limitation; mitigated in T6 by
evidence-based PRECHECK."
```

---

## Task 6: Add evidence-based PRECHECK to verify and retrospective

Addresses **alfred concerns #1 layer 2 / #2 mitigation** (concrete shell evidence over abstract timing rules).

**Files:**
- Modify: `~/side_project/openspec-schemas/superpowers-bridge/schema.yaml` (verify + retrospective instructions)

- [ ] **Step 1: Pre-test**

```bash
grep -c "PRECHECK — implementation evidence" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
grep -c "PRECHECK — verify completion evidence" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
```
Expected: 0, 0.

- [ ] **Step 2: Add evidence PRECHECK to verify artifact**

Find the verify instruction opening:

`old_string`:
```
    instruction: |
      Use the Skill tool to invoke **openspec-verify-change** (the
      `/opsx:verify` slash command is its user-facing equivalent).

      IMPORTANT timing note:
```

`new_string`:
```
    instruction: |
      PRECHECK — implementation evidence:
      Before producing verify.md, run BOTH commands. If either
      returns 0, STOP and tell the user that apply phase has not
      yet produced reviewable changes.

      1. Commit evidence (must return > 0):
         git log --oneline $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null)..HEAD | wc -l

      2. Task progress (must return > 0):
         grep -c '^- \[x\]' openspec/changes/<change-name>/tasks.md

      Only after BOTH return positive numbers, proceed to invoke
      the verification skill below.

      Use the Skill tool to invoke **openspec-verify-change** (the
      `/opsx:verify` slash command is its user-facing equivalent).

      IMPORTANT timing note:
```

- [ ] **Step 3: Add evidence PRECHECK to retrospective artifact**

Find the retrospective instruction opening:

`old_string`:
```
    instruction: |
      Write a retrospective of this change with evidence-first analysis.

      IMPORTANT timing note:
```

`new_string`:
```
    instruction: |
      PRECHECK — verify completion evidence:
      Before producing retrospective.md, run these commands. If
      either fails, STOP and tell the user verify must pass first.

      1. verify.md exists:
         test -f openspec/changes/<change-name>/verify.md

      2. verify.md does not contain unresolved blocking issues:
         ! grep -q '^- 🔴' openspec/changes/<change-name>/verify.md

      Only after both succeed, proceed.

      Write a retrospective of this change with evidence-first analysis.

      IMPORTANT timing note:
```

- [ ] **Step 4: Post-test**

```bash
grep -c "PRECHECK — implementation evidence" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
grep -c "PRECHECK — verify completion evidence" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
grep -c "git log --oneline" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
```
Expected: 1, 1, count >= 2 (verify + retro both reference git log).

- [ ] **Step 5: Regression validate**

```bash
rm -rf /tmp/oss-test-t6 && mkdir -p /tmp/oss-test-t6/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t6/openspec/schemas/sdd-plus-superpowers
cd /tmp/oss-test-t6 && openspec schema validate sdd-plus-superpowers
```
Expected: ✓ valid.

- [ ] **Step 6: Commit**

```bash
cd ~/side_project/openspec-schemas
git add superpowers-bridge/schema.yaml
git commit -m "feat(superpowers-bridge): add evidence-based PRECHECK to verify and retrospective

Addresses alfred-openspec's concerns #1 and #2 at layer 2 — concrete
evidence-based timing checks instead of abstract prompt-only rules.

verify PRECHECK runs:
  - git log --oneline <base>..HEAD | wc -l (commit evidence)
  - grep -c '^- \\[x\\]' tasks.md (task progress)

retrospective PRECHECK runs:
  - test -f verify.md (verify produced)
  - ! grep -q '^- 🔴' verify.md (no blocking issues)

The LLM checks observable shell state rather than interpreting
timing prose. This is the v1 mitigation for verify/retrospective
timing mismatch; full fix requires OpenSpec engine support (post_apply
phase, tracked in v1.1 backlog)."
```

---

## Task 7: Rename schema name to superpowers-bridge + sync description

Implements **Decision 2** (final naming).

**Files:**
- Modify: `~/side_project/openspec-schemas/superpowers-bridge/schema.yaml` (name + description)
- Modify: `~/side_project/openspec-schemas/superpowers-bridge/INTEGRATION.md` (any name references + add known-limitations note for retro)
- Modify: `~/side_project/openspec-schemas/superpowers-bridge/README.md` (any name references)

- [ ] **Step 1: Pre-test**

```bash
grep -c "^name: sdd-plus-superpowers$" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
grep -c "sdd-plus-superpowers" ~/side_project/openspec-schemas/superpowers-bridge/INTEGRATION.md
grep -c "sdd-plus-superpowers" ~/side_project/openspec-schemas/superpowers-bridge/README.md
```
Expected: 1, several (INTEGRATION mentions multiple times), 1+.

- [ ] **Step 2: Rename `name:` in schema.yaml + update description**

`old_string`:
```
name: sdd-plus-superpowers
version: 1
description: >
  Spec-driven workflow integrated with Superpowers skills.
  brainstorm → proposal → specs → tasks → plan → verify.
  design is optional (produced from brainstorm but not required by tasks).
  Apply phase uses git worktrees + subagent-driven-development
  (brings TDD and code-review transitively). executing-plans is
  documented only as a fallback for platforms without subagent support.
```

`new_string`:
```
name: superpowers-bridge
version: 1
description: >
  Spec-driven workflow integrated with Superpowers skills.
  Requirements: Superpowers plugin installed, providing skills:
  brainstorming, writing-plans, using-git-worktrees,
  subagent-driven-development, finishing-a-development-branch.
  Each artifact / apply step verifies its required skills before
  invoking and surfaces a clear error if any are missing.
  brainstorm → proposal → specs → tasks → plan → verify → retrospective.
  design is optional (produced from brainstorm but not required by tasks).
  Apply phase uses git worktrees + subagent-driven-development
  (brings TDD and code-review transitively). executing-plans is
  documented only as a fallback for platforms without subagent support.
```

- [ ] **Step 3: Update INTEGRATION.md**

The INTEGRATION.md may have several `sdd-plus-superpowers` references in headings, code blocks, footers. Use Bash:

```bash
sed -i.bak 's/sdd-plus-superpowers/superpowers-bridge/g' ~/side_project/openspec-schemas/superpowers-bridge/INTEGRATION.md
rm ~/side_project/openspec-schemas/superpowers-bridge/INTEGRATION.md.bak
```

Then add a known-limitations subsection to cover both verify and retrospective. Find this section near the end of INTEGRATION.md:

`old_string`:
```
### 5. Verify 是 schema graph 的 leaf 但實際在 apply 之後

`verify` 的 `requires: [plan]` 只是為了讓 schema graph 完整；它的 instruction 明寫「**MUST run on a completed implementation, NOT during planning**」。這是 OpenSpec DAG 與實際時序的刻意錯位，為的是讓 `openspec status` 能顯示 verify 進度。
```

`new_string`:
```
### 5. Verify 與 retrospective 是時序錯位的 artifacts(已知限制)

`verify` 的 `requires: [plan]` 與 `retrospective` 的 `requires: [verify]` 在 schema graph 上是「檔案存在」依賴，但兩者的 instruction 都明寫「MUST run AFTER apply phase / verify pass」。這是 OpenSpec 引擎能力不足造成的刻意錯位 —— 引擎只會檢查前置 artifact 檔案存在，不會檢查 apply phase 是否真的跑完、verify 是否真的 pass。

**v1 緩解**：每個 artifact 都加了 evidence-based PRECHECK，用 `git log` / `grep` 檢查可觀察的 runtime 狀態（commit 數、checkbox 完成度、verify.md 內容）。LLM 不必懂時序，只要會跑 shell 指令看 0/非 0。

**完整修法**：等 OpenSpec 引擎引入 `post_apply` phase（spec-kit 已有 `after_implement` hook 作為前例），屆時 verify 與 retrospective 都會從 artifact 遷移到 `post_apply`，引擎原生強制時序。
```

- [ ] **Step 4: Update README.md**

```bash
sed -i.bak 's/sdd-plus-superpowers/superpowers-bridge/g' ~/side_project/openspec-schemas/superpowers-bridge/README.md
rm ~/side_project/openspec-schemas/superpowers-bridge/README.md.bak
```

- [ ] **Step 5: Post-test**

```bash
grep -c "^name: superpowers-bridge$" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
grep -c "^name: sdd-plus-superpowers$" ~/side_project/openspec-schemas/superpowers-bridge/schema.yaml
grep -c "sdd-plus-superpowers" ~/side_project/openspec-schemas/superpowers-bridge/INTEGRATION.md
grep -c "sdd-plus-superpowers" ~/side_project/openspec-schemas/superpowers-bridge/README.md
grep -c "Verify 與 retrospective 是時序錯位的 artifacts" ~/side_project/openspec-schemas/superpowers-bridge/INTEGRATION.md
```
Expected: 1, 0, 0, 0, 1.

- [ ] **Step 6: Regression validate (now using new name)**

```bash
rm -rf /tmp/oss-test-t7 && mkdir -p /tmp/oss-test-t7/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t7/openspec/schemas/superpowers-bridge
cd /tmp/oss-test-t7 && openspec schema validate superpowers-bridge && openspec schemas | grep superpowers-bridge
```
Expected: ✓ valid; lists `superpowers-bridge (project)`.

- [ ] **Step 7: Commit**

```bash
cd ~/side_project/openspec-schemas
git add superpowers-bridge/schema.yaml superpowers-bridge/INTEGRATION.md superpowers-bridge/README.md
git commit -m "chore(superpowers-bridge): rename schema name to superpowers-bridge

Implements Decision 2 from the design spec — final naming aligns
with the bridge's directory name and Decision 1's flat repository
structure.

Also:
  - Adds Requirements line to schema description
  - Adds retrospective to the artifact pipeline description
  - Updates INTEGRATION.md known-limitations section to cover both
    verify and retrospective time-mismatch (with v1 mitigation and
    full-fix migration path noted)
  - Search-replace any remaining sdd-plus-superpowers references
    in INTEGRATION.md and README.md"
```

---

## Task 8: Top-level docs and bridge README install section

Implements **Decision 7** (Claude prompt install primary, bash fallback).

**Files:**
- Create: `~/side_project/openspec-schemas/README.md`
- Create: `~/side_project/openspec-schemas/docs/install.md`
- Create: `~/side_project/openspec-schemas/docs/roadmap.md`
- Modify: `~/side_project/openspec-schemas/superpowers-bridge/README.md` (add Install section)

- [ ] **Step 1: Pre-test**

```bash
test -f ~/side_project/openspec-schemas/README.md && echo FAIL || echo "expected: missing"
test -f ~/side_project/openspec-schemas/docs/install.md && echo FAIL || echo "expected: missing"
test -f ~/side_project/openspec-schemas/docs/roadmap.md && echo FAIL || echo "expected: missing"
grep -q "## Install" ~/side_project/openspec-schemas/superpowers-bridge/README.md && echo FAIL || echo "expected: no install section"
```
Expected: all 4 print "expected: ...".

- [ ] **Step 2: Create top-level README.md**

Use Write tool. Content:

````markdown
# openspec-schemas

Community-contributed [OpenSpec](https://github.com/Fission-AI/OpenSpec) schemas. Each schema is a self-contained bundle that you copy into your project's `openspec/schemas/` directory and select per-change with `--schema <name>`.

## Bridges in this repository

| Bridge | Purpose | Status |
|--------|---------|--------|
| [`superpowers-bridge`](./superpowers-bridge/) | Bridges OpenSpec's artifact governance with [obra/superpowers](https://github.com/obra/superpowers) execution skills (brainstorming, writing-plans, TDD-via-subagents, code review, finishing). Adds an evidence-first `retrospective` artifact filling a gap Superpowers does not natively cover. | v1 |

## Why a separate repository?

[OpenSpec PR #970](https://github.com/Fission-AI/OpenSpec/pull/970) originally proposed `sdd-plus-superpowers` as a built-in schema. After maintainer review, the integration moved to a community repository — same pattern as [github/spec-kit's community extension catalog](https://speckit-community.github.io/extensions/), which keeps third-party tool integrations out of core.

Benefits:
- OpenSpec core does not take on Superpowers' release cadence
- Bridge can iterate independently
- Other community schemas can join this repository as siblings

## Install

See [`docs/install.md`](./docs/install.md) for the complete install guide. Each bridge directory also has its own `README.md` with a copy-paste Claude Code prompt for one-shot installation.

## Roadmap

See [`docs/roadmap.md`](./docs/roadmap.md) for what's planned.

## License

MIT — see [LICENSE](./LICENSE).
````

- [ ] **Step 3: Create docs/install.md**

Use Write tool. Content:

````markdown
# Install guide

This repository hosts multiple OpenSpec schema bundles. Pick the bridge you want, then install via either method below.

## Method 1: Claude Code one-shot prompt (recommended)

Open Claude Code in your project root and paste this prompt (substitute `<bridge-name>` with `superpowers-bridge` or another bridge):

```
Install the <bridge-name> schema for OpenSpec into this project:

1. Verify the project has an `openspec/` directory (run `openspec init` if missing).
2. Clone https://github.com/JiangWay/openspec-schemas to a temp dir.
3. Copy the `<bridge-name>/` subdirectory to `openspec/schemas/<bridge-name>/`.
4. Run `openspec schema validate <bridge-name>` to verify.
5. Run `openspec schemas` and confirm `<bridge-name>` is listed.
6. Clean up the temp directory.
7. If the bridge requires the Superpowers plugin, verify it's installed
   by running `claude plugin list`. If not listed, run
   `claude plugin install superpowers@claude-plugins-official`.
8. Show me the final state.
```

Claude will execute the install end-to-end, including any per-bridge dependencies.

## Method 2: Manual bash (CI / non-Claude environments)

```bash
# Replace <bridge-name>
BRIDGE=superpowers-bridge
git clone https://github.com/JiangWay/openspec-schemas /tmp/oss
cp -R /tmp/oss/$BRIDGE ~/your-project/openspec/schemas/$BRIDGE
rm -rf /tmp/oss
cd ~/your-project
openspec schema validate $BRIDGE
openspec schemas
```

For Superpowers-dependent bridges:

```bash
claude plugin install superpowers@claude-plugins-official
```

## Verify

After install, in your project root:

```bash
openspec schemas       # Should list the new schema as "(project)"
openspec schema validate <bridge-name>  # Should print ✓ valid
```

To use the new schema for a change:

```bash
/opsx:new my-feature --schema <bridge-name>
```
````

- [ ] **Step 4: Create docs/roadmap.md**

Use Write tool. Content:

````markdown
# Roadmap

This repository is actively maintained as a side project. The roadmap below sketches what's planned but isn't a contract — items can shift based on what real usage surfaces.

## v1 — Released

- [x] **`superpowers-bridge`** — bridges OpenSpec ↔ obra/superpowers + native `retrospective` artifact

## v1.x — In follow-up backlog

These items are tracked in `~/.claude/plans/pr-quizzical-oasis.md` (the implementation plan):

- [ ] **`workflow-retrospective` skill packaging** — currently the retrospective procedure is embedded in the schema instruction (Decision 3). If real users need to invoke `/workflow-retrospective` interactively (outside the schema flow), repackage as a Claude Code plugin
- [ ] **End-to-end CI integration test** — current CI only runs `openspec schema validate`. A round-trip test (`/opsx:new` through `/opsx:archive`) would catch regressions but requires Superpowers in CI
- [ ] **Verify artifact 5 polish points** — listed in v1.1 backlog A (templates clarity, design optional handling, worktree origin, pass criteria, TDD note)

## Awaiting OpenSpec core

These cannot be solved in a community schema:

- [ ] **`requires_skills:` schema field** — would replace the prompt PRECHECKs with engine-validated declarations
- [ ] **`post_apply` phase** — would let `verify` and `retrospective` be true post-apply hooks instead of artifacts with timing-mismatch (analogous to spec-kit's `after_implement`)

## Future bridge candidates

When real demand surfaces:

- [ ] **`obra-bridge`** — broader integration with other obra/* tools (if the user community grows)
- [ ] **Domain-specific schemas** — e.g., a `data-pipeline` schema variant with stronger schema-validation artifacts

Want to suggest a bridge? Open an issue at <https://github.com/JiangWay/openspec-schemas/issues>.
````

- [ ] **Step 5: Add Install section to bridge README**

Use Edit tool on `~/side_project/openspec-schemas/superpowers-bridge/README.md`.

Find the existing first-line heading and immediately add the Install section after it.

`old_string`:
```
# superpowers-bridge Schema

將 OpenSpec 的 artifact 治理流程與 Superpowers 的執行技能整合為單一工作流。
```

`new_string`:
````
# superpowers-bridge Schema

將 OpenSpec 的 artifact 治理流程與 Superpowers 的執行技能整合為單一工作流。

## Install

### Method 1: Claude Code one-shot prompt (recommended)

Copy and paste this into Claude Code in your project root:

```
Install the superpowers-bridge schema for OpenSpec into this project:

1. Verify the project has an `openspec/` directory (run `openspec init` if missing).
2. Clone https://github.com/JiangWay/openspec-schemas to a temp dir.
3. Copy the `superpowers-bridge/` subdirectory to `openspec/schemas/superpowers-bridge/`.
4. Run `openspec schema validate superpowers-bridge` to verify.
5. Run `openspec schemas` and confirm `superpowers-bridge` is listed.
6. Clean up the temp directory.
7. Verify Superpowers plugin is installed by running `claude plugin list`.
   If not listed, run `claude plugin install superpowers@claude-plugins-official`.
8. Show me the final state.
```

### Method 2: Manual bash (CI / non-Claude environments)

```bash
git clone https://github.com/JiangWay/openspec-schemas /tmp/oss
cp -R /tmp/oss/superpowers-bridge ~/your-project/openspec/schemas/superpowers-bridge
rm -rf /tmp/oss
cd ~/your-project
openspec schema validate superpowers-bridge
claude plugin install superpowers@claude-plugins-official  # if not already
```

## What it does
````

- [ ] **Step 6: Post-test**

```bash
test -f ~/side_project/openspec-schemas/README.md && echo PASS || echo FAIL
test -f ~/side_project/openspec-schemas/docs/install.md && echo PASS || echo FAIL
test -f ~/side_project/openspec-schemas/docs/roadmap.md && echo PASS || echo FAIL
grep -q "## Install" ~/side_project/openspec-schemas/superpowers-bridge/README.md && echo PASS || echo FAIL
grep -q "Method 1: Claude Code one-shot prompt" ~/side_project/openspec-schemas/docs/install.md && echo PASS || echo FAIL
```
Expected: 5x PASS.

- [ ] **Step 7: Regression validate**

```bash
rm -rf /tmp/oss-test-t8 && mkdir -p /tmp/oss-test-t8/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t8/openspec/schemas/superpowers-bridge
cd /tmp/oss-test-t8 && openspec schema validate superpowers-bridge
```
Expected: ✓ valid.

- [ ] **Step 8: Commit**

```bash
cd ~/side_project/openspec-schemas
git add README.md docs/ superpowers-bridge/README.md
git commit -m "docs: add top-level README + install + roadmap (claude prompt + bash dual-track)

Implements Decision 7 from the design spec — Claude Code one-shot
prompt as the primary install method, manual bash for CI / non-Claude
environments.

  - README.md: project overview + bridge index
  - docs/install.md: unified install guide for any bridge
  - docs/roadmap.md: v1 / v1.x / awaiting-OpenSpec-core / future bridges
  - superpowers-bridge/README.md: per-bridge install section"
```

---

## Task 9: Add validate-schemas CI workflow

**Files:**
- Create: `~/side_project/openspec-schemas/.github/workflows/validate-schemas.yml`

- [ ] **Step 1: Pre-test**

```bash
test -f ~/side_project/openspec-schemas/.github/workflows/validate-schemas.yml && echo FAIL || echo "expected: missing"
```
Expected: `expected: missing`.

- [ ] **Step 2: Create the workflow file**

Use Write tool. Content:

```yaml
name: Validate schemas

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    timeout-minutes: 5

    strategy:
      matrix:
        bridge:
          - superpowers-bridge

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"

      - name: Install OpenSpec CLI
        run: npm install -g @fission-ai/openspec

      - name: Set up temp project + install bridge
        run: |
          mkdir -p /tmp/test-project/openspec/schemas
          cp -R ${{ matrix.bridge }} /tmp/test-project/openspec/schemas/

      - name: Validate bridge schema
        working-directory: /tmp/test-project
        run: openspec schema validate ${{ matrix.bridge }}

      - name: List schemas (smoke test)
        working-directory: /tmp/test-project
        run: openspec schemas
```

(Matrix-style so adding more bridges later only requires extending `matrix.bridge`.)

- [ ] **Step 3: Post-test**

```bash
test -f ~/side_project/openspec-schemas/.github/workflows/validate-schemas.yml && echo PASS
grep -q "matrix:" ~/side_project/openspec-schemas/.github/workflows/validate-schemas.yml && echo PASS
grep -q "openspec schema validate" ~/side_project/openspec-schemas/.github/workflows/validate-schemas.yml && echo PASS
```
Expected: 3x PASS.

- [ ] **Step 4: Local YAML lint sanity check**

```bash
python3 -c "import yaml; yaml.safe_load(open('/Users/waynechiang/side_project/openspec-schemas/.github/workflows/validate-schemas.yml'))" && echo "yaml valid"
```
Expected: `yaml valid`.

- [ ] **Step 5: Regression validate**

```bash
rm -rf /tmp/oss-test-t9 && mkdir -p /tmp/oss-test-t9/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-test-t9/openspec/schemas/superpowers-bridge
cd /tmp/oss-test-t9 && openspec schema validate superpowers-bridge
```
Expected: ✓ valid.

- [ ] **Step 6: Commit**

```bash
cd ~/side_project/openspec-schemas
git add .github/workflows/validate-schemas.yml
git commit -m "ci: add validate-schemas workflow

GitHub Actions matrix-style workflow that on every push and PR:
  1. Checks out the repo
  2. Installs the OpenSpec CLI from npm
  3. For each bridge in the matrix:
     a. Copies the bridge into a temp project's openspec/schemas/
     b. Runs openspec schema validate <bridge>
     c. Smoke-tests openspec schemas listing

Currently the matrix has one bridge (superpowers-bridge). To add a
new bridge later, extend matrix.bridge.

Note: this only validates schema structure (zod schema). End-to-end
round-trip testing is tracked in v1.x backlog as a follow-up (would
require Superpowers in CI)."
```

---

## Task 10: Final validation

After all 9 commits, do a final sanity check.

- [ ] **Step 1: Inspect commit history**

```bash
cd ~/side_project/openspec-schemas
git log --oneline
```

Expected (top to bottom, 11 commits including baseline + design):
```
ci: add validate-schemas workflow
docs: add top-level README + install + roadmap (claude prompt + bash dual-track)
chore(superpowers-bridge): rename schema name to superpowers-bridge
feat(superpowers-bridge): add evidence-based PRECHECK to verify and retrospective
feat(superpowers-bridge): promote retro to retrospective artifact
feat(superpowers-bridge): add Superpowers skill PRECHECK to brainstorm/plan/apply
refactor(superpowers-bridge): remove apply Step 0 auto-commit
feat(superpowers-bridge): add extension.yml documentation manifest
chore: add LICENSE and .gitignore
docs: add brainstorming design spec for openspec-schemas monorepo
chore: initial import — schema as-is from PR #970
```

- [ ] **Step 2: Final regression**

```bash
rm -rf /tmp/oss-final && mkdir -p /tmp/oss-final/openspec/schemas
cp -R ~/side_project/openspec-schemas/superpowers-bridge /tmp/oss-final/openspec/schemas/superpowers-bridge
cd /tmp/oss-final && openspec schema validate superpowers-bridge && openspec schemas
```

Expected: ✓ valid; lists `superpowers-bridge (project)` with full description; artifact pipeline shows `brainstorm → proposal → design → specs → tasks → plan → verify → retrospective`.

- [ ] **Step 3: Verify expected new files exist**

```bash
cd ~/side_project/openspec-schemas
test -f LICENSE
test -f .gitignore
test -f README.md
test -f docs/install.md
test -f docs/roadmap.md
test -f .github/workflows/validate-schemas.yml
test -f superpowers-bridge/extension.yml
test -f superpowers-bridge/templates/retrospective.md
test -f superpowers-bridge/schema.yaml
echo "all present"
```
Expected: `all present`.

- [ ] **Step 4: Verify expected DELETIONS in schema.yaml**

```bash
cd ~/side_project/openspec-schemas
grep -q "Pre-flight — commit change artifacts" superpowers-bridge/schema.yaml && echo FAIL || echo "PASS: Step 0 commit gone"
grep -q "git add openspec/changes/<name>/" superpowers-bridge/schema.yaml && echo FAIL || echo "PASS: auto-commit gone"
grep -q "Recommended — Retrospective before archive" superpowers-bridge/schema.yaml && echo FAIL || echo "PASS: old retro section gone"
```
Expected: 3 PASS lines.

- [ ] **Step 5: Verify expected ADDITIONS in schema.yaml**

```bash
cd ~/side_project/openspec-schemas
grep -c "^name: superpowers-bridge$" superpowers-bridge/schema.yaml      # 1
grep -c "PRECHECK — required skill availability" superpowers-bridge/schema.yaml  # 2 (brainstorm + plan)
grep -c "Pre-flight — verify required Superpowers skills" superpowers-bridge/schema.yaml  # 1
grep -c "id: retrospective" superpowers-bridge/schema.yaml      # 1
grep -c "PRECHECK — implementation evidence" superpowers-bridge/schema.yaml  # 1
grep -c "PRECHECK — verify completion evidence" superpowers-bridge/schema.yaml  # 1
```
Expected: 1, 2, 1, 1, 1, 1.

If any expected count is wrong, STOP and inform the user — something was missed.

---

## Self-review notes

**Spec coverage:** Each Decision in the design spec maps to a task:
- D1 (flat structure) → already done in Phase 0 baseline (no nested schema/skills/)
- D2 (naming) → T7
- D3 (workflow-retrospective embedded, not plugin) → T5 (no SKILL.md, no plugin manifest)
- D4 (concern #3 by removal) → T3
- D5 (concern #1 layer 1 + 2) → T4 (layer 1) + T6 (layer 2)
- D6 (concern #2 documented limitation) → T7 (INTEGRATION.md known limitation update)
- D7 (Claude prompt install) → T8
- D8 (PR #970 docs-only endgame) → out of scope for Phase 1; happens in Phase 2

**Placeholder scan:** No "TBD", "TODO", "implement later". Every code/text block is fully written out.

**Type consistency:** No types/methods to check. The only consistency-relevant thing is the schema's `name:` field — used as `sdd-plus-superpowers` in T1-T6 validation, then becomes `superpowers-bridge` in T7+. Plan respects this transition.

---

## Out of scope (handled in plan file, not here)

- Phase 2 (external actions: `gh repo create`, `git push`, PR #970 conversion, alfred comment) — listed in `~/.claude/plans/pr-quizzical-oasis.md`. Each requires explicit user confirmation.
