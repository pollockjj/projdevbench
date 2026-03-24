FROM prlu/ojbench-base:latest

USER root

# 安装tmux、unzip和其他必要工具
RUN apt-get update && apt-get install -y \
    tmux \
    unzip \
    git-extras \
    tig \
    && rm -rf /var/lib/apt/lists/*

# 复制容器内所有的脚本
COPY scripts/container/ /scripts/
RUN chmod +x /scripts/*.sh


# 创建工作目录和问题目录
RUN mkdir -p /workspace /problems
RUN chown -R agent:agent /workspace /problems 

# Update CLIs to latest as root (system-wide)
RUN npm install -g @anthropic-ai/claude-code@latest
RUN npm install -g @openai/codex@latest

USER agent
WORKDIR /workspace
# 在切换到 agent 用户之后设置
ENV HOME=/home/agent
ENV PATH="${HOME}/.local/bin:${PATH}"
# Git配置
RUN git config --global init.defaultBranch main
RUN git config --global core.editor "nano"

ENTRYPOINT ["/scripts/run_agent_base.sh"]
