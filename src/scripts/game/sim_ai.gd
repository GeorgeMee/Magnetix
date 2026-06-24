class_name SimAI
extends RefCounted

enum Surface { FLOOR, CEILING }

var rng : RandomNumberGenerator

func generate(initial_a_pol : Magnet.Polarity, initial_b_pol : Magnet.Polarity, start_world_x : float, length : float, interval : float) -> Array[TrajectoryPoint]:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	var points : Array[TrajectoryPoint] = []
	var current_x := start_world_x
	var surf_a := Surface.FLOOR
	var surf_b := Surface.FLOOR
	var last_decision_lane := -1

	while current_x < start_world_x + length:
		var swap_trigger := false
		var mag_a := false
		var mag_b := false

		var decision := rng.randi_range(0, 2)
		if decision == 2:
			swap_trigger = true
		elif decision == 0:
			if last_decision_lane == 0 and rng.randi_range(0, 2) > 0:
				decision = 1
			surf_a = Surface.CEILING if surf_a == Surface.FLOOR else Surface.FLOOR
			mag_a = true
			last_decision_lane = 0
		else:
			if last_decision_lane == 1 and rng.randi_range(0, 2) > 0:
				decision = 0
				surf_a = Surface.CEILING if surf_a == Surface.FLOOR else Surface.FLOOR
				mag_a = true
				last_decision_lane = 0
			else:
				surf_b = Surface.CEILING if surf_b == Surface.FLOOR else Surface.FLOOR
				mag_b = true
				last_decision_lane = 1

		points.append(TrajectoryPoint.new(current_x, surf_a, surf_b, swap_trigger, mag_a, mag_b))
		current_x += interval

	return points
