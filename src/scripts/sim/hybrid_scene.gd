extends Node2D

const AI_FIXED_X := 2500.0

@onready var physics_system: PhysicsSystem = $PhysicsSystem
@onready var scroll_manager: ScrollManager = $ScrollManager
@onready var magnet_manager: MagnetManager = $MagnetManager
@onready var choreographer: ChunkChoreographer = $ChunkChoreographer
@onready var sim_controller: SimController = $SimController
@onready var input_manager: InputManager = $InputManager
@onready var spike: Spike = $Spike
@onready var game_hud: GameHUD = $GameHUD

var ai_character_a: Character
var ai_character_b: Character
var player_character_a: Character
var player_character_b: Character
var character_scene: PackedScene = preload("res://src/scenes/game/character.tscn")

func _ready() -> void:
	GameManager.sim_mode = true
	GameManager.physics_system = physics_system
	GameManager.scroll_manager = scroll_manager
	GameManager.magnet_manager = magnet_manager
	GameManager.choreographer = choreographer

	_spawn_ai_characters()
	_spawn_player_characters()
	_connect_input()
	GameManager.character_a = player_character_a
	GameManager.character_b = player_character_b

	_ensure_trajectory()
	sim_controller.setup(ai_character_a, ai_character_b, choreographer)
	sim_controller.enable_swap = false
	game_hud.update_button_colors(player_character_a.character_color, player_character_b.character_color)
	GameManager.start_game()

func _spawn_ai_characters() -> void:
	ai_character_a = character_scene.instantiate()
	ai_character_a.lane = Character.Lane.TOP
	ai_character_a.character_polarity = Magnet.Polarity.NORTH
	ai_character_a.character_color = Color.DODGER_BLUE
	ai_character_a.custom_fixed_x = AI_FIXED_X
	add_child(ai_character_a)

	ai_character_b = character_scene.instantiate()
	ai_character_b.lane = Character.Lane.BOTTOM
	ai_character_b.character_polarity = Magnet.Polarity.SOUTH
	ai_character_b.character_color = Color.ORANGE_RED
	ai_character_b.custom_fixed_x = AI_FIXED_X
	add_child(ai_character_b)

func _spawn_player_characters() -> void:
	player_character_a = character_scene.instantiate()
	player_character_a.lane = Character.Lane.TOP
	player_character_a.character_polarity = Magnet.Polarity.NORTH
	player_character_a.character_color = Color.DODGER_BLUE
	add_child(player_character_a)

	player_character_b = character_scene.instantiate()
	player_character_b.lane = Character.Lane.BOTTOM
	player_character_b.character_polarity = Magnet.Polarity.SOUTH
	player_character_b.character_color = Color.ORANGE_RED
	add_child(player_character_b)

func _connect_input() -> void:
	input_manager.magnetism_a_toggled.connect(player_character_a.toggle_magnetism)
	input_manager.magnetism_b_toggled.connect(player_character_b.toggle_magnetism)
	input_manager.swap_pressed.connect(_on_swap)
	game_hud.magnetism_a_toggled.connect(player_character_a.toggle_magnetism)
	game_hud.magnetism_b_toggled.connect(player_character_b.toggle_magnetism)
	game_hud.swap_pressed.connect(_on_swap)

func _on_swap() -> void:
	var tmp_color := player_character_a.character_color
	var tmp_polarity := player_character_a.character_polarity
	player_character_a.character_color = player_character_b.character_color
	player_character_a.character_polarity = player_character_b.character_polarity
	player_character_b.character_color = tmp_color
	player_character_b.character_polarity = tmp_polarity
	game_hud.update_button_colors(player_character_a.character_color, player_character_b.character_color)
	_ensure_trajectory()

func _process(_delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	_ensure_trajectory()
	_check_game_over()
	queue_redraw()

func _draw() -> void:
	_draw_lane(GameManager.lane_top_y, Color.WEB_GREEN)
	_draw_lane(GameManager.lane_bottom_y, Color.WEB_GREEN)

func _draw_lane(floor_y: float, color: Color) -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), color, 3.0)
	draw_line(Vector2(0, floor_y - GameManager.ceiling_offset), Vector2(vp_w, floor_y - GameManager.ceiling_offset), color.darkened(0.4), 2.0)

func _check_game_over() -> void:
	if not player_character_a.is_alive or not player_character_b.is_alive:
		player_character_a.die()
		player_character_b.die()
		ai_character_a.die()
		ai_character_b.die()
		GameManager.end_game()
		return
	if spike.is_character_hit(player_character_a) or spike.is_character_hit(player_character_b):
		player_character_a.die()
		player_character_b.die()
		ai_character_a.die()
		ai_character_b.die()
		GameManager.end_game()

func _ensure_trajectory() -> void:
	if not player_character_a or not player_character_b:
		return
	var from_x := scroll_manager.screen_to_world_x(1920)
	choreographer.ensure_trajectory(from_x, player_character_a.character_polarity, player_character_b.character_polarity)
	GameManager.trajectory_data = choreographer.trajectory

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
