extends Node
## 渲染预览：自动推进对话几行，用于截图检查布局。

var gs
var ticks := 0

func _ready() -> void:
	gs = preload("res://ui/game_screen.gd").new()
	add_child(gs)
	var t := Timer.new()
	t.wait_time = 0.35
	t.autostart = true
	t.timeout.connect(_tick)
	add_child(t)

func _tick() -> void:
	ticks += 1
	if gs == null or not is_instance_valid(gs):
		return
	if gs.get("_choice_panel") != null and gs._choice_panel.visible:
		gs._pick(0)
		return
	if ticks < 200 and gs.has_method("ui_advance"):
		gs.ui_advance()
