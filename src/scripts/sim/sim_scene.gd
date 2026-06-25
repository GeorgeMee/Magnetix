extends Node2D

@onready var physics_system: PhysicsSystem = $PhysicsSystem
@onready var scroll_manager: ScrollManager = $ScrollManager
@onready var magnet_manager: MagnetManager = $MagnetManager
@onready var choreographer: ChunkChoreographer = $ChunkChoreographer
@onready var sim_controller: SimController = $SimController

var character_a: Character
var character_b: Character
var character_scene: PackedScene = preload("res://src/scenes/game/character.tscn")

func _ready() -> void:
	GameManager.sim_mode = true
	GameManager.physics_system = physics_system
	GameManager.scroll_manager = scroll_manager
	GameManager.magnet_manager = magnet_manager
	GameManager.choreographer = choreographer

	_spawn_characters()
	GameManager.character_a = character_a
	GameManager.character_b = character_b

	_ensure_trajectory()
	sim_controller.setup(character_a, character_b, choreographer)
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

func _process(_delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	_ensure_trajectory()
	queue_redraw()

func _draw() -> void:
	_draw_lane(GameManager.lane_top_y, Color.WEB_GREEN)
	_draw_lane(GameManager.lane_bottom_y, Color.WEB_GREEN)
	_draw_trajectory_debug()

func _draw_lane(floor_y: float, color: Color) -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), color, 3.0)
	draw_line(Vector2(0, floor_y - GameManager.ceiling_offset), Vector2(vp_w, floor_y - GameManager.ceiling_offset), color.darkened(0.4), 2.0)

func _draw_trajectory_debug() -> void:
	for pt in choreographer.trajectory:
		var sx := scroll_manager.world_to_screen_x(pt.world_x)
		if sx < -100 or sx > get_viewport().get_visible_rect().size.x + 100:
			continue
		if pt.swap_trigger:
			draw_circle(Vector2(sx, GameManager.lane_top_y - GameManager.ceiling_offset * 0.5), 6.0, Color.YELLOW)
		if pt.magnet_a_trigger:
			draw_circle(Vector2(sx, GameManager.lane_top_y - 10), 4.0, Color.WHITE)
		if pt.magnet_b_trigger:
			draw_circle(Vector2(sx, GameManager.lane_bottom_y - 10), 4.0, Color.WHITE)

func _ensure_trajectory() -> void:
	if not character_a or not character_b:
		return
	var from_x := scroll_manager.screen_to_world_x(1920)
	choreographer.ensure_trajectory(from_x, character_a.character_polarity, character_b.character_polarity)
	GameManager.trajectory_data = choreographer.trajectory

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
