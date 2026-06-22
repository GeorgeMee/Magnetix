class_name MagnetManager
extends Node

var magnets : Array[Magnet] = []

func _ready() -> void:
	GameManager.magnet_manager = self

func register_magnet(magnet : Magnet) -> void:
	if not magnets.has(magnet):
		magnets.append(magnet)

func unregister_magnet(magnet : Magnet) -> void:
	magnets.erase(magnet)

func get_target_surface(character : Character, magnetism_active : bool) -> Character.Surface:
	if not magnetism_active:
		return Character.Surface.FLOOR
	var has_ceiling := false
	var has_floor := false
	for magnet in magnets:
		magnet.update_field_aabb()
		if not magnet.is_character_in_field(character):
			continue
		var dir := magnet.get_force_direction(character)
		print("CHAR[%s] MAG[%s@%s] same=%s dir=%d field=(%.0f,%.0f)-(%.0f,%.0f) char=(%.0f,%.0f)-(%.0f,%.0f)" % [
			"N" if character.character_polarity == Magnet.Polarity.NORTH else "S",
			"N" if magnet.polarity == Magnet.Polarity.NORTH else "S",
			"CEIL" if magnet.placement == Magnet.Placement.CEILING else "FLR",
			"Y" if magnet.polarity == character.character_polarity else "N",
			dir,
			magnet.field_aabb.get_left(), magnet.field_aabb.get_top(),
			magnet.field_aabb.get_right(), magnet.field_aabb.get_bottom(),
			character.physics_body.get_aabb().get_left(),
			character.physics_body.get_aabb().get_top(),
			character.physics_body.get_aabb().get_right(),
			character.physics_body.get_aabb().get_bottom()
		])
		if dir < 0:
			if magnet.placement == Magnet.Placement.CEILING:
				has_floor = true
			else:
				has_ceiling = true
		else:
			if magnet.placement == Magnet.Placement.FLOOR:
				has_floor = true
			else:
				has_ceiling = true
	print("  → has_ceil=%s has_floor=%s → %s" % [has_ceiling, has_floor, "CEILING" if has_ceiling else "FLOOR"])
	if has_ceiling:
		return Character.Surface.CEILING
	if has_floor:
		return Character.Surface.FLOOR
	return Character.Surface.FLOOR
