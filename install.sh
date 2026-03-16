#!/usr/bin/env bash
# ============================================================
# macOS 开发工具一键安装与配置
# 支持: Ghostty / Yazi / Lazygit / Claude Code / OpenClaw
# 用法:
#   全部安装:  ./install.sh
#   选择安装:  ./install.sh ghostty yazi lazygit claude openclaw
#   查看帮助:  ./install.sh --help
# ============================================================
set -euo pipefail

# ── 颜色输出 ──────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR ]${NC} $*"; }

# ── 帮助信息 ──────────────────────────────────────────
show_help() {
    cat << 'EOF'
macOS 开发工具一键安装脚本

用法:
  ./install.sh                 交互式选择要安装的工具
  ./install.sh --all           安装全部工具
  ./install.sh <tool> ...      只安装指定工具

可选工具:
  ghostty     GPU 加速终端模拟器
  yazi        终端文件管理器
  lazygit     终端 Git UI
  claude      Claude Code (AI 编程助手)
  openclaw    OpenClaw (本地 AI 助手)

示例:
  ./install.sh ghostty yazi          只安装 Ghostty 和 Yazi
  ./install.sh claude openclaw       只安装 AI 工具
  ./install.sh --all                 全部安装
EOF
    exit 0
}

# ── 工具定义 ──────────────────────────────────────────
ALL_TOOLS=("ghostty" "yazi" "lazygit" "claude" "openclaw")
SELECTED_TOOLS=()

# ── 解析参数 ──────────────────────────────────────────
parse_args() {
    if [[ $# -eq 0 ]]; then
        interactive_select
        return
    fi

    for arg in "$@"; do
        case "$arg" in
            --help|-h) show_help ;;
            --all|-a)  SELECTED_TOOLS=("${ALL_TOOLS[@]}"); return ;;
            ghostty|yazi|lazygit|claude|openclaw)
                SELECTED_TOOLS+=("$arg") ;;
            *)
                err "未知选项: $arg"
                echo "运行 ./install.sh --help 查看帮助"
                exit 1 ;;
        esac
    done
}

# ── 交互式多选菜单 (方向键导航 + 空格选择) ───────────
interactive_select() {
    local labels=(
        "Ghostty      GPU 加速终端模拟器 (毛玻璃/分屏/Quake 下拉)"
        "Yazi         终端文件管理器 (快速预览/Vim 风格导航)"
        "Lazygit      终端 Git UI (可视化提交/分支/合并)"
        "Claude Code  Anthropic AI 编程助手 (终端内 AI 编程)"
        "OpenClaw     本地 AI 助手 (自托管/任务自动化)"
    )
    local count=${#labels[@]}
    local selected=()
    local cursor=0

    for ((i=0; i<count; i++)); do
        selected+=("off")
    done

    # 绘制整个菜单 (光标当前在菜单底部下方一行)
    draw_menu() {
        # 光标上移 count 行回到菜单顶部
        printf '\033[%dA' "$count" > /dev/tty
        for ((i=0; i<count; i++)); do
            # 清除当前行
            printf '\033[2K' > /dev/tty
            local check=" "
            [[ "${selected[$i]}" == "on" ]] && check="*"
            if [[ $i -eq $cursor ]]; then
                printf '  \033[0;36m>\033[0m [\033[0;32m%s\033[0m] %s\n' "$check" "${labels[$i]}" > /dev/tty
            else
                printf '    [%s] %s\n' "$check" "${labels[$i]}" > /dev/tty
            fi
        done
    }

    # 打印标题
    printf '\n' > /dev/tty
    printf '\033[1;36m╔══════════════════════════════════════════════╗\033[0m\n' > /dev/tty
    printf '\033[1;36m║     macOS 开发工具一键安装与配置             ║\033[0m\n' > /dev/tty
    printf '\033[1;36m╚══════════════════════════════════════════════╝\033[0m\n' > /dev/tty
    printf '\n' > /dev/tty
    printf '\033[1m操作: ↑↓ 移动  空格 选择/取消  a 全选  回车 确认  q 退出\033[0m\n' > /dev/tty
    printf '\n' > /dev/tty

    # 首次绘制 (打印 count 行，光标停在最后一行之后)
    for ((i=0; i<count; i++)); do
        local check=" "
        if [[ $i -eq $cursor ]]; then
            printf '  \033[0;36m>\033[0m [%s] %s\n' "$check" "${labels[$i]}" > /dev/tty
        else
            printf '    [%s] %s\n' "$check" "${labels[$i]}" > /dev/tty
        fi
    done

    # 隐藏光标
    printf '\033[?25l' > /dev/tty

    # 读取按键循环
    while true; do
        IFS= read -rsn1 key < /dev/tty

        case "$key" in
            $'\x1b')
                # 读取方向键剩余字节
                IFS= read -rsn1 bracket < /dev/tty
                IFS= read -rsn1 code < /dev/tty
                if [[ "$bracket" == "[" ]]; then
                    case "$code" in
                        A) ((cursor > 0)) && ((cursor--)) ;;          # 上
                        B) ((cursor < count-1)) && ((cursor++)) ;;    # 下
                    esac
                fi
                ;;
            ' ')
                if [[ "${selected[$cursor]}" == "off" ]]; then
                    selected[$cursor]="on"
                else
                    selected[$cursor]="off"
                fi
                ;;
            a|A)
                local all_on=true
                for ((i=0; i<count; i++)); do
                    [[ "${selected[$i]}" == "off" ]] && all_on=false && break
                done
                if $all_on; then
                    for ((i=0; i<count; i++)); do selected[$i]="off"; done
                else
                    for ((i=0; i<count; i++)); do selected[$i]="on"; done
                fi
                ;;
            '')
                # 显示光标并换行
                printf '\033[?25h' > /dev/tty
                printf '\n' > /dev/tty
                break
                ;;
            q|Q)
                printf '\033[?25h\n' > /dev/tty
                echo "已取消。" > /dev/tty
                exit 0
                ;;
        esac

        draw_menu
    done

    # 收集选中的工具
    for ((i=0; i<count; i++)); do
        if [[ "${selected[$i]}" == "on" ]]; then
            SELECTED_TOOLS+=("${ALL_TOOLS[$i]}")
        fi
    done

    if [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
        err "未选择任何工具，退出。"
        exit 1
    fi
}

# ── 工具函数 ──────────────────────────────────────────
is_selected() {
    local tool="$1"
    for t in "${SELECTED_TOOLS[@]}"; do
        [[ "$t" == "$tool" ]] && return 0
    done
    return 1
}

backup_if_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        local backup="${path}.bak.$(date +%Y%m%d%H%M%S)"
        warn "备份已有配置: $path -> $backup"
        cp -r "$path" "$backup"
    fi
}

# ══════════════════════════════════════════════════════
# 环境基础检查 (默认安装，无需选择)
# ══════════════════════════════════════════════════════
check_prerequisites() {
    echo ""
    echo -e "${BOLD}${CYAN}========== 环境基础检查 ==========${NC}"
    echo ""

    local need_source_zshrc=false

    # ── 1. Zsh ────────────────────────────────────────
    if command -v zsh &>/dev/null; then
        ok "Zsh 已安装: $(zsh --version)"
        # 检查是否为默认 Shell
        if [[ "$SHELL" == *zsh ]]; then
            ok "Zsh 已是默认 Shell"
        else
            warn "当前默认 Shell 为 $SHELL，正在切换到 Zsh..."
            chsh -s "$(which zsh)"
            ok "已将默认 Shell 切换为 Zsh (重新登录后生效)"
        fi
    else
        info "正在安装 Zsh..."
        brew install zsh
        chsh -s "$(which zsh)"
        ok "Zsh 安装完成，已设为默认 Shell"
    fi

    # ── 2. Homebrew ───────────────────────────────────
    if command -v brew &>/dev/null; then
        ok "Homebrew 已安装: $(brew --version | head -1)"
    else
        info "未检测到 Homebrew，正在安装..."
        # 必须用 /dev/tty 作为 stdin，否则 curl|bash 模式下 brew 安装脚本检测不到 TTY
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        ok "Homebrew 安装完成: $(brew --version | head -1)"
    fi

    # ── 3. Git ────────────────────────────────────────
    if command -v git &>/dev/null; then
        ok "Git 已安装: $(git --version)"
    else
        info "正在安装 Git..."
        brew install git
        ok "Git 安装完成: $(git --version)"
    fi

    # ── 4. Oh My Zsh ─────────────────────────────────
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        ok "Oh My Zsh 已安装"
    else
        info "正在安装 Oh My Zsh..."
        # RUNZSH=no 防止安装后自动切换到 zsh 导致脚本中断
        # KEEP_ZSHRC=yes 保留已有 .zshrc 配置
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" < /dev/tty
        ok "Oh My Zsh 安装完成"
    fi

    # 安装常用 Oh My Zsh 插件
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions (输入时显示历史建议)
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        ok "zsh-autosuggestions 插件已安装"
    else
        info "安装 zsh-autosuggestions 插件..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null
        ok "zsh-autosuggestions 已安装"
        need_source_zshrc=true
    fi

    # zsh-syntax-highlighting (命令语法高亮)
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        ok "zsh-syntax-highlighting 插件已安装"
    else
        info "安装 zsh-syntax-highlighting 插件..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null
        ok "zsh-syntax-highlighting 已安装"
        need_source_zshrc=true
    fi

    # 确保 .zshrc 中启用了插件
    local ZSHRC="$HOME/.zshrc"
    if [[ -f "$ZSHRC" ]]; then
        if grep -q "zsh-autosuggestions" "$ZSHRC" 2>/dev/null; then
            ok ".zshrc 中已配置 Oh My Zsh 插件"
        else
            # 尝试将插件加入 plugins=(...) 行
            if grep -q "^plugins=" "$ZSHRC" 2>/dev/null; then
                sed -i '' 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
                ok "已将插件添加到 .zshrc 的 plugins 列表"
                need_source_zshrc=true
            fi
        fi
    fi

    # ── 5. NVM (Node Version Manager) ────────────────
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # 尝试加载已有的 nvm
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" 2>/dev/null

    if command -v nvm &>/dev/null; then
        ok "NVM 已安装: $(nvm --version)"
    else
        info "正在安装 NVM..."
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash < /dev/tty
        # 立即加载 nvm
        export NVM_DIR="$HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        ok "NVM 安装完成: $(nvm --version 2>/dev/null || echo '已安装')"
        need_source_zshrc=true
    fi

    # ── 6. Node.js (通过 NVM 安装 LTS 版本) ─────────
    if command -v node &>/dev/null; then
        ok "Node.js 已安装: $(node --version)"
    else
        if command -v nvm &>/dev/null; then
            info "正在通过 NVM 安装 Node.js LTS..."
            nvm install --lts
            nvm use --lts
            nvm alias default lts/*
            ok "Node.js 安装完成: $(node --version)"
        else
            info "NVM 不可用，通过 Homebrew 安装 Node.js..."
            brew install node
            ok "Node.js 安装完成: $(node --version)"
        fi
    fi

    echo ""
    echo -e "${GREEN}${BOLD}环境基础检查完成${NC}"

    if $need_source_zshrc; then
        echo -e "${YELLOW}提示: 部分配置需要 source ~/.zshrc 或重新打开终端后生效${NC}"
    fi

    echo ""
}

brew_install() {
    local formula="$1"
    local name="${2:-$formula}"
    if brew list "$formula" &>/dev/null; then
        ok "$name 已安装"
    else
        info "正在安装 $name ..."
        brew install "$formula"
        ok "$name 安装完成"
    fi
}

brew_install_cask() {
    local cask="$1"
    local name="${2:-$cask}"
    if brew list --cask "$cask" &>/dev/null; then
        ok "$name (cask) 已安装"
    else
        info "正在安装 $name ..."
        brew install --cask "$cask"
        ok "$name 安装完成"
    fi
}

# ══════════════════════════════════════════════════════
# 安装模块
# ══════════════════════════════════════════════════════

# ── Ghostty ───────────────────────────────────────────
install_ghostty() {
    echo ""
    info "========== [1/5] Ghostty =========="
    brew_install_cask ghostty "Ghostty"

    GHOSTTY_DIR="$HOME/.config/ghostty"
    GHOSTTY_CONF="$GHOSTTY_DIR/config"
    mkdir -p "$GHOSTTY_DIR"

    if [[ -f "$GHOSTTY_CONF" ]]; then
        ok "Ghostty 已有配置，保留不覆盖"
    else
        cat > "$GHOSTTY_CONF" << 'GHOSTTY_EOF'
# ============================================
# Ghostty Terminal - 推荐配置
# ============================================
# 重新加载: Cmd+Shift+, | 浏览主题: ghostty +list-themes

# --- 字体 ---
font-family = JetBrains Mono
font-size = 14
font-thicken = true
adjust-cell-height = 2

# --- 主题 (跟随系统明暗) ---
theme = light:rose-pine-dawn,dark:rose-pine

# --- 窗口 ---
background-opacity = 0.92
background-blur-radius = 20
macos-titlebar-style = tabs
window-padding-x = 10
window-padding-y = 8
window-padding-balance = true
window-save-state = always
window-theme = auto

# --- 光标 ---
cursor-style = bar
cursor-style-blink = true
cursor-opacity = 0.8

# --- 鼠标 ---
mouse-hide-while-typing = true
copy-on-select = clipboard

# --- 快捷终端 (Quake 风格) ---
quick-terminal-position = top
quick-terminal-screen = mouse
quick-terminal-autohide = true
quick-terminal-animation-duration = 0.15

# --- 安全 ---
clipboard-paste-protection = true
clipboard-paste-bracketed-safe = true

# --- Shell 集成 ---
shell-integration = detect

# --- 快捷键 ---
keybind = cmd+t=new_tab
keybind = cmd+shift+left=previous_tab
keybind = cmd+shift+right=next_tab
keybind = cmd+w=close_surface

keybind = cmd+d=new_split:right
keybind = cmd+shift+d=new_split:down
keybind = cmd+alt+left=goto_split:left
keybind = cmd+alt+right=goto_split:right
keybind = cmd+alt+up=goto_split:top
keybind = cmd+alt+down=goto_split:bottom

keybind = cmd+plus=increase_font_size:1
keybind = cmd+minus=decrease_font_size:1
keybind = cmd+zero=reset_font_size

keybind = global:ctrl+grave_accent=toggle_quick_terminal
keybind = cmd+shift+e=equalize_splits
keybind = cmd+shift+f=toggle_split_zoom
keybind = cmd+shift+comma=reload_config

# --- 性能 ---
scrollback-limit = 50000
GHOSTTY_EOF
        ok "Ghostty 配置已写入"
    fi
}

# ── Yazi ──────────────────────────────────────────────
install_yazi() {
    echo ""
    info "========== [2/5] Yazi =========="
    brew_install yazi "Yazi"

    # 辅助依赖
    info "安装 Yazi 辅助依赖..."
    brew_install fd "fd (快速文件查找)"
    brew_install ripgrep "ripgrep (内容搜索)"
    brew_install fzf "fzf (模糊搜索)"
    brew_install zoxide "zoxide (智能目录跳转)"
    brew_install poppler "poppler (PDF 预览)"
    brew_install ffmpegthumbnailer "ffmpegthumbnailer (视频缩略图)"
    brew_install sevenzip "7zip (压缩包预览)"
    brew_install jq "jq (JSON 预览)"
    brew_install imagemagick "ImageMagick (图片处理)"
    brew_install font-symbols-only-nerd-font "Nerd Font Symbols"

    YAZI_DIR="$HOME/.config/yazi"
    mkdir -p "$YAZI_DIR"

    # yazi.toml
    backup_if_exists "$YAZI_DIR/yazi.toml"
    cat > "$YAZI_DIR/yazi.toml" << 'YAZI_EOF'
# ============================================
# Yazi 文件管理器 - 主配置
# ============================================

[mgr]
ratio         = [1, 4, 3]
sort_by       = "natural"
sort_sensitive = false
sort_reverse  = false
sort_dir_first = true
show_hidden   = false
show_symlink  = true
linemode      = "size"

[preview]
wrap       = "no"
tab_size   = 2
max_width  = 1000
max_height = 1000

[opener]
edit = [
    { run = '${EDITOR:-vim} "$@"', block = true, for = "unix" },
]
open = [
    { run = 'open "$@"', for = "macos" },
]
reveal = [
    { run = 'open -R "$1"', for = "macos" },
]

[[open.rules]]
name = "*.{md,txt,json,yaml,yml,toml,lua,py,go,rs,js,ts,tsx,jsx,sh,zsh,css,html,sql,env,conf,cfg}"
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
YAZI_EOF
    ok "yazi.toml 已写入"

    # keymap.toml
    backup_if_exists "$YAZI_DIR/keymap.toml"
    cat > "$YAZI_DIR/keymap.toml" << 'YAZI_EOF'
# ============================================
# Yazi - 快捷键配置
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
run  = "shell 'open -a Ghostty \"$PWD\"' --confirm"
desc = "Open in Ghostty"

[[mgr.prepend_keymap]]
on   = ["C"]
run  = "shell 'code \"$PWD\"' --confirm"
desc = "Open in VS Code"

[[mgr.prepend_keymap]]
on   = ["S"]
run  = "shell '$SHELL' --block --confirm"
desc = "Open shell here"
YAZI_EOF
    ok "keymap.toml 已写入"

    # theme.toml
    backup_if_exists "$YAZI_DIR/theme.toml"
    cat > "$YAZI_DIR/theme.toml" << 'YAZI_EOF'
# Yazi 主题配置 (使用默认主题)
# Catppuccin 主题: ya pack -a yazi-rs/flavors:catppuccin-mocha
# 然后取消注释:
# [flavor]
# use = "catppuccin-mocha"
YAZI_EOF
    ok "theme.toml 已写入"

    # init.lua
    backup_if_exists "$YAZI_DIR/init.lua"
    cat > "$YAZI_DIR/init.lua" << 'YAZI_EOF'
-- Yazi 插件初始化
local ok_border, full_border = pcall(require, "full-border")
if ok_border then full_border:setup() end

local ok_git, git = pcall(require, "git")
if ok_git then git:setup() end
YAZI_EOF
    ok "init.lua 已写入"

    # 安装插件
    if command -v ya &>/dev/null; then
        info "安装 Yazi 插件..."
        ya pack -a yazi-rs/plugins:full-border 2>/dev/null && ok "full-border 插件已安装" || warn "full-border 可能已安装"
        ya pack -a yazi-rs/plugins:git 2>/dev/null && ok "git 插件已安装" || warn "git 可能已安装"
        ya pack -a yazi-rs/plugins:chmod 2>/dev/null && ok "chmod 插件已安装" || warn "chmod 可能已安装"
    fi

    # Shell 集成 (y 命令)
    setup_yazi_shell_wrapper
}

setup_yazi_shell_wrapper() {
    local ZSHRC="$HOME/.zshrc"
    local YAZI_WRAPPER='# Yazi: 退出后自动 cd 到最后浏览的目录
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}'

    if [[ -f "$ZSHRC" ]] && grep -q "function y()" "$ZSHRC" 2>/dev/null; then
        ok "Yazi shell wrapper (y 命令) 已存在"
    else
        echo "" >> "$ZSHRC"
        echo "$YAZI_WRAPPER" >> "$ZSHRC"
        ok "已添加 y 命令到 .zshrc"
    fi
}

# ── Lazygit ───────────────────────────────────────────
install_lazygit() {
    echo ""
    info "========== [3/5] Lazygit =========="
    brew_install lazygit "Lazygit"
    brew_install git-delta "delta (语法高亮 diff)"

    LAZYGIT_DIR="$HOME/.config/lazygit"
    LAZYGIT_CONF="$LAZYGIT_DIR/config.yml"
    mkdir -p "$LAZYGIT_DIR"

    backup_if_exists "$LAZYGIT_CONF"
    cat > "$LAZYGIT_CONF" << 'LAZYGIT_EOF'
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
    command: "echo -n {{.SelectedLocalBranch.Name}} | pbcopy"
    description: "Copy branch name"
LAZYGIT_EOF
    ok "Lazygit 配置已写入"

    # 配置 Git Delta
    if ! git config --global core.pager 2>/dev/null | grep -q delta; then
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.dark true
        git config --global delta.line-numbers true
        git config --global delta.side-by-side false
        git config --global delta.hyperlinks true
        git config --global merge.conflictstyle "zdiff3"
        ok "Git Delta 全局配置已写入"
    else
        ok "Git Delta 已配置"
    fi
}

# ── Claude Code ───────────────────────────────────────
install_claude() {
    echo ""
    info "========== [4/5] Claude Code =========="

    if command -v claude &>/dev/null; then
        ok "Claude Code 已安装: $(claude --version 2>/dev/null || echo '已安装')"
    else
        info "正在安装 Claude Code..."
        # 优先使用官方安装脚本 (自包含二进制，无需 Node.js)
        if curl -fsSL https://claude.ai/install.sh | bash < /dev/tty; then
            ok "Claude Code 安装完成"
        else
            warn "官方脚本安装失败，尝试 Homebrew..."
            brew install --cask claude-code 2>/dev/null && ok "Claude Code (Homebrew) 安装完成" || err "Claude Code 安装失败，请手动安装"
        fi
    fi

    echo ""
    info "Claude Code 使用提示:"
    echo "   claude              启动交互式会话"
    echo "   claude \"问题\"       直接提问"
    echo "   claude -p \"问题\"    非交互模式 (管道友好)"
    echo "   首次使用需要登录:    claude login"
}

# ── OpenClaw ──────────────────────────────────────────
install_openclaw() {
    echo ""
    info "========== [5/5] OpenClaw =========="

    if command -v openclaw &>/dev/null; then
        ok "OpenClaw 已安装"
    else
        info "正在安装 OpenClaw..."
        brew_install openclaw-cli "OpenClaw CLI"
    fi

    # 可选安装 GUI 版本
    if ! brew list --cask openclaw &>/dev/null; then
        echo ""
        read -rp "$(echo -e "${BOLD}是否安装 OpenClaw 桌面应用? [y/N]: ${NC}")" install_gui < /dev/tty
        if [[ "$install_gui" =~ ^[yY]$ ]]; then
            brew_install_cask openclaw "OpenClaw Desktop"
        fi
    else
        ok "OpenClaw Desktop 已安装"
    fi

    echo ""
    info "OpenClaw 使用提示:"
    echo "   openclaw            启动 OpenClaw"
    echo "   openclaw onboard    首次设置向导"
}

# ══════════════════════════════════════════════════════
# 主流程
# ══════════════════════════════════════════════════════
main() {
    # 先检查基础环境 (zsh, brew, git, oh-my-zsh, nvm, node)
    check_prerequisites

    # 再让用户选择可选工具
    parse_args "$@"

    echo ""
    info "即将安装: ${SELECTED_TOOLS[*]}"
    echo ""

    is_selected "ghostty" && install_ghostty
    is_selected "yazi"    && install_yazi
    is_selected "lazygit" && install_lazygit
    is_selected "claude"  && install_claude
    is_selected "openclaw" && install_openclaw

    # ── 完成 ──────────────────────────────────────────
    echo ""
    echo -e "${GREEN}${BOLD}============================================${NC}"
    echo -e "${GREEN}${BOLD}  All done! 安装和配置全部完成${NC}"
    echo -e "${GREEN}${BOLD}============================================${NC}"
    echo ""

    echo "已安装: ${SELECTED_TOOLS[*]}"
    echo ""

    if is_selected "ghostty"; then
        echo "  Ghostty   ~/.config/ghostty/config"
    fi
    if is_selected "yazi"; then
        echo "  Yazi      ~/.config/yazi/"
    fi
    if is_selected "lazygit"; then
        echo "  Lazygit   ~/.config/lazygit/config.yml"
    fi
    echo ""

    if is_selected "yazi"; then
        echo -e "${YELLOW}source ~/.zshrc${NC} to activate the 'y' command for Yazi"
        echo ""
    fi
}

main "$@"
