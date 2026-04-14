package theme

import "github.com/charmbracelet/lipgloss"

// Catppuccin Mocha palette
var (
	Base     = lipgloss.Color("#1e1e2e")
	Mantle   = lipgloss.Color("#181825")
	Crust    = lipgloss.Color("#11111b")
	Surface0 = lipgloss.Color("#313244")
	Surface1 = lipgloss.Color("#45475a")
	Overlay0 = lipgloss.Color("#6c7086")
	Subtext0 = lipgloss.Color("#a6adc8")
	Text     = lipgloss.Color("#cdd6f4")

	Red    = lipgloss.Color("#f38ba8")
	Peach  = lipgloss.Color("#fab387")
	Yellow = lipgloss.Color("#f9e2af")
	Green  = lipgloss.Color("#a6e3a1")
	Teal   = lipgloss.Color("#94e2d5")
	Blue   = lipgloss.Color("#89b4fa")
	Mauve  = lipgloss.Color("#cba6f7")
	Sky    = lipgloss.Color("#89dcfe")
)

// Reusable styles
var (
	Title = lipgloss.NewStyle().
		Bold(true).
		Foreground(Mauve).
		Align(lipgloss.Center)

	Subtitle = lipgloss.NewStyle().
			Foreground(Subtext0).
			Align(lipgloss.Center)

	Card = lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(Surface1).
		Padding(0, 1).
		Width(28)

	CardSelected = Card.
			BorderForeground(Blue)

	CardCursor = Card.
			BorderForeground(Mauve)

	CardCursorSelected = Card.
				BorderForeground(Blue).
				Bold(true)

	HelpKey = lipgloss.NewStyle().
		Foreground(Blue).
		Bold(true)

	HelpDesc = lipgloss.NewStyle().
			Foreground(Overlay0)

	StatusOK   = lipgloss.NewStyle().Foreground(Green)
	StatusWarn = lipgloss.NewStyle().Foreground(Yellow)
	StatusErr  = lipgloss.NewStyle().Foreground(Red)
	StatusInfo = lipgloss.NewStyle().Foreground(Blue)
	StatusRun  = lipgloss.NewStyle().Foreground(Mauve)

	ProgressBar = lipgloss.NewStyle().Foreground(Blue)
)
