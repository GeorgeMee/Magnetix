class_name Wall
extends Node2D

var world_x : float = 0.0
var lane : int = 0
var screen_width : float = 32.0
var screen_height : float = 64.0
var physics_body : CustBody

func _ready() -> void:
	physics_body = CustBody.new(Vector2.ZERO, Vector2(screen_width, screen_height))
	GameManager.physics_system.register_static_body(physics_body)

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
	draw_rect(Rect2(Vector2.ZERO, Vector2(screen_width, screen_height)), Color.DIM_GRAY)
	draw_rect(Rect2(Vector2.ZERO, Vector2(screen_width, screen_height)), Color.BLACK, false, 2.0)

func setup(p_world_x : float, p_lane : int, p_width : float = 32.0, p_height : float = 64.0) -> void:
	world_x = p_world_x
	lane = p_lane
	screen_width = p_width
	screen_height = p_height

func _update_y() -> void:
	if not physics_body:
		return
	if lane == 0:
		physics_body.position.y = GameManager.lane_top_y - screen_height
	else:
		physics_body.position.y = GameManager.lane_bottom_y - screen_height

func _exit_tree() -> void:
	if GameManager and GameManager.physics_system and physics_body:
		GameManager.physics_system.unregister_static_body(physics_body)
