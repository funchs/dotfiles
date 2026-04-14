package view

import (
	"fmt"
	"runtime"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/funchs/kaishi/tui/internal/i18n"
	"github.com/funchs/kaishi/tui/internal/model"
	"github.com/funchs/kaishi/tui/internal/theme"
)

// SelectModel is the tool selection page
type SelectModel struct {
	tools    []model.Tool
	cursor   int
	mode     model.Mode
	width    int
	height   int
	cols     int
	quitting bool
	done     bool
}

// SelectDoneMsg is sent when user confirms selection
type SelectDoneMsg struct {
	Tools []model.Tool
	Mode  model.Mode
}

func NewSelectModel() SelectModel {
	osName := runtime.GOOS
	return SelectModel{
		tools:  model.DefaultTools(osName),
		cursor: 0,
		mode:   model.ModeInstall,
		cols:   2,
		width:  80,
		height: 24,
	}
}

func (m SelectModel) Init() tea.Cmd {
	return nil
}

func (m SelectModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		if m.width < 65 {
			m.cols = 1
		} else {
			m.cols = 2
		}
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			m.quitting = true
			return m, tea.Quit

		case "up", "k":
			if m.cursor >= m.cols {
				m.cursor -= m.cols
			}
		case "down", "j":
			if m.cursor+m.cols < len(m.tools) {
				m.cursor += m.cols
			}
		case "left", "h":
			if m.cursor > 0 {
				m.cursor--
			}
		case "right", "l":
			if m.cursor < len(m.tools)-1 {
				m.cursor++
			}

		case " ":
			if m.tools[m.cursor].Supported {
				m.tools[m.cursor].Selected = !m.tools[m.cursor].Selected
			}

		case "a":
			allSelected := true
			for _, t := range m.tools {
				if t.Supported && !t.Selected {
					allSelected = false
					break
				}
			}
			for i := range m.tools {
				if m.tools[i].Supported {
					m.tools[i].Selected = !allSelected
				}
			}

		case "tab":
			if m.mode == model.ModeInstall {
				m.mode = model.ModeUninstall
			} else {
				m.mode = model.ModeInstall
			}

		case "enter":
			selected := model.SelectedKeys(m.tools)
			if len(selected) > 0 {
				m.done = true
				return m, func() tea.Msg {
					return SelectDoneMsg{Tools: m.tools, Mode: m.mode}
				}
			}
		}
	}
	return m, nil
}

func (m SelectModel) View() string {
	if m.quitting {
		return ""
	}

	var b strings.Builder

	// Title
	osLabel := "macOS"
	switch runtime.GOOS {
	case "linux":
		osLabel = "Linux"
	case "windows":
		osLabel = "Windows"
	}
	modeLabel := i18n.InstallMode
	modeColor := theme.Green
	if m.mode == model.ModeUninstall {
		modeLabel = i18n.UninstallMode
		modeColor = theme.Red
	}

	titleBox := lipgloss.NewStyle().
		Width(m.cardWidth()*m.cols + (m.cols-1)*2).
		Align(lipgloss.Center).
		Bold(true).
		Foreground(theme.Mauve).
		Render(i18n.AppTitle)

	subtitleBox := lipgloss.NewStyle().
		Width(m.cardWidth()*m.cols + (m.cols-1)*2).
		Align(lipgloss.Center).
		Foreground(modeColor).
		Render(osLabel + " · " + modeLabel)

	b.WriteString("\n")
	b.WriteString(titleBox)
	b.WriteString("\n")
	b.WriteString(subtitleBox)
	b.WriteString("\n\n")

	// Tool grid
	for i := 0; i < len(m.tools); i += m.cols {
		var row []string
		for j := 0; j < m.cols && i+j < len(m.tools); j++ {
			idx := i + j
			row = append(row, m.renderCard(idx))
		}
		b.WriteString(lipgloss.JoinHorizontal(lipgloss.Top, row...))
		b.WriteString("\n")
	}

	// Help
	b.WriteString("\n")
	help := fmt.Sprintf(
		"  %s  %s  %s  %s  %s  %s",
		theme.HelpKey.Render("↑↓←→")+theme.HelpDesc.Render(" 移动"),
		theme.HelpKey.Render("空格")+theme.HelpDesc.Render(" 选择"),
		theme.HelpKey.Render("a")+theme.HelpDesc.Render(" 全选"),
		theme.HelpKey.Render("Tab")+theme.HelpDesc.Render(" 安装/卸载"),
		theme.HelpKey.Render("Enter")+theme.HelpDesc.Render(" 确认"),
		theme.HelpKey.Render("q")+theme.HelpDesc.Render(" 退出"),
	)
	b.WriteString(help)
	b.WriteString("\n")

	// Selected count
	count := len(model.SelectedKeys(m.tools))
	if count > 0 {
		b.WriteString(fmt.Sprintf("\n  %s",
			lipgloss.NewStyle().Foreground(theme.Green).
				Render(fmt.Sprintf("已选 %d 个工具", count))))
	}
	b.WriteString("\n")

	return b.String()
}

func (m SelectModel) cardWidth() int {
	w := (m.width - 4) / m.cols
	if w > 32 {
		w = 32
	}
	if w < 24 {
		w = 24
	}
	return w
}

func (m SelectModel) renderCard(idx int) string {
	t := m.tools[idx]
	isCursor := idx == m.cursor

	// Pick style
	style := theme.Card.Width(m.cardWidth())
	switch {
	case isCursor && t.Selected:
		style = theme.CardCursorSelected.Width(m.cardWidth())
	case isCursor:
		style = theme.CardCursor.Width(m.cardWidth())
	case t.Selected:
		style = theme.CardSelected.Width(m.cardWidth())
	}

	// Check mark
	check := "  "
	if t.Selected {
		check = lipgloss.NewStyle().Foreground(theme.Green).Render("✓ ")
	}

	// Name + description
	name := t.Name
	if !t.Supported {
		name = lipgloss.NewStyle().Foreground(theme.Overlay0).Strikethrough(true).Render(t.Name)
		check = lipgloss.NewStyle().Foreground(theme.Overlay0).Render("✗ ")
	}

	desc := lipgloss.NewStyle().Foreground(theme.Subtext0).Render(t.Description)

	content := fmt.Sprintf("%s%s\n%s", check, name, desc)

	return style.Render(content)
}
