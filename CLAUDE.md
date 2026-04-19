# CLAUDE.md

## 项目概述

macOS / Linux / Windows 开发工具一键安装与配置脚本，支持 Ghostty / Yazi / Lazygit / Claude Code / OpenClaw / Hermes Agent / OrbStack / Obsidian / Maccy / JDK / VS Code。

Linux 上自动检测发行版 (Ubuntu/Debian/Fedora/Arch 等)，macOS 专属工具提供替代方案（OrbStack→Docker, Maccy→CopyQ）。

## 脚本结构

- `install.sh` — macOS / Linux 主脚本，包含所有安装和配置逻辑
- `install.ps1` — Windows PowerShell 脚本，功能与 install.sh 对等
- 采用模块化函数设计：`install_ghostty`、`install_yazi`、`install_lazygit`、`install_claude`、`install_openclaw`、`install_hermes`、`install_orbstack`、`install_obsidian`、`install_maccy`、`install_jdk`、`install_vscode`
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

## 远程执行链接（前置要求）

**必须使用 repo 的 raw URL，不得使用 gist URL。** 链接以 `https://raw.githubusercontent.com/funchs/kaishi/main/` 开头。

```
curl -fsSL https://raw.githubusercontent.com/funchs/kaishi/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/funchs/kaishi/main/install.ps1 | iex   # Windows
```

同步顺序：先 `git push origin main`（repo raw URL 立即生效），再同步 gist 作为备用镜像。

## 脚本规范

- Shell：Bash，`set -uo pipefail`
- 所有 `read` 必须从 `/dev/tty` 读取（支持 `curl | bash` 管道模式）
- 所有用户可见输出通过 `info` / `ok` / `warn` / `err` 函数统一格式
- 每个工具安装完成后调用 `source_zshrc` 确保环境变量立即生效
- brew 安装带重试机制（最多 3 次，每次自动清锁）
- 已有配置先备份再覆盖（`backup_if_exists`）
- 跨平台兼容：`sed_i` 替代 `sed -i`，`clipboard_copy_cmd` 替代硬编码 `pbcopy`，`open_cmd` 替代硬编码 `open`
- macOS 专属工具在 Linux 上自动提供替代方案或跳过

## Linux 支持

- 通过 `uname -s` 检测 OS，`/etc/os-release` 检测发行版
- 支持包管理器：apt (Ubuntu/Debian)、dnf (Fedora)、pacman (Arch)、zypper (openSUSE)、yum (CentOS)
- Homebrew (Linuxbrew) 作为主要包管理器，原生包管理器作为后备
- macOS 专属工具映射：OrbStack → Docker Engine、Maccy → CopyQ、Antigravity → 跳过
- Nerd Font 在 Linux 上从 GitHub 下载到 `~/.local/share/fonts`
- Ghostty 配置在 Linux 上使用 Ctrl 快捷键（替代 Cmd）

## Claude 提供商配置

支持 4 种提供商 + 清除/跳过：
- Anthropic 直连（`ANTHROPIC_API_KEY`）
- Amazon Bedrock（`CLAUDE_CODE_USE_BEDROCK` + AWS 凭证/Profile）
- Google Vertex AI（`CLAUDE_CODE_USE_VERTEX` + GCP 项目）
- 自定义 API 代理（`ANTHROPIC_BASE_URL` + Key）

配置通过标记块写入 `.zshrc`，重复运行替换而非累加。
