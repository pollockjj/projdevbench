#!/bin/bash
if [ $# -lt 3 ]; then
 echo "Usage: $0 <ojbench_problem_id> <acmoj_problem_id> <agent_type> [model] [debug]"
 echo "Example: $0 001 1752 gemini-cli"
 echo "Example: $0 004 1075,1775 gemini-cli  # Multiple problem IDs"
 echo "Example: $0 001 1752 cursor sonnet-4.5-thinking"
 echo "Example: $0 003 1986 cursor sonnet-4.5-thinking debug"
 echo "Example: $0 001 1752 gemini-cli '' debug # Interactive debug mode"
 exit 1
fi

PROBLEM_ID=$1
# 支持单个或多个Problem ID（逗号分隔）
ACMOJ_PROBLEM_ID=$2
AGENT_TYPE=$3
MODEL_NAME=$4  # Default model
DEBUG_MODE=$5

# 从配置文件读取最大提交次数
PROBLEM_REGISTRY="$(pwd)/config/problem_registry.json"
if [ ! -f "$PROBLEM_REGISTRY" ]; then
    echo "❌ Configuration file not found: ${PROBLEM_REGISTRY}"
    exit 1
fi

# 检查是否安装了 jq
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed."
    echo "Please install jq:"
    echo "  - On macOS: brew install jq"
    echo "  - On Linux: sudo apt-get install jq (Ubuntu/Debian) or sudo yum install jq (CentOS/RHEL)"
    exit 1
fi

# 从 JSON 配置文件读取最大提交次数
MAX_SUBMISSIONS=$(jq -r ".problems.\"$PROBLEM_ID\".max_submissions // .default.max_submissions" "$PROBLEM_REGISTRY")
if [ -z "$MAX_SUBMISSIONS" ] || [ "$MAX_SUBMISSIONS" = "null" ]; then
    MAX_SUBMISSIONS=3  # 默认值
    echo "⚠️ Using default max submissions: ${MAX_SUBMISSIONS}"
else
    echo "ℹ️ Max submissions for problem ${PROBLEM_ID}: ${MAX_SUBMISSIONS}"
fi

# 生成统一的TIMESTAMP
TIMESTAMP=$(date +%Y%m%d%H%M%S)
echo "⏰ Evaluation TIMESTAMP: ${TIMESTAMP}"

# 检查problem目录是否存在
PROBLEM_DIR="$(pwd)/problem/${PROBLEM_ID}"
if [ ! -d "$PROBLEM_DIR" ]; then
 echo "⚠️ Warning: Problem directory not found at ${PROBLEM_DIR}"
 echo "Creating empty problem directory..."
#  直接退出
 exit 1
fi

# 加载环境变量
if [ ! -f "config/environment.env" ]; then
    echo "❌ Configuration file not found: config/environment.env"
    exit 1
fi
source config/environment.env

# 验证必需的环境变量（只验证通用必需的）
if [ "$GITHUB_TOKEN" = "your_github_token_here" ] || [ "$ACMOJ_TOKEN" = "acmoj-your-token-here" ]; then
 echo "❌ Please configure required API keys in config/environment.env first!"
 echo "Required: GITHUB_TOKEN, ACMOJ_TOKEN"
 exit 1
fi

# 根据agent类型验证特定的API密钥
case "$AGENT_TYPE" in
  gemini-cli|Gemini)
    if [ "$GEMINI_API_KEY" = "your_gemini_api_key_here" ]; then
      echo "❌ GEMINI_API_KEY is required for Gemini agent!"
      exit 1
    fi
    ;;
  cursor)
    if [ "$CURSOR_API_KEY" = "your_cursor_api_key_here" ]; then
      echo "❌ CURSOR_API_KEY is required for Cursor agent!"
      exit 1
    fi
    ;;
  claude-code|"Claude Code")
    if  [ "$ANTHROPIC_API_KEY" = "your_ANTHROPIC_API_KEY_here" ]; then
      echo "❌ ANTHROPIC_API_KEY is required for Claude Code agent!"
      exit 1
    fi
    ;;
  augment|Augment)
    if [ "$AUGMENT_SESSION_AUTH" = "your_augment_session_auth_here" ]; then
      echo "❌ AUGMENT_SESSION_AUTH is required for Augment agent!"
      exit 1
    fi
    ;;
  codex|Codex)
    if [ "$OPENAI_API_KEY" = "your_openai_api_key_here" ]; then
      echo "❌ OPENAI_API_KEY is required for Codex agent!"
      exit 1
    fi
    ;;
esac

# 🔧 修改：设置日志目录为Mac本地路径,目录位置为$(pwd)/logs/agent-type/modelname/problemid
# 如果模型是Sonnet或者Claude Sonnet 4.5，则为sonnet-4.5，其余的就是modelname,但是得把空格替换为-，斜杠替换为-
if [[ "$MODEL_NAME" == "Sonnet" || "$MODEL_NAME" == "Claude Sonnet 4.5" ]]; then
  LOG_MODEL_NAME="sonnet-4.5"
else
  LOG_MODEL_NAME="${MODEL_NAME// /-}"
  LOG_MODEL_NAME="${LOG_MODEL_NAME//\//-}"
fi
LOG_DIR="$(pwd)/logs/${AGENT_TYPE}/${LOG_MODEL_NAME}/${PROBLEM_ID}"

# 一层层创建目录
mkdir -p "$(pwd)/logs"
mkdir -p "$(pwd)/logs/${AGENT_TYPE}"
mkdir -p "$(pwd)/logs/${AGENT_TYPE}/${LOG_MODEL_NAME}"
mkdir -p "${LOG_DIR}"

# 设置目录权限，确保容器内的 agent 用户可以写入
chmod 777 "${LOG_DIR}"

echo "📝 Logs will be saved to: ${LOG_DIR}"

# 构造容器名称
CONTAINER_NAME="eval-${AGENT_TYPE}-${PROBLEM_ID}-${TIMESTAMP}"

# 使用数组构建 Docker 环境变量
DOCKER_ENV_ARGS=(
    -e "PROBLEM_ID=${PROBLEM_ID}"
    -e "ACMOJ_PROBLEM_ID=${ACMOJ_PROBLEM_ID}"
    -e "AGENT_TYPE=${AGENT_TYPE}"
    -e "MODEL_NAME=${MODEL_NAME}"
    -e "TIMESTAMP=${TIMESTAMP}"
    -e "GITHUB_TOKEN=${GITHUB_TOKEN}"
    -e "GITHUB_USER=${GITHUB_USER}"
    -e "ACMOJ_TOKEN=${ACMOJ_TOKEN}"
    -e "MAX_SUBMISSIONS=${MAX_SUBMISSIONS}"
    -e "NODE_OPTIONS=--max-old-space-size=6144"  # 添加这一行：设置Node.js堆内存为6GB
)

# 使用数组构建 Docker 挂载和资源限制
DOCKER_MOUNT_ARGS=(
    --name "${CONTAINER_NAME}"
    --memory="${AGENT_MEMORY_LIMIT:-8g}"
    --cpus="${AGENT_CPU_LIMIT:-4}"
    -v "${PROBLEM_DIR}:/problems/${PROBLEM_ID}:ro"
    -v "${LOG_DIR}:/workspace/logs"
    -v "$(pwd)/data/${PROBLEM_ID}:/data_readonly/${PROBLEM_ID}:ro"
    -v "$(pwd)/scripts/container:/scripts:ro"
)

if [ "$DEBUG_MODE" = "debug" ]; then
 echo "🐛 Starting in DEBUG mode - Interactive container"
 echo "📁 Problem Directory: ${PROBLEM_DIR}"
 echo "🎯 Problem: ${PROBLEM_ID} (ACMOJ: ${ACMOJ_PROBLEM_ID})"
 echo "🤖 Agent: ${AGENT_TYPE}"
 echo "🤖 Model: ${MODEL_NAME}"
 echo "🐳 Container: ${CONTAINER_NAME}"
 echo ""
 echo "Container will start with bash shell. You can:"
 echo " - Run: /scripts/run_agent_1.sh && /scripts/run_agent_2.sh # 执行评测脚本"
 echo " - Check environment variables: env | grep -E '(PROBLEM|GITHUB_USER|MODEL|TIMESTAMP)' | grep -v -E '(TOKEN|KEY|AUTH|SECRET)'"
 echo " - Explore: ls -la /problems/${PROBLEM_ID}"
 echo " - Exit: exit"
 echo ""
 
 # 根据agent类型添加特定的环境变量（使用数组）
 AGENT_SPECIFIC_ENV=()
 case "$AGENT_TYPE" in
   cursor)
     AGENT_SPECIFIC_ENV=(-e "CURSOR_API_KEY=${CURSOR_API_KEY}")
     ;;
  gemini-cli|Gemini)
    AGENT_SPECIFIC_ENV=(
      -e "GEMINI_API_KEY=${GEMINI_API_KEY}"
      -e "GOOGLE_API_KEY=${GEMINI_API_KEY}"
      -e "GOOGLE_GEMINI_BASE_URL=${GOOGLE_GEMINI_BASE_URL}"
      -e "GEMINI_MODEL=${MODEL_NAME}"
    )
    ;;
   claude-code|"Claude Code")
     AGENT_SPECIFIC_ENV=(
       -e "ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}"
       -e "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}"
     )
     ;;
   augment|Augment)
     AGENT_SPECIFIC_ENV=(-e "AUGMENT_SESSION_AUTH=${AUGMENT_SESSION_AUTH}")
     ;;
    codex|Codex)
     AGENT_SPECIFIC_ENV=(
       -e "OPENAI_API_KEY=${OPENAI_API_KEY}"
       -e "OPENAI_BASE_URL=${OPENAI_BASE_URL}"
     )
      ;;
      copilot|Copilot)
     AGENT_SPECIFIC_ENV=()
      ;;
 esac
  
 # 交互式运行 - 使用 -it 标志     # 添加这一行：将容器的1455端口映射到本地1455端口
# 交互式运行 - 使用 -it 标志
  docker run --rm -it \
    "${DOCKER_MOUNT_ARGS[@]}" \
    "${DOCKER_ENV_ARGS[@]}" \
    "${AGENT_SPECIFIC_ENV[@]}" \
    --entrypoint /bin/bash \
    prlu/ojbench-agent-runner:latest
else
 echo "🚀 Starting Repository-based Evaluation"
 echo "📁 Problem Directory: ${PROBLEM_DIR}"
 echo "🎯 Problem: ${PROBLEM_ID} (ACMOJ: ${ACMOJ_PROBLEM_ID})"
 echo "🤖 Agent: ${AGENT_TYPE}"
 echo "🤖 Model: ${MODEL_NAME}"
 echo "⏰ Timestamp: ${TIMESTAMP}"
 echo "🐳 Starting Docker container: ${CONTAINER_NAME}"
 
 # 根据 AGENT_TYPE 选择执行命令
 case "$AGENT_TYPE" in
   cursor)
     echo "🖱️ Running Cursor Agent (Interactive Mode)..."
     docker run --rm \
       "${DOCKER_MOUNT_ARGS[@]}" \
       "${DOCKER_ENV_ARGS[@]}" \
       -e "CURSOR_API_KEY=${CURSOR_API_KEY}" \
       --entrypoint /bin/bash \
       prlu/ojbench-agent-runner:latest \
       -c "bash /scripts/run_cursor.sh"
     ;;
   
  gemini-cli|Gemini)
    echo "🔷 Running Gemini Agent..."
    docker run --rm \
      "${DOCKER_MOUNT_ARGS[@]}" \
      "${DOCKER_ENV_ARGS[@]}" \
      -e "GEMINI_API_KEY=${GEMINI_API_KEY}" \
       -e "GOOGLE_API_KEY=${GEMINI_API_KEY}" \
       -e "GOOGLE_GEMINI_BASE_URL=${GOOGLE_GEMINI_BASE_URL}" \
       -e "GEMINI_MODEL=${MODEL_NAME}" \
       -e "GEMINI_SANDBOX=false" \
       --entrypoint /bin/bash \
      prlu/ojbench-agent-runner:latest \
       -c "bash /scripts/run_gemini.sh"
    ;;
   
  claude-code|"Claude Code")
    echo "🤖 Running Claude Code Agent..."
    docker run --rm \
      "${DOCKER_MOUNT_ARGS[@]}" \
      "${DOCKER_ENV_ARGS[@]}" \
      -e "ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}" \
      -e "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" \
      --entrypoint /bin/bash \
      prlu/ojbench-agent-runner:latest \
      -c "bash /scripts/run_claude_code.sh"
    ;;

   codex|Codex)
     echo "🟣 Running Codex Agent..."
     docker run --rm \
       "${DOCKER_MOUNT_ARGS[@]}" \
       "${DOCKER_ENV_ARGS[@]}" \
       -e "OPENAI_API_KEY=${OPENAI_API_KEY}" \
       -e "OPENAI_BASE_URL=${OPENAI_BASE_URL}" \
       -e "CODEX_API_KEY=${CODEX_API_KEY}" \
       -e "CODEX_BASE_URL=${CODEX_BASE_URL}" \
       --entrypoint /bin/bash \
       prlu/ojbench-agent-runner:latest \
       -c "bash /scripts/run_codex.sh"
     ;;
   
   augment|Augment)
     echo "🟣 Running Augment Agent..."
     docker run --rm \
       "${DOCKER_MOUNT_ARGS[@]}" \
       "${DOCKER_ENV_ARGS[@]}" \
       -e "AUGMENT_SESSION_AUTH=${AUGMENT_SESSION_AUTH}" \
       --entrypoint /bin/bash \
       prlu/ojbench-agent-runner:latest \
       -c "bash /scripts/run_augment.sh"
     ;;

   copilot|Copilot)
      echo "🟣 Running Copilot Agent..."
      docker run --rm \
        --user root \
        "${DOCKER_MOUNT_ARGS[@]}" \
        "${DOCKER_ENV_ARGS[@]}" \
        --entrypoint /bin/bash \
        prlu/ojbench-agent-runner:latest \
        -c "chmod 777 /workspace && su agent -c 'bash /scripts/run_copilot.sh'"
     ;;

   copilot-gitl|Copilot-GITL)
      echo "🟣 Running Copilot GITL Pipeline Agent..."
      SKILLS_DIR="$(pwd)/gitl-skills"
      if [ ! -d "$SKILLS_DIR" ]; then
        echo "❌ GITL skills not found at $SKILLS_DIR"
        echo "Copy skills from gitl-pipeclean: cp -r /path/to/gitl-pipeclean/.claude/skills gitl-skills"
        exit 1
      fi
      docker run --rm \
        --user root \
        "${DOCKER_MOUNT_ARGS[@]}" \
        "${DOCKER_ENV_ARGS[@]}" \
        -e "GITL_MODE=${GITL_MODE:-informed}" \
        -v "${SKILLS_DIR}:/workspace/skills:ro" \
        -v "/etc/gitl/github-apps:/etc/gitl/github-apps:ro" \
        --entrypoint /bin/bash \
        prlu/ojbench-agent-runner:latest \
        -c "chmod 777 /workspace && su agent -c 'bash /scripts/run_copilot_gitl.sh'"
     ;;

   *)
     echo "⚙️ Running default agent configuration..."
     # 默认执行逻辑
     docker run --rm \
       "${DOCKER_MOUNT_ARGS[@]}" \
       "${DOCKER_ENV_ARGS[@]}" \
       prlu/ojbench-agent-runner:latest
     ;;
 esac
fi

echo "✅ Container session completed!"
echo "📊 Check logs at: ${LOG_DIR}"








# copilot model (choices: "claude-sonnet-4.5", "claude-sonnet-4", "gpt-5")