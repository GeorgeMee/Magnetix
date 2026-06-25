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

var wall_scene: PackedScene = preload("res://src/scenes/game/wall.tscn")
var hazard_scene: PackedScene = preload("res://src/scenes/game/hazard.tscn")
var coin_scene: PackedScene = preload("res://src/scenes/game/coin.tscn")
var magnet_scene: PackedScene = preload("res://src/scenes/game/magnet.tscn")
var active_walls: Array[Wall] = []
var active_hazards: Array[Hazard] = []
var active_coins: Array[Coin] = []
var active_magnets: Array[Magnet] = []
var next_spawn_index := 0
var despawn_distance := 600.0

func _ready() -> void:
	GameManager.sim_mode = false
	GameManager.physics_system = physics_system
	GameManager.scroll_manager = scroll_manager
	GameManager.magnet_manager = magnet_manager

	_spawn_characters()
	GameManager.character_a = character_a
	GameManager.character_b = character_b
	_connect_input()
	game_hud.update_button_colors(character_a.character_color, character_b.character_color)
	GameManager.start_game()

func _spawn_characters() -> void:
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

func _connect_input() -> void:
	input_manager.magnetism_a_toggled.connect(character_a.toggle_magnetism)
	input_manager.magnetism_b_toggled.connect(character_b.toggle_magnetism)
	input_manager.swap_pressed.connect(_on_swap)
	game_hud.magnetism_a_toggled.connect(character_a.toggle_magnetism)
	game_hud.magnetism_b_toggled.connect(character_b.toggle_magnetism)
	game_hud.swap_pressed.connect(_on_swap)

func _on_swap() -> void:
	var tmp_color := character_a.character_color
	var tmp_polarity := character_a.character_polarity
	character_a.character_color = character_b.character_color
	character_a.character_polarity = character_b.character_polarity
	character_b.character_color = tmp_color
	character_b.character_polarity = tmp_polarity
	game_hud.update_button_colors(character_a.character_color, character_b.character_color)

func _process(_delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	_spawn_from_stored()
	_cleanup_offscreen()
	_check_game_over()
	queue_redraw()

func _spawn_from_stored() -> void:
	var layouts := GameManager.stored_layouts
	if layouts.is_empty():
		return
	var spawn_threshold := scroll_manager.screen_to_world_x(1920 + GameManager.chunk_width)
	while next_spawn_index < layouts.size():
		var entry := layouts[next_spawn_index]
		var wx: float = entry["world_x"]
		if wx > spawn_threshold:
			break
		_spawn_entry(entry)
		next_spawn_index += 1

func _spawn_entry(entry: Dictionary) -> void:
	var wx: float = entry["world_x"]
	var layout_a: ChunkLayout = entry["layout_a"]
	var layout_b: ChunkLayout = entry["layout_b"]
	for lane in [0, 1]:
		var layout := layout_a if lane == 0 else layout_b
		for m in layout.magnets:
			var magnet := magnet_scene.instantiate() as Magnet
			magnet.setup(m["world_x"], lane, m["placement"], m["polarity"], m["length"])
			add_child(magnet)
			active_magnets.append(magnet)
		for w in layout.walls:
			var wall := wall_scene.instantiate() as Wall
			wall.setup(w["world_x"], lane)
			add_child(wall)
			active_walls.append(wall)
		for h in layout.hazards:
			var hazard := hazard_scene.instantiate() as Hazard
			hazard.setup(h["world_x"], lane)
			add_child(hazard)
			active_hazards.append(hazard)
		for c in layout.coins:
			var coin := coin_scene.instantiate() as Coin
			coin.setup(c["world_x"], lane, c["type"], c["y_off"])
			add_child(coin)
			active_coins.append(coin)

func _cleanup_offscreen() -> void:
	var despawn_wx := scroll_manager.screen_to_world_x(-despawn_distance)
	_active_cleanup(active_walls, despawn_wx)
	_active_cleanup(active_hazards, despawn_wx)
	_active_cleanup_coins(despawn_wx)
	_active_cleanup(active_magnets, despawn_wx)

func _active_cleanup(arr: Array, despawn_wx: float) -> void:
	var i := arr.size() - 1
	while i >= 0:
		if arr[i].world_x < despawn_wx:
			arr[i].queue_free()
			arr.remove_at(i)
		i -= 1

func _active_cleanup_coins(despawn_wx: float) -> void:
	var i := active_coins.size() - 1
	while i >= 0:
		if not is_instance_valid(active_coins[i]) or active_coins[i].world_x < despawn_wx:
			if is_instance_valid(active_coins[i]):
				active_coins[i].queue_free()
			active_coins.remove_at(i)
		i -= 1

func _draw() -> void:
	_draw_lane(GameManager.lane_top_y, Color.WEB_GREEN)
	_draw_lane(GameManager.lane_bottom_y, Color.WEB_GREEN)
	if GameManager.debug_visualize:
		_draw_trajectory()

func _draw_lane(floor_y: float, color: Color) -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), color, 3.0)
	draw_line(Vector2(0, floor_y - GameManager.ceiling_offset), Vector2(vp_w, floor_y - GameManager.ceiling_offset), color.darkened(0.4), 2.0)

func _draw_trajectory() -> void:
	for pt in GameManager.trajectory_data:
		var sx := scroll_manager.world_to_screen_x(pt.world_x)
		if sx < -100 or sx > get_viewport().get_visible_rect().size.x + 100:
			continue
		var ay := GameManager.lane_top_y - Character.CHAR_HEIGHT
		var by := GameManager.lane_bottom_y - Character.CHAR_HEIGHT
		if pt.char_a_surface == Character.Surface.CEILING:
			ay = GameManager.lane_top_y - GameManager.ceiling_offset
		if pt.char_b_surface == Character.Surface.CEILING:
			by = GameManager.lane_bottom_y - GameManager.ceiling_offset
		draw_rect(Rect2(Vector2(sx, ay), Vector2(Character.CHAR_WIDTH, Character.CHAR_HEIGHT)), Color(Color.DODGER_BLUE, 0.3), false, 1.0)
		draw_rect(Rect2(Vector2(sx, by), Vector2(Character.CHAR_WIDTH, Character.CHAR_HEIGHT)), Color(Color.ORANGE_RED, 0.3), false, 1.0)
		if pt.swap_trigger:
			draw_circle(Vector2(sx + Character.CHAR_WIDTH * 0.5, ay + Character.CHAR_HEIGHT * 0.5), 6.0, Color.YELLOW)
		if pt.magnet_a_trigger:
			draw_rect(Rect2(Vector2(sx, ay - 4), Vector2(4, 4)), Color.WHITE)
		if pt.magnet_b_trigger:
			draw_rect(Rect2(Vector2(sx, by - 4), Vector2(4, 4)), Color.WHITE)

func _check_game_over() -> void:
	if not character_a.is_alive or not character_b.is_alive:
		character_a.die()
		character_b.die()
		GameManager.end_game()
		return
	if spike.is_character_hit(character_a) or spike.is_character_hit(character_b):
		character_a.die()
		character_b.die()
		GameManager.end_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
