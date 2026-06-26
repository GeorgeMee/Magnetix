extends Control

@onready var list_container: VBoxContainer = %ListContainer
@onready var btn_generate: Button = %BtnGenerate
@onready var btn_delete_all: Button = %BtnDeleteAll

func _ready() -> void:
	btn_generate.pressed.connect(_on_generate)
	btn_delete_all.pressed.connect(_on_delete_all)
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
			_add_preset_row(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _add_preset_row(file_name: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var btn := Button.new()
	btn.text = file_name.trim_suffix(".tres")
	btn.custom_minimum_size = Vector2(300, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func(): _open_preset(file_name))
	row.add_child(btn)

	var del_btn := Button.new()
	del_btn.text = "✕"
	del_btn.custom_minimum_size = Vector2(48, 40)
	del_btn.pressed.connect(func(): _delete_preset(file_name))
	row.add_child(del_btn)

	list_container.add_child(row)

func _open_preset(file_name: String) -> void:
	GameManager.pending_preset_path = "res://presets/" + file_name
	get_tree().change_scene_to_file("res://src/scenes/preset/preset_scene.tscn")

func _delete_preset(file_name: String) -> void:
	DirAccess.remove_absolute("res://presets/" + file_name)
	_refresh_list()

func _on_generate() -> void:
	get_tree().change_scene_to_file("res://src/scenes/preset/preset_generator.tscn")

func _on_delete_all() -> void:
	var dir := DirAccess.open("res://presets")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	_refresh_list()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
