class_name SimPreview
extends Node2D

var sim_ai : SimAI
var choreographer : ChunkChoreographer
var trajectory : Array[TrajectoryPoint] = []
var sim_time : float = 0.0
var sim_speed : float = 100.0
var playing : bool = true
var total_length : float = 5000.0
var char_x : float = 400.0
var transition_dist : float = 260.0
var last_surf_a := SimAI.Surface.FLOOR
var last_surf_b := SimAI.Surface.FLOOR
var last_flip_time_a : float = -9999.0
var last_flip_time_b : float = -9999.0
var prev_surf_a := SimAI.Surface.FLOOR
var prev_surf_b := SimAI.Surface.FLOOR
var prev_check_time : float = -9999.0

var layout_cache : Array[Dictionary] = []

@onready var speed_slider : HSlider = %SpeedSlider
@onready var speed_label : Label = %SpeedLabel
@onready var btn_play : Button = %BtnPlay

func _ready() -> void:
	sim_ai = SimAI.new()
	choreographer = ChunkChoreographer.new()
	add_child(choreographer)
	_regenerate()
	speed_slider.value = sim_speed
	speed_slider.value_changed.connect(_on_speed_changed)
	btn_play.pressed.connect(_on_play_toggle)

func _regenerate() -> void:
	trajectory = sim_ai.generate(Magnet.Polarity.NORTH, Magnet.Polarity.SOUTH, 100.0, total_length, GameManager.sim_decision_interval)
	sim_time = 0.0
	last_surf_a = SimAI.Surface.FLOOR
	last_surf_b = SimAI.Surface.FLOOR
	last_flip_time_a = -9999.0
	last_flip_time_b = -9999.0
	prev_surf_a = SimAI.Surface.FLOOR
	prev_surf_b = SimAI.Surface.FLOOR
	prev_check_time = -9999.0
	_build_layouts()

func _build_layouts() -> void:
	layout_cache.clear()
	var chunk_w := GameManager.chunk_width
	var num_chunks := int(ceilf(total_length / chunk_w))
	for ci in range(num_chunks):
		var wx := float(ci) * chunk_w
		for lane in [0, 1]:
			var pol := Magnet.Polarity.NORTH if lane == 0 else Magnet.Polarity.SOUTH
			var layout := choreographer.build_layout(trajectory, wx, lane, chunk_w, pol)
			layout_cache.append({"lane": lane, "layout": layout})

func _process(delta : float) -> void:
	if playing:
		sim_time += sim_speed * delta
		if sim_time > total_length:
			sim_time -= total_length
			last_flip_time_a -= total_length
			last_flip_time_b -= total_length
			prev_check_time -= total_length

		if sim_time - prev_check_time > 0.05:
			var cur_a := _get_surface_at(sim_time, 0)
			var cur_b := _get_surface_at(sim_time, 1)
			if cur_a != prev_surf_a:
				last_flip_time_a = sim_time
				last_surf_a = prev_surf_a
			if cur_b != prev_surf_b:
				last_flip_time_b = sim_time
				last_surf_b = prev_surf_b
			prev_surf_a = cur_a
			prev_surf_b = cur_b
			prev_check_time = sim_time
	queue_redraw()

func _on_speed_changed(value : float) -> void:
	sim_speed = value
	speed_label.text = "速度: %d" % int(value)

func _on_play_toggle() -> void:
	playing = not playing
	btn_play.text = "暂停" if playing else "播放"

func _feet_y_at(floor_y : float, coff : float, surf : int) -> float:
	return floor_y if surf == SimAI.Surface.FLOOR else floor_y - coff

func _get_surface_at(world_x : float, lane : int) -> int:
	var current := SimAI.Surface.FLOOR
	for i in range(trajectory.size()):
		if trajectory[i].world_x > world_x:
			break
		current = trajectory[i].char_a_surface if lane == 0 else trajectory[i].char_b_surface
	return current

func _smooth_feet_y(floor_y : float, coff : float, char_h : float, lane : int) -> float:
	var surf := _get_surface_at(sim_time, lane)
	var target_y := _feet_y_at(floor_y, coff, surf)
	var last_flip := last_flip_time_a if lane == 0 else last_flip_time_b
	var old_surf := last_surf_a if lane == 0 else last_surf_b
	var elapsed := sim_time - last_flip
	if elapsed >= transition_dist or elapsed < 0.0:
		return target_y
	var progress := clampf(elapsed / transition_dist, 0.0, 1.0)
	progress = ease(progress, 0.5)
	var old_y := _feet_y_at(floor_y, coff, old_surf)
	return lerpf(old_y, target_y, progress)

func _draw() -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	var vp_h := get_viewport().get_visible_rect().size.y
	var lane_top := vp_h * 0.28
	var lane_bot := vp_h * 0.63
	var coff := 180.0
	var char_w := Character.CHAR_WIDTH
	var char_h := Character.CHAR_HEIGHT

	_draw_lane(lane_top, coff, vp_w)
	_draw_lane(lane_bot, coff, vp_w)
	_draw_level(lane_top, lane_bot, coff, vp_w)
	_draw_trajectory_path(lane_top, lane_bot, coff, vp_w, char_h)
	_draw_characters(lane_top, lane_bot, coff, vp_w, char_w, char_h)

	draw_rect(Rect2(Vector2(0, 0), Vector2(vp_w, 60)), Color(Color.BLACK, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(20, 30), "Sim AI 轨迹  —  %d 决策点  —  间隔 %dpx" % [trajectory.size(), int(GameManager.sim_decision_interval)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

func _draw_lane(floor_y : float, coff : float, vp_w : float) -> void:
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), Color.WEB_GREEN, 2.0)
	draw_line(Vector2(0, floor_y - coff), Vector2(vp_w, floor_y - coff), Color.WEB_GREEN.darkened(0.4), 1.0)

func _draw_level(lane_top : float, lane_bot : float, coff : float, vp_w : float) -> void:
	var vis_start_x := sim_time - char_x
	var vis_end_x := sim_time + vp_w - char_x
	for entry in layout_cache:
		var layout := entry["layout"] as ChunkLayout
		var lane_y := lane_top if entry["lane"] == 0 else lane_bot
		_draw_magnets_in_layout(layout, lane_y, coff, vp_w, vis_start_x, vis_end_x)
		_draw_walls_in_layout(layout, lane_y, vp_w, vis_start_x, vis_end_x)
		_draw_coins_in_layout(layout, lane_y, vp_w, vis_start_x, vis_end_x)
		_draw_hazards_in_layout(layout, lane_y, vp_w, vis_start_x, vis_end_x)

func _world_to_sx(wx : float) -> float:
	return char_x + (wx - sim_time)

func _in_view(sx : float, vp_w : float) -> bool:
	return sx > -50 and sx < vp_w + 50

func _draw_magnets_in_layout(layout : ChunkLayout, lane_y : float, coff : float, vp_w : float, vx0 : float, vx1 : float) -> void:
	for m in layout.magnets:
		if m["world_x"] < vx0 - 200 or m["world_x"] > vx1 + 200:
			continue
		var sx := _world_to_sx(m["world_x"])
		var sy : float
		if m["placement"] == Magnet.Placement.CEILING:
			sy = lane_y - coff
		else:
			sy = lane_y - 16
		var len := m["length"] as float
		var col := Color.BLUE if m["polarity"] == Magnet.Polarity.NORTH else Color.RED
		draw_rect(Rect2(Vector2(sx, sy), Vector2(len, 16.0)), col, true)

func _draw_walls_in_layout(layout : ChunkLayout, lane_y : float, vp_w : float, vx0 : float, vx1 : float) -> void:
	for w in layout.walls:
		if w["world_x"] < vx0 - 200 or w["world_x"] > vx1 + 200:
			continue
		var sx := _world_to_sx(w["world_x"])
		var sy := lane_y - 64.0
		draw_rect(Rect2(Vector2(sx, sy), Vector2(32.0, 64.0)), Color.DIM_GRAY)
		draw_rect(Rect2(Vector2(sx, sy), Vector2(32.0, 64.0)), Color.BLACK, false, 2.0)

func _draw_coins_in_layout(layout : ChunkLayout, lane_y : float, vp_w : float, vx0 : float, vx1 : float) -> void:
	for c in layout.coins:
		if c["world_x"] < vx0 - 200 or c["world_x"] > vx1 + 200:
			continue
		var sx := _world_to_sx(c["world_x"])
		var sy := lane_y - c["y_off"]
		var col := Color.DODGER_BLUE
		var ct = c["type"]
		if ct == Coin.Type.RED:
			col = Color.ORANGE_RED
		elif ct == Coin.Type.RAINBOW:
			col = Color.from_hsv(fmod(sx * 0.01, 1.0), 1.0, 1.0)
		var h := 8.0
		var p := PackedVector2Array([Vector2(-h, 0), Vector2(0, h), Vector2(h, 0), Vector2(0, -h)])
		for i in range(4):
			p[i] += Vector2(sx, sy)
		draw_colored_polygon(p, col)

func _draw_hazards_in_layout(layout : ChunkLayout, lane_y : float, vp_w : float, vx0 : float, vx1 : float) -> void:
	for h in layout.hazards:
		if h["world_x"] < vx0 - 200 or h["world_x"] > vx1 + 200:
			continue
		var sx := _world_to_sx(h["world_x"])
		var sy := lane_y - 64.0
		var p := PackedVector2Array([Vector2(sx, sy + 64), Vector2(sx + 16, sy), Vector2(sx + 32, sy + 64)])
		draw_colored_polygon(p, Color.RED.darkened(0.3))

func _draw_trajectory_path(lane_top : float, lane_bot : float, coff : float, vp_w : float, char_h : float) -> void:
	if trajectory.size() < 2:
		return
	var prev_sx : float = 0.0
	var prev_fy_a : float = 0.0
	var prev_fy_b : float = 0.0
	var first := true
	for i in range(trajectory.size() - 1):
		var pt0 := trajectory[i]
		var pt1 := trajectory[i + 1]
		for s in range(6):
			var t := float(s) / 6.0
			var wx := lerpf(pt0.world_x, pt1.world_x, t)
			var sx := char_x + (wx - sim_time)
			if sx < -200 or sx > vp_w + 200:
				prev_sx = sx
				continue
			var fy_a := _feet_y_at(lane_top, coff, pt0.char_a_surface)
			var fy_b := _feet_y_at(lane_bot, coff, pt0.char_b_surface)
			if not first and sx > prev_sx - 5:
				draw_line(Vector2(prev_sx, prev_fy_a), Vector2(sx, fy_a), Color(Color.DODGER_BLUE, 0.3), 2.0)
				draw_line(Vector2(prev_sx, prev_fy_b), Vector2(sx, fy_b), Color(Color.ORANGE_RED, 0.3), 2.0)
			prev_sx = sx
			prev_fy_a = fy_a
			prev_fy_b = fy_b
			first = false

	for pt in trajectory:
		var sx := char_x + (pt.world_x - sim_time)
		if sx > 0 and sx < vp_w:
			if pt.swap_trigger:
				draw_circle(Vector2(sx, lane_top - coff * 0.5), 6.0, Color.YELLOW)
			if pt.magnet_a_trigger:
				draw_circle(Vector2(sx, _feet_y_at(lane_top, coff, pt.char_a_surface) - 10), 4.0, Color.WHITE)
			if pt.magnet_b_trigger:
				draw_circle(Vector2(sx, _feet_y_at(lane_bot, coff, pt.char_b_surface) - 10), 4.0, Color.WHITE)

func _draw_characters(lane_top : float, lane_bot : float, coff : float, vp_w : float, char_w : float, char_h : float) -> void:
	var fy_a := _smooth_feet_y(lane_top, coff, char_h, 0)
	var fy_b := _smooth_feet_y(lane_bot, coff, char_h, 1)

	var ay : float
	var by : float
	var flip_a := false
	var flip_b := false

	if fy_a < lane_top - coff * 0.5:
		flip_a = true
		ay = fy_a
	else:
		ay = fy_a - char_h

	if fy_b < lane_bot - coff * 0.5:
		flip_b = true
		by = fy_b
	else:
		by = fy_b - char_h

	var color_a := Color.DODGER_BLUE
	var color_b := Color.ORANGE_RED
	var light_a := Color.DODGER_BLUE.lightened(0.3)
	var light_b := Color.ORANGE_RED.lightened(0.3)

	draw_rect(Rect2(Vector2(char_x, ay), Vector2(char_w, char_h)), color_a if not flip_a else light_a)
	draw_rect(Rect2(Vector2(char_x, ay), Vector2(char_w, char_h)), Color.BLACK, false, 2.0)
	if flip_a:
		draw_line(Vector2(char_x, ay), Vector2(char_x + char_w, ay), Color.RED, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(char_x + char_w + 4, ay + 4), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	else:
		draw_line(Vector2(char_x, ay + char_h), Vector2(char_x + char_w, ay + char_h), Color.RED, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(char_x + char_w + 4, ay + char_h - 12), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

	draw_rect(Rect2(Vector2(char_x, by), Vector2(char_w, char_h)), color_b if not flip_b else light_b)
	draw_rect(Rect2(Vector2(char_x, by), Vector2(char_w, char_h)), Color.BLACK, false, 2.0)
	if flip_b:
		draw_line(Vector2(char_x, by), Vector2(char_x + char_w, by), Color.RED, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(char_x + char_w + 4, by + 4), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	else:
		draw_line(Vector2(char_x, by + char_h), Vector2(char_x + char_w, by + char_h), Color.RED, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(char_x + char_w + 4, by + char_h - 12), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
	if event.is_action_pressed("swap"):
		_regenerate()
