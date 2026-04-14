# Kaishi 使用手册

macOS / Linux / Windows 开发工具一键安装与配置 — 完整使用指南。

---

## 目录

1. [快速开始](#1-快速开始)
2. [macOS 安装示例](#2-macos-安装示例)
3. [Linux 安装示例](#3-linux-安装示例)
4. [Windows 安装示例](#4-windows-安装示例)
5. [交互式菜单操作指南](#5-交互式菜单操作指南)
6. [命令行参数详解](#6-命令行参数详解)
7. [工具安装示例](#7-工具安装示例)
8. [配置管理](#8-配置管理)
9. [卸载操作](#9-卸载操作)
10. [国内镜像加速](#10-国内镜像加速)
11. [常见问题 (FAQ)](#11-常见问题-faq)
12. [配置文件速查表](#12-配置文件速查表)

---

## 1. 快速开始

打开终端，粘贴一行命令即可启动安装，无需下载任何文件。

### macOS / Linux

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash
```

国内网络：

```bash
curl -fsSL https://tinyurl.com/2xrksrcy | bash
```

### Windows

以管理员身份打开 PowerShell，执行：

```powershell
irm https://tinyurl.com/225zvy2o | iex
```

国内网络：

```powershell
irm https://tinyurl.com/25pho3w9 | iex
```

> **提示:** 短链接隐藏了 GitHub 地址，等价于完整 URL：
> - macOS/Linux: `https://raw.githubusercontent.com/funchs/kaishi/main/install.sh`
> - Windows: `https://raw.githubusercontent.com/funchs/kaishi/main/install.ps1`

---

## 2. macOS 安装示例

### 2.1 全新 Mac 一键装机

打开终端（Terminal.app 或 iTerm2），粘贴以下命令：

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash
```

脚本会自动完成以下流程：

```
========== 环境基础检查 ==========

检测网络环境...
[ OK ] GitHub 连接正常
是否仍要使用国内镜像加速? [y/N]: N        ← 直接回车跳过
[ OK ] Xcode Command Line Tools 已安装
[ OK ] Zsh 已安装: zsh 5.9
[ OK ] Zsh 已是默认 Shell
[ OK ] Homebrew 已安装: Homebrew 4.x.x
[ OK ] Git 已安装: git version 2.47.x
[ OK ] NVM 已安装: 0.40.1
[ OK ] Node.js 已安装: v22.x.x
[ OK ] Bun 已安装: 1.x.x

环境基础检查完成

╔══════════════════════════════════════════════╗
║     macOS 开发工具一键安装与配置             ║
╚══════════════════════════════════════════════╝

操作: ↑↓ 移动  空格 选择/取消  a 全选  u 卸载  回车 确认  q 退出

  > [ ] Ghostty      GPU 加速终端模拟器 (毛玻璃/分屏/Quake 下拉)
    [ ] Yazi         终端文件管理器 (快速预览/Vim 风格导航)
    [ ] Lazygit      终端 Git UI (可视化提交/分支/合并)
    [ ] Claude Code  Anthropic AI 编程助手 (终端内 AI 编程)
    [ ] OpenClaw     本地 AI 助手 (自托管/任务自动化)
    [ ] Hermes       Nous Research 自学习 AI Agent
    [ ] Antigravity  Google AI 开发平台
    [ ] OrbStack     Docker 容器 & Linux 虚拟机
    [ ] Obsidian     知识管理 & 笔记工具
    [ ] Maccy        剪贴板管理工具
    [ ] JDK          Java 开发工具包
    [ ] VS Code      代码编辑器 (Catppuccin 主题/扩展自动安装)
    [ ] 跳过         不安装工具，仅修改配置
```

按 `a` 全选，或用方向键 + 空格逐个选择，然后回车确认。

### 2.2 只装 AI 工具

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- claude openclaw hermes
```

输出示例：

```
========== 环境基础检查 ==========
...
环境基础检查完成

[INFO] 即将安装: claude openclaw hermes

========== [4/12] Claude Code ==========
[INFO] 正在安装 Claude Code...
[ OK ] Claude Code 安装完成

  当前提供商: 未配置
  1) Anthropic 直连        (使用 Anthropic API Key)
  2) Amazon Bedrock        (使用 AWS 凭证)
  3) Google Vertex AI      (使用 GCP 项目)
  4) 自定义 API 代理       (OpenRouter / 中转站等)
  5) 清除配置
  0) 跳过

  请输入选项 [0-5]: 1                     ← 选择提供商
  Anthropic API Key: sk-ant-xxxxx         ← 输入 API Key
[ OK ] Anthropic 直连已配置 (Key: sk-ant-a...xxxx)

========== [5/12] OpenClaw ==========
...
========== [6/12] Hermes Agent ==========
...

============================================
  All done! 全部完成
============================================
```

### 2.3 只装终端 + 编辑器

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- ghostty vscode
```

安装 Ghostty 后会询问 Shell 提示符配置：

```
========== [1/12] Ghostty ==========
[ OK ] Ghostty 安装完成

  1) 使用推荐配置 (Maple Mono + Catppuccin + 毛玻璃)
  2) 使用默认配置 / 保留当前配置
选择 Ghostty 配置方案 [1/2] (默认 1): 1    ← 回车用推荐

请选择 Shell 提示符工具:
  1) Oh My Zsh + 插件 (经典方案，功能丰富)
  2) Starship (跨平台极速提示符)
  3) 跳过 (保持现有配置)
请输入选项 [1/2/3] (默认 1): 2             ← 选 Starship

选择 Nerd Font 字体:
  1) Hack Nerd Font (推荐)
  ...
  6) 跳过
请输入选项 [1-6] (默认 1): 1               ← 回车用推荐

选择 Starship 主题:
  1) Catppuccin Mocha Powerline (推荐)
  ...
 10) 跳过
请输入选项 [1-10] (默认 1): 1              ← 回车用推荐

========== [12/12] VS Code ==========
[ OK ] VS Code 安装完成
[ OK ] Catppuccin 主题安装完成
[ OK ] Catppuccin Icons 安装完成
[ OK ] 中文语言包安装完成
[ OK ] Claude Code 插件安装完成
[ OK ] 已切换 VS Code 界面语言为中文 (argv.json)
```

### 2.4 全部安装

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --all
```

### 2.5 仅切换 Claude 提供商

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- claude-provider
```

---

## 3. Linux 安装示例

### 3.1 Ubuntu / Debian

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash
```

与 macOS 区别：
- 自动安装 `build-essential curl file git procps` 编译工具链
- Homebrew → Linuxbrew（自动安装）
- OrbStack → Docker Engine（`curl -fsSL https://get.docker.com | sudo bash`）
- Maccy → CopyQ（`sudo apt-get install -y copyq`）
- Nerd Font 下载到 `~/.local/share/fonts`
- Ghostty 快捷键用 `Ctrl` 替代 `Cmd`

### 3.2 Fedora

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash
```

编译工具链自动改为：`sudo dnf groupinstall -y "Development Tools"`

### 3.3 Arch Linux

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash
```

编译工具链自动改为：`sudo pacman -S --noconfirm base-devel curl file git procps-ng`

### 3.4 指定工具安装

```bash
# 终端三件套
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- ghostty yazi lazygit

# 全部安装
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --all

# 国内加速 + 全部安装
curl -fsSL https://tinyurl.com/2xrksrcy | bash -s -- --all
```

### 3.5 Linux 平台工具映射

| macOS 工具 | Linux 替代 | 说明 |
|-----------|-----------|------|
| OrbStack | Docker Engine | 自动通过官方脚本安装 |
| Maccy | CopyQ | 通过原生包管理器安装 |
| Antigravity | - | Linux 不支持，自动跳过 |
| `Cmd+D` 分屏 | `Ctrl+Shift+D` | Ghostty 快捷键自动适配 |

---

## 4. Windows 安装示例

### 4.1 首次安装

以**管理员身份**打开 PowerShell，粘贴：

```powershell
irm https://tinyurl.com/25pho3w9 | iex
```

> **注意:** 国内网络必须使用加速链接（上面已经是国内加速版）。直连链接：`irm https://tinyurl.com/225zvy2o | iex`

脚本输出示例：

```
[WARN] 部分安装可能需要管理员权限，建议以管理员身份运行 PowerShell

================================================
   Windows Dev Tools One-Click Installer
================================================

 1) Ghostty      GPU 加速终端模拟器 (毛玻璃/分屏/Quake 下拉)
 2) Yazi         终端文件管理器 (快速预览/Vim 风格导航)
 3) Lazygit      终端 Git UI (可视化提交/分支/合并)
 4) Claude Code  Anthropic AI 编程助手 (终端内 AI 编程)
 5) OpenClaw     本地 AI 助手 (自托管/任务自动化)
 6) Hermes       Nous Research 自学习 AI Agent
 7) Antigravity  Google AI 开发平台
 8) Docker       Docker Desktop (容器 & Kubernetes)
 9) Obsidian     知识管理 & 笔记工具
10) Ditto        剪贴板管理工具 (Maccy 替代)
11) JDK          Java 开发工具包
12) VS Code      代码编辑器 (Catppuccin 主题/扩展自动安装)

  A) 全部安装
  U) 卸载已安装的工具
  S) 跳过安装，仅修改配置
  Q) 退出

请输入编号 (多选用逗号分隔, 例: 1,3,4):
```

### 4.2 安装 VS Code + Claude Code

```powershell
irm https://tinyurl.com/25pho3w9 | iex
```

输入 `4,12` 回车：

```
请输入编号 (多选用逗号分隔, 例: 1,3,4): 4,12

========== 环境基础检查 ==========
[WARN] GitHub 连接缓慢或不可用
是否使用国内镜像加速? [Y/n]: Y            ← 回车启用加速
[ OK ] 已启用国内镜像加速
[INFO]   GitHub 代理: https://ghfast.top/
[ OK ] winget 已可用
[ OK ] Scoop 已安装
[ OK ] Git 已安装: git version 2.47.x
[ OK ] Scoop bucket 'extras' 已添加
[ OK ] NVM for Windows 已安装
[ OK ] Node.js 已安装: v24.x.x
[ OK ] Bun 已安装: 1.x.x

环境基础检查完成

[INFO] 即将安装: claude, vscode

========== [4/12] Claude Code ==========
[INFO] 正在安装 Claude Code...
[ OK ] Claude Code 安装完成

  当前提供商: 未配置
  1) Anthropic 直连
  2) Amazon Bedrock
  3) Google Vertex AI
  4) 自定义 API 代理
  5) 清除配置
  0) 跳过

  请输入选项 [0-5]: 4                     ← 选自定义代理
  API Base URL: https://your-proxy.com/v1  ← 输入代理地址
  API Key: sk-xxxxx                        ← 输入 Key
[ OK ] 自定义 API 代理已配置
[INFO] 已写入用户环境变量 + ~/.claude/settings.json

========== [12/12] VS Code ==========
[INFO] 正在安装 VS Code...
[INFO] 系统架构: AMD64 -> VS Code x64
[INFO] Windows 版本: 10.0.xxxxx
[INFO] 正在下载: https://update.code.visualstudio.com/latest/win32-x64-user/stable
[INFO] 正在静默安装...
[ OK ] VS Code 安装完成 (直接下载)
[INFO] 安装 Catppuccin 主题扩展...
[ OK ] Catppuccin 主题安装完成
[ OK ] Catppuccin Icons 安装完成
[ OK ] 中文语言包安装完成
[ OK ] Claude Code 插件安装完成
[ OK ] 已切换 VS Code 界面语言为中文 (argv.json)
[ OK ] 已设置 Catppuccin 主题 + 中文语言

============================================
  All done! 全部完成
============================================

已安装: claude, vscode

  Claude    用户环境变量 + ~/.claude/settings.json
  VS Code   Catppuccin Latte 主题已应用
```

### 4.3 全部安装

```powershell
irm https://tinyurl.com/25pho3w9 | iex
```

输入 `A` 回车，全部安装。

### 4.4 只装指定工具（直接传参）

Windows 需要先下载脚本再传参：

```powershell
# 下载脚本
irm https://tinyurl.com/25pho3w9 -OutFile $env:TEMP\kaishi.ps1

# 安装指定工具
& $env:TEMP\kaishi.ps1 vscode claude

# 全部安装
& $env:TEMP\kaishi.ps1 --all

# 仅切换 Claude 提供商
& $env:TEMP\kaishi.ps1 claude-provider
```

### 4.5 Windows 平台特殊说明

| 项目 | 说明 |
|------|------|
| 包管理器 | Scoop（主力）+ winget（补充） |
| 管理员权限 | 建议以管理员运行，Scoop 安装时自动加 `-RunAsAdmin` |
| 不支持的工具 | Ghostty（仅 macOS/Linux）、Antigravity（需 macOS/Linux），选择后自动跳过 |
| Shell 提示符 | 安装 Ghostty 时询问 Starship / Oh My Posh（Windows 上 Ghostty 不可用则不触发） |
| Claude 配置 | 写入 Windows 用户环境变量 + `~/.claude/settings.json` |
| VS Code 下载 | 优先微软 CDN 直接下载，回退 winget → scoop |
| 网络超时 | 所有操作 60-120s 超时保护，不会无限挂起 |

---

## 5. 交互式菜单操作指南

### 5.1 macOS / Linux — 方向键模式

| 按键 | 功能 |
|------|------|
| `↑` `↓` | 上下移动光标 |
| `空格` | 选中/取消当前项 |
| `a` | 全选/取消全选 |
| `u` | 进入卸载模式 |
| `回车` | 确认选择，开始安装 |
| `q` | 退出脚本 |

### 5.2 Windows — 数字输入模式

| 输入 | 功能 |
|------|------|
| `1,3,4` | 安装第 1、3、4 号工具 |
| `12` | 只安装 VS Code |
| `A` | 全部安装 |
| `U` | 进入卸载模式 |
| `S` | 跳过安装，进入配置菜单 |
| `Q` | 退出脚本 |

---

## 6. 命令行参数详解

所有参数在 macOS/Linux/Windows 上通用。

### `--all` / `-a`

安装全部 12 个工具，跳过交互菜单。

```bash
# macOS / Linux
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --all
```

```powershell
# Windows
& $env:TEMP\kaishi.ps1 --all
```

### `--uninstall` / `-u`

进入交互式卸载模式，检测已安装的工具并选择卸载。

```bash
# macOS / Linux
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --uninstall
```

```powershell
# Windows
irm https://tinyurl.com/25pho3w9 -OutFile $env:TEMP\kaishi.ps1; & $env:TEMP\kaishi.ps1 --uninstall
```

### `--skip` / `-s`

跳过环境基础检查和工具安装，直接进入配置菜单（目前仅 Claude 提供商配置）。

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --skip
```

### `--mirror` / `-m`

强制启用国内镜像加速，跳过自动检测。

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --mirror --all
```

### `--help` / `-h`

显示帮助信息。

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --help
```

### `<tool> ...`

指定安装一个或多个工具，工具名用空格分隔。

可用工具名：`ghostty` `yazi` `lazygit` `claude` `openclaw` `hermes` `antigravity` `orbstack` `obsidian` `maccy` `jdk` `vscode`

```bash
# 安装终端三件套
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- ghostty yazi lazygit

# 只装 VS Code
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- vscode

# 安装 AI 工具组合
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- claude openclaw hermes vscode
```

### `claude-provider`

仅修改 Claude API 提供商配置，不安装任何工具。

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- claude-provider
```

---

## 7. 工具安装示例

### 7.1 单个工具安装

```bash
# Ghostty 终端
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- ghostty

# Yazi 文件管理器
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- yazi

# Lazygit Git UI
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- lazygit

# Claude Code AI 编程助手
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- claude

# VS Code 编辑器 (含主题/中文/Claude 插件)
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- vscode

# JDK (通过 SDKMAN，支持选择版本 21/17/11/8)
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- jdk

# Docker (macOS 装 OrbStack，Linux 装 Docker Engine)
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- orbstack
```

### 7.2 推荐组合

```bash
# 前端开发者
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- ghostty yazi lazygit vscode

# AI 开发者
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- claude openclaw hermes vscode

# Java 开发者
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- lazygit vscode jdk orbstack

# 轻量装机 (编辑器 + Git UI)
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- lazygit vscode
```

---

## 8. 配置管理

### 8.1 Claude 提供商配置

安装 Claude Code 时自动询问，也可单独运行：

```bash
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- claude-provider
```

#### 方式 1：Anthropic 直连

```
  请输入选项 [0-5]: 1
  Anthropic API Key: sk-ant-api03-xxxxx
[ OK ] Anthropic 直连已配置 (Key: sk-ant-a...xxxxx)
```

写入内容（macOS/Linux `~/.zshrc`）：
```bash
# >>> Claude Code Provider Config >>>
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"
# <<< Claude Code Provider Config <<<
```

#### 方式 2：Amazon Bedrock

```
  请输入选项 [0-5]: 2

  认证方式:
    a) AWS Access Key (AK/SK)
    b) AWS Profile (~/.aws/credentials)

  选择认证方式 [a/b]: b
  AWS Region [us-east-1]: us-west-2
  AWS Profile 名称 [default]: my-profile
[ OK ] Amazon Bedrock 已配置 (Profile: my-profile, Region: us-west-2)
```

#### 方式 3：Google Vertex AI

```
  请输入选项 [0-5]: 3
  GCP 项目 ID: my-gcp-project
  GCP Region [us-east5]: us-east5
[ OK ] Google Vertex AI 已配置 (项目: my-gcp-project, Region: us-east5)
```

> **提示:** 需要先运行 `gcloud auth application-default login` 完成认证。

#### 方式 4：自定义 API 代理

```
  请输入选项 [0-5]: 4
  API Base URL: https://openrouter.ai/api/v1
  API Key: sk-or-xxxxx
[ OK ] 自定义 API 代理已配置 (URL: https://openrouter.ai/api/v1)
```

> **Windows 特殊说明:** 配置同时写入 **Windows 用户环境变量** + **`~/.claude/settings.json`**，确保无论从哪里启动 Claude Code 都能读到。

### 8.2 Shell 提示符

安装 Ghostty 终端时自动询问。三个选项：

| 选项 | macOS/Linux | Windows |
|------|------------|---------|
| Oh My Zsh | Zsh 框架 + 插件 | - |
| Starship | 跨平台极速提示符 | Starship |
| Oh My Posh | - | PowerShell 美化 |

Starship 安装后可选主题：Catppuccin Mocha（推荐）、gruvbox-rainbow、tokyo-night 等 9 种。

### 8.3 VS Code 自动配置

安装 VS Code 后自动完成以下配置：

| 配置项 | 内容 |
|--------|------|
| 颜色主题 | Catppuccin Latte |
| 图标主题 | catppuccin-latte |
| 界面语言 | 中文 (`zh-cn`) |
| 扩展 - 主题 | `Catppuccin.catppuccin-vsc` |
| 扩展 - 图标 | `Catppuccin.catppuccin-vsc-icons` |
| 扩展 - 中文 | `MS-CEINTL.vscode-language-pack-zh-hans` |
| 扩展 - AI | `anthropic.claude-code` |

所有配置写入 `settings.json`，语言设置写入 `argv.json`（无 BOM 的 UTF-8）。

---

## 9. 卸载操作

### 9.1 交互式卸载

```bash
# macOS / Linux
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --uninstall
```

```powershell
# Windows
irm https://tinyurl.com/25pho3w9 -OutFile $env:TEMP\kaishi.ps1; & $env:TEMP\kaishi.ps1 --uninstall
```

输出示例（Windows）：

```
================================================
   Windows 开发工具卸载
================================================

[INFO] 检测已安装的工具...
  --- 应用工具 ---
  1) Yazi
  2) Lazygit
  3) VS Code

  --- 基础环境 ---
  4) Git
  5) Node.js
  6) NVM
  7) Bun

  A) 全部卸载
  Q) 取消

请输入编号 (多选用逗号分隔): 1,2          ← 卸载 Yazi 和 Lazygit

[WARN] 即将卸载: Yazi, Lazygit
确认卸载? [y/N]: y

[INFO] 正在卸载 Yazi...
[ OK ] Yazi 已卸载 (scoop)
[INFO] 正在卸载 Lazygit...
[ OK ] Lazygit 已卸载 (scoop)

卸载完成
```

### 9.2 卸载范围

卸载会自动清理以下内容：

| 工具 | 卸载程序 | 清理配置 |
|------|---------|---------|
| Ghostty | brew/winget/scoop | `~/.config/ghostty/` 或 `%APPDATA%\ghostty\` |
| Yazi | brew/scoop | `~/.config/yazi/` 或 `%APPDATA%\yazi\` |
| Lazygit | brew/scoop | `~/.config/lazygit/` 或 `%APPDATA%\lazygit\` |
| Claude Code | 官方脚本/npm | - |
| VS Code | brew/winget/scoop/卸载程序 | `~/.vscode/`、Code 配置目录 |
| Starship | brew/scoop | `starship.toml` + Profile 中的 init 行 |
| Oh My Posh | scoop | Profile 中的 init 行 |
| Git Delta | brew/scoop | `git config --global` 中的 delta 配置 |
| NVM | scoop/目录删除 | NVM 目录 |
| Bun | brew/scoop | `~/.bun` 目录 |

### 9.3 也可从交互菜单进入

不用传 `--uninstall`，直接运行脚本后：

- macOS/Linux：按 `u` 键
- Windows：输入 `U` 回车

---

## 10. 国内镜像加速

### 10.1 自动检测

脚本启动时自动测试 GitHub 连通性（3 秒超时）：

- **连接正常** → 询问是否仍要使用镜像（默认否）
- **连接失败** → 询问是否使用镜像（默认是）

### 10.2 强制启用

```bash
# macOS / Linux
curl -fsSL https://tinyurl.com/2xrksrcy | bash -s -- --mirror --all
```

```powershell
# Windows (国内加速链接已内置 ghfast)
irm https://tinyurl.com/25pho3w9 | iex
```

### 10.3 镜像源

| 服务 | 镜像 | 适用范围 |
|------|------|---------|
| GitHub 下载 | `ghfast.top` URL 前缀 | 脚本下载、Nerd Font、Hermes |
| Homebrew | USTC 镜像 | brew install（macOS/Linux） |
| Node.js | npmmirror | nvm install |
| npm | npmmirror registry | npm install |

> **注意:** `ghfast.top` 是 URL 前缀代理（`https://ghfast.top/https://github.com/...`），不是 HTTP 代理，不能设为 `http.proxy`。

---

## 11. 常见问题 (FAQ)

### Q: Windows 上 Scoop 安装报 "administrator is disabled"

以管理员身份运行 PowerShell。脚本会自动检测并加 `-RunAsAdmin` 参数。

### Q: GitHub 连接超时怎么办？

使用国内加速链接：

```bash
curl -fsSL https://tinyurl.com/2xrksrcy | bash
```

或启动时选择启用镜像加速。

### Q: VS Code 弹出 "argv.json contains errors"

`argv.json` 文件被损坏。运行以下命令修复：

```powershell
# Windows
[IO.File]::WriteAllText("$env:USERPROFILE\.vscode\argv.json", '{"locale":"zh-cn"}')
```

```bash
# macOS / Linux
echo '{"locale":"zh-cn"}' > ~/.vscode/argv.json
```

重启 VS Code 生效。

> **原因:** `argv.json` 是 JSONC 格式（带注释），不能有 UTF-8 BOM。脚本已修复为无 BOM 写入。

### Q: VS Code 中文界面没生效

1. 确认中文语言包已安装：`code --list-extensions | grep zh-hans`
2. 确认 `argv.json` 内容正确且无 BOM（底部状态栏应显示 "UTF-8"，不是 "UTF-8 with BOM"）
3. 完全关闭 VS Code（包括任务栏图标）后重新打开

### Q: VS Code 安装卡住不动

Windows 国内网络下 winget/scoop 下载微软服务器或 GitHub 可能很慢。脚本已加 60-120 秒超时保护，超时会自动跳过并尝试下一种方式。

如果所有方式都超时，手动下载：https://code.visualstudio.com/Download

### Q: macOS 上 Homebrew 安装失败

脚本有 3 次重试机制，每次自动清理锁文件。如果仍然失败：

```bash
# 手动清理
pkill -9 -f 'brew install'
rm -rf ~/Library/Caches/Homebrew/downloads/*incomplete*
# 重新运行
curl -fsSL https://tinyurl.com/25n5uezk | bash
```

### Q: JDK 安装时 SDKMAN 报 Bash 版本不兼容（macOS）

macOS 自带 Bash 3.2，SDKMAN 需要 Bash 4+。脚本会自动通过 Homebrew 安装新版 Bash 并用它运行 SDKMAN。

### Q: 安装 Ghostty 时不想配置 Shell 提示符

Shell 提示符配置在安装 Ghostty 时自动询问，选 `3) 跳过` 即可。

---

## 12. 配置文件速查表

### 12.1 配置文件路径

| 配置 | macOS | Linux | Windows |
|------|-------|-------|---------|
| Ghostty | `~/.config/ghostty/config` | `~/.config/ghostty/config` | `%APPDATA%\ghostty\config` |
| Yazi | `~/.config/yazi/` | `~/.config/yazi/` | `%APPDATA%\yazi\config\` |
| Lazygit | `~/.config/lazygit/config.yml` | `~/.config/lazygit/config.yml` | `%APPDATA%\lazygit\config.yml` |
| Starship | `~/.config/starship.toml` | `~/.config/starship.toml` | `%USERPROFILE%\.config\starship.toml` |
| VS Code 设置 | `~/Library/Application Support/Code/User/settings.json` | `~/.config/Code/User/settings.json` | `%APPDATA%\Code\User\settings.json` |
| VS Code 语言 | `~/.vscode/argv.json` | `~/.vscode/argv.json` | `%USERPROFILE%\.vscode\argv.json` |
| Claude 配置 | `~/.zshrc` 标记块 | `~/.zshrc` 标记块 | 用户环境变量 + `~/.claude/settings.json` |
| Shell 配置 | `~/.zshrc` | `~/.zshrc` | PowerShell Profile |

### 12.2 包管理器对照

| 操作 | macOS | Linux | Windows |
|------|-------|-------|---------|
| 安装包 | `brew install` | `brew install` / `apt install` | `scoop install` / `winget install` |
| 安装 GUI 应用 | `brew install --cask` | `flatpak` / `snap` | `winget install` |
| 搜索包 | `brew search` | `brew search` / `apt search` | `scoop search` / `winget search` |
| 卸载包 | `brew uninstall` | `brew uninstall` / `apt remove` | `scoop uninstall` / `winget uninstall` |

### 12.3 快捷键速查

#### Ghostty

| 功能 | macOS | Linux / Windows |
|------|-------|-----------------|
| 全局唤出 | `Ctrl+`` ` | `Ctrl+`` ` |
| 新标签页 | `Cmd+T` | `Ctrl+Shift+T` |
| 关闭标签 | `Cmd+W` | `Ctrl+Shift+W` |
| 右侧分屏 | `Cmd+D` | `Ctrl+Shift+D` |
| 下方分屏 | `Cmd+Shift+D` | `Ctrl+Shift+E` |
| 切换分屏 | `Cmd+Alt+方向键` | `Ctrl+Shift+H/J/K/L` |
| 放大字号 | `Cmd++` | `Ctrl++` |
| 缩小字号 | `Cmd+-` | `Ctrl+-` |

#### Yazi

| 快捷键 | 功能 |
|--------|------|
| `y` | 启动并退出后 cd |
| `.` | 切换隐藏文件 |
| `gd` / `gD` / `gh` / `gc` / `gp` | 跳转 Downloads / Desktop / Home / .config / Projects |
| `T` | Ghostty 打开当前目录 |
| `C` | VS Code 打开当前目录 |
| `S` | 打开 Shell |

#### Lazygit

| 快捷键 | 功能 |
|--------|------|
| `O` | 浏览器打开仓库 |
| `F` | fixup commit |
| `Y` | 复制分支名 |
| `Tab` | 切换面板 |
| `[` / `]` | 上/下翻页 |
