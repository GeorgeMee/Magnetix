@tool
class_name Character
extends Node2D

enum Lane { TOP, BOTTOM }
enum Surface { FLOOR, CEILING }

const CHAR_WIDTH : float = 48.0
const CHAR_HEIGHT : float = 64.0

@export var lane : Lane = Lane.TOP
@export var character_polarity : Magnet.Polarity = Magnet.Polarity.NORTH
@export var re_center_speed : float = 100.0
@export var custom_fixed_x : float = 0.0
@export var character_color : Color = Color.DODGER_BLUE:
	set(v):
		character_color = v
		if sprite:
			sprite.modulate = v

var physics_body : CustBody
var current_surface : Surface = Surface.FLOOR
var magnetism_active : bool = false
var magnetism_timer : float = 0.0
var cooldown_timer : float = 0.0
var can_activate : bool = true
var was_in_field : bool = false
var is_alive : bool = true

var floor_y : float = 0.0
var ceiling_y : float = 0.0
var default_x : float = 0.0
var transition_speed : float = 400.0
var fall_gravity : float = 800.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var magnetism_sprite: Sprite2D = $MagnetismSprite

func _ready() -> void:
	_sync_texture()
	if Engine.is_editor_hint():
		sprite.modulate = character_color
		magnetism_sprite.visible = false
		return
	sprite.modulate = character_color
	magnetism_sprite.visible = false
	default_x = custom_fixed_x if custom_fixed_x > 0.0 else GameManager.player_fixed_x
	_setup_lane_positions()
	physics_body = CustBody.new(Vector2(default_x, floor_y - CHAR_HEIGHT), Vector2(CHAR_WIDTH, CHAR_HEIGHT))
	GameManager.physics_system.register_body(physics_body)

func _sync_texture() -> void:
	if not sprite:
		return
	var tex := load("res://assets/textures/characters/character_placeholder.png")
	if tex:
		sprite.texture = tex
	var mt := load("res://assets/textures/characters/character_placeholder.png")
	if mt and magnetism_sprite:
		magnetism_sprite.texture = mt
		magnetism_sprite.modulate = Color.WHITE

func _process(delta : float) -> void:
	if Engine.is_editor_hint():
		sprite.modulate = character_color
		magnetism_sprite.visible = false
		return
	if not is_alive:
		return
	_update_horizontal(delta)
	_update_vertical(delta)
	_update_graphics()
	_clamp_to_bounds()
	_update_magnetism(delta)
	GameManager.physics_system.resolve_for_body(physics_body)
	if not GameManager.sim_mode and GameManager.physics_system.is_overlapping_hazard(physics_body):
		die()
	_refresh_visual()

func _refresh_visual() -> void:
	if not sprite:
		return
	var col := character_color
	if current_surface == Surface.CEILING:
		col = col.lightened(0.3)
	sprite.modulate = col
	magnetism_sprite.modulate = Color.WHITE
	magnetism_sprite.visible = magnetism_active

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
	var target_surface := GameManager.magnet_manager.get_target_surface(self, magnetism_active)
	var floor_pos := floor_y - CHAR_HEIGHT

	if magnetism_active and target_surface == Surface.CEILING:
		_move_toward_ceiling(delta)
	elif magnetism_active and target_surface == Surface.FLOOR:
		_move_toward_floor(delta)
	elif current_surface == Surface.CEILING:
		_fall_to_floor(delta)
	else:
		current_surface = Surface.FLOOR
		physics_body.position.y = floor_pos
		physics_body.velocity.y = 0

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

func toggle_magnetism() -> void:
	if magnetism_active:
		var in_field := GameManager.magnet_manager.is_character_in_any_field(self)
		magnetism_active = false
		magnetism_timer = GameManager.magnetism_duration
		if in_field:
			can_activate = true
			cooldown_timer = 0.0
		else:
			can_activate = false
			cooldown_timer = GameManager.magnetism_cooldown
	else:
		if not can_activate:
			return
		magnetism_active = true
		magnetism_timer = GameManager.magnetism_duration
		cooldown_timer = 0.0

func _update_magnetism(delta: float) -> void:
	var in_field := GameManager.magnet_manager.is_character_in_any_field(self)

	if magnetism_active:
		if was_in_field and not in_field:
			magnetism_active = false
			magnetism_timer = GameManager.magnetism_duration
			can_activate = true
			cooldown_timer = 0.0
		elif not in_field:
			magnetism_timer -= delta
			if magnetism_timer <= 0.0:
				magnetism_active = false
				can_activate = false
				cooldown_timer = GameManager.magnetism_cooldown

	was_in_field = in_field

	if not can_activate:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_activate = true
			cooldown_timer = 0.0

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
	if Engine.is_editor_hint():
		return
	if GameManager and GameManager.physics_system and physics_body:
		GameManager.physics_system.unregister_body(physics_body)
