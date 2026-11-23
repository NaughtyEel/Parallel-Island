extends Node
## 主路由：标题 / 游戏 / 分支树 三个界面互相切换。

const TitleScreen = preload("res://ui/title_screen.gd")
const GameScreen = preload("res://ui/game_screen.gd")
const BranchTreeScreen = preload("res://ui/branch_tree_screen.gd")
const ArchiveScreen = preload("res://ui/archive_screen.gd")

var screen: Control = null

func _ready() -> void:
	Game.router = self
	show_title()

func _clear() -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	screen = null

func show_title() -> void:
	_clear()
	screen = TitleScreen.new()
	add_child(screen)

func show_game(snapshot: Dictionary = {}) -> void:
	_clear()
	var g := GameScreen.new()
	g.pending_snapshot = snapshot
	add_child(g)
	screen = g

func show_archive() -> void:
	_clear()
	screen = ArchiveScreen.new()
	add_child(screen)
	screen = screen

func show_branch_tree() -> void:
	_clear()
	screen = BranchTreeScreen.new()
	add_child(screen)
