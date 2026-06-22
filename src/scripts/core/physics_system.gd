class_name PhysicsSystem
extends Node

var bodies : Array[CustBody]
var static_bodies : Array[CustBody]

func _ready() -> void:
	bodies = []
	static_bodies = []

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

func step(_delta : float) -> void:
	for body in bodies:
		for static_body in static_bodies:
			_resolve_collision(body, static_body)

func resolve_for_body(body : CustBody) -> void:
	for static_body in static_bodies:
		_resolve_collision(body, static_body)

func _resolve_collision(dynamic : CustBody, static_body : CustBody) -> void:
	if not dynamic.collision_box.overlaps(static_body.collision_box):
		return

	var overlap_left := dynamic.collision_box.get_right() - static_body.collision_box.get_left()
	var overlap_right := static_body.collision_box.get_right() - dynamic.collision_box.get_left()
	var overlap_top := dynamic.collision_box.get_bottom() - static_body.collision_box.get_top()
	var overlap_bottom := static_body.collision_box.get_bottom() - dynamic.collision_box.get_top()

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

	dynamic.collision_box.position = dynamic.position
