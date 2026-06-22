extends Control

func _ready() -> void:
	GameManager.state = GameManager.GameState.MENU
	%StartButton.pressed.connect(_on_start)

func _on_start() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main/main.tscn")
