extends Node
## 线性节点表 + 标签跳转的剧本执行器。
## 节点类型：label / line / choice / scene / stage / branch / dynamic_death / ending

signal line_ready(line: Dictionary)
signal choice_ready(choice: Dictionary)
signal ending_reached(id: String, title: String, text: String)
signal branch_reached(id: String, title: String)
signal stage_applied(stage: Dictionary)
signal story_done

var story: Dictionary = {}
var nodes: Array = []
var labels: Dictionary = {}
var idx: int = 0
var running: bool = false

func start(story_id: String, from_index: int = -1) -> void:
	story = Story.get_story(story_id)
	if story.is_empty():
		push_error("剧本不存在: " + story_id)
		story_done.emit()
		return
	nodes = story.get("nodes", [])
	labels = {}
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		if str(n.get("type", "")) == "label":
			labels[str(n.get("name", ""))] = i
	Game.story_id = story_id
	idx = from_index if from_index >= 0 else 0
	_run()

func _run() -> void:
	running = true
	var guard := 0
	while idx >= 0 and idx < nodes.size():
		guard += 1
		if guard > 5000:
			push_error("剧本疑似死循环")
			break
		var n: Dictionary = nodes[idx]
		var t := str(n.get("type", "line"))
		match t:
			"label":
				idx += 1
			"line":
				_show_line(n)
				return
			"choice":
				Game.node_index = idx
				choice_ready.emit(n)
				return
			"jump":
				var jt := str(n.get("goto", ""))
				idx = int(labels.get(jt, idx + 1))
			"death_fixed":
				_show_fixed_death(n)
				return
			"scene":
				_apply_scene(n)
				idx += 1
			"stage":
				_merge_stage(n)
				idx += 1
			"branch":
				Game.node_index = idx
				var bid := str(n.get("id", ""))
				var btitle := str(n.get("title", bid))
				Saves.unlock_branch(bid, btitle, Game.snapshot())
				branch_reached.emit(bid, btitle)
				idx += 1
			"dynamic_death":
				_show_death(n)
				return
			"ending":
				var eid := str(n.get("id", ""))
				Game.endings.append(eid)
				Saves.unlock_ending(eid, str(n.get("title", "")))
				ending_reached.emit(eid, str(n.get("title", "")), str(n.get("text", "")))
				story_done.emit()
				return
			_:
				idx += 1
	story_done.emit()

func _show_line(n: Dictionary) -> void:
	if n.has("stage"):
		_merge_stage(n["stage"])
	var last_death := ""
	if not Game.deaths.is_empty():
		last_death = Story.char_name(str(Game.deaths[Game.deaths.size() - 1]))
	var line := {
		"speaker": str(n.get("speaker", "")),
		"text": str(n.get("text", "")).replace("{victim}", last_death),
		"char": str(n.get("char", "")),
	}
	Game.history.append(line)
	if Game.history.size() > 600:
		Game.history.pop_front()
	Game.node_index = idx
	line_ready.emit(line)

func _show_death(n: Dictionary) -> void:
	var chars: Array = n.get("chars", [])
	var best := ""
	var best_aff := -9999
	for c in chars:
		var a := Game.affinity_of(str(c))
		if a > best_aff:
			best_aff = a
			best = str(c)
	if best == "":
		best = "leila"
	Game.deaths.append(best)
	var cname := Story.char_name(best)
	var raw := str(n.get("text", ""))
	var text := raw.replace("{victim}", cname)
	var line := {"speaker": "旁白", "text": text, "char": ""}
	Game.history.append(line)
	Game.node_index = idx
	line_ready.emit(line)

func _show_fixed_death(n: Dictionary) -> void:
	var cid := str(n.get("char", ""))
	Game.deaths.append(cid)
	var text := str(n.get("text", "")).replace("{victim}", Story.char_name(cid))
	var line := {"speaker": "旁白", "text": text, "char": ""}
	Game.history.append(line)
	Game.node_index = idx
	line_ready.emit(line)

func _apply_scene(n: Dictionary) -> void:
	Game.stage["bg"] = str(n.get("bg", Game.stage.get("bg", "island_day")))
	Game.stage["sky"] = str(n.get("sky", Game.stage.get("sky", "day")))
	stage_applied.emit(Game.stage)

func _merge_stage(n: Dictionary) -> void:
	for k in n.keys():
		if k == "type":
			continue
		Game.stage[k] = n[k]
	stage_applied.emit(Game.stage)

func advance() -> void:
	if idx < 0 or idx >= nodes.size():
		return
	var t := str(nodes[idx].get("type", ""))
	if t == "line" or t == "dynamic_death" or t == "death_fixed":
		idx += 1
		_run()

func choose(i: int) -> void:
	if idx < 0 or idx >= nodes.size():
		return
	var n: Dictionary = nodes[idx]
	var opts: Array = n.get("options", [])
	if i < 0 or i >= opts.size():
		return
	var opt: Dictionary = opts[i]
	var aff: Dictionary = opt.get("aff", {})
	for k in aff.keys():
		Game.add_affinity(str(k), int(aff[k]))
	var flags: Dictionary = opt.get("flags", {})
	for k in flags.keys():
		Game.add_flag(str(k), flags[k])
	var target := str(opt.get("goto", ""))
	if target != "" and labels.has(target):
		idx = int(labels[target])
	else:
		idx += 1
	_run()

func current_index() -> int:
	return idx
