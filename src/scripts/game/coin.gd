class_name Coin
extends Node2D

enum Type { RED, BLUE, RAINBOW }

var world_x : float = 0.0
var lane : int = 0
var coin_type : Type = Type.BLUE
var coin_size : float = 16.0
var y_offset : float = 0.0

func _ready() -> void:
	$EditorPlaceholder.queue_free()

func _process(_delta : float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	var screen_x := GameManager.scroll_manager.world_to_screen_x(world_x)
	position.x = screen_x
	position.y = _get_lane_floor_y() - y_offset
	_check_collect()
	queue_redraw()

func _draw() -> void:
	match coin_type:
		Type.BLUE:
			_draw_diamond(Color.DODGER_BLUE)
		Type.RED:
			_draw_diamond(Color.ORANGE_RED)
		Type.RAINBOW:
			var t := Time.get_ticks_msec() * 0.003
			_draw_diamond(Color.from_hsv(fmod(t, 1.0), 1.0, 1.0))

func _draw_diamond(col: Color) -> void:
	var h := coin_size * 0.5
	var p := PackedVector2Array([Vector2(h, 0), Vector2(coin_size, h), Vector2(h, coin_size), Vector2(0, h)])
	draw_colored_polygon(p, col)
	draw_line(Vector2(h, 0), Vector2(coin_size, h), Color.WHITE, 1.5)
	draw_line(Vector2(coin_size, h), Vector2(h, coin_size), Color.WHITE, 1.5)
	draw_line(Vector2(h, coin_size), Vector2(0, h), Color.WHITE, 1.5)
	draw_line(Vector2(0, h), Vector2(h, 0), Color.WHITE, 1.5)

func setup(p_world_x : float, p_lane : int, p_type : Type, p_y_offset : float) -> void:
	world_x = p_world_x
	lane = p_lane
	coin_type = p_type
	y_offset = p_y_offset

func _get_lane_floor_y() -> float:
	return GameManager.lane_top_y if lane == 0 else GameManager.lane_bottom_y

func _check_collect() -> void:
	var coin_aabb := CustAABB.new(position - Vector2(coin_size, coin_size) * 0.5, Vector2(coin_size, coin_size))
	var collected := false

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
