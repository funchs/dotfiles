package model

// Status represents the installation state of a tool
type Status int

const (
	Pending Status = iota
	Running
	OK
	Warn
	Error
	Skipped
)

// Tool represents an installable dev tool
type Tool struct {
	Key         string
	Name        string
	Description string
	Icon        string
	Selected    bool
	Status      Status
	Supported   bool // whether this tool is supported on current OS
}

// DefaultTools returns the 12 tools with Chinese descriptions
func DefaultTools(os string) []Tool {
	tools := []Tool{
		{Key: "ghostty", Name: "Ghostty", Description: "GPU 加速终端模拟器", Icon: "🖥️", Supported: os != "windows"},
		{Key: "yazi", Name: "Yazi", Description: "终端文件管理器", Icon: "📁", Supported: true},
		{Key: "lazygit", Name: "Lazygit", Description: "终端 Git UI", Icon: "🔀", Supported: true},
		{Key: "claude", Name: "Claude Code", Description: "AI 编程助手", Icon: "🤖", Supported: true},
		{Key: "openclaw", Name: "OpenClaw", Description: "本地 AI 助手", Icon: "🐾", Supported: true},
		{Key: "hermes", Name: "Hermes Agent", Description: "自学习 AI Agent", Icon: "🧠", Supported: true},
		{Key: "antigravity", Name: "Antigravity", Description: "Google AI 平台", Icon: "🚀", Supported: os != "linux"},
		{Key: "orbstack", Name: "Docker", Description: "容器 & Kubernetes", Icon: "🐳", Supported: true},
		{Key: "obsidian", Name: "Obsidian", Description: "知识管理 & 笔记", Icon: "📝", Supported: true},
		{Key: "maccy", Name: "剪贴板管理", Description: "Maccy / Ditto / CopyQ", Icon: "📋", Supported: true},
		{Key: "jdk", Name: "JDK", Description: "Java 开发工具包", Icon: "☕", Supported: true},
		{Key: "vscode", Name: "VS Code", Description: "代码编辑器", Icon: "💻", Supported: true},
	}
	return tools
}

// SelectedKeys returns the keys of selected tools
func SelectedKeys(tools []Tool) []string {
	var keys []string
	for _, t := range tools {
		if t.Selected && t.Supported {
			keys = append(keys, t.Key)
		}
	}
	return keys
}
