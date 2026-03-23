FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# 安装 Node.js 20
RUN apt-get update && apt-get install -y curl \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y nodejs

# 安装编译工具链和Python
RUN apt-get update && apt-get install -y \
 gcc-13 g++-13 \
 cmake \
 python3.12 python3.12-dev python3-pip \
 iverilog \
 git curl jq build-essential \
 sudo \
 && ln -sf /usr/bin/gcc-13 /usr/bin/gcc \
 && ln -sf /usr/bin/g++-13 /usr/bin/g++ \
 && ln -sf /usr/bin/python3.12 /usr/bin/python3

# 安装 Python 依赖
RUN python3 -m pip install requests --break-system-packages

# 安装GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
 && apt-get update \
 && apt-get install gh -y

# 安装Gemini CLI
RUN npm install -g @google/gemini-cli

# 安装Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Install GitHub Copilot CLI
RUN npm install -g @github/copilot@1.0.10

# 安装Codex (指定最新版本)
RUN npm install -g @openai/codex@0.91.0

# 安装Augment
RUN npm install -g @augmentcode/auggie

# 验证安装
RUN echo "Verifying installations..." && \
 g++ --version && \
 cmake --version && \
 python3 --version && \
 iverilog -V && \
 gh --version && \
 gemini --version && \
 claude --version && \
 copilot --version

WORKDIR /workspace

# 创建非root用户
RUN useradd -m -s /bin/bash agent

# 配置 sudo，允许所有用户使用 apt 和 dpkg 命令（无需密码）
RUN echo "ALL ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get, /usr/bin/dpkg, /usr/bin/dpkg-deb" >> /etc/sudoers
USER agent
WORKDIR /home/agent

# 安装Cursor并配置PATH
RUN curl https://cursor.com/install -fsS | bash && \
 echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# 注意: source ~/.bashrc 在Dockerfile中不会生效，因为每个RUN命令都在新的shell中执行
# PATH环境变量会在容器启动时通过.bashrc自动加载