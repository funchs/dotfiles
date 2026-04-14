package runner

import (
	"fmt"
	"regexp"
	"strings"
)

// LogLevel represents the severity of a log line
type LogLevel int

const (
	LevelInfo LogLevel = iota
	LevelOK
	LevelWarn
	LevelError
	LevelPlain
)

// LogLine is a parsed line from script output
type LogLine struct {
	Level LogLevel
	Text  string
}

// ToolStartEvent indicates a new tool installation has begun
type ToolStartEvent struct {
	Index int    // 0-based index
	Total int    // total tool count
	Name  string // tool name from the separator
}

var toolSepRegex = regexp.MustCompile(`=+\s*\[(\d+)/(\d+)\]\s*(.+?)\s*=+`)

// ParseLine parses a single line of script output
func ParseLine(line string) LogLine {
	trimmed := strings.TrimSpace(line)

	switch {
	case strings.HasPrefix(trimmed, "[ OK ]"):
		return LogLine{Level: LevelOK, Text: strings.TrimSpace(trimmed[6:])}
	case strings.HasPrefix(trimmed, "[INFO]"):
		return LogLine{Level: LevelInfo, Text: strings.TrimSpace(trimmed[6:])}
	case strings.HasPrefix(trimmed, "[WARN]"):
		return LogLine{Level: LevelWarn, Text: strings.TrimSpace(trimmed[6:])}
	case strings.HasPrefix(trimmed, "[ERR ]"):
		return LogLine{Level: LevelError, Text: strings.TrimSpace(trimmed[6:])}
	case strings.HasPrefix(trimmed, "[ERR]"):
		return LogLine{Level: LevelError, Text: strings.TrimSpace(trimmed[5:])}
	default:
		return LogLine{Level: LevelPlain, Text: trimmed}
	}
}

// ParseToolSeparator checks if a line is a tool separator like "========== [1/12] Ghostty =========="
// Returns (ToolStartEvent, true) if matched
func ParseToolSeparator(line string) (ToolStartEvent, bool) {
	matches := toolSepRegex.FindStringSubmatch(line)
	if matches == nil {
		return ToolStartEvent{}, false
	}
	var idx, total int
	fmt.Sscanf(matches[1], "%d", &idx)
	fmt.Sscanf(matches[2], "%d", &total)
	return ToolStartEvent{
		Index: idx - 1,
		Total: total,
		Name:  strings.TrimSpace(matches[3]),
	}, true
}
