extends Node2D

@onready var physics_system : PhysicsSystem = $PhysicsSystem
@onready var scroll_manager : ScrollManager = $ScrollManager
@onready var magnet_manager : MagnetManager = $MagnetManager
@onready var input_manager : InputManager = $InputManager
@onready var spike : Spike = $Spike
@onready var game_hud : GameHUD = $GameHUD

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

	_spawn_characters()
	_connect_input()
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
	input_manager.magnetism_a_pressed.connect(character_a.activate_magnetism)
	input_manager.magnetism_a_released.connect(character_a.deactivate_magnetism)
	input_manager.magnetism_b_pressed.connect(character_b.activate_magnetism)
	input_manager.magnetism_b_released.connect(character_b.deactivate_magnetism)
	input_manager.swap_pressed.connect(_on_swap)

	game_hud.magnetism_a_pressed.connect(character_a.activate_magnetism)
	game_hud.magnetism_a_released.connect(character_a.deactivate_magnetism)
	game_hud.magnetism_b_pressed.connect(character_b.activate_magnetism)
	game_hud.magnetism_b_released.connect(character_b.deactivate_magnetism)
	game_hud.swap_pressed.connect(_on_swap)

func _on_swap() -> void:
	character_a.swap_lane()
	character_b.swap_lane()

func _process(delta : float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	_check_game_over()
	queue_redraw()

func _draw() -> void:
	_draw_lane(GameManager.lane_top_y, Color.WEB_GREEN)
	_draw_lane(GameManager.lane_bottom_y, Color.WEB_GREEN)
	var viewport_size := get_viewport().get_visible_rect().size
	draw_rect(Rect2(Vector2(0, 0), viewport_size), Color.BLACK, false, 4.0)

func _draw_lane(floor_y : float, color : Color) -> void:
	var viewport_width := get_viewport().get_visible_rect().size.x
	draw_line(Vector2(0, floor_y), Vector2(viewport_width, floor_y), color, 3.0)
	var ceiling_y := floor_y - GameManager.ceiling_offset
	draw_line(Vector2(0, ceiling_y), Vector2(viewport_width, ceiling_y), color.darkened(0.4), 2.0)

func _check_game_over() -> void:
	if not character_a.is_alive or not character_b.is_alive:
		return
	if spike.is_character_hit(character_a) or spike.is_character_hit(character_b):
		character_a.die()
		character_b.die()
		GameManager.end_game()

func get_characters() -> Array[Character]:
	return [character_a, character_b]
