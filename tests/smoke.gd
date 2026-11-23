extends Node
## 无界面冒烟测试：跑完第一章事件流，检查好感度、分支记录与存档字段。

const StoryEngine = preload("res://story/story_engine.gd")

var engine: StoryEngine
var lines := 0
var choices := 0
var branches := 0
var done := false
var pick := 0

func _ready() -> void:
	await get_tree().process_frame
	await _play(0)
	print("SMOKE1 lines=", lines, " choices=", choices, " branches=", branches, " done=", done,
		" aff_leila=", Game.affinity_of("leila"), " aff_jiaoguan=", Game.affinity_of("jiaoguan"), " loop=", Game.loop, " event=", Game.event_id)
	Game.reset()
	Game.affinity["leila"] = 5
	Saves.save_slot(0, Game.snapshot())
	var d := Saves.load_slot(0)
	var snap: Dictionary = d.get("snapshot", {})
	print("SMOKE2 save_ok=", not snap.is_empty(), " aff=", snap.get("affinity", {}).get("leila", -1),
		" event=", snap.get("event_id", ""))
	print("SMOKE3 branch_meta=", Saves.branch_meta.size(), " chapter=", Events.chapter_title())
	get_tree().quit()

func _play(choice_i: int) -> void:
	pick = choice_i
	Game.reset()
	lines = 0
	choices = 0
	branches = 0
	done = false
	engine = StoryEngine.new()
	add_child(engine)
	engine.line_ready.connect(_on_line)
	engine.choice_ready.connect(_on_choice)
	engine.branch_reached.connect(func(_id: String, _t: String) -> void: branches += 1)
	engine.story_done.connect(_on_done)
	if not Events.start_flow("prologue"):
		push_error("事件流启动失败")
		done = true
		return
	engine.start("ev:" + Events.current_id, 0)
	var guard := 0
	while not done and guard < 600:
		guard += 1
		await get_tree().process_frame
	engine.queue_free()

func _on_line(_l: Dictionary) -> void:
	lines += 1
	await get_tree().process_frame
	if not done:
		engine.advance()

func _on_choice(c: Dictionary) -> void:
	choices += 1
	var opts: Array = c.get("options", [])
	var i: int = mini(pick, opts.size() - 1)
	await get_tree().process_frame
	engine.choose(i)

func _on_done() -> void:
	var nxt := Events.advance()
	if nxt == "":
		done = true
	else:
		call_deferred("_start_next", nxt)

func _start_next(event_id: String) -> void:
	engine.start("ev:" + event_id, 0)
