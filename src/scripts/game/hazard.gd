@tool
class_name Hazard
extends Node2D

@export var count : int = 1:
	set(v):
		count = max(1, v)
		_rebuild_grid()
@export var unit_height : float = 24.0

var world_x : float = 0.0
var lane : int = 0
var physics_body : CustBody

func _ready() -> void:
	if Engine.is_editor_hint():
		_rebuild_grid()
		return
	_rebuild_grid()
	if GameManager and GameManager.physics_system:
		physics_body = CustBody.new(Vector2.ZERO, Vector2(count * 24.0, unit_height))
		GameManager.physics_system.register_hazard_body(physics_body)

func _rebuild_grid() -> void:
	for child in get_children():
		child.queue_free()

	var tex := load("res://assets/textures/obstacles/hazard_unit.png")
	if not tex:
		return

	for i in range(count):
		var s := Sprite2D.new()
		s.texture = tex
		s.position = Vector2(i * 24.0, 0)
		s.centered = false
		add_child(s)

func _process(_delta : float) -> void:
	if Engine.is_editor_hint():
		return
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	if not GameManager.scroll_manager:
		return
	if not physics_body:
		return
	var screen_x := GameManager.scroll_manager.world_to_screen_x(world_x)
	physics_body.position.x = screen_x
	_update_y()
	position.x = screen_x
	position.y = physics_body.position.y

func setup(p_world_x : float, p_lane : int, p_width : float = 24.0, p_height : float = 24.0) -> void:
	world_x = p_world_x
	lane = p_lane
	count = max(1, int(p_width / 24.0))
	unit_height = p_height

func _update_y() -> void:
	if not physics_body:
		return
	if lane == 0:
		physics_body.position.y = GameManager.lane_top_y - unit_height
	else:
		physics_body.position.y = GameManager.lane_bottom_y - unit_height

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	if GameManager and GameManager.physics_system and physics_body:
		GameManager.physics_system.unregister_hazard_body(physics_body)
