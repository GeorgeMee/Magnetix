class_name SettingsPanel
extends Panel

@onready var duration_slider : HSlider = %DurationSlider
@onready var cooldown_slider : HSlider = %CooldownSlider
@onready var duration_label : Label = %DurationValue
@onready var cooldown_label : Label = %CooldownValue

func _ready() -> void:
	duration_slider.value = GameManager.magnetism_duration
	cooldown_slider.value = GameManager.magnetism_cooldown
	_on_duration_changed(duration_slider.value)
	_on_cooldown_changed(cooldown_slider.value)

	duration_slider.value_changed.connect(_on_duration_changed)
	cooldown_slider.value_changed.connect(_on_cooldown_changed)

func _on_duration_changed(value: float) -> void:
	var val := snappedf(value, 0.1)
	duration_label.text = "%.1f 秒" % val
	GameManager.magnetism_duration = val

func _on_cooldown_changed(value: float) -> void:
	var val := snappedf(value, 0.1)
	cooldown_label.text = "%.1f 秒" % val
	GameManager.magnetism_cooldown = val
