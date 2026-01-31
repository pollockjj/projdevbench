# ProjDevBench

[English](README.md) | 中文 | [项目主页](https://zsworld6.github.io/projdevbench/)

**ProjDevBench**（Project Development Benchmark）是一个用于评估 AI 编程智能体在端到端项目开发任务上表现的基准测试平台。与现有专注于 issue 级别 bug 修复的基准不同，ProjDevBench 评估智能体从高层规范构建完整、可执行软件仓库的能力。

<p align="center">
  <img src="assets/tasks.png" alt="任务对比" width="600">
</p>

<p align="center">
  <em>任务对比：ProjDevBench 评估从项目级需求进行端到端仓库构建的能力，而非修改已有代码库。</em>
</p>

## 核心特性

- **端到端项目构建**：智能体从零开始构建完整仓库，而非仅生成补丁或单个文件
- **多智能体支持**：评估 Claude Code、Cursor、Gemini CLI、Codex、Augment 和 GitHub Copilot
- **双重评估协议**：结合在线评测系统（OJ）执行测试与 LLM 辅助代码审查
- **诊断反馈**：细粒度的判定级信号（Wrong Answer、TLE、MLE、Runtime Error 等）
- **容器化执行**：基于 Docker 的隔离环境，确保结果可复现
- **Git 集成**：每次评估都会创建一个 GitHub 仓库，记录智能体完整的解题过程

<p align="center">
  <img src="assets/benchmark_pipeline.png" alt="基准测试流程" width="800">
</p>

<p align="center">
  <em>ProjDevBench 评估流程概览。</em>
</p>

## 基准统计

| 指标 | 数值 |
|------|------|
| 问题总数 | 20 |
| 类别数 | 8 |
| 平均交互轮数 | 138 |
| 每问题平均 Token 数 | 4.81M |
| 整体通过率 | 27.38% |

## 问题类别

<p align="center">
  <img src="assets/category_pie_chart.png" alt="类别分布" width="400">
</p>

| 类别 | 数量 | 主要挑战 |
|------|------|----------|
| 数据结构 | 7 | 模板编程、迭代器、内存管理 |
| 管理系统 | 3 | 业务逻辑、复杂查询、文件 I/O |
| 解释器 | 3 | 解析、闭包、求值 |
| 存储系统 | 2 | B+ 树、磁盘操作 |
| 算法 | 2 | 精度、编解码 |
| 汇编 | 1 | 底层计算 |
| 游戏/模拟 | 1 | 状态机 |
| 优化 | 2 | 内存管理、GPU 模拟 |

## 问题详情

| ID | 问题名称 | 类别 | 难度 | 时间限制 | 内存限制 | 平均得分 |
|----|----------|------|------|----------|----------|----------|
| 001 | A+B Problem | 算法 | 简单 | 1s | 256 MiB | 54.37 |
| 002 | int2048 大整数 | 算法 | 简单 | 10s | 190 MiB | 48.19 |
| 003 | ICPC 管理系统 | 管理系统 | 困难 | 2s | 512 MiB | 52.07 |
| 004 | 书店系统 | 管理系统 | 困难 | 10s | 64 MiB | 36.29 |
| 005 | QOI 格式编解码器 | 算法 | 简单 | 10s | 512 MiB | 58.87 |
| 006 | 扫雷 | 游戏 | 简单 | 30s | 256 MiB | 53.51 |
| 007 | BASIC 解释器 | 解释器 | 简单 | 5s | 256 MiB | 47.67 |
| 008 | MOV 语言 | 汇编 | 简单 | - | - | 54.70 |
| 009 | STLite Vector | 数据结构 | 简单 | 100s | 768 MiB | 58.46 |
| 010 | STLite List | 数据结构 | 简单 | 25s | 768 MiB | 30.76 |
| 011 | STLite Priority Queue | 数据结构 | 简单 | 15s | 512 MiB | 57.25 |
| 012 | STLite Linked HashMap | 数据结构 | 简单 | 24s | 893 MiB | 43.36 |
| 013 | STLite Map | 数据结构 | 简单 | 30s | 893 MiB | 58.21 |
| 014 | Python 解释器 | 解释器 | 简单 | 16s | 512 MiB | 46.23 |
| 015 | 文件存储 | 存储 | 困难 | 16s | 6 MiB | 42.71 |
| 016 | 文件存储 BPT | 存储 | 困难 | 5s | 64 MiB | 40.11 |
| 017 | 火车票系统 | 管理系统 | 困难 | 40s | 47 MiB | 53.24 |
| 018 | Scheme 解释器 | 解释器 | 简单 | 1.5s | 244 MiB | 32.94 |
| 019 | GPU 内存优化 | 优化 | 简单 | 1s | 244 MiB | 36.89 |
| 020 | Buddy 算法 | 优化 | 简单 | 10s | 244 MiB | 33.33 |

> **难度定义**：
> - **简单 (Easy)**：项目补全设置，提供部分代码库
> - **困难 (Hard)**：项目创建设置，需要从零开始构建

## 项目结构

```
projdevbench/
├── config/                    # 配置文件
│   ├── environment.env        # 环境变量模板
│   ├── problem_registry.json  # 问题定义
│   └── agent_model_config.json
├── docker/                    # Docker 配置
│   ├── base/                  # 包含 CLI 工具的基础镜像
│   └── agent-runner/          # 运行时镜像
├── scripts/                   # 执行脚本
│   ├── container/             # 容器内智能体脚本
│   ├── analyze/               # 结果分析工具
│   ├── cr/                    # 代码审查脚本
│   └── run_evaluation.sh      # 主评估脚本
├── problem/                   # 问题定义
│   └── [problem_id]/          # 各问题文件夹
│       ├── README.md          # 问题描述
│       └── submit_acmoj/      # OJ 提交客户端
└── data/                      # 测试数据
```

## 快速开始

### 前置要求

- Docker Desktop 或 Docker Engine
- Git
- jq（JSON 解析器）
- Python 3.8+
- 拥有 Personal Access Token 的 GitHub 账号（建议新建专门用于实验的账号）
- [ACMOJ](https://acm.sjtu.edu.cn/OnlineJudge) 账号及 API Token（注册时学工号填写 `123456123456`）

### GitHub Token 权限要求

评估系统需要代表智能体创建仓库并推送代码。你的 GitHub Fine-grained Personal Access Token **必须**具有以下权限：

创建地址：https://github.com/settings/personal-access-tokens/new

**必需的权限：**

| 权限 | 访问级别 | 用途 |
|------|----------|------|
| **Administration** | Read and write | 创建新仓库 |
| **Contents** | Read and write | 向仓库推送代码 |

> **注意：** 如果遇到 `Resource not accessible by personal access token (createRepository)` 或推送时 `Permission denied` 的错误，说明你的 Token 权限不足。请检查并更新你的 Token。

### 日志目录权限

评估在 Docker 容器内以不同用户（`agent`）运行。日志目录从宿主机挂载，因此需要先创建目录并确保正确的写入权限：

```bash
# 创建并设置日志目录权限（在项目根目录运行）
mkdir -p logs
chmod -R 777 logs/
```

或者脚本会在评估期间自动对日志目录执行 `chmod 777`。如果遇到写入日志时 `Permission denied` 的错误，请手动运行上述命令。

### 安装

1. **克隆仓库**
```bash
git clone https://github.com/your-username/projdevbench.git
cd projdevbench
```

2. **配置环境变量**
```bash
vim config/environment.env
```

必需的变量：
```bash
# GitHub（建议新建专门用于实验的账号）
# 在此创建 Token: https://github.com/settings/tokens
GITHUB_USER="你的用户名"
GITHUB_TOKEN="你的_github_token"

# ACMOJ (https://acm.sjtu.edu.cn/OnlineJudge)
# 在此创建 API Token: https://acm.sjtu.edu.cn/OnlineJudge/settings/api
# 注册时学工号填写: 123456123456
ACMOJ_TOKEN="你的_acmoj_token"

# 智能体相关（按需配置）
GEMINI_API_KEY="你的_gemini_key"
CURSOR_API_KEY="你的_cursor_key"
ANTHROPIC_AUTH_TOKEN="你的_anthropic_token"
OPENAI_API_KEY="你的_openai_key"
AUGMENT_SESSION_AUTH="你的_augment_auth"
```

可选变量（自定义 API 端点）：
```bash
# 自定义 Base URL（适用于代理或自托管服务）
OPENAI_BASE_URL="https://api.openai.com/v1"          # OpenAI API 地址
ANTHROPIC_BASE_URL="https://api.anthropic.com"       # Anthropic API 地址
GOOGLE_GEMINI_BASE_URL=""                            # Gemini API 地址

# Codex CLI（默认：OpenAI 官方 https://api.openai.com/v1）
# 使用 OpenRouter：CODEX_BASE_URL="https://openrouter.ai/api/v1"
CODEX_API_KEY="your_codex_api_key"                   # Codex API 密钥
CODEX_BASE_URL=""                                    # 默认：OpenAI 官方

# 代理配置（如需要）
# https_proxy="http://host.docker.internal:7890"
# http_proxy="http://host.docker.internal:7890"
```

3. **构建 Docker 镜像**
```bash
# 构建基础镜像
cd docker/base && docker build -t projdevbench-base:latest .

# 构建运行镜像（从项目根目录）
cd ../..
docker build -t projdevbench-runner:latest -f docker/agent-runner/Dockerfile .
```

## 支持的智能体

| 智能体 | 描述 | 所需配置 |
|--------|------|----------|
| **gemini-cli** | Google Gemini CLI | `GEMINI_API_KEY` |
| **cursor** | Cursor AI 编辑器 | `CURSOR_API_KEY` |
| **claude-code** | Anthropic Claude Code | `ANTHROPIC_AUTH_TOKEN` |
| **codex** | OpenAI Codex CLI | `OPENAI_API_KEY` |
| **augment** | Augment Code | `AUGMENT_SESSION_AUTH` |
| **copilot** | GitHub Copilot CLI | GitHub OAuth |

> **Copilot 说明：** 如需运行 Copilot 智能体，你的 `GITHUB_TOKEN` 必须具有 Copilot 权限。请确保你的 GitHub 账号已订阅 Copilot，且 Token 已授权访问 Copilot。

## 使用方法

### 运行评估

```bash
# 交互模式 - 交互式选择智能体、模型和问题
./scripts/run_all_problem.sh

# 使用环境变量
AGENT=cursor MODEL=gemini-3-pro ./scripts/run_all_problem.sh

# 指定要运行的问题
PROBLEMS="001,002,003" AGENT=claude-code MODEL=sonnet-4.5 ./scripts/run_all_problem.sh
```

### 并行执行

使用 `CONCURRENCY` 环境变量同时运行多个评估：

```bash
# 4 个问题并行运行
AGENT=cursor MODEL=auto CONCURRENCY=4 ./scripts/run_all_problem.sh

# 并行运行指定问题，跳过已有日志
PROBLEMS="001,002,003,004,005" AGENT=codex MODEL=gpt-5 CONCURRENCY=4 SKIP_EXISTING=true ./scripts/run_all_problem.sh

# 强制重跑所有问题（并行）
AGENT=cursor MODEL=auto CONCURRENCY=4 FORCE=true ./scripts/run_all_problem.sh
```

**环境变量说明：**

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `AGENT` | 智能体类型 (cursor, claude-code, codex 等) | - |
| `MODEL` | 模型名称 (auto, gpt-5, sonnet-4.5 等) | - |
| `PROBLEMS` | 逗号分隔的问题 ID (如 "001,002,003") | 所有问题 |
| `CONCURRENCY` | 并行任务数 | 1 (顺序执行) |
| `SKIP_EXISTING` | 跳过已有日志的问题 | false |
| `FORCE` | 强制重跑已有日志的问题 | false |

## 评估协议

### 执行评估
- 提交在在线评测系统上进行评估
- 测试用例验证功能正确性、边界情况处理和资源限制
- 细粒度诊断反馈：编译错误、运行时错误、答案错误、超时、超内存、内存泄漏

### 代码审查
- 基于规则的 Python 脚本检测显式约束违规
- 基于 LLM 的规范符合性审查
- 检测禁用库使用、hack 解决方案和规则违规

### 最终评分
```
最终得分 = 0.8 × 执行得分 + 0.2 × 代码审查得分
```

## 主要发现

基于对 6 个编程智能体在多个 LLM 后端上的评估：

| 提交状态 | 百分比 |
|----------|--------|
| 通过 (Accepted) | 27.38% |
| 答案错误 (Wrong Answer) | 41.86% |
| 超时 (Time Limit Exceeded) | 13.91% |
| 运行时错误 (Runtime Error) | 7.01% |
| 编译错误 (Compile Error) | 4.52% |
| 内存泄漏 (Memory Leak) | 3.51% |
| 超内存 (Memory Limit Exceeded) | 1.36% |

**表现最佳的配置**：
- Codex + GPT-5：77.85% 最终得分
- Cursor + Gemini-3-Pro-Preview：75.32% 最终得分
- Augment + GPT-5：72.35% 最终得分

## 结果分析

### 执行得分分析

运行以下脚本分析 OJ 执行结果并计算得分：

```bash
# 从项目根目录运行
python3 scripts/analyze/analyze_exec_score.py
```

该脚本会：
1. 扫描 `logs/` 目录，提取所有提交记录
2. 调用 ACMOJ API 获取每个提交的详细信息（状态、得分等）
3. 根据 `problem_registry.json` 中的 `max_submissions` 过滤超限提交
4. 使用加权公式计算最终得分：`final_score = Σ(得分/满分 × 权重) / 总权重 × 100`
5. 将结果保存到 `results/` 目录

**输出文件：**
```
results/
├── exec_results.json          # 原始提交数据
├── exec_results.csv           # 原始提交数据 (CSV)
├── exec_score_analysis.json   # 得分分析（加权计算）
├── exec_score_analysis.csv    # 得分矩阵
└── exec_score_summary.txt     # 可读的文本摘要
```

**注意事项：**
- 需要在 `config/environment.env` 中配置 `ACMOJ_TOKEN`
- `abort` 状态的提交不计入提交次数
- 超过 `max_submissions` 限制的提交会被排除

### Code Review 得分分析

运行以下脚本分析 Code Review 结果：

```bash
# 从项目根目录运行
python3 scripts/analyze/analyze_cr_score.py

# 指定 CR 结果目录
python3 scripts/analyze/analyze_cr_score.py --cr-result-root /path/to/cr_result
```

该脚本会：
1. 扫描 `cr_result/` 目录，读取所有 `all_result.json` 文件
2. 汇总每个 agent+model 组合的 CR 得分
3. 计算统计数据（平均分、最高分、最低分等）
4. 将结果保存到 `results/` 目录

**输出文件：**
```
results/
├── cr_score_analysis.json    # CR 得分分析
├── cr_score_analysis.csv     # CR 得分矩阵
├── cr_score_detail.csv       # CR 详细数据（含 commit 数等）
└── cr_score_summary.txt      # 可读的文本摘要
```

### 综合得分分析

运行以下脚本计算综合得分（执行 + CR）：

```bash
# 从项目根目录运行（默认 0.8×执行 + 0.2×CR）
python3 scripts/analyze/analyze_all_score.py

# 自定义权重
python3 scripts/analyze/analyze_all_score.py --exec-weight 0.7 --cr-weight 0.3
```

该脚本会：
1. 读取 `results/exec_score_analysis.json`（执行得分）
2. 读取 `results/cr_score_analysis.json`（CR 得分）
3. 计算综合得分：`all_score = 0.8 × exec_score + 0.2 × cr_score`
4. 将结果保存到 `results/` 目录

**输出文件：**
```
results/
├── all_score_analysis.json   # 综合得分分析
├── all_score_analysis.csv    # 综合得分矩阵
├── all_score_detail.csv      # 详细数据（exec、cr、all 三项得分）
└── all_score_summary.txt     # 可读的文本摘要
```

**注意事项：**
- 需要先运行 `analyze_exec_score.py` 和 `analyze_cr_score.py` 生成输入数据
- 如果某题只有执行得分或只有 CR 得分，会按实际存在的分数计算

## 添加新智能体

1. 在 `scripts/container/run_new_agent.sh` 中创建智能体脚本
2. 在 `docker/base/Dockerfile` 中安装 CLI 工具
3. 在 `scripts/run_evaluation.sh` 中添加 case 分支
4. 更新 `config/agent_model_config.json`

## 日志

日志保存在 `logs/[agent]/[model]/[problem_id]/`：
```
oj_eval_[agent]_[model]_[problem_id]_[timestamp].log
```

包含：
- 环境配置
- GitHub 仓库创建
- 智能体执行轨迹
- OJ 提交结果
- 提交 ID

## 许可证

MIT License

## 引用

如果你在研究中使用了 ProjDevBench，请引用：

```bibtex
@inproceedings{projdevbench2026,
  title={ProjDevBench: Benchmarking AI Coding Agents on End-to-End Project Development},
  author={Lu, Pengrui and Zhang, Shiqi and Hou, Yunzhong and Ye, Lyumanshan and Huang, Chaoyi and Chen, Zixi and Zeng, Ji and Jiang, Hantao and Liu, Pengfei and Wang, Yiwei and Yang, Ming-Hsuan},
  booktitle={International Conference on Machine Learning (ICML)},
  year={2026}
}
```

## 致谢

感谢 OJ 平台提供评估基础设施，以及本工作中评估的各编程智能体的开发者。
