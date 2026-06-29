extends Node2D

@onready var physics_system: PhysicsSystem = $PhysicsSystem
@onready var scroll_manager: ScrollManager = $ScrollManager
@onready var magnet_manager: MagnetManager = $MagnetManager
@onready var input_manager: InputManager = $InputManager
@onready var spike: Spike = $Spike
@onready var game_hud: GameHUD = $GameHUD

var character_a: Character
var character_b: Character
var character_scene: PackedScene = preload("res://src/scenes/game/character.tscn")
var magnet_scene: PackedScene = preload("res://src/scenes/game/magnet.tscn")
var wall_scene: PackedScene = preload("res://src/scenes/game/wall.tscn")
var hazard_scene: PackedScene = preload("res://src/scenes/game/hazard.tscn")
var coin_scene: PackedScene = preload("res://src/scenes/game/coin.tscn")

var _presets: Array[PresetData] = []
var _preset_index: int = 0
var _next_spawn_wx: float = 800.0
var _despawn_dist: float = 600.0
var _active_walls: Array[Wall] = []
var _active_hazards: Array[Hazard] = []
var _active_coins: Array[Coin] = []
var _active_magnets: Array[Magnet] = []
var _spawned_keys: Dictionary = {}

func _ready():
	GameManager.preset_mode = true
	GameManager.physics_system = physics_system
	GameManager.scroll_manager = scroll_manager
	GameManager.magnet_manager = magnet_manager
	_load_presets()
	if _presets.is_empty():
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
		return
	_presets.shuffle()
	_spawn_characters()
	GameManager.character_a = character_a
	GameManager.character_b = character_b
	_connect_input()
	game_hud.update_button_colors(character_a.character_color, character_b.character_color)
	GameManager.start_game()

func _load_presets():
	var dir := DirAccess.open("res://presets")
	if not dir: return
	dir.list_dir_begin()
	var fn := dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".tres"):
			var p := load("res://presets/" + fn) as PresetData
			if p: _presets.append(p)
		fn = dir.get_next()
	dir.list_dir_end()

func _spawn_characters():
	character_a = character_scene.instantiate()
	character_a.lane = Character.Lane.TOP
	character_a.character_polarity = Magnet.Polarity.NORTH
	character_a.character_color = Color.DODGER_BLUE
	add_child(character_a)
	character_b = character_scene.instantiate()
	character_b.lane = Character.Lane.BOTTOM
	character_b.character_polarity = Magnet.Polarity.SOUTH
	character_b.character_color = Color.ORANGE_RED
	add_child(character_b)

func _connect_input():
	input_manager.magnetism_a_toggled.connect(character_a.toggle_magnetism)
	input_manager.magnetism_b_toggled.connect(character_b.toggle_magnetism)
	input_manager.swap_pressed.connect(_on_swap)
	game_hud.magnetism_a_toggled.connect(character_a.toggle_magnetism)
	game_hud.magnetism_b_toggled.connect(character_b.toggle_magnetism)
	game_hud.swap_pressed.connect(_on_swap)

func _on_swap():
	var tc := character_a.character_color
	var tp := character_a.character_polarity
	character_a.character_color = character_b.character_color
	character_a.character_polarity = character_b.character_polarity
	character_b.character_color = tc
	character_b.character_polarity = tp
	game_hud.update_button_colors(character_a.character_color, character_b.character_color)

func _process(_delta):
	if GameManager.state != GameManager.GameState.PLAYING: return
	var cw := GameManager.chunk_width
	var th := scroll_manager.screen_to_world_x(1920 + cw)
	while _next_spawn_wx < th:
		_spawn_preset_chunk(_next_spawn_wx)
		_next_spawn_wx += cw
	_cleanup_offscreen()
	_check_game_over()
	queue_redraw()

func _spawn_preset_chunk(wx: float):
	if _preset_index >= _presets.size():
		_presets.shuffle()
		_preset_index = 0
	var data := _presets[_preset_index]
	_preset_index += 1
	var off := wx
	for mb in data.magnet_blocks:
		_spawn_magnet(mb.world_x + off, mb.lane, mb.placement, mb.polarity, mb.length)
	for w in data.walls:
		_spawn_wall(w.world_x + off, w.lane, w.count, w.height_units)
	for h in data.hazards:
		_spawn_hazard(h.world_x + off, h.lane, h.count)
	for c in data.coins:
		_spawn_coin(c.world_x + off, c.lane, c.coin_type, c.y_off)

func _spawn_magnet(wx, lane, placement, polarity, length):
	var key := "m_%d_%.1f_%d" % [lane, wx, placement]
	if _spawned_keys.has(key): return
	_spawned_keys[key] = true
	var m := magnet_scene.instantiate() as Magnet
	m.setup(wx, lane, placement, polarity, length)
	add_child(m)
	_active_magnets.append(m)

func _spawn_wall(wx, lane, cnt, hu):
	var key := "w_%d_%.1f" % [lane, wx]
	if _spawned_keys.has(key): return
	_spawned_keys[key] = true
	var w := wall_scene.instantiate() as Wall
	w.setup(wx, lane)
	w.count = cnt
	w.height_units = hu
	add_child(w)
	_active_walls.append(w)

func _spawn_hazard(wx, lane, cnt):
	var key := "h_%d_%.1f" % [lane, wx]
	if _spawned_keys.has(key): return
	_spawned_keys[key] = true
	var h := hazard_scene.instantiate() as Hazard
	h.setup(wx, lane)
	h.count = cnt
	add_child(h)
	_active_hazards.append(h)

func _spawn_coin(wx, lane, ctype, y_off):
	var key := "c_%d_%.1f" % [lane, wx]
	if _spawned_keys.has(key): return
	_spawned_keys[key] = true
	var c := coin_scene.instantiate() as Coin
	c.setup(wx, lane, ctype, y_off)
	add_child(c)
	_active_coins.append(c)

func _cleanup_offscreen():
	var dwx := scroll_manager.screen_to_world_x(-_despawn_dist)
	var i := _active_walls.size() - 1
	while i >= 0:
		var w := _active_walls[i]
		if w.world_x < dwx:
			_spawned_keys.erase("w_%d_%.1f" % [w.lane, w.world_x])
			w.queue_free()
			_active_walls.remove_at(i)
		i -= 1
	i = _active_hazards.size() - 1
	while i >= 0:
		var h := _active_hazards[i]
		if h.world_x < dwx:
			_spawned_keys.erase("h_%d_%.1f" % [h.lane, h.world_x])
			h.queue_free()
			_active_hazards.remove_at(i)
		i -= 1
	i = _active_coins.size() - 1
	while i >= 0:
		if not is_instance_valid(_active_coins[i]) or _active_coins[i].world_x < dwx:
			if is_instance_valid(_active_coins[i]):
				var c := _active_coins[i]
				_spawned_keys.erase("c_%d_%.1f" % [c.lane, c.world_x])
				c.queue_free()
			_active_coins.remove_at(i)
		i -= 1
	i = _active_magnets.size() - 1
	while i >= 0:
		var m := _active_magnets[i]
		if m.world_x < dwx:
			_spawned_keys.erase("m_%d_%.1f_%d" % [m.lane, m.world_x, m.placement])
			m.queue_free()
			_active_magnets.remove_at(i)
		i -= 1

func _draw():
	_draw_lane(GameManager.lane_top_y, Color.WEB_GREEN)
	_draw_lane(GameManager.lane_bottom_y, Color.WEB_GREEN)

func _draw_lane(floor_y, color):
	var vw := get_viewport().get_visible_rect().size.x
	draw_line(Vector2(0, floor_y), Vector2(vw, floor_y), color, 3.0)
	draw_line(Vector2(0, floor_y - GameManager.ceiling_offset), Vector2(vw, floor_y - GameManager.ceiling_offset), color.darkened(0.4), 2.0)

func _check_game_over():
	if not character_a.is_alive or not character_b.is_alive:
		character_a.die()
		character_b.die()
		GameManager.end_game()
		return
	if spike.is_character_hit(character_a) or spike.is_character_hit(character_b):
		character_a.die()
		character_b.die()
		GameManager.end_game()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")