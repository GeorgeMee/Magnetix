class_name PresetScene
extends Node2D

@onready var btn_left: Button = %BtnLeft
@onready var btn_right: Button = %BtnRight
@onready var btn_reset: Button = %BtnReset
@onready var btn_edit: Button = %BtnEdit
@onready var btn_save: Button = %BtnSave

var preset: PresetData
var _file_path: String = ""
var camera_offset: float = 0.0
var edit_mode: bool = false

func _ready() -> void:
	btn_left.pressed.connect(func(): camera_offset -= 320.0; _apply_camera())
	btn_right.pressed.connect(func(): camera_offset += 320.0; _apply_camera())
	btn_reset.pressed.connect(func(): camera_offset = _calc_auto_center(); _apply_camera())
	btn_edit.pressed.connect(_toggle_edit)
	btn_save.pressed.connect(_save_preset)

	GameManager.state = GameManager.GameState.MENU
	if not GameManager.pending_preset_path.is_empty():
		_file_path = GameManager.pending_preset_path
		load_preset(load(_file_path) as PresetData)
		GameManager.pending_preset_path = ""

func _apply_camera() -> void:
	queue_redraw()
	for child in get_children():
		if child is CanvasLayer:
			continue
		if child is Magnet or child is Wall or child is Hazard or child is Coin:
			child.position.x = child.world_x - camera_offset

func load_preset(data: PresetData) -> void:
	for child in get_children():
		if child is Magnet or child is Wall or child is Hazard or child is Coin:
			child.queue_free()

	if not data:
		preset = null
		camera_offset = 0.0
		queue_redraw()
		return

	preset = data
	_spawn_objects()
	camera_offset = _calc_auto_center()
	_apply_camera()

func _spawn_objects() -> void:
	_spawn_type(preset.magnet_blocks, preload("res://src/scenes/game/magnet.tscn"), "magnet")
	_spawn_type(preset.walls, preload("res://src/scenes/game/wall.tscn"), "wall")
	_spawn_type(preset.hazards, preload("res://src/scenes/game/hazard.tscn"), "hazard")
	_spawn_type(preset.coins, preload("res://src/scenes/game/coin.tscn"), "coin")

func _spawn_type(blocks: Array, pscene: PackedScene, type_name: String) -> void:
	for block in blocks:
		var node := pscene.instantiate()
		var bx: float = block.world_x
		var bl: int = block.lane
		match type_name:
			"magnet":
				node.setup(bx, bl, block.placement, block.polarity, block.length)
			"wall", "hazard":
				node.setup(bx, bl)
				node.count = block.count
				if type_name == "wall":
					node.height_units = block.height_units
			"coin":
				node.setup(bx, bl, block.coin_type, block.y_off)
		node.position.x = bx - camera_offset
		var lane_y := GameManager.lane_top_y if bl == 0 else GameManager.lane_bottom_y
		if type_name == "wall":
			node.position.y = lane_y - node.height_units * 64.0
		elif type_name == "hazard":
			node.position.y = lane_y - node.unit_height
		elif type_name == "magnet":
			node.position.y = lane_y
		elif type_name == "coin":
			node.position.y = lane_y - block.y_off
		add_child(node)

func _calc_auto_center() -> float:
	if not preset:
		return 0.0
	var min_wx := 1e7
	if preset.trajectory.size() > 0:
		min_wx = minf(min_wx, preset.trajectory[0].world_x)
	for mb in preset.magnet_blocks:
		min_wx = minf(min_wx, mb.world_x)
	for w in preset.walls:
		min_wx = minf(min_wx, w.world_x)
	for h in preset.hazards:
		min_wx = minf(min_wx, h.world_x)
	for c in preset.coins:
		min_wx = minf(min_wx, c.world_x)
	if min_wx < 1e6:
		return min_wx - 200.0
	return 0.0

func _draw() -> void:
	var lane_top := GameManager.lane_top_y
	var lane_bot := GameManager.lane_bottom_y
	var coff := GameManager.ceiling_offset
	var vp_w := get_viewport().get_visible_rect().size.x

	_draw_lane(lane_top, coff, vp_w)
	_draw_lane(lane_bot, coff, vp_w)

	if not preset:
		draw_string(ThemeDB.fallback_font, Vector2(20, 100), "未加载预设数据", HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		return

	if preset.trajectory.size() >= 2:
		_draw_trajectory(lane_top, lane_bot, coff)

	var w := preset.width
	draw_line(Vector2(w - camera_offset, 0), Vector2(w - camera_offset, get_viewport().get_visible_rect().size.y), Color(Color.WHITE, 0.3), 1.0)

func _draw_lane(floor_y: float, coff: float, vp_w: float) -> void:
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), Color.GRAY, 2.0)
	draw_line(Vector2(0, floor_y - coff), Vector2(vp_w, floor_y - coff), Color.GRAY.darkened(0.4), 1.0)

func _draw_trajectory(lane_top: float, lane_bot: float, coff: float) -> void:
	var traj := preset.trajectory
	for i in range(traj.size() - 1):
		var pt0 := traj[i]
		var pt1 := traj[i + 1]
		var sx0 := pt0.world_x - camera_offset
		var sx1 := pt1.world_x - camera_offset
		var fy0_a := lane_top if pt0.char_a_surface == SimAI.Surface.FLOOR else lane_top - coff
		var fy1_a := lane_top if pt1.char_a_surface == SimAI.Surface.FLOOR else lane_top - coff
		draw_line(Vector2(sx0, fy0_a), Vector2(sx1, fy1_a), Color(Color.DODGER_BLUE, 0.15), 2.0)
		var fy0_b := lane_bot if pt0.char_b_surface == SimAI.Surface.FLOOR else lane_bot - coff
		var fy1_b := lane_bot if pt1.char_b_surface == SimAI.Surface.FLOOR else lane_bot - coff
		draw_line(Vector2(sx0, fy0_b), Vector2(sx1, fy1_b), Color(Color.ORANGE_RED, 0.15), 2.0)
	for pt in traj:
		var sx := pt.world_x - camera_offset
		if pt.swap_trigger:
			draw_circle(Vector2(sx, lane_top - coff * 0.5), 6.0, Color.YELLOW)
		if pt.magnet_a_trigger:
			draw_circle(Vector2(sx, lane_top - 10), 4.0, Color.WHITE)
		if pt.magnet_b_trigger:
			draw_circle(Vector2(sx, lane_bot - 10), 4.0, Color.WHITE)

func _toggle_edit() -> void:
	edit_mode = not edit_mode
	btn_edit.text = "编辑:开" if edit_mode else "编辑:关"

func _save_preset() -> void:
	if not preset or _file_path.is_empty():
		return
	ResourceSaver.save(preset, _file_path)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		camera_offset -= 320.0
		_apply_camera()
	if event.is_action_pressed("ui_right"):
		camera_offset += 320.0
		_apply_camera()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
