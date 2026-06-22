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

func get_active_magnet_for(character : Character) -> Magnet:
	for magnet in magnets:
		magnet.update_field_aabb()
		if magnet.is_character_in_field(character):
			return magnet
	return null
