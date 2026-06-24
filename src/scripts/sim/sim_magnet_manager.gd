class_name SimMagnetManager
extends MagnetManager

func is_character_in_any_field(character: Character) -> bool:
	return character.magnetism_active

func get_target_surface(character: Character, magnetism_active: bool) -> Character.Surface:
	if magnetism_active:
		return Character.Surface.CEILING
	return Character.Surface.FLOOR
