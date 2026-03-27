# ============================================================
# Windows 开发工具一键安装与配置
# 支持: Windows Terminal / Yazi / Lazygit / Claude Code / OpenClaw / OrbStack(Docker Desktop)
# 用法:
#   全部安装:  .\install.ps1
#   选择安装:  .\install.ps1 terminal yazi lazygit claude openclaw orbstack
#   查看帮助:  .\install.ps1 --help
# ============================================================
$ErrorActionPreference = 'Continue'

# ── 颜色输出 ──────────────────────────────────────────
function Info  { param([string]$msg) Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $msg }
function OK    { param([string]$msg) Write-Host "[ OK ] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Warn  { param([string]$msg) Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Err   { param([string]$msg) Write-Host "[ERR ] " -ForegroundColor Red -NoNewline; Write-Host $msg }

# ── 国内加速配置 ──────────────────────────────────────
$script:USE_MIRROR = $false
$script:GITHUB_PROXY = ""

function Setup-Mirror {
    # 如果已通过 --mirror 标志启用，跳过检测
    if (-not $script:USE_MIRROR) {
        Write-Host ""
        Write-Host "检测网络环境..." -ForegroundColor White
        # 尝试访问 GitHub，超时 3 秒判断是否需要加速
        $canReachGithub = $false
        try {
            $response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/github/gitignore/main/README.md" `
                -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
            $canReachGithub = $true
        } catch {
            $canReachGithub = $false
        }

        if ($canReachGithub) {
            OK "GitHub 连接正常"
            Write-Host "是否仍要使用国内镜像加速? [y/N]: " -ForegroundColor Cyan -NoNewline
            $choice = Read-Host
            if ($choice -match '^[yY]$') { $script:USE_MIRROR = $true }
        } else {
            Warn "GitHub 连接缓慢或不可用"
            Write-Host "是否使用国内镜像加速? [Y/n]: " -ForegroundColor Cyan -NoNewline
            $choice = Read-Host
            if ($choice -notmatch '^[nN]$') { $script:USE_MIRROR = $true }
        }
    }

    if ($script:USE_MIRROR) {
        $script:GITHUB_PROXY = "https://ghfast.top/"

        # Node.js 镜像 (npmmirror)
        $env:NVM_NODEJS_ORG_MIRROR = "https://npmmirror.com/mirrors/node"
        $env:npm_config_registry = "https://registry.npmmirror.com"

        # Scoop 使用 npmmirror 源
        $env:SCOOP_REPO = "https://gitee.com/glsnames/scoop-installer"

        OK "已启用国内镜像加速"
        Info "  GitHub 代理:   $($script:GITHUB_PROXY)"
        Info "  Node.js 镜像:  npmmirror"
    }
}

# GitHub 原始文件 URL 加速
function Get-GithubRawUrl {
    param([string]$url)
    if ($script:USE_MIRROR) {
        return "$($script:GITHUB_PROXY)$url"
    }
    return $url
}

# GitHub 仓库 clone URL 加速
function Get-GithubCloneUrl {
    param([string]$url)
    if ($script:USE_MIRROR) {
        return "$($script:GITHUB_PROXY)$url"
    }
    return $url
}

# ── 帮助信息 ──────────────────────────────────────────
function Show-Help {
    $helpText = @"
Windows 开发工具一键安装脚本

用法:
  .\install.ps1                 交互式选择要安装的工具
  .\install.ps1 --all           安装全部工具
  .\install.ps1 --skip          跳过工具安装，仅修改配置
  .\install.ps1 --mirror        强制使用国内镜像加速
  .\install.ps1 <tool> ...      只安装指定工具

可选工具:
  terminal         Windows Terminal (现代终端模拟器)
  yazi             终端文件管理器 (快速预览/Vim 风格导航)
  lazygit          终端 Git UI (可视化提交/分支/合并)
  claude           Claude Code (AI 编程助手)
  openclaw         OpenClaw (本地 AI 助手)
  antigravity      Google Antigravity (AI 开发平台)
  orbstack         Docker Desktop (容器 & WSL 集成)
  claude-provider  仅修改 Claude API 提供商配置

示例:
  .\install.ps1 terminal yazi          只安装 Windows Terminal 和 Yazi
  .\install.ps1 claude openclaw        只安装 AI 工具
  .\install.ps1 claude-provider        仅切换 Claude 提供商
  .\install.ps1 --skip                 跳过安装，进入配置菜单
  .\install.ps1 --all                  全部安装
"@
    Write-Host $helpText
    exit 0
}

# ── 工具定义 ──────────────────────────────────────────
$script:ALL_TOOLS = @("terminal", "yazi", "lazygit", "claude", "openclaw", "antigravity", "orbstack")
$script:SELECTED_TOOLS = @()
$script:SKIP_PREREQUISITES = $false

# ── 交互式多选菜单 (方向键导航 + 空格选择) ───────────
function Interactive-Select {
    $labels = @(
        "Terminal     Windows Terminal (GPU/标签页/亚克力)"
        "Yazi         终端文件管理器 (预览/Vim导航)"
        "Lazygit      终端 Git UI (提交/分支/合并)"
        "Claude Code  AI 编程助手 (终端内编程)"
        "OpenClaw     本地 AI 助手 (自托管)"
        "Antigravity  Google AI (编码/Agent)"
        "OrbStack     Docker Desktop (容器/WSL)"
        "跳过         仅修改配置"
    )
    $count = $labels.Count
    $selected = [bool[]]::new($count)
    $cursor = 0

    # 打印标题
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Windows 开发工具一键安装与配置           ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "操作: ↑↓ 移动  空格 选择/取消  a 全选  回车 确认  q 退出" -ForegroundColor White
    Write-Host ""

    # 固定尾部空格（覆盖残留字符，不依赖 BufferWidth）
    $trail = "          "

    # 首次绘制
    for ($i = 0; $i -lt $count; $i++) {
        $check = if ($selected[$i]) { "*" } else { " " }
        if ($i -eq $cursor) {
            Write-Host "  > [$check] $($labels[$i])$trail"
        } else {
            Write-Host "    [$check] $($labels[$i])$trail"
        }
    }

    [Console]::CursorVisible = $false

    # 主循环
    $done = $false
    while (-not $done) {
        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow'   { if ($cursor -gt 0) { $cursor-- } }
            'DownArrow' { if ($cursor -lt ($count - 1)) { $cursor++ } }
            'Spacebar'  { $selected[$cursor] = -not $selected[$cursor] }
            'A' {
                $allOn = ($selected | Where-Object { -not $_ }).Count -eq 0
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = -not $allOn }
            }
            'Enter' {
                [Console]::CursorVisible = $true
                Write-Host ""
                $done = $true
            }
            'Q' {
                [Console]::CursorVisible = $true
                Write-Host ""
                Write-Host "已取消。"
                exit 0
            }
        }

        if (-not $done) {
            # 相对定位：从当前位置上移 $count 行
            $targetRow = [Math]::Max(0, [Console]::CursorTop - $count)
            [Console]::SetCursorPosition(0, $targetRow)
            for ($i = 0; $i -lt $count; $i++) {
                $check = if ($selected[$i]) { "*" } else { " " }
                if ($i -eq $cursor) {
                    Write-Host "  > [$check] $($labels[$i])$trail"
                } else {
                    Write-Host "    [$check] $($labels[$i])$trail"
                }
            }
        }
    }

    # 收集选中的工具
    $skipIndex = $count - 1
    for ($i = 0; $i -lt $count; $i++) {
        if ($selected[$i]) {
            if ($i -eq $skipIndex) {
                $script:SKIP_PREREQUISITES = $true
            } else {
                $script:SELECTED_TOOLS += $script:ALL_TOOLS[$i]
            }
        }
    }

    if ($script:SKIP_PREREQUISITES) {
        $script:SELECTED_TOOLS = @()
        Info "跳过工具安装，进入配置菜单"
    } elseif ($script:SELECTED_TOOLS.Count -eq 0) {
        $script:SKIP_PREREQUISITES = $true
        Info "未选择工具，跳过安装"
    }
}

# ── 解析参数 ──────────────────────────────────────────
function Parse-Args {
    param([string[]]$arguments)

    if ($arguments.Count -eq 0) {
        Interactive-Select
        return
    }

    foreach ($arg in $arguments) {
        switch ($arg) {
            { $_ -in '--help', '-h' } { Show-Help }
            { $_ -in '--all', '-a' } {
                $script:SELECTED_TOOLS = $script:ALL_TOOLS.Clone()
                return
            }
            { $_ -in '--skip', '-s' } {
                $script:SKIP_PREREQUISITES = $true
                return
            }
            { $_ -in '--mirror', '-m' } {
                $script:USE_MIRROR = $true
            }
            'claude-provider' {
                $script:SKIP_PREREQUISITES = $true
                $script:SELECTED_TOOLS += "claude-provider"
            }
            { $_ -in 'terminal', 'yazi', 'lazygit', 'claude', 'openclaw', 'antigravity', 'orbstack' } {
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

# ── 工具函数 ──────────────────────────────────────────
function Is-Selected {
    param([string]$tool)
    return ($script:SELECTED_TOOLS -contains $tool)
}

function Reload-Profile {
    if (Test-Path $PROFILE) {
        try { . $PROFILE 2>$null } catch {}
    }
}

function Backup-IfExists {
    param([string]$path)
    if (Test-Path $path) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backup = "${path}.bak.${timestamp}"
        Warn "备份已有配置: $path -> $backup"
        Copy-Item -Path $path -Destination $backup -Recurse -Force
    }
}

# ── 命令存在检查 ──────────────────────────────────────
function Test-CommandExists {
    param([string]$cmd)
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# ══════════════════════════════════════════════════════
# 环境基础检查 (默认安装，无需选择)
# ══════════════════════════════════════════════════════
function Check-Prerequisites {
    Write-Host ""
    Write-Host "========== 环境基础检查 ==========" -ForegroundColor Cyan
    Write-Host ""

    # ── 修复损坏的 PowerShell Profile ────────────────
    if (Test-Path $PROFILE) {
        $rawProfile = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($rawProfile) {
            # 尝试语法检查
            $parseErrors = $null
            [System.Management.Automation.Language.Parser]::ParseInput($rawProfile, [ref]$null, [ref]$parseErrors) | Out-Null
            if ($parseErrors.Count -gt 0) {
                Warn "检测到 PowerShell Profile 语法错误，正在修复..."
                Backup-IfExists $PROFILE
                # 清空损坏的 profile
                "" | Set-Content $PROFILE
                OK "已清空损坏的 Profile，将重新写入配置"
            }
        }
    }

    # ── 0. 网络环境检测 ─────────────────────────────
    Setup-Mirror

    $script:needReloadProfile = $false

    # ── 1. PowerShell 版本检查 & 自动切换 ──────────────
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 7) {
        OK "PowerShell 7+ 已安装: $($psVersion.ToString())"
    } elseif ($psVersion.Major -ge 5) {
        # 检查 pwsh 是否已安装但当前运行的是 PS5
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
        if (-not $pwshPath) {
            # 尝试常见安装路径
            $commonPaths = @(
                "$env:ProgramFiles\PowerShell\7\pwsh.exe",
                "$env:ProgramFiles(x86)\PowerShell\7\pwsh.exe",
                "$env:LOCALAPPDATA\Microsoft\PowerShell\7\pwsh.exe"
            )
            foreach ($p in $commonPaths) {
                if (Test-Path $p) { $pwshPath = $p; break }
            }
        }

        if ($pwshPath) {
            # pwsh 已安装但当前在 PS5 中运行，自动切换
            OK "检测到 PowerShell 7 已安装，自动切换到 pwsh 执行..."
        } else {
            Warn "当前 PowerShell 版本: $($psVersion.ToString())，建议升级到 7+"
            Write-Host "是否安装 PowerShell 7? [Y/n]: " -ForegroundColor Cyan -NoNewline
            $choice = Read-Host
            if ($choice -notmatch '^[nN]$') {
                Info "正在安装 PowerShell 7..."
                try {
                    winget install --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements -e
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                    $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
                    if (-not $pwshPath) {
                        foreach ($p in $commonPaths) {
                            if (Test-Path $p) { $pwshPath = $p; break }
                        }
                    }
                    if ($pwshPath) {
                        OK "PowerShell 7 安装完成"
                    } else {
                        OK "PowerShell 7 安装完成，但未找到 pwsh 路径，继续在当前 PS5 中运行"
                    }
                } catch {
                    Err "PowerShell 7 安装失败: $_"
                }
            }
        }

        # 如果找到 pwsh，自动切换执行
        if ($pwshPath) {
            Info "正在用 pwsh 重新执行脚本..."
            $tmpScript = Join-Path $env:TEMP "xshell_install.ps1"
            $scriptUrl = "https://raw.githubusercontent.com/funchs/dotfiles/main/install.ps1"
            $downloaded = $false
            # 先尝试直连
            try {
                Invoke-WebRequest -Uri $scriptUrl -OutFile $tmpScript -UseBasicParsing -TimeoutSec 5
                $downloaded = $true
            } catch {}
            # 失败则用镜像
            if (-not $downloaded) {
                try {
                    Invoke-WebRequest -Uri "https://ghfast.top/$scriptUrl" -OutFile $tmpScript -UseBasicParsing
                    $downloaded = $true
                } catch {
                    Warn "脚本下载失败，继续在当前 PS5 中运行"
                }
            }
            if ($downloaded) {
                $argString = ""
                if ($script:OriginalArgs) {
                    $argString = ($script:OriginalArgs | ForEach-Object { "`"$_`"" }) -join " "
                }
                & $pwshPath -NoProfile -ExecutionPolicy Bypass -File $tmpScript $script:OriginalArgs
                Remove-Item $tmpScript -Force -ErrorAction SilentlyContinue
                exit $LASTEXITCODE
            }
        }
    }

    # ── 2. winget 检查 ─────────────────────────────────
    if (Test-CommandExists "winget") {
        $wingetVersion = (winget --version 2>$null)
        OK "winget 已安装: $wingetVersion"
    } else {
        Warn "winget 未安装，正在尝试安装..."
        Info "winget 通常内置于 Windows 10 1709+ / Windows 11"
        Info "如果安装失败，请从 Microsoft Store 安装 'App Installer'"
        try {
            # 尝试通过 Microsoft Store 的 App Installer 包
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
            OK "winget 安装完成"
        } catch {
            Err "winget 安装失败，请手动从 Microsoft Store 安装 'App Installer'"
            Err "部分依赖 winget 的工具将无法自动安装"
        }
    }

    # ── 3. Git (Scoop 添加 bucket 依赖 Git，必须先装) ──
    if (Test-CommandExists "git") {
        OK "Git 已安装: $(git --version)"
    } else {
        Info "正在安装 Git..."
        $installed = $false

        # 镜像模式：直接通过代理下载 Git 安装包（winget/scoop 都会走 GitHub 直连，很慢）
        if ($script:USE_MIRROR) {
            Info "使用镜像加速下载 Git..."
            $gitVersion = "2.47.1"
            $arch = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
            $gitInstaller = "Git-$gitVersion-$arch.exe"
            $gitUrl = "$($script:GITHUB_PROXY)https://github.com/git-for-windows/git/releases/download/v$gitVersion.windows.1/$gitInstaller"
            $gitTmp = Join-Path $env:TEMP $gitInstaller
            try {
                Info "下载: $gitUrl"
                Invoke-WebRequest -Uri $gitUrl -OutFile $gitTmp -UseBasicParsing
                Info "正在静默安装 Git..."
                Start-Process -FilePath $gitTmp -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`"" -Wait
                Remove-Item $gitTmp -Force -ErrorAction SilentlyContinue
                # 刷新 PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                if (Test-CommandExists "git") {
                    $installed = $true
                    OK "Git 安装完成: $(git --version)"
                }
            } catch {
                Warn "镜像下载 Git 失败: $_"
            }
        }

        # 非镜像模式或镜像下载失败：尝试 winget
        if (-not $installed -and (Test-CommandExists "winget")) {
            winget install --id Git.Git --source winget --accept-source-agreements --accept-package-agreements -e 2>$null
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            if (Test-CommandExists "git") {
                $installed = $true
                OK "Git 安装完成: $(git --version)"
            } else {
                Warn "winget 安装 Git 失败，尝试 Scoop..."
            }
        }

        # 最后尝试 scoop
        if (-not $installed -and (Test-CommandExists "scoop")) {
            scoop install git 2>$null
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            if (Test-CommandExists "git") {
                OK "Git 安装完成: $(git --version)"
            } else {
                Err "Git 安装失败"
            }
        }
    }

    # ── 4. Scoop (开发工具包管理器) ────────────────────
    if (Test-CommandExists "scoop") {
        OK "Scoop 已安装"
    } else {
        Info "正在安装 Scoop..."
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
            if ($script:USE_MIRROR) {
                Invoke-RestMethod -Uri 'https://gitee.com/glsnames/scoop-installer/raw/master/bin/install.ps1' | Invoke-Expression
            } else {
                Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
            }
            OK "Scoop 安装完成"
        } catch {
            Err "Scoop 安装失败: $_"
            Err "请手动安装: https://scoop.sh"
        }
    }

    # 镜像模式下配置 Scoop 加速
    if ($script:USE_MIRROR -and (Test-CommandExists "scoop")) {
        scoop config SCOOP_REPO 'https://gitee.com/glsnames/scoop-installer' 2>$null
        # 安装 aria2（scoop 下载加速器，支持多线程）
        $scoopApps = scoop list 2>$null | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
        if ($scoopApps -notcontains "aria2") {
            Info "安装 aria2 (Scoop 下载加速)..."
            scoop install aria2 2>$null
            if ($LASTEXITCODE -eq 0) {
                OK "aria2 已安装"
            }
        }
        # 配置 scoop-proxy-cn 加速 GitHub 下载
        # 原理：替换 scoop 下载 URL 中的 github.com 为代理地址
        $scoopDir = if ($env:SCOOP) { $env:SCOOP } else { "$env:USERPROFILE\scoop" }
        $proxyHelper = "$scoopDir\apps\scoop\current\lib\proxy-cn.ps1"
        # 写入代理配置（scoop 会在下载前调用）
        scoop config proxy $null 2>$null
        # 设置环境变量让后续 Scoop-Install 使用代理
        $env:SCOOP_GH_PROXY = $script:GITHUB_PROXY
        OK "Scoop 镜像已配置 (GitHub 代理: $($script:GITHUB_PROXY))"
    }

    # 添加常用 bucket（需要 Git）
    if ((Test-CommandExists "scoop") -and (Test-CommandExists "git")) {
        $buckets = scoop bucket list 2>$null | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
        if ($buckets -notcontains "extras") {
            Info "添加 Scoop extras bucket..."
            if ($script:USE_MIRROR) {
                scoop bucket add extras https://gitee.com/scoop-bucket/extras.git 2>$null
            } else {
                scoop bucket add extras 2>$null
            }
            OK "extras bucket 已添加"
        }
        if ($buckets -notcontains "nerd-fonts") {
            Info "添加 Scoop nerd-fonts bucket..."
            if ($script:USE_MIRROR) {
                scoop bucket add nerd-fonts https://gitee.com/scoop-bucket/nerd-fonts.git 2>$null
            } else {
                scoop bucket add nerd-fonts 2>$null
            }
            OK "nerd-fonts bucket 已添加"
        }
    } elseif ((Test-CommandExists "scoop") -and -not (Test-CommandExists "git")) {
        Warn "Git 未安装，跳过 Scoop bucket 添加"
    }

    # ── 5. Shell 提示符 ──────────────────────────────
    Write-Host ""
    Write-Host "请选择 Shell 提示符工具:" -ForegroundColor White
    Write-Host "  1) Oh My Posh (经典方案，主题丰富)" -ForegroundColor Cyan
    Write-Host "  2) Starship (跨平台极速提示符)" -ForegroundColor Cyan
    Write-Host "  3) 跳过 (保持现有配置)" -ForegroundColor Cyan
    Write-Host "请输入选项 [1/2/3] (默认 1): " -ForegroundColor Cyan -NoNewline
    $promptChoice = Read-Host
    if (-not $promptChoice) { $promptChoice = "1" }

    # 确保 Profile 目录和文件存在 (两种方案都需要)
    if ($promptChoice -ne "3") {
        $profileDir = Split-Path $PROFILE -Parent
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        if (-not (Test-Path $PROFILE)) {
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        }
    }

    if ($promptChoice -eq "2") {
        # ── Starship ────────────────────────────────────
        if (Test-CommandExists "starship") {
            OK "Starship 已安装"
        } else {
            Info "正在安装 Starship..."
            $installed = $false
            if (Test-CommandExists "scoop") {
                scoop install starship 2>$null
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                if (Test-CommandExists "starship") {
                    $installed = $true
                    OK "Starship 安装完成 (Scoop)"
                } else {
                    Warn "Scoop 安装失败，尝试 winget..."
                }
            }
            if (-not $installed -and (Test-CommandExists "winget")) {
                winget install --id Starship.Starship --source winget --accept-source-agreements --accept-package-agreements -e 2>$null
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                if (Test-CommandExists "starship") {
                    $installed = $true
                    OK "Starship 安装完成 (winget)"
                } else {
                    Err "Starship 安装失败"
                }
            }
            if (-not $installed -and -not (Test-CommandExists "scoop") -and -not (Test-CommandExists "winget")) {
                Err "未找到 Scoop 或 winget，无法安装 Starship"
            }
        }

        # 选择 Starship 主题
        $starshipConfigDir = Join-Path $env:USERPROFILE ".config"
        $starshipConfig = Join-Path $starshipConfigDir "starship.toml"
        $gistUrl = "https://gist.githubusercontent.com/zhangchitc/62f5dca64c599084f936fda9963f1100/raw/starship.toml"
        if (-not (Test-Path $starshipConfigDir)) {
            New-Item -ItemType Directory -Path $starshipConfigDir -Force | Out-Null
        }

        Write-Host ""
        Write-Host "选择 Starship 主题:" -ForegroundColor White
        Write-Host "   1) Catppuccin Mocha Powerline (推荐，Nerd Font 图标)" -ForegroundColor Cyan
        Write-Host "   2) catppuccin-powerline" -ForegroundColor Cyan
        Write-Host "   3) gruvbox-rainbow" -ForegroundColor Cyan
        Write-Host "   4) tokyo-night" -ForegroundColor Cyan
        Write-Host "   5) pastel-powerline" -ForegroundColor Cyan
        Write-Host "   6) jetpack" -ForegroundColor Cyan
        Write-Host "   7) pure-preset" -ForegroundColor Cyan
        Write-Host "   8) nerd-font-symbols" -ForegroundColor Cyan
        Write-Host "   9) plain-text-symbols (无需 Nerd Font)" -ForegroundColor Cyan
        Write-Host "  10) 跳过 (保持现有配置)" -ForegroundColor Cyan
        Write-Host "请输入选项 [1-10] (默认 1): " -ForegroundColor Cyan -NoNewline
        $themeChoice = Read-Host
        if (-not $themeChoice) { $themeChoice = "1" }

        # 从 Gist 下载主题的辅助函数
        function Download-GistTheme {
            $downloaded = $false
            try {
                Invoke-WebRequest -Uri $gistUrl -OutFile $starshipConfig -UseBasicParsing -TimeoutSec 10
                $downloaded = $true
            } catch {}
            if (-not $downloaded -and $script:USE_MIRROR) {
                try {
                    Invoke-WebRequest -Uri "$($script:GITHUB_PROXY)$gistUrl" -OutFile $starshipConfig -UseBasicParsing
                    $downloaded = $true
                } catch {}
            }
            return $downloaded
        }

        switch ($themeChoice) {
            "1" {
                Info "下载 Catppuccin Mocha 主题..."
                if (Download-GistTheme) {
                    OK "Starship 主题已应用: Catppuccin Mocha Powerline"
                } else {
                    Warn "下载失败，使用内置 catppuccin-powerline"
                    starship preset catppuccin-powerline -o $starshipConfig 2>$null
                }
            }
            "2"  { starship preset catppuccin-powerline -o $starshipConfig 2>$null; OK "Starship 主题已应用: catppuccin-powerline" }
            "3"  { starship preset gruvbox-rainbow -o $starshipConfig 2>$null; OK "Starship 主题已应用: gruvbox-rainbow" }
            "4"  { starship preset tokyo-night -o $starshipConfig 2>$null; OK "Starship 主题已应用: tokyo-night" }
            "5"  { starship preset pastel-powerline -o $starshipConfig 2>$null; OK "Starship 主题已应用: pastel-powerline" }
            "6"  { starship preset jetpack -o $starshipConfig 2>$null; OK "Starship 主题已应用: jetpack" }
            "7"  { starship preset pure-preset -o $starshipConfig 2>$null; OK "Starship 主题已应用: pure-preset" }
            "8"  { starship preset nerd-font-symbols -o $starshipConfig 2>$null; OK "Starship 主题已应用: nerd-font-symbols" }
            "9"  { starship preset plain-text-symbols -o $starshipConfig 2>$null; OK "Starship 主题已应用: plain-text-symbols" }
            "10" { OK "保持现有 Starship 配置" }
            default {
                Warn "无效选项，使用推荐主题"
                Download-GistTheme | Out-Null
            }
        }

        # 配置 Starship 到 PowerShell Profile
        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($profileContent -and $profileContent.Contains("starship init powershell")) {
            OK "Starship 已配置到 PowerShell Profile"
        } else {
            $starshipInit = @'

# Starship 提示符
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
'@
            Add-Content -Path $PROFILE -Value $starshipInit
            OK "Starship 配置已写入 PowerShell Profile"
            $script:needReloadProfile = $true
        }

    } elseif ($promptChoice -eq "1" -or $promptChoice -ne "3") {
        # ── Oh My Posh (默认) ───────────────────────────
        if (Test-CommandExists "oh-my-posh") {
            OK "Oh My Posh 已安装"
        } else {
            Info "正在安装 Oh My Posh..."
            $installed = $false
            if (Test-CommandExists "winget") {
                winget install --id JanDeDobbeleer.OhMyPosh --source winget --accept-source-agreements --accept-package-agreements -e 2>$null
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                if (Test-CommandExists "oh-my-posh") {
                    $installed = $true
                    OK "Oh My Posh 安装完成"
                } else {
                    Warn "winget 安装失败，尝试 Scoop..."
                }
            }
            if (-not $installed -and (Test-CommandExists "scoop")) {
                scoop install oh-my-posh 2>$null
                if (Test-CommandExists "oh-my-posh") {
                    OK "Oh My Posh 安装完成"
                } else {
                    Err "Oh My Posh 安装失败"
                }
            }
        }

        # 配置 Oh My Posh 到 PowerShell Profile
        # 先确定可用的主题文件
        $ompThemeConfig = ""
        if (Test-CommandExists "oh-my-posh") {
            $themesPath = $env:POSH_THEMES_PATH
            if (-not $themesPath) {
                # 尝试常见路径
                $possiblePaths = @(
                    "$env:LOCALAPPDATA\Programs\oh-my-posh\themes",
                    "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes",
                    "$env:USERPROFILE\scoop\apps\oh-my-posh\current\themes"
                )
                foreach ($p in $possiblePaths) {
                    if (Test-Path $p) { $themesPath = $p; break }
                }
            }
            # 按优先级查找主题: catppuccin_mocha > catppuccin > night-owl > jandedobbeleer
            $themeFound = $false
            if ($themesPath) {
                foreach ($name in @("catppuccin_mocha", "catppuccin", "night-owl", "jandedobbeleer")) {
                    $themeFile = Join-Path $themesPath "$name.omp.json"
                    if (Test-Path $themeFile) {
                        $ompThemeConfig = $themeFile
                        $themeFound = $true
                        OK "Oh My Posh 主题: $name"
                        break
                    }
                }
            }
            if (-not $themeFound) {
                # 使用内置默认主题
                $ompThemeConfig = ""
                Warn "Oh My Posh 未找到预设主题，将使用默认主题"
            }
        }

        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        $needWriteOmp = $true
        if ($profileContent -and $profileContent.Contains("oh-my-posh")) {
            # 检查已有配置是否有效（主题文件是否存在）
            $configMatch = [regex]::Match($profileContent, '--config\s+"?([^"\r\n]+)"?')
            if ($configMatch.Success) {
                $existingTheme = $configMatch.Groups[1].Value.Trim()
                # 展开 $env:VAR 风格的变量
                $expandedTheme = $existingTheme -replace '\$env:(\w+)', { [System.Environment]::GetEnvironmentVariable($_.Groups[1].Value) }
                $expandedTheme = [System.Environment]::ExpandEnvironmentVariables($expandedTheme)
                if ($expandedTheme -and (Test-Path $expandedTheme)) {
                    OK "Oh My Posh 已配置到 PowerShell Profile"
                    $needWriteOmp = $false
                } else {
                    Warn "Oh My Posh 配置的主题文件不存在: $existingTheme"
                    Info "正在清理旧配置并重新写入..."
                    # 用正则整块删除 Oh My Posh 配置（注释 + if 块 + 闭合大括号）
                    $cleaned = $profileContent -replace '(?m)[\r\n]*#\s*Oh My Posh[^\r\n]*[\r\n]+(?:.*oh-my-posh.*[\r\n]*)*\}[\r\n]*', "`n"
                    # 清理连续空行
                    $cleaned = $cleaned -replace '(\r?\n){3,}', "`n`n"
                    Set-Content -Path $PROFILE -Value $cleaned.TrimEnd() -NoNewline
                }
            } else {
                # 有 oh-my-posh 但没指定 --config（使用默认主题），视为有效
                OK "Oh My Posh 已配置到 PowerShell Profile"
                $needWriteOmp = $false
            }
        }
        if ($needWriteOmp) {
            if ($ompThemeConfig) {
                $ompInit = @"

# Oh My Posh 终端美化
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$ompThemeConfig" | Invoke-Expression
}
"@
            } else {
                $ompInit = @'

# Oh My Posh 终端美化
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
}
'@
            }
            Add-Content -Path $PROFILE -Value $ompInit
            OK "Oh My Posh 配置已写入 PowerShell Profile"
            $script:needReloadProfile = $true
        }

    } else {
        # ── 跳过 ────────────────────────────────────────
        OK "已跳过 Shell 提示符配置"
    }

    # 安装 Maple Mono NF CN 字体
    $fontInstalled = $false
    # 检查字体是否已安装（兼容 PS5 和 PS7）
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
        $installedFonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($installedFonts -contains "Maple Mono NF CN" -or $installedFonts -match "Maple Mono") {
            OK "Maple Mono 字体已安装"
            $fontInstalled = $true
        }
    } catch {
        # System.Drawing 不可用时，通过注册表检查
        $regFonts = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue
        if ($regFonts.PSObject.Properties.Name -match "Maple Mono") {
            OK "Maple Mono 字体已安装"
            $fontInstalled = $true
        }
    }

    if (-not $fontInstalled) {
        Info "安装 Maple Mono NF CN 字体..."
        # 方法1: oh-my-posh font install（内置字体安装器，名称用 Maple Mono）
        if (Test-CommandExists "oh-my-posh") {
            # oh-my-posh font list 中的名称是 "Maple Mono"
            oh-my-posh font install "Maple Mono" 2>$null
            if ($LASTEXITCODE -eq 0) {
                OK "Maple Mono 字体安装完成 (oh-my-posh)"
                $fontInstalled = $true
            } else {
                # 尝试不带空格的版本
                oh-my-posh font install MapleMonoNFCN 2>$null
                if ($LASTEXITCODE -eq 0) {
                    OK "Maple Mono 字体安装完成 (oh-my-posh)"
                    $fontInstalled = $true
                }
            }
        }
        # 方法2: 镜像模式下直接从 GitHub 代理下载字体 zip
        if (-not $fontInstalled -and $script:USE_MIRROR) {
            try {
                $fontZipUrl = "$($script:GITHUB_PROXY)https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF-CN.zip"
                $fontZip = Join-Path $env:TEMP "MapleMono-NF-CN.zip"
                $fontDir = Join-Path $env:TEMP "MapleMono-NF-CN"
                Info "从镜像下载字体: $fontZipUrl"
                Invoke-WebRequest -Uri $fontZipUrl -OutFile $fontZip -UseBasicParsing
                Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force
                # 安装所有 ttf/otf 字体文件
                $shellApp = New-Object -ComObject Shell.Application
                $fontsFolder = $shellApp.Namespace(0x14) # Windows Fonts 文件夹
                Get-ChildItem "$fontDir\*.ttf", "$fontDir\*.otf" -Recurse | ForEach-Object {
                    $fontsFolder.CopyHere($_.FullName, 0x10) # 0x10 = 覆盖已有
                }
                Remove-Item $fontZip, $fontDir -Recurse -Force -ErrorAction SilentlyContinue
                OK "Maple Mono NF CN 字体安装完成 (镜像下载)"
                $fontInstalled = $true
            } catch {
                Warn "镜像下载字体失败: $_"
            }
        }
        # 方法3: scoop nerd-fonts bucket
        if (-not $fontInstalled -and (Test-CommandExists "scoop")) {
            scoop install MapleMono-NF-CN 2>$null
            if ($LASTEXITCODE -eq 0) {
                OK "Maple Mono NF CN 字体安装完成 (scoop)"
                $fontInstalled = $true
            }
        }
        if (-not $fontInstalled) {
            Warn "Maple Mono NF CN 字体自动安装失败"
            Info "请手动下载: https://github.com/subframe7536/maple-font/releases"
            Info "Windows Terminal 将使用 Cascadia Code 作为备选字体"
        }
    }

    # ── 6. NVM for Windows ─────────────────────────────
    if (Test-CommandExists "nvm") {
        OK "NVM for Windows 已安装: $(nvm version 2>$null)"
    } else {
        Info "正在安装 NVM for Windows..."
        $installed = $false
        # 镜像模式优先 winget（scoop 从 GitHub 下载会超时）
        if ($script:USE_MIRROR) {
            if (Test-CommandExists "winget") {
                winget install --id CoreyButler.NVMforWindows --source winget --accept-source-agreements --accept-package-agreements -e 2>$null
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                if (Test-CommandExists "nvm") {
                    $installed = $true
                    OK "NVM for Windows 安装完成"
                } else {
                    Warn "winget 安装 NVM 失败"
                }
            }
        } else {
            if (Test-CommandExists "scoop") {
                scoop install nvm 2>$null
                if ($LASTEXITCODE -eq 0 -and (Test-CommandExists "nvm")) {
                    $installed = $true
                    OK "NVM for Windows 安装完成"
                } else {
                    Warn "Scoop 安装 NVM 失败，尝试 winget..."
                }
            }
            if (-not $installed -and (Test-CommandExists "winget")) {
                winget install --id CoreyButler.NVMforWindows --source winget --accept-source-agreements --accept-package-agreements -e 2>$null
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                if (Test-CommandExists "nvm") {
                    $installed = $true
                    OK "NVM for Windows 安装完成"
                } else {
                    Err "NVM 安装失败"
                }
            }
        }
    }

    # 配置 NVM 镜像
    if ($script:USE_MIRROR -and (Test-CommandExists "nvm")) {
        nvm node_mirror https://npmmirror.com/mirrors/node/ 2>$null
        nvm npm_mirror https://npmmirror.com/mirrors/npm/ 2>$null
        OK "NVM 国内镜像已配置"
    }

    # ── 7. Node.js (通过 NVM 安装 LTS 版本) ─────────
    if (Test-CommandExists "node") {
        OK "Node.js 已安装: $(node --version)"
    } else {
        if (Test-CommandExists "nvm") {
            Info "正在通过 NVM 安装 Node.js LTS..."
            nvm install lts 2>$null
            nvm use lts 2>$null
            # 刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            if (Test-CommandExists "node") {
                OK "Node.js 安装完成: $(node --version)"
            } else {
                Warn "NVM 安装 Node.js 失败，尝试 winget..."
                if (Test-CommandExists "winget") {
                    winget install --id OpenJS.NodeJS.LTS --source winget --accept-source-agreements --accept-package-agreements -e 2>$null
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                    if (Test-CommandExists "node") {
                        OK "Node.js 安装完成: $(node --version)"
                    } else {
                        Err "Node.js 安装失败"
                    }
                }
            }
        } else {
            Info "NVM 不可用，通过 winget 安装 Node.js..."
            if (Test-CommandExists "winget") {
                winget install --id OpenJS.NodeJS.LTS --source winget --accept-source-agreements --accept-package-agreements -e 2>$null
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                if (Test-CommandExists "node") {
                    OK "Node.js 安装完成: $(node --version)"
                } else {
                    Err "Node.js 安装失败"
                }
            }
        }
    }

    # ── 8. Bun (高性能 JavaScript 运行时 / 包管理器) ──
    if (Test-CommandExists "bun") {
        OK "Bun 已安装: $(bun --version)"
    } else {
        Info "正在安装 Bun..."
        $installed = $false
        if (-not $script:USE_MIRROR -and (Test-CommandExists "scoop")) {
            scoop install bun 2>$null
            if ($LASTEXITCODE -eq 0 -and (Test-CommandExists "bun")) {
                $installed = $true
                OK "Bun 安装完成: $(bun --version)"
            } else {
                Warn "Scoop 安装 Bun 失败，尝试官方安装脚本..."
            }
        }
        if (-not $installed) {
            try {
                if ($script:USE_MIRROR) {
                    # 官方安装脚本，通过 npm 安装
                    if (Test-CommandExists "npm") {
                        npm install -g bun 2>$null
                        if (Test-CommandExists "bun") {
                            $installed = $true
                            OK "Bun 安装完成 (npm): $(bun --version)"
                        }
                    }
                    if (-not $installed) {
                        irm bun.sh/install.ps1 | iex
                        OK "Bun 安装完成: $(bun --version 2>$null)"
                    }
                } else {
                    irm bun.sh/install.ps1 | iex
                    OK "Bun 安装完成: $(bun --version 2>$null)"
                }
            } catch {
                Err "Bun 安装失败: $_"
            }
        }
    }

    Write-Host ""
    Write-Host "环境基础检查完成" -ForegroundColor Green
    if ($script:needReloadProfile) {
        Write-Host "提示: 部分配置需要重新打开终端后生效" -ForegroundColor Yellow
    }
    Write-Host ""
}

# ── 带重试的 winget 安装 ──────────────────────────────
function Winget-Install {
    param(
        [string]$id,
        [string]$name
    )
    if (-not $name) { $name = $id }

    # 检查是否已安装
    $existing = winget list --id $id --source winget 2>$null
    if ($existing -match $id) {
        OK "$name 已安装"
        return
    }

    $maxRetries = 3
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        if ($attempt -gt 1) {
            Warn "$name 第 $attempt 次重试..."
        } else {
            Info "正在安装 $name ..."
        }
        winget install --id $id --source winget --accept-source-agreements --accept-package-agreements -e 2>$null
        if ($LASTEXITCODE -eq 0) {
            # 刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            OK "$name 安装完成"
            return
        }
        Err "$name 安装失败 (第 $attempt/$maxRetries 次)"
    }
    Err "$name 安装失败，已跳过。可稍后手动运行: winget install --id $id --source winget"
}

# ── 带重试的 scoop 安装 ──────────────────────────────
function Scoop-Install {
    param(
        [string]$package,
        [string]$name
    )
    if (-not $name) { $name = $package }

    # 检查是否已安装
    $installed = scoop list 2>$null | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
    if ($installed -contains $package) {
        OK "$name 已安装"
        return
    }

    $maxRetries = 3
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        if ($attempt -gt 1) {
            Warn "$name 第 $attempt 次重试..."
        } else {
            Info "正在安装 $name ..."
        }

        # 镜像模式：尝试通过代理下载（修改 scoop 缓存中的 URL）
        if ($script:USE_MIRROR -and $env:SCOOP_GH_PROXY) {
            # 先获取包的下载 URL，替换 github.com 为代理
            $scoopDir = if ($env:SCOOP) { $env:SCOOP } else { "$env:USERPROFILE\scoop" }
            # 使用 scoop 的 --skip 和直接下载不好控制，改用 scoop config 的 aria2 方式
            # 临时设置 aria2 的 all-proxy
            $proxyUrl = $env:SCOOP_GH_PROXY
            # scoop 下载时会用 aria2 或 Invoke-WebRequest，我们通过 hook 替换 URL
            # 最简单方式：临时设置 SCOOP_REPO 确保 scoop update 快，包下载走 aria2
            scoop install $package 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                OK "$name 安装完成"
                return
            }
            # 如果 scoop 直接安装失败，尝试手动通过代理下载
            Warn "Scoop 下载失败，尝试代理下载 $name..."
            $manifestFile = Get-ChildItem "$scoopDir\buckets\*\bucket\$package.json" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($manifestFile) {
                $manifest = Get-Content $manifestFile.FullName -Raw | ConvertFrom-Json
                $url = if ($manifest.architecture.'64bit'.url) { $manifest.architecture.'64bit'.url } elseif ($manifest.url) { $manifest.url } else { $null }
                if ($url -is [array]) { $url = $url[0] }
                if ($url -and $url -match 'github\.com') {
                    $proxyUrl = $url -replace 'https://github.com', "${proxyUrl}https://github.com"
                    $fileName = Split-Path $url -Leaf
                    $cachePath = "$scoopDir\cache\$package#$($manifest.version)#$fileName"
                    try {
                        Info "代理下载: $fileName"
                        Invoke-WebRequest -Uri $proxyUrl -OutFile $cachePath -UseBasicParsing
                        # 再次安装（scoop 会使用缓存）
                        scoop install $package 2>&1 | Out-Null
                        if ($LASTEXITCODE -eq 0) {
                            OK "$name 安装完成 (代理)"
                            return
                        }
                    } catch {
                        Warn "代理下载失败: $_"
                    }
                }
            }
        } else {
            scoop install $package 2>$null
            if ($LASTEXITCODE -eq 0) {
                OK "$name 安装完成"
                return
            }
        }
        Err "$name 安装失败 (第 $attempt/$maxRetries 次)"
    }
    Err "$name 安装失败，已跳过。可稍后手动运行: scoop install $package"
}

# ══════════════════════════════════════════════════════
# 安装模块
# ══════════════════════════════════════════════════════

# ── Windows Terminal ─────────────────────────────────
function Install-Terminal {
    Write-Host ""
    Info "========== [1/7] Windows Terminal =========="

    if (Test-CommandExists "winget") {
        Winget-Install -id "Microsoft.WindowsTerminal" -name "Windows Terminal"
    } else {
        Warn "winget 不可用，请从 Microsoft Store 安装 Windows Terminal"
    }

    # Windows Terminal 配置路径
    $wtSettingsDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    $wtSettingsFile = "$wtSettingsDir\settings.json"

    Write-Host ""
    Write-Host "  1) " -ForegroundColor Cyan -NoNewline; Write-Host "使用推荐配置 (Maple Mono + Catppuccin + 亚克力背景)"
    Write-Host "  2) " -ForegroundColor Cyan -NoNewline; Write-Host "使用默认配置 / 保留当前配置"
    Write-Host ""
    Write-Host "选择 Windows Terminal 配置方案 [1/2] (默认 1): " -ForegroundColor White -NoNewline
    $terminalChoice = Read-Host

    if ($terminalChoice -ne "2") {
        if (Test-Path $wtSettingsDir) {
            Backup-IfExists $wtSettingsFile

            # 根据字体是否安装成功选择字体
            $wtFontFace = "Cascadia Mono"
            # 检查 Maple Mono 是否已安装
            $hasMapleMono = $false
            try {
                Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
                $fonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
                if ($fonts -match "Maple Mono") { $hasMapleMono = $true }
            } catch {
                $regFonts = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue
                if ($regFonts.PSObject.Properties.Name -match "Maple Mono") { $hasMapleMono = $true }
            }
            if ($hasMapleMono) {
                $wtFontFace = "Maple Mono NF CN"
                OK "Windows Terminal 将使用 Maple Mono NF CN 字体"
            } else {
                Info "Maple Mono 未安装，Windows Terminal 使用 Cascadia Mono"
            }

            $wtConfig = @"
{
    "`$help": "https://aka.ms/terminal-documentation",
    "`$schema": "https://aka.ms/terminal-profiles-schema",
    "defaultProfile": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
    "copyOnSelect": true,
    "trimBlockSelection": true,
    "profiles": {
        "defaults": {
            "font": {
                "face": "$wtFontFace",
                "size": 12,
                "weight": "normal"
            },
            "colorScheme": "Catppuccin Latte",
            "useAcrylic": true,
            "acrylicOpacity": 0.85,
            "padding": "10, 8, 10, 8",
            "cursorShape": "bar",
            "cursorHeight": 25,
            "scrollbarState": "visible",
            "antialiasingMode": "cleartype",
            "bellStyle": "none"
        },
        "list": [
            {
                "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
                "name": "Windows PowerShell",
                "commandline": "powershell.exe",
                "hidden": false
            },
            {
                "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
                "name": "PowerShell 7",
                "commandline": "pwsh.exe",
                "hidden": false
            },
            {
                "guid": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}",
                "name": "命令提示符",
                "commandline": "cmd.exe",
                "hidden": false
            }
        ]
    },
    "schemes": [
        {
            "name": "Catppuccin Latte",
            "cursorColor": "#DC8A78",
            "selectionBackground": "#ACB0BE",
            "background": "#EFF1F5",
            "foreground": "#4C4F69",
            "black": "#5C5F77",
            "red": "#D20F39",
            "green": "#40A02B",
            "yellow": "#DF8E1D",
            "blue": "#1E66F5",
            "purple": "#8839EF",
            "cyan": "#179299",
            "white": "#ACB0BE",
            "brightBlack": "#6C6F85",
            "brightRed": "#D20F39",
            "brightGreen": "#40A02B",
            "brightYellow": "#DF8E1D",
            "brightBlue": "#1E66F5",
            "brightPurple": "#8839EF",
            "brightCyan": "#179299",
            "brightWhite": "#BCC0CC"
        },
        {
            "name": "Catppuccin Mocha",
            "cursorColor": "#F5E0DC",
            "selectionBackground": "#585B70",
            "background": "#1E1E2E",
            "foreground": "#CDD6F4",
            "black": "#45475A",
            "red": "#F38BA8",
            "green": "#A6E3A1",
            "yellow": "#F9E2AF",
            "blue": "#89B4FA",
            "purple": "#CBA6F7",
            "cyan": "#94E2D5",
            "white": "#BAC2DE",
            "brightBlack": "#585B70",
            "brightRed": "#F38BA8",
            "brightGreen": "#A6E3A1",
            "brightYellow": "#F9E2AF",
            "brightBlue": "#89B4FA",
            "brightPurple": "#CBA6F7",
            "brightCyan": "#94E2D5",
            "brightWhite": "#A6ADC8"
        }
    ],
    "actions": [
        { "command": { "action": "copy", "singleLine": false }, "keys": "ctrl+c" },
        { "command": "paste", "keys": "ctrl+v" },
        { "command": "find", "keys": "ctrl+shift+f" },
        { "command": { "action": "splitPane", "split": "auto", "splitMode": "duplicate" }, "keys": "alt+shift+d" },
        { "command": { "action": "splitPane", "split": "horizontal" }, "keys": "alt+shift+minus" },
        { "command": { "action": "splitPane", "split": "vertical" }, "keys": "alt+shift+plus" },
        { "command": { "action": "moveFocus", "direction": "left" }, "keys": "alt+left" },
        { "command": { "action": "moveFocus", "direction": "right" }, "keys": "alt+right" },
        { "command": { "action": "moveFocus", "direction": "up" }, "keys": "alt+up" },
        { "command": { "action": "moveFocus", "direction": "down" }, "keys": "alt+down" },
        { "command": "newTab", "keys": "ctrl+shift+t" },
        { "command": "closeTab", "keys": "ctrl+shift+w" },
        { "command": { "action": "nextTab" }, "keys": "ctrl+tab" },
        { "command": { "action": "prevTab" }, "keys": "ctrl+shift+tab" },
        { "command": { "action": "adjustFontSize", "delta": 1 }, "keys": "ctrl+plus" },
        { "command": { "action": "adjustFontSize", "delta": -1 }, "keys": "ctrl+minus" },
        { "command": "resetFontSize", "keys": "ctrl+0" },
        { "command": "toggleFullscreen", "keys": "alt+enter" },
        { "command": "toggleFocusMode", "keys": "ctrl+shift+enter" }
    ],
    "keybindings": []
}
"@
            Set-Content -Path $wtSettingsFile -Value $wtConfig -Encoding UTF8
            OK "Windows Terminal 配置已写入"
        } else {
            Warn "Windows Terminal 配置目录不存在: $wtSettingsDir"
            Info "请先启动一次 Windows Terminal，然后重新运行此脚本配置"
        }
    }

    Reload-Profile
}

# ── Yazi ──────────────────────────────────────────────
function Install-Yazi {
    Write-Host ""
    Info "========== [2/7] Yazi =========="

    if (Test-CommandExists "scoop") {
        Scoop-Install -package "yazi" -name "Yazi"
    } else {
        Err "需要 Scoop 来安装 Yazi，请先安装 Scoop"
        return
    }

    # 辅助依赖
    Info "安装 Yazi 辅助依赖..."
    Scoop-Install -package "fd" -name "fd (快速文件查找)"
    Scoop-Install -package "ripgrep" -name "ripgrep (内容搜索)"
    Scoop-Install -package "fzf" -name "fzf (模糊搜索)"
    Scoop-Install -package "zoxide" -name "zoxide (智能目录跳转)"
    Scoop-Install -package "poppler" -name "poppler (PDF 预览)"
    Scoop-Install -package "ffmpeg" -name "ffmpeg (视频处理)"
    Scoop-Install -package "7zip" -name "7zip (压缩包预览)"
    Scoop-Install -package "jq" -name "jq (JSON 预览)"
    Scoop-Install -package "imagemagick" -name "ImageMagick (图片处理)"

    $yaziDir = "$env:APPDATA\yazi\config"
    if (-not (Test-Path $yaziDir)) {
        New-Item -ItemType Directory -Path $yaziDir -Force | Out-Null
    }

    Write-Host ""
    Write-Host "  1) " -ForegroundColor Cyan -NoNewline; Write-Host "使用推荐配置 (glow 预览 + 大预览区 + 快捷跳转)"
    Write-Host "  2) " -ForegroundColor Cyan -NoNewline; Write-Host "使用默认配置 / 保留当前配置"
    Write-Host ""
    Write-Host "选择 Yazi 配置方案 [1/2] (默认 1): " -ForegroundColor White -NoNewline
    $yaziChoice = Read-Host

    if ($yaziChoice -ne "2") {

    # yazi.toml
    Backup-IfExists "$yaziDir\yazi.toml"
    # 安装 glow (Markdown 终端渲染)
    if (Test-CommandExists "scoop") {
        Scoop-Install -package "glow" -name "glow (Markdown 预览)"
    }

    $yaziToml = @'
# ============================================
# Yazi 文件管理器 - 主配置 (Windows)
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

# Markdown 文件使用 glow 渲染预览
[[plugin.prepend_previewers]]
url = "*.md"
run = 'piper -- CLICOLOR_FORCE=1 glow -w=$w -s=auto "$1"'

[preview]
wrap       = "yes"
tab_size   = 2
max_width  = 1000
max_height = 1000

[opener]
edit = [
    { run = '${EDITOR:-code} "%@"', block = true, for = "windows" },
]
open = [
    { run = 'Start-Process "%1"', for = "windows" },
]
reveal = [
    { run = 'explorer /select,"%1"', for = "windows" },
]

[[open.rules]]
name = "*.{md,txt,json,yaml,yml,toml,lua,py,go,rs,js,ts,tsx,jsx,sh,ps1,css,html,sql,env,conf,cfg}"
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
mime = "audio/*"
use = "open"

[[open.rules]]
use = "open"
'@
    Set-Content -Path "$yaziDir\yazi.toml" -Value $yaziToml -Encoding UTF8
    OK "yazi.toml 已写入"

    # keymap.toml
    Backup-IfExists "$yaziDir\keymap.toml"
    $yaziKeymap = @'
# ============================================
# Yazi - 快捷键配置 (Windows)
# ============================================

# --- 快速跳转 ---
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

# --- 实用操作 ---
[[mgr.prepend_keymap]]
on   = ["T"]
run  = "shell 'wt -d \"$PWD\"' --confirm"
desc = "Open in Windows Terminal"

[[mgr.prepend_keymap]]
on   = ["C"]
run  = "shell 'code \"$PWD\"' --confirm"
desc = "Open in VS Code"

[[mgr.prepend_keymap]]
on   = ["S"]
run  = "shell 'pwsh' --block --confirm"
desc = "Open shell here"
'@
    Set-Content -Path "$yaziDir\keymap.toml" -Value $yaziKeymap -Encoding UTF8
    OK "keymap.toml 已写入"

    # theme.toml
    Backup-IfExists "$yaziDir\theme.toml"
    $yaziTheme = @'
# Yazi 主题配置 (使用默认主题)
# Catppuccin 主题: ya pack -a yazi-rs/flavors:catppuccin-mocha
# 然后取消注释:
# [flavor]
# use = "catppuccin-mocha"
'@
    Set-Content -Path "$yaziDir\theme.toml" -Value $yaziTheme -Encoding UTF8
    OK "theme.toml 已写入"

    # init.lua
    Backup-IfExists "$yaziDir\init.lua"
    $yaziInit = @'
-- Yazi 插件初始化
local ok_border, full_border = pcall(require, "full-border")
if ok_border then full_border:setup() end

local ok_git, git = pcall(require, "git")
if ok_git then git:setup() end
'@
    Set-Content -Path "$yaziDir\init.lua" -Value $yaziInit -Encoding UTF8
    OK "init.lua 已写入"

    # 安装插件
    if (Test-CommandExists "ya") {
        Info "安装 Yazi 插件..."
        ya pack -a yazi-rs/plugins:full-border 2>$null; if ($LASTEXITCODE -eq 0) { OK "full-border 插件已安装" } else { Warn "full-border 可能已安装" }
        ya pack -a yazi-rs/plugins:git 2>$null; if ($LASTEXITCODE -eq 0) { OK "git 插件已安装" } else { Warn "git 可能已安装" }
        ya pack -a yazi-rs/plugins:chmod 2>$null; if ($LASTEXITCODE -eq 0) { OK "chmod 插件已安装" } else { Warn "chmod 可能已安装" }
    }

    } # end apply_yazi_config

    # Shell 集成 (y 函数)
    Setup-YaziShellWrapper
}

function Setup-YaziShellWrapper {
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    $yaziWrapper = @'

# Yazi: 退出后自动 cd 到最后浏览的目录
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content $tmp -ErrorAction SilentlyContinue
    if ($cwd -and $cwd -ne $PWD.Path) {
        Set-Location $cwd
    }
    Remove-Item $tmp -ErrorAction SilentlyContinue
}
'@

    if ($profileContent -and $profileContent.Contains("function y")) {
        OK "Yazi shell wrapper (y 函数) 已存在"
    } else {
        Add-Content -Path $PROFILE -Value $yaziWrapper
        OK "已添加 y 函数到 PowerShell Profile"
    }

    Reload-Profile
}

# ── Lazygit ───────────────────────────────────────────
function Install-Lazygit {
    Write-Host ""
    Info "========== [3/7] Lazygit =========="

    if (Test-CommandExists "scoop") {
        Scoop-Install -package "lazygit" -name "Lazygit"
        Scoop-Install -package "delta" -name "delta (语法高亮 diff)"
    } elseif (Test-CommandExists "winget") {
        Winget-Install -id "JesseDuffield.lazygit" -name "Lazygit"
        Winget-Install -id "dandavison.delta" -name "delta (语法高亮 diff)"
    }

    $lazygitDir = "$env:APPDATA\lazygit"
    $lazygitConf = "$lazygitDir\config.yml"
    if (-not (Test-Path $lazygitDir)) {
        New-Item -ItemType Directory -Path $lazygitDir -Force | Out-Null
    }

    Backup-IfExists $lazygitConf
    $lazygitConfig = @'
# ============================================
# Lazygit - 推荐配置 (Windows)
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
'@
    Set-Content -Path $lazygitConf -Value $lazygitConfig -Encoding UTF8
    OK "Lazygit 配置已写入"

    # 配置 Git Delta
    $currentPager = git config --global core.pager 2>$null
    if ($currentPager -notmatch "delta") {
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.dark true
        git config --global delta.line-numbers true
        git config --global delta.side-by-side false
        git config --global delta.hyperlinks true
        git config --global merge.conflictstyle "zdiff3"
        OK "Git Delta 全局配置已写入"
    } else {
        OK "Git Delta 已配置"
    }

    Reload-Profile
}

# ── Claude Code 提供商配置 ────────────────────────────
# 标记块的起止标识，用于在 PowerShell Profile 中定位和替换
$script:CLAUDE_BLOCK_START = "# >>> Claude Code Provider Config >>>"
$script:CLAUDE_BLOCK_END = "# <<< Claude Code Provider Config <<<"

# 从 Profile 中读取当前生效的提供商
function Detect-ClaudeProvider {
    if (-not (Test-Path $PROFILE)) { return "未配置" }
    $content = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $content -or -not $content.Contains($script:CLAUDE_BLOCK_START)) { return "未配置" }

    # 提取配置块
    $pattern = "(?s)$([regex]::Escape($script:CLAUDE_BLOCK_START))(.+?)$([regex]::Escape($script:CLAUDE_BLOCK_END))"
    $match = [regex]::Match($content, $pattern)
    if (-not $match.Success) { return "未配置" }

    $block = $match.Groups[1].Value
    if ($block -match "CLAUDE_CODE_USE_BEDROCK") { return "Amazon Bedrock" }
    if ($block -match "CLAUDE_CODE_USE_VERTEX") { return "Google Vertex AI" }
    if ($block -match "ANTHROPIC_BASE_URL") { return "自定义 API 代理" }
    if ($block -match "ANTHROPIC_API_KEY") { return "Anthropic 直连" }
    return "未知"
}

# 将配置写入 Profile（替换已有的 Claude 配置块）
function Write-ClaudeConfig {
    param([string]$configContent)

    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $content = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $content) { $content = "" }

    # 如果已有配置块，先移除
    if ($content.Contains($script:CLAUDE_BLOCK_START)) {
        $pattern = "(?s)\r?\n?$([regex]::Escape($script:CLAUDE_BLOCK_START)).+?$([regex]::Escape($script:CLAUDE_BLOCK_END))\r?\n?"
        $content = [regex]::Replace($content, $pattern, "`n")
    }

    # 追加新配置块
    $newBlock = @"

$($script:CLAUDE_BLOCK_START)
$configContent
$($script:CLAUDE_BLOCK_END)
"@
    $content = $content.TrimEnd() + "`n" + $newBlock + "`n"
    Set-Content -Path $PROFILE -Value $content -Encoding UTF8 -NoNewline
}

# 读取用户输入（带默认值）
function Read-WithDefault {
    param(
        [string]$prompt,
        [string]$default
    )
    if ($default) {
        Write-Host "  $prompt [$default]: " -ForegroundColor Cyan -NoNewline
    } else {
        Write-Host "  $prompt`: " -ForegroundColor Cyan -NoNewline
    }
    $result = Read-Host
    if ([string]::IsNullOrEmpty($result)) { return $default }
    return $result
}

# 从 Profile 现有配置块中提取某个环境变量的值
function Get-ExistingValue {
    param([string]$varName)
    if (-not (Test-Path $PROFILE)) { return "" }
    $content = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $content -or -not $content.Contains($script:CLAUDE_BLOCK_START)) { return "" }

    $pattern = "(?s)$([regex]::Escape($script:CLAUDE_BLOCK_START))(.+?)$([regex]::Escape($script:CLAUDE_BLOCK_END))"
    $match = [regex]::Match($content, $pattern)
    if (-not $match.Success) { return "" }

    $block = $match.Groups[1].Value
    $varPattern = "\`$env:${varName}\s*=\s*`"([^`"]*)`""
    $varMatch = [regex]::Match($block, $varPattern)
    if ($varMatch.Success) { return $varMatch.Groups[1].Value }
    return ""
}

function Configure-ClaudeProvider {
    Info "配置 Claude Code API 提供商"

    $currentProvider = Detect-ClaudeProvider
    Write-Host ""
    Write-Host "  当前提供商: " -NoNewline; Write-Host $currentProvider -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) " -ForegroundColor Green -NoNewline; Write-Host "Anthropic 直连        (使用 Anthropic API Key)"
    Write-Host "  2) " -ForegroundColor Green -NoNewline; Write-Host "Amazon Bedrock        (使用 AWS 凭证)"
    Write-Host "  3) " -ForegroundColor Green -NoNewline; Write-Host "Google Vertex AI      (使用 GCP 项目)"
    Write-Host "  4) " -ForegroundColor Green -NoNewline; Write-Host "自定义 API 代理       (OpenRouter / 中转站等)"
    Write-Host "  5) " -ForegroundColor Green -NoNewline; Write-Host "清除配置              (移除当前提供商设置)"
    Write-Host "  0) " -ForegroundColor Green -NoNewline; Write-Host "跳过                  (保持现有配置不变)"
    Write-Host ""
    Write-Host "  请输入选项 [0-5]: " -ForegroundColor Cyan -NoNewline
    $providerChoice = Read-Host

    switch ($providerChoice) {
        "1" {
            Info "配置 Anthropic 直连..."
            $existingKey = Get-ExistingValue "ANTHROPIC_API_KEY"
            $apiKey = Read-WithDefault "Anthropic API Key" $existingKey

            if ([string]::IsNullOrEmpty($apiKey)) {
                Err "API Key 不能为空，跳过配置"
            } else {
                $maskedKey = $apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)) + "..." + $apiKey.Substring([Math]::Max(0, $apiKey.Length - 4))
                Write-ClaudeConfig "`$env:ANTHROPIC_API_KEY = `"$apiKey`""
                OK "Anthropic 直连已配置 (Key: $maskedKey)"
            }
        }
        "2" {
            Info "配置 Amazon Bedrock..."
            Write-Host ""
            Write-Host "  认证方式:" -ForegroundColor White
            Write-Host "    a) " -ForegroundColor Green -NoNewline; Write-Host "AWS Access Key (AK/SK)"
            Write-Host "    b) " -ForegroundColor Green -NoNewline; Write-Host "AWS Profile (~/.aws/credentials)"
            Write-Host ""
            Write-Host "  选择认证方式 [a/b]: " -ForegroundColor Cyan -NoNewline
            $awsAuthMode = Read-Host

            $existingRegion = Get-ExistingValue "AWS_REGION"
            if (-not $existingRegion) { $existingRegion = "us-east-1" }
            $awsRegion = Read-WithDefault "AWS Region" $existingRegion

            $configLines = @"
`$env:CLAUDE_CODE_USE_BEDROCK = "1"
`$env:AWS_REGION = "$awsRegion"
"@

            if ($awsAuthMode -eq "b") {
                $existingProfile = Get-ExistingValue "AWS_PROFILE"
                if (-not $existingProfile) { $existingProfile = "default" }
                $awsProfile = Read-WithDefault "AWS Profile 名称" $existingProfile
                $configLines += "`n`$env:AWS_PROFILE = `"$awsProfile`""
                Write-ClaudeConfig $configLines
                OK "Amazon Bedrock 已配置 (Profile: $awsProfile, Region: $awsRegion)"
            } else {
                $existingAk = Get-ExistingValue "AWS_ACCESS_KEY_ID"
                $existingSk = Get-ExistingValue "AWS_SECRET_ACCESS_KEY"
                $existingToken = Get-ExistingValue "AWS_SESSION_TOKEN"

                $accessKey = Read-WithDefault "AWS Access Key ID" $existingAk
                $secretKey = Read-WithDefault "AWS Secret Access Key" $existingSk
                $sessionToken = Read-WithDefault "AWS Session Token (可选, 回车跳过)" $existingToken

                if ([string]::IsNullOrEmpty($accessKey) -or [string]::IsNullOrEmpty($secretKey)) {
                    Err "Access Key 和 Secret Key 不能为空，跳过配置"
                } else {
                    $configLines += @"
`n`$env:AWS_ACCESS_KEY_ID = "$accessKey"
`$env:AWS_SECRET_ACCESS_KEY = "$secretKey"
"@
                    if (-not [string]::IsNullOrEmpty($sessionToken)) {
                        $configLines += "`n`$env:AWS_SESSION_TOKEN = `"$sessionToken`""
                    }
                    Write-ClaudeConfig $configLines
                    $maskedAk = $accessKey.Substring(0, [Math]::Min(4, $accessKey.Length)) + "..." + $accessKey.Substring([Math]::Max(0, $accessKey.Length - 4))
                    OK "Amazon Bedrock 已配置 (AK: $maskedAk, Region: $awsRegion)"
                }
            }
        }
        "3" {
            Info "配置 Google Vertex AI..."
            $existingRegion = Get-ExistingValue "CLOUD_ML_REGION"
            if (-not $existingRegion) { $existingRegion = "us-east5" }
            $existingProject = Get-ExistingValue "ANTHROPIC_VERTEX_PROJECT_ID"

            $gcpProject = Read-WithDefault "GCP 项目 ID" $existingProject
            $gcpRegion = Read-WithDefault "GCP Region" $existingRegion

            if ([string]::IsNullOrEmpty($gcpProject)) {
                Err "GCP 项目 ID 不能为空，跳过配置"
            } else {
                $configContent = @"
`$env:CLAUDE_CODE_USE_VERTEX = "1"
`$env:CLOUD_ML_REGION = "$gcpRegion"
`$env:ANTHROPIC_VERTEX_PROJECT_ID = "$gcpProject"
"@
                Write-ClaudeConfig $configContent
                OK "Google Vertex AI 已配置 (项目: $gcpProject, Region: $gcpRegion)"
                Write-Host ""
                Info "提示: 请确保已通过 gcloud auth application-default login 完成认证"
            }
        }
        "4" {
            Info "配置自定义 API 代理..."
            $existingUrl = Get-ExistingValue "ANTHROPIC_BASE_URL"
            $existingKey = Get-ExistingValue "ANTHROPIC_API_KEY"

            $baseUrl = Read-WithDefault "API Base URL (例: https://openrouter.ai/api/v1)" $existingUrl
            $apiKey = Read-WithDefault "API Key" $existingKey

            if ([string]::IsNullOrEmpty($baseUrl) -or [string]::IsNullOrEmpty($apiKey)) {
                Err "Base URL 和 API Key 不能为空，跳过配置"
            } else {
                $maskedKey = $apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)) + "..." + $apiKey.Substring([Math]::Max(0, $apiKey.Length - 4))
                $configContent = @"
`$env:ANTHROPIC_BASE_URL = "$baseUrl"
`$env:ANTHROPIC_API_KEY = "$apiKey"
"@
                Write-ClaudeConfig $configContent
                OK "自定义 API 代理已配置 (URL: $baseUrl, Key: $maskedKey)"
            }
        }
        "5" {
            if (Test-Path $PROFILE) {
                $content = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
                if ($content -and $content.Contains($script:CLAUDE_BLOCK_START)) {
                    $pattern = "(?s)\r?\n?$([regex]::Escape($script:CLAUDE_BLOCK_START)).+?$([regex]::Escape($script:CLAUDE_BLOCK_END))\r?\n?"
                    $content = [regex]::Replace($content, $pattern, "`n")
                    Set-Content -Path $PROFILE -Value $content -Encoding UTF8 -NoNewline
                    OK "已清除 Claude 提供商配置"
                } else {
                    Warn "未找到已有的 Claude 提供商配置"
                }
            } else {
                Warn "未找到已有的 Claude 提供商配置"
            }
        }
        { $_ -in "0", "" } {
            OK "保持现有配置不变"
        }
        default {
            Warn "无效选项，跳过 Claude 提供商配置"
        }
    }
}

# ── Claude Code ───────────────────────────────────────
function Install-Claude {
    Write-Host ""
    Info "========== [4/7] Claude Code =========="

    if (Test-CommandExists "claude") {
        OK "Claude Code 已安装: $(claude --version 2>$null)"
    } else {
        Info "正在安装 Claude Code..."
        $installed = $false

        # 尝试官方安装脚本
        try {
            irm https://claude.ai/install.ps1 | iex
            # 刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            if (Test-CommandExists "claude") {
                $installed = $true
                OK "Claude Code 安装完成"
            }
        } catch {
            Warn "官方脚本安装失败，尝试 npm..."
        }

        if (-not $installed) {
            # 尝试 npm 全局安装
            if (Test-CommandExists "npm") {
                try {
                    npm install -g @anthropic-ai/claude-code
                    $installed = $true
                    OK "Claude Code (npm) 安装完成"
                } catch {
                    Err "npm 安装 Claude Code 失败"
                }
            }
        }

        if (-not $installed) {
            Err "Claude Code 安装失败，请手动安装: https://claude.ai/download"
        }
    }

    # ── 提供商配置 ──────────────────────────────────────
    Write-Host ""
    Configure-ClaudeProvider

    Write-Host ""
    Info "Claude Code 使用提示:"
    Write-Host "   claude              启动交互式会话"
    Write-Host "   claude `"问题`"       直接提问"
    Write-Host "   claude -p `"问题`"    非交互模式 (管道友好)"
    Write-Host "   首次使用需要登录:    claude login"

    Reload-Profile
}

# ── OpenClaw ──────────────────────────────────────────
function Install-OpenClaw {
    Write-Host ""
    Info "========== [5/7] OpenClaw =========="

    if (Test-CommandExists "openclaw") {
        OK "OpenClaw 已安装"
    } else {
        Info "正在安装 OpenClaw..."
        $installed = $false
        if (Test-CommandExists "scoop") {
            try {
                Scoop-Install -package "openclaw-cli" -name "OpenClaw CLI"
                $installed = $true
            } catch {}
        }
        if (-not $installed -and (Test-CommandExists "winget")) {
            Winget-Install -id "OpenClaw.CLI" -name "OpenClaw CLI"
        }
    }

    # 可选安装 GUI 版本
    Write-Host ""
    Write-Host "是否安装 OpenClaw 桌面应用? [y/N]: " -ForegroundColor White -NoNewline
    $installGui = Read-Host
    if ($installGui -match '^[yY]$') {
        if (Test-CommandExists "winget") {
            Winget-Install -id "OpenClaw.OpenClaw" -name "OpenClaw Desktop"
        } elseif (Test-CommandExists "scoop") {
            Scoop-Install -package "openclaw" -name "OpenClaw Desktop"
        }
    }

    Write-Host ""
    Info "OpenClaw 使用提示:"
    Write-Host "   openclaw            启动 OpenClaw"
    Write-Host "   openclaw onboard    首次设置向导"

    Reload-Profile
}

# ── Antigravity ──────────────────────────────────────
function Install-Antigravity {
    Write-Host ""
    Info "========== [6/7] Antigravity =========="

    $installed = $false
    if (Test-CommandExists "winget") {
        Winget-Install -id "Google.Antigravity" -name "Antigravity"
        $installed = $true
    }
    if (-not $installed -and (Test-CommandExists "scoop")) {
        Scoop-Install -package "antigravity" -name "Antigravity"
    }

    Write-Host ""
    Info "Antigravity 使用提示:"
    Write-Host "   从开始菜单启动 Antigravity"
    Write-Host "   首次启动需要 Google 账号登录"

    Reload-Profile
}

# ── OrbStack (Docker Desktop on Windows) ─────────────
function Install-OrbStack {
    Write-Host ""
    Info "========== [7/7] Docker Desktop =========="

    $installed = $false
    if (Test-CommandExists "winget") {
        Winget-Install -id "Docker.DockerDesktop" -name "Docker Desktop"
        $installed = $true
    }
    if (-not $installed -and (Test-CommandExists "scoop")) {
        # Docker Desktop 不在 scoop main bucket，用 winget 优先
        Warn "Docker Desktop 建议通过 winget 安装，请运行: winget install Docker.DockerDesktop"
    }

    Write-Host ""
    Info "Docker Desktop 使用提示:"
    Write-Host "   从开始菜单启动 Docker Desktop"
    Write-Host "   支持 Docker 容器、Kubernetes、WSL 2 集成"
    Write-Host "   macOS 上对应工具为 OrbStack (更轻量)"

    Reload-Profile
}

# ══════════════════════════════════════════════════════
# 主流程
# ══════════════════════════════════════════════════════
function Main {
    # 保存原始参数（用于 pwsh 自动切换时传递）
    $script:OriginalArgs = $args

    # 基础环境检查（始终最先运行）
    Check-Prerequisites

    # 解析参数（可能进入交互菜单选择工具）
    Parse-Args -arguments $args

    # 仅修改 Claude 提供商配置
    if (Is-Selected "claude-provider") {
        Write-Host ""
        Configure-ClaudeProvider
        Reload-Profile
        return
    }

    # 安装选中的工具
    if ($script:SELECTED_TOOLS.Count -gt 0) {
        Write-Host ""
        Info "即将安装: $($script:SELECTED_TOOLS -join ' ')"
        Write-Host ""

        if (Is-Selected "terminal")    { Install-Terminal }
        if (Is-Selected "yazi")        { Install-Yazi }
        if (Is-Selected "lazygit")     { Install-Lazygit }
        if (Is-Selected "claude")      { Install-Claude }
        if (Is-Selected "openclaw")    { Install-OpenClaw }
        if (Is-Selected "antigravity") { Install-Antigravity }
        if (Is-Selected "orbstack")    { Install-OrbStack }
    }

    # 跳过模式：提供配置操作菜单
    if ($script:SKIP_PREREQUISITES -and $script:SELECTED_TOOLS.Count -eq 0) {
        Write-Host ""
        Info "========== 配置操作 =========="
        Write-Host ""
        Write-Host "  1) " -ForegroundColor Green -NoNewline; Write-Host "修改 Claude 提供商配置"
        Write-Host "  0) " -ForegroundColor Green -NoNewline; Write-Host "退出"
        Write-Host ""
        Write-Host "  请选择 [0-1]: " -ForegroundColor Cyan -NoNewline
        $configChoice = Read-Host

        switch ($configChoice) {
            "1" { Configure-ClaudeProvider }
            default { OK "已退出" }
        }
    }

    # ── 完成 ──────────────────────────────────────────
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  All done! 全部完成" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""

    if ($script:SELECTED_TOOLS.Count -gt 0) {
        Write-Host "已安装: $($script:SELECTED_TOOLS -join ' ')"
        Write-Host ""
    }

    if (Is-Selected "terminal") {
        Write-Host "  Terminal  $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    }
    if (Is-Selected "yazi") {
        Write-Host "  Yazi      $env:APPDATA\yazi\config\"
    }
    if (Is-Selected "lazygit") {
        Write-Host "  Lazygit   $env:APPDATA\lazygit\config.yml"
    }
    if (Is-Selected "claude") {
        Write-Host "  Claude    $PROFILE (>>> Claude Code Provider Config >>> 块)"
    }
    Write-Host ""

    Reload-Profile
}

# 运行主流程
Main @args
