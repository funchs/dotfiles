package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/funchs/kaishi/tui/internal/view"
)

func main() {
	p := tea.NewProgram(
		view.NewSelectModel(),
		tea.WithAltScreen(),
	)

	finalModel, err := p.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Handle selection result
	if m, ok := finalModel.(view.SelectModel); ok {
		_ = m // Phase 2: pass selected tools to runner
	}
}
