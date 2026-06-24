class_name ChunkChoreographer
extends Node

var sim_ai : SimAI
var trajectory : Array[TrajectoryPoint] = []
var rng : RandomNumberGenerator

func _ready() -> void:
	sim_ai = SimAI.new()
	rng = RandomNumberGenerator.new()
	rng.randomize()

func ensure_trajectory(from_world_x : float, lane_a_pol : Magnet.Polarity, lane_b_pol : Magnet.Polarity) -> void:
	var needed_length := GameManager.sim_chunks_ahead * GameManager.chunk_width
	var needed_end := from_world_x + needed_length
	if trajectory.size() > 0 and trajectory[-1].world_x >= needed_end:
		return
	var start_x := from_world_x
	if trajectory.size() > 0:
		start_x = maxf(trajectory[-1].world_x, from_world_x)
	trajectory = sim_ai.generate(lane_a_pol, lane_b_pol, start_x, needed_length, GameManager.sim_decision_interval)

func get_chunk_layout(chunk_world_x : float, lane : int, chunk_width : float) -> ChunkLayout:
	var layout := ChunkLayout.new()
	var lane_traj : Array[Dictionary] = []
	for pt in trajectory:
		if pt.world_x < chunk_world_x or pt.world_x >= chunk_world_x + chunk_width:
			continue
		var surf := pt.char_a_surface if lane == 0 else pt.char_b_surface
		var mag_trig := pt.magnet_a_trigger if lane == 0 else pt.magnet_b_trigger
		lane_traj.append({"world_x": pt.world_x, "surface": surf, "mag_trigger": mag_trig, "swap": pt.swap_trigger})

	var last_surface := Character.Surface.FLOOR
	var floor_start_x := chunk_world_x

	for entry in lane_traj:
		if entry["mag_trigger"]:
			var placement : Magnet.Placement
			var pol : Magnet.Polarity
			var cur_pol : Magnet.Polarity
			if lane == 0:
				cur_pol = GameManager.character_a.character_polarity if GameManager.character_a else Magnet.Polarity.NORTH
			else:
				cur_pol = GameManager.character_b.character_polarity if GameManager.character_b else Magnet.Polarity.SOUTH

			if entry["surface"] == Character.Surface.CEILING:
				placement = Magnet.Placement.FLOOR
				pol = cur_pol
			else:
				placement = Magnet.Placement.CEILING
				pol = cur_pol

			layout.magnets.append({
				"world_x": entry["world_x"],
				"placement": placement,
				"polarity": pol,
				"length": 160.0
			})

		if entry["surface"] != last_surface:
			last_surface = entry["surface"]

	_layout_coins(layout, lane_traj, chunk_world_x, chunk_width)
	_layout_walls_and_hazards(layout, lane_traj, chunk_world_x, chunk_width)

	return layout

func _layout_coins(layout : ChunkLayout, lane_traj : Array, chunk_start : float, chunk_width : float) -> void:
	var coin_step := 120.0
	var cy := 80.0
	for x := chunk_start + 40.0; x < chunk_start + chunk_width - 40.0; x += coin_step:
		if rng.randi_range(0, 3) == 0:
			continue
		var ctype : int = Coin.Type.BLUE
		var r := rng.randi_range(0, 9)
		if r < 4:
			ctype = Coin.Type.BLUE
		elif r < 8:
			ctype = Coin.Type.RED
		else:
			ctype = Coin.Type.RAINBOW
		layout.coins.append({"world_x": x, "type": ctype, "y_off": cy + rng.randf_range(-20.0, 20.0)})

func _layout_walls_and_hazards(layout : ChunkLayout, lane_traj : Array, chunk_start : float, chunk_width : float) -> void:
	var has_wall := false
	for entry in lane_traj:
		if entry["surface"] == Character.Surface.FLOOR and not has_wall and rng.randi_range(0, 2) == 0:
			layout.walls.append({"world_x": entry["world_x"] + 40.0})
			has_wall = true
		if entry["surface"] == Character.Surface.CEILING and rng.randi_range(0, 4) == 0:
			layout.hazards.append({"world_x": entry["world_x"] + 20.0})
