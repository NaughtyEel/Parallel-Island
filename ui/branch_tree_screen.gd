extends Control

const Kit = preload("res://ui/kit.gd")
## 分支树：跨周目记录的分支点，可"从此刻重来"；同时展示已解锁结局。

func _ready() -> void:
	Kit.full(self)
	_build()

func _build() -> void:
	var bg := Kit.vgrad(Kit.c("#0a0f18"), Kit.c("#151d2a"))
	add_child(bg)
	Kit.full(bg)

	var title := Kit.label("分支树", 38, Kit.c("#f2e6d8"))
	title.position = Vector2(80, 60)
	add_child(title)

	var sub := Kit.label("分支点会随剧情推进自动记录；点击「从此刻重来」可带着当时的好感度与状态重新开始。", 15, Kit.c("#8fa0ba"))
	sub.position = Vector2(82, 112)
	add_child(sub)

	var back := Kit.button("返回标题", 16)
	back.position = Vector2(1060, 64)
	back.custom_minimum_size = Vector2(140, 40)
	back.pressed.connect(func() -> void: Game.router.show_title())
	add_child(back)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 160)
	scroll.custom_minimum_size = Vector2(1120, 470)
	add_child(scroll)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(1100, 0)
	vb.add_theme_constant_override("separation", 10)
	scroll.add_child(vb)

	var branches: Array = Events.list_branches()
	var branch_count := 0
	for br in branches:
		branch_count += 1
		var bid := str(br.get("id", ""))
		var btitle := str(br.get("title", bid))
		var unlocked := Saves.branch_meta.has(bid)
		var row := Kit.panel(
			Kit.c("#121a26") if unlocked else Kit.c("#0f141d"),
			Kit.c("#3c5170") if unlocked else Kit.c("#222b3a")
		)
		row.custom_minimum_size = Vector2(1080, 74)
		vb.add_child(row)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 16)
		row.add_child(hb)
		var mark := Kit.label("◆" if unlocked else "◇", 26, Kit.c("#ffd479") if unlocked else Kit.c("#4a566a"))
		mark.custom_minimum_size = Vector2(40, 0)
		hb.add_child(mark)
		var info := VBoxContainer.new()
		info.custom_minimum_size = Vector2(760, 0)
		info.add_theme_constant_override("separation", 2)
		hb.add_child(info)
		info.add_child(Kit.label(btitle, 20, Kit.c("#e8eef8") if unlocked else Kit.c("#6b7a90")))
		if unlocked:
			var meta: Dictionary = Saves.branch_meta[bid]
			info.add_child(Kit.label("解锁于 " + str(meta.get("time", "")), 13, Kit.c("#7d8ea6")))
		else:
			info.add_child(Kit.label("尚未抵达", 13, Kit.c("#55627a")))
		var btn := Kit.button("从此刻重来" if unlocked else "未解锁", 15)
		btn.custom_minimum_size = Vector2(160, 40)
		btn.disabled = not unlocked
		var key := bid
		btn.pressed.connect(func() -> void: _resume(key))
		hb.add_child(btn)

	if branch_count == 0:
		vb.add_child(Kit.label("还没有分支点。", 16, Kit.c("#8fa0ba")))

	vb.add_child(Kit.label("已解锁结局", 22, Kit.c("#f0c070")))
	if Saves.ending_meta.is_empty():
		vb.add_child(Kit.label("还没有抵达任何结局。", 15, Kit.c("#7d8ea6")))
	else:
		for eid in Saves.ending_meta.keys():
			var meta: Dictionary = Saves.ending_meta[eid]
			var row2 := Kit.panel(Kit.c("#121a26"), Kit.c("#3c5170"))
			row2.custom_minimum_size = Vector2(1080, 62)
			vb.add_child(row2)
			var hb2 := HBoxContainer.new()
			row2.add_child(hb2)
			hb2.add_child(Kit.label("★ " + str(meta.get("title", eid)), 18, Kit.c("#ffd479")))
			hb2.add_child(Kit.label("    " + str(meta.get("time", "")), 13, Kit.c("#7d8ea6")))

func _resume(branch_id: String) -> void:
	if not Saves.branch_meta.has(branch_id):
		return
	var meta: Dictionary = Saves.branch_meta[branch_id]
	var snap: Dictionary = meta.get("snapshot", {})
	if snap.is_empty():
		return
	Game.restore(snap)
	Game.router.show_game(snap)
