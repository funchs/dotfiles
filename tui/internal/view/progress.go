package view

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/progress"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/funchs/kaishi/tui/internal/i18n"
	"github.com/funchs/kaishi/tui/internal/model"
	"github.com/funchs/kaishi/tui/internal/runner"
	"github.com/funchs/kaishi/tui/internal/theme"
)

// ProgressModel shows installation progress
type ProgressModel struct {
	tools       []model.Tool
	mode        model.Mode
	events      <-chan runner.Event
	logs        []runner.LogLine
	currentTool int
	totalTools  int
	progress    progress.Model
	spinner     spinner.Model
	done        bool
	err         error
	width       int
	height      int
}

// ProgressDoneMsg is sent when all installations complete
type ProgressDoneMsg struct {
	Tools []model.Tool
	Err   error
}

// eventMsg wraps a runner event for Bubble Tea
type eventMsg runner.Event

func NewProgressModel(tools []model.Tool, mode model.Mode) ProgressModel {
	selected := model.SelectedKeys(tools)

	// Start the runner
	uninstall := mode == model.ModeUninstall
	ch := runner.Run(selected, uninstall)

	p := progress.New(
		progress.WithDefaultGradient(),
		progress.WithoutPercentage(),
	)

	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(theme.Mauve)

	return ProgressModel{
		tools:      tools,
		mode:       mode,
		events:     ch,
		totalTools: len(selected),
		progress:   p,
		spinner:    s,
		width:      80,
		height:     24,
	}
}

func (m ProgressModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		waitForEvent(m.events),
	)
}

func waitForEvent(ch <-chan runner.Event) tea.Cmd {
	return func() tea.Msg {
		evt, ok := <-ch
		if !ok {
			return eventMsg(runner.Event{Type: runner.EventDone})
		}
		return eventMsg(evt)
	}
}

func (m ProgressModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.progress.Width = msg.Width - 10
		if m.progress.Width > 60 {
			m.progress.Width = 60
		}
		return m, nil

	case tea.KeyMsg:
		if msg.String() == "q" || msg.String() == "ctrl+c" {
			return m, tea.Quit
		}

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case progress.FrameMsg:
		progressModel, cmd := m.progress.Update(msg)
		m.progress = progressModel.(progress.Model)
		return m, cmd

	case eventMsg:
		evt := runner.Event(msg)
		switch evt.Type {
		case runner.EventLog:
			m.logs = append(m.logs, evt.Log)
			// Keep last N lines to avoid memory issues
			if len(m.logs) > 200 {
				m.logs = m.logs[len(m.logs)-200:]
			}
			return m, waitForEvent(m.events)

		case runner.EventToolStart:
			m.currentTool = evt.ToolStart.Index + 1
			return m, tea.Batch(
				waitForEvent(m.events),
				m.progress.SetPercent(float64(m.currentTool-1)/float64(m.totalTools)),
			)

		case runner.EventDone:
			m.done = true
			return m, tea.Batch(
				m.progress.SetPercent(1.0),
				func() tea.Msg {
					return ProgressDoneMsg{Tools: m.tools, Err: nil}
				},
			)

		case runner.EventError:
			m.err = evt.Err
			m.done = true
			return m, func() tea.Msg {
				return ProgressDoneMsg{Tools: m.tools, Err: evt.Err}
			}
		}
	}

	return m, nil
}

func (m ProgressModel) View() string {
	var b strings.Builder

	// Title
	modeText := i18n.Installing
	if m.mode == model.ModeUninstall {
		modeText = i18n.Uninstalling
	}

	title := theme.Title.Width(m.width - 4).Render(i18n.AppTitle)
	b.WriteString("\n")
	b.WriteString(title)
	b.WriteString("\n\n")

	// Progress bar
	if m.done {
		if m.err != nil {
			b.WriteString(fmt.Sprintf("  %s %s\n\n",
				theme.StatusErr.Render("❌"),
				theme.StatusErr.Render(fmt.Sprintf("执行失败: %v", m.err)),
			))
		} else {
			b.WriteString(fmt.Sprintf("  %s %s\n\n",
				theme.StatusOK.Render("✅"),
				theme.StatusOK.Render(i18n.AllDone),
			))
		}
		b.WriteString(fmt.Sprintf("  %s\n", m.progress.View()))
	} else {
		b.WriteString(fmt.Sprintf("  %s %s %d/%d\n\n",
			m.spinner.View(),
			lipgloss.NewStyle().Foreground(theme.Mauve).Render(modeText),
			m.currentTool, m.totalTools,
		))
		b.WriteString(fmt.Sprintf("  %s\n", m.progress.View()))
	}

	b.WriteString("\n")

	// Log viewport - show last N lines that fit
	maxLogLines := m.height - 12
	if maxLogLines < 5 {
		maxLogLines = 5
	}

	logBox := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(theme.Surface1).
		Width(m.width - 6).
		Height(maxLogLines).
		Padding(0, 1)

	startIdx := 0
	if len(m.logs) > maxLogLines {
		startIdx = len(m.logs) - maxLogLines
	}

	var logLines []string
	for i := startIdx; i < len(m.logs); i++ {
		line := renderLogLine(m.logs[i])
		if line != "" {
			logLines = append(logLines, line)
		}
	}
	// Pad with empty lines if needed
	for len(logLines) < maxLogLines {
		logLines = append(logLines, "")
	}

	b.WriteString("  ")
	b.WriteString(logBox.Render(strings.Join(logLines, "\n")))
	b.WriteString("\n")

	// Help
	if m.done {
		b.WriteString(fmt.Sprintf("\n  %s\n",
			theme.HelpKey.Render("q")+theme.HelpDesc.Render(" 退出"),
		))
	}

	return b.String()
}

func renderLogLine(l runner.LogLine) string {
	switch l.Level {
	case runner.LevelOK:
		return theme.StatusOK.Render("  ✓ " + l.Text)
	case runner.LevelInfo:
		return theme.StatusInfo.Render("  ℹ " + l.Text)
	case runner.LevelWarn:
		return theme.StatusWarn.Render("  ⚠ " + l.Text)
	case runner.LevelError:
		return theme.StatusErr.Render("  ✗ " + l.Text)
	default:
		if l.Text == "" {
			return ""
		}
		return lipgloss.NewStyle().Foreground(theme.Subtext0).Render("    " + l.Text)
	}
}
