class_name AABB
extends RefCounted

var position : Vector2
var size : Vector2

func _init(p_pos : Vector2 = Vector2.ZERO, p_size : Vector2 = Vector2.ZERO) -> void:
	position = p_pos
	size = p_size

func get_left() -> float:
	return position.x

func get_right() -> float:
	return position.x + size.x

func get_top() -> float:
	return position.y

func get_bottom() -> float:
	return position.y + size.y

func get_center() -> Vector2:
	return position + size * 0.5

func overlaps(other : AABB) -> bool:
	if get_right() <= other.get_left() or other.get_right() <= get_left():
		return false
	if get_bottom() <= other.get_top() or other.get_bottom() <= get_top():
		return false
	return true
