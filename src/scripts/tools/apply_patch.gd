@tool
extends Node

func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
	_patch_file("res://src/scripts/preset/preset_generator.gd")
	_patch_file("res://src/scripts/preset/preset_scene.gd")
	print_rich("[color=green]Patch applied![/color]")
	queue_free()

func _patch_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return
	var s := f.get_as_text()
	f.close()

	if path.ends_with("preset_generator.gd"):
		s = _fix_generator(s)
	elif path.ends_with("preset_scene.gd"):
		s = _fix_scene(s)

	f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(s)
		f.close()

func _fix_generator(s: String) -> String:
	var old = """for w in layout.walls:
		var obs := ObstacleBlock.new()
		obs.world_x = w["world_x"]
		obs.lane = lane
		walls.append(obs)
	for h in layout.hazards:
		var obs := ObstacleBlock.new()
		obs.world_x = h["world_x"]
		obs.lane = lane
		hazards.append(obs)"""
	var rep = """for w in layout.walls:
		var obs := ObstacleBlock.new()
		obs.world_x = w["world_x"]
		obs.lane = lane
		obs.count = 1
		obs.height_units = 1
		walls.append(obs)
	for h in layout.hazards:
		var obs := ObstacleBlock.new()
		obs.world_x = h["world_x"]
		obs.lane = lane
		obs.count = 1
		hazards.append(obs)"""
	s = s.replace(old, rep)

	old = """func _transition_back() -> void:
	transitioned = true
	GameManager.character_a = null
	GameManager.character_b = null
	get_tree().change_scene_to_file("res://src/scenes/preset/preset_viewer.tscn")"""
	rep = """func _transition_back() -> void:
	transitioned = true
	GameManager.character_a = null
	GameManager.character_b = null
	GameManager.physics_system = null
	GameManager.scroll_manager = null
	GameManager.magnet_manager = null
	GameManager.choreographer = null
	GameManager.state = GameManager.GameState.MENU
	get_tree().change_scene_to_file("res://src/scenes/preset/preset_viewer.tscn")"""
	s = s.replace(old, rep)
	return s

func _fix_scene(s: String) -> String:
	var old = """	btn_save.pressed.connect(_save_preset)

	if not GameManager.pending_preset_path.is_empty():"""
	var rep = """	btn_save.pressed.connect(_save_preset)

	GameManager.state = GameManager.GameState.MENU
	if not GameManager.pending_preset_path.is_empty():"""
	s = s.replace(old, rep)

	old = """	elif type_name == "hazard":
			node.position.y = lane_y - 24.0"""
	rep = """	elif type_name == "hazard":
			node.position.y = lane_y - node.unit_height"""
	s = s.replace(old, rep)
	return s