class_name SimPreview
extends Node2D

var sim_ai : SimAI
var trajectory : Array[TrajectoryPoint] = []
var sim_time : float = 0.0
var sim_speed : float = 100.0
var playing : bool = true
var total_length : float = 5000.0
var char_x : float = 400.0

@onready var speed_slider : HSlider = %SpeedSlider
@onready var speed_label : Label = %SpeedLabel
@onready var btn_play : Button = %BtnPlay

func _ready() -> void:
	sim_ai = SimAI.new()
	_regenerate()
	speed_slider.value = sim_speed
	speed_slider.value_changed.connect(_on_speed_changed)
	btn_play.pressed.connect(_on_play_toggle)

func _regenerate() -> void:
	trajectory = sim_ai.generate(Magnet.Polarity.NORTH, Magnet.Polarity.SOUTH, 100.0, total_length, GameManager.sim_decision_interval)
	sim_time = 0.0

func _process(delta : float) -> void:
	if playing:
		sim_time += sim_speed * delta
		if sim_time > total_length:
			sim_time -= total_length
	queue_redraw()

func _on_speed_changed(value : float) -> void:
	sim_speed = value
	speed_label.text = "速度: %d" % int(value)

func _on_play_toggle() -> void:
	playing = not playing
	btn_play.text = "暂停" if playing else "播放"

func _get_surface_at(world_x : float, lane : int) -> int:
	var current := SimAI.Surface.FLOOR
	for i in range(trajectory.size()):
		if trajectory[i].world_x > world_x:
			break
		current = trajectory[i].char_a_surface if lane == 0 else trajectory[i].char_b_surface
	return current

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

	_draw_trajectory_path(lane_top, lane_bot, coff, vp_w)
	_draw_characters(lane_top, lane_bot, coff, vp_w)

	draw_rect(Rect2(Vector2(0, 0), Vector2(vp_w, 60)), Color(Color.BLACK, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(20, 30), "Sim AI 轨迹  —  %d 决策点  —  间隔 %dpx" % [trajectory.size(), int(GameManager.sim_decision_interval)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

func _draw_lane(floor_y : float, coff : float, vp_w : float) -> void:
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), Color.WEB_GREEN, 2.0)
	draw_line(Vector2(0, floor_y - coff), Vector2(vp_w, floor_y - coff), Color.WEB_GREEN.darkened(0.4), 1.0)

func _draw_trajectory_path(lane_top : float, lane_bot : float, coff : float, vp_w : float) -> void:
	if trajectory.size() < 2:
		return
	var prev_sx : float
	var prev_sy_a : float
	var prev_sy_b : float
	var first := true
	for i in range(trajectory.size()):
		var pt := trajectory[i]
		var sx := char_x + (pt.world_x - sim_time)
		if sx < -100 or sx > vp_w + 100:
			if not first:
				prev_sx = sx
			continue
		var ay := lane_top - (coff if pt.char_a_surface == SimAI.Surface.CEILING else 0.0) - char_h * 0.5
		var by := lane_bot - (coff if pt.char_b_surface == SimAI.Surface.CEILING else 0.0) - char_h * 0.5

		if not first:
			draw_line(Vector2(prev_sx, prev_sy_a), Vector2(sx, ay), Color(Color.DODGER_BLUE, 0.3), 2.0)
			draw_line(Vector2(prev_sx, prev_sy_b), Vector2(sx, by), Color(Color.ORANGE_RED, 0.3), 2.0)

		prev_sx = sx
		prev_sy_a = ay
		prev_sy_b = by
		first = false

		if pt.swap_trigger and sx > 0 and sx < vp_w:
			draw_circle(Vector2(sx, lane_top - coff * 0.5), 5.0, Color.YELLOW)

func _draw_characters(lane_top : float, lane_bot : float, coff : float, vp_w : float) -> void:
	var surf_a := _get_surface_at(sim_time, 0)
	var surf_b := _get_surface_at(sim_time, 1)

	var ay := lane_top - char_h
	if surf_a == SimAI.Surface.CEILING:
		ay = lane_top - coff
	var by := lane_bot - char_h
	if surf_b == SimAI.Surface.CEILING:
		by = lane_bot - coff

	var color_a := Color.DODGER_BLUE
	var color_b := Color.ORANGE_RED
	if surf_a == SimAI.Surface.CEILING:
		color_a = color_a.lightened(0.3)
	if surf_b == SimAI.Surface.CEILING:
		color_b = color_b.lightened(0.3)

	draw_rect(Rect2(Vector2(char_x, ay), Vector2(char_w, char_h)), color_a)
	draw_rect(Rect2(Vector2(char_x, ay), Vector2(char_w, char_h)), Color.BLACK, false, 2.0)
	draw_rect(Rect2(Vector2(char_x, by), Vector2(char_w, char_h)), color_b)
	draw_rect(Rect2(Vector2(char_x, by), Vector2(char_w, char_h)), Color.BLACK, false, 2.0)

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
	if event.is_action_pressed("swap"):
		_regenerate()
