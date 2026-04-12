# ============================================================
# Windows Dev Tools One-Click Install & Configuration
# Supports: Ghostty / Yazi / Lazygit / Claude Code / OpenClaw / Hermes Agent / Docker Desktop / Obsidian / Ditto / JDK / VS Code
# Usage:
#   Install all:    .\install.ps1
#   Select tools:   .\install.ps1 ghostty yazi lazygit claude openclaw hermes orbstack obsidian maccy jdk vscode
#   Show help:      .\install.ps1 --help
# Requires: Windows 10+ / PowerShell 5.1+
# ============================================================

#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# -- Color Output ------------------------------------------------
function Info  { param([string]$msg) Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Ok    { param([string]$msg) Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Warn  { param([string]$msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Err   { param([string]$msg) Write-Host "[ERR ] $msg" -ForegroundColor Red }

# -- System Detection --------------------------------------------
$ARCH = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# -- Mirror Acceleration Config ----------------------------------
$script:USE_MIRROR = $false
$script:GITHUB_PROXY = ""

function Setup-Mirror {
    if (-not $script:USE_MIRROR) {
        Write-Host ""
        Write-Host "Checking network connectivity..." -ForegroundColor White -NoNewline
        try {
            $null = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/github/gitignore/main/README.md" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
            Ok "GitHub connection is OK"
            $choice = Read-Host "Use mirror acceleration anyway? [y/N]"
            if ($choice -match '^[yY]$') { $script:USE_MIRROR = $true }
        } catch {
            Warn "GitHub connection is slow or unavailable"
            $choice = Read-Host "Use mirror acceleration? [Y/n]"
            if ($choice -notmatch '^[nN]$') { $script:USE_MIRROR = $true }
        }
    }

    if ($script:USE_MIRROR) {
        $script:GITHUB_PROXY = "https://ghfast.top/"

        # Prevent git from popping up credential dialogs (avoid popup after timeout)
        $env:GIT_TERMINAL_PROMPT = "0"

        Ok "Mirror acceleration enabled"
        Info "  GitHub proxy: $($script:GITHUB_PROXY)"
    }
}

function GitHub-RawUrl {
    param([string]$url)
    if ($script:USE_MIRROR) { return "$($script:GITHUB_PROXY)$url" }
    return $url
}

# -- Help Info ---------------------------------------------------
function Show-Help {
    @"
Windows Dev Tools One-Click Install Script

Usage:
  .\install.ps1                 Interactive tool selection
  .\install.ps1 --all           Install all tools
  .\install.ps1 --skip          Skip installation, configure only
  .\install.ps1 --mirror        Force mirror acceleration
  .\install.ps1 <tool> ...      Install specified tools only

Available tools:
  ghostty          GPU-accelerated terminal emulator
  yazi             Terminal file manager
  lazygit          Terminal Git UI
  claude           Claude Code (AI coding assistant)
  openclaw         OpenClaw (local AI assistant)
  hermes           Hermes Agent (Nous Research self-learning AI Agent)
  antigravity      Google Antigravity (AI development platform)
  orbstack         Docker Desktop (containers & Kubernetes)
  obsidian         Obsidian (knowledge management & notes)
  maccy            Ditto (clipboard manager, Maccy alternative)
  jdk              JDK (via winget/scoop)
  vscode           VS Code (code editor + Catppuccin theme)
  claude-provider  Configure Claude API provider only

Examples:
  .\install.ps1 ghostty yazi          Install Ghostty and Yazi only
  .\install.ps1 claude openclaw       Install AI tools only
  .\install.ps1 claude-provider       Switch Claude provider only
  .\install.ps1 --skip                Skip installation, enter config menu
  .\install.ps1 --all                 Install everything
"@
    exit 0
}

# -- Tool Definitions --------------------------------------------
$ALL_TOOLS = @("ghostty", "yazi", "lazygit", "claude", "openclaw", "hermes", "antigravity", "orbstack", "obsidian", "maccy", "jdk", "vscode")
$script:SELECTED_TOOLS = @()
$script:SKIP_PREREQUISITES = $false

# -- Command Execution with Timeout ------------------------------
function Run-WithTimeout {
    param(
        [string]$Command,
        [string]$Name,
        [int]$TimeoutSec = 120
    )
    Info "$Name ..."
    $job = Start-Job -ScriptBlock ([scriptblock]::Create($Command))
    $finished = $job | Wait-Job -Timeout $TimeoutSec
    if ($finished) {
        $output = Receive-Job $job 2>&1
        $exitCode = if ($job.State -eq "Completed") { 0 } else { 1 }
        Remove-Job $job -Force
        if ($exitCode -eq 0) {
            Ok "$Name completed"
            return $true
        }
        Warn "$Name failed: $output"
        return $false
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        Warn "$Name timed out (${TimeoutSec}s), skipped"
        return $false
    }
}

# -- Package Manager Helpers -------------------------------------
function Ensure-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Ok "Scoop already installed"
        return
    }
    Info "Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    try {
        if ($isAdmin) {
            Invoke-Expression "& {$(Invoke-RestMethod -Uri 'https://get.scoop.sh' -TimeoutSec 30)} -RunAsAdmin"
        } else {
            Invoke-RestMethod -Uri "https://get.scoop.sh" -TimeoutSec 30 | Invoke-Expression
        }
    } catch {
        Err "Scoop installation failed (network timeout). Please install manually: https://scoop.sh"
        return
    }
    Refresh-Path
    $scoopShim = "$env:USERPROFILE\scoop\shims"
    if (Test-Path $scoopShim) { $env:Path = "$scoopShim;$env:Path" }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Ok "Scoop installed successfully"
    } else {
        Err "Scoop command not available after install. Please close the terminal and rerun the script"
    }
}

function Ensure-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Ok "winget is available"
        return $true
    }
    Warn "winget is not available (Windows 10 requires manual App Installer installation)"
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
        Ok "$Name already installed"
        return
    }

    Info "Installing $Name ..."
    $wingetArgs = @("install", "--id", $Id, "--accept-source-agreements", "--accept-package-agreements")
    if (-not $Interactive) { $wingetArgs += "--silent" }

    & winget @wingetArgs 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Ok "$Name installed successfully"
    } else {
        Err "$Name installation failed"
    }
}

function Scoop-Install {
    param(
        [string]$Package,
        [string]$Name,
        [string]$Bucket,
        [int]$TimeoutSec = 120
    )

    if (scoop list $Package 2>$null | Select-String $Package) {
        Ok "$Name already installed (scoop)"
        return $true
    }

    if ($Bucket) {
        scoop bucket add $Bucket 2>$null
    }

    Info "Installing $Name (scoop, ${TimeoutSec}s timeout)..."
    $job = Start-Job -ScriptBlock { param($p) scoop install $p 2>&1 } -ArgumentList $Package
    $finished = $job | Wait-Job -Timeout $TimeoutSec
    if ($finished) {
        $output = Receive-Job $job 2>&1
        Remove-Job $job -Force
        Refresh-Path
        Ok "$Name installed successfully"
        return $true
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        Warn "$Name installation timed out (${TimeoutSec}s), skipped"
        return $false
    }
}

# -- Interactive Multi-Select Menu (numeric input, irm | iex compatible) --
function Interactive-Select {
    $labels = @(
        " 1) Ghostty      GPU-accelerated terminal emulator (blur/split/Quake dropdown)"
        " 2) Yazi         Terminal file manager (fast preview/Vim-style navigation)"
        " 3) Lazygit      Terminal Git UI (visual commit/branch/merge)"
        " 4) Claude Code  Anthropic AI coding assistant (in-terminal AI programming)"
        " 5) OpenClaw     Local AI assistant (self-hosted/task automation)"
        " 6) Hermes       Nous Research self-learning AI Agent (skills/memory/multi-platform)"
        " 7) Antigravity  Google AI development platform (smart coding/Agent workflow)"
        " 8) Docker       Docker Desktop (containers & Kubernetes)"
        " 9) Obsidian     Knowledge management & notes (Markdown/backlinks/plugins)"
        "10) Ditto        Clipboard manager (Maccy alternative, open-source/quick search)"
        "11) JDK          Java Development Kit (multi-version switching)"
        "12) VS Code      Code editor (Catppuccin theme/auto extension install)"
    )

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "   Windows Dev Tools One-Click Installer        " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($label in $labels) {
        Write-Host "  $label" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "  A) Install all" -ForegroundColor Green
    Write-Host "  S) Skip installation, configure only" -ForegroundColor Yellow
    Write-Host "  Q) Quit" -ForegroundColor Red
    Write-Host ""
    $input = Read-Host "Enter numbers (comma-separated for multiple, e.g.: 1,3,4)"

    if (-not $input -or $input -match '^[qQ]$') {
        Write-Host "Cancelled."
        exit 0
    }

    if ($input -match '^[aA]$') {
        $script:SELECTED_TOOLS = @() + $ALL_TOOLS
        return
    }

    if ($input -match '^[sS]$') {
        $script:SKIP_PREREQUISITES = $true
        $script:SELECTED_TOOLS = @()
        Info "Skipping tool installation, entering config menu"
        return
    }

    # Parse comma-separated numbers
    $nums = $input -split '[,\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
    foreach ($num in $nums) {
        $idx = [int]$num - 1
        if ($idx -ge 0 -and $idx -lt $ALL_TOOLS.Count) {
            if ($ALL_TOOLS[$idx] -notin $script:SELECTED_TOOLS) {
                $script:SELECTED_TOOLS += $ALL_TOOLS[$idx]
            }
        } else {
            Warn "Invalid number: $num (valid range 1-$($ALL_TOOLS.Count))"
        }
    }

    if ($script:SELECTED_TOOLS.Count -eq 0) {
        $script:SKIP_PREREQUISITES = $true
        Info "No tools selected, skipping installation"
    }
}

# -- Parse Arguments ---------------------------------------------
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
                Err "Unknown option: $arg"
                Write-Host "Run .\install.ps1 --help for usage info"
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
        Warn "Backing up existing config: $Path -> $backup"
        Copy-Item -Path $Path -Destination $backup -Recurse -Force
    }
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# -- PowerShell Profile Helpers ----------------------------------
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
        Ok "$Name already configured in PowerShell Profile"
    } else {
        Add-Content -Path $profilePath -Value "`n# $Name`n$InitLine"
        Ok "$Name init added to PowerShell Profile"
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

# ================================================================
# Prerequisites Check (dependency order: network -> pkg mgr -> base tools -> runtimes -> config)
# ================================================================
function Check-Prerequisites {
    Write-Host ""
    Write-Host "========== Prerequisites Check ==========" -ForegroundColor Cyan
    Write-Host ""

    # == Phase 1: Network & Package Managers ====================

    # -- 1. Network connectivity check --------------------------
    Setup-Mirror

    # -- 2. Package managers ------------------------------------
    $hasWinget = Ensure-Winget
    Ensure-Scoop

    # -- 3. Git (Scoop bucket dependency) -----------------------
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Ok "Git already installed: $(git --version)"
    } else {
        Scoop-Install -Package "git" -Name "Git" -TimeoutSec 60
        Refresh-Path
    }

    # -- 4. Mirror mode additional config -----------------------
    if ($script:USE_MIRROR) {
        $env:GIT_TERMINAL_PROMPT = "0"
        Ok "Mirror mode enabled, GitHub downloads accelerated via ghfast.top"
    }

    # -- 5. Scoop Buckets (30s timeout) -------------------------
    $buckets = @("extras", "versions", "nerd-fonts")
    foreach ($bucket in $buckets) {
        $existing = scoop bucket list 2>$null | Select-String $bucket
        if ($existing) {
            Ok "Scoop bucket '$bucket' already added"
        } else {
            $job = Start-Job -ScriptBlock { param($b) scoop bucket add $b 2>&1 } -ArgumentList $bucket
            $finished = $job | Wait-Job -Timeout 30
            if ($finished) {
                Receive-Job $job | Out-Null
                Remove-Job $job -Force
                Ok "Scoop bucket '$bucket' added"
            } else {
                Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -Force
                Warn "Scoop bucket '$bucket' add timed out, skipped"
            }
        }
    }

    # == Phase 2: Development Runtimes ==========================

    # -- 6. NVM + Node.js ---------------------------------------
    if (Get-Command nvm -ErrorAction SilentlyContinue) {
        Ok "NVM for Windows already installed"
    } else {
        Scoop-Install -Package "nvm" -Name "NVM for Windows" -TimeoutSec 60
    }

    Refresh-Path

    if (Get-Command node -ErrorAction SilentlyContinue) {
        Ok "Node.js already installed: $(node --version)"
    } else {
        if (Get-Command nvm -ErrorAction SilentlyContinue) {
            Info "Installing Node.js LTS via NVM..."
            nvm install lts
            nvm use lts
            Ok "Node.js installed successfully"
        } else {
            Scoop-Install -Package "nodejs-lts" -Name "Node.js" -TimeoutSec 60
        }
    }

    Refresh-Path

    # -- 7. Bun -------------------------------------------------
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        Ok "Bun already installed: $(bun --version)"
    } else {
        Scoop-Install -Package "bun" -Name "Bun" -TimeoutSec 60
    }

    # == Phase 3: Shell Prompt Config (optional) ================

    Write-Host ""
    Write-Host "Select shell prompt tool:" -ForegroundColor White
    Write-Host "  1) Starship (cross-platform fast prompt, recommended)" -ForegroundColor Cyan
    Write-Host "  2) Oh My Posh (PowerShell beautification)" -ForegroundColor Cyan
    Write-Host "  3) Skip (keep current config)" -ForegroundColor Cyan
    $promptChoice = Read-Host "Select option [1/2/3] (default 3)"
    if (-not $promptChoice) { $promptChoice = "3" }

    if ($promptChoice -eq "1") {
        # -- Starship -------------------------------------------
        if (Get-Command starship -ErrorAction SilentlyContinue) {
            Ok "Starship already installed"
        } else {
            Scoop-Install -Package "starship" -Name "Starship" -TimeoutSec 60
        }

        # Nerd Font
        Write-Host ""
        Write-Host "Select Nerd Font:" -ForegroundColor White
        Write-Host "  1) Hack Nerd Font (recommended)" -ForegroundColor Cyan
        Write-Host "  2) JetBrainsMono Nerd Font" -ForegroundColor Cyan
        Write-Host "  3) FiraCode Nerd Font" -ForegroundColor Cyan
        Write-Host "  4) MesloLG Nerd Font" -ForegroundColor Cyan
        Write-Host "  5) CascadiaCode Nerd Font" -ForegroundColor Cyan
        Write-Host "  6) Skip" -ForegroundColor Cyan
        $fontChoice = Read-Host "Select option [1-6] (default 1)"
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
            Warn "Please switch your terminal font to the corresponding Nerd Font in terminal settings"
        }

        # Starship theme
        $starshipConfig = "$env:USERPROFILE\.config\starship.toml"
        $starshipDir = Split-Path $starshipConfig
        if (-not (Test-Path $starshipDir)) { New-Item -ItemType Directory -Path $starshipDir -Force | Out-Null }

        Write-Host ""
        Write-Host "Select Starship theme:" -ForegroundColor White
        Write-Host "   1) Catppuccin Mocha Powerline (recommended)" -ForegroundColor Cyan
        Write-Host "   2) catppuccin-powerline" -ForegroundColor Cyan
        Write-Host "   3) gruvbox-rainbow" -ForegroundColor Cyan
        Write-Host "   4) tokyo-night" -ForegroundColor Cyan
        Write-Host "   5) pastel-powerline" -ForegroundColor Cyan
        Write-Host "   6) jetpack" -ForegroundColor Cyan
        Write-Host "   7) pure-preset" -ForegroundColor Cyan
        Write-Host "   8) nerd-font-symbols" -ForegroundColor Cyan
        Write-Host "   9) plain-text-symbols (no Nerd Font needed)" -ForegroundColor Cyan
        Write-Host "  10) Skip" -ForegroundColor Cyan
        $themeChoice = Read-Host "Select option [1-10] (default 1)"
        if (-not $themeChoice) { $themeChoice = "1" }

        $gistUrl = "https://gist.githubusercontent.com/zhangchitc/62f5dca64c599084f936fda9963f1100/raw/starship.toml"

        switch ($themeChoice) {
            "1"  {
                Info "Downloading Catppuccin Mocha theme..."
                try {
                    Invoke-WebRequest -Uri (GitHub-RawUrl $gistUrl) -OutFile $starshipConfig -UseBasicParsing -TimeoutSec 15
                    Ok "Starship theme applied: Catppuccin Mocha Powerline"
                } catch {
                    Warn "Download failed, falling back to built-in catppuccin-powerline"
                    starship preset catppuccin-powerline -o $starshipConfig 2>$null
                }
            }
            "2"  { starship preset catppuccin-powerline -o $starshipConfig 2>$null; Ok "Theme: catppuccin-powerline" }
            "3"  { starship preset gruvbox-rainbow -o $starshipConfig 2>$null; Ok "Theme: gruvbox-rainbow" }
            "4"  { starship preset tokyo-night -o $starshipConfig 2>$null; Ok "Theme: tokyo-night" }
            "5"  { starship preset pastel-powerline -o $starshipConfig 2>$null; Ok "Theme: pastel-powerline" }
            "6"  { starship preset jetpack -o $starshipConfig 2>$null; Ok "Theme: jetpack" }
            "7"  { starship preset pure-preset -o $starshipConfig 2>$null; Ok "Theme: pure-preset" }
            "8"  { starship preset nerd-font-symbols -o $starshipConfig 2>$null; Ok "Theme: nerd-font-symbols" }
            "9"  { starship preset plain-text-symbols -o $starshipConfig 2>$null; Ok "Theme: plain-text-symbols" }
            "10" { Ok "Keeping existing Starship config" }
        }

        Ensure-ProfileInit 'Invoke-Expression (&starship init powershell)' "Starship"

    } elseif ($promptChoice -eq "2") {
        # -- Oh My Posh -----------------------------------------
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Ok "Oh My Posh already installed"
        } else {
            Scoop-Install -Package "oh-my-posh" -Name "Oh My Posh" -TimeoutSec 60
        }
        Ensure-ProfileInit 'oh-my-posh init pwsh | Invoke-Expression' "Oh My Posh"
    } else {
        Ok "Skipped shell prompt configuration"
    }

    Write-Host ""
    Write-Host "Prerequisites check completed" -ForegroundColor Green
    Write-Host ""
}

# ================================================================
# Installation Modules
# ================================================================

# -- Ghostty -----------------------------------------------------
function Install-Ghostty {
    Write-Host ""
    Info "========== [1/12] Ghostty =========="

    if (Get-Command ghostty -ErrorAction SilentlyContinue) {
        Ok "Ghostty already installed"
    } else {
        Info "Installing Ghostty..."
        $installed = $false
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            try {
                Winget-Install -Id "com.mitchellh.ghostty" -Name "Ghostty"
                $installed = $true
            } catch {}
        }
        if (-not $installed) {
            Warn "Ghostty for Windows may not be available. Please download from https://ghostty.org/download"
            Warn "Alternative: winget install Microsoft.WindowsTerminal"
        }
    }

    $ghosttyDir = "$env:APPDATA\ghostty"
    $ghosttyConf = "$ghosttyDir\config"
    if (-not (Test-Path $ghosttyDir)) { New-Item -ItemType Directory -Path $ghosttyDir -Force | Out-Null }

    Write-Host ""
    Write-Host "  1) Use recommended config (Maple Mono + Catppuccin + blur effect)" -ForegroundColor Cyan
    Write-Host "  2) Use default config / keep current config" -ForegroundColor Cyan
    Write-Host ""
    $ghosttyChoice = Read-Host "Select Ghostty config [1/2] (default 1)"
    if (-not $ghosttyChoice) { $ghosttyChoice = "1" }

    if ($ghosttyChoice -ne "2") {
        Backup-IfExists $ghosttyConf
        @"
# ============================================
# Ghostty Terminal - Windows Config
# ============================================

# --- Font & Typography ---
font-family = "Maple Mono NF CN"
font-size = 12
font-thicken = true
adjust-cell-height = 2

# --- Theme & Colors ---
theme = Catppuccin Latte

# --- Window & Appearance ---
background-opacity = 0.85
window-padding-x = 10
window-padding-y = 8
window-save-state = always
window-theme = auto

# --- Cursor ---
cursor-style = bar
cursor-style-blink = true
cursor-opacity = 0.8

# --- Mouse ---
mouse-hide-while-typing = true
copy-on-select = clipboard

# --- Security ---
clipboard-paste-protection = true
clipboard-paste-bracketed-safe = true

# --- Shell Integration ---
shell-integration = detect

# --- Keybindings ---
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

# --- Performance ---
scrollback-limit = 25000000
"@ | Set-Content -Path $ghosttyConf -Encoding UTF8
        Ok "Ghostty config written (Windows)"
    }
}

# -- Yazi --------------------------------------------------------
function Install-Yazi {
    Write-Host ""
    Info "========== [2/12] Yazi =========="

    Scoop-Install -Package "yazi" -Name "Yazi"

    Info "Installing Yazi helper dependencies..."
    Scoop-Install -Package "fd" -Name "fd (fast file finder)"
    Scoop-Install -Package "ripgrep" -Name "ripgrep (content search)"
    Scoop-Install -Package "fzf" -Name "fzf (fuzzy finder)"
    Scoop-Install -Package "zoxide" -Name "zoxide (smart directory jump)"
    Scoop-Install -Package "poppler" -Name "poppler (PDF preview)"
    Scoop-Install -Package "ffmpeg" -Name "ffmpeg (video processing)"
    Scoop-Install -Package "7zip" -Name "7zip (archive preview)"
    Scoop-Install -Package "jq" -Name "jq (JSON preview)"
    Scoop-Install -Package "imagemagick" -Name "ImageMagick (image processing)"

    $yaziDir = "$env:APPDATA\yazi\config"
    if (-not (Test-Path $yaziDir)) { New-Item -ItemType Directory -Path $yaziDir -Force | Out-Null }

    Write-Host ""
    Write-Host "  1) Use recommended config (glow preview + large preview area + quick jump)" -ForegroundColor Cyan
    Write-Host "  2) Use default config / keep current config" -ForegroundColor Cyan
    Write-Host ""
    $yaziChoice = Read-Host "Select Yazi config [1/2] (default 1)"
    if (-not $yaziChoice) { $yaziChoice = "1" }

    if ($yaziChoice -ne "2") {
        Scoop-Install -Package "glow" -Name "glow (Markdown preview)"

        Backup-IfExists "$yaziDir\yazi.toml"
        @"
# ============================================
# Yazi File Manager - Main Config
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
        Ok "yazi.toml written"

        Backup-IfExists "$yaziDir\keymap.toml"
        @"
# ============================================
# Yazi - Keymap Config
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
        Ok "keymap.toml written"

        Backup-IfExists "$yaziDir\theme.toml"
        @"
# Yazi theme config (using default theme)
# Catppuccin: ya pack -a yazi-rs/flavors:catppuccin-mocha
"@ | Set-Content -Path "$yaziDir\theme.toml" -Encoding UTF8
        Ok "theme.toml written"

        Backup-IfExists "$yaziDir\init.lua"
        @"
-- Yazi plugin initialization
local ok_border, full_border = pcall(require, "full-border")
if ok_border then full_border:setup() end

local ok_git, git = pcall(require, "git")
if ok_git then git:setup() end
"@ | Set-Content -Path "$yaziDir\init.lua" -Encoding UTF8
        Ok "init.lua written"

        if (Get-Command ya -ErrorAction SilentlyContinue) {
            Info "Installing Yazi plugins..."
            ya pack -a yazi-rs/plugins:full-border 2>$null
            ya pack -a yazi-rs/plugins:git 2>$null
            ya pack -a yazi-rs/plugins:chmod 2>$null
            Ok "Yazi plugins installed"
        }
    }

    # Shell integration (y function)
    $yaziWrapper = @'
# Yazi: auto cd to last browsed directory on exit
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
    if ($added) { Ok "Added y command to PowerShell Profile" }
    else { Ok "Yazi shell wrapper (y command) already exists" }
}

# -- Lazygit -----------------------------------------------------
function Install-Lazygit {
    Write-Host ""
    Info "========== [3/12] Lazygit =========="

    Scoop-Install -Package "lazygit" -Name "Lazygit"
    Scoop-Install -Package "delta" -Name "delta (syntax-highlighted diff)"

    $lazygitDir = "$env:APPDATA\lazygit"
    $lazygitConf = "$lazygitDir\config.yml"
    if (-not (Test-Path $lazygitDir)) { New-Item -ItemType Directory -Path $lazygitDir -Force | Out-Null }

    Backup-IfExists $lazygitConf
    @"
# ============================================
# Lazygit - Recommended Config
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
    Ok "Lazygit config written"

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
        Ok "Git Delta global config written"
    } else {
        Ok "Git Delta already configured"
    }
}

# -- Claude Code Provider Config ---------------------------------
# Dual-write strategy: set both Windows user env vars + ~/.claude/settings.json
# Ensures Claude Code reads config regardless of how it is launched

$CLAUDE_SETTINGS_PATH = "$env:USERPROFILE\.claude\settings.json"

$script:PROVIDER_KEYS = @(
    "ANTHROPIC_API_KEY", "ANTHROPIC_BASE_URL",
    "CLAUDE_CODE_USE_BEDROCK", "AWS_REGION", "AWS_PROFILE",
    "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN",
    "CLAUDE_CODE_USE_VERTEX", "CLOUD_ML_REGION", "ANTHROPIC_VERTEX_PROJECT_ID"
)

function Detect-ClaudeProvider {
    # Prefer user environment variables for detection
    $userBedrock = [Environment]::GetEnvironmentVariable("CLAUDE_CODE_USE_BEDROCK", "User")
    $userVertex  = [Environment]::GetEnvironmentVariable("CLAUDE_CODE_USE_VERTEX", "User")
    $userBaseUrl = [Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "User")
    $userApiKey  = [Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")

    if ($userBedrock) { return "Amazon Bedrock" }
    if ($userVertex)  { return "Google Vertex AI" }
    if ($userBaseUrl) { return "Custom API Proxy" }
    if ($userApiKey)  { return "Anthropic Direct" }
    return "Not configured"
}

function Write-ClaudeEnv {
    param([hashtable]$EnvVars)

    # 1. Clear old provider environment variables first
    foreach ($key in $script:PROVIDER_KEYS) {
        [Environment]::SetEnvironmentVariable($key, $null, "User")
    }

    # 2. Set new user environment variables (effective for all new processes immediately)
    foreach ($k in $EnvVars.Keys) {
        [Environment]::SetEnvironmentVariable($k, $EnvVars[$k], "User")
        # Also set current process env var (effective immediately)
        Set-Item -Path "Env:\$k" -Value $EnvVars[$k]
    }

    # 3. Also write to ~/.claude/settings.json (dual insurance)
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

    # Build env field: preserve non-provider keys + write new keys
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

    # Clear user environment variables
    foreach ($key in $script:PROVIDER_KEYS) {
        $val = [Environment]::GetEnvironmentVariable($key, "User")
        if ($val) {
            [Environment]::SetEnvironmentVariable($key, $null, "User")
            Remove-Item -Path "Env:\$key" -ErrorAction SilentlyContinue
            $cleared = $true
        }
    }

    # Clear provider keys from settings.json
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
    # Prefer reading from user environment variables
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
    Info "Configure Claude Code API provider"

    $currentProvider = Detect-ClaudeProvider
    Write-Host ""
    Write-Host "  Current provider: $currentProvider" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) Anthropic Direct      (using Anthropic API Key)" -ForegroundColor Green
    Write-Host "  2) Amazon Bedrock        (using AWS credentials)" -ForegroundColor Green
    Write-Host "  3) Google Vertex AI      (using GCP project)" -ForegroundColor Green
    Write-Host "  4) Custom API Proxy      (OpenRouter / relay, etc.)" -ForegroundColor Green
    Write-Host "  5) Clear config          (remove current provider settings)" -ForegroundColor Green
    Write-Host "  0) Skip                  (keep current config unchanged)" -ForegroundColor Green
    Write-Host ""
    $providerChoice = Read-Host "  Select option [0-5]"

    switch ($providerChoice) {
        "1" {
            Info "Configuring Anthropic Direct..."
            $existingKey = Get-ExistingValue "ANTHROPIC_API_KEY"
            $apiKey = Read-WithDefault "  Anthropic API Key" $existingKey
            if (-not $apiKey) {
                Err "API Key cannot be empty, skipping config"
            } else {
                $masked = "$($apiKey.Substring(0,8))...$($apiKey.Substring($apiKey.Length-4))"
                Write-ClaudeEnv @{ "ANTHROPIC_API_KEY" = $apiKey }
                Ok "Anthropic Direct configured (Key: $masked)"
                Info "Written to user env vars + $CLAUDE_SETTINGS_PATH"
            }
        }
        "2" {
            Info "Configuring Amazon Bedrock..."
            Write-Host ""
            Write-Host "  Authentication method:" -ForegroundColor White
            Write-Host "    a) AWS Access Key (AK/SK)" -ForegroundColor Green
            Write-Host "    b) AWS Profile (~/.aws/credentials)" -ForegroundColor Green
            Write-Host ""
            $awsAuthMode = Read-Host "  Select auth method [a/b]"

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
                $awsProfile = Read-WithDefault "  AWS Profile name" $defaultProfile
                $envVars["AWS_PROFILE"] = $awsProfile
                Write-ClaudeEnv $envVars
                Ok "Amazon Bedrock configured (Profile: $awsProfile, Region: $awsRegion)"
                Info "Written to user env vars + $CLAUDE_SETTINGS_PATH"
            } else {
                $existingAK = Get-ExistingValue "AWS_ACCESS_KEY_ID"
                $existingSK = Get-ExistingValue "AWS_SECRET_ACCESS_KEY"
                $existingToken = Get-ExistingValue "AWS_SESSION_TOKEN"

                $accessKey = Read-WithDefault "  AWS Access Key ID" $existingAK
                $secretKey = Read-WithDefault "  AWS Secret Access Key" $existingSK
                $sessionToken = Read-WithDefault "  AWS Session Token (optional, press Enter to skip)" $existingToken

                if (-not $accessKey -or -not $secretKey) {
                    Err "Access Key and Secret Key cannot be empty, skipping config"
                } else {
                    $envVars["AWS_ACCESS_KEY_ID"] = $accessKey
                    $envVars["AWS_SECRET_ACCESS_KEY"] = $secretKey
                    if ($sessionToken) {
                        $envVars["AWS_SESSION_TOKEN"] = $sessionToken
                    }
                    Write-ClaudeEnv $envVars
                    $maskedAK = "$($accessKey.Substring(0,4))...$($accessKey.Substring($accessKey.Length-4))"
                    Ok "Amazon Bedrock configured (AK: $maskedAK, Region: $awsRegion)"
                    Info "Written to user env vars + $CLAUDE_SETTINGS_PATH"
                }
            }
        }
        "3" {
            Info "Configuring Google Vertex AI..."
            $existingRegion = Get-ExistingValue "CLOUD_ML_REGION"
            $existingProject = Get-ExistingValue "ANTHROPIC_VERTEX_PROJECT_ID"

            $gcpProject = Read-WithDefault "  GCP Project ID" $existingProject
            $defaultRegion = if ($existingRegion) { $existingRegion } else { "us-east5" }
            $gcpRegion = Read-WithDefault "  GCP Region" $defaultRegion

            if (-not $gcpProject) {
                Err "GCP Project ID cannot be empty, skipping config"
            } else {
                Write-ClaudeEnv @{
                    "CLAUDE_CODE_USE_VERTEX" = "1"
                    "CLOUD_ML_REGION" = $gcpRegion
                    "ANTHROPIC_VERTEX_PROJECT_ID" = $gcpProject
                }
                Ok "Google Vertex AI configured (Project: $gcpProject, Region: $gcpRegion)"
                Info "Written to user env vars + $CLAUDE_SETTINGS_PATH"
                Write-Host ""
                Info "Note: Please ensure you have authenticated via gcloud auth application-default login"
            }
        }
        "4" {
            Info "Configuring Custom API Proxy..."
            $existingUrl = Get-ExistingValue "ANTHROPIC_BASE_URL"
            $existingKey = Get-ExistingValue "ANTHROPIC_API_KEY"

            $baseUrl = Read-WithDefault "  API Base URL (e.g.: https://openrouter.ai/api/v1)" $existingUrl
            $apiKey = Read-WithDefault "  API Key" $existingKey
            if (-not $baseUrl -or -not $apiKey) {
                Err "Base URL and API Key cannot be empty, skipping config"
            } else {
                $masked = "$($apiKey.Substring(0,8))...$($apiKey.Substring($apiKey.Length-4))"
                Write-ClaudeEnv @{
                    "ANTHROPIC_BASE_URL" = $baseUrl
                    "ANTHROPIC_API_KEY" = $apiKey
                }
                Ok "Custom API Proxy configured (URL: $baseUrl, Key: $masked)"
                Info "Written to user env vars + $CLAUDE_SETTINGS_PATH"
            }
        }
        "5" {
            if (Clear-ClaudeEnv) {
                Ok "Claude provider config cleared"
                Info "Cleared user env vars + $CLAUDE_SETTINGS_PATH"
            } else {
                Warn "No existing Claude provider config found"
            }
        }
        { $_ -in @("0", "") } {
            Ok "Keeping current config unchanged"
        }
        default {
            Warn "Invalid option, skipping Claude provider config"
        }
    }
}

# -- Claude Code -------------------------------------------------
function Install-Claude {
    Write-Host ""
    Info "========== [4/12] Claude Code =========="

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Ok "Claude Code already installed"
    } else {
        Info "Installing Claude Code..."
        $installed = $false

        # Try official install script (15s timeout)
        try {
            $script = Invoke-RestMethod -Uri "https://claude.ai/install.ps1" -TimeoutSec 15
            Invoke-Expression $script
            $installed = $true
            Ok "Claude Code installed successfully"
        } catch {
            Warn "Official script install failed, trying other methods..."
        }

        if (-not $installed -and (Get-Command npm -ErrorAction SilentlyContinue)) {
            npm install -g @anthropic-ai/claude-code 2>$null
            if ($LASTEXITCODE -eq 0) {
                Ok "Claude Code (npm) installed successfully"
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
            Err "Claude Code installation failed. Please install manually: https://docs.anthropic.com/en/docs/claude-code"
        }
    }

    Refresh-Path

    Write-Host ""
    Configure-ClaudeProvider

    Write-Host ""
    Info "Claude Code usage tips:"
    Write-Host "   claude              Start interactive session"
    Write-Host '   claude "question"   Ask directly'
    Write-Host '   claude -p "query"   Non-interactive mode (pipe-friendly)'
    Write-Host "   First-time login:   claude login"
}

# -- OpenClaw ----------------------------------------------------
function Install-OpenClaw {
    Write-Host ""
    Info "========== [5/12] OpenClaw =========="

    if (Get-Command openclaw -ErrorAction SilentlyContinue) {
        Ok "OpenClaw already installed"
    } else {
        Info "Installing OpenClaw..."
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            try { Winget-Install -Id "OpenClaw.OpenClaw" -Name "OpenClaw" } catch {}
        }
        if (-not (Get-Command openclaw -ErrorAction SilentlyContinue)) {
            Warn "Please download and install OpenClaw from https://openclaw.ai"
        }
    }

    Write-Host ""
    Info "OpenClaw usage tips:"
    Write-Host "   openclaw            Start OpenClaw"
    Write-Host "   openclaw onboard    First-time setup wizard"
}

# -- Hermes Agent ------------------------------------------------
function Install-Hermes {
    Write-Host ""
    Info "========== [6/12] Hermes Agent =========="

    if (Get-Command hermes -ErrorAction SilentlyContinue) {
        Ok "Hermes Agent already installed"
    } else {
        Info "Installing Hermes Agent..."
        try {
            $installUrl = GitHub-RawUrl "https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1"
            Invoke-RestMethod -Uri $installUrl -TimeoutSec 15 | Invoke-Expression
            Ok "Hermes Agent installed successfully"
        } catch {
            Warn "Auto-install failed. Please install manually from https://github.com/nousresearch/hermes-agent"
        }
    }

    # Check OpenClaw migration
    if ((Test-Path "$env:USERPROFILE\.openclaw") -and (Get-Command hermes -ErrorAction SilentlyContinue)) {
        Write-Host ""
        $migrateChoice = Read-Host "OpenClaw data detected. Migrate to Hermes? [y/N]"
        if ($migrateChoice -match '^[yY]$') {
            Info "Migrating OpenClaw data..."
            hermes claw migrate
        }
    }

    Write-Host ""
    Info "Hermes Agent usage tips:"
    Write-Host "   hermes              Start interactive session"
    Write-Host "   hermes setup        Run full setup wizard"
    Write-Host "   hermes model        Select LLM provider and model"
    Write-Host "   hermes tools        Configure available tools"
    Write-Host "   hermes update       Update to latest version"
}

# -- Antigravity -------------------------------------------------
function Install-Antigravity {
    Write-Host ""
    Info "========== [7/12] Antigravity =========="

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Winget-Install -Id "Google.Antigravity" -Name "Antigravity"
    } else {
        Warn "Please download Antigravity from the Google official website"
    }

    Write-Host ""
    Info "Antigravity usage tips:"
    Write-Host "   Launch Antigravity from the Start menu"
    Write-Host "   First launch requires Google account login"
}

# -- Docker Desktop (OrbStack alternative) -----------------------
function Install-OrbStack {
    Write-Host ""
    Info "========== [8/12] Docker Desktop =========="
    Info "OrbStack is macOS only. Installing Docker Desktop as alternative on Windows"

    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Ok "Docker already installed: $(docker --version)"
    } else {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Winget-Install -Id "Docker.DockerDesktop" -Name "Docker Desktop"
        } else {
            Warn "Please download Docker Desktop from https://www.docker.com/products/docker-desktop/"
        }
    }

    Write-Host ""
    Info "Docker Desktop usage tips:"
    Write-Host "   docker run hello-world     Verify installation"
    Write-Host "   docker compose up -d       Start container orchestration"
    Write-Host "   Note: Docker Desktop app must be running first"
}

# -- Obsidian ----------------------------------------------------
function Install-Obsidian {
    Write-Host ""
    Info "========== [9/12] Obsidian =========="

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Winget-Install -Id "Obsidian.Obsidian" -Name "Obsidian"
    } else {
        Scoop-Install -Package "obsidian" -Name "Obsidian" -Bucket "extras"
    }

    # Excalidraw plugin
    Write-Host ""
    Info "Configuring Excalidraw plugin..."
    Write-Host ""
    Write-Host "Select Obsidian Vault path:" -ForegroundColor White
    Write-Host "  1) Default path: ~/Obsidian" -ForegroundColor Cyan
    Write-Host "  2) Custom path" -ForegroundColor Cyan
    Write-Host "  3) Skip plugin installation" -ForegroundColor Cyan
    $vaultChoice = Read-Host "Select option [1/2/3] (default 1)"
    if (-not $vaultChoice) { $vaultChoice = "1" }

    $vaultPath = switch ($vaultChoice) {
        "1" { "$env:USERPROFILE\Obsidian" }
        "2" { Read-Host "Enter Vault path" }
        "3" { "" }
        default { "$env:USERPROFILE\Obsidian" }
    }

    if (-not $vaultPath) {
        Ok "Skipped Excalidraw plugin installation"
    } else {
        $pluginDir = "$vaultPath\.obsidian\plugins\obsidian-excalidraw-plugin"
        if (Test-Path $pluginDir) {
            Ok "Excalidraw plugin already installed"
        } else {
            New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
            Info "Downloading Excalidraw plugin..."

            try {
                $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/zsviczian/obsidian-excalidraw-plugin/releases/latest" -UseBasicParsing -TimeoutSec 15
                $tag = $releaseInfo.tag_name
                $baseUrl = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/$tag"

                foreach ($file in @("main.js", "manifest.json", "styles.css")) {
                    $dlUrl = GitHub-RawUrl "$baseUrl/$file"
                    Invoke-WebRequest -Uri $dlUrl -OutFile "$pluginDir\$file" -UseBasicParsing -TimeoutSec 30
                }
                Ok "Excalidraw plugin installed ($tag)"
            } catch {
                Err "Download failed. Please install Excalidraw plugin manually in Obsidian settings"
                Remove-Item -Path $pluginDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # Enable plugin
        $communityPlugins = "$vaultPath\.obsidian\community-plugins.json"
        if (Test-Path $pluginDir) {
            if (Test-Path $communityPlugins) {
                $plugins = Get-Content $communityPlugins -Raw -ErrorAction SilentlyContinue
                if ($plugins -notlike "*obsidian-excalidraw-plugin*") {
                    $plugins = $plugins -replace '\]$', ',"obsidian-excalidraw-plugin"]'
                    Set-Content -Path $communityPlugins -Value $plugins
                    Ok "Added Excalidraw to enabled plugins list"
                }
            } else {
                $obsidianDir = "$vaultPath\.obsidian"
                if (-not (Test-Path $obsidianDir)) { New-Item -ItemType Directory -Path $obsidianDir -Force | Out-Null }
                '["obsidian-excalidraw-plugin"]' | Set-Content -Path $communityPlugins
                Ok "Created community plugins config and enabled Excalidraw"
            }
        }

        Write-Host ""
        Info "Obsidian usage tips:"
        Write-Host "   Launch Obsidian from the Start menu"
        Write-Host "   Open Vault: $vaultPath"
        Write-Host "   Excalidraw: Ctrl+P and search for Excalidraw commands"
    }
}

# -- Ditto (Maccy alternative) -----------------------------------
function Install-Maccy {
    Write-Host ""
    Info "========== [10/12] Ditto (clipboard manager) =========="
    Info "Maccy is macOS only. Installing Ditto as alternative on Windows"

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Winget-Install -Id "Ditto.Ditto" -Name "Ditto"
    } else {
        Scoop-Install -Package "ditto" -Name "Ditto" -Bucket "extras"
    }

    Write-Host ""
    Info "Ditto usage tips:"
    Write-Host "   Default shortcut: Ctrl+`` to open clipboard history"
    Write-Host "   Supports text, images, files and more"
    Write-Host "   Also available: Windows built-in Win+V"
}

# -- JDK ---------------------------------------------------------
function Install-JDK {
    Write-Host ""
    Info "========== [11/12] JDK =========="

    Write-Host ""
    Write-Host "Select JDK version (Eclipse Temurin):" -ForegroundColor White
    Write-Host "  1) JDK 21 (LTS, recommended)" -ForegroundColor Cyan
    Write-Host "  2) JDK 17 (LTS)" -ForegroundColor Cyan
    Write-Host "  3) JDK 11 (LTS)" -ForegroundColor Cyan
    Write-Host "  4) JDK 8  (LTS)" -ForegroundColor Cyan
    Write-Host "  5) Skip" -ForegroundColor Cyan
    $jdkChoice = Read-Host "Select option [1-5] (default 1)"
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
        Ok "Skipped JDK installation"
    }

    Refresh-Path

    Write-Host ""
    Info "JDK usage tips:"
    Write-Host "   java -version               Check current JDK version"
    Write-Host "   Multi-version: scoop install temurin17-jdk"
    Write-Host "   Switch version: scoop reset temurin21-jdk"
}

# -- VS Code ----------------------------------------------------
function Install-VSCode {
    Write-Host ""
    Info "========== [12/12] VS Code =========="

    if (Get-Command code -ErrorAction SilentlyContinue) {
        Ok "VS Code already installed"
    } else {
        Info "Installing VS Code..."
        $installed = $false
        $installer = "$env:TEMP\vscode-installer.exe"

        # Detect architecture: ARM64 / x64 / ia32
        $cpuArch = $env:PROCESSOR_ARCHITECTURE
        $arch = switch ($cpuArch) {
            "ARM64" { "arm64" }
            "AMD64" { "x64" }
            default { if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "ia32" } }
        }
        Info "System architecture: $cpuArch -> VS Code $arch"

        # Detect Windows version
        $winVer = [Environment]::OSVersion.Version
        Info "Windows version: $($winVer.Major).$($winVer.Minor).$($winVer.Build)"

        # Method 1: Direct download from Microsoft CDN
        $cdnUrls = @(
            "https://update.code.visualstudio.com/latest/win32-$arch-user/stable"
            "https://vscode.cdn.azure.cn/stable/latest/VSCodeUserSetup-$arch.exe"
        )
        foreach ($url in $cdnUrls) {
            if ($installed) { break }
            try {
                Info "Downloading: $url"
                Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing -TimeoutSec 120
                if ((Test-Path $installer) -and (Get-Item $installer).Length -gt 1MB) {
                    Info "Running silent install..."
                    $proc = Start-Process -FilePath $installer -ArgumentList "/verysilent", "/mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" -Wait -NoNewWindow -PassThru
                    Remove-Item $installer -Force -ErrorAction SilentlyContinue
                    if ($proc.ExitCode -ne 0) {
                        Warn "Installer exit code: $($proc.ExitCode), possible version incompatibility"
                        continue
                    }
                    Refresh-Path
                    $vscodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
                    if (Test-Path $vscodePath) { $env:Path = "$vscodePath;$env:Path" }
                    if (Get-Command code -ErrorAction SilentlyContinue) {
                        $installed = $true
                        Ok "VS Code installed successfully (direct download)"
                    }
                }
            } catch {
                Warn "Download failed: $($_.Exception.Message)"
                Remove-Item $installer -Force -ErrorAction SilentlyContinue
            }
        }

        # Method 2: winget (Microsoft Store CDN, 60s timeout)
        if (-not $installed -and (Get-Command winget -ErrorAction SilentlyContinue)) {
            Info "Trying winget install (60s timeout)..."
            $job = Start-Job -ScriptBlock { winget install --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements --silent 2>&1 }
            $finished = $job | Wait-Job -Timeout 60
            if ($finished) {
                Receive-Job $job | Out-Null
                Remove-Job $job -Force
            } else {
                Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -Force
                Warn "winget install timed out"
            }
            Refresh-Path
            $vscodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
            if (Test-Path $vscodePath) { $env:Path = "$vscodePath;$env:Path" }
            if (Get-Command code -ErrorAction SilentlyContinue) {
                $installed = $true
                Ok "VS Code installed successfully (winget)"
            }
        }

        # Method 3: scoop (GitHub Releases, 60s timeout)
        if (-not $installed) {
            Info "Trying scoop install (60s timeout)..."
            $result = Scoop-Install -Package "vscode" -Name "VS Code" -Bucket "extras" -TimeoutSec 60
        }

        if (-not $installed -and -not (Get-Command code -ErrorAction SilentlyContinue)) {
            Err "VS Code auto-install failed"
            Warn "Possible cause: Windows version incompatible (requires Win10 1709+ or Win11)"
            Warn "ARM Mac VM: download ARM64 version at https://code.visualstudio.com/Download"
            Warn "Older Windows: download VS Code 1.83 at https://update.code.visualstudio.com/1.83.1/win32-$arch-user/stable"
        }
    }

    Refresh-Path

    # Ensure code command is available
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Err "VS Code CLI (code) not available, skipping extension install"
        Warn "Please reopen terminal and run: code --install-extension Catppuccin.catppuccin-vsc"
        return
    }

    # Install Catppuccin theme
    Info "Installing Catppuccin theme extension..."

    $extensions = code --list-extensions 2>$null
    if ($extensions -match "Catppuccin.catppuccin-vsc$") {
        Ok "Catppuccin theme already installed"
    } else {
        code --install-extension Catppuccin.catppuccin-vsc --force 2>$null
        Ok "Catppuccin theme installed"
    }

    if ($extensions -match "Catppuccin.catppuccin-vsc-icons") {
        Ok "Catppuccin Icons already installed"
    } else {
        code --install-extension Catppuccin.catppuccin-vsc-icons --force 2>$null
        Ok "Catppuccin Icons installed"
    }

    # Set Catppuccin as default theme
    $vscodSettingsDir = "$env:APPDATA\Code\User"
    $vscodeSettings = "$vscodSettingsDir\settings.json"
    if (-not (Test-Path $vscodSettingsDir)) { New-Item -ItemType Directory -Path $vscodSettingsDir -Force | Out-Null }

    if (Test-Path $vscodeSettings) {
        $content = Get-Content $vscodeSettings -Raw -ErrorAction SilentlyContinue
        if ($content -match '"workbench.colorTheme"') {
            $content = $content -replace '"workbench.colorTheme"\s*:\s*"[^"]*"', '"workbench.colorTheme": "Catppuccin Latte"'
            Ok "Switched VS Code theme to Catppuccin Latte"
        } else {
            $content = $content -replace '^\{', "{`n    `"workbench.colorTheme`": `"Catppuccin Latte`","
            Ok "Added Catppuccin Latte theme to settings.json"
        }
        if ($content -match '"workbench.iconTheme"') {
            $content = $content -replace '"workbench.iconTheme"\s*:\s*"[^"]*"', '"workbench.iconTheme": "catppuccin-latte"'
        } else {
            $content = $content -replace '^\{', "{`n    `"workbench.iconTheme`": `"catppuccin-latte`","
        }
        Set-Content -Path $vscodeSettings -Value $content -Encoding UTF8
        Ok "Catppuccin Icons theme set"
    } else {
        @"
{
    "workbench.colorTheme": "Catppuccin Latte",
    "workbench.iconTheme": "catppuccin-latte"
}
"@ | Set-Content -Path $vscodeSettings -Encoding UTF8
        Ok "Created VS Code settings.json (Catppuccin Latte theme)"
    }

    Write-Host ""
    Info "VS Code usage tips:"
    Write-Host "   code .                Open current directory"
    Write-Host "   code <file>           Open file"
    Write-Host "   Theme: Catppuccin Latte (auto-applied)"
    Write-Host "   Switch theme: Ctrl+K Ctrl+T"
}

# ================================================================
# Main Flow
# ================================================================
function Main {
    # Check admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Warn "Some installations may require admin privileges. Consider running PowerShell as Administrator"
    }

    # Parse arguments
    Parse-Args $args

    # Claude-provider only mode
    if ($script:SKIP_PREREQUISITES -and ($script:SELECTED_TOOLS -contains "claude-provider")) {
        Write-Host ""
        Configure-ClaudeProvider
        return
    }

    # Prerequisites check
    if (-not $script:SKIP_PREREQUISITES) {
        Check-Prerequisites
    }

    # Install selected tools
    if ($script:SELECTED_TOOLS.Count -gt 0) {
        Write-Host ""
        Info "About to install: $($script:SELECTED_TOOLS -join ', ')"
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

    # Skip mode: config menu
    if ($script:SKIP_PREREQUISITES -and $script:SELECTED_TOOLS.Count -eq 0) {
        Write-Host ""
        Info "========== Configuration =========="
        Write-Host ""
        Write-Host "  1) Modify Claude provider config" -ForegroundColor Green
        Write-Host "  0) Exit" -ForegroundColor Green
        Write-Host ""
        $configChoice = Read-Host "  Select [0-1]"
        switch ($configChoice) {
            "1" { Configure-ClaudeProvider }
            default { Ok "Exited" }
        }
    }

    # -- Done ---------------------------------------------------
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  All done!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""

    if ($script:SELECTED_TOOLS.Count -gt 0) {
        Write-Host "Installed: $($script:SELECTED_TOOLS -join ', ')"
        Write-Host ""
    }

    if (Is-Selected "ghostty")  { Write-Host "  Ghostty   $env:APPDATA\ghostty\config" }
    if (Is-Selected "yazi")     { Write-Host "  Yazi      $env:APPDATA\yazi\config\" }
    if (Is-Selected "lazygit")  { Write-Host "  Lazygit   $env:APPDATA\lazygit\config.yml" }
    if (Is-Selected "claude")   { Write-Host "  Claude    User env vars + $CLAUDE_SETTINGS_PATH" }
    if (Is-Selected "hermes")   { Write-Host "  Hermes    $env:USERPROFILE\.hermes\ (config/skills/memory)" }
    if (Is-Selected "obsidian") { Write-Host "  Obsidian  $env:USERPROFILE\Obsidian (with Excalidraw plugin)" }
    if (Is-Selected "maccy")    { Write-Host "  Ditto     Clipboard manager (Ctrl+``)" }
    if (Is-Selected "jdk")      { Write-Host "  JDK       Managed via winget/scoop" }
    if (Is-Selected "vscode")   { Write-Host "  VS Code   Catppuccin Latte theme applied" }
    Write-Host ""

    Refresh-Path
}

# Run main flow
Main
