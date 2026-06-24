class_name PhysicsSystem
extends Node

var bodies : Array[CustBody]
var static_bodies : Array[CustBody]
var hazard_bodies : Array[CustBody]

func _ready() -> void:
	bodies = []
	static_bodies = []
	hazard_bodies = []

func register_body(body : CustBody) -> void:
	if bodies.has(body):
		return
	bodies.append(body)

func unregister_body(body : CustBody) -> void:
	bodies.erase(body)

func register_static_body(body : CustBody) -> void:
	if static_bodies.has(body):
		return
	static_bodies.append(body)

func unregister_static_body(body : CustBody) -> void:
	static_bodies.erase(body)

func register_hazard_body(body : CustBody) -> void:
	if hazard_bodies.has(body):
		return
	hazard_bodies.append(body)

func unregister_hazard_body(body : CustBody) -> void:
	hazard_bodies.erase(body)

func is_overlapping_hazard(body : CustBody) -> bool:
	var d_aabb := body.get_aabb()
	for hb in hazard_bodies:
		if d_aabb.overlaps(hb.get_aabb()):
			return true
	return false

func step(_delta : float) -> void:
	for body in bodies:
		for static_body in static_bodies:
			_resolve_collision(body, static_body)

func resolve_for_body(body : CustBody) -> void:
	for static_body in static_bodies:
		_resolve_collision(body, static_body)

func _resolve_collision(dynamic : CustBody, static_body : CustBody) -> void:
	var d_aabb := dynamic.get_aabb()
	var s_aabb := static_body.get_aabb()
	if not d_aabb.overlaps(s_aabb):
		return

	var overlap_left := d_aabb.get_right() - s_aabb.get_left()
	var overlap_right := s_aabb.get_right() - d_aabb.get_left()
	var overlap_top := d_aabb.get_bottom() - s_aabb.get_top()
	var overlap_bottom := s_aabb.get_bottom() - d_aabb.get_top()

	var min_overlap_x := minf(overlap_left, overlap_right)
	var min_overlap_y := minf(overlap_top, overlap_bottom)

	if min_overlap_x < min_overlap_y:
		if overlap_left < overlap_right:
			dynamic.position.x -= overlap_left
			dynamic.blocked_right = true
		else:
			dynamic.position.x += overlap_right
			dynamic.blocked_left = true
	else:
		if overlap_top < overlap_bottom:
			dynamic.position.y -= overlap_top
			dynamic.on_floor = true
		else:
			dynamic.position.y += overlap_bottom
			dynamic.on_ceiling = true
