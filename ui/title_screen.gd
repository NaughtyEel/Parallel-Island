extends Control

const Kit = preload("res://ui/kit.gd")
## 标题 / 新游戏 / 继续 / 分支树 / 设置。

var _overlay: Control = null

func _ready() -> void:
	Kit.full(self)
	_build()

func _build() -> void:
	var bg := Kit.vgrad(Kit.c("#0a0f18"), Kit.c("#1a2333"))
	add_child(bg)
	Kit.full(bg)

	var red := ColorRect.new()
	red.color = Color(0.72, 0.16, 0.16, 0.10)
	red.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	red.offset_top = -220
	add_child(red)

	var title := Kit.label("平行之岛", 66, Kit.c("#f2e6d8"))
	title.position = Vector2(96, 150)
	add_child(title)

	var sub := Kit.label("PARALLEL ISLAND — a veridical paradox", 20, Kit.c("#9fb0c8"))
	sub.position = Vector2(102, 232)
	add_child(sub)

	var tag := Kit.label("恋爱 × 悬疑 ｜ 一周目必死 ｜ 二周目回环 ｜ 三周目破局", 16, Kit.c("#7d8ea6"))
	tag.position = Vector2(104, 268)
	add_child(tag)

	var loop_label := Kit.label("已回溯：第 %d 周目" % (Saves.loop_count + 1), 15, Kit.c("#c9a86a"))
	loop_label.position = Vector2(104, 296)
	add_child(loop_label)

	var box := VBoxContainer.new()
	box.position = Vector2(104, 340)
	box.custom_minimum_size = Vector2(300, 0)
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var b_new := Kit.button("开 始 新 游 戏")
	b_new.pressed.connect(_on_new)
	box.add_child(b_new)

	var b_cont := Kit.button("继 续 游 戏")
	b_cont.disabled = not (Saves.has_slot(0) or Saves.has_slot(1) or Saves.has_slot(2))
	b_cont.pressed.connect(_on_continue)
	box.add_child(b_cont)

	var b_tree := Kit.button("分 支 树")
	b_tree.pressed.connect(func() -> void: Game.router.show_branch_tree())
	box.add_child(b_tree)

	var b_archive := Kit.button("设 定 档 案")
	b_archive.pressed.connect(func() -> void: Game.router.show_archive())
	box.add_child(b_archive)

	var b_set := Kit.button("设 置")
	b_set.pressed.connect(_open_settings)
	box.add_child(b_set)

	var b_quit := Kit.button("退 出")
	b_quit.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(b_quit)

	var foot := Kit.label("v0.1 · 骨架演示（序章）· Godot 4.6", 14, Kit.c("#5f6f86"))
	foot.position = Vector2(104, 668)
	add_child(foot)

func _on_new() -> void:
	Game.reset()
	Game.router.show_game()

func _on_continue() -> void:
	_close_overlay()
	_overlay = Control.new()
	Kit.full(_overlay)
	add_child(_overlay)
	_overlay.add_child(Kit.dimmer())

	var panel := Kit.panel(Kit.c("#141b28"), Kit.c("#33415c"))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 320)
	panel.position = Vector2(380, 200)
	_overlay.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	vb.add_child(Kit.label("读取存档", 24))
	for i in Saves.SLOT_COUNT:
		var info := Saves.slot_info(i)
		var txt := "空槽位 %d" % (i + 1)
		if not info.is_empty():
			txt = "槽 %d ｜ %s" % [i + 1, str(info.get("label", ""))]
		var b := Kit.button(txt, 16)
		b.disabled = info.is_empty()
		var idx := i
		b.pressed.connect(func() -> void:
			var d := Saves.load_slot(idx)
			if not d.is_empty():
				_close_overlay()
				Game.router.show_game(d.get("snapshot", {}))
		)
		vb.add_child(b)

	var back := Kit.button("取消", 16)
	back.pressed.connect(_close_overlay)
	vb.add_child(back)

func _open_settings() -> void:
	_close_overlay()
	_overlay = Control.new()
	Kit.full(_overlay)
	add_child(_overlay)
	_overlay.add_child(Kit.dimmer())

	var panel := Kit.panel(Kit.c("#141b28"), Kit.c("#33415c"))
	panel.position = Vector2(390, 170)
	panel.custom_minimum_size = Vector2(500, 380)
	_overlay.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	vb.add_child(Kit.label("设置", 26))

	var size_label := Kit.label("字幕大小：%d px" % Settings.font_size, 16)
	vb.add_child(size_label)
	var s1 := HSlider.new()
	s1.min_value = 14
	s1.max_value = 30
	s1.step = 1
	s1.value = Settings.font_size
	s1.custom_minimum_size = Vector2(420, 24)
	s1.value_changed.connect(func(v: float) -> void:
		Settings.font_size = int(v)
		size_label.text = "字幕大小：%d px" % Settings.font_size
		Settings.save_settings()
	)
	vb.add_child(s1)

	var speed_label := Kit.label("文本速度：x%.1f" % Settings.text_speed, 16)
	vb.add_child(speed_label)
	var s2 := HSlider.new()
	s2.min_value = 0.5
	s2.max_value = 3.0
	s2.step = 0.1
	s2.value = Settings.text_speed
	s2.custom_minimum_size = Vector2(420, 24)
	s2.value_changed.connect(func(v: float) -> void:
		Settings.text_speed = v
		speed_label.text = "文本速度：x%.1f" % Settings.text_speed
		Settings.save_settings()
	)
	vb.add_child(s2)

	var auto_label := Kit.label("自动播放间隔：%.1f 秒" % Settings.auto_delay, 16)
	vb.add_child(auto_label)
	var s3 := HSlider.new()
	s3.min_value = 0.8
	s3.max_value = 4.0
	s3.step = 0.1
	s3.value = Settings.auto_delay
	s3.custom_minimum_size = Vector2(420, 24)
	s3.value_changed.connect(func(v: float) -> void:
		Settings.auto_delay = v
		auto_label.text = "自动播放间隔：%.1f 秒" % Settings.auto_delay
		Settings.save_settings()
	)
	vb.add_child(s3)

	var close := Kit.button("关闭", 16)
	close.pressed.connect(_close_overlay)
	vb.add_child(close)

func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
