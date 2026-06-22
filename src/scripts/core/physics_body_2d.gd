class_name CustBody
extends RefCounted

var position : Vector2
var velocity : Vector2
var acceleration : Vector2
var gravity : float
var aabb_size : Vector2
var on_ceiling : bool
var on_floor : bool
var blocked_left : bool
var blocked_right : bool

func _init(p_pos : Vector2 = Vector2.ZERO, p_collision_size : Vector2 = Vector2(32, 32)) -> void:
	position = p_pos
	velocity = Vector2.ZERO
	acceleration = Vector2.ZERO
	gravity = 0.0
	aabb_size = p_collision_size
	on_ceiling = false
	on_floor = false
	blocked_left = false
	blocked_right = false

func get_aabb() -> CustAABB:
	return CustAABB.new(position, aabb_size)

func apply_force(force : Vector2) -> void:
	acceleration += force

func apply_vertical_force(amount : float) -> void:
	acceleration.y += amount

func integrate(delta : float) -> void:
	velocity += acceleration * delta
	position += velocity * delta
	acceleration = Vector2.ZERO
	on_ceiling = false
	on_floor = false
	blocked_left = false
	blocked_right = false

func reset_flags() -> void:
	on_ceiling = false
	on_floor = false
	blocked_left = false
	blocked_right = false
