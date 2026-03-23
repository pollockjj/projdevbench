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

# --- Setup clean workspace — NO problem files, NO submit tools ---
: "${PROBLEM_ID?Required: PROBLEM_ID}"
: "${AGENT_TYPE?Required: AGENT_TYPE}"
: "${GITHUB_TOKEN?Required: GITHUB_TOKEN}"
: "${MODEL_NAME?Required: MODEL_NAME}"

REPO_NAME="oj-eval-${AGENT_TYPE}-${PROBLEM_ID}-${TIMESTAMP}"
GITHUB_USER="${GITHUB_USER:-pollockjj}"
WORKSPACE_DIR="/workspace/work_${PROBLEM_ID}"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}"

# Create empty workspace and git repo
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"
git init
git commit --allow-empty -m "initial empty commit"

# Create remote repo and push
gh repo create "${GITHUB_USER}/${REPO_NAME}" --public --confirm 2>&1 || true
git remote add origin "https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
git push -u origin HEAD:master 2>&1

echo "========================================="
echo "Clean workspace ready: ${WORKSPACE_DIR}"
echo "Repo: ${REPO_URL}"
echo "No problem files. Agent reads the issue for the problem definition."
echo "========================================="

# GITL mode: cold or informed
GITL_MODE="${GITL_MODE:-informed}"

echo "========================================="
echo "GITL Pipeline Evaluation"
echo "Problem ID: ${PROBLEM_ID} (ACMOJ: ${ACMOJ_PROBLEM_ID})"
echo "Model Name: ${MODEL_NAME}"
echo "GITL Mode: ${GITL_MODE}"
echo "Repository: ${REPO_NAME}"
echo "========================================="

cd "$WORKSPACE_DIR"

# --- Clone gitl-pipeclean for pipeline infrastructure ---
echo "📦 Cloning GITL pipeline infrastructure..."
git clone https://${GITHUB_TOKEN}@github.com/pollockjj/gitl-pipeclean.git /workspace/gitl-infra 2>&1
echo "✅ GITL infrastructure cloned"

# --- Issue number: pre-created or passed via GITL_ISSUE env var ---
: "${GITL_ISSUE?Required: GITL_ISSUE — the pre-created issue number on gitl-pipeclean}"
ISSUE_NUMBER="${GITL_ISSUE}"
echo "📋 Using pre-created issue: #${ISSUE_NUMBER}"
echo "   URL: https://github.com/pollockjj/gitl-pipeclean/issues/${ISSUE_NUMBER}"

# --- Informed briefing ---
INFORMED_BRIEFING=""
if [ "$GITL_MODE" = "informed" ]; then
    INFORMED_BRIEFING="
IMPORTANT: Your solution will be graded by an automated judge against hidden test cases including edge cases. Your plan must ensure build compatibility, handle all boundary conditions described or implied by the spec, and produce a submission-ready result. A .gitignore excluding build artifacts is required. The build system uses cmake and make — ensure your CMakeLists.txt is compatible."
fi

# --- The prompt ---
PROMPT="You are operating under a mandatory TDD pipeline. You MUST follow ALL FOUR skill files in order. Skipping any skill or phase is a fatal protocol violation.

STEP 1: Read ALL four skill files. They are your binding instructions:
  /workspace/gitl-infra/.claude/skills/tdd-plan/SKILL.md
  /workspace/gitl-infra/.claude/skills/tdd-slice/SKILL.md
  /workspace/gitl-infra/.claude/skills/qa-plan/SKILL.md
  /workspace/gitl-infra/.claude/skills/qa-slice/SKILL.md

STEP 2: Read the CLAUDE.md at /workspace/gitl-infra/CLAUDE.md for repository workflow mechanics.

STEP 3: Check open issues on pollockjj/gitl-pipeclean using: gh api /repos/pollockjj/gitl-pipeclean/issues --jq '.[0]'

STEP 4: Execute the tdd-plan skill against that issue. This is MANDATORY. You do not write code until the plan has passed qa-plan.

STEP 5: On qa-plan PASS, execute tdd-slice for each slice. Each slice MUST pass qa-slice before proceeding.

Your code workspace is $(pwd). Push code changes to ${REPO_URL} using: git push origin master
Posting scripts are at /workspace/gitl-infra/scripts/. The repo for issues is pollockjj/gitl-pipeclean.
${INFORMED_BRIEFING}
Begin by reading the four skill files."

echo "========================================="
echo "GITL Prompt (skills are primary instructions):"
echo "$PROMPT"
echo "========================================="

echo "🚀 Starting GITL Agent..."
copilot -p "${PROMPT}" --model "${MODEL_NAME}" --yolo --no-ask-user

echo "========================================="
echo "🎯 GITL Agent session completed"
echo "Issue: https://github.com/pollockjj/gitl-pipeclean/issues/${ISSUE_NUMBER}"
echo "Code repo: ${REPO_URL}"
echo "========================================="

# ACMOJ submission is done separately by the evaluator, not in this script.
echo "========================================="
echo "📊 GITL run complete. Code repo ready for external grading."
echo "Code repo: ${REPO_URL}"
echo "========================================="
