extends Control
## 设定档案：按周目解锁的世界观条目。

const Kit = preload("res://ui/kit.gd")

var _entries: Array = []

func _ready() -> void:
	Kit.full(self)
	_load_entries()
	_build()

func _load_entries() -> void:
	var path := "res://data/lore/entries.json"
	if not FileAccess.file_exists(path):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if d is Array:
		_entries = d

func _build() -> void:
	var bg := Kit.vgrad(Kit.c("#0a0e16"), Kit.c("#141a26"))
	add_child(bg)
	Kit.full(bg)

	var title := Kit.label("设定档案", 38, Kit.c("#f2e6d8"))
	title.position = Vector2(80, 52)
	add_child(title)

	var sub := Kit.label("第 %d 周目 ｜ 已解锁条目会显示全文，未解锁的只给出周目条件" % (Saves.loop_count + 1), 14, Kit.c("#8fa0ba"))
	sub.position = Vector2(82, 104)
	add_child(sub)

	var back := Kit.button("返回标题", 16)
	back.position = Vector2(1080, 56)
	back.custom_minimum_size = Vector2(140, 40)
	back.pressed.connect(func() -> void: Game.router.show_title())
	add_child(back)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 148)
	scroll.custom_minimum_size = Vector2(1120, 500)
	add_child(scroll)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(1100, 0)
	vb.add_theme_constant_override("separation", 12)
	scroll.add_child(vb)

	for e in _entries:
		var need := int(e.get("loop_required", 1))
		var cur_loop := Saves.loop_count + 1
		var unlocked := cur_loop >= need
		var row := Kit.panel(Kit.c("#121a26") if unlocked else Kit.c("#0f141d"),
			Kit.c("#3c5170") if unlocked else Kit.c("#222b3a"))
		row.custom_minimum_size = Vector2(1080, 0)
		vb.add_child(row)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		row.add_child(box)
		var head := Kit.label(str(e.get("title", "")), 20, Kit.c("#ffd479") if unlocked else Kit.c("#6b7a90"))
		box.add_child(head)
		if unlocked:
			var body := RichTextLabel.new()
			body.bbcode_enabled = false
			body.fit_content = true
			body.custom_minimum_size = Vector2(1040, 0)
			body.add_theme_font_size_override("normal_font_size", 15)
			body.add_theme_color_override("default_color", Kit.c("#cfdae8"))
			body.text = str(e.get("body", ""))
			box.add_child(body)
		else:
			box.add_child(Kit.label("第 %d 周目解锁" % need, 14, Kit.c("#55627a")))
