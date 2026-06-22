class_name ChunkSpawner
extends Node

@export var chunk_width : float = 640.0
@export var spawn_distance_ahead : float = 2400.0
@export var despawn_distance_behind : float = 600.0

var active_walls : Array[Wall]
var active_magnets : Array[Magnet]
var next_spawn_world_x : float = 0.0

var wall_scene : PackedScene = preload("res://src/scenes/game/wall.tscn")
var magnet_scene : PackedScene = preload("res://src/scenes/game/magnet.tscn")

func _ready() -> void:
	next_spawn_world_x = spawn_distance_ahead

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

	if rng.randi_range(0, 2) == 0:
		_spawn_wall(world_x + 200, 0)
	if rng.randi_range(0, 2) == 0:
		_spawn_wall(world_x + 300, 1)

	for lane in [0, 1]:
		var p_place : Magnet.Placement = Magnet.Placement.CEILING if rng.randi_range(0, 1) == 0 else Magnet.Placement.FLOOR
		var p_pol : Magnet.Polarity = Magnet.Polarity.NORTH if rng.randi_range(0, 1) == 0 else Magnet.Polarity.SOUTH
		_spawn_magnet(world_x + 100.0 + lane * 200.0, lane, p_place, p_pol, 160.0)

func _spawn_wall(world_x : float, lane : int) -> void:
	var wall := wall_scene.instantiate() as Wall
	wall.setup(world_x, lane)
	add_child(wall)
	active_walls.append(wall)

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
	i = active_magnets.size() - 1
	while i >= 0:
		if active_magnets[i].world_x < despawn_world_x:
			active_magnets[i].queue_free()
			active_magnets.remove_at(i)
		i -= 1
