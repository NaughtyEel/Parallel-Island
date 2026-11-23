extends Control

const Kit = preload("res://ui/kit.gd")
## 游戏主界面：背景/角色/道具舞台 + 字幕 + 选择 + 存读档 + 日志 + 分支树入口。

const StoryEngine = preload("res://story/story_engine.gd")

var pending_snapshot: Dictionary = {}

var engine: StoryEngine
var _bg_tex: TextureRect
var _dimmer: ColorRect
var _chars_layer: Control
var _props_layer: Control
var _dlg: PanelContainer
var _name_label: Label
var _text: RichTextLabel
var _hint: Label
var _choice_panel: PanelContainer
var _choice_box: VBoxContainer
var _choice_prompt: Label
var _status: Label
var _toast: Label
var _menu: HBoxContainer
var _overlay: Control

var _typing := false
var _type_acc := 0.0
var _line_active := false
var _auto := false
var _skip := false
var _auto_acc := 0.0
var _ending_open := false
var _dev_panel: Control = null

func _ready() -> void:
	Kit.full(self)
	_build()
	engine = StoryEngine.new()
	add_child(engine)
	engine.line_ready.connect(_on_line)
	engine.choice_ready.connect(_on_choice)
	engine.stage_applied.connect(_on_stage)
	engine.ending_reached.connect(_on_ending)
	engine.branch_reached.connect(_on_branch)
	engine.story_done.connect(_on_engine_done)
	Events.event_started.connect(_on_event_started)
	if not pending_snapshot.is_empty():
		Game.restore(pending_snapshot)
		if Game.event_id != "":
			engine.start("ev:" + Game.event_id, Game.node_index)
		else:
			engine.start(Game.story_id, Game.node_index)
	else:
		Game.reset()
		if Events.start_flow("prologue"):
			engine.start("ev:" + Events.current_id, 0)
		else:
			push_error("无法开始事件流")

# ── 构建界面 ──────────────────────────────────────────────

func _build() -> void:
	_bg_tex = TextureRect.new()
	_bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_tex)
	Kit.full(_bg_tex)

	_dimmer = ColorRect.new()
	_dimmer.color = Color(0, 0, 0, 0.0)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dimmer)
	Kit.full(_dimmer)

	_chars_layer = Control.new()
	_chars_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chars_layer)
	Kit.full(_chars_layer)

	_props_layer = Control.new()
	_props_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_props_layer)
	Kit.full(_props_layer)

	# 对话框
	_dlg = Kit.panel(Kit.c("#0d1119", 0.92), Kit.c("#39465e"))
	_dlg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dlg.offset_left = 40
	_dlg.offset_right = -40
	_dlg.offset_top = -236
	_dlg.offset_bottom = -24
	add_child(_dlg)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_dlg.add_child(vb)

	_name_label = Kit.label("", 24, Kit.c("#f0d9a0"))
	vb.add_child(_name_label)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.fit_content = false
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(0, 132)
	_text.add_theme_font_size_override("normal_font_size", Settings.font_size)
	_text.add_theme_color_override("default_color", Kit.c("#e8eef8"))
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_text)

	_hint = Kit.label("空格 / 点击 继续 ｜ Ctrl 快进 ｜ Esc 菜单 ｜ F1 调试面板", 12, Kit.c("#5c6b84"))
	vb.add_child(_hint)

	# 顶栏
	_menu = HBoxContainer.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_menu.offset_left = -660
	_menu.offset_top = 12
	_menu.offset_right = -16
	_menu.add_theme_constant_override("separation", 8)
	add_child(_menu)
	_menu.add_child(_menu_button("日志", _open_log))
	_menu.add_child(_menu_button("保存", _open_save))
	_menu.add_child(_menu_button("读取", _open_load))
	_menu.add_child(_menu_button("自动", _toggle_auto))
	_menu.add_child(_menu_button("快进", _toggle_skip))
	_menu.add_child(_menu_button("设置", _open_settings))
	_menu.add_child(_menu_button("分支树", func() -> void: Game.router.show_branch_tree()))
	_menu.add_child(_menu_button("标题", func() -> void: Game.router.show_title()))

	# 选项（独立面板，盖在角色之上，避免和立绘打架）
	_choice_panel = Kit.panel(Kit.c("#0c1017", 0.94), Kit.c("#5a4a2a"), 14)
	_choice_panel.position = Vector2(330, 250)
	_choice_panel.custom_minimum_size = Vector2(620, 0)
	_choice_panel.visible = false
	add_child(_choice_panel)

	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 10)
	_choice_panel.add_child(_choice_box)

	_choice_prompt = Kit.label("", 16, Kit.c("#ffe9b0"))
	_choice_box.add_child(_choice_prompt)

	# 状态栏
	_status = Kit.label("", 15, Kit.c("#b9c6d8"))
	_status.position = Vector2(28, 16)
	add_child(_status)

	# 提示条
	_toast = Kit.label("", 16, Kit.c("#ffe28a"))
	_toast.position = Vector2(430, 70)
	_toast.modulate.a = 0.0
	add_child(_toast)

func _menu_button(txt: String, cb: Callable) -> Button:
	var b := Kit.button(txt, 15)
	b.custom_minimum_size = Vector2(66, 34)
	b.pressed.connect(cb)
	return b

# ── 舞台渲染 ──────────────────────────────────────────────

func _on_event_started(ev: Dictionary) -> void:
	var chapter := Events.chapter_title()
	var slot: String = {"morning": "清晨", "noon": "正午", "dusk": "黄昏", "night": "深夜"}.get(Game.time_slot, Game.time_slot)
	var loc: String = {"ferry": "渡轮", "dock": "码头", "villa": "别墅", "warship": "军舰"}.get(Game.location, Game.location)
	_status.text = "%s ｜ %s ｜ %s" % [chapter, slot, loc]
	_on_stage(Game.stage)

func _on_engine_done() -> void:
	if _ending_open:
		return
	var nxt := Events.advance()
	if nxt == "":
		_line_active = false
		_show_toast("本章待续 —— 后续事件待编写")
		return
	call_deferred("_start_event", nxt)

func _start_event(event_id: String) -> void:
	engine.start("ev:" + event_id, 0)

func _on_stage(stage: Dictionary) -> void:
	_render_bg(stage)
	_render_chars(stage)
	_render_props(stage)

func _render_bg(stage: Dictionary) -> void:
	var sid := str(stage.get("bg", "island_day"))
	var sc := Story.get_scene(sid)
	var sky_hex := str(sc.get("sky", "#79b8ff"))
	var bg_hex := str(sc.get("bg", "#cfe4ff"))
	var sky_mode := str(stage.get("sky", sc.get("sky_mode", "day")))
	if sky_mode == "red":
		sky_hex = "#8c1f1f"
		bg_hex = "#2a0d0d"
		_dimmer.color = Color(0.5, 0.02, 0.02, 0.18)
	elif sky_mode == "dusk":
		_dimmer.color = Color(0.15, 0.02, 0.05, 0.10)
	elif sky_mode == "night":
		_dimmer.color = Color(0, 0, 0, 0.28)
	else:
		_dimmer.color = Color(0, 0, 0, 0.0)
	var bg_tex_path := str(sc.get("texture", ""))
	if bg_tex_path != "" and ResourceLoader.exists(bg_tex_path):
		_bg_tex.texture = load(bg_tex_path)
	else:
		_bg_tex.texture = Kit.vgrad(Kit.c(sky_hex), Kit.c(bg_hex)).texture
	_bg_tex.self_modulate = Color.WHITE

func _render_chars(stage: Dictionary) -> void:
	for c in _chars_layer.get_children():
		c.queue_free()
	var chars: Array = stage.get("chars", [])
	var slots := {
		"left": Vector2(100, 170),
		"center": Vector2(480, 150),
		"right": Vector2(860, 170),
	}
	for entry in chars:
		if not (entry is Dictionary):
			continue
		var cid := str(entry.get("id", ""))
		var slot := str(entry.get("slot", "center"))
		var pos: Vector2 = slots.get(slot, slots["center"])
		var info := Story.get_char(cid)
		var col := Kit.c(str(info.get("color", "#888888")))
		var p := Kit.panel(col.darkened(0.72), col, 16)
		p.position = pos
		p.custom_minimum_size = Vector2(300, 320)
		p.size = Vector2(300, 320)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_chars_layer.add_child(p)

		var tex_path := str(info.get("texture", ""))
		if tex_path != "" and ResourceLoader.exists(tex_path):
			var tr := TextureRect.new()
			tr.texture = load(tex_path)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(300, 320)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.add_child(tr)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		p.add_child(vb)
		var name_l := Kit.label(str(info.get("name", cid)), 34, col)
		vb.add_child(name_l)
		var type_l := Kit.label(str(info.get("type", "")), 15, Kit.c("#9aa8bc"))
		vb.add_child(type_l)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 170)
		vb.add_child(spacer)
		var expr := str(entry.get("expr", ""))
		if expr != "":
			vb.add_child(Kit.label("表情：" + expr, 14, Kit.c("#b9c6d8")))

func _render_props(stage: Dictionary) -> void:
	for c in _props_layer.get_children():
		c.queue_free()
	var props: Array = stage.get("props", [])
	var x := 900
	for entry in props:
		if not (entry is Dictionary):
			continue
		var pid := str(entry.get("id", ""))
		var info := Story.get_prop(pid)
		var col := Kit.c(str(info.get("color", "#888888")))
		var p := Kit.panel(col.darkened(0.6), col, 10)
		p.position = Vector2(x, 470)
		p.custom_minimum_size = Vector2(150, 90)
		p.size = Vector2(150, 90)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_props_layer.add_child(p)
		var ptex := str(info.get("texture", ""))
		if ptex != "" and ResourceLoader.exists(ptex):
			var tr2 := TextureRect.new()
			tr2.texture = load(ptex)
			tr2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr2.custom_minimum_size = Vector2(150, 70)
			tr2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.add_child(tr2)
		var vb := VBoxContainer.new()
		p.add_child(vb)
		vb.add_child(Kit.label(str(info.get("title", pid)), 16, col))
		x -= 160

# ── 对话流程 ──────────────────────────────────────────────

func _on_line(line: Dictionary) -> void:
	var speaker := str(line.get("speaker", ""))
	_name_label.text = speaker
	if speaker == "旁白" or speaker == "":
		_name_label.add_theme_color_override("font_color", Kit.c("#8fa0ba"))
	else:
		var cid := str(line.get("char", ""))
		var col := Color(0.93, 0.85, 0.62)
		if cid != "":
			col = Kit.c(Story.char_color(cid))
		_name_label.add_theme_color_override("font_color", col)

	_text.text = str(line.get("text", ""))
	_text.visible_characters = 0
	_text.add_theme_font_size_override("normal_font_size", Settings.font_size)
	_type_acc = 0.0
	_typing = true
	_line_active = true
	_auto_acc = 0.0

func _process(delta: float) -> void:
	if _typing:
		var speed := 55.0 * Settings.text_speed * (3.0 if _skip else 1.0)
		_type_acc += delta * speed
		var total := _text.get_total_character_count()
		_text.visible_characters = int(min(_type_acc, total))
		if _text.visible_characters >= total:
			_typing = false
			_skip = false
	elif _auto and _line_active:
		_auto_acc += delta
		if _auto_acc > Settings.auto_delay + 0.03 * _text.get_total_character_count():
			_advance()

func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null or _ending_open:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_open_menu_hint()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_toggle_dev_panel()
		return
	if event is InputEventKey and event.ctrl_pressed and event.pressed and event.keycode == KEY_SPACE:
		return
	var go := false
	if event.is_action_pressed("ui_accept"):
		go = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		go = true
	if not go or not _line_active:
		return
	ui_advance()

func ui_advance() -> void:
	if not _line_active:
		return
	if _typing:
		_typing = false
		_text.visible_characters = _text.get_total_character_count()
	else:
		_advance()

func _advance() -> void:
	if not _line_active:
		return
	_line_active = false
	_auto_acc = 0.0
	engine.advance()

# ── 选项 ──────────────────────────────────────────────────

func _on_choice(choice: Dictionary) -> void:
	_line_active = false
	_typing = false
	_text.text = str(choice.get("prompt", ""))
	_text.visible_characters = -1
	_name_label.text = "选择"
	_name_label.add_theme_color_override("font_color", Kit.c("#ffd479"))

	for c in _choice_box.get_children():
		if c != _choice_prompt:
			c.queue_free()
	_choice_prompt.text = "—— 选择 ——"
	var opts: Array = choice.get("options", [])
	for i in opts.size():
		var opt: Dictionary = opts[i]
		var b := Kit.button(str(opt.get("text", "选项 %d" % (i + 1))), 17)
		var idx := i
		b.pressed.connect(func() -> void: _pick(idx))
		_choice_box.add_child(b)
	_choice_panel.visible = true
	if is_instance_valid(_chars_layer):
		_chars_layer.modulate = Color(1, 1, 1, 0.28)

func _pick(i: int) -> void:
	_choice_panel.visible = false
	for c in _choice_box.get_children():
		if c != _choice_prompt:
			c.queue_free()
	if is_instance_valid(_chars_layer):
		_chars_layer.modulate = Color.WHITE
	engine.choose(i)

# ── 结局 / 分支 ──────────────────────────────────────────

func _on_branch(_id: String, title: String) -> void:
	_show_toast("已记录分支：" + title)

func _on_ending(_id: String, title: String, text: String) -> void:
	_ending_open = true
	_auto = false
	_overlay = Control.new()
	Kit.full(_overlay)
	add_child(_overlay)
	_overlay.add_child(Kit.dimmer())
	var panel := Kit.panel(Kit.c("#141821", 0.97), Kit.c("#8a3a3a"))
	panel.position = Vector2(240, 130)
	panel.custom_minimum_size = Vector2(800, 460)
	_overlay.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)
	vb.add_child(Kit.label(title, 34, Kit.c("#f0c070")))
	var t := RichTextLabel.new()
	t.bbcode_enabled = false
	t.fit_content = false
	t.custom_minimum_size = Vector2(720, 280)
	t.add_theme_font_size_override("normal_font_size", Settings.font_size)
	t.text = text
	vb.add_child(t)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	var b1 := Kit.button("回到标题", 16)
	b1.pressed.connect(func() -> void: Game.router.show_title())
	hb.add_child(b1)
	var b2 := Kit.button("分支树", 16)
	b2.pressed.connect(func() -> void: Game.router.show_branch_tree())
	hb.add_child(b2)

# ── 覆盖层：日志 / 保存 / 读取 / 设置 ─────────────────────

func _open_overlay() -> void:
	_close_overlay()
	_overlay = Control.new()
	Kit.full(_overlay)
	add_child(_overlay)
	_overlay.add_child(Kit.dimmer())

func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null

func _overlay_panel(w: int, h: int, x: int, y: int) -> VBoxContainer:
	var panel := Kit.panel(Kit.c("#141b28"), Kit.c("#33415c"))
	panel.position = Vector2(x, y)
	panel.custom_minimum_size = Vector2(w, h)
	_overlay.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	return vb

func _open_log() -> void:
	_open_overlay()
	var vb := _overlay_panel(900, 560, 190, 80)
	vb.add_child(Kit.label("对话记录", 24))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(860, 440)
	vb.add_child(scroll)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(840, 0)
	rt.add_theme_font_size_override("normal_font_size", 16)
	var lines: Array = []
	for h in Game.history:
		var sp := str(h.get("speaker", ""))
		var tx := str(h.get("text", ""))
		if sp == "旁白" or sp == "":
			lines.append("[color=#8fa0ba]%s[/color]" % tx)
		else:
			lines.append("[color=#e8c887]%s[/color]：%s" % [sp, tx])
	rt.text = "\n".join(lines)
	scroll.add_child(rt)
	var close := Kit.button("关闭", 16)
	close.pressed.connect(_close_overlay)
	vb.add_child(close)

func _open_save() -> void:
	_open_overlay()
	var vb := _overlay_panel(560, 360, 360, 180)
	vb.add_child(Kit.label("保存到槽位", 22))
	for i in 3:
		var info := Saves.slot_info(i)
		var txt := "空槽位 %d" % (i + 1)
		if not info.is_empty():
			txt = "槽 %d ｜ %s" % [i + 1, str(info.get("label", ""))]
		var b := Kit.button(txt, 15)
		var idx := i
		b.pressed.connect(func() -> void:
			Saves.save_slot(idx, Game.snapshot())
			_show_toast("已保存到槽 %d" % (idx + 1))
			_close_overlay()
		)
		vb.add_child(b)
	var cancel := Kit.button("取消", 15)
	cancel.pressed.connect(_close_overlay)
	vb.add_child(cancel)

func _open_load() -> void:
	_open_overlay()
	var vb := _overlay_panel(560, 360, 360, 180)
	vb.add_child(Kit.label("读取存档", 22))
	for i in 3:
		var info := Saves.slot_info(i)
		var b := Kit.button("空槽位 %d" % (i + 1), 15)
		if not info.is_empty():
			b.text = "槽 %d ｜ %s" % [i + 1, str(info.get("label", ""))]
		else:
			b.disabled = true
		var idx := i
		b.pressed.connect(func() -> void:
			var d := Saves.load_slot(idx)
			if not d.is_empty():
				Game.router.show_game(d.get("snapshot", {}))
		)
		vb.add_child(b)
	var cancel := Kit.button("取消", 15)
	cancel.pressed.connect(_close_overlay)
	vb.add_child(cancel)

func _open_settings() -> void:
	_open_overlay()
	var vb := _overlay_panel(520, 300, 380, 200)
	vb.add_child(Kit.label("设置", 22))
	var size_label := Kit.label("字幕大小：%d px" % Settings.font_size, 15)
	vb.add_child(size_label)
	var s := HSlider.new()
	s.min_value = 14
	s.max_value = 30
	s.step = 1
	s.value = Settings.font_size
	s.custom_minimum_size = Vector2(460, 24)
	s.value_changed.connect(func(v: float) -> void:
		Settings.font_size = int(v)
		size_label.text = "字幕大小：%d px" % Settings.font_size
		_text.add_theme_font_size_override("normal_font_size", Settings.font_size)
		Settings.save_settings()
	)
	vb.add_child(s)
	var auto_label := Kit.label("自动间隔：%.1f 秒" % Settings.auto_delay, 15)
	vb.add_child(auto_label)
	var s2 := HSlider.new()
	s2.min_value = 0.8
	s2.max_value = 4.0
	s2.step = 0.1
	s2.value = Settings.auto_delay
	s2.custom_minimum_size = Vector2(460, 24)
	s2.value_changed.connect(func(v: float) -> void:
		Settings.auto_delay = v
		auto_label.text = "自动间隔：%.1f 秒" % Settings.auto_delay
		Settings.save_settings()
	)
	vb.add_child(s2)
	var close := Kit.button("关闭", 15)
	close.pressed.connect(_close_overlay)
	vb.add_child(close)

# ── 小工具 ────────────────────────────────────────────────

func _toggle_auto() -> void:
	_auto = not _auto
	_show_toast("自动播放：" + ("开" if _auto else "关"))

func _toggle_skip() -> void:
	_skip = true
	_show_toast("快进中……")

func _open_menu_hint() -> void:
	_show_toast("Esc：菜单在右上角（日志/保存/读取/设置/分支树）")

func _show_toast(msg: String) -> void:
	_toast.text = msg
	_toast.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.4)
	t.tween_property(_toast, "modulate:a", 0.0, 0.5)

func _toggle_dev_panel() -> void:
	if _dev_panel != null and is_instance_valid(_dev_panel):
		_dev_panel.queue_free()
		_dev_panel = null
		return
	_dev_panel = Control.new()
	Kit.full(_dev_panel)
	add_child(_dev_panel)
	var panel := Kit.panel(Kit.c("#121722", 0.94), Kit.c("#3b4a63"))
	panel.position = Vector2(880, 70)
	panel.custom_minimum_size = Vector2(360, 520)
	_dev_panel.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	vb.add_child(Kit.label("调试面板（F1 关闭）", 16, Kit.c("#ffd479")))
	vb.add_child(Kit.label("场景预览", 14, Kit.c("#9fb0c8")))
	for sid in Story.scenes.keys():
		var sc := Story.get_scene(str(sid))
		var b := Kit.button(str(sc.get("title", sid)), 12)
		b.custom_minimum_size = Vector2(320, 28)
		var key := str(sid)
		b.pressed.connect(func() -> void:
			Game.stage["bg"] = key
			Game.stage["sky"] = str(sc.get("sky_mode", "day"))
			_on_stage(Game.stage)
		)
		vb.add_child(b)
	vb.add_child(Kit.label("道具开关", 14, Kit.c("#9fb0c8")))
	for pid in Story.props.keys():
		var pr := Story.get_prop(str(pid))
		var b2 := Kit.button("＋ " + str(pr.get("title", pid)), 12)
		b2.custom_minimum_size = Vector2(320, 28)
		var key2 := str(pid)
		b2.pressed.connect(func() -> void:
			var props: Array = Game.stage.get("props", [])
			props.append({"id": key2})
			Game.stage["props"] = props
			_on_stage(Game.stage)
		)
		vb.add_child(b2)
