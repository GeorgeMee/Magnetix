extends Node2D

const GENERATE_DURATION := 15.0

@onready var physics_system: PhysicsSystem = $PhysicsSystem
@onready var scroll_manager: ScrollManager = $ScrollManager
@onready var magnet_manager: MagnetManager = $MagnetManager
@onready var choreographer: ChunkChoreographer = $ChunkChoreographer
@onready var sim_controller: SimController = $SimController
@onready var ui_label: Label = $UILayer/Label

var character_a: Character
var character_b: Character
var character_scene: PackedScene = preload("res://src/scenes/game/character.tscn")
var last_recorded_wx: float = 0.0
var elapsed: float = 0.0
var transitioned := false

func _ready() -> void:
	GameManager.sim_mode = true
	GameManager.stored_layouts.clear()
	GameManager.physics_system = physics_system
	GameManager.scroll_manager = scroll_manager
	GameManager.magnet_manager = magnet_manager
	GameManager.choreographer = choreographer

	_spawn_characters()
	GameManager.character_a = character_a
	GameManager.character_b = character_b

	_ensure_trajectory()
	sim_controller.setup(character_a, character_b, choreographer)
	sim_controller.enable_swap = false
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

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING or transitioned:
		return
	elapsed += delta
	_ensure_trajectory()
	_record_layouts()
	queue_redraw()

	var pct := minf(elapsed / GENERATE_DURATION * 100.0, 100.0)
	ui_label.text = "生成中... %.0f%% (%d 场景块)" % [pct, GameManager.stored_layouts.size()]
	if elapsed >= GENERATE_DURATION:
		_transition_to_play()

func _record_layouts() -> void:
	var chunk_w := GameManager.chunk_width
	var traj := choreographer.trajectory
	if traj.is_empty():
		return
	var max_wx := traj[-1].world_x
	while last_recorded_wx < max_wx:
		var wx := last_recorded_wx
		var layout_a := choreographer.build_layout(traj, wx, 0, chunk_w, Magnet.Polarity.NORTH)
		var layout_b := choreographer.build_layout(traj, wx, 1, chunk_w, Magnet.Polarity.SOUTH)
		GameManager.stored_layouts.append({"world_x": wx, "layout_a": layout_a, "layout_b": layout_b})
		last_recorded_wx += chunk_w

func _draw() -> void:
	_draw_lane(GameManager.lane_top_y, Color.WEB_GREEN)
	_draw_lane(GameManager.lane_bottom_y, Color.WEB_GREEN)

func _draw_lane(floor_y: float, color: Color) -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	draw_line(Vector2(0, floor_y), Vector2(vp_w, floor_y), color, 3.0)
	draw_line(Vector2(0, floor_y - GameManager.ceiling_offset), Vector2(vp_w, floor_y - GameManager.ceiling_offset), color.darkened(0.4), 2.0)

func _ensure_trajectory() -> void:
	if not character_a or not character_b:
		return
	var from_x := scroll_manager.screen_to_world_x(1920)
	choreographer.ensure_trajectory(from_x, character_a.character_polarity, character_b.character_polarity)
	GameManager.trajectory_data = choreographer.trajectory

func _transition_to_play() -> void:
	transitioned = true
	GameManager.character_a = null
	GameManager.character_b = null
	get_tree().change_scene_to_file("res://src/scenes/sim/play_scene.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.stored_layouts.clear()
		get_tree().change_scene_to_file("res://src/scenes/ui/start_menu.tscn")
