package view

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/funchs/kaishi/tui/internal/i18n"
	"github.com/funchs/kaishi/tui/internal/model"
	"github.com/funchs/kaishi/tui/internal/theme"
)

// ResultModel shows the final result
type ResultModel struct {
	tools  []model.Tool
	mode   model.Mode
	err    error
	width  int
	height int
}

func NewResultModel(tools []model.Tool, mode model.Mode, err error) ResultModel {
	return ResultModel{
		tools:  tools,
		mode:   mode,
		err:    err,
		width:  80,
		height: 24,
	}
}

func (m ResultModel) Init() tea.Cmd { return nil }

func (m ResultModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	case tea.KeyMsg:
		if msg.String() == "q" || msg.String() == "ctrl+c" || msg.String() == "enter" {
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m ResultModel) View() string {
	var b strings.Builder

	b.WriteString("\n")

	if m.err != nil {
		// Error state
		errBox := lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(theme.Red).
			Width(m.width - 6).
			Padding(1, 2).
			Align(lipgloss.Center)

		b.WriteString("  ")
		b.WriteString(errBox.Render(
			theme.StatusErr.Render("❌ 执行失败\n\n") +
				lipgloss.NewStyle().Foreground(theme.Text).Render(m.err.Error()),
		))
		b.WriteString("\n")
	} else {
		// Success state
		successBox := lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(theme.Green).
			Width(m.width - 6).
			Padding(1, 2).
			Align(lipgloss.Center)

		action := "安装"
		if m.mode == model.ModeUninstall {
			action = "卸载"
		}

		b.WriteString("  ")
		b.WriteString(successBox.Render(
			theme.StatusOK.Bold(true).Render(fmt.Sprintf("✅ %s完成!", action)),
		))
		b.WriteString("\n\n")

		// Tool list
		var selected []model.Tool
		for _, t := range m.tools {
			if t.Selected && t.Supported {
				selected = append(selected, t)
			}
		}

		if len(selected) > 0 {
			b.WriteString(lipgloss.NewStyle().
				Foreground(theme.Subtext0).
				Render(fmt.Sprintf("  已%s %d 个工具:\n\n", action, len(selected))))

			for _, t := range selected {
				b.WriteString(fmt.Sprintf("  %s %s  %s\n",
					theme.StatusOK.Render("✓"),
					lipgloss.NewStyle().Foreground(theme.Text).Bold(true).Render(t.Name),
					lipgloss.NewStyle().Foreground(theme.Overlay0).Render(t.Description),
				))
			}
		}
	}

	b.WriteString(fmt.Sprintf("\n  %s %s\n",
		theme.HelpKey.Render("q"),
		theme.HelpDesc.Render("退出"),
	))

	return b.String()
}

// Ensure i18n is used
var _ = i18n.AppTitle
