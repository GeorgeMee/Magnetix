class_name InputManager
extends Node

signal magnetism_a_toggled
signal magnetism_b_toggled
signal swap_pressed

func _ready() -> void:
	set_process_input(true)

func _input(event : InputEvent) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	if event.is_action_pressed("magnetism_a"):
		magnetism_a_toggled.emit()

	if event.is_action_pressed("magnetism_b"):
		magnetism_b_toggled.emit()

	if event.is_action_pressed("swap"):
		swap_pressed.emit()
