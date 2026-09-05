extends RefCounted

const INK := Color("#0a1020")
const PANEL := Color("#141e33")
const TEXT := Color("#ecf4ff")
const MUTED := Color("#9baac4")
const ACCENT := Color("#74efcf")
const LILAC := Color("#b4a0ff")

static func box(color: Color, border: Color = Color("#293653"), radius: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 24
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", MUTED.darkened(0.25))
	theme.set_font("font", "Button", load("res://assets/fonts/DynaPuff-Medium.ttf"))
	theme.set_font_size("font_size", "Button", 23)
	theme.set_stylebox("normal", "Button", box(PANEL))
	theme.set_stylebox("hover", "Button", box(PANEL.lightened(0.12), ACCENT.darkened(0.4)))
	theme.set_stylebox("pressed", "Button", box(PANEL.lightened(0.04), ACCENT))
	theme.set_stylebox("disabled", "Button", box(INK.lightened(0.025)))
	theme.set_stylebox("focus", "Button", box(Color(0,0,0,0), ACCENT, 20))
	theme.set_color("font_color", "CheckButton", TEXT)
	theme.set_constant("separation", "VBoxContainer", 16)
	theme.set_constant("separation", "HBoxContainer", 14)
	return theme
