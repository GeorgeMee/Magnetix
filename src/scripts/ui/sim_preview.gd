class_name SimPreview
extends Node2D

var sim_ai : SimAI
var trajectory : Array[TrajectoryPoint] = []
var sim_time : float = 0.0
var sim_speed : float = 100.0
var playing : bool = true
var viewport_ox : float = 0.0

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
	trajectory = sim_ai.generate(Magnet.Polarity.NORTH, Magnet.Polarity.SOUTH, 100.0, 5000.0, GameManager.sim_decision_interval)
	sim_time = 0.0

func _process(delta : float) -> void:
	if playing:
		sim_time += sim_speed * delta
		if sim_time > 5000.0:
			sim_time -= 5000.0

	var scroll_ox := sim_time
	viewport_ox = scroll_ox
	queue_redraw()

func _on_speed_changed(value : float) -> void:
	sim_speed = value
	speed_label.text = "速度: %d" % int(value)

func _on_play_toggle() -> void:
	playing = not playing
	btn_play.text = "暂停" if playing else "播放"

func _draw() -> void:
	var lane_top := 250.0
	var lane_bot := 650.0
	var coff := 180.0
	var hw := 30.0
	var margin := 200.0
	var view_w := get_viewport().get_visible_rect().size.x - margin

	draw_line(Vector2(0, lane_top), Vector2(get_viewport().get_visible_rect().size.x, lane_top), Color.WEB_GREEN, 2.0)
	draw_line(Vector2(0, lane_top - coff), Vector2(get_viewport().get_visible_rect().size.x, lane_top - coff), Color.WEB_GREEN.darkened(0.4), 1.0)
	draw_line(Vector2(0, lane_bot), Vector2(get_viewport().get_visible_rect().size.x, lane_bot), Color.WEB_GREEN, 2.0)
	draw_line(Vector2(0, lane_bot - coff), Vector2(get_viewport().get_visible_rect().size.x, lane_bot - coff), Color.WEB_GREEN.darkened(0.4), 1.0)

	for i in range(trajectory.size() - 1):
		var pt := trajectory[i]
		var next := trajectory[i + 1]
		var sx := margin + pt.world_x - viewport_ox
		var nx := margin + next.world_x - viewport_ox
		if sx < -100 or nx > get_viewport().get_visible_rect().size.x + 100:
			continue

		var ay := lane_top - (coff if pt.char_a_surface == Character.Surface.CEILING else 0.0) - Character.CHAR_HEIGHT * 0.5
		var by := lane_bot - (coff if pt.char_b_surface == Character.Surface.CEILING else 0.0) - Character.CHAR_HEIGHT * 0.5

		draw_rect(Rect2(Vector2(sx - hw, ay - hw), Vector2(hw * 2, hw * 2)), Color(Color.DODGER_BLUE, 0.25), false, 1.0)
		draw_rect(Rect2(Vector2(sx - hw, by - hw), Vector2(hw * 2, hw * 2)), Color(Color.ORANGE_RED, 0.25), false, 1.0)

		if pt.swap_trigger:
			draw_circle(Vector2(sx, lane_top - coff * 0.5), 5.0, Color.YELLOW)
		if pt.magnet_a_trigger:
			draw_circle(Vector2(sx, ay - 10), 3.0, Color.WHITE)
		if pt.magnet_b_trigger:
			draw_circle(Vector2(sx, by - 10), 3.0, Color.WHITE)

	draw_rect(Rect2(Vector2(0, 0), Vector2(get_viewport().get_visible_rect().size.x, 60)), Color(Color.BLACK, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(20, 30), "Sim AI 轨迹预览  —  %d 决策点" % trajectory.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
	if event.is_action_pressed("swap"):
		_regenerate()
