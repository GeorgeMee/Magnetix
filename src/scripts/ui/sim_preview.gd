class_name SimPreview
extends Node2D

const TRANSITION_SPEED := 400.0
const FALL_GRAVITY := 800.0

var sim_ai : SimAI
var choreographer : ChunkChoreographer
var trajectory : Array[TrajectoryPoint] = []
var sim_time : float = 0.0
var sim_speed : float = 100.0
var playing : bool = true
var total_length : float = 5000.0
var last_surf_a := SimAI.Surface.FLOOR
var last_surf_b := SimAI.Surface.FLOOR
var last_flip_time_a : float = -9999.0
var last_flip_time_b : float = -9999.0
var prev_surf_a := SimAI.Surface.FLOOR
var prev_surf_b := SimAI.Surface.FLOOR

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

		var cur_a := _get_surface_at(sim_time, 0)
		var cur_b := _get_surface_at(sim_time, 1)
		if cur_a != prev_surf_a:
			last_flip_time_a = _find_flip_point(sim_time, 0)
			last_surf_a = prev_surf_a
		if cur_b != prev_surf_b:
			last_flip_time_b = _find_flip_point(sim_time, 1)
			last_surf_b = prev_surf_b
		prev_surf_a = cur_a
		prev_surf_b = cur_b
	queue_redraw()

func _find_flip_point(wx : float, lane : int) -> float:
	var last_flip := -1.0
	for i in range(1, trajectory.size()):
		if trajectory[i].world_x > wx:
			break
		var s := trajectory[i].char_a_surface if lane == 0 else trajectory[i].char_b_surface
		var ps := trajectory[i - 1].char_a_surface if lane == 0 else trajectory[i - 1].char_b_surface
		if s != ps:
			last_flip = trajectory[i].world_x
	return wx if last_flip < 0.0 else last_flip

func _on_speed_changed(value : float) -> void:
	sim_speed = value
	speed_label.text = "速度: %d" % int(value)

func _on_play_toggle() -> void:
	playing = not playing
	btn_play.text = "暂停" if playing else "播放"

func _feet_y_at(floor_y : float, coff : float, surf : int) -> float:
	return floor_y if surf == SimAI.Surface.FLOOR else floor_y - coff

func _smooth_feet_y_at(wx : float, floor_y : float, coff : float, lane : int) -> float:
	var surf := _get_surface_at(wx, lane)
	var flip_wx := _find_flip_point(wx, lane)
	if flip_wx < 0.0:
		return _feet_y_at(floor_y, coff, surf)
	var old_surf := _get_surface_at(flip_wx - 0.1, lane)
	var elapsed := wx - flip_wx
	var speed := TRANSITION_SPEED if old_surf == SimAI.Surface.FLOOR else FALL_GRAVITY
	var td := sim_speed * coff / speed
	if elapsed >= td or elapsed < 0.0:
		return _feet_y_at(floor_y, coff, surf)
	var progress := elapsed / td
	var old_y := _feet_y_at(floor_y, coff, old_surf)
	var new_y := _feet_y_at(floor_y, coff, surf)
	return lerpf(old_y, new_y, progress)

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
	var speed := TRANSITION_SPEED if old_surf == SimAI.Surface.FLOOR else FALL_GRAVITY
	var td := sim_speed * coff / speed
	if elapsed >= td or elapsed < 0.0:
		return target_y
	var progress := clampf(elapsed / td, 0.0, 1.0)
	var old_y := _feet_y_at(floor_y, coff, old_surf)
	return lerpf(old_y, target_y, progress)

func _draw() -> void:
	var vp_w := get_viewport().get_visible_rect().size.x

	var lane_top := GameManager.lane_top_y
	var lane_bot := GameManager.lane_bottom_y
	var coff := GameManager.ceiling_offset
	var px := GameManager.player_fixed_x
	var char_w := Character.CHAR_WIDTH
	var char_h := Character.CHAR_HEIGHT

	_draw_lane(lane_top, coff, vp_w)
	_draw_lane(lane_bot, coff, vp_w)
	_draw_level(lane_top, lane_bot, coff, vp_w)
	_draw_trajectory_path(lane_top, lane_bot, coff, vp_w, char_h)
	_draw_characters(lane_top, lane_bot, coff, vp_w, px, char_w, char_h)

	draw_rect(Rect2(Vector2(0, 0), Vector2(vp_w, 60)), Color(Color.BLACK, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(20, 30), "Sim AI 轨迹  —  %d 决策点  —  间隔 %dpx" % [trajectory.size(), int(GameManager.sim_decision_interval)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

func _draw_lane(floor_y : float, coff : float, vp_w : float) -> void:
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), Color.WEB_GREEN, 2.0)
	draw_line(Vector2(0, floor_y - coff), Vector2(vp_w, floor_y - coff), Color.WEB_GREEN.darkened(0.4), 1.0)

func _draw_level(lane_top : float, lane_bot : float, coff : float, vp_w : float) -> void:
	var vis_start_x := sim_time - GameManager.player_fixed_x
	var vis_end_x := sim_time + vp_w - GameManager.player_fixed_x
	for entry in layout_cache:
		var layout := entry["layout"] as ChunkLayout
		var lane_y := lane_top if entry["lane"] == 0 else lane_bot
		_draw_magnets_in_layout(layout, lane_y, coff, vp_w, vis_start_x, vis_end_x)
		_draw_walls_in_layout(layout, lane_y, vp_w, vis_start_x, vis_end_x)
		_draw_coins_in_layout(layout, lane_y, vp_w, vis_start_x, vis_end_x)
		_draw_hazards_in_layout(layout, lane_y, vp_w, vis_start_x, vis_end_x)

func _world_to_sx(wx : float) -> float:
	return GameManager.player_fixed_x + (wx - sim_time)

func _in_view(sx : float, vp_w : float) -> bool:
	return sx > -50 and sx < vp_w + 50

func _draw_magnets_in_layout(layout : ChunkLayout, lane_y : float, coff : float, vp_w : float, vx0 : float, vx1 : float) -> void:
	for m in layout.magnets:
		var wx : float = m["world_x"]
		if wx < vx0 - 200 or wx > vx1 + 200:
			continue
		var sx := _world_to_sx(wx)
		var len : float = m["length"]
		var col := Color.BLUE if m["polarity"] == Magnet.Polarity.NORTH else Color.RED
		var field_col := col.darkened(0.5)
		field_col.a = 0.3
		draw_rect(Rect2(Vector2(sx, lane_y - coff), Vector2(len, coff)), field_col)
		var mag_y : float
		if m["placement"] == Magnet.Placement.CEILING:
			mag_y = lane_y - coff
		else:
			mag_y = lane_y - 16.0
		draw_rect(Rect2(Vector2(sx, mag_y), Vector2(len, 16.0)), col)

func _draw_walls_in_layout(layout : ChunkLayout, lane_y : float, vp_w : float, vx0 : float, vx1 : float) -> void:
	for w in layout.walls:
		var wx : float = w["world_x"]
		if wx < vx0 - 200 or wx > vx1 + 200:
			continue
		var sx := _world_to_sx(wx)
		var sy := lane_y - 64.0
		draw_rect(Rect2(Vector2(sx, sy), Vector2(32.0, 64.0)), Color.DIM_GRAY)
		draw_rect(Rect2(Vector2(sx, sy), Vector2(32.0, 64.0)), Color.BLACK, false, 2.0)

func _draw_coins_in_layout(layout : ChunkLayout, lane_y : float, vp_w : float, vx0 : float, vx1 : float) -> void:
	for c in layout.coins:
		var cx : float = c["world_x"]
		if cx < vx0 - 200 or cx > vx1 + 200:
			continue
		var sx := _world_to_sx(cx)
		var sy : float = lane_y - (c["y_off"] as float)
		var col := Color.DODGER_BLUE
		var ct : int = c["type"]
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
		var hx : float = h["world_x"]
		if hx < vx0 - 200 or hx > vx1 + 200:
			continue
		var sx := _world_to_sx(hx)
		var sy := lane_y - 24.0
		var hw := 12.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx, sy + 24), Vector2(sx + hw, sy), Vector2(sx + 24, sy + 24)]), Color.RED)
		draw_line(Vector2(sx + hw - 4, sy + 9.6), Vector2(sx + hw + 4, sy + 9.6), Color.YELLOW, 2.0)

func _draw_trajectory_path(lane_top : float, lane_bot : float, coff : float, vp_w : float, char_h : float) -> void:
	if trajectory.size() < 2:
		return
	var px := GameManager.player_fixed_x
	var step := 5.0
	var wx0 := sim_time - px
	var wx1 := sim_time + vp_w - px
	wx0 = maxf(wx0, trajectory[0].world_x)
	wx1 = minf(wx1, trajectory[-1].world_x)

	var prev_sx_a := 0.0; var prev_sy_a := 0.0; var first_a := true
	var prev_sx_b := 0.0; var prev_sy_b := 0.0; var first_b := true

	var wx := wx0
	while wx <= wx1:
		var sx := px + (wx - sim_time)
		var fy_a := _smooth_feet_y_at(wx, lane_top, coff, 0)
		var fy_b := _smooth_feet_y_at(wx, lane_bot, coff, 1)
		if not first_a:
			draw_line(Vector2(prev_sx_a, prev_sy_a), Vector2(sx, fy_a), Color(Color.DODGER_BLUE, 0.15), 2.0)
		if not first_b:
			draw_line(Vector2(prev_sx_b, prev_sy_b), Vector2(sx, fy_b), Color(Color.ORANGE_RED, 0.15), 2.0)
		prev_sx_a = sx; prev_sy_a = fy_a; first_a = false
		prev_sx_b = sx; prev_sy_b = fy_b; first_b = false
		wx += step

	for pt in trajectory:
		var sx := px + (pt.world_x - sim_time)
		if sx > 0 and sx < vp_w:
			if pt.swap_trigger:
				draw_circle(Vector2(sx, lane_top - coff * 0.5), 6.0, Color.YELLOW)
			if pt.magnet_a_trigger:
				draw_circle(Vector2(sx, lane_top - 10), 4.0, Color.WHITE)
			if pt.magnet_b_trigger:
				draw_circle(Vector2(sx, lane_bot - 10), 4.0, Color.WHITE)

func _draw_characters(lane_top : float, lane_bot : float, coff : float, vp_w : float, px : float, char_w : float, char_h : float) -> void:
	var fy_a := _smooth_feet_y(lane_top, coff, char_h, 0)
	var fy_b := _smooth_feet_y(lane_bot, coff, char_h, 1)

	var on_ceil_a := fy_a < lane_top - coff * 0.5
	var on_ceil_b := fy_b < lane_bot - coff * 0.5

	var ay := fy_a if on_ceil_a else fy_a - char_h
	var by := fy_b if on_ceil_b else fy_b - char_h

	var color_a := Color.DODGER_BLUE.lightened(0.3) if on_ceil_a else Color.DODGER_BLUE
	var color_b := Color.ORANGE_RED.lightened(0.3) if on_ceil_b else Color.ORANGE_RED

	draw_rect(Rect2(Vector2(px, ay), Vector2(char_w, char_h)), color_a)
	draw_rect(Rect2(Vector2(px, ay), Vector2(char_w, char_h)), Color.BLACK, false, 2.0)
	if on_ceil_a:
		draw_line(Vector2(px, ay + 4), Vector2(px + char_w, ay + char_h - 4), Color.WHITE, 1.0)
	else:
		draw_line(Vector2(px, ay + 4), Vector2(px + char_w, ay + 4), Color.RED, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(px + char_w + 4, fy_a - 12), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

	draw_rect(Rect2(Vector2(px, by), Vector2(char_w, char_h)), color_b)
	draw_rect(Rect2(Vector2(px, by), Vector2(char_w, char_h)), Color.BLACK, false, 2.0)
	if on_ceil_b:
		draw_line(Vector2(px, by + 4), Vector2(px + char_w, by + char_h - 4), Color.WHITE, 1.0)
	else:
		draw_line(Vector2(px, by + 4), Vector2(px + char_w, by + 4), Color.RED, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(px + char_w + 4, fy_b - 12), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
	if event.is_action_pressed("swap"):
		_regenerate()
