class_name Character
extends Node2D

enum Lane { TOP, BOTTOM }
enum Surface { FLOOR, CEILING }

const CHAR_WIDTH : float = 48.0
const CHAR_HEIGHT : float = 64.0

@export var lane : Lane = Lane.TOP
@export var character_polarity : Magnet.Polarity = Magnet.Polarity.NORTH
@export var re_center_speed : float = 100.0

var character_color : Color = Color.DODGER_BLUE
var physics_body : CustBody
var current_surface : Surface = Surface.FLOOR
var magnetism_active : bool = false
var is_alive : bool = true

var floor_y : float = 0.0
var ceiling_y : float = 0.0
var default_x : float = 0.0
var transition_speed : float = 400.0
var fall_gravity : float = 800.0

@onready var sprite : Sprite2D = $Sprite2D

func _ready() -> void:
	default_x = GameManager.player_fixed_x
	_setup_lane_positions()
	physics_body = CustBody.new(Vector2(default_x, floor_y - CHAR_HEIGHT), Vector2(CHAR_WIDTH, CHAR_HEIGHT))
	GameManager.physics_system.register_body(physics_body)

func _process(delta : float) -> void:
	if not is_alive:
		return
	_update_horizontal(delta)
	_update_vertical(delta)
	_update_graphics()
	_clamp_to_bounds()
	GameManager.physics_system.resolve_for_body(physics_body)
	queue_redraw()

func _draw() -> void:
	if not is_alive:
		return
	var color := character_color
	if current_surface == Surface.CEILING:
		color = color.lightened(0.3)
	draw_rect(Rect2(Vector2.ZERO, Vector2(CHAR_WIDTH, CHAR_HEIGHT)), color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(CHAR_WIDTH, CHAR_HEIGHT)), Color.BLACK, false, 2.0)

func _setup_lane_positions() -> void:
	if lane == Lane.TOP:
		floor_y = GameManager.lane_top_y
	else:
		floor_y = GameManager.lane_bottom_y
	ceiling_y = floor_y - GameManager.ceiling_offset

func _update_horizontal(delta : float) -> void:
	if current_surface == Surface.FLOOR and not physics_body.blocked_left:
		var diff := default_x - physics_body.position.x
		if absf(diff) < 1.0:
			physics_body.position.x = default_x
		else:
			physics_body.position.x += signf(diff) * re_center_speed * delta
	elif current_surface == Surface.CEILING and not physics_body.blocked_left:
		var diff := default_x - physics_body.position.x
		if absf(diff) < 1.0:
			physics_body.position.x = default_x
		else:
			physics_body.position.x += signf(diff) * re_center_speed * delta

func _update_vertical(delta : float) -> void:
	var magnet := GameManager.magnet_manager.get_active_magnet_for(self)
	var target_surface := _get_target_surface(magnet)
	var floor_pos := floor_y - CHAR_HEIGHT

	if magnet and magnetism_active:
		print("Magnet[%s@%s] Char[%s] same=%s → %s" % [
			" NORTH" if magnet.polarity == Magnet.Polarity.NORTH else " SOUTH",
			"CEIL" if magnet.placement == Magnet.Placement.CEILING else " FLR",
			" NORTH" if character_polarity == Magnet.Polarity.NORTH else " SOUTH",
			"SAME" if magnet.polarity == character_polarity else "DIFF",
			"CEILING" if target_surface == Surface.CEILING else "FLOOR"
		])

	if magnet and magnetism_active and target_surface == Surface.CEILING:
		_move_toward_ceiling(delta)
	elif magnet and magnetism_active and target_surface == Surface.FLOOR:
		_move_toward_floor(delta)
	elif current_surface == Surface.CEILING:
		_fall_to_floor(delta)
	else:
		current_surface = Surface.FLOOR
		physics_body.position.y = floor_pos
		physics_body.velocity.y = 0

func _get_target_surface(magnet : Magnet) -> Surface:
	if not magnet:
		return Surface.FLOOR
	var direction := magnet.get_force_direction(self)
	if direction < 0:
		if magnet.placement == Magnet.Placement.CEILING:
			return Surface.CEILING
		else:
			return Surface.FLOOR
	else:
		if magnet.placement == Magnet.Placement.FLOOR:
			return Surface.CEILING
		else:
			return Surface.FLOOR

func _move_toward_ceiling(delta : float) -> void:
	if physics_body.position.y <= ceiling_y + 2.0:
		physics_body.position.y = ceiling_y
		current_surface = Surface.CEILING
		physics_body.velocity.y = 0
		return
	physics_body.position.y -= transition_speed * delta
	if physics_body.position.y < ceiling_y:
		physics_body.position.y = ceiling_y
		current_surface = Surface.CEILING
		physics_body.velocity.y = 0

func _move_toward_floor(delta : float) -> void:
	var floor_pos := floor_y - CHAR_HEIGHT
	if physics_body.position.y >= floor_pos - 2.0:
		physics_body.position.y = floor_pos
		current_surface = Surface.FLOOR
		physics_body.velocity.y = 0
		return
	physics_body.position.y += transition_speed * delta
	if physics_body.position.y > floor_pos:
		physics_body.position.y = floor_pos
		current_surface = Surface.FLOOR
		physics_body.velocity.y = 0

func _fall_to_floor(delta : float) -> void:
	var floor_pos := floor_y - CHAR_HEIGHT
	if physics_body.position.y >= floor_pos - 1.0:
		physics_body.position.y = floor_pos
		current_surface = Surface.FLOOR
		physics_body.velocity.y = 0
		return
	physics_body.position.y += fall_gravity * delta
	if physics_body.position.y > floor_pos:
		physics_body.position.y = floor_pos
		current_surface = Surface.FLOOR
		physics_body.velocity.y = 0

func activate_magnetism() -> void:
	magnetism_active = true

func deactivate_magnetism() -> void:
	magnetism_active = false

func swap_lane() -> void:
	lane = Lane.BOTTOM if lane == Lane.TOP else Lane.TOP
	_setup_lane_positions()
	if current_surface == Surface.FLOOR:
		physics_body.position.y = floor_y - CHAR_HEIGHT
	else:
		physics_body.position.y = ceiling_y

func die() -> void:
	is_alive = false

func _update_graphics() -> void:
	if current_surface == Surface.FLOOR:
		position = physics_body.position
		scale.y = 1.0
	else:
		position = Vector2(physics_body.position.x, physics_body.position.y + CHAR_HEIGHT)
		scale.y = -1.0

func _clamp_to_bounds() -> void:
	physics_body.position.x = maxf(physics_body.position.x, 0.0)

func _exit_tree() -> void:
	if GameManager and GameManager.physics_system and physics_body:
		GameManager.physics_system.unregister_body(physics_body)
