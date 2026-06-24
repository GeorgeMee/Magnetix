extends Node2D

@onready var physics_system : PhysicsSystem = $PhysicsSystem
@onready var scroll_manager : ScrollManager = $ScrollManager
@onready var magnet_manager : MagnetManager = $MagnetManager
@onready var input_manager : InputManager = $InputManager
@onready var spike : Spike = $Spike
@onready var game_hud : GameHUD = $GameHUD
@onready var choreographer : ChunkChoreographer = $ChunkChoreographer

var character_a : Character
var character_b : Character
var character_scene : PackedScene = preload("res://src/scenes/game/character.tscn")

func _ready() -> void:
	GameManager.physics_system = physics_system
	GameManager.scroll_manager = scroll_manager
	GameManager.magnet_manager = magnet_manager
	GameManager.lane_top_y = 300.0
	GameManager.lane_bottom_y = 750.0
	GameManager.ceiling_offset = 180.0
	GameManager.player_fixed_x = 500.0
	GameManager.choreographer = choreographer

	_spawn_characters()
	GameManager.character_a = character_a
	GameManager.character_b = character_b
	_connect_input()
	_ensure_trajectory()
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
	_ensure_trajectory()

func _process(delta : float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	_ensure_trajectory()
	_check_game_over()
	queue_redraw()

func _draw() -> void:
	_draw_lane(GameManager.lane_top_y, Color.WEB_GREEN)
	_draw_lane(GameManager.lane_bottom_y, Color.WEB_GREEN)
	var viewport_size := get_viewport().get_visible_rect().size
	draw_rect(Rect2(Vector2(0, 0), viewport_size), Color.BLACK, false, 4.0)
	if GameManager.debug_visualize:
		_draw_trajectory()

func _draw_trajectory() -> void:
	for pt in GameManager.trajectory_data:
		var sx := GameManager.scroll_manager.world_to_screen_x(pt.world_x)
		var ay : float
		var by : float
		if pt.char_a_surface == Character.Surface.CEILING:
			ay = GameManager.lane_top_y - GameManager.ceiling_offset
		else:
			ay = GameManager.lane_top_y - Character.CHAR_HEIGHT
		if pt.char_b_surface == Character.Surface.CEILING:
			by = GameManager.lane_bottom_y - GameManager.ceiling_offset
		else:
			by = GameManager.lane_bottom_y - Character.CHAR_HEIGHT
		draw_rect(Rect2(Vector2(sx, ay), Vector2(Character.CHAR_WIDTH, Character.CHAR_HEIGHT)), Color(Color.DODGER_BLUE, 0.3), false, 1.0)
		draw_rect(Rect2(Vector2(sx, by), Vector2(Character.CHAR_WIDTH, Character.CHAR_HEIGHT)), Color(Color.ORANGE_RED, 0.3), false, 1.0)
		if pt.swap_trigger:
			draw_circle(Vector2(sx + Character.CHAR_WIDTH * 0.5, ay + Character.CHAR_HEIGHT * 0.5), 6.0, Color.YELLOW)
		if pt.magnet_a_trigger:
			draw_rect(Rect2(Vector2(sx, ay - 4), Vector2(4, 4)), Color.WHITE)
		if pt.magnet_b_trigger:
			draw_rect(Rect2(Vector2(sx, by - 4), Vector2(4, 4)), Color.WHITE)

func _draw_lane(floor_y : float, color : Color) -> void:
	var viewport_width := get_viewport().get_visible_rect().size.x
	draw_line(Vector2(0, floor_y), Vector2(viewport_width, floor_y), color, 3.0)
	var ceiling_y := floor_y - GameManager.ceiling_offset
	draw_line(Vector2(0, ceiling_y), Vector2(viewport_width, ceiling_y), color.darkened(0.4), 2.0)

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

func _ensure_trajectory() -> void:
	if not character_a or not character_b:
		return
	var from_x := GameManager.scroll_manager.screen_to_world_x(1920)
	choreographer.ensure_trajectory(from_x, character_a.character_polarity, character_b.character_polarity)
	GameManager.trajectory_data = choreographer.trajectory

func get_characters() -> Array[Character]:
	return [character_a, character_b]
