# ============================================================
# Windows 开发工具一键安装与配置
# 支持: Ghostty / Yazi / Lazygit / Claude Code / OpenClaw / Hermes Agent / Docker Desktop / Obsidian / Ditto / JDK / VS Code
# 用法:
#   全部安装:  .\install.ps1
#   选择安装:  .\install.ps1 ghostty yazi lazygit claude openclaw hermes orbstack obsidian maccy jdk vscode
#   查看帮助:  .\install.ps1 --help
# 要求: Windows 10+ / PowerShell 5.1+
# ============================================================

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ── 颜色输出 ──────────────────────────────────────────
function Info  { param([string]$msg) Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Ok    { param([string]$msg) Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Warn  { param([string]$msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Err   { param([string]$msg) Write-Host "[ERR ] $msg" -ForegroundColor Red }

# ── 系统检测 ─────────────────────────────────────────
$ARCH = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# ── 国内加速配置 ──────────────────────────────────────
$script:USE_MIRROR = $false
$script:GITHUB_PROXY = ""

function Setup-Mirror {
    if (-not $script:USE_MIRROR) {
        Write-Host ""
        Write-Host "检测网络环境..." -ForegroundColor White -NoNewline
        try {
            $null = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/github/gitignore/main/README.md" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
            Ok "GitHub 连接正常"
            $choice = Read-Host "是否仍要使用国内镜像加速? [y/N]"
            if ($choice -match '^[yY]$') { $script:USE_MIRROR = $true }
        } catch {
            Warn "GitHub 连接缓慢或不可用"
            $choice = Read-Host "是否使用国内镜像加速? [Y/n]"
            if ($choice -notmatch '^[nN]$') { $script:USE_MIRROR = $true }
        }
    }

    if ($script:USE_MIRROR) {
        $script:GITHUB_PROXY = "https://ghfast.top/"

        # 给 git 设置代理，让 scoop bucket add 等 git 操作也能走加速
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git config --global http.proxy $script:GITHUB_PROXY 2>$null
            git config --global https.proxy $script:GITHUB_PROXY 2>$null
        }
        # 禁止 git 弹出凭据对话框 (避免超时后弹窗)
        $env:GIT_TERMINAL_PROMPT = "0"

        Ok "已启用国内镜像加速"
        Info "  GitHub 代理: $($script:GITHUB_PROXY)"
    }
}

function GitHub-RawUrl {
    param([string]$url)
    if ($script:USE_MIRROR) { return "$($script:GITHUB_PROXY)$url" }
    return $url
}

# ── 帮助信息 ──────────────────────────────────────────
function Show-Help {
    @"
Windows 开发工具一键安装脚本

用法:
  .\install.ps1                 交互式选择要安装的工具
  .\install.ps1 --all           安装全部工具
  .\install.ps1 --skip          跳过工具安装，仅修改配置
  .\install.ps1 --mirror        强制使用国内镜像加速
  .\install.ps1 <tool> ...      只安装指定工具

可选工具:
  ghostty          GPU 加速终端模拟器
  yazi             终端文件管理器
  lazygit          终端 Git UI
  claude           Claude Code (AI 编程助手)
  openclaw         OpenClaw (本地 AI 助手)
  hermes           Hermes Agent (Nous Research 自学习 AI Agent)
  antigravity      Google Antigravity (AI 开发平台)
  orbstack         Docker Desktop (容器 & Kubernetes)
  obsidian         Obsidian (知识管理 & 笔记工具)
  maccy            Ditto (剪贴板管理工具, Maccy 替代)
  jdk              JDK (通过 winget/scoop 安装)
  vscode           VS Code (代码编辑器 + Catppuccin 主题)
  claude-provider  仅修改 Claude API 提供商配置

示例:
  .\install.ps1 ghostty yazi          只安装 Ghostty 和 Yazi
  .\install.ps1 claude openclaw       只安装 AI 工具
  .\install.ps1 claude-provider       仅切换 Claude 提供商
  .\install.ps1 --skip                跳过安装，进入配置菜单
  .\install.ps1 --all                 全部安装
"@
    exit 0
}

# ── 工具定义 ──────────────────────────────────────────
$ALL_TOOLS = @("ghostty", "yazi", "lazygit", "claude", "openclaw", "hermes", "antigravity", "orbstack", "obsidian", "maccy", "jdk", "vscode")
$script:SELECTED_TOOLS = @()
$script:SKIP_PREREQUISITES = $false

# ── 包管理器辅助 ──────────────────────────────────────
function Ensure-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Ok "Scoop 已安装"
        return
    }
    Info "正在安装 Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Invoke-Expression "& {$(Invoke-RestMethod get.scoop.sh)} -RunAsAdmin"
    } else {
        Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
    }
    # 刷新 PATH 确保 scoop 命令立即可用
    Refresh-Path
    $scoopShim = "$env:USERPROFILE\scoop\shims"
    if (Test-Path $scoopShim) { $env:Path = "$scoopShim;$env:Path" }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Ok "Scoop 安装完成"
    } else {
        Err "Scoop 安装后命令不可用，请关闭终端重新运行脚本"
        exit 1
    }
}

function Ensure-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Ok "winget 已可用"
        return $true
    }
    Warn "winget 不可用 (Windows 10 需要手动安装 App Installer)"
    return $false
}

function Winget-Install {
    param(
        [string]$Id,
        [string]$Name,
        [switch]$Interactive
    )

    $installed = winget list --id $Id 2>$null | Select-String $Id
    if ($installed) {
        Ok "$Name 已安装"
        return
    }

    Info "正在安装 $Name ..."
    $wingetArgs = @("install", "--id", $Id, "--accept-source-agreements", "--accept-package-agreements")
    if (-not $Interactive) { $wingetArgs += "--silent" }

    & winget @wingetArgs 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Ok "$Name 安装完成"
    } else {
        Err "$Name 安装失败"
    }
}

function Scoop-Install {
    param(
        [string]$Package,
        [string]$Name,
        [string]$Bucket
    )

    if (scoop list $Package 2>$null | Select-String $Package) {
        Ok "$Name 已安装 (scoop)"
        return
    }

    if ($Bucket) {
        scoop bucket add $Bucket 2>$null
    }

    Info "正在安装 $Name (scoop)..."
    scoop install $Package
    if ($LASTEXITCODE -eq 0) {
        Ok "$Name 安装完成"
    } else {
        Err "$Name 安装失败"
    }
}

# ── 交互式多选菜单 (数字输入，兼容 irm | iex) ───────
function Interactive-Select {
    $labels = @(
        " 1) Ghostty      GPU 加速终端模拟器 (毛玻璃/分屏/Quake 下拉)"
        " 2) Yazi         终端文件管理器 (快速预览/Vim 风格导航)"
        " 3) Lazygit      终端 Git UI (可视化提交/分支/合并)"
        " 4) Claude Code  Anthropic AI 编程助手 (终端内 AI 编程)"
        " 5) OpenClaw     本地 AI 助手 (自托管/任务自动化)"
        " 6) Hermes       Nous Research 自学习 AI Agent (技能/记忆/多平台)"
        " 7) Antigravity  Google AI 开发平台 (智能编码/Agent 工作流)"
        " 8) Docker       Docker Desktop (容器 & Kubernetes)"
        " 9) Obsidian     知识管理 & 笔记工具 (Markdown/双链/插件)"
        "10) Ditto        剪贴板管理工具 (Maccy 替代, 开源/快捷搜索)"
        "11) JDK          Java 开发工具包 (多版本切换)"
        "12) VS Code      代码编辑器 (Catppuccin 主题/扩展自动安装)"
    )

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Windows 开发工具一键安装与配置           ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    foreach ($label in $labels) {
        Write-Host "  $label" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "  A) 全部安装" -ForegroundColor Green
    Write-Host "  S) 跳过安装，仅修改配置" -ForegroundColor Yellow
    Write-Host "  Q) 退出" -ForegroundColor Red
    Write-Host ""
    $input = Read-Host "请输入编号 (多选用逗号分隔, 例: 1,3,4)"

    if (-not $input -or $input -match '^[qQ]$') {
        Write-Host "已取消。"
        exit 0
    }

    if ($input -match '^[aA]$') {
        $script:SELECTED_TOOLS = @() + $ALL_TOOLS
        return
    }

    if ($input -match '^[sS]$') {
        $script:SKIP_PREREQUISITES = $true
        $script:SELECTED_TOOLS = @()
        Info "跳过工具安装，进入配置菜单"
        return
    }

    # 解析逗号分隔的编号
    $nums = $input -split '[,\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
    foreach ($num in $nums) {
        $idx = [int]$num - 1
        if ($idx -ge 0 -and $idx -lt $ALL_TOOLS.Count) {
            if ($ALL_TOOLS[$idx] -notin $script:SELECTED_TOOLS) {
                $script:SELECTED_TOOLS += $ALL_TOOLS[$idx]
            }
        } else {
            Warn "无效编号: $num (有效范围 1-$($ALL_TOOLS.Count))"
        }
    }

    if ($script:SELECTED_TOOLS.Count -eq 0) {
        $script:SKIP_PREREQUISITES = $true
        Info "未选择工具，跳过安装"
    }
}

# ── 解析参数 ──────────────────────────────────────────
function Parse-Args {
    param([string[]]$Arguments)

    if ($Arguments.Count -eq 0) {
        Interactive-Select
        return
    }

    foreach ($arg in $Arguments) {
        switch ($arg) {
            "--help"  { Show-Help }
            "-h"      { Show-Help }
            "--all"   { $script:SELECTED_TOOLS = $ALL_TOOLS; return }
            "-a"      { $script:SELECTED_TOOLS = $ALL_TOOLS; return }
            "--skip"  { $script:SKIP_PREREQUISITES = $true; return }
            "-s"      { $script:SKIP_PREREQUISITES = $true; return }
            "--mirror" { $script:USE_MIRROR = $true }
            "-m"      { $script:USE_MIRROR = $true }
            "claude-provider" {
                $script:SKIP_PREREQUISITES = $true
                $script:SELECTED_TOOLS += "claude-provider"
            }
            { $_ -in @("ghostty","yazi","lazygit","claude","openclaw","hermes","antigravity","orbstack","obsidian","maccy","jdk","vscode") } {
                $script:SELECTED_TOOLS += $_
            }
            default {
                Err "未知选项: $arg"
                Write-Host "运行 .\install.ps1 --help 查看帮助"
                exit 1
            }
        }
    }
}

function Is-Selected {
    param([string]$tool)
    return ($script:SELECTED_TOOLS -contains $tool)
}

function Backup-IfExists {
    param([string]$Path)
    if (Test-Path $Path) {
        $backup = "$Path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Warn "备份已有配置: $Path -> $backup"
        Copy-Item -Path $Path -Destination $backup -Recurse -Force
    }
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# ── PowerShell Profile 辅助 ──────────────────────────
function Ensure-ProfileInit {
    param(
        [string]$InitLine,
        [string]$Name
    )

    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path $profilePath
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Contains($InitLine)) {
        Ok "$Name 已在 PowerShell Profile 中配置"
    } else {
        Add-Content -Path $profilePath -Value "`n# $Name`n$InitLine"
        Ok "$Name 初始化已写入 PowerShell Profile"
    }
}

function Add-ToProfile {
    param(
        [string]$Content,
        [string]$Marker
    )

    $profilePath = $PROFILE.CurrentUserAllHosts
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    $existing = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($existing -and $existing.Contains($Marker)) {
        return $false
    }

    Add-Content -Path $profilePath -Value "`n$Content"
    return $true
}

# ══════════════════════════════════════════════════════
# 环境基础检查 (按依赖顺序: 网络 → 包管理器 → 基础工具 → 运行时 → 配置)
# ══════════════════════════════════════════════════════
function Check-Prerequisites {
    Write-Host ""
    Write-Host "========== 环境基础检查 ==========" -ForegroundColor Cyan
    Write-Host ""

    # ━━ 第一阶段: 网络与包管理器 ━━━━━━━━━━━━━━━━━━━━

    # ── 1. 网络环境检测 ─────────────────────────────
    Setup-Mirror

    # ── 2. 包管理器 ─────────────────────────────────
    $hasWinget = Ensure-Winget
    Ensure-Scoop

    # ── 3. Git (Scoop Bucket 依赖) ──────────────────
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Ok "Git 已安装: $(git --version)"
    } else {
        Info "正在安装 Git..."
        scoop install git
        Refresh-Path
        Ok "Git 安装完成: $(git --version)"
    }

    # ── 4. Git 代理 (镜像模式) ──────────────────────
    if ($script:USE_MIRROR -and (Get-Command git -ErrorAction SilentlyContinue)) {
        git config --global http.proxy $script:GITHUB_PROXY 2>$null
        git config --global https.proxy $script:GITHUB_PROXY 2>$null
        $env:GIT_TERMINAL_PROMPT = "0"
        Ok "Git 代理已设置: $($script:GITHUB_PROXY)"
    }

    # ── 5. Scoop Buckets ────────────────────────────
    $buckets = @("extras", "versions", "nerd-fonts")
    foreach ($bucket in $buckets) {
        $existing = scoop bucket list 2>$null | Select-String $bucket
        if ($existing) {
            Ok "Scoop bucket '$bucket' 已添加"
        } else {
            try {
                scoop bucket add $bucket 2>$null | Out-Null
                Ok "Scoop bucket '$bucket' 添加完成"
            } catch {
                Warn "Scoop bucket '$bucket' 添加失败，部分工具可能无法安装"
            }
        }
    }

    # ━━ 第二阶段: 开发运行时 ━━━━━━━━━━━━━━━━━━━━━━━

    # ── 6. NVM + Node.js ────────────────────────────
    if (Get-Command nvm -ErrorAction SilentlyContinue) {
        Ok "NVM for Windows 已安装"
    } else {
        Info "正在安装 NVM for Windows..."
        scoop install nvm
        Ok "NVM 安装完成"
    }

    Refresh-Path

    if (Get-Command node -ErrorAction SilentlyContinue) {
        Ok "Node.js 已安装: $(node --version)"
    } else {
        if (Get-Command nvm -ErrorAction SilentlyContinue) {
            Info "正在通过 NVM 安装 Node.js LTS..."
            nvm install lts
            nvm use lts
            Ok "Node.js 安装完成"
        } else {
            Info "正在通过 Scoop 安装 Node.js..."
            scoop install nodejs-lts
            Ok "Node.js 安装完成"
        }
    }

    Refresh-Path

    # ── 7. Bun ──────────────────────────────────────
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        Ok "Bun 已安装: $(bun --version)"
    } else {
        Info "正在安装 Bun..."
        scoop install bun
        Ok "Bun 安装完成"
    }

    # ━━ 第三阶段: Shell 提示符配置 (可选) ━━━━━━━━━━━

    Write-Host ""
    Write-Host "请选择 Shell 提示符工具:" -ForegroundColor White
    Write-Host "  1) Starship (跨平台极速提示符，推荐)" -ForegroundColor Cyan
    Write-Host "  2) Oh My Posh (PowerShell 美化方案)" -ForegroundColor Cyan
    Write-Host "  3) 跳过 (保持现有配置)" -ForegroundColor Cyan
    $promptChoice = Read-Host "请输入选项 [1/2/3] (默认 3)"
    if (-not $promptChoice) { $promptChoice = "3" }

    if ($promptChoice -eq "1") {
        # ── Starship ────────────────────────────────────
        if (Get-Command starship -ErrorAction SilentlyContinue) {
            Ok "Starship 已安装"
        } else {
            Info "正在安装 Starship..."
            scoop install starship
            Ok "Starship 安装完成"
        }

        # Nerd Font
        Write-Host ""
        Write-Host "选择 Nerd Font 字体:" -ForegroundColor White
        Write-Host "  1) Hack Nerd Font (推荐)" -ForegroundColor Cyan
        Write-Host "  2) JetBrainsMono Nerd Font" -ForegroundColor Cyan
        Write-Host "  3) FiraCode Nerd Font" -ForegroundColor Cyan
        Write-Host "  4) MesloLG Nerd Font" -ForegroundColor Cyan
        Write-Host "  5) CascadiaCode Nerd Font" -ForegroundColor Cyan
        Write-Host "  6) 跳过" -ForegroundColor Cyan
        $fontChoice = Read-Host "请输入选项 [1-6] (默认 1)"
        if (-not $fontChoice) { $fontChoice = "1" }

        $fontPkg = switch ($fontChoice) {
            "1" { "Hack-NF" }
            "2" { "JetBrainsMono-NF" }
            "3" { "FiraCode-NF" }
            "4" { "Meslo-NF" }
            "5" { "CascadiaCode-NF" }
            "6" { "" }
            default { "Hack-NF" }
        }

        if ($fontPkg) {
            Scoop-Install -Package $fontPkg -Name $fontPkg -Bucket "nerd-fonts"
            Warn "请在终端设置中将字体切换为对应的 Nerd Font"
        }

        # Starship 主题
        $starshipConfig = "$env:USERPROFILE\.config\starship.toml"
        $starshipDir = Split-Path $starshipConfig
        if (-not (Test-Path $starshipDir)) { New-Item -ItemType Directory -Path $starshipDir -Force | Out-Null }

        Write-Host ""
        Write-Host "选择 Starship 主题:" -ForegroundColor White
        Write-Host "   1) Catppuccin Mocha Powerline (推荐)" -ForegroundColor Cyan
        Write-Host "   2) catppuccin-powerline" -ForegroundColor Cyan
        Write-Host "   3) gruvbox-rainbow" -ForegroundColor Cyan
        Write-Host "   4) tokyo-night" -ForegroundColor Cyan
        Write-Host "   5) pastel-powerline" -ForegroundColor Cyan
        Write-Host "   6) jetpack" -ForegroundColor Cyan
        Write-Host "   7) pure-preset" -ForegroundColor Cyan
        Write-Host "   8) nerd-font-symbols" -ForegroundColor Cyan
        Write-Host "   9) plain-text-symbols (无需 Nerd Font)" -ForegroundColor Cyan
        Write-Host "  10) 跳过" -ForegroundColor Cyan
        $themeChoice = Read-Host "请输入选项 [1-10] (默认 1)"
        if (-not $themeChoice) { $themeChoice = "1" }

        $gistUrl = "https://gist.githubusercontent.com/zhangchitc/62f5dca64c599084f936fda9963f1100/raw/starship.toml"

        switch ($themeChoice) {
            "1"  {
                Info "下载 Catppuccin Mocha 主题..."
                try {
                    Invoke-WebRequest -Uri (GitHub-RawUrl $gistUrl) -OutFile $starshipConfig -UseBasicParsing
                    Ok "Starship 主题已应用: Catppuccin Mocha Powerline"
                } catch {
                    Warn "下载失败，使用内置 catppuccin-powerline"
                    starship preset catppuccin-powerline -o $starshipConfig 2>$null
                }
            }
            "2"  { starship preset catppuccin-powerline -o $starshipConfig 2>$null; Ok "主题: catppuccin-powerline" }
            "3"  { starship preset gruvbox-rainbow -o $starshipConfig 2>$null; Ok "主题: gruvbox-rainbow" }
            "4"  { starship preset tokyo-night -o $starshipConfig 2>$null; Ok "主题: tokyo-night" }
            "5"  { starship preset pastel-powerline -o $starshipConfig 2>$null; Ok "主题: pastel-powerline" }
            "6"  { starship preset jetpack -o $starshipConfig 2>$null; Ok "主题: jetpack" }
            "7"  { starship preset pure-preset -o $starshipConfig 2>$null; Ok "主题: pure-preset" }
            "8"  { starship preset nerd-font-symbols -o $starshipConfig 2>$null; Ok "主题: nerd-font-symbols" }
            "9"  { starship preset plain-text-symbols -o $starshipConfig 2>$null; Ok "主题: plain-text-symbols" }
            "10" { Ok "保持现有 Starship 配置" }
        }

        Ensure-ProfileInit 'Invoke-Expression (&starship init powershell)' "Starship"

    } elseif ($promptChoice -eq "2") {
        # ── Oh My Posh ──────────────────────────────────
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Ok "Oh My Posh 已安装"
        } else {
            Info "正在安装 Oh My Posh..."
            scoop install oh-my-posh
            Ok "Oh My Posh 安装完成"
        }
        Ensure-ProfileInit 'oh-my-posh init pwsh | Invoke-Expression' "Oh My Posh"
    } else {
        Ok "已跳过 Shell 提示符配置"
    }

    Write-Host ""
    Write-Host "环境基础检查完成" -ForegroundColor Green
    Write-Host ""
}

# ══════════════════════════════════════════════════════
# 安装模块
# ══════════════════════════════════════════════════════

# ── Ghostty ───────────────────────────────────────────
function Install-Ghostty {
    Write-Host ""
    Info "========== [1/12] Ghostty =========="

    if (Get-Command ghostty -ErrorAction SilentlyContinue) {
        Ok "Ghostty 已安装"
    } else {
        Info "正在安装 Ghostty..."
        $installed = $false
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            try {
                Winget-Install -Id "com.mitchellh.ghostty" -Name "Ghostty"
                $installed = $true
            } catch {}
        }
        if (-not $installed) {
            Warn "Ghostty Windows 版可能不可用，请从 https://ghostty.org/download 手动下载"
            Warn "替代方案: winget install Microsoft.WindowsTerminal"
        }
    }

    $ghosttyDir = "$env:APPDATA\ghostty"
    $ghosttyConf = "$ghosttyDir\config"
    if (-not (Test-Path $ghosttyDir)) { New-Item -ItemType Directory -Path $ghosttyDir -Force | Out-Null }

    Write-Host ""
    Write-Host "  1) 使用推荐配置 (Maple Mono + Catppuccin + 毛玻璃)" -ForegroundColor Cyan
    Write-Host "  2) 使用默认配置 / 保留当前配置" -ForegroundColor Cyan
    Write-Host ""
    $ghosttyChoice = Read-Host "选择 Ghostty 配置方案 [1/2] (默认 1)"
    if (-not $ghosttyChoice) { $ghosttyChoice = "1" }

    if ($ghosttyChoice -ne "2") {
        Backup-IfExists $ghosttyConf
        @"
# ============================================
# Ghostty Terminal - Windows 配置
# ============================================

# --- 字体排版 ---
font-family = "Maple Mono NF CN"
font-size = 12
font-thicken = true
adjust-cell-height = 2

# --- 主题与颜色 ---
theme = Catppuccin Latte

# --- 窗口与外观 ---
background-opacity = 0.85
window-padding-x = 10
window-padding-y = 8
window-save-state = always
window-theme = auto

# --- 光标 ---
cursor-style = bar
cursor-style-blink = true
cursor-opacity = 0.8

# --- 鼠标 ---
mouse-hide-while-typing = true
copy-on-select = clipboard

# --- 安全 ---
clipboard-paste-protection = true
clipboard-paste-bracketed-safe = true

# --- Shell 集成 ---
shell-integration = detect

# --- 快捷键 ---
keybind = ctrl+shift+t=new_tab
keybind = ctrl+shift+left=previous_tab
keybind = ctrl+shift+right=next_tab
keybind = ctrl+shift+w=close_surface
keybind = ctrl+shift+d=new_split:right
keybind = ctrl+shift+e=new_split:down
keybind = ctrl+shift+h=goto_split:left
keybind = ctrl+shift+l=goto_split:right
keybind = ctrl+shift+k=goto_split:top
keybind = ctrl+shift+j=goto_split:bottom
keybind = ctrl+plus=increase_font_size:1
keybind = ctrl+minus=decrease_font_size:1
keybind = ctrl+zero=reset_font_size

# --- 性能 ---
scrollback-limit = 25000000
"@ | Set-Content -Path $ghosttyConf -Encoding UTF8
        Ok "Ghostty 配置已写入 (Windows)"
    }
}

# ── Yazi ──────────────────────────────────────────────
function Install-Yazi {
    Write-Host ""
    Info "========== [2/12] Yazi =========="

    Scoop-Install -Package "yazi" -Name "Yazi"

    Info "安装 Yazi 辅助依赖..."
    Scoop-Install -Package "fd" -Name "fd (快速文件查找)"
    Scoop-Install -Package "ripgrep" -Name "ripgrep (内容搜索)"
    Scoop-Install -Package "fzf" -Name "fzf (模糊搜索)"
    Scoop-Install -Package "zoxide" -Name "zoxide (智能目录跳转)"
    Scoop-Install -Package "poppler" -Name "poppler (PDF 预览)"
    Scoop-Install -Package "ffmpeg" -Name "ffmpeg (视频处理)"
    Scoop-Install -Package "7zip" -Name "7zip (压缩包预览)"
    Scoop-Install -Package "jq" -Name "jq (JSON 预览)"
    Scoop-Install -Package "imagemagick" -Name "ImageMagick (图片处理)"

    $yaziDir = "$env:APPDATA\yazi\config"
    if (-not (Test-Path $yaziDir)) { New-Item -ItemType Directory -Path $yaziDir -Force | Out-Null }

    Write-Host ""
    Write-Host "  1) 使用推荐配置 (glow 预览 + 大预览区 + 快捷跳转)" -ForegroundColor Cyan
    Write-Host "  2) 使用默认配置 / 保留当前配置" -ForegroundColor Cyan
    Write-Host ""
    $yaziChoice = Read-Host "选择 Yazi 配置方案 [1/2] (默认 1)"
    if (-not $yaziChoice) { $yaziChoice = "1" }

    if ($yaziChoice -ne "2") {
        Scoop-Install -Package "glow" -Name "glow (Markdown 预览)"

        Backup-IfExists "$yaziDir\yazi.toml"
        @"
# ============================================
# Yazi 文件管理器 - 主配置
# ============================================

[mgr]
ratio         = [1, 3, 5]
sort_by       = "natural"
sort_sensitive = false
sort_reverse  = false
sort_dir_first = true
show_hidden   = false
show_symlink  = true
linemode      = "size"

[[plugin.prepend_previewers]]
url = "*.md"
run = 'piper -- glow -w=`$w -s=auto "`$1"'

[preview]
wrap       = "yes"
tab_size   = 2
max_width  = 1000
max_height = 1000

[opener]
edit = [
    { run = '`${EDITOR:-code} "%*"', block = true, for = "windows" },
]
open = [
    { run = 'start "" "%1"', for = "windows" },
]
reveal = [
    { run = 'explorer /select,"%1"', for = "windows" },
]

[[open.rules]]
name = "*.{md,txt,json,yaml,yml,toml,lua,py,go,rs,js,ts,tsx,jsx,sh,css,html,sql,env,conf,cfg,ps1}"
use = "edit"

[[open.rules]]
mime = "text/*"
use = "edit"

[[open.rules]]
mime = "image/*"
use = "open"

[[open.rules]]
mime = "video/*"
use = "open"

[[open.rules]]
use = "open"
"@ | Set-Content -Path "$yaziDir\yazi.toml" -Encoding UTF8
        Ok "yazi.toml 已写入"

        Backup-IfExists "$yaziDir\keymap.toml"
        @"
# ============================================
# Yazi - 快捷键配置
# ============================================

[[mgr.prepend_keymap]]
on   = ["g", "d"]
run  = "cd ~/Downloads"
desc = "Go to Downloads"

[[mgr.prepend_keymap]]
on   = ["g", "D"]
run  = "cd ~/Desktop"
desc = "Go to Desktop"

[[mgr.prepend_keymap]]
on   = ["g", "c"]
run  = "cd ~/.config"
desc = "Go to .config"

[[mgr.prepend_keymap]]
on   = ["g", "p"]
run  = "cd ~/Projects"
desc = "Go to Projects"

[[mgr.prepend_keymap]]
on   = ["g", "h"]
run  = "cd ~"
desc = "Go to Home"

[[mgr.prepend_keymap]]
on   = ["C"]
run  = "shell 'code \"%PWD%\"' --confirm"
desc = "Open in VS Code"

[[mgr.prepend_keymap]]
on   = ["S"]
run  = "shell 'pwsh' --block --confirm"
desc = "Open PowerShell here"
"@ | Set-Content -Path "$yaziDir\keymap.toml" -Encoding UTF8
        Ok "keymap.toml 已写入"

        Backup-IfExists "$yaziDir\theme.toml"
        @"
# Yazi 主题配置 (使用默认主题)
# Catppuccin: ya pack -a yazi-rs/flavors:catppuccin-mocha
"@ | Set-Content -Path "$yaziDir\theme.toml" -Encoding UTF8
        Ok "theme.toml 已写入"

        Backup-IfExists "$yaziDir\init.lua"
        @"
-- Yazi 插件初始化
local ok_border, full_border = pcall(require, "full-border")
if ok_border then full_border:setup() end

local ok_git, git = pcall(require, "git")
if ok_git then git:setup() end
"@ | Set-Content -Path "$yaziDir\init.lua" -Encoding UTF8
        Ok "init.lua 已写入"

        if (Get-Command ya -ErrorAction SilentlyContinue) {
            Info "安装 Yazi 插件..."
            ya pack -a yazi-rs/plugins:full-border 2>$null
            ya pack -a yazi-rs/plugins:git 2>$null
            ya pack -a yazi-rs/plugins:chmod 2>$null
            Ok "Yazi 插件已安装"
        }
    }

    # Shell 集成 (y 函数)
    $yaziWrapper = @'
# Yazi: 退出后自动 cd 到最后浏览的目录
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content $tmp -ErrorAction SilentlyContinue
    if ($cwd -and $cwd -ne $PWD.Path) {
        Set-Location $cwd
    }
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}
'@
    $added = Add-ToProfile -Content $yaziWrapper -Marker "function y {"
    if ($added) { Ok "已添加 y 命令到 PowerShell Profile" }
    else { Ok "Yazi shell wrapper (y 命令) 已存在" }
}

# ── Lazygit ───────────────────────────────────────────
function Install-Lazygit {
    Write-Host ""
    Info "========== [3/12] Lazygit =========="

    Scoop-Install -Package "lazygit" -Name "Lazygit"
    Scoop-Install -Package "delta" -Name "delta (语法高亮 diff)"

    $lazygitDir = "$env:APPDATA\lazygit"
    $lazygitConf = "$lazygitDir\config.yml"
    if (-not (Test-Path $lazygitDir)) { New-Item -ItemType Directory -Path $lazygitDir -Force | Out-Null }

    Backup-IfExists $lazygitConf
    @"
# ============================================
# Lazygit - 推荐配置
# ============================================

gui:
  nerdFontsVersion: "3"
  showFileIcons: true
  border: rounded
  showCommandLog: true
  theme:
    selectedLineBgColor:
      - reverse
    selectedRangeBgColor:
      - reverse
  showRandomTip: true
  showFileTree: true
  showDivergenceFromBaseBranch: arrowAndNumber

git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"
  autoFetch: true
  autoRefresh: true
  parseEmoji: true

os:
  editPreset: vim

promptToReturnFromSubprocess: false
quitOnTopLevelReturn: true
disableStartupPopups: true

keybinding:
  universal:
    quit: q
    return: <esc>
    togglePanel: <tab>
    prevPage: "["
    nextPage: "]"

customCommands:
  - key: "O"
    context: global
    command: "gh browse"
    description: "Open repo in browser"

  - key: "F"
    context: commits
    command: "git commit --fixup={{.SelectedLocalCommit.Hash}}"
    description: "Create fixup commit"

  - key: "Y"
    context: localBranches
    command: "echo {{.SelectedLocalBranch.Name}} | clip"
    description: "Copy branch name"
"@ | Set-Content -Path $lazygitConf -Encoding UTF8
    Ok "Lazygit 配置已写入"

    $pager = git config --global core.pager 2>$null
    if ($pager -notlike "*delta*") {
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.dark true
        git config --global delta.line-numbers true
        git config --global delta.side-by-side false
        git config --global delta.hyperlinks true
        git config --global merge.conflictstyle "zdiff3"
        Ok "Git Delta 全局配置已写入"
    } else {
        Ok "Git Delta 已配置"
    }
}

# ── Claude Code 提供商配置 ────────────────────────────
# 双写策略: 同时设置 Windows 用户环境变量 + ~/.claude/settings.json
# 确保无论 Claude Code 从何处启动都能读到配置

$CLAUDE_SETTINGS_PATH = "$env:USERPROFILE\.claude\settings.json"

$script:PROVIDER_KEYS = @(
    "ANTHROPIC_API_KEY", "ANTHROPIC_BASE_URL",
    "CLAUDE_CODE_USE_BEDROCK", "AWS_REGION", "AWS_PROFILE",
    "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN",
    "CLAUDE_CODE_USE_VERTEX", "CLOUD_ML_REGION", "ANTHROPIC_VERTEX_PROJECT_ID"
)

function Detect-ClaudeProvider {
    # 优先从用户环境变量检测
    $userBedrock = [Environment]::GetEnvironmentVariable("CLAUDE_CODE_USE_BEDROCK", "User")
    $userVertex  = [Environment]::GetEnvironmentVariable("CLAUDE_CODE_USE_VERTEX", "User")
    $userBaseUrl = [Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "User")
    $userApiKey  = [Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")

    if ($userBedrock) { return "Amazon Bedrock" }
    if ($userVertex)  { return "Google Vertex AI" }
    if ($userBaseUrl) { return "自定义 API 代理" }
    if ($userApiKey)  { return "Anthropic 直连" }
    return "未配置"
}

function Write-ClaudeEnv {
    param([hashtable]$EnvVars)

    # 1. 先清除旧的提供商环境变量
    foreach ($key in $script:PROVIDER_KEYS) {
        [Environment]::SetEnvironmentVariable($key, $null, "User")
    }

    # 2. 设置新的用户环境变量 (立即对所有新进程生效)
    foreach ($k in $EnvVars.Keys) {
        [Environment]::SetEnvironmentVariable($k, $EnvVars[$k], "User")
        # 同时设置当前进程环境变量 (立即生效)
        Set-Item -Path "Env:\$k" -Value $EnvVars[$k]
    }

    # 3. 同时写入 ~/.claude/settings.json (双保险)
    $settingsDir = Split-Path $CLAUDE_SETTINGS_PATH
    if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }

    $settings = @{}
    if (Test-Path $CLAUDE_SETTINGS_PATH) {
        try {
            $raw = Get-Content $CLAUDE_SETTINGS_PATH -Raw -ErrorAction Stop
            $parsed = $raw | ConvertFrom-Json
            $parsed.PSObject.Properties | ForEach-Object { $settings[$_.Name] = $_.Value }
        } catch {}
    }

    # 构建 env 字段: 保留非提供商 key + 写入新 key
    $envHash = [ordered]@{}
    if ($settings.ContainsKey("env") -and $settings["env"]) {
        $settings["env"].PSObject.Properties | ForEach-Object {
            if ($_.Name -notin $script:PROVIDER_KEYS) {
                $envHash[$_.Name] = $_.Value
            }
        }
    }
    foreach ($k in $EnvVars.Keys) {
        $envHash[$k] = $EnvVars[$k]
    }
    $settings["env"] = $envHash

    [PSCustomObject]$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $CLAUDE_SETTINGS_PATH -Encoding UTF8
}

function Clear-ClaudeEnv {
    $cleared = $false

    # 清除用户环境变量
    foreach ($key in $script:PROVIDER_KEYS) {
        $val = [Environment]::GetEnvironmentVariable($key, "User")
        if ($val) {
            [Environment]::SetEnvironmentVariable($key, $null, "User")
            Remove-Item -Path "Env:\$key" -ErrorAction SilentlyContinue
            $cleared = $true
        }
    }

    # 清除 settings.json 中的提供商 key
    if (Test-Path $CLAUDE_SETTINGS_PATH) {
        try {
            $raw = Get-Content $CLAUDE_SETTINGS_PATH -Raw -ErrorAction Stop
            $parsed = $raw | ConvertFrom-Json
            if ($parsed.env) {
                $envHash = [ordered]@{}
                $parsed.env.PSObject.Properties | ForEach-Object {
                    if ($_.Name -notin $script:PROVIDER_KEYS) {
                        $envHash[$_.Name] = $_.Value
                    } else {
                        $cleared = $true
                    }
                }
                $settings = [ordered]@{}
                $parsed.PSObject.Properties | ForEach-Object {
                    if ($_.Name -ne "env") { $settings[$_.Name] = $_.Value }
                }
                if ($envHash.Count -gt 0) { $settings["env"] = $envHash }
                [PSCustomObject]$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $CLAUDE_SETTINGS_PATH -Encoding UTF8
            }
        } catch {}
    }

    return $cleared
}

function Get-ExistingValue {
    param([string]$VarName)
    # 优先从用户环境变量读取
    $val = [Environment]::GetEnvironmentVariable($VarName, "User")
    if ($val) { return $val }
    return ""
}

function Read-WithDefault {
    param(
        [string]$Prompt,
        [string]$Default
    )
    if ($Default) {
        $result = Read-Host "$Prompt [$Default]"
    } else {
        $result = Read-Host $Prompt
    }
    if (-not $result -and $Default) { return $Default }
    return $result
}

function Configure-ClaudeProvider {
    Info "配置 Claude Code API 提供商"

    $currentProvider = Detect-ClaudeProvider
    Write-Host ""
    Write-Host "  当前提供商: $currentProvider" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) Anthropic 直连        (使用 Anthropic API Key)" -ForegroundColor Green
    Write-Host "  2) Amazon Bedrock        (使用 AWS 凭证)" -ForegroundColor Green
    Write-Host "  3) Google Vertex AI      (使用 GCP 项目)" -ForegroundColor Green
    Write-Host "  4) 自定义 API 代理       (OpenRouter / 中转站等)" -ForegroundColor Green
    Write-Host "  5) 清除配置              (移除当前提供商设置)" -ForegroundColor Green
    Write-Host "  0) 跳过                  (保持现有配置不变)" -ForegroundColor Green
    Write-Host ""
    $providerChoice = Read-Host "  请输入选项 [0-5]"

    switch ($providerChoice) {
        "1" {
            Info "配置 Anthropic 直连..."
            $existingKey = Get-ExistingValue "ANTHROPIC_API_KEY"
            $apiKey = Read-WithDefault "  Anthropic API Key" $existingKey
            if (-not $apiKey) {
                Err "API Key 不能为空，跳过配置"
            } else {
                $masked = "$($apiKey.Substring(0,8))...$($apiKey.Substring($apiKey.Length-4))"
                Write-ClaudeEnv @{ "ANTHROPIC_API_KEY" = $apiKey }
                Ok "Anthropic 直连已配置 (Key: $masked)"
                Info "已写入用户环境变量 + $CLAUDE_SETTINGS_PATH"
            }
        }
        "2" {
            Info "配置 Amazon Bedrock..."
            Write-Host ""
            Write-Host "  认证方式:" -ForegroundColor White
            Write-Host "    a) AWS Access Key (AK/SK)" -ForegroundColor Green
            Write-Host "    b) AWS Profile (~/.aws/credentials)" -ForegroundColor Green
            Write-Host ""
            $awsAuthMode = Read-Host "  选择认证方式 [a/b]"

            $existingRegion = Get-ExistingValue "AWS_REGION"
            $defaultRegion = if ($existingRegion) { $existingRegion } else { "us-east-1" }
            $awsRegion = Read-WithDefault "  AWS Region" $defaultRegion

            $envVars = [ordered]@{
                "CLAUDE_CODE_USE_BEDROCK" = "1"
                "AWS_REGION" = $awsRegion
            }

            if ($awsAuthMode -eq "b") {
                $existingProfile = Get-ExistingValue "AWS_PROFILE"
                $defaultProfile = if ($existingProfile) { $existingProfile } else { "default" }
                $awsProfile = Read-WithDefault "  AWS Profile 名称" $defaultProfile
                $envVars["AWS_PROFILE"] = $awsProfile
                Write-ClaudeEnv $envVars
                Ok "Amazon Bedrock 已配置 (Profile: $awsProfile, Region: $awsRegion)"
                Info "已写入用户环境变量 + $CLAUDE_SETTINGS_PATH"
            } else {
                $existingAK = Get-ExistingValue "AWS_ACCESS_KEY_ID"
                $existingSK = Get-ExistingValue "AWS_SECRET_ACCESS_KEY"
                $existingToken = Get-ExistingValue "AWS_SESSION_TOKEN"

                $accessKey = Read-WithDefault "  AWS Access Key ID" $existingAK
                $secretKey = Read-WithDefault "  AWS Secret Access Key" $existingSK
                $sessionToken = Read-WithDefault "  AWS Session Token (可选, 回车跳过)" $existingToken

                if (-not $accessKey -or -not $secretKey) {
                    Err "Access Key 和 Secret Key 不能为空，跳过配置"
                } else {
                    $envVars["AWS_ACCESS_KEY_ID"] = $accessKey
                    $envVars["AWS_SECRET_ACCESS_KEY"] = $secretKey
                    if ($sessionToken) {
                        $envVars["AWS_SESSION_TOKEN"] = $sessionToken
                    }
                    Write-ClaudeEnv $envVars
                    $maskedAK = "$($accessKey.Substring(0,4))...$($accessKey.Substring($accessKey.Length-4))"
                    Ok "Amazon Bedrock 已配置 (AK: $maskedAK, Region: $awsRegion)"
                    Info "已写入用户环境变量 + $CLAUDE_SETTINGS_PATH"
                }
            }
        }
        "3" {
            Info "配置 Google Vertex AI..."
            $existingRegion = Get-ExistingValue "CLOUD_ML_REGION"
            $existingProject = Get-ExistingValue "ANTHROPIC_VERTEX_PROJECT_ID"

            $gcpProject = Read-WithDefault "  GCP 项目 ID" $existingProject
            $defaultRegion = if ($existingRegion) { $existingRegion } else { "us-east5" }
            $gcpRegion = Read-WithDefault "  GCP Region" $defaultRegion

            if (-not $gcpProject) {
                Err "GCP 项目 ID 不能为空，跳过配置"
            } else {
                Write-ClaudeEnv @{
                    "CLAUDE_CODE_USE_VERTEX" = "1"
                    "CLOUD_ML_REGION" = $gcpRegion
                    "ANTHROPIC_VERTEX_PROJECT_ID" = $gcpProject
                }
                Ok "Google Vertex AI 已配置 (项目: $gcpProject, Region: $gcpRegion)"
                Info "已写入用户环境变量 + $CLAUDE_SETTINGS_PATH"
                Write-Host ""
                Info "提示: 请确保已通过 gcloud auth application-default login 完成认证"
            }
        }
        "4" {
            Info "配置自定义 API 代理..."
            $existingUrl = Get-ExistingValue "ANTHROPIC_BASE_URL"
            $existingKey = Get-ExistingValue "ANTHROPIC_API_KEY"

            $baseUrl = Read-WithDefault "  API Base URL (例: https://openrouter.ai/api/v1)" $existingUrl
            $apiKey = Read-WithDefault "  API Key" $existingKey

            if (-not $baseUrl -or -not $apiKey) {
                Err "Base URL 和 API Key 不能为空，跳过配置"
            } else {
                $masked = "$($apiKey.Substring(0,8))...$($apiKey.Substring($apiKey.Length-4))"
                Write-ClaudeEnv @{
                    "ANTHROPIC_BASE_URL" = $baseUrl
                    "ANTHROPIC_API_KEY" = $apiKey
                }
                Ok "自定义 API 代理已配置 (URL: $baseUrl, Key: $masked)"
                Info "已写入用户环境变量 + $CLAUDE_SETTINGS_PATH"
            }
        }
        "5" {
            if (Clear-ClaudeEnv) {
                Ok "已清除 Claude 提供商配置"
                Info "已清除用户环境变量 + $CLAUDE_SETTINGS_PATH"
            } else {
                Warn "未找到已有的 Claude 提供商配置"
            }
        }
        { $_ -in @("0", "") } {
            Ok "保持现有配置不变"
        }
        default {
            Warn "无效选项，跳过 Claude 提供商配置"
        }
    }
}

# ── Claude Code ───────────────────────────────────────
function Install-Claude {
    Write-Host ""
    Info "========== [4/12] Claude Code =========="

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Ok "Claude Code 已安装"
    } else {
        Info "正在安装 Claude Code..."
        $installed = $false

        # 尝试官方安装脚本
        try {
            Invoke-RestMethod -Uri "https://claude.ai/install.ps1" | Invoke-Expression
            $installed = $true
            Ok "Claude Code 安装完成"
        } catch {
            Warn "官方脚本安装失败，尝试其他方式..."
        }

        if (-not $installed -and (Get-Command npm -ErrorAction SilentlyContinue)) {
            npm install -g @anthropic-ai/claude-code 2>$null
            if ($LASTEXITCODE -eq 0) {
                Ok "Claude Code (npm) 安装完成"
                $installed = $true
            }
        }

        if (-not $installed -and (Get-Command winget -ErrorAction SilentlyContinue)) {
            try {
                Winget-Install -Id "Anthropic.ClaudeCode" -Name "Claude Code"
                $installed = $true
            } catch {}
        }

        if (-not $installed) {
            Err "Claude Code 安装失败，请手动安装: https://docs.anthropic.com/en/docs/claude-code"
        }
    }

    Refresh-Path

    Write-Host ""
    Configure-ClaudeProvider

    Write-Host ""
    Info "Claude Code 使用提示:"
    Write-Host "   claude              启动交互式会话"
    Write-Host '   claude "问题"       直接提问'
    Write-Host '   claude -p "问题"    非交互模式 (管道友好)'
    Write-Host "   首次使用需要登录:    claude login"
}

# ── OpenClaw ──────────────────────────────────────────
function Install-OpenClaw {
    Write-Host ""
    Info "========== [5/12] OpenClaw =========="

    if (Get-Command openclaw -ErrorAction SilentlyContinue) {
        Ok "OpenClaw 已安装"
    } else {
        Info "正在安装 OpenClaw..."
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            try { Winget-Install -Id "OpenClaw.OpenClaw" -Name "OpenClaw" } catch {}
        }
        if (-not (Get-Command openclaw -ErrorAction SilentlyContinue)) {
            Warn "请从 https://openclaw.ai 手动下载安装 OpenClaw"
        }
    }

    Write-Host ""
    Info "OpenClaw 使用提示:"
    Write-Host "   openclaw            启动 OpenClaw"
    Write-Host "   openclaw onboard    首次设置向导"
}

# ── Hermes Agent ─────────────────────────────────────
function Install-Hermes {
    Write-Host ""
    Info "========== [6/12] Hermes Agent =========="

    if (Get-Command hermes -ErrorAction SilentlyContinue) {
        Ok "Hermes Agent 已安装"
    } else {
        Info "正在安装 Hermes Agent..."
        try {
            $installUrl = GitHub-RawUrl "https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1"
            Invoke-RestMethod -Uri $installUrl | Invoke-Expression
            Ok "Hermes Agent 安装完成"
        } catch {
            Warn "自动安装失败，请从 https://github.com/nousresearch/hermes-agent 手动安装"
        }
    }

    # 检查 OpenClaw 迁移
    if ((Test-Path "$env:USERPROFILE\.openclaw") -and (Get-Command hermes -ErrorAction SilentlyContinue)) {
        Write-Host ""
        $migrateChoice = Read-Host "检测到 OpenClaw 数据，是否迁移到 Hermes? [y/N]"
        if ($migrateChoice -match '^[yY]$') {
            Info "正在迁移 OpenClaw 数据..."
            hermes claw migrate
        }
    }

    Write-Host ""
    Info "Hermes Agent 使用提示:"
    Write-Host "   hermes              启动交互式会话"
    Write-Host "   hermes setup        运行完整设置向导"
    Write-Host "   hermes model        选择 LLM 提供商和模型"
    Write-Host "   hermes tools        配置可用工具"
    Write-Host "   hermes update       更新到最新版本"
}

# ── Antigravity ──────────────────────────────────────
function Install-Antigravity {
    Write-Host ""
    Info "========== [7/12] Antigravity =========="

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Winget-Install -Id "Google.Antigravity" -Name "Antigravity"
    } else {
        Warn "请从 Google 官方网站下载 Antigravity"
    }

    Write-Host ""
    Info "Antigravity 使用提示:"
    Write-Host "   从开始菜单启动 Antigravity"
    Write-Host "   首次启动需要 Google 账号登录"
}

# ── Docker Desktop (OrbStack 替代) ────────────────────
function Install-OrbStack {
    Write-Host ""
    Info "========== [8/12] Docker Desktop =========="
    Info "OrbStack 仅支持 macOS，Windows 上安装 Docker Desktop 替代"

    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Ok "Docker 已安装: $(docker --version)"
    } else {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Winget-Install -Id "Docker.DockerDesktop" -Name "Docker Desktop"
        } else {
            Warn "请从 https://www.docker.com/products/docker-desktop/ 下载 Docker Desktop"
        }
    }

    Write-Host ""
    Info "Docker Desktop 使用提示:"
    Write-Host "   docker run hello-world     验证安装"
    Write-Host "   docker compose up -d       启动容器编排"
    Write-Host "   注意: 需要先启动 Docker Desktop 应用"
}

# ── Obsidian ──────────────────────────────────────────
function Install-Obsidian {
    Write-Host ""
    Info "========== [9/12] Obsidian =========="

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Winget-Install -Id "Obsidian.Obsidian" -Name "Obsidian"
    } else {
        Scoop-Install -Package "obsidian" -Name "Obsidian" -Bucket "extras"
    }

    # Excalidraw 插件
    Write-Host ""
    Info "配置 Excalidraw 插件..."
    Write-Host ""
    Write-Host "请选择 Obsidian Vault 路径:" -ForegroundColor White
    Write-Host "  1) 默认路径: ~/Obsidian" -ForegroundColor Cyan
    Write-Host "  2) 自定义路径" -ForegroundColor Cyan
    Write-Host "  3) 跳过插件安装" -ForegroundColor Cyan
    $vaultChoice = Read-Host "请输入选项 [1/2/3] (默认 1)"
    if (-not $vaultChoice) { $vaultChoice = "1" }

    $vaultPath = switch ($vaultChoice) {
        "1" { "$env:USERPROFILE\Obsidian" }
        "2" { Read-Host "请输入 Vault 路径" }
        "3" { "" }
        default { "$env:USERPROFILE\Obsidian" }
    }

    if (-not $vaultPath) {
        Ok "跳过 Excalidraw 插件安装"
    } else {
        $pluginDir = "$vaultPath\.obsidian\plugins\obsidian-excalidraw-plugin"
        if (Test-Path $pluginDir) {
            Ok "Excalidraw 插件已安装"
        } else {
            New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
            Info "正在下载 Excalidraw 插件..."

            try {
                $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/zsviczian/obsidian-excalidraw-plugin/releases/latest" -UseBasicParsing
                $tag = $releaseInfo.tag_name
                $baseUrl = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/$tag"

                foreach ($file in @("main.js", "manifest.json", "styles.css")) {
                    $dlUrl = GitHub-RawUrl "$baseUrl/$file"
                    Invoke-WebRequest -Uri $dlUrl -OutFile "$pluginDir\$file" -UseBasicParsing
                }
                Ok "Excalidraw 插件安装完成 ($tag)"
            } catch {
                Err "下载失败，请手动在 Obsidian 设置中安装 Excalidraw 插件"
                Remove-Item -Path $pluginDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # 启用插件
        $communityPlugins = "$vaultPath\.obsidian\community-plugins.json"
        if (Test-Path $pluginDir) {
            if (Test-Path $communityPlugins) {
                $plugins = Get-Content $communityPlugins -Raw -ErrorAction SilentlyContinue
                if ($plugins -notlike "*obsidian-excalidraw-plugin*") {
                    $plugins = $plugins -replace '\]$', ',"obsidian-excalidraw-plugin"]'
                    Set-Content -Path $communityPlugins -Value $plugins
                    Ok "已将 Excalidraw 添加到启用列表"
                }
            } else {
                $obsidianDir = "$vaultPath\.obsidian"
                if (-not (Test-Path $obsidianDir)) { New-Item -ItemType Directory -Path $obsidianDir -Force | Out-Null }
                '["obsidian-excalidraw-plugin"]' | Set-Content -Path $communityPlugins
                Ok "已创建社区插件配置并启用 Excalidraw"
            }
        }

        Write-Host ""
        Info "Obsidian 使用提示:"
        Write-Host "   从开始菜单启动 Obsidian"
        Write-Host "   打开 Vault: $vaultPath"
        Write-Host "   Excalidraw: Ctrl+P 搜索 Excalidraw 命令"
    }
}

# ── Ditto (Maccy 替代) ────────────────────────────────
function Install-Maccy {
    Write-Host ""
    Info "========== [10/12] Ditto (剪贴板管理) =========="
    Info "Maccy 仅支持 macOS，Windows 上安装 Ditto 替代"

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Winget-Install -Id "Ditto.Ditto" -Name "Ditto"
    } else {
        Scoop-Install -Package "ditto" -Name "Ditto" -Bucket "extras"
    }

    Write-Host ""
    Info "Ditto 使用提示:"
    Write-Host "   默认快捷键: Ctrl+`` 打开剪贴板历史"
    Write-Host "   支持文本、图片、文件等多种格式"
    Write-Host "   也可使用 Windows 内置: Win+V"
}

# ── JDK ──────────────────────────────────────────────
function Install-JDK {
    Write-Host ""
    Info "========== [11/12] JDK =========="

    Write-Host ""
    Write-Host "选择 JDK 版本 (Eclipse Temurin):" -ForegroundColor White
    Write-Host "  1) JDK 21 (LTS，推荐)" -ForegroundColor Cyan
    Write-Host "  2) JDK 17 (LTS)" -ForegroundColor Cyan
    Write-Host "  3) JDK 11 (LTS)" -ForegroundColor Cyan
    Write-Host "  4) JDK 8  (LTS)" -ForegroundColor Cyan
    Write-Host "  5) 跳过" -ForegroundColor Cyan
    $jdkChoice = Read-Host "请输入选项 [1-5] (默认 1)"
    if (-not $jdkChoice) { $jdkChoice = "1" }

    $jdkId = switch ($jdkChoice) {
        "1" { "EclipseAdoptium.Temurin.21.JDK" }
        "2" { "EclipseAdoptium.Temurin.17.JDK" }
        "3" { "EclipseAdoptium.Temurin.11.JDK" }
        "4" { "EclipseAdoptium.Temurin.8.JDK" }
        "5" { "" }
        default { "EclipseAdoptium.Temurin.21.JDK" }
    }

    if ($jdkId) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Winget-Install -Id $jdkId -Name "JDK ($jdkId)"
        } else {
            $scoopPkg = switch ($jdkChoice) {
                "1" { "temurin21-jdk" }
                "2" { "temurin17-jdk" }
                "3" { "temurin11-jdk" }
                "4" { "temurin8-jdk" }
                default { "temurin21-jdk" }
            }
            scoop bucket add java 2>$null
            Scoop-Install -Package $scoopPkg -Name "JDK" -Bucket "java"
        }
    } else {
        Ok "跳过 JDK 安装"
    }

    Refresh-Path

    Write-Host ""
    Info "JDK 使用提示:"
    Write-Host "   java -version               查看当前 JDK 版本"
    Write-Host "   多版本管理: scoop install temurin17-jdk"
    Write-Host "   切换版本:   scoop reset temurin21-jdk"
}

# ── VS Code ──────────────────────────────────────────
function Install-VSCode {
    Write-Host ""
    Info "========== [12/12] VS Code =========="

    if (Get-Command code -ErrorAction SilentlyContinue) {
        Ok "VS Code 已安装"
    } else {
        Info "正在安装 VS Code..."
        # 优先 scoop (国内更快，winget 下载微软服务器容易卡住)
        Scoop-Install -Package "vscode" -Name "VS Code" -Bucket "extras"
        Refresh-Path
        if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
            # scoop 失败时回退到 winget
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Winget-Install -Id "Microsoft.VisualStudioCode" -Name "VS Code"
            }
        }
    }

    Refresh-Path

    # 确保 code 命令可用
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Err "VS Code CLI (code) 不可用，跳过扩展安装"
        Warn "请重新打开终端后运行: code --install-extension Catppuccin.catppuccin-vsc"
        return
    }

    # 安装 Catppuccin 主题
    Info "安装 Catppuccin 主题扩展..."

    $extensions = code --list-extensions 2>$null
    if ($extensions -match "Catppuccin.catppuccin-vsc$") {
        Ok "Catppuccin 主题已安装"
    } else {
        code --install-extension Catppuccin.catppuccin-vsc --force 2>$null
        Ok "Catppuccin 主题安装完成"
    }

    if ($extensions -match "Catppuccin.catppuccin-vsc-icons") {
        Ok "Catppuccin Icons 已安装"
    } else {
        code --install-extension Catppuccin.catppuccin-vsc-icons --force 2>$null
        Ok "Catppuccin Icons 安装完成"
    }

    # 设置 Catppuccin 为默认主题
    $vscodSettingsDir = "$env:APPDATA\Code\User"
    $vscodeSettings = "$vscodSettingsDir\settings.json"
    if (-not (Test-Path $vscodSettingsDir)) { New-Item -ItemType Directory -Path $vscodSettingsDir -Force | Out-Null }

    if (Test-Path $vscodeSettings) {
        $content = Get-Content $vscodeSettings -Raw -ErrorAction SilentlyContinue
        if ($content -match '"workbench.colorTheme"') {
            $content = $content -replace '"workbench.colorTheme"\s*:\s*"[^"]*"', '"workbench.colorTheme": "Catppuccin Latte"'
            Ok "已将 VS Code 主题切换为 Catppuccin Latte"
        } else {
            $content = $content -replace '^\{', "{`n    `"workbench.colorTheme`": `"Catppuccin Latte`","
            Ok "已添加 Catppuccin Latte 主题到 settings.json"
        }
        if ($content -match '"workbench.iconTheme"') {
            $content = $content -replace '"workbench.iconTheme"\s*:\s*"[^"]*"', '"workbench.iconTheme": "catppuccin-latte"'
        } else {
            $content = $content -replace '^\{', "{`n    `"workbench.iconTheme`": `"catppuccin-latte`","
        }
        Set-Content -Path $vscodeSettings -Value $content -Encoding UTF8
        Ok "已设置 Catppuccin Icons 图标主题"
    } else {
        @"
{
    "workbench.colorTheme": "Catppuccin Latte",
    "workbench.iconTheme": "catppuccin-latte"
}
"@ | Set-Content -Path $vscodeSettings -Encoding UTF8
        Ok "已创建 VS Code settings.json (Catppuccin Latte 主题)"
    }

    Write-Host ""
    Info "VS Code 使用提示:"
    Write-Host "   code .                打开当前目录"
    Write-Host "   code <file>           打开文件"
    Write-Host "   主题: Catppuccin Latte (已自动应用)"
    Write-Host "   切换主题: Ctrl+K Ctrl+T"
}

# ══════════════════════════════════════════════════════
# 主流程
# ══════════════════════════════════════════════════════
function Main {
    # 检查管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Warn "部分安装可能需要管理员权限，建议以管理员身份运行 PowerShell"
    }

    # 解析参数
    Parse-Args $args

    # 仅 claude-provider 模式
    if ($script:SKIP_PREREQUISITES -and ($script:SELECTED_TOOLS -contains "claude-provider")) {
        Write-Host ""
        Configure-ClaudeProvider
        return
    }

    # 环境基础检查
    if (-not $script:SKIP_PREREQUISITES) {
        Check-Prerequisites
    }

    # 安装选中的工具
    if ($script:SELECTED_TOOLS.Count -gt 0) {
        Write-Host ""
        Info "即将安装: $($script:SELECTED_TOOLS -join ', ')"
        Write-Host ""

        if (Is-Selected "ghostty")     { Install-Ghostty }
        if (Is-Selected "yazi")        { Install-Yazi }
        if (Is-Selected "lazygit")     { Install-Lazygit }
        if (Is-Selected "claude")      { Install-Claude }
        if (Is-Selected "openclaw")    { Install-OpenClaw }
        if (Is-Selected "hermes")      { Install-Hermes }
        if (Is-Selected "antigravity") { Install-Antigravity }
        if (Is-Selected "orbstack")    { Install-OrbStack }
        if (Is-Selected "obsidian")    { Install-Obsidian }
        if (Is-Selected "maccy")       { Install-Maccy }
        if (Is-Selected "jdk")         { Install-JDK }
        if (Is-Selected "vscode")      { Install-VSCode }
    }

    # 跳过模式：配置菜单
    if ($script:SKIP_PREREQUISITES -and $script:SELECTED_TOOLS.Count -eq 0) {
        Write-Host ""
        Info "========== 配置操作 =========="
        Write-Host ""
        Write-Host "  1) 修改 Claude 提供商配置" -ForegroundColor Green
        Write-Host "  0) 退出" -ForegroundColor Green
        Write-Host ""
        $configChoice = Read-Host "  请选择 [0-1]"
        switch ($configChoice) {
            "1" { Configure-ClaudeProvider }
            default { Ok "已退出" }
        }
    }

    # ── 完成 ──────────────────────────────────────────
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  All done! 全部完成" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""

    if ($script:SELECTED_TOOLS.Count -gt 0) {
        Write-Host "已安装: $($script:SELECTED_TOOLS -join ', ')"
        Write-Host ""
    }

    if (Is-Selected "ghostty")  { Write-Host "  Ghostty   $env:APPDATA\ghostty\config" }
    if (Is-Selected "yazi")     { Write-Host "  Yazi      $env:APPDATA\yazi\config\" }
    if (Is-Selected "lazygit")  { Write-Host "  Lazygit   $env:APPDATA\lazygit\config.yml" }
    if (Is-Selected "claude")   { Write-Host "  Claude    用户环境变量 + $CLAUDE_SETTINGS_PATH" }
    if (Is-Selected "hermes")   { Write-Host "  Hermes    $env:USERPROFILE\.hermes\ (配置/技能/记忆)" }
    if (Is-Selected "obsidian") { Write-Host "  Obsidian  $env:USERPROFILE\Obsidian (含 Excalidraw 插件)" }
    if (Is-Selected "maccy")    { Write-Host "  Ditto     剪贴板管理 (Ctrl+``)" }
    if (Is-Selected "jdk")      { Write-Host "  JDK       通过 winget/scoop 管理" }
    if (Is-Selected "vscode")   { Write-Host "  VS Code   Catppuccin Latte 主题已应用" }
    Write-Host ""

    Refresh-Path
}

# 运行主流程
Main
