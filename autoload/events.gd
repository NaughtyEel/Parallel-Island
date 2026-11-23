extends Node
## 事件系统：按 时间段 / 前置事件 / 好感度 / 周目 / 地点 判定该进哪个事件，
## 不满足时走 fallback。事件内容 = 场景 + BGM + 人物 + 节点（对白/选择/反馈）。

signal event_started(ev: Dictionary)
signal flow_finished

var flows: Dictionary = {}     # flow_id -> {title, events: [ids], start}
var events: Dictionary = {}    # event_id -> event dict
var current_id: String = ""
var flow_id: String = ""

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open("res://data/events")
	if dir == null:
		push_warning("缺少事件目录 res://data/events")
		return
	for file in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/events/" + file))
		if not (d is Dictionary):
			continue
		var flow_events: Array = []
		for ev in d.get("events", []):
			if not (ev is Dictionary) or not ev.has("id"):
				continue
			var eid := str(ev.id)
			events[eid] = ev
			# 注册成 StoryDB 里的一个剧本，引擎直接按 "ev:<id>" 播放
			Story.stories["ev:" + eid] = {
				"id": "ev:" + eid,
				"title": str(ev.get("title", eid)),
				"nodes": ev.get("nodes", []),
			}
			flow_events.append(eid)
		flows[str(d.get("id", file))] = {
			"title": str(d.get("title", "")),
			"events": flow_events,
			"start": flow_events[0] if flow_events.size() > 0 else "",
		}

func start_flow(id: String) -> bool:
	if not flows.has(id):
		push_error("事件流不存在: " + id)
		return false
	flow_id = id
	Game.seen_events = []
	var start := str(flows[id].get("start", ""))
	if start == "":
		return false
	return _enter(start)

func _enter(id: String) -> bool:
	if not events.has(id):
		return false
	var ev: Dictionary = events[id]
	if not matches(ev):
		return _enter_fallback(ev)
	current_id = id
	Game.event_id = id
	var ts: Array = ev.get("time_slots", [])
	if ts.size() > 0:
		Game.time_slot = str(ts[0])
	var loc := str(ev.get("location", ""))
	var arrive := str(ev.get("arrive_location", ""))
	if arrive != "":
		Game.location = arrive
	elif loc != "":
		Game.location = loc
	if not Game.seen_events.has(id):
		Game.seen_events.append(id)
	Game.add_flag("ev:" + id, true)

	var scene_id := str(ev.get("scene", ""))
	if scene_id != "":
		Game.stage["bg"] = scene_id
		var sky := str(ev.get("sky", ""))
		if sky != "":
			Game.stage["sky"] = sky
	Game.stage["chars"] = ev.get("chars", [])
	Game.stage["props"] = ev.get("props", [])
	Audio.play(str(ev.get("bgm", "")))
	event_started.emit(ev)
	return true

func _enter_fallback(ev: Dictionary) -> bool:
	var fb := str(ev.get("fallback", ""))
	if fb != "" and fb != str(ev.get("id", "")) and events.has(fb):
		return _enter(fb)
	return false

func matches(ev: Dictionary) -> bool:
	var loop_range: Array = ev.get("loop", [])
	if loop_range.size() == 2:
		if Game.loop < int(loop_range[0]) or Game.loop > int(loop_range[1]):
			return false
	var ts: Array = ev.get("time_slots", [])
	if ts.size() > 0 and not ts.has(Game.time_slot):
		return false
	var loc := str(ev.get("location", ""))
	if loc != "" and loc != Game.location:
		return false
	for req in ev.get("requires", []):
		if not Game.has_flag("ev:" + str(req)):
			return false
	for bad in ev.get("forbid", []):
		if Game.has_flag("ev:" + str(bad)):
			return false
	var amin: Dictionary = ev.get("affinity_min", {})
	for k in amin.keys():
		if Game.affinity_of(str(k)) < int(amin[k]):
			return false
	return true

func advance() -> String:
	if not events.has(current_id):
		return ""
	var ev: Dictionary = events[current_id]
	for cand in ev.get("next", []):
		var cid := str(cand)
		if events.has(cid) and matches(events[cid]):
			if _enter(cid):
				return cid
	var fb := str(ev.get("fallback", ""))
	if fb != "" and events.has(fb):
		if _enter(fb):
			return fb
	flow_finished.emit()
	return ""

func chapter_title() -> String:
	return str(flows.get(flow_id, {}).get("title", ""))

func current_event() -> Dictionary:
	return events.get(current_id, {})

func list_branches() -> Array:
	var out: Array = []
	for eid in events.keys():
		for n in events[eid].get("nodes", []):
			if str(n.get("type", "")) == "branch":
				out.append({
					"id": str(n.get("id", "")),
					"title": str(n.get("title", "")),
					"event": str(eid),
				})
	return out
