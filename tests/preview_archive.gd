extends Node

func _ready() -> void:
	Saves.loop_count = 4
	add_child(preload("res://ui/archive_screen.gd").new())
