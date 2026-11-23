extends RefCounted
## 轻量 UI 小工具：统一字幕/按钮/面板的样式，避免每个界面重复造轮子。

static func c(hex: String, a := 1.0) -> Color:
	var col := Color(hex)
	col.a = a
	return col

static func label(txt: String, size: int, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func button(txt: String, size := 18) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(0, 42)
	b.focus_mode = Control.FOCUS_NONE
	return b

static func panel(col: Color, border := Color(1, 1, 1, 0.14), radius := 12) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	p.add_theme_stylebox_override("panel", sb)
	return p

static func full(n: Control) -> void:
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.offset_left = 0
	n.offset_top = 0
	n.offset_right = 0
	n.offset_bottom = 0

static func dimmer() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, 0.66)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r

static func vgrad(top: Color, bottom: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 4
	t.height = 256
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
