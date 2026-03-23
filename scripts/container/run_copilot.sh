#!/bin/bash
echo "🚀 Starting Cursor Agent Evaluation Script～～～～～～～～～～～～～～～～～～～～～～～～～～allow all paths"

# --- 清理函数 - 在脚本退出时执行 ---
cleanup() {
    echo ""
    echo "========================================="
    echo "📊 Collecting evaluation results..."
    
    # 复制 submission IDs 日志到日志目录
    if [ -f "/workspace/submission_ids.log" ]; then
        SUBMISSION_LOG_DEST="/workspace/logs/submission_ids_${PROBLEM_ID}_${TIMESTAMP}.log"
        cp /workspace/submission_ids.log "$SUBMISSION_LOG_DEST"
        echo "✅ Submission IDs saved to: $SUBMISSION_LOG_DEST"
        
        # 打印 submission IDs 摘要
        echo ""
        echo "📝 Submission Summary:"
        echo "----------------------------------------"
        cat /workspace/submission_ids.log
        echo "----------------------------------------"
        
        # 统计提交次数
        SUBMISSION_COUNT=$(wc -l < /workspace/submission_ids.log)
        echo "Total submissions: $SUBMISSION_COUNT"
    else
        echo "⚠️ No submission log found"
    fi
    
    echo "========================================="
}

# 注册清理函数，在脚本退出时执行
trap cleanup EXIT

# 使用传入的TIMESTAMP，如果没有则退出
: "${TIMESTAMP?Required: TIMESTAMP}"
echo "Using TIMESTAMP: $TIMESTAMP"
# Output to both terminal and file
LOG_DIR="/workspace/logs"
mkdir -p "$LOG_DIR"

# 如果模型是Sonnet或者Claude Sonnet 4.5，则为sonnet-4.5，其余的就是modelname,但是得把空格替换为-，斜杠替换为-
if [[ "$MODEL_NAME" == "Sonnet" || "$MODEL_NAME" == "Claude Sonnet 4.5" ]]; then
  LOG_MODEL_NAME="sonnet-4.5"
else
  LOG_MODEL_NAME="${MODEL_NAME// /-}"
  LOG_MODEL_NAME="${LOG_MODEL_NAME//\//-}"
fi

LOG_FILE="${LOG_DIR}/oj_eval_${AGENT_TYPE}_${LOG_MODEL_NAME}_${PROBLEM_ID}_${TIMESTAMP}.log"
echo "📝 Log file: $LOG_FILE"

exec > >(tee -a "$LOG_FILE")
exec 2>&1

# 打印所有环境变量来验证ENV PATH="$HOME/.local/bin:$PATH"
echo "========================================="
echo "Current Environment Variables:"
env | grep -E '(PROBLEM|GITHUB_USER|MODEL|TIMESTAMP)' | grep -v -E '(TOKEN|KEY|AUTH|SECRET)'
echo "========================================="
# 打印PATH变量
echo "Current PATH: $PATH"
echo "========================================="





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

# MODEL_NAME默认值，如果没有，则出错
: "${MODEL_NAME?Required: MODEL_NAME}"

# --- 配置变量 ---
REPO_NAME="oj-eval-${AGENT_TYPE}-${PROBLEM_ID}-${TIMESTAMP}"
GITHUB_USER="${GITHUB_USER:-your-oj-account}"
WORKSPACE_DIR="/workspace/problem_${PROBLEM_ID}"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}"

# 设置 submission log 文件路径
export SUBMISSION_LOG_FILE="/workspace/submission_ids.log"
touch "$SUBMISSION_LOG_FILE"
echo "📝 Submission tracking enabled: $SUBMISSION_LOG_FILE"

echo "========================================="
echo "OJBench Agent Repository Management Evaluation"
echo "Problem ID: ${PROBLEM_ID} (ACMOJ: ${ACMOJ_PROBLEM_ID})"
echo "Agent Type: ${AGENT_TYPE}"
echo "Model Name: ${MODEL_NAME}"
echo "Timestamp: ${TIMESTAMP}"
echo "Repository: ${REPO_NAME}"
echo "Workspace: ${WORKSPACE_DIR}"
echo "Repo URL: ${REPO_URL}"
echo "Max Submissions: ${MAX_SUBMISSIONS}"
echo "========================================="

# 进入工作目录/workspace/problem_${PROBLEM_ID}
cd "$WORKSPACE_DIR"

# run copilot
# --- 5. 准备完整的Agent提示词 ---

echo "🤖 Preparing Agent prompt..."

# 检测是否为多个Problem ID（通过检测是否包含逗号）
if [[ "$ACMOJ_PROBLEM_ID" == *","* ]]; then
    echo "✨ Detected MULTIPLE Problem IDs: ${ACMOJ_PROBLEM_ID}"
    echo "📋 Using Multi-Problem Prompt (PROMPT2)"
    USE_MULTI_PROMPT=true
else
    echo "✨ Detected SINGLE Problem ID: ${ACMOJ_PROBLEM_ID}"
    echo "📋 Using Single-Problem Prompt (PROMPT)"
    USE_MULTI_PROMPT=false
fi

# Single Problem Prompt
# Single Problem Prompt
PROMPT="You are a professional programming expert and Git expert. You are now in a Git repository and need to complete the following tasks:

## Current Environment
- Repository URL: ${REPO_URL}
- Working Directory: $(pwd)
- OJBench Problem ID: ${PROBLEM_ID}
- ACMOJ Problem ID: ${ACMOJ_PROBLEM_ID}
- Maximum Submission Limit: ${MAX_SUBMISSIONS} attempts

## Important Scoring Rules (Must Read!)

### Submission Limit
- This problem allows a maximum of ${MAX_SUBMISSIONS} submissions
- Submissions exceeding ${MAX_SUBMISSIONS} attempts will not be counted and will incur score penalties
- Please use your submission attempts wisely!

### OnlineJudge Scoring Calculation Method
1. Final score is based on the **highest score among all valid submissions**
2. Each problem has many test points
   - Score for each submission = sum of scores from all passed test points (unless otherwise specified)
   - Each test point may have different score weights (specific weights will not be disclosed)

## Important Notes
- You may freely modify all files in the current working directory (including README.md, etc.)
- You may create new files, add test cases, delete files, compile files, etc.
- No need to ask for my permission. Please complete the task until you achieve a satisfactory score or exhaust your submission attempts, then end the task

## Your Tasks
1. **Analyze the Problem**: Carefully read README.md and other files in the current directory, thoroughly analyze the project, and understand the requirements
2. **Develop Solution**: Implement the optimal solution
3. **Git Management**: Use git to manage your code versions
   - **After git push, verify the push was successful using command line**
   - If push failed, check error messages and retry
   - Every code modification must be committed to Git, maintaining a clear version history
4. **Submit to OJ and Check Results**: Carefully review the contents of the submit_acmoj directory
   - Use the submit_acmoj/acmoj_client.py script to submit tasks or query submission status
   - **During OJ submission and result checking, DO NOT modify or push to the remote repository**
   - Wait for OJ results before making any new commits or pushes
   - **Please remember the submission_id for each submission (needed for querying submission status)**
   - **Abort Mechanism**: The submit_acmoj/acmoj_client.py script provides an abort command. If a submission is pending for too long (e.g., more than 2-3 minutes), you can abort it
   - **Important: Aborted submissions DO NOT count toward your ${MAX_SUBMISSIONS} submission limit**
   - After aborting, you can resubmit the same or modified code
5. **Iterative Optimization**:
   - If OJ returns errors (such as Wrong Answer, Time Limit Exceeded, Runtime Error, Compile Error, etc.), analyze the problem and modify code accordingly, then resubmit, keeping in mind not to exceed ${MAX_SUBMISSIONS} attempts
6. **Record Process**: Every modification must be recorded with git commit, clearly stating the reason for changes
7. **Free Exploration**: You may use any tools and methods that help solve the problem
8. **Maintain Project Structure**: Pay attention to your repository management and keep the project structure organized
9. **Code Quality**: Pay attention to time and space complexity, code efficiency, and code readability

## Available API Tokens
- GITHUB_TOKEN: Configured
- ACMOJ_TOKEN: Configured

## Important Reminders
- You may compile and test locally (using available g++/gcc, python, etc.)
- **If a submission is stuck in pending status, abort it (doesn't count as an attempt) and resubmit**
- Keep trying until you achieve a satisfactory score or reach the submission limit
- You have complete control over the current working directory and may freely modify and create files

Now begin your work! Remember: you have full control, including Git operations, OJ submissions, error handling, file modifications, and all other aspects. Plan your ${MAX_SUBMISSIONS} submission opportunities wisely and pursue the highest score!"


# Multiple Problems Prompt
PROMPT2="You are a professional programming expert and Git expert. You are now in a Git repository and need to complete the following tasks:

## Current Environment
- Repository URL: ${REPO_URL}
- Working Directory: $(pwd)
- OJBench Problem ID: ${PROBLEM_ID}
- ACMOJ Problem IDs: ${ACMOJ_PROBLEM_ID}
- Maximum Submission Limit: ${MAX_SUBMISSIONS} attempts (SHARED across all problems)

## Important Scoring Rules (Must Read!)

### Submission Limit
- This problem allows a maximum of ${MAX_SUBMISSIONS} submissions in total
- This limit is **SHARED** across all problem IDs: ${ACMOJ_PROBLEM_ID}
- Submissions exceeding ${MAX_SUBMISSIONS} attempts will not be counted and will incur score penalties
- Please use your submission attempts wisely across all problems!

### OnlineJudge Scoring Calculation Method
1. Final score for each problem is based on the **highest score among all valid submissions**
2. Each problem has many test points
   - Score for each submission = sum of scores from all passed test points (unless otherwise specified)
   - Each test point may have different score weights (specific weights will not be disclosed)

## Important Notes
- You may freely modify all files in the current working directory (including README.md, etc.)
- You may create new files, add test cases, delete files, compile files, etc.
- No need to ask for my permission. Please complete the task until you achieve a satisfactory score or exhaust your submission attempts, then end the task

## Your Tasks
1. **Analyze the Problem**: Carefully read README.md and other files in the current directory, thoroughly analyze the project, and understand the requirements
2. **Develop Solution**: Implement the optimal solution
3. **Git Management**: Use git to manage your code versions
   - **After git push, verify the push was successful using command line**
   - If push failed, check error messages and retry
   - Every code modification must be committed to Git, maintaining a clear version history
4. **Submit to OJ and Check Results**: Carefully review the contents of the submit_acmoj directory
   - Use the submit_acmoj/acmoj_client.py script to submit tasks or query submission status
   - **When submitting, specify which problem ID to submit to** (choose from: ${ACMOJ_PROBLEM_ID})
   - **During OJ submission and result checking, DO NOT modify or push to the remote repository**
   - Wait for OJ results before making any new commits or pushes
   - **Please remember the submission_id for each submission (needed for querying submission status)**
   - **Track your remaining attempts**: Each submission reduces your remaining quota across all problems
   - **Abort Mechanism**: The submit_acmoj/acmoj_client.py script provides an abort command. If a submission is pending for too long (e.g., more than 2-3 minutes), you can abort it
   - **Important: Aborted submissions DO NOT count toward your ${MAX_SUBMISSIONS} submission limit**
   - After aborting, you can resubmit the same or modified code
5. **Iterative Optimization**:
   - If OJ returns errors (such as Wrong Answer, Time Limit Exceeded, Runtime Error, Compile Error, etc.), analyze the problem and modify code accordingly, then resubmit, keeping in mind not to exceed ${MAX_SUBMISSIONS} attempts
6. **Record Process**: Every modification must be recorded with git commit, clearly stating the reason for changes
7. **Free Exploration**: You may use any tools and methods that help solve the problem
8. **Maintain Project Structure**: Pay attention to your repository management and keep the project structure organized
9. **Code Quality**: Pay attention to time and space complexity, code efficiency, and code readability

## Available API Tokens
- GITHUB_TOKEN: Configured
- ACMOJ_TOKEN: Configured

## Important Reminders
- You may compile and test locally (using available g++/gcc, python, etc.)
- **If a submission is stuck in pending status, abort it (doesn't count as an attempt) and resubmit**
- **Remember: ${MAX_SUBMISSIONS} attempts are SHARED across all problem IDs: ${ACMOJ_PROBLEM_ID}**
- Keep trying until you achieve a satisfactory score or reach the submission limit
- You have complete control over the current working directory and may freely modify and create files

Now begin your work! Remember: you have full control, including Git operations, OJ submissions, error handling, file modifications, and all other aspects. Plan your ${MAX_SUBMISSIONS} submission opportunities wisely across all problem IDs (${ACMOJ_PROBLEM_ID}) and pursue the highest overall score!"


# 根据检测结果选择使用哪个Prompt
if [ "$USE_MULTI_PROMPT" = true ]; then
    SELECTED_PROMPT="$PROMPT2"
else
    SELECTED_PROMPT="$PROMPT"
fi

# 打印选中的prompt
echo "========================================="
echo "Agent Prompt:"
echo "$SELECTED_PROMPT"
echo "========================================="

# --- 调用AI Agent并给予完全控制权 ---
echo "🚀 Starting AI Agent with full control..."
echo "Agent has complete autonomy over the repository and OJ submission process"
echo "Max submissions allowed: ${MAX_SUBMISSIONS}"
echo "Using model: ${MODEL_NAME}"
echo "========================================="

# 给Agent足够的时间来完成整个任务
# 不设置超时限制，让Agent自己决定什么时候完成
#   --model <model>                     Set the AI model to use (choices: "claude-sonnet-4.5", "claude-sonnet-4",
#                                       "gpt-5")
copilot -p "${SELECTED_PROMPT}" --model "${MODEL_NAME}" --yolo --no-ask-user -s

echo "========================================="
echo "🎯 Agent session completed"
echo "Repository: ${REPO_URL}"
echo "Check the repository for complete task history and results"

echo "========================================="