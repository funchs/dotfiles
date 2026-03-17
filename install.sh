#!/usr/bin/env bash
# ============================================================
# macOS 开发工具一键安装与配置
# 支持: Ghostty / Yazi / Lazygit / Claude Code / OpenClaw
# 用法:
#   全部安装:  ./install.sh
#   选择安装:  ./install.sh ghostty yazi lazygit claude openclaw
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

    # ── 0. Xcode Command Line Tools ──────────────────
    if xcode-select -p &>/dev/null; then
        ok "Xcode Command Line Tools 已安装"
    else
        info "正在安装 Xcode Command Line Tools (Homebrew 编译依赖)..."
        xcode-select --install 2>/dev/null
        # xcode-select --install 会弹出 GUI 对话框，等待用户点击安装完成
        info "请在弹出的对话框中点击「安装」，等待完成后按回车继续..."
        read -r < /dev/tty
        # 验证是否安装成功
        if xcode-select -p &>/dev/null; then
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
    info "========== [1/5] Ghostty =========="
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

    # 自动加载最新 .zshrc 配置
    if [[ -f "$HOME/.zshrc" ]]; then
        info "正在加载 .zshrc ..."
        source "$HOME/.zshrc" 2>/dev/null || true
        ok ".zshrc 已加载，y 命令等配置已生效"
    fi
}

main "$@"
