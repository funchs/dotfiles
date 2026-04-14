package model

// Page represents the current app page
type Page int

const (
	PageSelect Page = iota
	PageProgress
	PageResult
)
