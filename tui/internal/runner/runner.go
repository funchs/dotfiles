package runner

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// Event is sent from the runner to the TUI
type Event struct {
	Type      EventType
	Log       LogLine
	ToolStart ToolStartEvent
	Err       error
}

type EventType int

const (
	EventLog EventType = iota
	EventToolStart
	EventDone
	EventError
)

// Run executes the install script with selected tools and streams events
func Run(toolKeys []string, uninstall bool) <-chan Event {
	ch := make(chan Event, 64)

	go func() {
		defer close(ch)

		script, cleanup, err := writeScript()
		if err != nil {
			ch <- Event{Type: EventError, Err: fmt.Errorf("写入临时脚本失败: %w", err)}
			return
		}
		defer cleanup()

		args := buildArgs(script, toolKeys, uninstall)
		cmd := exec.Command(args[0], args[1:]...)
		cmd.Env = append(os.Environ(), "KAISHI_TUI=1")

		stdout, err := cmd.StdoutPipe()
		if err != nil {
			ch <- Event{Type: EventError, Err: fmt.Errorf("创建输出管道失败: %w", err)}
			return
		}
		cmd.Stderr = cmd.Stdout // merge stderr into stdout

		if err := cmd.Start(); err != nil {
			ch <- Event{Type: EventError, Err: fmt.Errorf("启动脚本失败: %w", err)}
			return
		}

		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()

			if toolEvt, ok := ParseToolSeparator(line); ok {
				ch <- Event{Type: EventToolStart, ToolStart: toolEvt}
				continue
			}

			parsed := ParseLine(line)
			if parsed.Text != "" {
				ch <- Event{Type: EventLog, Log: parsed}
			}
		}

		if err := cmd.Wait(); err != nil {
			ch <- Event{Type: EventError, Err: fmt.Errorf("脚本执行失败: %w", err)}
			return
		}

		ch <- Event{Type: EventDone}
	}()

	return ch
}

func writeScript() (path string, cleanup func(), err error) {
	if runtime.GOOS == "windows" {
		return writeWindowsScript()
	}
	return writeUnixScript()
}

func writeUnixScript() (string, func(), error) {
	// Try to use the script from the project root (dev mode)
	candidates := []string{
		"../install.sh",
		"install.sh",
	}
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c, func() {}, nil
		}
	}

	// Write embedded script to temp file
	tmp, err := os.CreateTemp("", "kaishi-install-*.sh")
	if err != nil {
		return "", nil, err
	}
	// Placeholder: Phase 3 will use go:embed
	// For now, download from GitHub
	tmp.Close()
	cleanup := func() { os.Remove(tmp.Name()) }

	downloadCmd := exec.Command("curl", "-fsSL", "-o", tmp.Name(),
		"https://raw.githubusercontent.com/funchs/kaishi/main/install.sh")
	if err := downloadCmd.Run(); err != nil {
		cleanup()
		return "", nil, fmt.Errorf("下载 install.sh 失败: %w", err)
	}

	os.Chmod(tmp.Name(), 0755)
	return tmp.Name(), cleanup, nil
}

func writeWindowsScript() (string, func(), error) {
	candidates := []string{
		"..\\install.ps1",
		"install.ps1",
	}
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c, func() {}, nil
		}
	}

	tmp, err := os.CreateTemp("", "kaishi-install-*.ps1")
	if err != nil {
		return "", nil, err
	}
	tmp.Close()
	cleanup := func() { os.Remove(tmp.Name()) }

	downloadCmd := exec.Command("curl", "-fsSL", "-o", tmp.Name(),
		"https://raw.githubusercontent.com/funchs/kaishi/main/install.ps1")
	if err := downloadCmd.Run(); err != nil {
		cleanup()
		return "", nil, fmt.Errorf("下载 install.ps1 失败: %w", err)
	}

	return tmp.Name(), cleanup, nil
}

func buildArgs(script string, toolKeys []string, uninstall bool) []string {
	if runtime.GOOS == "windows" {
		args := []string{"powershell", "-ExecutionPolicy", "Bypass", "-File", script}
		if uninstall {
			args = append(args, "--uninstall")
		} else {
			args = append(args, toolKeys...)
		}
		return args
	}

	args := []string{"bash", script}
	if uninstall {
		args = append(args, "--uninstall")
	} else {
		args = append(args, toolKeys...)
	}
	return args
}

// FormatLogLine renders a log line with ANSI color prefix
func FormatLogLine(l LogLine) string {
	switch l.Level {
	case LevelOK:
		return fmt.Sprintf("  ✅ %s", l.Text)
	case LevelInfo:
		return fmt.Sprintf("  ℹ️  %s", l.Text)
	case LevelWarn:
		return fmt.Sprintf("  ⚠️  %s", l.Text)
	case LevelError:
		return fmt.Sprintf("  ❌ %s", l.Text)
	default:
		if l.Text == "" {
			return ""
		}
		return fmt.Sprintf("     %s", l.Text)
	}
}

// Ensure strings is used
var _ = strings.TrimSpace
