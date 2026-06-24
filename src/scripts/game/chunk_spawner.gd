class_name ChunkSpawner
extends Node

@export var chunk_width : float = 640.0
@export var spawn_distance_ahead : float = 2400.0
@export var despawn_distance_behind : float = 600.0

var active_walls : Array[Wall]
var active_hazards : Array[Hazard]
var active_coins : Array[Coin]
var active_magnets : Array[Magnet]
var next_spawn_world_x : float = 0.0

var wall_scene : PackedScene = preload("res://src/scenes/game/wall.tscn")
var hazard_scene : PackedScene = preload("res://src/scenes/game/hazard.tscn")
var coin_scene : PackedScene = preload("res://src/scenes/game/coin.tscn")
var magnet_scene : PackedScene = preload("res://src/scenes/game/magnet.tscn")

func _ready() -> void:
	next_spawn_world_x = 800.0

func _process(_delta : float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	var scroll_mgr := GameManager.scroll_manager
	var spawn_threshold := scroll_mgr.screen_to_world_x(1920 + chunk_width)
	while next_spawn_world_x < spawn_threshold:
		_spawn_chunk(next_spawn_world_x)
		next_spawn_world_x += chunk_width
	_cleanup_offscreen()

func _spawn_chunk(world_x : float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var wall_gap_min := 60.0
	var wall_gap_max := 100.0

	for lane in [0, 1]:
		var p_place : Magnet.Placement = Magnet.Placement.CEILING if rng.randi_range(0, 1) == 0 else Magnet.Placement.FLOOR
		var p_pol : Magnet.Polarity = Magnet.Polarity.NORTH if rng.randi_range(0, 1) == 0 else Magnet.Polarity.SOUTH
		_spawn_magnet(world_x + 100.0 + lane * 200.0, lane, p_place, p_pol, 160.0)

		if rng.randi_range(0, 2) == 0:
			var magnet_left : float = world_x + 100.0 + lane * 200.0
			var gap := rng.randf_range(wall_gap_min, wall_gap_max)
			_spawn_wall(magnet_left + gap, lane)

		if rng.randi_range(0, 3) == 0:
			var magnet_left : float = world_x + 100.0 + lane * 200.0
			var gap := rng.randf_range(30.0, 80.0)
			_spawn_hazard(magnet_left + gap, lane)

		var coin_count := rng.randi_range(1, 3)
		for j in coin_count:
			var magnet_left : float = world_x + 100.0 + lane * 200.0
			var cx := magnet_left + rng.randf_range(10.0, 150.0)
			var ctype := _rand_coin_type(rng)
			var cy := rng.randf_range(20.0, GameManager.ceiling_offset - 20.0)
			_spawn_coin(cx, lane, ctype, cy)

func _spawn_wall(world_x : float, lane : int) -> void:
	var wall := wall_scene.instantiate() as Wall
	wall.setup(world_x, lane)
	add_child(wall)
	active_walls.append(wall)

func _rand_coin_type(rng: RandomNumberGenerator) -> Coin.Type:
	var r := rng.randi_range(0, 9)
	if r < 4:
		return Coin.Type.BLUE
	elif r < 8:
		return Coin.Type.RED
	return Coin.Type.RAINBOW

func _spawn_coin(world_x : float, lane : int, type : Coin.Type, y_off : float) -> void:
	var coin := coin_scene.instantiate() as Coin
	coin.setup(world_x, lane, type, y_off)
	add_child(coin)
	active_coins.append(coin)

func _spawn_hazard(world_x : float, lane : int) -> void:
	var hazard := hazard_scene.instantiate() as Hazard
	hazard.setup(world_x, lane)
	add_child(hazard)
	active_hazards.append(hazard)

func _spawn_magnet(world_x : float, lane : int, placement : Magnet.Placement, polarity : Magnet.Polarity, length : float) -> void:
	var magnet := magnet_scene.instantiate() as Magnet
	magnet.setup(world_x, lane, placement, polarity, length)
	add_child(magnet)
	active_magnets.append(magnet)

func _cleanup_offscreen() -> void:
	var scroll_mgr := GameManager.scroll_manager
	var despawn_world_x := scroll_mgr.screen_to_world_x(-despawn_distance_behind)
	var i := active_walls.size() - 1
	while i >= 0:
		if active_walls[i].world_x < despawn_world_x:
			active_walls[i].queue_free()
			active_walls.remove_at(i)
		i -= 1
	i = active_hazards.size() - 1
	while i >= 0:
		if active_hazards[i].world_x < despawn_world_x:
			active_hazards[i].queue_free()
			active_hazards.remove_at(i)
		i -= 1
	i = active_coins.size() - 1
	while i >= 0:
		if not is_instance_valid(active_coins[i]) or active_coins[i].world_x < despawn_world_x:
			if is_instance_valid(active_coins[i]):
				active_coins[i].queue_free()
			active_coins.remove_at(i)
		i -= 1
	i = active_magnets.size() - 1
	while i >= 0:
		if active_magnets[i].world_x < despawn_world_x:
			active_magnets[i].queue_free()
			active_magnets.remove_at(i)
		i -= 1
