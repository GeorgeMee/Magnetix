extends Control

var settings_panel : Panel

func _ready() -> void:
	GameManager.state = GameManager.GameState.MENU
	GameManager.sim_mode = false
	%StartButton.pressed.connect(_on_start)
	%SettingsButton.pressed.connect(_on_settings)
	%SimPreviewButton.pressed.connect(_on_sim_preview)
	%SimSceneButton.pressed.connect(_on_sim_scene)

func _on_start() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main/main.tscn")

func _on_sim_preview() -> void:
	get_tree().change_scene_to_file("res://src/scenes/ui/sim_preview.tscn")

func _on_sim_scene() -> void:
	get_tree().change_scene_to_file("res://src/scenes/sim/sim_scene.tscn")

func _on_settings() -> void:
	if settings_panel:
		return
	settings_panel = preload("res://src/scenes/ui/settings_panel.tscn").instantiate()
	settings_panel.visible = true
	settings_panel.get_node("VBoxContainer/CloseButton").pressed.connect(_close_settings)
	add_child(settings_panel)

func _close_settings() -> void:
	if settings_panel:
		settings_panel.queue_free()
		settings_panel = null
