---
name: tdd-slice
description: "TDD slice execution with adversarial QA gate. ACTIVATE when: (1) user says 'start slice N', 'next slice', 'execute slice', (2) explicit /tdd-slice invocation. PREREQUISITE: Plan document with defined slices must exist at PLAN_*.md in the repo root and a GitHub issue must be tracking the work. FORBIDS: Skipping phases, claiming pass without evidence, proceeding without QA gate, self-approving."
---

# TDD Slice Execution Mode

**ROLE:** You execute one slice of a multi-slice plan using test-driven development. You produce structured, evidence-based output that a QA gate can evaluate mechanically. You do not evaluate your own work. You do not proceed past Phase 5 without a QA PASS.

---

## ⛔ HARD GATE: Prerequisites

```
IF no plan document at PLAN_*.md in the repo root:
    REFUSE — "No plan. Create plan first."

IF no GitHub issue tracking this work:
    REFUSE — "No tracking issue. Create issue first."

IF previous slice has not received QA PASS on the issue:
    REFUSE — "Slice N-1 not QA-cleared. Await gate."

IF previous slice QA PASS comment author.login ≠ "gitl-qa[bot]":
    REFUSE — "Slice N-1 QA PASS has invalid provenance.
    Expected author: gitl-qa[bot]
    Actual author: {actual_login}
    The QA verdict was not posted via the authorized posting protocol."
```

### Prior Slice QA Provenance Check

For Slice N where N > 1, before beginning Phase 1:

```bash
gh api /repos/{OWNER}/{REPO}/issues/{ISSUE_NUMBER}/comments?per_page=100 \
  --jq '[.[] | select(.body | test("Decision\\\\([0-9]+\\\\): PASS")) | select(.body | test("Slice '"$((N-1))"'"))] | last | .user.login'
```

The returned login MUST be exactly `gitl-qa[bot]`. Any other value — including `pollockjj`, `github-actions[bot]`, or any other bot — is a provenance failure. STOP immediately.

---

## ⛔ Critical Prohibitions

- **NO** `pkill`, `kill` commands
- **NO** `rm -rf` or destructive file operations
- **NO** Direct application launch — use the designated test runner
- **NO** Writing to `/tmp/` — use workspace directories only
- **NO** Installing packages into host venv — isolation deps go in isolated venv only
- **NO** Self-approval — you do not issue your own QA verdict
- **NO** Proceeding to the next slice without a QA PASS comment on the issue

---

## GitHub Posting Protocol

All GitHub posts route through `scripts/run_tdd_post.py`. **Never use `gh issue comment`, `gh api`, `scripts/post_as_app.py`, or any other direct posting mechanism.**

| Action | Command |
|:--|:--|
| Post comment | `scripts/run_tdd_post.py comment {OWNER}/{REPO} {ISSUE_NUMBER} {BODY_FILE}` |
| Update issue body | `scripts/run_tdd_post.py update-issue {OWNER}/{REPO} {ISSUE_NUMBER} {BODY_FILE}` |

- **Identity:** posts as `gitl-tdd[bot]`
- The runner resolves the correct Python interpreter, then delegates to `post_as_app.py`, which authenticates via JWT, posts, verifies the post landed, and prints the URL. Exits non-zero with FATAL on any failure.
- Record the printed URL immediately after every post.
- **Posting responsibility:** This skill invokes the runner directly — do NOT invoke `post_as_app.py` directly.

---

## Allowed Commands

```yaml
allowed:
  - <your test runner> *
  - debug/reset_gpu.sh
  - python -m ruff check *
  - python -m mypy *
  - python -m pytest *
  - git add, git commit, git status, git diff, git log
  - scripts/run_tdd_post.py (per GitHub Posting Protocol)
  - gh issue view, gh issue edit
  - ls, sha256sum, diff

forbidden:
  - pkill, kill
  - rm -rf
  - python main.py
  - pip install (into host venv)
```

---

## The 5 Phases (Strictly Sequential)

---

### Phase 1 — TDD Plan

Write and post the TDD plan to the GitHub issue. **This phase determines what the QA gate will evaluate.** The acceptance criteria you write here become the exact contract the gate will enforce.

#### Contract Format (MANDATORY — QA gate parses this mechanically)

The issue comment MUST contain a section formatted exactly as follows. Deviations break the QA gate's parser.

```markdown
## Slice N TDD Plan: [Title from plan]

### Objective
[One sentence: what this slice proves.]

### Acceptance Criteria

- AC-1: [Exact, independently verifiable criterion]
- AC-2: [Exact, independently verifiable criterion]
- AC-N: [Exact, independently verifiable criterion]

### Test Protocol
[Numbered commands the QA gate and any auditor can reproduce to verify each AC.]

1. [Command] → captures [artifact] → verifies [condition]
2. ...
```

#### Contract Rules

- Every AC must be independently verifiable from committed artifacts — not from your claims
- Every AC must map to at least one specific test protocol step
- No AC may require trusting agent assertions — evidence must speak for itself
- If comparing outputs: define comparison method and tolerance in the AC itself
- AC wording is fixed at post time — you do not revise ACs after Phase 1

**Post per the GitHub Posting Protocol:**
```bash
scripts/run_tdd_post.py comment {OWNER}/{REPO} {ISSUE_NUMBER} evidence/issue{ISSUE_NUMBER}/sliceN/phase1_plan.md
```
Record the printed URL — you will reference it in Phase 5.

**⛔ Post Provenance Verification (MANDATORY):**
After posting, extract the comment ID from the returned URL and verify authorship:
```bash
COMMENT_ID=$(echo "$URL" | grep -oP '\d+$')
AUTHOR=$(gh api /repos/{OWNER}/{REPO}/issues/comments/$COMMENT_ID --jq '.user.login')
```
The author MUST be `gitl-tdd[bot]`. If it is any other value:
- STOP immediately
- Report: `"FATAL: Phase 1 post provenance failure. Expected: gitl-tdd[bot], Got: {AUTHOR}. Post was not made via authorized protocol."`
- Do NOT proceed to Phase 2

---

### Phase 2 — Implementation

Execute the code changes defined in the plan for this slice.

- Follow `/execute` mode rules: quality gates, fail loud, no silent failures
- Match plan scope exactly — no scope creep, no "while I'm here" additions
- Run with `<your isolation flags>` for isolated runs
- No isolation deps in host venv

---

### Phase 3 — Evidence Collection (CI-Driven)

Evidence is collected by CI, not by you. Your job is to push code to a branch that triggers the CI workflow. CI runs tests, commits evidence, and posts results.

#### Workflow

1. **Create a branch** named `issue{ISSUE_NUMBER}/slice{N}` from main
2. **Commit your code changes** to that branch (implementation only — no test logs, no evidence artifacts)
3. **Push the branch** — this triggers the `.github/workflows/slice-evidence.yml` workflow
4. **Wait for CI to complete** — poll with `gh run list --branch issue{ISSUE_NUMBER}/slice{N}` until status is `completed`
5. **Verify CI success** — `gh run view {RUN_ID} --json conclusion --jq '.conclusion'` must be `success`

```bash
# Create branch and push code
git checkout -b issue{ISSUE_NUMBER}/slice{N}
git add [your code files]
git commit -m "issue{ISSUE_NUMBER} slice{N}: [description]"
git push origin issue{ISSUE_NUMBER}/slice{N}

# Wait for CI
sleep 15
RUN_ID=$(gh run list --branch issue{ISSUE_NUMBER}/slice{N} -R {OWNER}/{REPO} --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID -R {OWNER}/{REPO}
```

**You do NOT run tests yourself.** You do NOT commit evidence artifacts. You do NOT run pytest. CI does all of this. If you run tests locally to verify your code works before pushing, that is fine — but those local results are not evidence. Only CI-committed artifacts count.

#### Evidence Manifest

After CI completes, the evidence manifest is what CI committed. Record it:

```
EVIDENCE MANIFEST — Slice N
[E-1] ci-run       — <Actions run URL>                 — status: pass/fail
[E-2] test-log     — evidence/issue{ISSUE_NUMBER}/sliceN/test_run.log     — SHA: <CI commit SHA>
[E-3] checksums    — evidence/issue{ISSUE_NUMBER}/sliceN/sha256sums.txt   — SHA: <CI commit SHA>
```

The CI commit SHA is different from your code commit SHA. The CI commit is authored by `github-actions[bot]`. This identity separation is structural — you cannot fabricate CI evidence.

#### Collection Rules

- **Always use `pytest -v`** — the CI workflow is configured to use verbose mode. If you need to override test commands, update the workflow, not the test invocation.
- Evidence lives at `evidence/issue{ISSUE_NUMBER}/sliceN/` — canonical path, no exceptions.
- If CI fails: read the run log, fix your code, push again to the same branch. CI will re-run.

**⛔ Do NOT proceed to Phase 4 until CI completes successfully.**

If CI fails, do not proceed. Fix, push again, wait for CI. Report what broke and what you did.

If an AC cannot be verified with CI evidence, do not invent evidence. Mark it explicitly as NOT DONE in Phase 4.

---

### Phase 4 — Submission

Post results to the GitHub issue as a structured submission comment. The QA gate reads this comment as **pointers to evidence**, not as assertions. Every claim must cite a specific artifact from the evidence manifest.

#### Submission Format (MANDATORY — QA gate input)

```markdown
## Slice N TDD Results — [COMPLETE | BLOCKED]

**Submitted:** [run: date -u +"%Y-%m-%dT%H:%M:%SZ"]
**Code commit SHA:** [full SHA of your code commit on the branch]
**CI evidence commit SHA:** [full SHA of the CI-authored evidence commit]
**CI run:** [GitHub Actions run URL]
**Evidence directory:** evidence/issue{ISSUE_NUMBER}/sliceN/ @ [CI commit SHA]

### Evidence Manifest

- [E-1] [artifact type] — [path or SHA] — [brief description]
- [E-2] ...

### Acceptance Criteria Status

| # | Criterion | Status | Evidence |
|:--|:--|:--|:--|
| AC-1 | [verbatim from Phase 1] | DONE / NOT DONE | [E-ref or "NOT DONE"] |
| AC-2 | ... | ... | ... |
| AC-N | ... | ... | ... |

### Summary

[2–3 sentences. Factual only. No self-evaluation. Do not say "all criteria met" — the QA gate determines that.]

[If any AC is NOT DONE:]
#### Blocked Items
- AC-N: NOT DONE — [exact reason: what's missing, what failed, what was not attempted]
```

#### Submission Rules

- **NOT DONE is mandatory for any unmet criterion.** Do not omit it, soften it, or imply it might be close. The QA gate treats explicit NOT DONE as ground truth and will mark it NOT MET without further evaluation.
- Every DONE claim must cite an E-reference. A DONE with no E-reference is equivalent to NOT DONE.
- Criterion wording in the table must be verbatim from Phase 1. Do not paraphrase.
- Do not editorialize. Do not preemptively argue for a PASS. The gate decides.

**Post per the GitHub Posting Protocol:**
```bash
scripts/run_tdd_post.py comment {OWNER}/{REPO} {ISSUE_NUMBER} evidence/issue{ISSUE_NUMBER}/sliceN/phase4_results.md
```
Record the printed URL immediately.

**⛔ Post Provenance Verification (MANDATORY):**
After posting, extract the comment ID from the returned URL and verify authorship:
```bash
COMMENT_ID=$(echo "$URL" | grep -oP '\d+$')
AUTHOR=$(gh api /repos/{OWNER}/{REPO}/issues/comments/$COMMENT_ID --jq '.user.login')
```
The author MUST be `gitl-tdd[bot]`. If it is any other value:
- STOP immediately
- Report: `"FATAL: Phase 4 post provenance failure. Expected: gitl-tdd[bot], Got: {AUTHOR}. Post was not made via authorized protocol."`
- Do NOT proceed to Phase 5

---

### Phase 5 — QA Gate Invocation (Autonomous)

Invoke the QA gate programmatically via the self-contained gate runner script. Do not evaluate your own submission.

**Label transition:** Swap to `qa-slice` before invoking gate:
```bash
gh issue edit {ISSUE_NUMBER} -R {OWNER}/{REPO} --remove-label "tdd-slice" --add-label "qa-slice"
```

#### Gate Invocation

```bash
scripts/run_qa_gate.py slice {OWNER}/{REPO} {ISSUE_NUMBER} {SLICE_NUMBER} {SUBMISSION_COMMENT_URL}
```

Run that command directly as one blocking terminal call. Wait up to 300 seconds for it to exit before treating it as failed or stuck.

**Wait for the gate runner to complete.** Do not proceed until it exits. Do not poll with alternate commands, do not inspect partial output mid-run, and do not evaluate your own submission while it is still running.

**⛔ QA Verdict Provenance Verification (MANDATORY):**
After the gate runner exits, before acting on PASS or HOLD, verify the verdict comment was posted by `gitl-qa[bot]`:
```bash
VERDICT_AUTHOR=$(gh api /repos/{OWNER}/{REPO}/issues/{ISSUE_NUMBER}/comments?per_page=100 \
  --jq '[.[] | select(.body | test("Decision\\("))] | last | .user.login')
```
The author MUST be `gitl-qa[bot]`. If it is any other value:
- STOP immediately
- Report: `"FATAL: QA verdict provenance failure. Expected: gitl-qa[bot], Got: {VERDICT_AUTHOR}. Verdict was not posted via the authorized gate runner."`
- Do NOT act on the verdict
- Do NOT proceed to the next slice or report results to the human

#### On PASS — Non-Final Slice

If this is NOT the final slice in the plan: **proceed immediately to Phase 1 of Slice N+1.** No human approval is required between slices. The QA PASS is the authorization to continue.

**Label transition:** Swap back to `tdd-slice`:
```bash
gh issue edit {ISSUE_NUMBER} -R {OWNER}/{REPO} --remove-label "qa-slice" --add-label "tdd-slice"
```

#### On PASS — Final Slice

Before completing, post a post-mortem to the issue as `gitl-tdd[bot]`. Go back and do a full review of the issue. Do a post-mortem on the SKILL.md chained process you followed. How could this process have been improved? What could have been clearer? What caused you to misinterpret or otherwise create avoidable rework? Provide at least one suggestion that would have eliminated an impactful dead cycle.

```bash
scripts/run_tdd_post.py comment {OWNER}/{REPO} {ISSUE_NUMBER} {postmortem_file}
```

Then: **stop.** Post a completion summary to the issue. The pipeline is complete. No human approval required — the QA verdicts are the authority.

**Label transition:** Swap to `done`:
```bash
gh issue edit {ISSUE_NUMBER} -R {OWNER}/{REPO} --remove-label "qa-slice" --add-label "done"
```

#### On HOLD

The gate will post a HOLD with a per-criterion evaluation table and a "To Unblock" section. Read the HOLD verdict. Address only the specific blockers listed. Then:

1. Fix the failing criteria
2. Re-run from Phase 3 (re-collect evidence)
3. Post a new Phase 4 submission comment
4. Re-invoke the gate runner (repeat Phase 5)

Do not argue with the gate verdict. If you believe a HOLD is incorrect, document your reasoning to the user — do not post a counter-argument to the issue.

---

## Anti-Patterns (FORBIDDEN)

1. **Skipping phases** — every phase completes before the next starts
2. **Asserting instead of pointing** — "tests passed" without an E-reference is not evidence
3. **Omitting NOT DONE** — if a criterion is not met, the submission must say so explicitly
4. **Self-evaluation** — you do not determine whether your own submission PASSes
5. **Soft NOT DONE** — "mostly done," "partially implemented," "close" are NOT DONE
6. **Scope leak** — testing workflows or criteria from other slices
7. **Ghost commits** — citing artifacts you did not actually commit
8. **Proceeding past Phase 5 without PASS** — the gate verdict is the only unlock

---

## Post-Mortem Protocol (HOLD Received)

When the gate issues a HOLD, before addressing the blockers, write the following into the issue as an internal comment or into your memory blob:

```
POST-MORTEM — Slice N HOLD — [timestamp]
Failed criteria: [list AC numbers]
Root cause: [what was wrong — implementation, evidence collection, or test protocol]
NOT DONE items: [any that were explicitly marked NOT DONE vs. those that were evaluated and found lacking]
Fix required: [specific change needed per blocker]
```

This ensures the failure pattern is documented and available to future sessions rather than lost when this context window closes.

---

## GitHub Comment Templates (Quick Reference)

| Phase | Header |
|:--|:--|
| Phase 1 | `## Slice N TDD Plan: [title]` |
| Phase 4 COMPLETE | `## Slice N TDD Results — COMPLETE` |
| Phase 4 BLOCKED | `## Slice N TDD Results — BLOCKED` |
| Phase 5 | `## Slice N: Awaiting QA Gate` |

