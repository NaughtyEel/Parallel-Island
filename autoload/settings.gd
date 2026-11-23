extends Node
## 字幕大小 / 文本速度 / 自动播放间隔，存 user://settings.json。

const PATH := "user://settings.json"

var font_size: int = 21
var text_speed: float = 1.0
var auto_delay: float = 1.8

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if d is Dictionary:
		font_size = int(d.get("font_size", font_size))
		text_speed = float(d.get("text_speed", text_speed))
		auto_delay = float(d.get("auto_delay", auto_delay))

func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"font_size": font_size,
		"text_speed": text_speed,
		"auto_delay": auto_delay,
	}, "\t"))
	f.close()
