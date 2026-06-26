class_name TrajectoryPoint
extends Resource

@export var world_x : float
@export var char_a_surface : int
@export var char_b_surface : int
@export var swap_trigger : bool
@export var magnet_a_trigger : bool
@export var magnet_b_trigger : bool

func _init(p_x : float = 0.0, p_a_surf : int = 0, p_b_surf : int = 0, p_swap : bool = false, p_mag_a : bool = false, p_mag_b : bool = false) -> void:
	world_x = p_x
	char_a_surface = p_a_surf
	char_b_surface = p_b_surf
	swap_trigger = p_swap
	magnet_a_trigger = p_mag_a
	magnet_b_trigger = p_mag_b
