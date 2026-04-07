#!/usr/bin/env bash
# ============================================================
# macOS 开发工具一键安装与配置
# 支持: Ghostty / Yazi / Lazygit / Claude Code / OpenClaw / OrbStack / Obsidian / Maccy / JDK
# 用法:
#   全部安装:  ./install.sh
#   选择安装:  ./install.sh ghostty yazi lazygit claude openclaw orbstack obsidian maccy jdk
#   查看帮助:  ./install.sh --help
# ============================================================
set -uo pipefail

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

# ── 国内加速配置 ──────────────────────────────────────
USE_MIRROR=false
GITHUB_PROXY=""

setup_mirror() {
    # 如果已通过 --mirror 标志启用，跳过检测
    if ! $USE_MIRROR; then
        echo ""
        echo -e "${BOLD}检测网络环境...${NC}"
        # 尝试访问 GitHub，超时 3 秒判断是否需要加速
        if curl -fsSL --connect-timeout 3 https://raw.githubusercontent.com/github/gitignore/main/README.md &>/dev/null; then
            ok "GitHub 连接正常"
            echo -en "${CYAN}是否仍要使用国内镜像加速? [y/N]: ${NC}" > /dev/tty
            local use_mirror_choice
            read -r use_mirror_choice < /dev/tty
            [[ "$use_mirror_choice" =~ ^[yY]$ ]] && USE_MIRROR=true
        else
            warn "GitHub 连接缓慢或不可用"
            echo -en "${CYAN}是否使用国内镜像加速? [Y/n]: ${NC}" > /dev/tty
            local use_mirror_choice
            read -r use_mirror_choice < /dev/tty
            [[ ! "$use_mirror_choice" =~ ^[nN]$ ]] && USE_MIRROR=true
        fi
    fi

    if $USE_MIRROR; then
        GITHUB_PROXY="https://ghfast.top/"

        # Homebrew 镜像 (USTC)
        export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
        export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
        export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
        export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

        # Node.js 镜像 (npmmirror)
        export NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"
        export npm_config_registry="https://registry.npmmirror.com"

        ok "已启用国内镜像加速"
        info "  GitHub 代理:   ${GITHUB_PROXY}"
        info "  Homebrew 镜像: USTC"
        info "  Node.js 镜像:  npmmirror"
    fi
}

# GitHub 原始文件 URL 加速
github_raw_url() {
    local url="$1"
    if $USE_MIRROR; then
        echo "${GITHUB_PROXY}${url}"
    else
        echo "$url"
    fi
}

# GitHub 仓库 clone URL 加速
github_clone_url() {
    local url="$1"
    if $USE_MIRROR; then
        echo "${GITHUB_PROXY}${url}"
    else
        echo "$url"
    fi
}

# ── 启动时清理残留 brew 进程和锁文件 ─────────────────
pkill -9 -f 'brew install\|brew fetch' 2>/dev/null
find "$HOME/Library/Caches/Homebrew/downloads" -name '*incomplete*' -delete 2>/dev/null

# ── 帮助信息 ──────────────────────────────────────────
show_help() {
    cat << 'EOF'
macOS 开发工具一键安装脚本

用法:
  ./install.sh                 交互式选择要安装的工具
  ./install.sh --all           安装全部工具
  ./install.sh --skip          跳过工具安装，仅修改配置
  ./install.sh --mirror        强制使用国内镜像加速
  ./install.sh <tool> ...      只安装指定工具

可选工具:
  ghostty          GPU 加速终端模拟器
  yazi             终端文件管理器
  lazygit          终端 Git UI
  claude           Claude Code (AI 编程助手)
  openclaw         OpenClaw (本地 AI 助手)
  antigravity      Google Antigravity (AI 开发平台)
  orbstack         OrbStack (Docker 容器 & Linux 虚拟机)
  obsidian         Obsidian (知识管理 & 笔记工具)
  maccy            Maccy (剪贴板管理工具)
  jdk              JDK (通过 SDKMAN 安装，支持版本选择)
  claude-provider  仅修改 Claude API 提供商配置

示例:
  ./install.sh ghostty yazi          只安装 Ghostty 和 Yazi
  ./install.sh claude openclaw       只安装 AI 工具
  ./install.sh claude-provider       仅切换 Claude 提供商
  ./install.sh --skip                跳过安装，进入配置菜单
  ./install.sh --all                 全部安装
EOF
    exit 0
}

# ── 工具定义 ──────────────────────────────────────────
ALL_TOOLS=("ghostty" "yazi" "lazygit" "claude" "openclaw" "antigravity" "orbstack" "obsidian" "maccy" "jdk")
SELECTED_TOOLS=()
SKIP_PREREQUISITES=false

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
            --skip|-s) SKIP_PREREQUISITES=true; return ;;
            --mirror|-m) USE_MIRROR=true ;;
            claude-provider)
                SKIP_PREREQUISITES=true
                SELECTED_TOOLS+=("claude-provider") ;;
            ghostty|yazi|lazygit|claude|openclaw|antigravity|orbstack|obsidian|maccy|jdk)
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
        "Antigravity  Google AI 开发平台 (智能编码/Agent 工作流)"
        "OrbStack     Docker 容器 & Linux 虚拟机 (轻量/快速)"
        "Obsidian     知识管理 & 笔记工具 (Markdown/双链/插件)"
        "Maccy        剪贴板管理工具 (轻量/开源/快捷搜索)"
        "JDK          Java 开发工具包 (SDKMAN 管理/多版本切换)"
        "跳过         不安装工具，仅修改配置"
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
    local skip_index=$((count - 1))
    for ((i=0; i<count; i++)); do
        if [[ "${selected[$i]}" == "on" ]]; then
            if [[ $i -eq $skip_index ]]; then
                SKIP_PREREQUISITES=true
            else
                SELECTED_TOOLS+=("${ALL_TOOLS[$i]}")
            fi
        fi
    done

    # "跳过" 被选中时，忽略其他工具选择
    if $SKIP_PREREQUISITES; then
        SELECTED_TOOLS=()
        info "跳过工具安装，进入配置菜单"
    elif [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
        SKIP_PREREQUISITES=true
        info "未选择工具，跳过安装"
    fi
}

# ── 工具函数 ──────────────────────────────────────────
is_selected() {
    local tool="$1"
    [[ ${#SELECTED_TOOLS[@]} -eq 0 ]] && return 1
    for t in "${SELECTED_TOOLS[@]}"; do
        [[ "$t" == "$tool" ]] && return 0
    done
    return 1
}

source_zshrc() {
    if [[ -f "$HOME/.zshrc" ]]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    fi
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

    # ── 0. 网络环境检测 ─────────────────────────────
    setup_mirror

    local need_source_zshrc=false

    # ── 1. Xcode Command Line Tools ──────────────────
    # 用 xcrun --version 验证 CLT 是否真正可用（xcode-select -p 可能路径存在但工具损坏）
    if xcode-select -p &>/dev/null && xcrun --version &>/dev/null; then
        ok "Xcode Command Line Tools 已安装"
    else
        # 如果路径存在但工具损坏，先重置
        if xcode-select -p &>/dev/null; then
            warn "Xcode Command Line Tools 路径存在但工具损坏，正在重置..."
            sudo xcode-select --reset 2>/dev/null < /dev/tty
        fi
        info "正在安装 Xcode Command Line Tools (Homebrew 编译依赖)..."
        xcode-select --install 2>/dev/null
        # xcode-select --install 会弹出 GUI 对话框，等待用户点击安装完成
        info "请在弹出的对话框中点击「安装」，等待完成后按回车继续..."
        read -r < /dev/tty
        # 验证是否安装成功
        if xcrun --version &>/dev/null; then
            ok "Xcode Command Line Tools 安装完成"
        else
            err "Xcode Command Line Tools 安装失败，部分 brew 包可能无法编译安装"
        fi
    fi

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
        # 预先获取 sudo 权限，避免 brew 安装脚本因非管理员而失败
        info "Homebrew 需要管理员权限，请输入密码:"
        sudo -v < /dev/tty
        # 必须用 /dev/tty 作为 stdin，否则 curl|bash 模式下 brew 安装脚本检测不到 TTY
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$(github_raw_url https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")" < /dev/tty
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

    # ── 4. Shell 提示符 ──────────────────────────────
    echo ""
    echo -e "${BOLD}请选择 Shell 提示符工具:${NC}"
    echo -e "  ${CYAN}1)${NC} Oh My Zsh + 插件 (经典方案，功能丰富)"
    echo -e "  ${CYAN}2)${NC} Starship (跨平台极速提示符)"
    echo -e "  ${CYAN}3)${NC} 跳过 (保持现有配置)"
    echo -en "${CYAN}请输入选项 [1/2/3] (默认 1): ${NC}" > /dev/tty
    local prompt_choice
    read -r prompt_choice < /dev/tty
    prompt_choice="${prompt_choice:-1}"

    if [[ "$prompt_choice" == "2" ]]; then
        # ── Starship ────────────────────────────────────
        if command -v starship &>/dev/null; then
            ok "Starship 已安装: $(starship --print-full-init 2>/dev/null | head -1 || echo '已安装')"
        else
            info "正在安装 Starship..."
            brew install starship
            ok "Starship 安装完成"
        fi

        # 安装 Nerd Font（Starship 大部分主题需要）
        echo ""
        echo -e "${BOLD}选择 Nerd Font 字体:${NC}"
        echo -e "  ${CYAN}1)${NC} Hack Nerd Font (推荐，等宽编程字体)"
        echo -e "  ${CYAN}2)${NC} JetBrainsMono Nerd Font"
        echo -e "  ${CYAN}3)${NC} FiraCode Nerd Font"
        echo -e "  ${CYAN}4)${NC} MesloLG Nerd Font"
        echo -e "  ${CYAN}5)${NC} CascadiaCode Nerd Font"
        echo -e "  ${CYAN}6)${NC} 跳过 (已安装或不需要)"
        echo -en "${CYAN}请输入选项 [1-6] (默认 1): ${NC}" > /dev/tty
        local font_choice
        read -r font_choice < /dev/tty
        font_choice="${font_choice:-1}"

        local font_pkg=""
        case "$font_choice" in
            1) font_pkg="font-hack-nerd-font" ;;
            2) font_pkg="font-jetbrains-mono-nerd-font" ;;
            3) font_pkg="font-fira-code-nerd-font" ;;
            4) font_pkg="font-meslo-lg-nerd-font" ;;
            5) font_pkg="font-cascadia-code-nerd-font" ;;
            6) font_pkg="" ;;
            *) warn "无效选项，使用推荐字体"
               font_pkg="font-hack-nerd-font" ;;
        esac

        if [[ -n "$font_pkg" ]]; then
            if brew list --cask "$font_pkg" &>/dev/null; then
                ok "$font_pkg 已安装"
            else
                info "正在安装 $font_pkg..."
                brew install --cask "$font_pkg"
                ok "$font_pkg 安装完成"
                warn "请在终端偏好设置中将字体切换为对应的 Nerd Font"
            fi
        else
            ok "跳过 Nerd Font 安装"
        fi

        # 选择 Starship 主题
        local STARSHIP_CONFIG_DIR="$HOME/.config"
        local STARSHIP_CONFIG="$STARSHIP_CONFIG_DIR/starship.toml"
        local STARSHIP_GIST_URL="https://gist.githubusercontent.com/zhangchitc/62f5dca64c599084f936fda9963f1100/raw/starship.toml"
        mkdir -p "$STARSHIP_CONFIG_DIR"

        echo ""
        echo -e "${BOLD}选择 Starship 主题:${NC}"
        echo -e "  ${CYAN} 1)${NC} Catppuccin Mocha Powerline (推荐，Nerd Font 图标)"
        echo -e "  ${CYAN} 2)${NC} catppuccin-powerline"
        echo -e "  ${CYAN} 3)${NC} gruvbox-rainbow"
        echo -e "  ${CYAN} 4)${NC} tokyo-night"
        echo -e "  ${CYAN} 5)${NC} pastel-powerline"
        echo -e "  ${CYAN} 6)${NC} jetpack"
        echo -e "  ${CYAN} 7)${NC} pure-preset"
        echo -e "  ${CYAN} 8)${NC} nerd-font-symbols"
        echo -e "  ${CYAN} 9)${NC} plain-text-symbols (无需 Nerd Font)"
        echo -e "  ${CYAN}10)${NC} 跳过 (保持现有配置)"
        echo -en "${CYAN}请输入选项 [1-10] (默认 1): ${NC}" > /dev/tty
        local theme_choice
        read -r theme_choice < /dev/tty
        theme_choice="${theme_choice:-1}"

        case "$theme_choice" in
            1)
                info "下载 Catppuccin Mocha 主题..."
                if curl -fsSL "$(github_raw_url "$STARSHIP_GIST_URL")" -o "$STARSHIP_CONFIG" 2>/dev/null; then
                    ok "Starship 主题已应用: Catppuccin Mocha Powerline"
                else
                    warn "下载失败，使用内置 catppuccin-powerline"
                    starship preset catppuccin-powerline -o "$STARSHIP_CONFIG" 2>/dev/null
                fi
                ;;
            2)  starship preset catppuccin-powerline -o "$STARSHIP_CONFIG" 2>/dev/null
                ok "Starship 主题已应用: catppuccin-powerline" ;;
            3)  starship preset gruvbox-rainbow -o "$STARSHIP_CONFIG" 2>/dev/null
                ok "Starship 主题已应用: gruvbox-rainbow" ;;
            4)  starship preset tokyo-night -o "$STARSHIP_CONFIG" 2>/dev/null
                ok "Starship 主题已应用: tokyo-night" ;;
            5)  starship preset pastel-powerline -o "$STARSHIP_CONFIG" 2>/dev/null
                ok "Starship 主题已应用: pastel-powerline" ;;
            6)  starship preset jetpack -o "$STARSHIP_CONFIG" 2>/dev/null
                ok "Starship 主题已应用: jetpack" ;;
            7)  starship preset pure-preset -o "$STARSHIP_CONFIG" 2>/dev/null
                ok "Starship 主题已应用: pure-preset" ;;
            8)  starship preset nerd-font-symbols -o "$STARSHIP_CONFIG" 2>/dev/null
                ok "Starship 主题已应用: nerd-font-symbols" ;;
            9)  starship preset plain-text-symbols -o "$STARSHIP_CONFIG" 2>/dev/null
                ok "Starship 主题已应用: plain-text-symbols" ;;
            10) ok "保持现有 Starship 配置" ;;
            *)  warn "无效选项，使用推荐主题"
                curl -fsSL "$(github_raw_url "$STARSHIP_GIST_URL")" -o "$STARSHIP_CONFIG" 2>/dev/null
                ;;
        esac

        # 将 Starship 初始化写入 .zshrc
        local ZSHRC="$HOME/.zshrc"
        if [[ -f "$ZSHRC" ]] && grep -q 'starship init zsh' "$ZSHRC" 2>/dev/null; then
            ok ".zshrc 中已配置 Starship"
        else
            [[ ! -f "$ZSHRC" ]] && touch "$ZSHRC"
            cat >> "$ZSHRC" << 'ZSHRC_EOF'

# Starship 提示符
eval "$(starship init zsh)"
ZSHRC_EOF
            ok "Starship 初始化已写入 .zshrc"
            need_source_zshrc=true
        fi

        # Starship 模式下仍然安装 zsh 插件（增强补全和高亮）
        # zsh-autosuggestions (输入时显示历史建议)
        local ZSH_PLUGIN_DIR="${HOME}/.zsh/plugins"
        mkdir -p "$ZSH_PLUGIN_DIR"

        if [[ -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]]; then
            ok "zsh-autosuggestions 插件已安装"
        else
            info "安装 zsh-autosuggestions 插件..."
            git clone "$(github_clone_url https://github.com/zsh-users/zsh-autosuggestions)" "$ZSH_PLUGIN_DIR/zsh-autosuggestions" 2>/dev/null
            ok "zsh-autosuggestions 已安装"
            need_source_zshrc=true
        fi

        # zsh-syntax-highlighting (命令语法高亮)
        if [[ -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]]; then
            ok "zsh-syntax-highlighting 插件已安装"
        else
            info "安装 zsh-syntax-highlighting 插件..."
            git clone "$(github_clone_url https://github.com/zsh-users/zsh-syntax-highlighting)" "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" 2>/dev/null
            ok "zsh-syntax-highlighting 已安装"
            need_source_zshrc=true
        fi

        # 确保 .zshrc 中加载了插件 (非 Oh My Zsh 模式下手动 source)
        if ! grep -q 'zsh-autosuggestions/zsh-autosuggestions.zsh' "$ZSHRC" 2>/dev/null; then
            cat >> "$ZSHRC" << ZSHRC_PLUGIN_EOF

# Zsh 插件 (手动加载)
[[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSHRC_PLUGIN_EOF
            ok "zsh 插件加载配置已写入 .zshrc"
            need_source_zshrc=true
        fi

    elif [[ "$prompt_choice" == "1" ]] || [[ "$prompt_choice" != "3" ]]; then
        # ── Oh My Zsh (默认) ────────────────────────────
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            ok "Oh My Zsh 已安装"
        else
            info "正在安装 Oh My Zsh..."
            # RUNZSH=no 防止安装后自动切换到 zsh 导致脚本中断
            # KEEP_ZSHRC=yes 保留已有 .zshrc 配置
            RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "$(github_raw_url https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)")" < /dev/tty
            ok "Oh My Zsh 安装完成"
        fi

        # 安装常用 Oh My Zsh 插件
        local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

        # zsh-autosuggestions (输入时显示历史建议)
        if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
            ok "zsh-autosuggestions 插件已安装"
        else
            info "安装 zsh-autosuggestions 插件..."
            git clone "$(github_clone_url https://github.com/zsh-users/zsh-autosuggestions)" "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null
            ok "zsh-autosuggestions 已安装"
            need_source_zshrc=true
        fi

        # zsh-syntax-highlighting (命令语法高亮)
        if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
            ok "zsh-syntax-highlighting 插件已安装"
        else
            info "安装 zsh-syntax-highlighting 插件..."
            git clone "$(github_clone_url https://github.com/zsh-users/zsh-syntax-highlighting)" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null
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

    else
        # ── 跳过 ────────────────────────────────────────
        ok "已跳过 Shell 提示符配置"
    fi

    # ── 5. NVM (Node Version Manager) ────────────────
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # 尝试加载已有的 nvm
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" 2>/dev/null

    if command -v nvm &>/dev/null; then
        ok "NVM 已安装: $(nvm --version)"
    else
        info "正在安装 NVM..."
        # PROFILE=/dev/null 防止 NVM 安装脚本修改 shell 配置导致管道中断
        curl -fsSL "$(github_raw_url https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh)" | PROFILE=/dev/null bash
        # 立即加载 nvm
        export NVM_DIR="$HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        ok "NVM 安装完成: $(nvm --version 2>/dev/null || echo '已安装')"
        # 手动写入 .zshrc（因为上面用了 PROFILE=/dev/null 跳过了自动写入）
        local ZSHRC="$HOME/.zshrc"
        if ! grep -q 'NVM_DIR' "$ZSHRC" 2>/dev/null; then
            cat >> "$ZSHRC" << 'NVM_EOF'

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
NVM_EOF
            ok "NVM 配置已写入 .zshrc"
        fi
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

    # ── 7. Bun (高性能 JavaScript 运行时 / 包管理器) ──
    if command -v bun &>/dev/null; then
        ok "Bun 已安装: $(bun --version)"
    else
        info "正在安装 Bun..."
        if brew install oven-sh/bun/bun 2>&1; then
            ok "Bun 安装完成: $(bun --version)"
        else
            warn "Homebrew 安装失败，尝试官方脚本..."
            curl -fsSL https://bun.sh/install | bash
            export BUN_INSTALL="$HOME/.bun"
            export PATH="$BUN_INSTALL/bin:$PATH"
            # 写入 .zshrc
            local ZSHRC="$HOME/.zshrc"
            if ! grep -q 'BUN_INSTALL' "$ZSHRC" 2>/dev/null; then
                cat >> "$ZSHRC" << 'BUN_EOF'

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
BUN_EOF
                ok "Bun 配置已写入 .zshrc"
            fi
            need_source_zshrc=true
            ok "Bun 安装完成: $(bun --version 2>/dev/null || echo '已安装')"
        fi
    fi

    echo ""
    echo -e "${GREEN}${BOLD}环境基础检查完成${NC}"

    if $need_source_zshrc; then
        echo -e "${YELLOW}提示: 部分配置需要 source ~/.zshrc 或重新打开终端后生效${NC}"
    fi

    echo ""
}

# 强制清理 brew 残留锁文件和僵尸进程
brew_cleanup_locks() {
    local cache_dir
    cache_dir="$(brew --cache 2>/dev/null || echo "$HOME/Library/Caches/Homebrew/downloads")"
    # 杀掉所有残留的 brew 子进程
    local stale_pids
    stale_pids=$(ps aux | grep '[b]rew install\|[b]rew fetch' | awk '{print $2}')
    if [[ -n "$stale_pids" ]]; then
        warn "终止残留 brew 进程..."
        echo "$stale_pids" | xargs kill -9 2>/dev/null
        sleep 1
    fi
    # 删除所有锁文件
    find "$cache_dir" -name '*incomplete*' -maxdepth 1 -delete 2>/dev/null
}

# 带重试的 brew install (最多 3 次，每次失败自动清锁)
brew_install() {
    local formula="$1"
    local name="${2:-$formula}"
    if brew list "$formula" &>/dev/null; then
        ok "$name 已安装"
        return
    fi

    local max_retries=3
    local attempt=1
    while [[ $attempt -le $max_retries ]]; do
        brew_cleanup_locks
        if [[ $attempt -gt 1 ]]; then
            warn "$name 第 $attempt 次重试..."
        else
            info "正在安装 $name ..."
        fi
        if brew install "$formula" 2>&1; then
            ok "$name 安装完成"
            return
        fi
        err "$name 安装失败 (第 $attempt/$max_retries 次)"
        ((attempt++))
    done
    err "$name 安装失败，已跳过。可稍后手动运行: brew install $formula"
}

brew_install_cask() {
    local cask="$1"
    local name="${2:-$cask}"
    if brew list --cask "$cask" &>/dev/null; then
        ok "$name (cask) 已安装"
        return
    fi

    local max_retries=3
    local attempt=1
    while [[ $attempt -le $max_retries ]]; do
        brew_cleanup_locks
        if [[ $attempt -gt 1 ]]; then
            warn "$name 第 $attempt 次重试..."
        else
            info "正在安装 $name ..."
        fi
        if brew install --cask "$cask" 2>&1; then
            ok "$name 安装完成"
            return
        fi
        err "$name 安装失败 (第 $attempt/$max_retries 次)"
        ((attempt++))
    done
    err "$name 安装失败，已跳过。可稍后手动运行: brew install --cask $cask"
}

# ══════════════════════════════════════════════════════
# 安装模块
# ══════════════════════════════════════════════════════

# ── Ghostty ───────────────────────────────────────────
install_ghostty() {
    echo ""
    info "========== [1/10] Ghostty =========="
    brew_install_cask ghostty "Ghostty"

    GHOSTTY_DIR="$HOME/.config/ghostty"
    GHOSTTY_CONF="$GHOSTTY_DIR/config"
    mkdir -p "$GHOSTTY_DIR"

    echo ""
    echo -e "  ${CYAN}1)${NC} 使用推荐配置 (Maple Mono + Catppuccin + 毛玻璃)"
    echo -e "  ${CYAN}2)${NC} 使用默认配置 / 保留当前配置"
    echo ""
    read -rp "$(echo -e "${BOLD}选择 Ghostty 配置方案 [1/2] (默认 1): ${NC}")" ghostty_choice < /dev/tty

    if [[ "$ghostty_choice" != "2" ]]; then
        backup_if_exists "$GHOSTTY_CONF"
        cat > "$GHOSTTY_CONF" << 'GHOSTTY_EOF'
# ============================================
# Ghostty Terminal - 完整配置
# ============================================
# 文件路径: ~/.config/ghostty/config
# 重新加载: Cmd+Shift+, (macOS)
# 查看所有选项: ghostty +show-config --default --docs

# --- 字体排版 ---
# 主字体（Maple Mono 等宽字体，含 Nerd Font 图标和中文）
font-family = "Maple Mono NF CN"
# 字号
font-size = 12
# 加粗渲染，让字体在低分辨率下更清晰
font-thicken = true
# 行高微调，增加 2px 让行间距更舒适
adjust-cell-height = 2

# --- 主题与颜色 ---
# 使用 Catppuccin Latte 亮色主题
theme = Catppuccin Latte
#theme = Ayu Light

# --- 窗口与外观 ---
# 背景透明度（0.0 全透明 ~ 1.0 不透明）
background-opacity = 0.85
# 背景模糊半径，配合透明度实现毛玻璃效果
background-blur-radius = 30
# macOS 标题栏透明，与终端背景融为一体
macos-titlebar-style = transparent
# 窗口左右内边距（像素）
window-padding-x = 10
# 窗口上下内边距（像素）
window-padding-y = 8
# 始终保存窗口状态（位置、大小），重启后恢复
window-save-state = always
# 窗口主题跟随系统明暗模式
window-theme = auto

# --- 光标 ---
# 光标样式：bar（竖线）/ block（方块）/ underline（下划线）
cursor-style = bar
# 光标闪烁
cursor-style-blink = true
# 光标透明度
cursor-opacity = 0.8

# --- 鼠标 ---
# 打字时自动隐藏鼠标指针
mouse-hide-while-typing = true
# 选中文本自动复制到系统剪贴板
copy-on-select = clipboard

# --- 快捷终端（Quake 风格下拉终端）---
# 快捷终端从屏幕顶部滑出
quick-terminal-position = top
# 在鼠标所在的屏幕上显示
quick-terminal-screen = mouse
# 失去焦点时自动隐藏
quick-terminal-autohide = true
# 滑出/收回动画时长（秒）
quick-terminal-animation-duration = 0.15

# --- 安全 ---
# 粘贴保护：粘贴含危险命令时弹出确认
clipboard-paste-protection = true
# 括号粘贴模式安全检查，防止粘贴注入攻击
clipboard-paste-bracketed-safe = true

# --- Shell 集成 ---
# 自动检测并启用 Shell 集成（支持 zsh/bash/fish）
shell-integration = detect

# --- 快捷键 ---
# 标签页
# 新建标签页
keybind = cmd+t=new_tab
# 切换到上一个标签页
keybind = cmd+shift+left=previous_tab
# 切换到下一个标签页
keybind = cmd+shift+right=next_tab
# 关闭当前标签页/分屏
keybind = cmd+w=close_surface

# 分屏
# 向右新建分屏
keybind = cmd+d=new_split:right
# 向下新建分屏
keybind = cmd+shift+d=new_split:down
# 焦点移到左侧分屏
keybind = cmd+alt+left=goto_split:left
# 焦点移到右侧分屏
keybind = cmd+alt+right=goto_split:right
# 焦点移到上方分屏
keybind = cmd+alt+up=goto_split:top
# 焦点移到下方分屏
keybind = cmd+alt+down=goto_split:bottom

# 字号调整
# 放大字号
keybind = cmd+plus=increase_font_size:1
# 缩小字号
keybind = cmd+minus=decrease_font_size:1
# 重置字号为默认值
keybind = cmd+zero=reset_font_size

# 快捷终端全局热键
# Ctrl+` 全局唤出/隐藏快捷终端
keybind = global:ctrl+grave_accent=toggle_quick_terminal

# 分屏管理
# 均分所有分屏大小
keybind = cmd+shift+e=equalize_splits
# 切换当前分屏全屏/还原
keybind = cmd+shift+f=toggle_split_zoom

# 重新加载配置
# 重新加载此配置文件
keybind = cmd+shift+comma=reload_config

# --- 性能 ---
# 回滚缓冲区大小（约 25MB），可回看大量历史输出
scrollback-limit = 25000000
GHOSTTY_EOF
        ok "Ghostty 配置已写入"
    fi

    source_zshrc
}

# ── Yazi ──────────────────────────────────────────────
install_yazi() {
    echo ""
    info "========== [2/10] Yazi =========="
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

    echo ""
    echo -e "  ${CYAN}1)${NC} 使用推荐配置 (glow 预览 + 大预览区 + 快捷跳转)"
    echo -e "  ${CYAN}2)${NC} 使用默认配置 / 保留当前配置"
    echo ""
    read -rp "$(echo -e "${BOLD}选择 Yazi 配置方案 [1/2] (默认 1): ${NC}")" yazi_choice < /dev/tty

    if [[ "$yazi_choice" != "2" ]]; then

    # yazi.toml
    backup_if_exists "$YAZI_DIR/yazi.toml"
    # 安装 glow (Markdown 终端渲染，用于 Yazi 预览)
    brew_install glow "glow (Markdown 预览)"

    cat > "$YAZI_DIR/yazi.toml" << 'YAZI_EOF'
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

    fi  # end apply_yazi_config

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

    source_zshrc
}

# ── Lazygit ───────────────────────────────────────────
install_lazygit() {
    echo ""
    info "========== [3/10] Lazygit =========="
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

    source_zshrc
}

# ── Claude Code 提供商配置 ────────────────────────────
# 标记块的起止标识，用于在 .zshrc 中定位和替换
CLAUDE_BLOCK_START="# >>> Claude Code Provider Config >>>"
CLAUDE_BLOCK_END="# <<< Claude Code Provider Config <<<"

# 从 .zshrc 中读取当前生效的提供商
detect_claude_provider() {
    local zshrc="$HOME/.zshrc"
    if [[ ! -f "$zshrc" ]] || ! grep -q "$CLAUDE_BLOCK_START" "$zshrc"; then
        echo "未配置"
        return
    fi
    local block
    block=$(sed -n "/$CLAUDE_BLOCK_START/,/$CLAUDE_BLOCK_END/p" "$zshrc")
    if echo "$block" | grep -q "CLAUDE_CODE_USE_BEDROCK"; then
        echo "Amazon Bedrock"
    elif echo "$block" | grep -q "CLAUDE_CODE_USE_VERTEX"; then
        echo "Google Vertex AI"
    elif echo "$block" | grep -q "ANTHROPIC_BASE_URL"; then
        echo "自定义 API 代理"
    elif echo "$block" | grep -q "ANTHROPIC_API_KEY"; then
        echo "Anthropic 直连"
    else
        echo "未知"
    fi
}

# 将配置写入 .zshrc（替换已有的 Claude 配置块）
write_claude_config() {
    local config_content="$1"
    local zshrc="$HOME/.zshrc"
    touch "$zshrc"

    # 如果已有配置块，先移除
    if grep -q "$CLAUDE_BLOCK_START" "$zshrc"; then
        local tmpfile
        tmpfile=$(mktemp)
        sed "/$CLAUDE_BLOCK_START/,/$CLAUDE_BLOCK_END/d" "$zshrc" > "$tmpfile"
        mv "$tmpfile" "$zshrc"
    fi

    # 追加新配置块
    {
        echo ""
        echo "$CLAUDE_BLOCK_START"
        echo "$config_content"
        echo "$CLAUDE_BLOCK_END"
    } >> "$zshrc"
}

# 读取用户输入（带默认值）
read_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    if [[ -n "$default" ]]; then
        echo -en "${CYAN}$prompt [${default}]: ${NC}" > /dev/tty
    else
        echo -en "${CYAN}$prompt: ${NC}" > /dev/tty
    fi
    read -r result < /dev/tty
    echo "${result:-$default}"
}

# 从 .zshrc 现有配置块中提取某个环境变量的值
get_existing_value() {
    local var_name="$1"
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]] && grep -q "$CLAUDE_BLOCK_START" "$zshrc"; then
        sed -n "/$CLAUDE_BLOCK_START/,/$CLAUDE_BLOCK_END/p" "$zshrc" \
            | grep "export ${var_name}=" \
            | head -1 \
            | sed "s/.*export ${var_name}=\"\(.*\)\"/\1/" \
            | sed "s/.*export ${var_name}=\(.*\)/\1/"
    fi
}

configure_claude_provider() {
    info "配置 Claude Code API 提供商"

    local current_provider
    current_provider=$(detect_claude_provider)
    echo ""
    echo -e "  当前提供商: ${CYAN}${current_provider}${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Anthropic 直连        (使用 Anthropic API Key)"
    echo -e "  ${GREEN}2)${NC} Amazon Bedrock        (使用 AWS 凭证)"
    echo -e "  ${GREEN}3)${NC} Google Vertex AI      (使用 GCP 项目)"
    echo -e "  ${GREEN}4)${NC} 自定义 API 代理       (OpenRouter / 中转站等)"
    echo -e "  ${GREEN}5)${NC} 清除配置              (移除当前提供商设置)"
    echo -e "  ${GREEN}0)${NC} 跳过                  (保持现有配置不变)"
    echo ""
    echo -en "${CYAN}  请输入选项 [0-5]: ${NC}" > /dev/tty
    read -r provider_choice < /dev/tty

    case "${provider_choice}" in
        1)
            info "配置 Anthropic 直连..."
            local existing_key
            existing_key=$(get_existing_value "ANTHROPIC_API_KEY")
            local api_key
            api_key=$(read_with_default "  Anthropic API Key" "$existing_key")

            if [[ -z "$api_key" ]]; then
                err "API Key 不能为空，跳过配置"
            else
                local masked_key="${api_key:0:8}...${api_key: -4}"
                write_claude_config "export ANTHROPIC_API_KEY=\"${api_key}\""
                ok "Anthropic 直连已配置 (Key: ${masked_key})"
            fi
            ;;
        2)
            info "配置 Amazon Bedrock..."
            echo "" > /dev/tty
            echo -e "  认证方式:" > /dev/tty
            echo -e "    ${GREEN}a)${NC} AWS Access Key (AK/SK)" > /dev/tty
            echo -e "    ${GREEN}b)${NC} AWS Profile (~/.aws/credentials)" > /dev/tty
            echo "" > /dev/tty
            echo -en "${CYAN}  选择认证方式 [a/b]: ${NC}" > /dev/tty
            local aws_auth_mode
            read -r aws_auth_mode < /dev/tty

            local existing_region
            existing_region=$(get_existing_value "AWS_REGION")
            local aws_region
            aws_region=$(read_with_default "  AWS Region" "${existing_region:-us-east-1}")

            local config_lines="export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=\"${aws_region}\""

            if [[ "$aws_auth_mode" == "b" ]]; then
                local existing_profile
                existing_profile=$(get_existing_value "AWS_PROFILE")
                local aws_profile
                aws_profile=$(read_with_default "  AWS Profile 名称" "${existing_profile:-default}")
                config_lines="${config_lines}
export AWS_PROFILE=\"${aws_profile}\""
                write_claude_config "$config_lines"
                ok "Amazon Bedrock 已配置 (Profile: ${aws_profile}, Region: ${aws_region})"
            else
                local existing_ak existing_sk existing_token
                existing_ak=$(get_existing_value "AWS_ACCESS_KEY_ID")
                existing_sk=$(get_existing_value "AWS_SECRET_ACCESS_KEY")
                existing_token=$(get_existing_value "AWS_SESSION_TOKEN")

                local access_key secret_key session_token
                access_key=$(read_with_default "  AWS Access Key ID" "$existing_ak")
                secret_key=$(read_with_default "  AWS Secret Access Key" "$existing_sk")
                session_token=$(read_with_default "  AWS Session Token (可选, 回车跳过)" "$existing_token")

                if [[ -z "$access_key" || -z "$secret_key" ]]; then
                    err "Access Key 和 Secret Key 不能为空，跳过配置"
                else
                    config_lines="${config_lines}
export AWS_ACCESS_KEY_ID=\"${access_key}\"
export AWS_SECRET_ACCESS_KEY=\"${secret_key}\""
                    [[ -n "$session_token" ]] && config_lines="${config_lines}
export AWS_SESSION_TOKEN=\"${session_token}\""
                    write_claude_config "$config_lines"
                    local masked_ak="${access_key:0:4}...${access_key: -4}"
                    ok "Amazon Bedrock 已配置 (AK: ${masked_ak}, Region: ${aws_region})"
                fi
            fi
            ;;
        3)
            info "配置 Google Vertex AI..."
            local existing_region existing_project
            existing_region=$(get_existing_value "CLOUD_ML_REGION")
            existing_project=$(get_existing_value "ANTHROPIC_VERTEX_PROJECT_ID")

            local gcp_project gcp_region
            gcp_project=$(read_with_default "  GCP 项目 ID" "$existing_project")
            gcp_region=$(read_with_default "  GCP Region" "${existing_region:-us-east5}")

            if [[ -z "$gcp_project" ]]; then
                err "GCP 项目 ID 不能为空，跳过配置"
            else
                write_claude_config "export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=\"${gcp_region}\"
export ANTHROPIC_VERTEX_PROJECT_ID=\"${gcp_project}\""
                ok "Google Vertex AI 已配置 (项目: ${gcp_project}, Region: ${gcp_region})"
                echo ""
                info "提示: 请确保已通过 gcloud auth application-default login 完成认证"
            fi
            ;;
        4)
            info "配置自定义 API 代理..."
            local existing_url existing_key
            existing_url=$(get_existing_value "ANTHROPIC_BASE_URL")
            existing_key=$(get_existing_value "ANTHROPIC_API_KEY")

            local base_url api_key
            base_url=$(read_with_default "  API Base URL (例: https://openrouter.ai/api/v1)" "$existing_url")
            api_key=$(read_with_default "  API Key" "$existing_key")

            if [[ -z "$base_url" || -z "$api_key" ]]; then
                err "Base URL 和 API Key 不能为空，跳过配置"
            else
                local masked_key="${api_key:0:8}...${api_key: -4}"
                write_claude_config "export ANTHROPIC_BASE_URL=\"${base_url}\"
export ANTHROPIC_API_KEY=\"${api_key}\""
                ok "自定义 API 代理已配置 (URL: ${base_url}, Key: ${masked_key})"
            fi
            ;;
        5)
            local zshrc="$HOME/.zshrc"
            if [[ -f "$zshrc" ]] && grep -q "$CLAUDE_BLOCK_START" "$zshrc"; then
                local tmpfile
                tmpfile=$(mktemp)
                sed "/$CLAUDE_BLOCK_START/,/$CLAUDE_BLOCK_END/d" "$zshrc" > "$tmpfile"
                mv "$tmpfile" "$zshrc"
                ok "已清除 Claude 提供商配置"
            else
                warn "未找到已有的 Claude 提供商配置"
            fi
            ;;
        0|"")
            ok "保持现有配置不变"
            ;;
        *)
            warn "无效选项，跳过 Claude 提供商配置"
            ;;
    esac
}

# ── Claude Code ───────────────────────────────────────
install_claude() {
    echo ""
    info "========== [4/10] Claude Code =========="

    if command -v claude &>/dev/null; then
        ok "Claude Code 已安装: $(claude --version 2>/dev/null || echo '已安装')"
    else
        info "正在安装 Claude Code..."
        # 确保默认 shell 是 zsh（Claude Code 安装脚本会检测并提示切换，导致管道中断）
        if [[ "$SHELL" != */zsh ]]; then
            chsh -s "$(which zsh)" 2>/dev/null < /dev/tty
        fi
        # 优先使用官方安装脚本 (自包含二进制，无需 Node.js)
        if curl -fsSL https://claude.ai/install.sh | SHELL=/bin/zsh bash; then
            # 确保 ~/.local/bin 在 PATH 中
            local ZSHRC="$HOME/.zshrc"
            if ! grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
                ok "已将 ~/.local/bin 添加到 PATH"
            fi
            export PATH="$HOME/.local/bin:$PATH"
            ok "Claude Code 安装完成"
        else
            warn "官方脚本安装失败，尝试 Homebrew..."
            brew install --cask claude-code 2>/dev/null && ok "Claude Code (Homebrew) 安装完成" || err "Claude Code 安装失败，请手动安装"
        fi
    fi

    # ── 提供商配置 ──────────────────────────────────────
    echo ""
    configure_claude_provider

    echo ""
    info "Claude Code 使用提示:"
    echo "   claude              启动交互式会话"
    echo "   claude \"问题\"       直接提问"
    echo "   claude -p \"问题\"    非交互模式 (管道友好)"
    echo "   首次使用需要登录:    claude login"

    source_zshrc
}

# ── OpenClaw ──────────────────────────────────────────
install_openclaw() {
    echo ""
    info "========== [5/10] OpenClaw =========="

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

    source_zshrc
}

# ── Antigravity ──────────────────────────────────────
install_antigravity() {
    echo ""
    info "========== [6/10] Antigravity =========="

    if brew list --cask antigravity &>/dev/null; then
        ok "Antigravity 已安装"
    else
        info "正在安装 Google Antigravity..."
        brew_install_cask antigravity "Antigravity"
    fi

    echo ""
    info "Antigravity 使用提示:"
    echo "   从 Applications 启动 Antigravity"
    echo "   首次启动需要 Google 账号登录"

    source_zshrc
}

# ── OrbStack ────────────────────────────────────────
install_orbstack() {
    echo ""
    info "========== [7/10] OrbStack =========="

    brew_install_cask orbstack "OrbStack"

    echo ""
    info "OrbStack 使用提示:"
    echo "   从 Applications 启动 OrbStack"
    echo "   OrbStack 兼容 Docker CLI，安装后可直接使用 docker 命令"
    echo "   支持 Docker 容器、Kubernetes、Linux 虚拟机"

    source_zshrc
}

# ── Obsidian ──────────────────────────────────────────
install_obsidian() {
    echo ""
    info "========== [8/10] Obsidian =========="

    brew_install_cask obsidian "Obsidian"

    # 安装 Excalidraw 社区插件
    echo ""
    info "配置 Excalidraw 插件..."

    echo ""
    echo -e "${BOLD}请选择 Obsidian Vault 路径 (Excalidraw 插件将安装到此 Vault):${NC}"
    echo -e "  ${CYAN}1)${NC} 默认路径: ~/Obsidian"
    echo -e "  ${CYAN}2)${NC} 自定义路径"
    echo -e "  ${CYAN}3)${NC} 跳过插件安装"
    echo -en "${CYAN}请输入选项 [1/2/3] (默认 1): ${NC}" > /dev/tty
    local vault_choice
    read -r vault_choice < /dev/tty
    vault_choice="${vault_choice:-1}"

    local vault_path=""
    case "$vault_choice" in
        1) vault_path="$HOME/Obsidian" ;;
        2)
            echo -en "${CYAN}请输入 Vault 路径: ${NC}" > /dev/tty
            read -r vault_path < /dev/tty
            # 展开 ~ 为 $HOME
            vault_path="${vault_path/#\~/$HOME}"
            ;;
        3)
            ok "跳过 Excalidraw 插件安装"
            source_zshrc
            return
            ;;
        *)
            vault_path="$HOME/Obsidian"
            ;;
    esac

    if [[ -z "$vault_path" ]]; then
        warn "Vault 路径为空，跳过插件安装"
        source_zshrc
        return
    fi

    local plugin_dir="$vault_path/.obsidian/plugins/obsidian-excalidraw-plugin"

    if [[ -d "$plugin_dir" ]]; then
        ok "Excalidraw 插件已安装: $plugin_dir"
    else
        mkdir -p "$plugin_dir"
        info "正在下载 Excalidraw 插件..."

        # 获取最新 release 版本
        local release_url="https://api.github.com/repos/zsviczian/obsidian-excalidraw-plugin/releases/latest"
        local release_info
        release_info=$(curl -fsSL "$release_url" 2>/dev/null)

        if [[ -n "$release_info" ]]; then
            local tag
            tag=$(echo "$release_info" | grep '"tag_name"' | head -1 | sed 's/.*: *"//;s/".*//')

            if [[ -n "$tag" ]]; then
                local base_url="https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/${tag}"
                local dl_ok=true

                for file in main.js manifest.json styles.css; do
                    local dl_url
                    dl_url="$(github_raw_url "${base_url}/${file}")"
                    if ! curl -fsSL "$dl_url" -o "$plugin_dir/$file" 2>/dev/null; then
                        warn "下载 $file 失败"
                        dl_ok=false
                    fi
                done

                if $dl_ok; then
                    ok "Excalidraw 插件安装完成 (${tag})"
                else
                    err "部分文件下载失败，请手动在 Obsidian 设置中安装 Excalidraw 插件"
                    rm -rf "$plugin_dir"
                fi
            else
                err "无法获取最新版本号，请手动安装 Excalidraw 插件"
                rm -rf "$plugin_dir"
            fi
        else
            err "无法访问 GitHub API，请手动在 Obsidian 设置中安装 Excalidraw 插件"
            rm -rf "$plugin_dir"
        fi
    fi

    # 启用 Excalidraw 插件（将其加入社区插件启用列表）
    local community_plugins="$vault_path/.obsidian/community-plugins.json"
    if [[ -d "$plugin_dir" ]]; then
        if [[ -f "$community_plugins" ]]; then
            if grep -q 'obsidian-excalidraw-plugin' "$community_plugins" 2>/dev/null; then
                ok "Excalidraw 插件已在启用列表中"
            else
                # 在 JSON 数组末尾追加
                sed -i '' 's/\]$/,"obsidian-excalidraw-plugin"\]/' "$community_plugins"
                ok "已将 Excalidraw 添加到启用列表"
            fi
        else
            mkdir -p "$vault_path/.obsidian"
            echo '["obsidian-excalidraw-plugin"]' > "$community_plugins"
            ok "已创建社区插件配置并启用 Excalidraw"
        fi
    fi

    echo ""
    info "Obsidian 使用提示:"
    echo "   从 Applications 启动 Obsidian"
    echo "   打开 Vault: $vault_path"
    echo "   Excalidraw: 在笔记中使用 Ctrl/Cmd+P 搜索 Excalidraw 命令"

    source_zshrc
}

# ── Maccy ────────────────────────────────────────────
install_maccy() {
    echo ""
    info "========== [9/10] Maccy =========="

    brew_install_cask maccy "Maccy"

    echo ""
    info "Maccy 使用提示:"
    echo "   默认快捷键: Cmd+Shift+C 打开剪贴板历史"
    echo "   支持文本、图片、文件等多种格式"
    echo "   可在设置中调整历史记录数量和快捷键"

    source_zshrc
}

# ── JDK (SDKMAN) ─────────────────────────────────────
install_jdk() {
    echo ""
    info "========== [10/10] JDK (SDKMAN) =========="

    # 安装 SDKMAN
    export SDKMAN_DIR="$HOME/.sdkman"
    if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        ok "SDKMAN 已安装"
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
    else
        info "正在安装 SDKMAN..."
        # macOS 自带 Bash 3.2，SDKMAN 要求 Bash 4+，需用 brew 安装的新版 Bash
        if ! command -v /opt/homebrew/bin/bash &>/dev/null && ! command -v /usr/local/bin/bash &>/dev/null; then
            info "SDKMAN 需要 Bash 4+，正在通过 Homebrew 安装新版 Bash..."
            brew install bash
        fi
        local new_bash="/opt/homebrew/bin/bash"
        [[ ! -x "$new_bash" ]] && new_bash="/usr/local/bin/bash"
        curl -fsSL "https://get.sdkman.io" | "$new_bash"
        if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
            source "$SDKMAN_DIR/bin/sdkman-init.sh"
            ok "SDKMAN 安装完成"
        else
            err "SDKMAN 安装失败，请手动安装: https://sdkman.io/install"
            return
        fi
    fi

    # 选择 JDK 版本
    echo ""
    echo -e "${BOLD}选择 JDK 版本 (Eclipse Temurin):${NC}"
    echo -e "  ${CYAN}1)${NC} JDK 21 (LTS，推荐)"
    echo -e "  ${CYAN}2)${NC} JDK 17 (LTS)"
    echo -e "  ${CYAN}3)${NC} JDK 11 (LTS)"
    echo -e "  ${CYAN}4)${NC} JDK 8  (LTS)"
    echo -e "  ${CYAN}5)${NC} 跳过 (仅安装 SDKMAN)"
    echo -en "${CYAN}请输入选项 [1-5] (默认 1): ${NC}" > /dev/tty
    local jdk_choice
    read -r jdk_choice < /dev/tty
    jdk_choice="${jdk_choice:-1}"

    local jdk_major=""
    case "$jdk_choice" in
        1) jdk_major="21" ;;
        2) jdk_major="17" ;;
        3) jdk_major="11" ;;
        4) jdk_major="8"  ;;
        5) ok "跳过 JDK 安装，仅保留 SDKMAN" ;;
        *) warn "无效选项，使用默认 JDK 21"
           jdk_major="21" ;;
    esac

    if [[ -n "$jdk_major" ]]; then
        # 检查是否已安装该版本
        if sdk list java 2>/dev/null | grep -q "${jdk_major}\.\S*-tem.*installed"; then
            ok "JDK ${jdk_major} (Temurin) 已安装"
        else
            info "正在安装 JDK ${jdk_major} (Eclipse Temurin)..."
            local jdk_version
            jdk_version=$(sdk list java 2>/dev/null | grep -oE "${jdk_major}\.[0-9.]*-tem" | head -1)
            if [[ -n "$jdk_version" ]]; then
                sdk install java "$jdk_version" < /dev/tty
                ok "JDK ${jdk_version} 安装完成"
            else
                warn "未找到精确版本号，尝试安装 ${jdk_major}-tem..."
                sdk install java "${jdk_major}-tem" < /dev/tty
                ok "JDK ${jdk_major} 安装完成"
            fi
        fi

        # 设置默认版本
        sdk default java "$(sdk current java 2>/dev/null | grep -oE "${jdk_major}\S*" || echo '')" 2>/dev/null
    fi

    echo ""
    info "JDK 使用提示:"
    echo "   java -version            查看当前 JDK 版本"
    echo "   sdk list java            查看可用 JDK 版本"
    echo "   sdk install java <ver>   安装指定版本"
    echo "   sdk use java <ver>       临时切换版本"
    echo "   sdk default java <ver>   设置默认版本"

    source_zshrc
}

# ══════════════════════════════════════════════════════
# 主流程
# ══════════════════════════════════════════════════════
main() {
    # 基础环境检查（始终最先运行）
    check_prerequisites

    # 解析参数（可能进入交互菜单选择工具）
    parse_args "$@"

    # 仅修改 Claude 提供商配置
    if is_selected "claude-provider"; then
        echo ""
        configure_claude_provider
        source_zshrc
        return
    fi

    # 安装选中的工具
    if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
        echo ""
        info "即将安装: ${SELECTED_TOOLS[*]:-}"
        echo ""

        is_selected "ghostty" && install_ghostty
        is_selected "yazi"    && install_yazi
        is_selected "lazygit" && install_lazygit
        is_selected "claude"  && install_claude
        is_selected "openclaw" && install_openclaw
        is_selected "antigravity" && install_antigravity
        is_selected "orbstack" && install_orbstack
        is_selected "obsidian" && install_obsidian
        is_selected "maccy"    && install_maccy
        is_selected "jdk"      && install_jdk
    fi

    # 跳过模式：提供配置操作菜单
    if $SKIP_PREREQUISITES && [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
        echo ""
        info "========== 配置操作 =========="
        echo ""
        echo -e "  ${GREEN}1)${NC} 修改 Claude 提供商配置"
        echo -e "  ${GREEN}0)${NC} 退出"
        echo ""
        echo -en "${CYAN}  请选择 [0-1]: ${NC}" > /dev/tty
        local config_choice
        read -r config_choice < /dev/tty

        case "$config_choice" in
            1) configure_claude_provider ;;
            *) ok "已退出" ;;
        esac
    fi

    # ── 完成 ──────────────────────────────────────────
    echo ""
    echo -e "${GREEN}${BOLD}============================================${NC}"
    echo -e "${GREEN}${BOLD}  All done! 全部完成${NC}"
    echo -e "${GREEN}${BOLD}============================================${NC}"
    echo ""

    if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
        echo "已安装: ${SELECTED_TOOLS[*]}"
        echo ""
    fi

    if is_selected "ghostty"; then
        echo "  Ghostty   ~/.config/ghostty/config"
    fi
    if is_selected "yazi"; then
        echo "  Yazi      ~/.config/yazi/"
    fi
    if is_selected "lazygit"; then
        echo "  Lazygit   ~/.config/lazygit/config.yml"
    fi
    if is_selected "claude"; then
        echo "  Claude    ~/.zshrc (>>> Claude Code Provider Config >>> 块)"
    fi
    if is_selected "obsidian"; then
        echo "  Obsidian  ~/Obsidian (含 Excalidraw 插件)"
    fi
    if is_selected "maccy"; then
        echo "  Maccy     剪贴板管理 (Cmd+Shift+C)"
    fi
    if is_selected "jdk"; then
        echo "  JDK       ~/.sdkman/ (SDKMAN 管理)"
    fi
    echo ""

    source_zshrc
}

main "$@"
