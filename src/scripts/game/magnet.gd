class_name Magnet
extends Node2D

enum Polarity { NORTH, SOUTH }
enum Placement { FLOOR, CEILING }

@export var polarity : Polarity = Polarity.NORTH
@export var placement : Placement = Placement.FLOOR
@export var field_length : float = 128.0
@export var field_height : float = 64.0
@export var force_strength : float = 600.0

var world_x : float = 0.0
var lane : int = 0
var field_aabb : CustAABB

func _ready() -> void:
	if GameManager and GameManager.magnet_manager:
		GameManager.magnet_manager.register_magnet(self)

func _process(_delta : float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	update_field_aabb()
	position.x = GameManager.scroll_manager.world_to_screen_x(world_x)
	position.y = _get_screen_y()
	queue_redraw()

func _draw() -> void:
	var field_color := Color.RED if polarity == Polarity.NORTH else Color.BLUE
	field_color = field_color.darkened(0.5)
	field_color.a = 0.3
	draw_rect(Rect2(Vector2(0, -GameManager.ceiling_offset), Vector2(field_length, GameManager.ceiling_offset)), field_color)

	var magnet_color := Color.RED if polarity == Polarity.NORTH else Color.BLUE
	var magnet_h := 16.0
	var magnet_y := -GameManager.ceiling_offset if placement == Placement.CEILING else -magnet_h
	draw_rect(Rect2(Vector2(0, magnet_y), Vector2(field_length, magnet_h)), magnet_color)

func setup(p_world_x : float, p_lane : int, p_placement : Placement, p_polarity : Polarity, p_length : float = 128.0) -> void:
	world_x = p_world_x
	lane = p_lane
	placement = p_placement
	polarity = p_polarity
	field_length = p_length

func _get_screen_y() -> float:
	if lane == 0:
		return GameManager.lane_top_y
	return GameManager.lane_bottom_y

func update_field_aabb() -> void:
	var screen_x := GameManager.scroll_manager.world_to_screen_x(world_x)
	_update_field_aabb_at(screen_x)

func _update_field_aabb_at(screen_x : float) -> void:
	var y := _get_screen_y() - GameManager.ceiling_offset
	field_aabb = CustAABB.new(Vector2(screen_x, y), Vector2(field_length, GameManager.ceiling_offset))

func is_character_in_field(character : Character) -> bool:
	if not character or not character.physics_body:
		return false
	var char_aabb : CustAABB = character.physics_body.collision_box
	return char_aabb.overlaps(field_aabb)

func get_force_direction(character : Character) -> float:
	if polarity == character.character_polarity:
		return -1.0
	return 1.0

func get_vertical_force(character : Character) -> float:
	var direction := get_force_direction(character)
	if placement == Placement.FLOOR:
		return -direction * force_strength
	else:
		return direction * force_strength

func _exit_tree() -> void:
	if GameManager and GameManager.magnet_manager:
		GameManager.magnet_manager.unregister_magnet(self)
