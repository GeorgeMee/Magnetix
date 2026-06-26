extends Control

@onready var list_container: VBoxContainer = %ListContainer
@onready var btn_generate: Button = %BtnGenerate

func _ready() -> void:
	btn_generate.pressed.connect(_on_generate)
	_refresh_list()

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var dir := DirAccess.open("res://presets")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			_add_preset_button(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _add_preset_button(file_name: String) -> void:
	var btn := Button.new()
	btn.text = file_name.trim_suffix(".tres")
	btn.pressed.connect(func(): _open_preset(file_name))
	list_container.add_child(btn)

func _open_preset(file_name: String) -> void:
	GameManager.pending_preset_path = "res://presets/" + file_name
	get_tree().change_scene_to_file("res://src/scenes/preset/preset_scene.tscn")

func _on_generate() -> void:
	_preset_data = null
	get_tree().change_scene_to_file("res://src/scenes/preset/preset_generator.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
