extends Node
## 数据层：剧本、角色、场景、道具全部来自 data/*.json，方便后续扩展。

var stories: Dictionary = {}
var characters: Dictionary = {}
var scenes: Dictionary = {}
var props: Dictionary = {}

const CHAR_PATH := "res://data/characters.json"
const SCENE_PATH := "res://data/scenes.json"
const PROP_PATH := "res://data/props.json"
const STORY_DIR := "res://data/story"

func _ready() -> void:
	_load_list(CHAR_PATH, characters)
	_load_list(SCENE_PATH, scenes)
	_load_list(PROP_PATH, props)
	_load_stories()

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("缺少数据文件: " + path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d

func _load_list(path: String, target: Dictionary) -> void:
	var d = _read_json(path)
	if d is Array:
		for item in d:
			if item is Dictionary and item.has("id"):
				target[str(item.id)] = item
	elif d is Dictionary:
		for k in d:
			if d[k] is Dictionary:
				target[str(k)] = d[k]

func _load_stories() -> void:
	var dir := DirAccess.open(STORY_DIR)
	if dir == null:
		push_warning("缺少剧本目录: " + STORY_DIR)
		return
	for file in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var d = _read_json(STORY_DIR + "/" + file)
		if d is Dictionary and d.has("id"):
			stories[str(d.id)] = d

func get_story(id: String) -> Dictionary:
	return stories.get(id, {})

func get_char(id: String) -> Dictionary:
	return characters.get(id, {"id": id, "name": id, "color": "#888888", "type": ""})

func char_name(id: String) -> String:
	return str(get_char(id).get("name", id))

func char_color(id: String) -> String:
	return str(get_char(id).get("color", "#dddddd"))

func get_scene(id: String) -> Dictionary:
	return scenes.get(id, {})

func get_prop(id: String) -> Dictionary:
	return props.get(id, {"id": id, "name": id})
