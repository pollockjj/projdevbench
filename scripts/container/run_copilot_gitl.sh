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
: "${MODEL_NAME?Required: MODEL_NAME}"

REPO_NAME="oj-eval-${AGENT_TYPE}-${PROBLEM_ID}-${TIMESTAMP}"
GITHUB_USER="${GITHUB_USER:-your-oj-account}"
WORKSPACE_DIR="/workspace/problem_${PROBLEM_ID}"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}"

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

# --- Create tracking issue on gitl-pipeclean ---
echo "📋 Creating tracking issue..."
ISSUE_TITLE="Benchmark ${PROBLEM_ID}: ${MODEL_NAME} — GITL ${GITL_MODE}"
ISSUE_BODY="## Benchmark Problem ${PROBLEM_ID}

**Model:** ${MODEL_NAME}
**Mode:** ${GITL_MODE}
**Repo:** ${REPO_URL}
**Timestamp:** ${TIMESTAMP}

Problem files are in the agent workspace. The agent will execute the full GITL pipeline against this issue."

ISSUE_URL=$(cd /workspace/gitl-infra && python3 scripts/post_as_app.py tdd create-issue pollockjj/gitl-pipeclean --title "${ISSUE_TITLE}" --body "${ISSUE_BODY}" 2>&1)
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oP '/issues/\K\d+')

if [ -z "$ISSUE_NUMBER" ]; then
    echo "❌ Failed to create tracking issue"
    echo "Output: $ISSUE_URL"
    exit 1
fi

echo "✅ Tracking issue created: #${ISSUE_NUMBER}"
echo "   URL: ${ISSUE_URL}"

# --- Informed briefing ---
INFORMED_BRIEFING=""
if [ "$GITL_MODE" = "informed" ]; then
    INFORMED_BRIEFING="
IMPORTANT: Your solution will be graded by an automated judge against hidden test cases including edge cases. Your plan must ensure build compatibility, handle all boundary conditions described or implied by the spec, and produce a submission-ready result. A .gitignore excluding build artifacts is required. The build system uses cmake and make — ensure your CMakeLists.txt is compatible."
fi

# --- The prompt: skills are the instructions, prompt just activates them ---
PROMPT="You are executing a coding task under the Grader-in-the-Loop pipeline.

Your tracking issue is #${ISSUE_NUMBER} on pollockjj/gitl-pipeclean.
Your code workspace is $(pwd).
The pipeline infrastructure is at /workspace/gitl-infra.

READ THESE SKILL FILES — they are your PRIMARY instructions:
- /workspace/gitl-infra/.claude/skills/tdd-plan/SKILL.md
- /workspace/gitl-infra/.claude/skills/tdd-slice/SKILL.md
- /workspace/gitl-infra/.claude/skills/qa-plan/SKILL.md
- /workspace/gitl-infra/.claude/skills/qa-slice/SKILL.md

POSTING PROTOCOL:
- Post plans and submissions using: python3 /workspace/gitl-infra/scripts/run_tdd_post.py comment pollockjj/gitl-pipeclean {ISSUE_NUMBER} {BODY_FILE}
- Update issue body using: python3 /workspace/gitl-infra/scripts/run_tdd_post.py update-issue pollockjj/gitl-pipeclean {ISSUE_NUMBER} {BODY_FILE}
- Invoke QA gate using: python3 /workspace/gitl-infra/scripts/run_qa_gate.py plan pollockjj/gitl-pipeclean {ISSUE_NUMBER}
- Invoke QA slice gate using: python3 /workspace/gitl-infra/scripts/run_qa_gate.py slice pollockjj/gitl-pipeclean {ISSUE_NUMBER} {SLICE_NUMBER} {SUBMISSION_URL}

Replace {ISSUE_NUMBER} with ${ISSUE_NUMBER} in all commands.

EVIDENCE: Commit evidence to your code repo and push. The QA gate fetches from GitHub.

SCOPE: Read the problem files in $(pwd). Implement the solution. Follow the skills exactly. Do NOT submit to any external judge — your only job is to get all slices through the QA gate.

GIT: Push code changes to ${REPO_URL} using: git push origin master
${INFORMED_BRIEFING}
Begin now. Read the skills first."

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

# --- Post-agent: WE submit to ACMOJ, not the agent ---
echo "========================================="
echo "📤 GITL post-agent ACMOJ submission"
echo "========================================="

export SUBMISSION_LOG_FILE="/workspace/submission_ids.log"
touch "$SUBMISSION_LOG_FILE"

# Submit the final state of the repo to ACMOJ
echo "Submitting ${REPO_URL} to ACMOJ problem ${ACMOJ_PROBLEM_ID}..."
SUBMIT_RESULT=$(python3 /workspace/problem_${PROBLEM_ID}/submit_acmoj/acmoj_client.py \
    --token "${ACMOJ_TOKEN}" submit \
    --problem-id "${ACMOJ_PROBLEM_ID}" \
    --git-url "${REPO_URL}.git" 2>&1)
echo "Submit result: ${SUBMIT_RESULT}"

# Wait and check status
SUBMISSION_ID=$(echo "$SUBMIT_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
if [ -n "$SUBMISSION_ID" ]; then
    echo "Submission ID: ${SUBMISSION_ID}"
    echo "Waiting 30s for grading..."
    sleep 30
    STATUS_RESULT=$(python3 /workspace/problem_${PROBLEM_ID}/submit_acmoj/acmoj_client.py \
        --token "${ACMOJ_TOKEN}" status \
        --submission-id "${SUBMISSION_ID}" 2>&1)
    echo "Status: ${STATUS_RESULT}"
else
    echo "⚠️ Could not parse submission ID"
fi

echo "========================================="
echo "📊 GITL evaluation complete"
echo "Issue: https://github.com/pollockjj/gitl-pipeclean/issues/${ISSUE_NUMBER}"
echo "Code repo: ${REPO_URL}"
echo "========================================="
