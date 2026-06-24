class_name SimController
extends Node

var character_a: Character
var character_b: Character
var choreographer: ChunkChoreographer
var tracked_index_a := -1
var tracked_index_b := -1
var tracked_swap_index := -1

func setup(ca: Character, cb: Character, chor: ChunkChoreographer) -> void:
	character_a = ca
	character_b = cb
	choreographer = chor

func _process(_delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	var sim_time := GameManager.scroll_manager.world_offset
	_check_a(sim_time)
	_check_b(sim_time)
	_check_swap(sim_time)

func _check_a(sim_time: float) -> void:
	var traj := choreographer.trajectory
	for i in range(max(tracked_index_a + 1, 0), traj.size()):
		var pt := traj[i]
		if pt.world_x > sim_time:
			break
		tracked_index_a = i
		var target_ceil := pt.char_a_surface == SimAI.Surface.CEILING
		if target_ceil and not character_a.magnetism_active:
			character_a.toggle_magnetism()
		elif not target_ceil and character_a.magnetism_active:
			character_a.toggle_magnetism()

func _check_b(sim_time: float) -> void:
	var traj := choreographer.trajectory
	for i in range(max(tracked_index_b + 1, 0), traj.size()):
		var pt := traj[i]
		if pt.world_x > sim_time:
			break
		tracked_index_b = i
		var target_ceil := pt.char_b_surface == SimAI.Surface.CEILING
		if target_ceil and not character_b.magnetism_active:
			character_b.toggle_magnetism()
		elif not target_ceil and character_b.magnetism_active:
			character_b.toggle_magnetism()

func _check_swap(sim_time: float) -> void:
	var traj := choreographer.trajectory
	for i in range(max(tracked_swap_index + 1, 0), traj.size()):
		var pt := traj[i]
		if pt.world_x > sim_time:
			break
		tracked_swap_index = i
		if pt.swap_trigger:
			_do_swap()

func _do_swap() -> void:
	var tmp_color := character_a.character_color
	var tmp_polarity := character_a.character_polarity
	character_a.character_color = character_b.character_color
	character_a.character_polarity = character_b.character_polarity
	character_b.character_color = tmp_color
	character_b.character_polarity = tmp_polarity
