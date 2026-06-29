@tool
class_name Coin
extends Node2D

enum Type { RED, BLUE, RAINBOW }

@export var coin_type : Type = Type.BLUE:
	set(v):
		coin_type = v
		_refresh_visual()
@export var coin_size : float = 16.0

var world_x : float = 0.0
var lane : int = 0
var y_offset : float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if Engine.is_editor_hint():
		_sync_texture()
		_refresh_visual()
		return
	_sync_texture()
	_refresh_visual()

func _sync_texture() -> void:
	var tex := load("res://assets/textures/coins/coin_placeholder.png")
	if tex and sprite:
		sprite.texture = tex

func _refresh_visual() -> void:
	if not sprite:
		return
	match coin_type:
		Type.BLUE:
			sprite.modulate = Color.DODGER_BLUE
		Type.RED:
			sprite.modulate = Color.ORANGE_RED
		Type.RAINBOW:
			var t := Time.get_ticks_msec() * 0.003
			sprite.modulate = Color.from_hsv(fmod(t, 1.0), 1.0, 1.0)
			return
	sprite.modulate = sprite.modulate

func _process(_delta : float) -> void:
	if Engine.is_editor_hint():
		return
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	if not GameManager.scroll_manager:
		return
	var screen_x := GameManager.scroll_manager.world_to_screen_x(world_x)
	position.x = screen_x
	position.y = _get_lane_floor_y() - y_offset
	if coin_type == Type.RAINBOW:
		_refresh_visual()
	_check_collect()

func setup(p_world_x : float, p_lane : int, p_type : Type, p_y_offset : float) -> void:
	world_x = p_world_x
	lane = p_lane
	coin_type = p_type
	y_offset = p_y_offset

func _get_lane_floor_y() -> float:
	return GameManager.lane_top_y if lane == 0 else GameManager.lane_bottom_y

func _check_collect() -> void:
	var coin_aabb := CustAABB.new(position - Vector2(coin_size, coin_size) * 0.5, Vector2(coin_size, coin_size))

	if GameManager.character_a and GameManager.character_a.is_alive:
		var ca := GameManager.character_a.physics_body.get_aabb()
		if coin_aabb.overlaps(ca):
			_collect()
			return

	if GameManager.character_b and GameManager.character_b.is_alive:
		var cb := GameManager.character_b.physics_body.get_aabb()
		if coin_aabb.overlaps(cb):
			_collect()

func _collect() -> void:
	match coin_type:
		Type.BLUE:
			GameManager.coin_blue += 1
		Type.RED:
			GameManager.coin_red += 1
		Type.RAINBOW:
			GameManager.coin_rainbow += 1
	queue_free()
