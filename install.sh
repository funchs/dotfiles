#!/usr/bin/env bash
# ============================================================
# 自动安装并配置 Ghostty / Yazi / Lazygit
# 用法: chmod +x setup-tools.sh && ./setup-tools.sh
# ============================================================
set -euo pipefail

# ── 颜色输出 ──────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ── 检测 Homebrew ─────────────────────────────────────
if ! command -v brew &>/dev/null; then
    err "未检测到 Homebrew，正在安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon 路径
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi
ok "Homebrew 已就绪: $(brew --version | head -1)"

# ── 通用安装函数 ──────────────────────────────────────
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

# ── 安装主程序 ────────────────────────────────────────
echo ""
info "========== 安装主程序 =========="
brew_install_cask ghostty "Ghostty"
brew_install yazi "Yazi"
brew_install lazygit "Lazygit"

# ── 安装辅助依赖 ──────────────────────────────────────
echo ""
info "========== 安装辅助依赖 =========="

# Yazi 的预览/搜索依赖
brew_install fd "fd (快速文件查找)"
brew_install ripgrep "ripgrep (快速内容搜索)"
brew_install fzf "fzf (模糊搜索)"
brew_install zoxide "zoxide (智能目录跳转)"
brew_install poppler "poppler (PDF 预览)"
brew_install ffmpegthumbnailer "ffmpegthumbnailer (视频缩略图)"
brew_install sevenzip "7zip (压缩包预览)"
brew_install jq "jq (JSON 预览)"
brew_install imagemagick "ImageMagick (图片处理)"
brew_install font-symbols-only-nerd-font "Nerd Font Symbols"

# Lazygit 的增强 diff
brew_install git-delta "delta (语法高亮 diff)"

# ── 备份已有配置 ──────────────────────────────────────
backup_if_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        local backup="${path}.bak.$(date +%Y%m%d%H%M%S)"
        warn "备份已有配置: $path → $backup"
        cp -r "$path" "$backup"
    fi
}

# ── 配置 Ghostty ──────────────────────────────────────
echo ""
info "========== 配置 Ghostty =========="

GHOSTTY_DIR="$HOME/.config/ghostty"
GHOSTTY_CONF="$GHOSTTY_DIR/config"
mkdir -p "$GHOSTTY_DIR"

if [[ -f "$GHOSTTY_CONF" ]]; then
    ok "Ghostty 已有配置，保留现有配置不覆盖"
    info "配置路径: $GHOSTTY_CONF"
else
    cat > "$GHOSTTY_CONF" << 'GHOSTTY_EOF'
# ============================================
# Ghostty Terminal - 推荐配置
# ============================================
# 重新加载: Cmd+Shift+, (macOS)
# 查看所有选项: ghostty +show-config --default --docs
# 浏览主题: ghostty +list-themes

# --- 字体 ---
font-family = JetBrains Mono
font-size = 14
font-thicken = true
adjust-cell-height = 2

# --- 主题 ---
# 跟随系统明暗自动切换
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

# ── 配置 Yazi ─────────────────────────────────────────
echo ""
info "========== 配置 Yazi =========="

YAZI_DIR="$HOME/.config/yazi"
mkdir -p "$YAZI_DIR"

# yazi.toml - 主配置
backup_if_exists "$YAZI_DIR/yazi.toml"
cat > "$YAZI_DIR/yazi.toml" << 'YAZI_EOF'
# ============================================
# Yazi 文件管理器 - 主配置
# ============================================
# 文档: https://yazi-rs.github.io/docs/configuration/yazi

# --- 文件管理器核心 ---
[mgr]
ratio         = [1, 4, 3]     # 侧边栏 : 文件列表 : 预览 的宽度比
sort_by       = "natural"      # 自然排序 (readme2 < readme10)
sort_sensitive = false          # 排序不区分大小写
sort_reverse  = false
sort_dir_first = true           # 目录排在前面
show_hidden   = false           # 运行时按 '.' 切换
show_symlink  = true            # 显示软链接目标
linemode      = "size"          # 文件列表中显示大小

# --- 预览 ---
[preview]
wrap       = "no"
tab_size   = 2
max_width  = 1000              # 图片预览最大宽度 (px)
max_height = 1000              # 图片预览最大高度 (px)

# --- 打开方式 ---
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

# --- 文件类型关联 ---
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

# 兜底：使用系统默认应用打开
[[open.rules]]
use = "open"
YAZI_EOF
ok "yazi.toml 已写入"

# keymap.toml - 快捷键
backup_if_exists "$YAZI_DIR/keymap.toml"
cat > "$YAZI_DIR/keymap.toml" << 'YAZI_EOF'
# ============================================
# Yazi 文件管理器 - 快捷键配置
# ============================================
# 文档: https://yazi-rs.github.io/docs/configuration/keymap
# 这里只添加/覆盖默认快捷键，其余保留默认值

# --- 快速跳转目录 ---
[[mgr.prepend_keymap]]
on   = ["g", "d"]
run  = "cd ~/Downloads"
desc = "跳转到 Downloads"

[[mgr.prepend_keymap]]
on   = ["g", "D"]
run  = "cd ~/Desktop"
desc = "跳转到 Desktop"

[[mgr.prepend_keymap]]
on   = ["g", "c"]
run  = "cd ~/.config"
desc = "跳转到 .config"

[[mgr.prepend_keymap]]
on   = ["g", "p"]
run  = "cd ~/Projects"
desc = "跳转到 Projects"

[[mgr.prepend_keymap]]
on   = ["g", "h"]
run  = "cd ~"
desc = "跳转到 Home"

# --- 实用操作 ---
[[mgr.prepend_keymap]]
on   = ["T"]
run  = "shell 'open -a Ghostty \"$PWD\"' --confirm"
desc = "在 Ghostty 中打开当前目录"

[[mgr.prepend_keymap]]
on   = ["C"]
run  = "shell 'code \"$PWD\"' --confirm"
desc = "在 VS Code 中打开当前目录"

[[mgr.prepend_keymap]]
on   = ["S"]
run  = "shell '$SHELL' --block --confirm"
desc = "在当前目录打开 Shell"
YAZI_EOF
ok "keymap.toml 已写入"

# theme.toml - 主题 (使用默认 + 微调)
backup_if_exists "$YAZI_DIR/theme.toml"
cat > "$YAZI_DIR/theme.toml" << 'YAZI_EOF'
# ============================================
# Yazi 文件管理器 - 主题配置
# ============================================
# 使用默认主题，可在此覆盖特定项
# 完整参考: https://yazi-rs.github.io/docs/configuration/theme

# 如需使用 Catppuccin 主题，运行:
# ya pack -a yazi-rs/flavors:catppuccin-mocha
# 然后取消注释下面的行:
# [flavor]
# use = "catppuccin-mocha"
YAZI_EOF
ok "theme.toml 已写入"

# init.lua - 插件初始化
backup_if_exists "$YAZI_DIR/init.lua"
cat > "$YAZI_DIR/init.lua" << 'YAZI_EOF'
-- ============================================
-- Yazi 插件初始化
-- ============================================

-- 全边框 UI（需安装: ya pack -a yazi-rs/plugins:full-border）
local ok_border, full_border = pcall(require, "full-border")
if ok_border then
    full_border:setup()
end

-- Git 状态显示（需安装: ya pack -a yazi-rs/plugins:git）
local ok_git, git = pcall(require, "git")
if ok_git then
    git:setup()
end
YAZI_EOF
ok "init.lua 已写入"

# 安装推荐插件
echo ""
info "安装 Yazi 插件..."
if command -v ya &>/dev/null; then
    ya pack -a yazi-rs/plugins:full-border 2>/dev/null && ok "已安装 full-border 插件" || warn "full-border 插件可能已安装"
    ya pack -a yazi-rs/plugins:git 2>/dev/null && ok "已安装 git 插件" || warn "git 插件可能已安装"
    ya pack -a yazi-rs/plugins:chmod 2>/dev/null && ok "已安装 chmod 插件" || warn "chmod 插件可能已安装"
else
    warn "ya 命令不可用，请手动安装插件"
fi

# ── 配置 Lazygit ──────────────────────────────────────
echo ""
info "========== 配置 Lazygit =========="

LAZYGIT_DIR="$HOME/.config/lazygit"
LAZYGIT_CONF="$LAZYGIT_DIR/config.yml"
mkdir -p "$LAZYGIT_DIR"

backup_if_exists "$LAZYGIT_CONF"
cat > "$LAZYGIT_CONF" << 'LAZYGIT_EOF'
# ============================================
# Lazygit - 推荐配置
# ============================================
# 文档: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md

# --- 界面 ---
gui:
  # Nerd Font 图标版本 (v3+)
  nerdFontsVersion: "3"
  # 显示文件图标
  showFileIcons: true
  # 圆角边框
  border: rounded
  # 显示命令日志（学习 Git 命令很有用）
  showCommandLog: true
  # 主题高亮
  theme:
    selectedLineBgColor:
      - reverse
    selectedRangeBgColor:
      - reverse
  # 显示随机提示
  showRandomTip: true
  # 文件树显示模式（tree 更直观）
  showFileTree: true
  # 显示分支对应的远端分支名
  showDivergenceFromBaseBranch: arrowAndNumber

# --- Git ---
git:
  # 使用 delta 语法高亮 diff
  paging:
    colorArg: always
    pager: delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"
  # 自动拉取远端状态
  autoFetch: true
  autoRefresh: true
  # 解析 commit message 中的 emoji
  parseEmoji: true
  # commit 时显示差异
  showWholeGitGraph: false

# --- OS 集成 ---
os:
  # 编辑器 (修改为你偏好的编辑器)
  editPreset: vim

# --- 行为 ---
# 子进程结束后不需要按回车
promptToReturnFromSubprocess: false
# 在顶层按 q/Esc 退出
quitOnTopLevelReturn: true
# 禁用启动弹窗
disableStartupPopups: true

# --- 快捷键 ---
keybinding:
  universal:
    quit: q
    return: <esc>
    togglePanel: <tab>
    prevPage: "["
    nextPage: "]"

# --- 自定义命令 ---
customCommands:
  # 在浏览器中打开仓库 (需要安装 gh CLI)
  - key: "O"
    context: global
    command: "gh browse"
    description: "在浏览器中打开仓库"

  # 创建 fixup commit
  - key: "F"
    context: commits
    command: "git commit --fixup={{.SelectedLocalCommit.Hash}}"
    description: "创建 fixup commit"
    loadingText: "创建 fixup commit..."

  # 复制当前分支名到剪贴板
  - key: "Y"
    context: localBranches
    command: "echo -n {{.SelectedLocalBranch.Name}} | pbcopy"
    description: "复制分支名到剪贴板"
LAZYGIT_EOF
ok "Lazygit 配置已写入"

# ── 配置 Shell 集成 (Yazi 的 y 快捷命令) ─────────────
echo ""
info "========== 配置 Shell 集成 =========="

ZSHRC="$HOME/.zshrc"

# Yazi wrapper: 退出 Yazi 后自动 cd 到最后浏览的目录
YAZI_WRAPPER='# Yazi: 退出后自动 cd 到最后浏览的目录
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}'

if [[ -f "$ZSHRC" ]]; then
    if grep -q "function y()" "$ZSHRC" 2>/dev/null; then
        ok "Yazi shell wrapper (y 命令) 已存在于 .zshrc"
    else
        echo "" >> "$ZSHRC"
        echo "$YAZI_WRAPPER" >> "$ZSHRC"
        ok "已添加 Yazi shell wrapper (y 命令) 到 .zshrc"
    fi
else
    echo "$YAZI_WRAPPER" > "$ZSHRC"
    ok "已创建 .zshrc 并添加 Yazi shell wrapper"
fi

# ── 配置 delta (git diff 增强) ───────────────────────
echo ""
info "========== 配置 Git Delta =========="

GITCONFIG_DELTA='[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    dark = true
    line-numbers = true
    side-by-side = false
    hyperlinks = true

[merge]
    conflictstyle = zdiff3'

if git config --global core.pager | grep -q delta 2>/dev/null; then
    ok "Git Delta 已配置"
else
    # 逐项配置，避免覆盖 .gitconfig 中的其他设置
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.dark true
    git config --global delta.line-numbers true
    git config --global delta.side-by-side false
    git config --global delta.hyperlinks true
    git config --global merge.conflictstyle "zdiff3"
    ok "Git Delta 全局配置已写入"
fi

# ── 完成 ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ 全部安装和配置完成！${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "📁 配置文件位置:"
echo "   Ghostty  → ~/.config/ghostty/config"
echo "   Yazi     → ~/.config/yazi/"
echo "   Lazygit  → ~/.config/lazygit/config.yml"
echo ""
echo "🚀 快速使用:"
echo "   ghostty             打开 Ghostty 终端"
echo "   y                   打开 Yazi 文件管理器 (退出后 cd 到浏览目录)"
echo "   lazygit / lg        打开 Lazygit (在 git 仓库中)"
echo "   Ctrl+\`              Ghostty 快捷终端 (Quake 风格)"
echo ""
echo "🔑 Yazi 常用快捷键:"
echo "   .       显示/隐藏隐藏文件"
echo "   /       搜索文件"
echo "   gd      跳转到 Downloads"
echo "   gh      跳转到 Home"
echo "   T       在 Ghostty 中打开当前目录"
echo "   C       在 VS Code 中打开当前目录"
echo "   S       在当前目录打开 Shell"
echo ""
echo "💡 提示:"
echo "   - 重新加载 Shell: source ~/.zshrc"
echo "   - Ghostty 重载配置: Cmd+Shift+,"
echo "   - Yazi 安装 Catppuccin 主题: ya pack -a yazi-rs/flavors:catppuccin-mocha"
echo ""
