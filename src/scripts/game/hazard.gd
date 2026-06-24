class_name Hazard
extends Node2D

var world_x : float = 0.0
var lane : int = 0
var spike_width : float = 24.0
var spike_height : float = 24.0
var physics_body : CustBody

func _ready() -> void:
	physics_body = CustBody.new(Vector2.ZERO, Vector2(spike_width, spike_height))
	GameManager.physics_system.register_hazard_body(physics_body)

func _process(_delta : float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	if not physics_body:
		return
	var screen_x := GameManager.scroll_manager.world_to_screen_x(world_x)
	physics_body.position.x = screen_x
	_update_y()
	position.x = screen_x
	position.y = physics_body.position.y
	queue_redraw()

func _draw() -> void:
	var color := Color.RED
	var hw := spike_width * 0.5
	var tip := Vector2(hw, 0)
	var bl := Vector2(0, spike_height)
	var br := Vector2(spike_width, spike_height)
	draw_colored_polygon(PackedVector2Array([tip, bl, br, tip]), color)
	draw_line(Vector2(hw - 4, spike_height * 0.4), Vector2(hw + 4, spike_height * 0.4), Color.YELLOW, 2.0)

func setup(p_world_x : float, p_lane : int, p_width : float = 24.0, p_height : float = 24.0) -> void:
	world_x = p_world_x
	lane = p_lane
	spike_width = p_width
	spike_height = p_height

func _update_y() -> void:
	if not physics_body:
		return
	if lane == 0:
		physics_body.position.y = GameManager.lane_top_y - spike_height
	else:
		physics_body.position.y = GameManager.lane_bottom_y - spike_height

func _exit_tree() -> void:
	if GameManager and GameManager.physics_system and physics_body:
		GameManager.physics_system.unregister_hazard_body(physics_body)
