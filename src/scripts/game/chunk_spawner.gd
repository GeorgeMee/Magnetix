class_name ChunkSpawner
extends Node

@export var despawn_distance_behind : float = 600.0

var active_walls : Array[Wall]
var active_hazards : Array[Hazard]
var active_coins : Array[Coin]
var active_magnets : Array[Magnet]
var next_spawn_world_x : float = 0.0
var _spawned_keys : Dictionary = {}

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
	var chunk_width := GameManager.chunk_width
	var spawn_threshold := scroll_mgr.screen_to_world_x(1920 + chunk_width)
	while next_spawn_world_x < spawn_threshold:
		_spawn_chunk(next_spawn_world_x)
		next_spawn_world_x += chunk_width
	_cleanup_offscreen()

func _spawn_chunk(world_x : float) -> void:
	var chunk_width := GameManager.chunk_width
	for lane in [0, 1]:
		var layout := GameManager.choreographer.get_chunk_layout(world_x, lane, chunk_width)
		for m in layout.magnets:
			_spawn_magnet(m["world_x"], lane, m["placement"], m["polarity"], m["length"])
		for w in layout.walls:
			_spawn_wall(w["world_x"], lane)
		for h in layout.hazards:
			_spawn_hazard(h["world_x"], lane)
		for c in layout.coins:
			_spawn_coin(c["world_x"], lane, c["type"], c["y_off"])

func _spawn_wall(world_x : float, lane : int) -> void:
	var key := "wall_%d_%.1f" % [lane, world_x]
	if _spawned_keys.has(key):
		return
	_spawned_keys[key] = true
	var wall := wall_scene.instantiate() as Wall
	wall.setup(world_x, lane)
	add_child(wall)
	active_walls.append(wall)

func _spawn_coin(world_x : float, lane : int, type : Coin.Type, y_off : float) -> void:
	var key := "coin_%d_%.1f" % [lane, world_x]
	if _spawned_keys.has(key):
		return
	_spawned_keys[key] = true
	var coin := coin_scene.instantiate() as Coin
	coin.setup(world_x, lane, type, y_off)
	add_child(coin)
	active_coins.append(coin)

func _spawn_hazard(world_x : float, lane : int) -> void:
	var key := "hazard_%d_%.1f" % [lane, world_x]
	if _spawned_keys.has(key):
		return
	_spawned_keys[key] = true
	var hazard := hazard_scene.instantiate() as Hazard
	hazard.setup(world_x, lane)
	add_child(hazard)
	active_hazards.append(hazard)

func _spawn_magnet(world_x : float, lane : int, placement : Magnet.Placement, polarity : Magnet.Polarity, length : float) -> void:
	var key := "magnet_%d_%.1f_%d" % [lane, world_x, placement]
	if _spawned_keys.has(key):
		return
	_spawned_keys[key] = true
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
			_spawned_keys.erase("wall_%d_%.1f" % [active_walls[i].lane, active_walls[i].world_x])
			active_walls[i].queue_free()
			active_walls.remove_at(i)
		i -= 1
	i = active_hazards.size() - 1
	while i >= 0:
		if active_hazards[i].world_x < despawn_world_x:
			_spawned_keys.erase("hazard_%d_%.1f" % [active_hazards[i].lane, active_hazards[i].world_x])
			active_hazards[i].queue_free()
			active_hazards.remove_at(i)
		i -= 1
	i = active_coins.size() - 1
	while i >= 0:
		if not is_instance_valid(active_coins[i]) or active_coins[i].world_x < despawn_world_x:
			if is_instance_valid(active_coins[i]):
				_spawned_keys.erase("coin_%d_%.1f" % [active_coins[i].lane, active_coins[i].world_x])
				active_coins[i].queue_free()
			active_coins.remove_at(i)
		i -= 1
	i = active_magnets.size() - 1
	while i >= 0:
		if active_magnets[i].world_x < despawn_world_x:
			var m := active_magnets[i]
			_spawned_keys.erase("magnet_%d_%.1f_%d" % [m.lane, m.world_x, m.placement])
			m.queue_free()
			active_magnets.remove_at(i)
		i -= 1
