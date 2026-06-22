class_name Spike
extends Node2D

@export var offset_from_left : float = 80.0

func _ready() -> void:
	position.x = offset_from_left

func _draw() -> void:
	var spike_color := Color.RED
	spike_color.a = 0.7
	var spike_width := 30.0
	var viewport_height := get_viewport().get_visible_rect().size.y
	draw_rect(Rect2(Vector2(0, 0), Vector2(spike_width, viewport_height)), spike_color)

	var points := PackedVector2Array()
	points.append(Vector2(0, 0))
	points.append(Vector2(spike_width, viewport_height * 0.5))
	points.append(Vector2(0, viewport_height))
	draw_colored_polygon(points, Color.RED.darkened(0.3))

func get_danger_x() -> float:
	return offset_from_left

func is_character_hit(character : Character) -> bool:
	return character.physics_body.position.x <= offset_from_left
