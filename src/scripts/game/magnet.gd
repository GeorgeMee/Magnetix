@tool
class_name Magnet
extends Node2D

enum Polarity { NORTH, SOUTH }
enum Placement { FLOOR, CEILING }

@export var polarity : Polarity = Polarity.NORTH:
	set(v):
		polarity = v
		_refresh_visual()
@export var placement : Placement = Placement.FLOOR:
	set(v):
		placement = v
		_refresh_visual()
@export var field_length : float = 128.0:
	set(v):
		field_length = v
		_refresh_visual()
@export var force_strength : float = 600.0

var world_x : float = 0.0
var lane : int = 0
var field_aabb : CustAABB

@onready var field_sprite: Sprite2D = $FieldSprite
@onready var bar_sprite: Sprite2D = $BarSprite

func _ready() -> void:
	if Engine.is_editor_hint():
		_sync_textures()
		_refresh_visual()
		return
	_sync_textures()
	_refresh_visual()
	if GameManager and GameManager.magnet_manager:
		GameManager.magnet_manager.register_magnet(self)

func _sync_textures() -> void:
	var bar_tex := load("res://assets/textures/magnets/magnet_bar.png")
	var field_tex := load("res://assets/textures/magnets/magnet_field.png")
	if bar_sprite and bar_tex:
		bar_sprite.texture = bar_tex
	if field_sprite and field_tex:
		field_sprite.texture = field_tex

func _refresh_visual() -> void:
	const DEFAULT_COFF := 180.0
	var coff := DEFAULT_COFF
	if not Engine.is_editor_hint() and GameManager:
		coff = GameManager.ceiling_offset
	var col := Color.BLUE if polarity == Polarity.NORTH else Color.RED

	if field_sprite:
		field_sprite.modulate = Color(col, 0.3)
		field_sprite.position.y = -coff
		field_sprite.scale = Vector2(field_length / 128.0, coff)

	if bar_sprite:
		bar_sprite.modulate = col
		bar_sprite.scale.x = field_length / 128.0
		if placement == Placement.FLOOR:
			bar_sprite.position.y = -16.0
		else:
			bar_sprite.position.y = -coff

func _process(_delta : float) -> void:
	if Engine.is_editor_hint():
		return
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	if not GameManager.scroll_manager:
		return
	update_field_aabb()
	position.x = GameManager.scroll_manager.world_to_screen_x(world_x)
	position.y = _get_screen_y()

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
	var char_aabb : CustAABB = character.physics_body.get_aabb()
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
	if Engine.is_editor_hint():
		return
	if GameManager and GameManager.magnet_manager:
		GameManager.magnet_manager.unregister_magnet(self)
