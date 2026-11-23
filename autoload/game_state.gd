extends Node
## 运行时状态：一条"世界线"的全部可存档内容。
## 分支树里的每个分支点都会复制一份 snapshot，用于"从这里重来"。

var router: Node = null

var story_id: String = "prologue"
var node_index: int = 0

var event_id: String = ""
var loop: int = 1
var time_slot: String = "morning"   # morning / noon / dusk / night
var location: String = "ferry"      # ferry / dock / villa / warship ...
var seen_events: Array = []

var affinity: Dictionary = {}   # char_id -> int
var flags: Dictionary = {}      # flag_name -> Variant
var deaths: Array = []          # 已死亡角色 id，按顺序
var endings: Array = []         # 本周目已抵达结局 id
var history: Array = []         # [{speaker, text}]
var stage: Dictionary = {}      # {bg, sky, chars:[{id,slot,expr}], props:[{id,slot}]}

func reset() -> void:
	story_id = "prologue"
	node_index = 0
	event_id = ""
	loop = 1
	if Saves != null:
		loop = Saves.loop_count + 1
	time_slot = "morning"
	location = "ferry"
	seen_events = []
	affinity = {}
	flags = {}
	deaths = []
	endings = []
	history = []
	stage = {"bg": "island_day", "sky": "day", "chars": [], "props": []}

func affinity_of(id: String) -> int:
	return int(affinity.get(id, 0))

func add_affinity(id: String, v: int) -> void:
	affinity[id] = affinity_of(id) + v

func add_flag(key: String, value = true) -> void:
	flags[key] = value

func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))

func is_dead(id: String) -> bool:
	return deaths.has(id)

func snapshot() -> Dictionary:
	return {
		"story_id": story_id,
		"node_index": node_index,
		"event_id": event_id,
		"loop": loop,
		"time_slot": time_slot,
		"location": location,
		"seen_events": seen_events.duplicate(),
		"affinity": affinity.duplicate(true),
		"flags": flags.duplicate(true),
		"deaths": deaths.duplicate(),
		"endings": endings.duplicate(),
		"history": history.duplicate(true),
		"stage": stage.duplicate(true),
		"saved_at": Time.get_datetime_string_from_system(),
	}

func restore(d: Dictionary) -> void:
	story_id = str(d.get("story_id", "prologue"))
	node_index = int(d.get("node_index", 0))
	event_id = str(d.get("event_id", ""))
	loop = int(d.get("loop", 1))
	time_slot = str(d.get("time_slot", "morning"))
	location = str(d.get("location", "ferry"))
	seen_events = d.get("seen_events", []).duplicate()
	affinity = d.get("affinity", {}).duplicate(true)
	flags = d.get("flags", {}).duplicate(true)
	deaths = d.get("deaths", []).duplicate()
	endings = d.get("endings", []).duplicate()
	history = d.get("history", []).duplicate(true)
	stage = d.get("stage", {"bg": "island_day", "sky": "day", "chars": [], "props": []}).duplicate(true)

func last_line() -> String:
	if history.is_empty():
		return ""
	return str(history[history.size() - 1].get("text", ""))
