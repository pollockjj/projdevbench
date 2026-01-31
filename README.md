# ProjDevBench

[English](README.md) | [中文](README_zh.md) | [Homepage](https://zsworld6.github.io/projdevbench/)

**ProjDevBench** (Project Development Benchmark) is a benchmark platform for evaluating AI coding agents on end-to-end project development tasks. Unlike existing benchmarks that focus on issue-level bug fixing, ProjDevBench evaluates agents on their ability to construct complete, executable software repositories from high-level specifications.

<p align="center">
  <img src="assets/tasks.png" alt="Task Comparison" width="600">
</p>

<p align="center">
  <em>Task comparison: ProjDevBench evaluates end-to-end repository construction from project-level requirements, unlike benchmarks that modify pre-existing codebases.</em>
</p>

## Key Features

- **End-to-End Project Construction**: Agents build complete repositories from scratch, not just patches or single files
- **Multi-Agent Support**: Evaluate Claude Code, Cursor, Gemini CLI, Codex, Augment, and GitHub Copilot
- **Dual Evaluation Protocol**: Combines Online Judge (OJ) execution-based testing with LLM-assisted code review
- **Diagnostic Feedback**: Fine-grained verdict-level signals (Wrong Answer, TLE, MLE, Runtime Error, etc.)
- **Containerized Execution**: Docker-based isolated environments ensure reproducible results
- **Git Integration**: Each evaluation creates a GitHub repository tracking the agent's complete problem-solving process

<p align="center">
  <img src="assets/benchmark_pipeline.png" alt="Benchmark Pipeline" width="800">
</p>

<p align="center">
  <em>Overview of the ProjDevBench evaluation pipeline.</em>
</p>

## Benchmark Statistics

| Metric | Value |
|--------|-------|
| Total Problems | 20 |
| Categories | 8 |
| Avg. Interaction Turns | 138 |
| Avg. Tokens per Problem | 4.81M |
| Overall Acceptance Rate | 27.38% |

## Problem Categories

<p align="center">
  <img src="assets/category_pie_chart.png" alt="Category Distribution" width="400">
</p>

| Category | Count | Key Challenges |
|----------|-------|----------------|
| Data Structures | 7 | Template programming, iterators, memory management |
| Management Systems | 3 | Business logic, complex queries, file I/O |
| Interpreters | 3 | Parsing, closures, evaluation |
| Storage Systems | 2 | B+ tree, disk-based operations |
| Algorithm | 2 | Precision, codecs |
| Assembly | 1 | Low-level computation |
| Game/Simulation | 1 | State machines |
| Optimization | 2 | Memory management, GPU simulation |

## Problem Details

| ID | Problem Name | Category | Difficulty | Time Limit | Memory Limit | Avg Score |
|----|--------------|----------|------------|------------|--------------|-----------|
| 001 | A+B Problem | Algorithm | Easy | 1s | 256 MiB | 54.37 |
| 002 | int2048 Big Integer | Algorithm | Easy | 10s | 190 MiB | 48.19 |
| 003 | ICPC Management System | Management | Hard | 2s | 512 MiB | 52.07 |
| 004 | Bookstore System | Management | Hard | 10s | 64 MiB | 36.29 |
| 005 | QOI Format Codec | Algorithm | Easy | 10s | 512 MiB | 58.87 |
| 006 | Minesweeper | Game | Easy | 30s | 256 MiB | 53.51 |
| 007 | BASIC Interpreter | Interpreter | Easy | 5s | 256 MiB | 47.67 |
| 008 | MOV Language | Assembly | Easy | - | - | 54.70 |
| 009 | STLite Vector | Data Structure | Easy | 100s | 768 MiB | 58.46 |
| 010 | STLite List | Data Structure | Easy | 25s | 768 MiB | 30.76 |
| 011 | STLite Priority Queue | Data Structure | Easy | 15s | 512 MiB | 57.25 |
| 012 | STLite Linked HashMap | Data Structure | Easy | 24s | 893 MiB | 43.36 |
| 013 | STLite Map | Data Structure | Easy | 30s | 893 MiB | 58.21 |
| 014 | Python Interpreter | Interpreter | Easy | 16s | 512 MiB | 46.23 |
| 015 | File Storage | Storage | Hard | 16s | 6 MiB | 42.71 |
| 016 | File Storage BPT | Storage | Hard | 5s | 64 MiB | 40.11 |
| 017 | Train Ticket System | Management | Hard | 40s | 47 MiB | 53.24 |
| 018 | Scheme Interpreter | Interpreter | Easy | 1.5s | 244 MiB | 32.94 |
| 019 | GPU Memory Optimization | Optimization | Easy | 1s | 244 MiB | 36.89 |
| 020 | Buddy Algorithm | Optimization | Easy | 10s | 244 MiB | 33.33 |

> **Difficulty Definition**: 
> - **Easy (E)**: Project-completion setting with partial codebase provided
> - **Hard (H)**: Project-creation setting requiring from-scratch construction

## Project Structure

```
projdevbench/
├── config/                    # Configuration files
│   ├── environment.env        # Environment variable template
│   ├── problem_registry.json  # Problem definitions
│   └── agent_model_config.json
├── docker/                    # Docker configurations
│   ├── base/                  # Base image with CLI tools
│   └── agent-runner/          # Runtime image
├── scripts/                   # Execution scripts
│   ├── container/             # In-container agent scripts
│   ├── analyze/               # Result analysis tools
│   ├── cr/                    # Code review scripts
│   └── run_evaluation.sh      # Main evaluation script
├── problem/                   # Problem definitions
│   └── [problem_id]/          # Each problem folder
│       ├── README.md          # Problem description
│       └── submit_acmoj/      # OJ submission client
└── data/                      # Test data
```

## Quick Start

### Prerequisites

- Docker Desktop or Docker Engine
- Git
- jq (JSON parser)
- Python 3.8+
- GitHub account with Personal Access Token (recommend creating a dedicated account for experiments)
- [ACMOJ](https://acm.sjtu.edu.cn/OnlineJudge) account with API Token (register with student ID `123456123456`)

### GitHub Token Requirements

The evaluation system needs to create repositories and push code on behalf of the agent. Your GitHub Fine-grained Personal Access Token **must** have the following permissions:

Create at: https://github.com/settings/personal-access-tokens/new

**Required permissions:**

| Permission | Access Level | Purpose |
|------------|--------------|---------|
| **Administration** | Read and write | Create new repositories |
| **Contents** | Read and write | Push code to repositories |

> **Note:** If you encounter errors like `Resource not accessible by personal access token (createRepository)` or `Permission denied` when pushing, your token lacks the required permissions. Please verify and update your token.

### Logs Directory Permissions

The evaluation runs inside a Docker container with a different user (`agent`). The logs directory is mounted from the host, so you need to create it and ensure proper write permissions:

```bash
# Create and set permissions for the logs directory (run from project root)
mkdir -p logs
chmod -R 777 logs/
```

Or the script will automatically set `chmod 777` on the log directory during evaluation. If you encounter `Permission denied` errors when writing logs, manually run the above commands.

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/your-username/projdevbench.git
cd projdevbench
```

2. **Configure environment variables**
```bash
vim config/environment.env
```

Required variables:
```bash
# GitHub (recommend creating a dedicated account for experiments)
# Create token at: https://github.com/settings/tokens
GITHUB_USER="your_username"
GITHUB_TOKEN="your_github_token"

# ACMOJ (https://acm.sjtu.edu.cn/OnlineJudge)
# Create API token at: https://acm.sjtu.edu.cn/OnlineJudge/settings/api
# For registration, use student ID: 123456123456
ACMOJ_TOKEN="your_acmoj_token"

# Agent-specific (configure as needed)
GEMINI_API_KEY="your_gemini_key"
CURSOR_API_KEY="your_cursor_key"
ANTHROPIC_AUTH_TOKEN="your_anthropic_token"
OPENAI_API_KEY="your_openai_key"
AUGMENT_SESSION_AUTH="your_augment_auth"
```

Optional variables (for custom API endpoints):
```bash
# Custom Base URLs (useful for proxies or self-hosted services)
OPENAI_BASE_URL="https://api.openai.com/v1"          # OpenAI API base URL
ANTHROPIC_BASE_URL="https://api.anthropic.com"       # Anthropic API base URL
GOOGLE_GEMINI_BASE_URL=""                            # Gemini API base URL

# Codex CLI (default: OpenAI official https://api.openai.com/v1)
# For OpenRouter: CODEX_BASE_URL="https://openrouter.ai/api/v1"
CODEX_API_KEY="your_codex_api_key"                   # Codex API key
CODEX_BASE_URL=""                                    # Default: OpenAI official

# Proxy Configuration (if needed)
# https_proxy="http://host.docker.internal:7890"
# http_proxy="http://host.docker.internal:7890"
```

3. **Build Docker images**
```bash
# Build base image
cd docker/base && docker build -t projdevbench-base:latest .

# Build runner image (from project root)
cd ../..
docker build -t projdevbench-runner:latest -f docker/agent-runner/Dockerfile .
```

## Supported Agents

| Agent | Description | Required Config |
|-------|-------------|-----------------|
| **gemini-cli** | Google Gemini CLI | `GEMINI_API_KEY` |
| **cursor** | Cursor AI Editor | `CURSOR_API_KEY` |
| **claude-code** | Anthropic Claude Code | `ANTHROPIC_AUTH_TOKEN` |
| **codex** | OpenAI Codex CLI | `OPENAI_API_KEY` |
| **augment** | Augment Code | `AUGMENT_SESSION_AUTH` |
| **copilot** | GitHub Copilot CLI | GitHub OAuth |

> **Copilot Note:** To run the Copilot agent, your `GITHUB_TOKEN` must have Copilot permissions enabled. Ensure your GitHub account has an active Copilot subscription and the token is authorized to access Copilot.

## Usage

### Run Evaluation

```bash
# Interactive mode - select agent, model, and problems interactively
./scripts/run_all_problem.sh

# With environment variables
AGENT=cursor MODEL=gemini-3-pro ./scripts/run_all_problem.sh

# Specify problems to run
PROBLEMS="001,002,003" AGENT=claude-code MODEL=sonnet-4.5 ./scripts/run_all_problem.sh
```

### Parallel Execution

Run multiple evaluations concurrently using the `CONCURRENCY` environment variable:

```bash
# Run 4 problems in parallel
AGENT=cursor MODEL=auto CONCURRENCY=4 ./scripts/run_all_problem.sh

# Run specific problems in parallel, skip existing logs
PROBLEMS="001,002,003,004,005" AGENT=codex MODEL=gpt-5 CONCURRENCY=4 SKIP_EXISTING=true ./scripts/run_all_problem.sh

# Force re-run all problems in parallel
AGENT=cursor MODEL=auto CONCURRENCY=4 FORCE=true ./scripts/run_all_problem.sh
```

**Environment Variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| `AGENT` | Agent type (cursor, claude-code, codex, etc.) | - |
| `MODEL` | Model name (auto, gpt-5, sonnet-4.5, etc.) | - |
| `PROBLEMS` | Comma-separated problem IDs (e.g., "001,002,003") | All problems |
| `CONCURRENCY` | Number of parallel jobs | 1 (sequential) |
| `SKIP_EXISTING` | Skip problems with existing logs | false |
| `FORCE` | Force re-run problems with existing logs | false |

## Evaluation Protocol

### Execution-based Evaluation
- Submissions are evaluated on an Online Judge platform
- Test cases verify functional correctness, edge-case handling, and resource limits
- Fine-grained diagnostic feedback: Compile Error, Runtime Error, Wrong Answer, TLE, MLE, Memory Leak

### Code Review
- Rule-based Python scripts for explicit constraint violations
- LLM-based review for specification compliance
- Detects forbidden library usage, hack solutions, and rule violations

### Final Scoring
```
Final Score = 0.8 × Execution Score + 0.2 × Code Review Score
```

## Key Findings

From our evaluation of 6 coding agents across multiple LLM backends:

| Submission Status | Percentage |
|-------------------|------------|
| Accepted | 27.38% |
| Wrong Answer | 41.86% |
| Time Limit Exceeded | 13.91% |
| Runtime Error | 7.01% |
| Compile Error | 4.52% |
| Memory Leak | 3.51% |
| Memory Limit Exceeded | 1.36% |

**Top Performing Configurations**:
- Codex + GPT-5: 77.85% final score
- Cursor + Gemini-3-Pro-Preview: 75.32% final score
- Augment + GPT-5: 72.35% final score

## Result Analysis

### Execution Score Analysis

Run the following script to analyze OJ execution results and calculate scores:

```bash
# Run from project root
python3 scripts/analyze/analyze_exec_score.py
```

This script will:
1. Scan the `logs/` directory and extract all submission records
2. Call ACMOJ API to get detailed information for each submission (status, score, etc.)
3. Filter out submissions exceeding `max_submissions` limit defined in `problem_registry.json`
4. Calculate final score using weighted formula: `final_score = Σ(score/full_score × weight) / total_weight × 100`
5. Save results to the `results/` directory

**Output Files:**
```
results/
├── exec_results.json          # Raw submission data
├── exec_results.csv           # Raw submission data (CSV)
├── exec_score_analysis.json   # Score analysis (weighted calculation)
├── exec_score_analysis.csv    # Score matrix
└── exec_score_summary.txt     # Human-readable summary
```

**Notes:**
- Requires `ACMOJ_TOKEN` configured in `config/environment.env`
- Submissions with `abort` status are not counted towards submission limit
- Submissions exceeding `max_submissions` limit are excluded from scoring

### Code Review Score Analysis

Run the following script to analyze Code Review results:

```bash
# Run from project root
python3 scripts/analyze/analyze_cr_score.py

# Specify CR result directory
python3 scripts/analyze/analyze_cr_score.py --cr-result-root /path/to/cr_result
```

This script will:
1. Scan the `cr_result/` directory and read all `all_result.json` files
2. Aggregate CR scores for each agent+model combination
3. Calculate statistics (average, min, max scores, etc.)
4. Save results to the `results/` directory

**Output Files:**
```
results/
├── cr_score_analysis.json    # CR score analysis
├── cr_score_analysis.csv     # CR score matrix
├── cr_score_detail.csv       # CR detailed data (with commit count, etc.)
└── cr_score_summary.txt      # Human-readable summary
```

### Combined Score Analysis

Run the following script to calculate combined scores (Execution + CR):

```bash
# Run from project root (default: 0.8×Exec + 0.2×CR)
python3 scripts/analyze/analyze_all_score.py

# Custom weights
python3 scripts/analyze/analyze_all_score.py --exec-weight 0.7 --cr-weight 0.3
```

This script will:
1. Read `results/exec_score_analysis.json` (execution scores)
2. Read `results/cr_score_analysis.json` (CR scores)
3. Calculate combined score: `all_score = 0.8 × exec_score + 0.2 × cr_score`
4. Save results to the `results/` directory

**Output Files:**
```
results/
├── all_score_analysis.json   # Combined score analysis
├── all_score_analysis.csv    # Combined score matrix
├── all_score_detail.csv      # Detailed data (exec, cr, all scores)
└── all_score_summary.txt     # Human-readable summary
```

**Notes:**
- Requires running `analyze_exec_score.py` and `analyze_cr_score.py` first to generate input data
- If a problem only has execution score or only has CR score, it will be calculated based on the available score

## Adding New Agents

1. Create agent script in `scripts/container/run_new_agent.sh`
2. Install CLI tools in `docker/base/Dockerfile`
3. Add case branch in `scripts/run_evaluation.sh`
4. Update `config/agent_model_config.json`

## Logs

Logs are saved to `logs/[agent]/[model]/[problem_id]/`:
```
oj_eval_[agent]_[model]_[problem_id]_[timestamp].log
```

Contains:
- Environment configuration
- GitHub repository creation
- Agent execution trace
- OJ submission results
- Submission IDs

## License

MIT License

## Citation

If you use ProjDevBench in your research, please cite:

```bibtex
@inproceedings{projdevbench2026,
  title={ProjDevBench: Benchmarking AI Coding Agents on End-to-End Project Development},
  author={Lu, Pengrui and Zhang, Shiqi and Hou, Yunzhong and Ye, Lyumanshan and Huang, Chaoyi and Chen, Zixi and Zeng, Ji and Jiang, Hantao and Liu, Pengfei and Wang, Yiwei and Yang, Ming-Hsuan},
  booktitle={International Conference on Machine Learning (ICML)},
  year={2026}
}
```

## Acknowledgments

We thank the OJ platform for providing the evaluation infrastructure and the developers of the coding agents evaluated in this work.
