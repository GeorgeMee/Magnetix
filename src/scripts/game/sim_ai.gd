class_name SimAI
extends RefCounted

enum Surface { FLOOR, CEILING }

var rng : RandomNumberGenerator

func generate(initial_a_pol : Magnet.Polarity, initial_b_pol : Magnet.Polarity, start_world_x : float, length : float, interval : float, start_surf_a := Surface.FLOOR, start_surf_b := Surface.FLOOR) -> Array[TrajectoryPoint]:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	var points : Array[TrajectoryPoint] = []
	var current_x := start_world_x
	var surf_a := start_surf_a
	var surf_b := start_surf_b
	var last_lane := -1

	while current_x < start_world_x + length:
		var swap_trigger := false
		var mag_a := false
		var mag_b := false
		var chosen_lane := -1

		var r := rng.randf()
		if r < 0.2:
			swap_trigger = true
		elif r < 0.6:
			chosen_lane = 0
		else:
			chosen_lane = 1

		if chosen_lane == last_lane and chosen_lane >= 0:
			chosen_lane = 1 - chosen_lane

		if chosen_lane == 0:
			surf_a = Surface.CEILING if surf_a == Surface.FLOOR else Surface.FLOOR
			mag_a = true
		elif chosen_lane == 1:
			surf_b = Surface.CEILING if surf_b == Surface.FLOOR else Surface.FLOOR
			mag_b = true

		last_lane = chosen_lane
		points.append(TrajectoryPoint.new(current_x, surf_a, surf_b, swap_trigger, mag_a, mag_b))
		current_x += interval

	return points
