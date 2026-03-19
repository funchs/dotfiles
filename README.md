# dotfiles

macOS 开发工具一键安装与配置脚本。

## 支持的工具

| 工具 | 说明 |
|------|------|
| [Ghostty](https://ghostty.org) | GPU 加速终端模拟器（毛玻璃 / 分屏 / Quake 下拉） |
| [Yazi](https://yazi-rs.github.io) | 终端文件管理器（快速预览 / Vim 风格导航） |
| [Lazygit](https://github.com/jesseduffield/lazygit) | 终端 Git UI（可视化提交 / 分支 / 合并） |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Anthropic AI 编程助手（终端内 AI 编程） |
| [OpenClaw](https://openclaw.com) | 本地 AI 助手（自托管 / 任务自动化） |

## 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/funchs/dotfiles/main/install.sh)
```

国内加速：

```bash
bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/funchs/dotfiles/main/install.sh)
```

## 用法

```bash
# 交互式选择（方向键导航 + 空格选择）
./install.sh

# 安装全部工具
./install.sh --all

# 只安装指定工具
./install.sh ghostty yazi
./install.sh claude openclaw

# 跳过工具安装，仅修改配置
./install.sh --skip

# 仅切换 Claude API 提供商
./install.sh claude-provider
```

## 交互式菜单

运行 `./install.sh` 后会显示交互式多选菜单：

```
╔══════════════════════════════════════════════╗
║     macOS 开发工具一键安装与配置             ║
╚══════════════════════════════════════════════╝

操作: ↑↓ 移动  空格 选择/取消  a 全选  回车 确认  s 跳过  q 退出

  > [*] Ghostty      GPU 加速终端模拟器 (毛玻璃/分屏/Quake 下拉)
    [*] Yazi         终端文件管理器 (快速预览/Vim 风格导航)
    [ ] Lazygit      终端 Git UI (可视化提交/分支/合并)
    [ ] Claude Code  Anthropic AI 编程助手 (终端内 AI 编程)
    [ ] OpenClaw     本地 AI 助手 (自托管/任务自动化)
```

## 环境基础检查

脚本会自动检测并安装以下基础依赖（无需手动选择）：

- Xcode Command Line Tools
- Zsh（设为默认 Shell）
- Homebrew
- Git
- Oh My Zsh（含 autosuggestions / syntax-highlighting 插件）
- NVM + Node.js LTS

> 使用 `--skip` 可跳过基础检查，直接进入配置菜单。

## Claude 提供商配置

安装 Claude Code 时或使用 `./install.sh claude-provider` 可配置 API 提供商：

| 选项 | 提供商 | 所需配置 |
|------|--------|----------|
| 1 | Anthropic 直连 | `ANTHROPIC_API_KEY` |
| 2 | Amazon Bedrock | AWS 凭证 (AK/SK) 或 AWS Profile |
| 3 | Google Vertex AI | GCP 项目 ID + Region |
| 4 | 自定义 API 代理 | Base URL + API Key |
| 5 | 清除配置 | 移除已有提供商设置 |

配置写入 `~/.zshrc` 的标记块中，重复运行自动替换，不会累加。

## 配置文件位置

```
~/.config/ghostty/config       # Ghostty 终端配置
~/.config/yazi/                 # Yazi 文件管理器配置
  ├── yazi.toml                 #   主配置
  ├── keymap.toml               #   快捷键
  ├── theme.toml                #   主题
  └── init.lua                  #   插件初始化
~/.config/lazygit/config.yml   # Lazygit 配置
~/.zshrc                        # Shell 集成 + Claude 提供商
```

## 常用快捷键

### Ghostty

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+`` ` | 全局唤出快捷终端 |
| `Cmd+D` | 右侧分屏 |
| `Cmd+Shift+D` | 下方分屏 |
| `Cmd+Shift+,` | 重载配置 |

### Yazi

| 快捷键 | 功能 |
|--------|------|
| `y` | 启动 Yazi（退出后 cd 到浏览目录） |
| `.` | 显示/隐藏隐藏文件 |
| `gd` / `gD` / `gh` | 跳转到 Downloads / Desktop / Home |
| `T` | 在 Ghostty 中打开当前目录 |
| `C` | 在 VS Code 中打开当前目录 |
| `S` | 在当前目录打开 Shell |

### Lazygit

| 快捷键 | 功能 |
|--------|------|
| `O` | 在浏览器中打开仓库 |
| `F` | 创建 fixup commit |
| `Y` | 复制分支名到剪贴板 |

## License

MIT
