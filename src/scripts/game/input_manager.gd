class_name InputManager
extends Node

signal magnetism_a_pressed
signal magnetism_a_released
signal magnetism_b_pressed
signal magnetism_b_released
signal swap_pressed

var magnetism_a_held : bool = false
var magnetism_b_held : bool = false

func _input(event : InputEvent) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	if event.is_action_pressed("magnetism_a"):
		magnetism_a_held = true
		magnetism_a_pressed.emit()
	elif event.is_action_released("magnetism_a"):
		magnetism_a_held = false
		magnetism_a_released.emit()

	if event.is_action_pressed("magnetism_b"):
		magnetism_b_held = true
		magnetism_b_pressed.emit()
	elif event.is_action_released("magnetism_b"):
		magnetism_b_held = false
		magnetism_b_released.emit()

	if event.is_action_pressed("swap"):
		swap_pressed.emit()
