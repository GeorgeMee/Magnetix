class_name TrajectoryPoint
extends RefCounted

var world_x : float
var char_a_surface : int
var char_b_surface : int
var swap_trigger : bool
var magnet_a_trigger : bool
var magnet_b_trigger : bool

func _init(p_x : float, p_a_surf : int, p_b_surf : int, p_swap : bool, p_mag_a : bool, p_mag_b : bool) -> void:
	world_x = p_x
	char_a_surface = p_a_surf
	char_b_surface = p_b_surf
	swap_trigger = p_swap
	magnet_a_trigger = p_mag_a
	magnet_b_trigger = p_mag_b
