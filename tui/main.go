package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/funchs/kaishi/tui/internal/model"
	"github.com/funchs/kaishi/tui/internal/view"
)

// appModel manages page transitions: Select -> Progress -> Result
type appModel struct {
	page    model.Page
	select_ tea.Model
	prog    tea.Model
	result  tea.Model
}

func newAppModel() appModel {
	return appModel{
		page:    model.PageSelect,
		select_: view.NewSelectModel(),
	}
}

func (m appModel) Init() tea.Cmd {
	return m.select_.Init()
}

func (m appModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch m.page {
	case model.PageSelect:
		// Check for page transition
		if done, ok := msg.(view.SelectDoneMsg); ok {
			prog := view.NewProgressModel(done.Tools, done.Mode)
			m.page = model.PageProgress
			m.prog = prog
			return m, prog.Init()
		}
		var cmd tea.Cmd
		m.select_, cmd = m.select_.Update(msg)
		return m, cmd

	case model.PageProgress:
		// Check for completion
		if done, ok := msg.(view.ProgressDoneMsg); ok {
			result := view.NewResultModel(done.Tools, model.ModeInstall, done.Err)
			m.page = model.PageResult
			m.result = result
			return m, result.Init()
		}
		var cmd tea.Cmd
		m.prog, cmd = m.prog.Update(msg)
		return m, cmd

	case model.PageResult:
		var cmd tea.Cmd
		m.result, cmd = m.result.Update(msg)
		return m, cmd
	}

	return m, nil
}

func (m appModel) View() string {
	switch m.page {
	case model.PageSelect:
		return m.select_.View()
	case model.PageProgress:
		return m.prog.View()
	case model.PageResult:
		return m.result.View()
	}
	return ""
}

func main() {
	p := tea.NewProgram(
		newAppModel(),
		tea.WithAltScreen(),
	)

	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
