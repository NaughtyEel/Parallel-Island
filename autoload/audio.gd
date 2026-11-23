extends Node
## 极简 BGM 管理：有 assets/audio/bgm/<id>.ogg 就播放，没有就只记录曲名。

var current_id: String = ""
var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.0
	add_child(_player)

func play(id: String) -> void:
	if id == "":
		return
	current_id = id
	var path := "res://assets/audio/bgm/%s.ogg" % id
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStream:
			_player.stream = stream
			_player.play()
	else:
		stop()

func stop() -> void:
	current_id = ""
	_player.stop()

func current_track() -> String:
	return current_id
