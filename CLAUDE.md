# CLAUDE.md

## 项目概述

macOS 开发工具一键安装与配置脚本，支持 Ghostty / Yazi / Lazygit / Claude Code / OpenClaw / OrbStack / Obsidian / Maccy / JDK。

## 脚本结构

- `install.sh` — 唯一的主脚本文件，包含所有安装和配置逻辑
- 采用模块化函数设计：`install_ghostty`、`install_yazi`、`install_lazygit`、`install_claude`、`install_openclaw`、`install_orbstack`、`install_obsidian`、`install_maccy`、`install_jdk`
- 交互式多选菜单（方向键导航 + 空格选择），支持 `--skip` 跳过安装和 `claude-provider` 单独切换提供商
- Claude 提供商配置写入 `~/.zshrc` 的 `>>> Claude Code Provider Config >>>` 标记块中

## Git 提交规范

- 本项目使用 GitHub 账户提交，不使用全局 git 配置
- 用户名：`funchs`，邮箱：`eshore1258@gmail.com`
- 已通过 `git config user.name` / `git config user.email` 设置为项目级别

## 同步要求

**修改 install.sh 后必须同时同步到两个远程位置：**

1. **GitHub repo**：`git push origin main`
2. **Gist**：`gh gist edit 9848b313c7fd00253543d2db032b5dce -f install.sh install.sh`

每次提交后都要执行这两步，确保 repo 和 gist 内容一致。

## 远程执行链接

生成一键安装链接时使用 raw 格式：

```
curl -fsSL https://raw.githubusercontent.com/funchs/9848b313c7fd00253543d2db032b5dce/raw/install.sh | bash
```

## 脚本规范

- Shell：Bash，`set -uo pipefail`
- 所有 `read` 必须从 `/dev/tty` 读取（支持 `curl | bash` 管道模式）
- 所有用户可见输出通过 `info` / `ok` / `warn` / `err` 函数统一格式
- 每个工具安装完成后调用 `source_zshrc` 确保环境变量立即生效
- brew 安装带重试机制（最多 3 次，每次自动清锁）
- 已有配置先备份再覆盖（`backup_if_exists`）

## Claude 提供商配置

支持 4 种提供商 + 清除/跳过：
- Anthropic 直连（`ANTHROPIC_API_KEY`）
- Amazon Bedrock（`CLAUDE_CODE_USE_BEDROCK` + AWS 凭证/Profile）
- Google Vertex AI（`CLAUDE_CODE_USE_VERTEX` + GCP 项目）
- 自定义 API 代理（`ANTHROPIC_BASE_URL` + Key）

配置通过标记块写入 `.zshrc`，重复运行替换而非累加。
