class_name ScrollManager
extends Node

var world_offset : float = 0.0

var top_lane_speed : float = 200.0
var bottom_lane_speed : float = 200.0

func _process(delta : float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	top_lane_speed = GameManager.lane_top_scroll_speed
	bottom_lane_speed = GameManager.lane_bottom_scroll_speed
	world_offset += top_lane_speed * delta

func world_to_screen_x(world_x : float) -> float:
	return world_x - world_offset + GameManager.player_fixed_x

func screen_to_world_x(screen_x : float) -> float:
	return screen_x - GameManager.player_fixed_x + world_offset

func get_lane_speed(lane : int) -> float:
	if lane == 0:
		return top_lane_speed
	return bottom_lane_speed
