class_name Spike
extends Node2D

@export var offset_from_left : float = 80.0
@export var chase_speed : float = 40.0

var spike_x : float = 0.0

func _ready() -> void:
	spike_x = offset_from_left

func _process(delta : float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	spike_x += chase_speed * delta
	position.x = spike_x
	queue_redraw()

func _draw() -> void:
	var spike_color := Color.RED
	spike_color.a = 0.7
	var spike_width := 30.0
	var spike_height := 1080.0
	draw_rect(Rect2(Vector2(0, 0), Vector2(spike_width, spike_height)), spike_color)

	var points := PackedVector2Array()
	points.append(Vector2(0, 0))
	points.append(Vector2(spike_width, spike_height * 0.5))
	points.append(Vector2(0, spike_height))
	draw_colored_polygon(points, Color.RED.darkened(0.3))

func get_danger_x() -> float:
	return spike_x

func is_character_hit(character : Character) -> bool:
	return character.physics_body.position.x <= spike_x
