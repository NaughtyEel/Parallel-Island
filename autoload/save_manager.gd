extends Node
## 存档槽 + 跨周目的分支/结局解锁记录。

const SLOT_COUNT := 3
const SAVE_DIR := "user://saves"
const META_PATH := "user://branch_tree.json"

var branch_meta: Dictionary = {}   # branch_id -> {title, time, snapshot}
var loop_count: int = 0            # 已完成周目数
var ending_meta: Dictionary = {}   # ending_id -> {title, time}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	load_meta()

func slot_path(i: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, i]

func save_slot(i: int, snap: Dictionary) -> bool:
	var data := {
		"snapshot": snap,
		"time": Time.get_datetime_string_from_system(),
		"label": _label_of(snap),
	}
	var f := FileAccess.open(slot_path(i), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true

func load_slot(i: int) -> Dictionary:
	if not FileAccess.file_exists(slot_path(i)):
		return {}
	var f := FileAccess.open(slot_path(i), FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d if d is Dictionary else {}

func has_slot(i: int) -> bool:
	return FileAccess.file_exists(slot_path(i))

func slot_info(i: int) -> Dictionary:
	var d := load_slot(i)
	if d.is_empty():
		return {}
	return d

func _label_of(snap: Dictionary) -> String:
	var st: Dictionary = Story.get_story(str(snap.get("story_id", "")))
	var title := str(st.get("title", "序章"))
	var hist: Array = snap.get("history", [])
	var last := ""
	if not hist.is_empty():
		last = str(hist[hist.size() - 1].get("text", ""))
	if last.length() > 22:
		last = last.substr(0, 22) + "…"
	return "%s ｜ %s" % [title, last]

func load_meta() -> void:
	branch_meta = {}
	ending_meta = {}
	if not FileAccess.file_exists(META_PATH):
		return
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if d is Dictionary:
		branch_meta = d.get("branches", {})
		ending_meta = d.get("endings", {})
		loop_count = int(d.get("loop_count", 0))

func save_meta() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"branches": branch_meta, "endings": ending_meta, "loop_count": loop_count}, "\t"))
	f.close()

func record_loop() -> void:
	loop_count += 1
	save_meta()

func unlock_branch(id: String, title: String, snap: Dictionary) -> void:
	if branch_meta.has(id):
		return
	branch_meta[id] = {"title": title, "snapshot": snap, "time": Time.get_datetime_string_from_system()}
	save_meta()

func unlock_ending(id: String, title: String) -> void:
	if ending_meta.has(id):
		return
	ending_meta[id] = {"title": title, "time": Time.get_datetime_string_from_system()}
	save_meta()

func clear_all() -> void:
	for i in SLOT_COUNT:
		if FileAccess.file_exists(slot_path(i)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(i)))
	branch_meta = {}
	ending_meta = {}
	save_meta()
