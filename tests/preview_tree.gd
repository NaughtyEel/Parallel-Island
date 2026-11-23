extends Node

func _ready() -> void:
	add_child(preload("res://ui/branch_tree_screen.gd").new())
