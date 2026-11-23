extends Node
## 第 5 周目：联合会档案事件应被触发，随后进入既视感上岛。

const StoryEngine = preload("res://story/story_engine.gd")
var engine
var lines := 0
var done := false
var first_event := ""
var events_seen: Array = []

func _ready() -> void:
	await get_tree().process_frame
	Saves.loop_count = 4
	Game.reset()
	print("LOOP check loop=", Game.loop)
	engine = StoryEngine.new()
	add_child(engine)
	engine.line_ready.connect(_on_line)
	engine.story_done.connect(_on_done)
	Events.start_flow("prologue")
	first_event = Events.current_id
	events_seen.append(first_event)
	engine.start("ev:" + Events.current_id, 0)
	var guard := 0
	while not done and guard < 400:
		guard += 1
		await get_tree().process_frame
	var lore = JSON.parse_string(FileAccess.get_file_as_string("res://data/lore/entries.json"))
	var malice_unlocked := false
	for e in lore:
		if str(e.get("id", "")) == "malice":
			malice_unlocked = (Saves.loop_count + 1) >= int(e.get("loop_required", 99))
	print("LOOP first=", first_event, " seen=", events_seen, " lines=", lines, " malice_unlocked=", malice_unlocked)
	Saves.loop_count = 0
	get_tree().quit()

func _on_line(_l: Dictionary) -> void:
	lines += 1
	await get_tree().process_frame
	if not done:
		engine.advance()

func _on_done() -> void:
	var nxt := Events.advance()
	if nxt == "":
		done = true
	else:
		events_seen.append(nxt)
		call_deferred("_start_next", nxt)

func _start_next(id: String) -> void:
	engine.start("ev:" + id, 0)
