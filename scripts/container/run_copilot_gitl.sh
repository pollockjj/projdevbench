#!/bin/bash
echo "🚀 Starting GITL Pipeline Evaluation"

# --- Cleanup ---
cleanup() {
    echo ""
    echo "========================================="
    echo "📊 Collecting evaluation results..."

    if [ -f "/workspace/submission_ids.log" ]; then
        SUBMISSION_LOG_DEST="/workspace/logs/submission_ids_${PROBLEM_ID}_${TIMESTAMP}.log"
        cp /workspace/submission_ids.log "$SUBMISSION_LOG_DEST"
        echo "✅ Submission IDs saved to: $SUBMISSION_LOG_DEST"
        echo ""
        echo "📝 Submission Summary:"
        echo "----------------------------------------"
        cat /workspace/submission_ids.log
        echo "----------------------------------------"
        SUBMISSION_COUNT=$(wc -l < /workspace/submission_ids.log)
        echo "Total submissions: $SUBMISSION_COUNT"
    else
        echo "⚠️ No submission log found"
    fi

    echo "========================================="
}

trap cleanup EXIT

: "${TIMESTAMP?Required: TIMESTAMP}"
echo "Using TIMESTAMP: $TIMESTAMP"

LOG_DIR="/workspace/logs"
mkdir -p "$LOG_DIR"

if [[ "$MODEL_NAME" == "Sonnet" || "$MODEL_NAME" == "Claude Sonnet 4.5" ]]; then
  LOG_MODEL_NAME="sonnet-4.5"
else
  LOG_MODEL_NAME="${MODEL_NAME// /-}"
  LOG_MODEL_NAME="${LOG_MODEL_NAME//\//-}"
fi

LOG_FILE="${LOG_DIR}/oj_eval_gitl_${LOG_MODEL_NAME}_${PROBLEM_ID}_${TIMESTAMP}.log"
echo "📝 Log file: $LOG_FILE"

exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "========================================="
echo "Current Environment Variables:"
env | grep -E '(PROBLEM|GITHUB_USER|MODEL|TIMESTAMP|GITL)' | grep -v -E '(TOKEN|KEY|AUTH|SECRET)'
echo "========================================="
echo "Current PATH: $PATH"
echo "========================================="

# --- Setup workspace (same as baseline) ---
echo "🚀 Running setting up shell script"
/scripts/run_agent_base.sh

echo "========================================="
echo "Setting up shell script completed"
echo "========================================="

: "${PROBLEM_ID?Required: PROBLEM_ID}"
: "${ACMOJ_PROBLEM_ID?Required: ACMOJ_PROBLEM_ID}"
: "${AGENT_TYPE?Required: AGENT_TYPE}"
: "${GITHUB_TOKEN?Required: GITHUB_TOKEN}"
: "${ACMOJ_TOKEN?Required: ACMOJ_TOKEN}"
: "${MAX_SUBMISSIONS?Required: MAX_SUBMISSIONS}"
: "${MODEL_NAME?Required: MODEL_NAME}"

REPO_NAME="oj-eval-${AGENT_TYPE}-${PROBLEM_ID}-${TIMESTAMP}"
GITHUB_USER="${GITHUB_USER:-your-oj-account}"
WORKSPACE_DIR="/workspace/problem_${PROBLEM_ID}"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}"

export SUBMISSION_LOG_FILE="/workspace/submission_ids.log"
touch "$SUBMISSION_LOG_FILE"

# --- Detect GITL mode: cold or informed ---
GITL_MODE="${GITL_MODE:-informed}"

echo "========================================="
echo "GITL Pipeline Evaluation"
echo "Problem ID: ${PROBLEM_ID} (ACMOJ: ${ACMOJ_PROBLEM_ID})"
echo "Agent Type: ${AGENT_TYPE}"
echo "Model Name: ${MODEL_NAME}"
echo "GITL Mode: ${GITL_MODE}"
echo "Timestamp: ${TIMESTAMP}"
echo "Repository: ${REPO_NAME}"
echo "Workspace: ${WORKSPACE_DIR}"
echo "Repo URL: ${REPO_URL}"
echo "Max ACMOJ Submissions: 1 (GITL final only)"
echo "Max QA Slice Attempts: 3 per slice"
echo "========================================="

cd "$WORKSPACE_DIR"

# --- Build the GITL prompt ---

INFORMED_BRIEFING=""
if [ "$GITL_MODE" = "informed" ]; then
    INFORMED_BRIEFING="
## Submission Environment
- Your solution will be compiled and tested by an automated judge against hidden test cases including edge cases.
- Compilation: if CMakeLists.txt exists, \`cmake .\` then \`make\`. Otherwise \`make\` directly. The compiled binary must be named \`code\`.
- You get ONE submission to the judge. Make it count.
- Your plan must ensure build compatibility, handle all boundary conditions described or implied by the spec, and produce a submission-ready result.
- You must create a .gitignore excluding build artifacts (CMakeFiles/, CMakeCache.txt).
"
fi

PROMPT="You are operating under the Grader-in-the-Loop (GITL) pipeline.

## Skills
Read ALL skill files in /workspace/skills/ (tdd-plan, tdd-slice, qa-plan, qa-slice). These define your workflow.

## Your Task
Read the problem specification in README.md and all provided source files in the current directory. Implement a complete, correct, production-quality solution.

## Pipeline Rules
1. Execute tdd-plan: analyze the problem, decompose into slices, write acceptance criteria, self-review, and get qa-plan PASS. No human approval needed — qa-plan PASS auto-proceeds.
2. Execute tdd-slice for each slice: implement, collect evidence, submit to qa-slice gate.
3. You get 3 qa-slice attempts per slice. If you cannot pass in 3 attempts, mark as DNF.
4. Evidence collection: run your tests locally (no CI in this container). Commit evidence to evidence/issue0/sliceN/.
5. After ALL slices pass qa-slice, make ONE final submission to ACMOJ.

## ACMOJ Submission
- Use submit_acmoj/acmoj_client.py to submit
- ACMOJ_TOKEN is configured in environment
- You get exactly ONE submission. Do not submit until all slices have passed your internal QA gate.
- Repository URL for submission: ${REPO_URL}
- ACMOJ Problem ID: ${ACMOJ_PROBLEM_ID}

## Posting Protocol
- The posting scripts (run_tdd_post.py, run_qa_gate.py) are NOT available in this container.
- Instead, write your plan, evidence, and results as local files in the workspace.
- The qa-plan and qa-slice evaluations happen in YOUR context — you read the skill, apply it to your own work, and determine PASS/HOLD yourself.
- This is a self-contained run: you are BOTH the implementer AND the evaluator, but you must follow the skill protocols strictly. Apply the 12-point plan audit. Apply the item-by-item AC evaluation. Do not skip checks.

## Git Management
- Commit all changes with clear messages
- Push to remote after each significant change: git push origin master
- Verify push succeeded before proceeding
${INFORMED_BRIEFING}
## Current Environment
- Repository URL: ${REPO_URL}
- Working Directory: $(pwd)
- Problem ID: ${PROBLEM_ID}
- ACMOJ Problem ID: ${ACMOJ_PROBLEM_ID}

Now begin. Read the skills, read the problem, plan, implement, verify, then submit once."

echo "========================================="
echo "GITL Prompt:"
echo "$PROMPT"
echo "========================================="

# --- Copy skills into container workspace ---
if [ -d "/workspace/skills" ]; then
    echo "✅ Skills directory found at /workspace/skills"
    ls /workspace/skills/
else
    echo "⚠️ No skills directory mounted. Agent will operate without GITL skills."
fi

echo "🚀 Starting GITL Agent..."
echo "Model: ${MODEL_NAME}"
echo "========================================="

copilot -p "${PROMPT}" --model "${MODEL_NAME}" --yolo --no-ask-user

echo "========================================="
echo "🎯 GITL Agent session completed"
echo "Repository: ${REPO_URL}"
echo "========================================="
