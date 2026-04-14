package model

// Mode represents the operation mode
type Mode int

const (
	ModeInstall Mode = iota
	ModeUninstall
)

func (m Mode) String() string {
	if m == ModeUninstall {
		return "卸载模式"
	}
	return "安装模式"
}
