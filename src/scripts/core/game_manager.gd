extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var state : GameState = GameState.MENU
var score : float = 0.0
var distance : float = 0.0

var lane_top_scroll_speed : float = 200.0
var lane_bottom_scroll_speed : float = 200.0
var base_scroll_speed : float = 200.0
var scroll_acceleration : float = 5.0

var player_fixed_x : float = 300.0
var lane_top_y : float = 0.0
var lane_bottom_y : float = 0.0
var ceiling_offset : float = 120.0

var physics_system : PhysicsSystem
var scroll_manager : ScrollManager
var magnet_manager : MagnetManager

var character_a : Character
var character_b : Character
var coin_red : int = 0
var coin_blue : int = 0
var coin_rainbow : int = 0

var magnetism_duration : float = 3.0
var magnetism_cooldown : float = 2.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta : float) -> void:
	if state == GameState.PLAYING:
		distance += base_scroll_speed * delta
		score = distance
		lane_top_scroll_speed = base_scroll_speed
		lane_bottom_scroll_speed = base_scroll_speed

func start_game() -> void:
	state = GameState.PLAYING
	score = 0.0
	distance = 0.0
	base_scroll_speed = 200.0
	coin_red = 0
	coin_blue = 0
	coin_rainbow = 0

func end_game() -> void:
	state = GameState.GAME_OVER

func pause_game() -> void:
	if state == GameState.PLAYING:
		state = GameState.PAUSED

func resume_game() -> void:
	if state == GameState.PAUSED:
		state = GameState.PLAYING

func set_lane_speed(lane : int, speed : float) -> void:
	match lane:
		0:
			lane_top_scroll_speed = speed
		1:
			lane_bottom_scroll_speed = speed

func get_lane_speed(lane : int) -> float:
	match lane:
		0:
			return lane_top_scroll_speed
		1:
			return lane_bottom_scroll_speed
	return lane_top_scroll_speed
