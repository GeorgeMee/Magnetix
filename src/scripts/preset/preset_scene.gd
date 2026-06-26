class_name PresetScene
extends Node2D

@onready var btn_left: Button = %BtnLeft
@onready var btn_right: Button = %BtnRight
@onready var btn_reset: Button = %BtnReset
@onready var btn_edit: Button = %BtnEdit
@onready var btn_save: Button = %BtnSave
@onready var edit_panel: Panel = %EditPanel
@onready var edit_label: Label = %EditLabel
@onready var btn_count_minus: Button = %BtnCountMinus
@onready var btn_count_plus: Button = %BtnCountPlus
@onready var btn_height_minus: Button = %BtnHeightMinus
@onready var btn_height_plus: Button = %BtnHeightPlus
@onready var btn_polarity: Button = %BtnPolarity
@onready var btn_placement: Button = %BtnPlacement
@onready var btn_x_minus: Button = %BtnXMinus
@onready var btn_x_plus: Button = %BtnXPlus

var preset: PresetData
var _file_path: String = ""
var camera_offset: float = 0.0
var edit_mode: bool = false
var selected_idx: int = -1
var selected_type: String = ""

func _ready() -> void:
	btn_left.pressed.connect(func(): camera_offset += 320.0; queue_redraw())
	btn_right.pressed.connect(func(): camera_offset -= 320.0; queue_redraw())
	btn_reset.pressed.connect(func(): camera_offset = 0.0; queue_redraw())
	btn_edit.pressed.connect(_toggle_edit)
	btn_save.pressed.connect(_save_preset)
	btn_count_minus.pressed.connect(_mod_count.bind(-1))
	btn_count_plus.pressed.connect(_mod_count.bind(1))
	btn_height_minus.pressed.connect(_mod_height.bind(-1))
	btn_height_plus.pressed.connect(_mod_height.bind(1))
	btn_polarity.pressed.connect(_toggle_polarity)
	btn_placement.pressed.connect(_toggle_placement)
	btn_x_minus.pressed.connect(_mod_x.bind(-20.0))
	btn_x_plus.pressed.connect(_mod_x.bind(20.0))
	edit_panel.visible = false

	if not GameManager.pending_preset_path.is_empty():
		_file_path = GameManager.pending_preset_path
		load_preset(load(_file_path) as PresetData)
		GameManager.pending_preset_path = ""

func load_preset(data: PresetData) -> void:
	if not data:
		push_error("PresetScene: 加载预设失败，数据为 null")
		preset = null
	else:
		preset = data
		push_warning("PresetScene: 已加载 %s, 轨迹点=%d, 磁铁=%d, 墙=%d, 地刺=%d, 金币=%d" % [data.preset_name, data.trajectory.size(), data.magnet_blocks.size(), data.walls.size(), data.hazards.size(), data.coins.size()])
	camera_offset = 0.0
	_clear_selection()
	queue_redraw()

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
	if preset.magnet_blocks.size() > 0:
		_draw_magnets(lane_top, lane_bot, coff)
	if preset.walls.size() > 0:
		_draw_walls(lane_top, lane_bot, coff)
	if preset.hazards.size() > 0:
		_draw_hazards(lane_top, lane_bot, coff)
	if preset.coins.size() > 0:
		_draw_coins(lane_top, lane_bot, coff)

	var w := preset.width
	draw_line(Vector2(w - camera_offset, 0), Vector2(w - camera_offset, get_viewport().get_visible_rect().size.y), Color(Color.WHITE, 0.3), 1.0)

func _draw_lane(floor_y: float, coff: float, vp_w: float) -> void:
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), Color.GRAY, 2.0)
	draw_line(Vector2(0, floor_y - coff), Vector2(vp_w, floor_y - coff), Color.GRAY.darkened(0.4), 1.0)

func _draw_trajectory(lane_top: float, lane_bot: float, coff: float) -> void:
	var traj := preset.trajectory
	if traj.size() < 2:
		return
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

func _draw_magnets(lane_top: float, lane_bot: float, coff: float) -> void:
	for i in range(preset.magnet_blocks.size()):
		var m := preset.magnet_blocks[i]
		var lane_y := lane_top if m.lane == 0 else lane_bot
		var sx := m.world_x - camera_offset
		var col := Color.BLUE if m.polarity == Magnet.Polarity.NORTH else Color.RED

		if i == selected_idx and selected_type == "magnet":
			draw_rect(Rect2(Vector2(sx - 2, lane_y - coff - 2), Vector2(m.length + 4, coff + 4)), Color.WHITE, false, 3.0)

		var field_col := col.darkened(0.5)
		field_col.a = 0.25
		draw_rect(Rect2(Vector2(sx, lane_y - coff), Vector2(m.length, coff)), field_col)

		var bar_h := 16.0
		var bar_y: float
		var arrow_dir: float
		if m.placement == Magnet.Placement.FLOOR:
			bar_y = lane_y - bar_h
			arrow_dir = -1.0
		else:
			bar_y = lane_y - coff
			arrow_dir = 1.0
		draw_rect(Rect2(Vector2(sx, bar_y), Vector2(m.length, bar_h)), col)

		var mid_x := sx + m.length * 0.5
		var arrow_y := bar_y + bar_h * 0.5
		for j in range(3):
			var off := (j - 1) * 8.0
			draw_line(Vector2(mid_x + off, arrow_y), Vector2(mid_x + off, arrow_y + arrow_dir * 14.0), col, 2.0)

func _draw_walls(lane_top: float, lane_bot: float, coff: float) -> void:
	for i in range(preset.walls.size()):
		var w := preset.walls[i]
		var lane_y := lane_top if w.lane == 0 else lane_bot
		var unit_w := 32.0
		var unit_h := 64.0
		var sx := w.world_x - camera_offset
		var sy := lane_y - unit_h * w.height_units

		if i == selected_idx and selected_type == "wall":
			draw_rect(Rect2(Vector2(sx - 2, sy - 2), Vector2(unit_w * w.count + 4, unit_h * w.height_units + 4)), Color.WHITE, false, 3.0)

		for j in range(w.count):
			draw_rect(Rect2(Vector2(sx + j * unit_w, sy), Vector2(unit_w, unit_h * w.height_units)), Color.DIM_GRAY)
			draw_rect(Rect2(Vector2(sx + j * unit_w, sy), Vector2(unit_w, unit_h * w.height_units)), Color.BLACK, false, 2.0)

func _draw_hazards(lane_top: float, lane_bot: float, coff: float) -> void:
	for i in range(preset.hazards.size()):
		var h := preset.hazards[i]
		var lane_y := lane_top if h.lane == 0 else lane_bot
		var unit_w := 24.0
		var unit_h := 24.0
		var sx := h.world_x - camera_offset
		var sy := lane_y - unit_h
		var hw := unit_w * 0.5

		if i == selected_idx and selected_type == "hazard":
			draw_rect(Rect2(Vector2(sx - 2, sy - 2), Vector2(unit_w * h.count + 4, unit_h + 4)), Color.WHITE, false, 3.0)

		for j in range(h.count):
			var x := sx + j * unit_w
			var p := PackedVector2Array([Vector2(x, sy + unit_h), Vector2(x + hw, sy), Vector2(x + unit_w, sy + unit_h)])
			draw_colored_polygon(p, Color.RED)
			draw_line(Vector2(x + hw - 4, sy + 9.6), Vector2(x + hw + 4, sy + 9.6), Color.YELLOW, 2.0)

func _draw_coins(lane_top: float, lane_bot: float, coff: float) -> void:
	for c in preset.coins:
		var lane_y := lane_top if c.lane == 0 else lane_bot
		var sx := c.world_x - camera_offset
		var sy := lane_y - c.y_off
		var col := Color.DODGER_BLUE
		if c.coin_type == Coin.Type.RED:
			col = Color.ORANGE_RED
		elif c.coin_type == Coin.Type.RAINBOW:
			col = Color.from_hsv(fmod(sx * 0.01, 1.0), 1.0, 1.0)
		var h := 8.0
		var p := PackedVector2Array([Vector2(-h, 0), Vector2(0, h), Vector2(h, 0), Vector2(0, -h)])
		for k in range(4):
			p[k] += Vector2(sx, sy)
		draw_colored_polygon(p, col)

func _toggle_edit() -> void:
	edit_mode = not edit_mode
	btn_edit.text = "编辑:开" if edit_mode else "编辑:关"
	if not edit_mode:
		_clear_selection()

func _clear_selection() -> void:
	selected_idx = -1
	selected_type = ""
	edit_panel.visible = false
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		camera_offset += 320.0
		queue_redraw()
	if event.is_action_pressed("ui_right"):
		camera_offset -= 320.0
		queue_redraw()

	if event is InputEventMouseButton and event.pressed and edit_mode:
		var mx : float = event.position.x + camera_offset
		var my : float = event.position.y
		_select_at(mx, my)

func _select_at(wx: float, wy: float) -> void:
	var coff := GameManager.ceiling_offset
	var lane_top := GameManager.lane_top_y
	var lane_bot := GameManager.lane_bottom_y

	for i in range(preset.magnet_blocks.size()):
		var m := preset.magnet_blocks[i]
		var lane_y := lane_top if m.lane == 0 else lane_bot
		if wx >= m.world_x and wx <= m.world_x + m.length and wy >= lane_y - coff and wy <= lane_y:
			selected_idx = i
			selected_type = "magnet"
			_show_edit_panel()
			queue_redraw()
			return
	for i in range(preset.walls.size()):
		var w := preset.walls[i]
		var lane_y := lane_top if w.lane == 0 else lane_bot
		var unit_w := 32.0 * w.count
		var unit_h := 64.0 * w.height_units
		if wx >= w.world_x and wx <= w.world_x + unit_w and wy >= lane_y - unit_h and wy <= lane_y:
			selected_idx = i
			selected_type = "wall"
			_show_edit_panel()
			queue_redraw()
			return
	for i in range(preset.hazards.size()):
		var h := preset.hazards[i]
		var lane_y := lane_top if h.lane == 0 else lane_bot
		var unit_w := 24.0 * h.count
		if wx >= h.world_x and wx <= h.world_x + unit_w and wy >= lane_y - 24.0 and wy <= lane_y:
			selected_idx = i
			selected_type = "hazard"
			_show_edit_panel()
			queue_redraw()
			return
	_clear_selection()

func _show_edit_panel() -> void:
	edit_panel.visible = true
	match selected_type:
		"magnet":
			var m := preset.magnet_blocks[selected_idx]
			edit_label.text = "磁铁 x=%.0f" % m.world_x
			btn_polarity.text = "N" if m.polarity == Magnet.Polarity.NORTH else "S"
			btn_placement.text = "地板" if m.placement == Magnet.Placement.FLOOR else "天花"
			_set_edit_buttons(false, false, true, true)
		"wall", "hazard":
			var obs: ObstacleBlock = preset.walls[selected_idx] if selected_type == "wall" else preset.hazards[selected_idx]
			edit_label.text = "%s x=%.0f" % [("墙" if selected_type == "wall" else "地刺"), obs.world_x]
			btn_count_minus.text = "宽-"
			btn_count_plus.text = "宽+"
			btn_height_minus.text = "高-"
			btn_height_plus.text = "高+"
			_set_edit_buttons(true, true, true, true)
	btn_polarity.visible = selected_type == "magnet"
	btn_placement.visible = selected_type == "magnet"
	btn_count_minus.visible = selected_type != "magnet"
	btn_count_plus.visible = selected_type != "magnet"
	btn_height_minus.visible = selected_type != "magnet"
	btn_height_plus.visible = selected_type != "magnet"

func _set_edit_buttons(show_count: bool, show_height: bool, show_x: bool, _unused: bool) -> void:
	pass

func _mod_count(delta: int) -> void:
	var obs: ObstacleBlock
	if selected_type == "wall":
		obs = preset.walls[selected_idx]
	else:
		obs = preset.hazards[selected_idx]
	obs.count = max(1, obs.count + delta)
	queue_redraw()

func _mod_height(delta: int) -> void:
	if selected_type != "wall":
		return
	var obs := preset.walls[selected_idx]
	obs.height_units = max(1, obs.height_units + delta)
	queue_redraw()

func _toggle_polarity() -> void:
	var m := preset.magnet_blocks[selected_idx]
	m.polarity = Magnet.Polarity.SOUTH if m.polarity == Magnet.Polarity.NORTH else Magnet.Polarity.NORTH
	_show_edit_panel()
	queue_redraw()

func _toggle_placement() -> void:
	var m := preset.magnet_blocks[selected_idx]
	m.placement = Magnet.Placement.CEILING if m.placement == Magnet.Placement.FLOOR else Magnet.Placement.FLOOR
	_show_edit_panel()
	queue_redraw()

func _mod_x(delta: float) -> void:
	if selected_type == "magnet":
		preset.magnet_blocks[selected_idx].world_x += delta
	elif selected_type == "wall":
		preset.walls[selected_idx].world_x += delta
	elif selected_type == "hazard":
		preset.hazards[selected_idx].world_x += delta
	_show_edit_panel()
	queue_redraw()

func _save_preset() -> void:
	if not preset or _file_path.is_empty():
		return
	ResourceSaver.save(preset, _file_path)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
