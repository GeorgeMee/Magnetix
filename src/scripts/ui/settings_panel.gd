class_name SettingsPanel
extends Panel

@onready var duration_slider : HSlider = %DurationSlider
@onready var cooldown_slider : HSlider = %CooldownSlider
@onready var interval_slider : HSlider = %IntervalSlider
@onready var duration_label : Label = %DurationValue
@onready var cooldown_label : Label = %CooldownValue
@onready var interval_label : Label = %IntervalValue

func _ready() -> void:
	duration_slider.value = GameManager.magnetism_duration
	cooldown_slider.value = GameManager.magnetism_cooldown
	interval_slider.value = GameManager.sim_decision_interval
	_on_duration_changed(duration_slider.value)
	_on_cooldown_changed(cooldown_slider.value)
	_on_interval_changed(interval_slider.value)

	duration_slider.value_changed.connect(_on_duration_changed)
	cooldown_slider.value_changed.connect(_on_cooldown_changed)
	interval_slider.value_changed.connect(_on_interval_changed)

func _on_duration_changed(value: float) -> void:
	var val := snappedf(value, 0.1)
	duration_label.text = "%.1f 秒" % val
	GameManager.magnetism_duration = val

func _on_cooldown_changed(value: float) -> void:
	var val := snappedf(value, 0.1)
	cooldown_label.text = "%.1f 秒" % val
	GameManager.magnetism_cooldown = val

func _on_interval_changed(value: float) -> void:
	var val := snappedf(value, 1.0)
	interval_label.text = "%d px" % int(val)
	GameManager.sim_decision_interval = val
