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
	var pol := _get_cur_pol(lane)
	return build_layout(trajectory, chunk_world_x, lane, chunk_width, pol)

func build_layout(traj : Array[TrajectoryPoint], chunk_world_x : float, lane : int, chunk_width : float, pol : Magnet.Polarity) -> ChunkLayout:
	var layout := ChunkLayout.new()

	var pts_in_range : Array[TrajectoryPoint] = []
	for pt in traj:
		if pt.world_x >= chunk_world_x - chunk_width and pt.world_x < chunk_world_x + chunk_width * 2:
			pts_in_range.append(pt)

	if pts_in_range.size() == 0:
		return layout

	_place_magnets_with_pol(layout, pts_in_range, lane, pol)
	_place_coins(layout, pts_in_range, lane, chunk_world_x, chunk_width)
	_place_walls(layout, pts_in_range, lane, chunk_world_x, chunk_width)
	_place_hazards(layout, pts_in_range, lane, chunk_world_x, chunk_width)

	return layout

func _get_surface(pt : TrajectoryPoint, lane : int) -> int:
	return pt.char_a_surface if lane == 0 else pt.char_b_surface

func _get_cur_pol(lane : int) -> Magnet.Polarity:
	if lane == 0:
		return GameManager.character_a.character_polarity if GameManager.character_a else Magnet.Polarity.NORTH
	return GameManager.character_b.character_polarity if GameManager.character_b else Magnet.Polarity.SOUTH

func _place_magnets_with_pol(layout : ChunkLayout, pts : Array[TrajectoryPoint], lane : int, pol : Magnet.Polarity) -> void:
	var in_ceiling_zone := false
	var zone_start_x : float = 0.0
	var mag_length := GameManager.sim_decision_interval * 1.2

	for i in range(pts.size()):
		var pt := pts[i]
		var surf := _get_surface(pt, lane)
		var next_surf := _get_surface(pts[i + 1], lane) if i + 1 < pts.size() else surf

		if surf == Character.Surface.CEILING and not in_ceiling_zone:
			in_ceiling_zone = true
			zone_start_x = pt.world_x
		elif surf == Character.Surface.FLOOR and in_ceiling_zone:
			in_ceiling_zone = false
			var end_x := pt.world_x
			var x := zone_start_x
			while x < end_x:
				var mag_x := x
				var place_len := minf(mag_length, end_x - x)
				var placement := Magnet.Placement.FLOOR
				layout.magnets.append({"world_x": mag_x, "placement": placement, "polarity": pol, "length": place_len})
				x += mag_length

		if in_ceiling_zone and i == pts.size() - 1:
			var end_x := pt.world_x + mag_length
			var x := zone_start_x
			while x < end_x:
				var mag_x := x
				layout.magnets.append({"world_x": mag_x, "placement": Magnet.Placement.FLOOR, "polarity": pol, "length": minf(mag_length, end_x - x)})
				x += mag_length

func _place_coins(layout : ChunkLayout, pts : Array[TrajectoryPoint], lane : int, chunk_start : float, chunk_width : float) -> void:
	var coin_gap := 100.0
	var x : float = chunk_start + 30.0
	while x < chunk_start + chunk_width - 30.0:
		x += coin_gap
		if rng.randi_range(0, 4) == 0:
			continue
		var ctype : int = Coin.Type.BLUE
		var r := rng.randi_range(0, 9)
		if r < 4:
			ctype = Coin.Type.BLUE
		elif r < 8:
			ctype = Coin.Type.RED
		else:
			ctype = Coin.Type.RAINBOW
		var surf := Character.Surface.FLOOR
		for pt in pts:
			if pt.world_x > x:
				break
			surf = _get_surface(pt, lane)
		var base_y := 15.0 if surf == Character.Surface.FLOOR else GameManager.ceiling_offset - 15.0
		var y_off := base_y + rng.randf_range(-20.0, 20.0)
		y_off = clampf(y_off, 15.0, GameManager.ceiling_offset - 15.0)
		layout.coins.append({"world_x": x, "type": ctype, "y_off": y_off})

func _place_walls(layout : ChunkLayout, pts : Array[TrajectoryPoint], lane : int, chunk_start : float, chunk_width : float) -> void:
	for i in range(pts.size() - 1):
		var pt := pts[i]
		var next_pt := pts[i + 1]
		var surf := _get_surface(pt, lane)
		var next_surf := _get_surface(next_pt, lane)

		if surf != Character.Surface.FLOOR:
			continue

		if next_surf == Character.Surface.CEILING:
			var wall_x := next_pt.world_x - 30.0
			if wall_x >= chunk_start and wall_x < chunk_start + chunk_width:
				if rng.randi_range(0, 2) > 0:
					layout.walls.append({"world_x": wall_x})

		if pt.world_x < chunk_start or pt.world_x >= chunk_start + chunk_width:
			continue

		var floor_duration := next_pt.world_x - pt.world_x
		if floor_duration > GameManager.sim_decision_interval * 1.8 and next_surf == Character.Surface.FLOOR:
			if rng.randi_range(0, 1) == 0:
				layout.walls.append({"world_x": pt.world_x + floor_duration * 0.7})

func _place_hazards(layout : ChunkLayout, pts : Array[TrajectoryPoint], lane : int, chunk_start : float, chunk_width : float) -> void:
	for pt in pts:
		if pt.world_x < chunk_start or pt.world_x >= chunk_start + chunk_width:
			continue
		var surf := _get_surface(pt, lane)
		if surf == Character.Surface.CEILING and rng.randi_range(0, 3) == 0:
			layout.hazards.append({"world_x": pt.world_x + 20.0})
