# Kaishi 用户手册

macOS / Linux / Windows 开发工具一键安装与配置脚本完整使用指南。

---

## 目录

1. [快速开始](#1-快速开始)
2. [本地安装使用](#2-本地安装使用)
   - [macOS 完整示例](#21-macos-完整示例)
   - [Linux 完整示例](#22-linux-完整示例)
   - [Windows 完整示例](#23-windows-完整示例)
3. [交互式菜单操作指南](#3-交互式菜单操作指南)
4. [命令行参数详解](#4-命令行参数详解)
5. [逐个工具安装示例](#5-逐个工具安装示例)
6. [配置管理](#6-配置管理)
7. [卸载操作](#7-卸载操作)
8. [国内镜像加速](#8-国内镜像加速)
9. [常见问题 (FAQ)](#9-常见问题-faq)
10. [配置文件速查表](#10-配置文件速查表)

---

## 1. 快速开始

### 一键远程安装

无需下载任何文件，打开终端执行一条命令即可启动交互式安装。

**macOS / Linux:**

```bash
# 短链接 (推荐)
curl -fsSL https://tinyurl.com/25n5uezk | bash

# 完整 URL
curl -fsSL https://gist.githubusercontent.com/funchs/9848b313c7fd00253543d2db032b5dce/raw/install.sh | bash
```

**Windows (PowerShell):**

```powershell
# 短链接 (推荐)
irm https://tinyurl.com/225zvy2o | iex

# 完整 URL
irm https://gist.githubusercontent.com/funchs/9848b313c7fd00253543d2db032b5dce/raw/install.ps1 | iex
```

> **提示:** 国内用户如遇 GitHub 连接超时，请参阅 [第 8 节 - 国内镜像加速](#8-国内镜像加速)。

### 一键远程卸载

```bash
# macOS / Linux
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --uninstall
```

```powershell
# Windows
irm https://tinyurl.com/25pho3w9 -OutFile $env:TEMP\i.ps1; & $env:TEMP\i.ps1 --uninstall
```

---

## 2. 本地安装使用

### 2.1 macOS 完整示例

#### 步骤一：克隆仓库

```bash
git clone https://github.com/funchs/dotfiles.git
cd dotfiles
```

#### 步骤二：添加执行权限

```bash
chmod +x install.sh
```

#### 步骤三：启动安装

```bash
./install.sh
```

执行后将看到交互式菜单（参见 [第 3 节](#3-交互式菜单操作指南)）。

脚本会自动按以下顺序运行：

1. **环境基础检查**（自动完成，无需手动选择）：
   - 检测并安装 Xcode Command Line Tools
   - 检测并安装 Zsh，设为默认 Shell
   - 检测并安装 Homebrew
   - 检测并安装 Git
   - 检测并安装 NVM + Node.js LTS
   - 检测并安装 Bun
2. **安装选中的工具**：按 Ghostty -> Yazi -> ... -> VS Code 顺序安装

#### 示例终端输出

```
========== 环境基础检查 ==========

检测网络环境...
[ OK ] GitHub 连接正常
是否仍要使用国内镜像加速? [y/N]: N
[ OK ] Xcode Command Line Tools 已安装
[ OK ] Zsh 已安装: zsh 5.9
[ OK ] Zsh 已是默认 Shell
[ OK ] Homebrew 已安装: Homebrew 4.x.x
[ OK ] Git 已安装: git version 2.x.x
[ OK ] NVM 已安装: 0.40.1
[ OK ] Node.js 已安装: v22.x.x
[ OK ] Bun 已安装: 1.x.x

环境基础检查完成
```

#### 安装全部工具

```bash
./install.sh --all
```

#### 仅安装 AI 工具组合

```bash
./install.sh claude openclaw hermes
```

### 2.2 Linux 完整示例

#### Ubuntu / Debian

```bash
git clone https://github.com/funchs/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

环境基础检查时会自动安装编译工具链：

```
[INFO] 正在安装编译工具链 (Homebrew 编译依赖)...
# 自动执行: sudo apt-get update && sudo apt-get install -y build-essential curl file git procps
[ OK ] 编译工具链安装完成
```

> **注意:** Linux 上部分工具有替代方案。OrbStack 会替换为 Docker Engine，Maccy 会替换为 CopyQ，Antigravity 在 Linux 上不可用。

#### Fedora

```bash
git clone https://github.com/funchs/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

编译工具链安装命令不同：

```
# 自动执行: sudo dnf groupinstall -y "Development Tools" && sudo dnf install -y curl file git procps-ng
```

#### Arch Linux

```bash
git clone https://github.com/funchs/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

编译工具链安装命令：

```
# 自动执行: sudo pacman -S --noconfirm base-devel curl file git procps-ng
```

#### Linux 平台差异一览

| 功能 | macOS | Linux |
|------|-------|-------|
| 容器工具 | OrbStack | Docker Engine |
| 剪贴板管理 | Maccy | CopyQ |
| Ghostty 快捷键 | Cmd 系列 | Ctrl 系列 |
| Nerd Font 安装 | `brew install --cask` | GitHub 下载到 `~/.local/share/fonts` |
| Antigravity | brew cask | 不支持 (跳过) |

### 2.3 Windows 完整示例

#### 前置要求

- Windows 10 或更高版本
- PowerShell 5.1 或更高版本（Windows 10 自带）
- 建议以管理员身份运行 PowerShell

#### 步骤一：克隆仓库

```powershell
git clone https://github.com/funchs/dotfiles.git
cd dotfiles
```

#### 步骤二：设置执行策略（如尚未设置）

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

#### 步骤三：启动安装

```powershell
.\install.ps1
```

Windows 版环境基础检查会安装：

```
========== 环境基础检查 ==========

检测网络环境...
[ OK ] GitHub 连接正常
[ OK ] winget 已可用
[ OK ] Scoop 已安装
[ OK ] Git 已安装: git version 2.x.x
[ OK ] Scoop bucket 'extras' 已添加
[ OK ] Scoop bucket 'versions' 已添加
[ OK ] Scoop bucket 'nerd-fonts' 已添加
[ OK ] NVM for Windows 已安装
[ OK ] Node.js 已安装: v22.x.x
[ OK ] Bun 已安装: 1.x.x

环境基础检查完成
```

#### 安装全部工具

```powershell
.\install.ps1 --all
```

> **注意:** Windows 上使用 Scoop 和 winget 作为包管理器，部分工具安装方式与 macOS/Linux 不同。Scoop 安装有 120 秒超时保护，超时会自动跳过。

---

## 3. 交互式菜单操作指南

### macOS / Linux 菜单

直接运行 `./install.sh`（不带参数）进入交互式菜单：

```
╔══════════════════════════════════════════════╗
║     macOS 开发工具一键安装与配置             ║
╚══════════════════════════════════════════════╝

操作: ↑↓ 移动  空格 选择/取消  a 全选  u 卸载  回车 确认  q 退出

  > [*] Ghostty      GPU 加速终端模拟器 (毛玻璃/分屏/Quake 下拉)
    [*] Yazi         终端文件管理器 (快速预览/Vim 风格导航)
    [ ] Lazygit      终端 Git UI (可视化提交/分支/合并)
    [ ] Claude Code  Anthropic AI 编程助手 (终端内 AI 编程)
    [ ] OpenClaw     本地 AI 助手 (自托管/任务自动化)
    [ ] Hermes       Nous Research 自学习 AI Agent (技能/记忆/多平台)
    [ ] Antigravity  Google AI 开发平台 (智能编码/Agent 工作流)
    [ ] OrbStack     Docker 容器 & Linux 虚拟机 (轻量/快速)
    [ ] Obsidian     知识管理 & 笔记工具 (Markdown/双链/插件)
    [ ] Maccy        剪贴板管理工具 (轻量/开源/快捷搜索)
    [ ] JDK          Java 开发工具包 (SDKMAN 管理/多版本切换)
    [ ] VS Code      代码编辑器 (Catppuccin 主题/扩展自动安装)
    [ ] 跳过         不安装工具，仅修改配置
```

**操作方式：**

| 按键 | 功能 |
|------|------|
| `↑` / `↓` | 上下移动光标 |
| `空格` | 选中 / 取消选中当前项（`[*]` 表示已选中） |
| `a` | 全选 / 全不选（切换） |
| `u` | 进入卸载模式 |
| `回车` | 确认选择并开始安装 |
| `q` | 退出脚本 |

> **提示:** 选择最后一项「跳过」将不安装任何工具，直接进入配置菜单（可切换 Claude 提供商等）。

### Windows 菜单

直接运行 `.\install.ps1`（不带参数）进入交互式菜单：

```
╔══════════════════════════════════════════════╗
║     Windows 开发工具一键安装与配置           ║
╚══════════════════════════════════════════════╝

   1) Ghostty      GPU 加速终端模拟器 (毛玻璃/分屏/Quake 下拉)
   2) Yazi         终端文件管理器 (快速预览/Vim 风格导航)
   3) Lazygit      终端 Git UI (可视化提交/分支/合并)
   4) Claude Code  Anthropic AI 编程助手 (终端内 AI 编程)
   5) OpenClaw     本地 AI 助手 (自托管/任务自动化)
   6) Hermes       Nous Research 自学习 AI Agent (技能/记忆/多平台)
   7) Antigravity  Google AI 开发平台 (智能编码/Agent 工作流)
   8) Docker       Docker Desktop (容器 & Kubernetes)
   9) Obsidian     知识管理 & 笔记工具 (Markdown/双链/插件)
  10) Ditto        剪贴板管理工具 (Maccy 替代, 开源/快捷搜索)
  11) JDK          Java 开发工具包 (多版本切换)
  12) VS Code      代码编辑器 (Catppuccin 主题/扩展自动安装)

  A) 全部安装
  U) 卸载已安装的工具
  S) 跳过安装，仅修改配置
  Q) 退出

请输入编号 (多选用逗号分隔, 例: 1,3,4):
```

**操作方式：**

- 输入单个数字安装一个工具：`4` (安装 Claude Code)
- 输入逗号分隔的多个数字：`1,3,4` (安装 Ghostty + Lazygit + Claude Code)
- 输入 `A` 全部安装
- 输入 `U` 进入卸载模式
- 输入 `S` 跳过安装进入配置菜单
- 输入 `Q` 退出

---

## 4. 命令行参数详解

### macOS / Linux (`install.sh`)

#### `--all` / `-a` — 安装全部工具

跳过交互式菜单，直接安装所有 12 个工具。

```bash
./install.sh --all
```

```
# 预期输出:
[INFO] 即将安装: ghostty yazi lazygit claude openclaw hermes antigravity orbstack obsidian maccy jdk vscode
```

#### `--uninstall` / `-u` — 卸载模式

进入交互式卸载菜单，检测并列出所有已安装的工具供选择卸载。

```bash
./install.sh --uninstall
```

详见 [第 7 节 - 卸载操作](#7-卸载操作)。

#### `--skip` / `-s` — 跳过安装

跳过工具安装和环境基础检查，直接进入配置操作菜单。

```bash
./install.sh --skip
```

```
# 预期输出:
[INFO] 跳过工具安装，进入配置菜单

========== 配置操作 ==========

  1) 修改 Claude 提供商配置
  0) 退出

  请选择 [0-1]:
```

> **提示:** 适用于已安装完工具后想单独修改配置的场景。

#### `--mirror` / `-m` — 强制启用国内镜像

跳过网络检测，直接启用 GitHub/Homebrew/Node.js 的国内镜像加速。

```bash
./install.sh --mirror
```

```
# 预期输出:
[ OK ] 已启用国内镜像加速
[INFO]   GitHub 代理:   https://ghfast.top/
[INFO]   Homebrew 镜像: USTC
[INFO]   Node.js 镜像:  npmmirror
```

可与其他参数组合使用：

```bash
# 使用镜像加速安装全部工具
./install.sh --mirror --all

# 使用镜像加速安装指定工具
./install.sh --mirror ghostty claude
```

#### `--help` / `-h` — 显示帮助

```bash
./install.sh --help
```

#### `<tool>` — 指定工具名称

直接在参数中传入工具名称，跳过交互式菜单。

```bash
# 只安装 Ghostty 和 Yazi
./install.sh ghostty yazi

# 只安装 Claude Code
./install.sh claude

# 只安装 VS Code
./install.sh vscode
```

可用的工具名称：`ghostty`、`yazi`、`lazygit`、`claude`、`openclaw`、`hermes`、`antigravity`、`orbstack`、`obsidian`、`maccy`、`jdk`、`vscode`

#### `claude-provider` — 切换 Claude 提供商

跳过所有工具安装，仅修改 Claude Code 的 API 提供商配置。

```bash
./install.sh claude-provider
```

```
# 预期输出:
[INFO] 配置 Claude Code API 提供商

  当前提供商: Anthropic 直连

  1) Anthropic 直连        (使用 Anthropic API Key)
  2) Amazon Bedrock        (使用 AWS 凭证)
  3) Google Vertex AI      (使用 GCP 项目)
  4) 自定义 API 代理       (OpenRouter / 中转站等)
  5) 清除配置              (移除当前提供商设置)
  0) 跳过                  (保持现有配置不变)

  请输入选项 [0-5]:
```

### Windows (`install.ps1`)

Windows 版支持完全相同的参数，用法也一致：

```powershell
.\install.ps1 --all              # 安装全部
.\install.ps1 --uninstall        # 卸载模式
.\install.ps1 --skip             # 跳过安装
.\install.ps1 --mirror           # 强制镜像
.\install.ps1 --help             # 帮助
.\install.ps1 ghostty yazi       # 指定工具
.\install.ps1 claude-provider    # 切换提供商
```

---

## 5. 逐个工具安装示例

### 5.1 Ghostty — GPU 加速终端模拟器

```bash
# macOS / Linux
./install.sh ghostty
```

```powershell
# Windows
.\install.ps1 ghostty
```

安装过程会依次询问：

1. **配置方案选择：**
   ```
     1) 使用推荐配置 (Maple Mono + Catppuccin + 毛玻璃)
     2) 使用默认配置 / 保留当前配置
   
   选择 Ghostty 配置方案 [1/2] (默认 1):
   ```

2. **Shell 提示符选择（仅安装 Ghostty 时触发）：**
   ```
   请选择 Shell 提示符工具:
     1) Oh My Zsh + 插件 (经典方案，功能丰富)          # macOS/Linux
     2) Starship (跨平台极速提示符)
     3) 跳过 (保持现有配置)
   请输入选项 [1/2/3] (默认 1):
   ```

   Windows 上提示符选项不同：
   ```
     1) Starship (跨平台极速提示符，推荐)
     2) Oh My Posh (PowerShell 美化方案)
     3) 跳过 (保持现有配置)
   ```

3. **选择 Starship 时，还会询问 Nerd Font 和主题：**
   ```
   选择 Nerd Font 字体:
     1) Hack Nerd Font (推荐)
     2) JetBrainsMono Nerd Font
     3) FiraCode Nerd Font
     4) MesloLG Nerd Font
     5) CascadiaCode Nerd Font
     6) 跳过

   选择 Starship 主题:
      1) Catppuccin Mocha Powerline (推荐)
      2) catppuccin-powerline
      3) gruvbox-rainbow
      4) tokyo-night
      ...
     10) 跳过
   ```

### 5.2 Yazi — 终端文件管理器

```bash
./install.sh yazi
```

会自动安装辅助依赖（fd、ripgrep、fzf、zoxide、poppler、ffmpegthumbnailer、7zip、jq、imagemagick），然后询问配置方案：

```
  1) 使用推荐配置 (glow 预览 + 大预览区 + 快捷跳转)
  2) 使用默认配置 / 保留当前配置

选择 Yazi 配置方案 [1/2] (默认 1):
```

选择推荐配置后会写入 4 个配置文件并安装插件：

```
[ OK ] yazi.toml 已写入
[ OK ] keymap.toml 已写入
[ OK ] theme.toml 已写入
[ OK ] init.lua 已写入
[ OK ] full-border 插件已安装
[ OK ] git 插件已安装
[ OK ] chmod 插件已安装
[ OK ] 已添加 y 命令到 .zshrc
```

> **提示:** `y` 命令是 Yazi 的 shell wrapper，退出 Yazi 后会自动 `cd` 到最后浏览的目录。

### 5.3 Lazygit — 终端 Git UI

```bash
./install.sh lazygit
```

会同时安装 `git-delta`（语法高亮 diff），写入推荐配置并配置 Git Delta 全局设置：

```
[ OK ] Lazygit 安装完成
[ OK ] delta (语法高亮 diff) 安装完成
[ OK ] Lazygit 配置已写入
[ OK ] Git Delta 全局配置已写入
```

### 5.4 Claude Code — AI 编程助手

```bash
./install.sh claude
```

安装后会进入提供商配置流程（详见 [6.1 Claude 提供商配置](#61-claude-提供商配置)），完成后显示使用提示：

```
[INFO] Claude Code 使用提示:
   claude              启动交互式会话
   claude "问题"       直接提问
   claude -p "问题"    非交互模式 (管道友好)
   首次使用需要登录:    claude login
```

### 5.5 OpenClaw — 本地 AI 助手

```bash
./install.sh openclaw
```

macOS 上会额外询问是否安装桌面应用版本：

```
是否安装 OpenClaw 桌面应用? [y/N]:
```

### 5.6 Hermes Agent — 自学习 AI Agent

```bash
./install.sh hermes
```

如果检测到已有 OpenClaw 数据，会询问是否迁移：

```
检测到 OpenClaw 数据，是否迁移到 Hermes? [y/N]:
```

安装后使用提示：

```
   hermes              启动交互式会话
   hermes setup        运行完整设置向导
   hermes model        选择 LLM 提供商和模型
   hermes tools        配置可用工具
   hermes gateway      启动消息网关 (Telegram/Discord 等)
   hermes update       更新到最新版本
```

### 5.7 Antigravity — Google AI 开发平台

```bash
./install.sh antigravity
```

> **注意:** Antigravity 仅支持 macOS 和 Windows，Linux 上会跳过安装。

### 5.8 OrbStack / Docker — 容器工具

```bash
./install.sh orbstack
```

| 平台 | 实际安装 | 安装方式 |
|------|---------|---------|
| macOS | OrbStack | `brew install --cask orbstack` |
| Linux | Docker Engine | 包管理器 / `get.docker.com` 脚本 |
| Windows | Docker Desktop | `winget install Docker.DockerDesktop` |

### 5.9 Obsidian — 知识管理工具

```bash
./install.sh obsidian
```

安装后会询问 Excalidraw 插件的 Vault 路径：

```
请选择 Obsidian Vault 路径 (Excalidraw 插件将安装到此 Vault):
  1) 默认路径: ~/Obsidian
  2) 自定义路径
  3) 跳过插件安装
请输入选项 [1/2/3] (默认 1):
```

### 5.10 Maccy / Ditto / CopyQ — 剪贴板管理

```bash
./install.sh maccy
```

| 平台 | 实际安装 | 默认快捷键 |
|------|---------|-----------|
| macOS | Maccy | `Cmd+Shift+C` |
| Linux | CopyQ | `Ctrl+Shift+V` |
| Windows | Ditto | `Ctrl+`` `（也可用 `Win+V`） |

### 5.11 JDK — Java 开发工具包

```bash
./install.sh jdk
```

macOS/Linux 通过 SDKMAN 安装，Windows 通过 winget/scoop 安装：

```
选择 JDK 版本 (Eclipse Temurin):
  1) JDK 21 (LTS，推荐)
  2) JDK 17 (LTS)
  3) JDK 11 (LTS)
  4) JDK 8  (LTS)
  5) 跳过 (仅安装 SDKMAN)
请输入选项 [1-5] (默认 1):
```

macOS/Linux JDK 管理命令：

```bash
java -version            # 查看当前版本
sdk list java            # 查看可用版本
sdk install java <ver>   # 安装指定版本
sdk use java <ver>       # 临时切换版本
sdk default java <ver>   # 设置默认版本
```

Windows JDK 管理命令：

```powershell
java -version                         # 查看当前版本
scoop install temurin17-jdk           # 安装其他版本
scoop reset temurin21-jdk             # 切换默认版本
```

### 5.12 VS Code — 代码编辑器

```bash
./install.sh vscode
```

安装后自动完成以下配置：

```
[ OK ] Catppuccin 主题安装完成
[ OK ] Catppuccin Icons 安装完成
[ OK ] 中文语言包安装完成
[ OK ] Claude Code 插件安装完成
[ OK ] 已切换 VS Code 界面语言为中文 (argv.json)
[ OK ] 已创建 VS Code settings.json (Catppuccin Latte + 中文)
```

自动安装的扩展：
- `Catppuccin.catppuccin-vsc` — Catppuccin Latte 主题
- `Catppuccin.catppuccin-vsc-icons` — Catppuccin 图标主题
- `MS-CEINTL.vscode-language-pack-zh-hans` — 中文语言包
- `anthropic.claude-code` — Claude Code 插件

### 组合安装示例

```bash
# 终端三件套：Ghostty + Yazi + Lazygit
./install.sh ghostty yazi lazygit

# AI 工具全家桶
./install.sh claude openclaw hermes antigravity

# 开发者基础套件
./install.sh ghostty yazi lazygit claude vscode

# Java 开发者
./install.sh ghostty lazygit jdk vscode

# 最小安装（仅终端和文件管理）
./install.sh ghostty yazi

# 使用国内镜像安装多个工具
./install.sh --mirror ghostty yazi claude vscode
```

```powershell
# Windows: 终端三件套
.\install.ps1 ghostty yazi lazygit

# Windows: 使用镜像安装全部
.\install.ps1 --mirror --all
```

---

## 6. 配置管理

### 6.1 Claude 提供商配置

安装 Claude Code 时会自动触发提供商配置，也可以随时单独运行：

```bash
# macOS / Linux
./install.sh claude-provider
```

```powershell
# Windows
.\install.ps1 claude-provider
```

#### 方式一：Anthropic 直连

最简单的方式，使用 Anthropic 官方 API Key。

```
  请输入选项 [0-5]: 1

[INFO] 配置 Anthropic 直连...
  Anthropic API Key: sk-ant-api03-xxxxxxxxxxxx
[ OK ] Anthropic 直连已配置 (Key: sk-ant-a...xxxx)
```

macOS/Linux 写入 `~/.zshrc`：

```bash
# >>> Claude Code Provider Config >>>
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxxxxxxxxx"
# <<< Claude Code Provider Config <<<
```

Windows 写入用户环境变量 + `~/.claude/settings.json`。

#### 方式二：Amazon Bedrock

支持两种认证方式：

**方式 2a — AWS Access Key：**

```
  请输入选项 [0-5]: 2

  认证方式:
    a) AWS Access Key (AK/SK)
    b) AWS Profile (~/.aws/credentials)

  选择认证方式 [a/b]: a
  AWS Region [us-east-1]: us-east-1
  AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
  AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  AWS Session Token (可选, 回车跳过):

[ OK ] Amazon Bedrock 已配置 (AK: AKIA...MPLE, Region: us-east-1)
```

macOS/Linux 写入 `~/.zshrc`：

```bash
# >>> Claude Code Provider Config >>>
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
# <<< Claude Code Provider Config <<<
```

**方式 2b — AWS Profile：**

```
  选择认证方式 [a/b]: b
  AWS Region [us-east-1]: us-west-2
  AWS Profile 名称 [default]: my-bedrock-profile

[ OK ] Amazon Bedrock 已配置 (Profile: my-bedrock-profile, Region: us-west-2)
```

macOS/Linux 写入 `~/.zshrc`：

```bash
# >>> Claude Code Provider Config >>>
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION="us-west-2"
export AWS_PROFILE="my-bedrock-profile"
# <<< Claude Code Provider Config <<<
```

> **提示:** 使用 AWS Profile 方式需要先在 `~/.aws/credentials` 中配置好对应的 Profile。

#### 方式三：Google Vertex AI

```
  请输入选项 [0-5]: 3

  GCP 项目 ID: my-gcp-project
  GCP Region [us-east5]: us-east5

[ OK ] Google Vertex AI 已配置 (项目: my-gcp-project, Region: us-east5)

[INFO] 提示: 请确保已通过 gcloud auth application-default login 完成认证
```

macOS/Linux 写入 `~/.zshrc`：

```bash
# >>> Claude Code Provider Config >>>
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION="us-east5"
export ANTHROPIC_VERTEX_PROJECT_ID="my-gcp-project"
# <<< Claude Code Provider Config <<<
```

> **注意:** 使用 Vertex AI 前必须完成 GCP 认证：
> ```bash
> gcloud auth application-default login
> ```

#### 方式四：自定义 API 代理

适用于 OpenRouter、API 中转站等第三方代理。

```
  请输入选项 [0-5]: 4

  API Base URL (例: https://openrouter.ai/api/v1): https://my-proxy.example.com/v1
  API Key: sk-xxxxxxxx

[ OK ] 自定义 API 代理已配置 (URL: https://my-proxy.example.com/v1, Key: sk-xxxxx...xxxx)
```

macOS/Linux 写入 `~/.zshrc`：

```bash
# >>> Claude Code Provider Config >>>
export ANTHROPIC_BASE_URL="https://my-proxy.example.com/v1"
export ANTHROPIC_API_KEY="sk-xxxxxxxx"
# <<< Claude Code Provider Config <<<
```

#### 清除配置

选择选项 5 将移除所有已有的提供商配置：

```
  请输入选项 [0-5]: 5

[ OK ] 已清除 Claude 提供商配置
```

> **提示:** 重复运行提供商配置会替换旧配置，不会累加。macOS/Linux 上通过 `~/.zshrc` 中的标记块 `>>> Claude Code Provider Config >>>` 定位并替换。Windows 上通过清除旧的用户环境变量再写入新值实现。

### 6.2 Shell 提示符配置

Shell 提示符在安装 Ghostty 时自动触发配置，不单独提供命令行入口。

#### macOS / Linux — Oh My Zsh (默认选项 1)

```bash
# 安装 Ghostty 时选择提示符方案 1
./install.sh ghostty
# 选择 1) Oh My Zsh + 插件
```

自动完成：
- 安装 Oh My Zsh
- 安装 zsh-autosuggestions 插件
- 安装 zsh-syntax-highlighting 插件
- 配置写入 `~/.zshrc` 的 `plugins=()` 行

#### macOS / Linux — Starship (选项 2)

```bash
# 安装 Ghostty 时选择提示符方案 2
./install.sh ghostty
# 选择 2) Starship
```

自动完成：
- 安装 Starship
- 安装 Nerd Font（可选 Hack/JetBrainsMono/FiraCode/MesloLG/CascadiaCode）
- 下载 Starship 主题（可选 10 种主题）
- 安装 zsh-autosuggestions 和 zsh-syntax-highlighting 插件
- 配置写入 `~/.config/starship.toml` 和 `~/.zshrc`

#### Windows — Starship (选项 1)

```powershell
.\install.ps1 ghostty
# 选择 1) Starship
```

自动完成：
- 通过 Scoop 安装 Starship
- 安装 Nerd Font（通过 scoop nerd-fonts bucket）
- 下载 Starship 主题
- 初始化命令写入 PowerShell Profile

#### Windows — Oh My Posh (选项 2)

```powershell
.\install.ps1 ghostty
# 选择 2) Oh My Posh
```

自动完成：
- 通过 Scoop 安装 Oh My Posh
- 初始化命令写入 PowerShell Profile

### 6.3 VS Code 自动配置说明

安装 VS Code 时自动完成以下配置，无需手动操作：

| 配置项 | 说明 |
|--------|------|
| Catppuccin Latte 主题 | `workbench.colorTheme: "Catppuccin Latte"` |
| Catppuccin 图标主题 | `workbench.iconTheme: "catppuccin-latte"` |
| 中文语言 | `locale: "zh-cn"` (写入 settings.json + argv.json) |
| Claude Code 插件 | `anthropic.claude-code` 扩展 |
| 中文语言包 | `MS-CEINTL.vscode-language-pack-zh-hans` 扩展 |

配置文件位置（参见 [第 10 节](#10-配置文件速查表)）：

```bash
# macOS
~/Library/Application Support/Code/User/settings.json    # 主设置
~/.vscode/argv.json                                       # 语言设置

# Linux
~/.config/Code/User/settings.json
~/.vscode/argv.json

# Windows
%APPDATA%\Code\User\settings.json
%USERPROFILE%\.vscode\argv.json
```

> **注意:** 如果已有 settings.json，脚本会通过 sed (macOS/Linux) 或字符串替换 (Windows) 在现有文件中添加/修改主题和语言设置，不会覆盖其他自定义配置。
>
> argv.json 采用重建方式处理，会保留 `crash-reporter-id` 字段。Windows 上使用无 BOM 的 UTF-8 编码写入，避免 VS Code 报错。

---

## 7. 卸载操作

### 7.1 交互式卸载

#### macOS / Linux

```bash
./install.sh --uninstall
```

脚本会自动检测已安装的工具并列出：

```
================================================
   开发工具卸载
================================================

  1) Ghostty
  2) Yazi
  3) Lazygit
  4) Claude Code
  5) VS Code

  A) 全部卸载
  Q) 取消

请输入编号 (多选用逗号分隔): 1,2

[WARN] 即将卸载: ghostty yazi
确认卸载? [y/N]: y

[INFO] 卸载 Ghostty...
[ OK ] Ghostty 已卸载
[INFO] 卸载 Yazi...
[ OK ] Yazi 已卸载

卸载完成
```

#### Windows

```powershell
.\install.ps1 --uninstall
```

Windows 版还会检测基础环境工具（Git、Node.js、NVM、Bun、Starship、Oh My Posh、Git Delta），分为「应用工具」和「基础环境」两组显示：

```
================================================
   Windows 开发工具卸载
================================================

  --- 应用工具 ---
  1) Ghostty
  2) Yazi
  3) Lazygit
  4) Claude Code
  5) VS Code
  --- 基础环境 ---
  6) Git
  7) Node.js
  8) NVM
  9) Bun

  A) 全部卸载
  Q) 取消

请输入编号 (多选用逗号分隔):
```

### 7.2 命令行卸载（远程）

```bash
# macOS / Linux (短链接)
curl -fsSL https://tinyurl.com/25n5uezk | bash -s -- --uninstall

# macOS / Linux (国内加速)
curl -fsSL https://tinyurl.com/2xrksrcy | bash -s -- --uninstall
```

```powershell
# Windows
irm https://tinyurl.com/25pho3w9 -OutFile $env:TEMP\i.ps1; & $env:TEMP\i.ps1 --uninstall
```

### 卸载详细行为

| 工具 | macOS 卸载 | Linux 卸载 | Windows 卸载 |
|------|-----------|-----------|-------------|
| Ghostty | `brew uninstall --cask ghostty` + 删除配置 | `brew uninstall ghostty` + 删除配置 | winget 卸载 + 删除配置 |
| Yazi | `brew uninstall yazi` + 删除配置 | 同 macOS | scoop 卸载 + 删除配置 |
| Lazygit | `brew uninstall lazygit` + 删除配置 | 同 macOS | scoop 卸载 + 删除配置 |
| Claude Code | 删除 `~/.local/bin/claude` + npm 卸载 | 同 macOS | npm 卸载 / 删除安装目录 |
| VS Code | `brew uninstall --cask` + 删除配置 | apt/dnf/snap 卸载 + 删除配置 | winget/scoop 卸载 / 手动卸载 + 删除配置 |
| JDK | SDKMAN 卸载 | 同 macOS | scoop/winget 卸载 |
| Docker | `brew uninstall --cask orbstack` | apt/dnf/pacman 卸载 | winget 卸载 Docker Desktop |

> **注意:** 卸载工具时会同时删除对应的配置文件目录（如 `~/.config/ghostty`、`~/.config/yazi` 等）。

---

## 8. 国内镜像加速

### 自动检测

脚本启动时会自动检测 GitHub 连通性（3 秒超时），不可达时提示启用镜像：

```
检测网络环境...
[WARN] GitHub 连接缓慢或不可用
是否使用国内镜像加速? [Y/n]:
```

如果 GitHub 连接正常，也可以选择启用：

```
检测网络环境...
[ OK ] GitHub 连接正常
是否仍要使用国内镜像加速? [y/N]:
```

### 强制启用

```bash
# macOS / Linux
./install.sh --mirror

# 远程一键安装 (国内加速短链接)
curl -fsSL https://tinyurl.com/2xrksrcy | bash
```

```powershell
# Windows
.\install.ps1 --mirror

# 远程一键安装 (国内加速短链接)
irm https://tinyurl.com/25pho3w9 | iex
```

### 加速内容

| 加速项 | 镜像源 | 平台 |
|--------|--------|------|
| GitHub 文件下载 | `ghfast.top` URL 前缀代理 | macOS / Linux / Windows |
| Homebrew 安装源 | USTC (中科大) | macOS / Linux |
| Homebrew Bottle | USTC (中科大) | macOS / Linux |
| Node.js 下载 | npmmirror | macOS / Linux |
| npm registry | npmmirror | macOS / Linux |

> **提示:** 镜像模式下所有 GitHub 资源（NVM 安装脚本、Nerd Font 字体、Oh My Zsh、Hermes Agent 安装脚本等）都会自动通过 `ghfast.top` 代理下载。

---

## 9. 常见问题 (FAQ)

### Q1: Windows 上 Scoop 安装失败

**现象：**

```
[ERR ] Scoop 安装失败 (网络超时)，请手动安装: https://scoop.sh
```

**解决方案：**

1. 确保 PowerShell 执行策略允许运行脚本：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   ```

2. 手动安装 Scoop：
   ```powershell
   irm get.scoop.sh | iex
   ```

3. 如果是网络问题，使用镜像模式重新运行：
   ```powershell
   .\install.ps1 --mirror
   ```

4. 如果以管理员身份运行，Scoop 安装脚本需要 `-RunAsAdmin` 参数（脚本已自动处理）。

### Q2: GitHub 连接超时

**现象：**

```
[WARN] GitHub 连接缓慢或不可用
```

**解决方案：**

1. 使用国内加速链接一键安装：
   ```bash
   # macOS / Linux
   curl -fsSL https://tinyurl.com/2xrksrcy | bash
   ```
   ```powershell
   # Windows
   irm https://tinyurl.com/25pho3w9 | iex
   ```

2. 本地安装时使用 `--mirror` 参数：
   ```bash
   ./install.sh --mirror
   ```

3. 如果使用代理，确保终端已设置 HTTP_PROXY 环境变量：
   ```bash
   export HTTP_PROXY=http://127.0.0.1:7890
   export HTTPS_PROXY=http://127.0.0.1:7890
   ```

### Q3: VS Code 版本不兼容 (Windows)

**现象：**

```
[WARN] 安装程序退出码: 非0，可能版本不兼容
[WARN] 可能原因: Windows 版本不兼容 (需要 Win10 1709+ 或 Win11)
```

**解决方案：**

1. 检查 Windows 版本是否满足要求（Windows 10 1709 或更高版本）。

2. ARM Mac 虚拟机用户需要下载 ARM64 版本：
   ```
   https://code.visualstudio.com/Download
   ```

3. 旧版 Windows 可下载 VS Code 1.83（最后一个兼容版本）：
   ```powershell
   # x64
   https://update.code.visualstudio.com/1.83.1/win32-x64-user/stable
   # ARM64
   https://update.code.visualstudio.com/1.83.1/win32-arm64-user/stable
   ```

4. 脚本会依次尝试三种安装方式：
   - 微软 CDN 直接下载安装
   - winget 安装（60 秒超时）
   - scoop 安装（60 秒超时）

### Q4: argv.json 报错

**现象：**

VS Code 启动时提示 argv.json 解析错误，或中文语言未生效。

**解决方案：**

argv.json 是 JSONC 格式（JSON with Comments），脚本使用重建方式处理以避免格式损坏。

1. macOS/Linux 手动修复：
   ```bash
   # 重建 argv.json
   cat > ~/.vscode/argv.json << 'EOF'
   {
       "locale": "zh-cn"
   }
   EOF
   ```

2. Windows 手动修复（必须使用无 BOM 的 UTF-8）：
   ```powershell
   $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
   $json = '{ "locale": "zh-cn" }'
   [System.IO.File]::WriteAllText("$env:USERPROFILE\.vscode\argv.json", $json, $utf8NoBom)
   ```

> **注意:** Windows 上 PowerShell 默认的 `Set-Content -Encoding UTF8` 会写入 BOM 头，VS Code 无法解析带 BOM 的 argv.json，因此脚本使用 `[System.IO.File]::WriteAllText` 方式写入。

### Q5: 中文不生效

**现象：**

VS Code 安装中文语言包后界面仍然是英文。

**解决方案：**

1. 确认 argv.json 中的 locale 设置正确：
   ```bash
   # macOS / Linux
   cat ~/.vscode/argv.json
   # 应包含: "locale": "zh-cn"
   ```
   ```powershell
   # Windows
   Get-Content $env:USERPROFILE\.vscode\argv.json
   ```

2. 确认 settings.json 中也有 locale 设置：
   ```bash
   # macOS
   cat ~/Library/Application\ Support/Code/User/settings.json | grep locale
   # Linux
   cat ~/.config/Code/User/settings.json | grep locale
   ```
   ```powershell
   # Windows
   Get-Content $env:APPDATA\Code\User\settings.json | Select-String locale
   ```

3. 重启 VS Code。如仍不生效，在 VS Code 中按 `Ctrl+Shift+P`（macOS 为 `Cmd+Shift+P`），输入 `Configure Display Language`，选择 `zh-cn`。

### Q6: brew 安装反复失败

**现象：**

```
[ERR ] xxx 安装失败 (第 3/3 次)
[ERR ] xxx 安装失败，已跳过。可稍后手动运行: brew install xxx
```

**解决方案：**

脚本内置了 brew 安装的重试机制（最多 3 次），每次失败会自动清理锁文件和僵尸进程。如果仍然失败：

1. 手动清理 Homebrew 缓存：
   ```bash
   brew cleanup
   brew doctor
   ```

2. 手动安装失败的包：
   ```bash
   brew install <package-name>
   ```

3. 如果是网络原因，使用 `--mirror` 参数启用 USTC 镜像：
   ```bash
   ./install.sh --mirror <tool>
   ```

### Q7: macOS 上 SDKMAN 安装失败

**现象：**

SDKMAN 安装脚本报错，提示 Bash 版本过低。

**解决方案：**

macOS 自带的 Bash 版本是 3.2（因许可证限制），而 SDKMAN 需要 Bash 4+。脚本会自动通过 Homebrew 安装新版 Bash：

```
[INFO] SDKMAN 需要 Bash 4+，正在通过 Homebrew 安装新版 Bash...
```

如果自动安装失败，可手动操作：

```bash
brew install bash
# 然后重新运行
./install.sh jdk
```

### Q8: Linux 上 Ghostty 安装失败

**现象：**

Ghostty 在 Linux 上通过原生包管理器安装失败。

**解决方案：**

脚本会依次尝试原生包管理器和 Homebrew (Linuxbrew)：
- Ubuntu/Debian: 尝试 snap
- Fedora: 尝试 dnf
- Arch: 尝试 pacman

如果都失败，会回退到 `brew install ghostty`。如果仍然失败，请从官方网站手动下载：

```
https://ghostty.org/download
```

---

## 10. 配置文件速查表

### 三平台路径对比

| 配置文件 | macOS | Linux | Windows |
|----------|-------|-------|---------|
| **Ghostty 配置** | `~/.config/ghostty/config` | `~/.config/ghostty/config` | `%APPDATA%\ghostty\config` |
| **Yazi 主配置** | `~/.config/yazi/yazi.toml` | `~/.config/yazi/yazi.toml` | `%APPDATA%\yazi\config\yazi.toml` |
| **Yazi 快捷键** | `~/.config/yazi/keymap.toml` | `~/.config/yazi/keymap.toml` | `%APPDATA%\yazi\config\keymap.toml` |
| **Yazi 主题** | `~/.config/yazi/theme.toml` | `~/.config/yazi/theme.toml` | `%APPDATA%\yazi\config\theme.toml` |
| **Yazi 插件** | `~/.config/yazi/init.lua` | `~/.config/yazi/init.lua` | `%APPDATA%\yazi\config\init.lua` |
| **Lazygit 配置** | `~/.config/lazygit/config.yml` | `~/.config/lazygit/config.yml` | `%APPDATA%\lazygit\config.yml` |
| **Starship 配置** | `~/.config/starship.toml` | `~/.config/starship.toml` | `%USERPROFILE%\.config\starship.toml` |
| **VS Code 设置** | `~/Library/Application Support/Code/User/settings.json` | `~/.config/Code/User/settings.json` | `%APPDATA%\Code\User\settings.json` |
| **VS Code 语言** | `~/.vscode/argv.json` | `~/.vscode/argv.json` | `%USERPROFILE%\.vscode\argv.json` |
| **Claude 提供商** | `~/.zshrc` (标记块) | `~/.zshrc` (标记块) | 用户环境变量 + `%USERPROFILE%\.claude\settings.json` |
| **Shell 配置** | `~/.zshrc` | `~/.zshrc` | `$PROFILE.CurrentUserAllHosts` |
| **Oh My Zsh** | `~/.oh-my-zsh/` | `~/.oh-my-zsh/` | - |
| **NVM 目录** | `~/.nvm/` | `~/.nvm/` | `%APPDATA%\nvm\` |
| **SDKMAN 目录** | `~/.sdkman/` | `~/.sdkman/` | - |
| **Hermes 数据** | `~/.hermes/` | `~/.hermes/` | `%USERPROFILE%\.hermes\` |
| **Obsidian Vault** | `~/Obsidian/` (默认) | `~/Obsidian/` (默认) | `%USERPROFILE%\Obsidian\` (默认) |
| **Nerd Font** | brew cask 管理 | `~/.local/share/fonts/` | scoop nerd-fonts bucket |

### 包管理器对比

| 包管理器 | macOS | Linux | Windows |
|----------|-------|-------|---------|
| 主要 | Homebrew | Homebrew (Linuxbrew) | Scoop |
| 辅助 | - | apt / dnf / pacman / zypper / yum | winget |
| GUI 应用 | `brew install --cask` | flatpak / snap | winget / scoop extras |
| JDK 管理 | SDKMAN | SDKMAN | winget / scoop java bucket |

### Ghostty 快捷键对比

| 功能 | macOS | Linux / Windows |
|------|-------|-----------------|
| 全局唤出 | `Ctrl+`` ` | `Ctrl+`` ` |
| 新标签页 | `Cmd+T` | `Ctrl+Shift+T` |
| 关闭标签页 | `Cmd+W` | `Ctrl+Shift+W` |
| 右侧分屏 | `Cmd+D` | `Ctrl+Shift+D` |
| 下方分屏 | `Cmd+Shift+D` | `Ctrl+Shift+E` |
| 上一标签页 | `Cmd+Shift+Left` | `Ctrl+Shift+Left` |
| 下一标签页 | `Cmd+Shift+Right` | `Ctrl+Shift+Right` |
| 分屏导航 (左) | `Cmd+Alt+Left` | `Ctrl+Shift+H` |
| 分屏导航 (右) | `Cmd+Alt+Right` | `Ctrl+Shift+L` |
| 分屏导航 (上) | `Cmd+Alt+Up` | `Ctrl+Shift+K` |
| 分屏导航 (下) | `Cmd+Alt+Down` | `Ctrl+Shift+J` |
| 均分分屏 | `Cmd+Shift+E` | - |
| 分屏全屏 | `Cmd+Shift+F` | - |
| 放大字号 | `Cmd++` | `Ctrl++` |
| 缩小字号 | `Cmd+-` | `Ctrl+-` |
| 重置字号 | `Cmd+0` | `Ctrl+0` |
| 重载配置 | `Cmd+Shift+,` | - |

### Yazi 快捷键速查

| 快捷键 | 功能 |
|--------|------|
| `y` | 启动 Yazi（退出后 cd 到浏览目录，需 shell wrapper） |
| `.` | 显示 / 隐藏隐藏文件 |
| `gd` | 跳转到 `~/Downloads` |
| `gD` | 跳转到 `~/Desktop` |
| `gc` | 跳转到 `~/.config` |
| `gp` | 跳转到 `~/Projects` |
| `gh` | 跳转到 Home 目录 |
| `T` | 在 Ghostty 中打开当前目录 (macOS/Linux) |
| `C` | 在 VS Code 中打开当前目录 |
| `S` | 在当前目录打开 Shell |

### Lazygit 自定义快捷键

| 快捷键 | 功能 |
|--------|------|
| `O` | 在浏览器中打开仓库 (`gh browse`) |
| `F` | 创建 fixup commit |
| `Y` | 复制分支名到剪贴板 |

---

## 附录：支持的工具完整列表

| 编号 | 工具名 | 参数名 | macOS 安装方式 | Linux 安装方式 | Windows 安装方式 |
|------|--------|--------|---------------|---------------|-----------------|
| 1 | Ghostty | `ghostty` | brew cask | 包管理器/snap/brew | winget |
| 2 | Yazi | `yazi` | brew | brew | scoop |
| 3 | Lazygit | `lazygit` | brew | brew | scoop |
| 4 | Claude Code | `claude` | 官方脚本/brew cask/npm | 官方脚本/npm | 官方脚本/npm/winget |
| 5 | OpenClaw | `openclaw` | brew (CLI + cask) | brew | winget |
| 6 | Hermes Agent | `hermes` | 官方脚本 | 官方脚本 | 官方脚本 |
| 7 | Antigravity | `antigravity` | brew cask | 不支持 | winget |
| 8 | OrbStack/Docker | `orbstack` | OrbStack (brew cask) | Docker Engine | Docker Desktop (winget) |
| 9 | Obsidian | `obsidian` | brew cask | flatpak/snap | winget/scoop |
| 10 | Maccy/CopyQ/Ditto | `maccy` | Maccy (brew cask) | CopyQ (原生包管理器) | Ditto (winget/scoop) |
| 11 | JDK | `jdk` | SDKMAN | SDKMAN | winget/scoop |
| 12 | VS Code | `vscode` | brew cask | apt/dnf/snap/brew | CDN 下载/winget/scoop |
