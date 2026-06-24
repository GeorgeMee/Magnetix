class_name GameHUD
extends CanvasLayer

signal magnetism_a_toggled
signal magnetism_b_toggled
signal swap_pressed

@onready var score_label : Label = %ScoreLabel
@onready var coin_label : Label = %CoinLabel
@onready var btn_magnet_a : Button = %BtnMagnetA
@onready var btn_magnet_b : Button = %BtnMagnetB
@onready var btn_swap : Button = %BtnSwap
@onready var game_over_panel : Panel = %GameOverPanel
@onready var game_over_score : Label = %GameOverScore
@onready var restart_button : Button = %RestartButton
@onready var settings_button : Button = %SettingsButton
@onready var assist_toggle : Button = %AssistToggle
var settings_panel : Panel
var highlight_tween : Tween
var highlight_on : bool = false
var pulse_time : float = 0.0

func _ready() -> void:
	_setup_touch_buttons()
	game_over_panel.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings)
	assist_toggle.pressed.connect(_on_assist_toggle)
	_update_assist_button_text()

func _process(delta : float) -> void:
	if GameManager.state == GameManager.GameState.PLAYING:
		score_label.text = "Score: %d" % int(GameManager.score)
		coin_label.text = "B:%d  R:%d  ★:%d" % [GameManager.coin_blue, GameManager.coin_red, GameManager.coin_rainbow]
		if GameManager.assist_mode:
			_update_assist_highlights(delta)
	elif GameManager.state == GameManager.GameState.GAME_OVER:
		if not game_over_panel.visible:
			_show_game_over()

func _setup_touch_buttons() -> void:
	btn_magnet_a.pressed.connect(func(): magnetism_a_toggled.emit())
	btn_magnet_b.pressed.connect(func(): magnetism_b_toggled.emit())
	btn_swap.pressed.connect(func(): swap_pressed.emit())

func update_button_colors(color_a : Color, color_b : Color) -> void:
	btn_magnet_a.modulate = color_a
	btn_magnet_a.text = "▲ 上"
	btn_magnet_b.modulate = color_b
	btn_magnet_b.text = "▼ 下"

func _show_game_over() -> void:
	game_over_panel.visible = true
	game_over_score.text = "Score: %d" % int(GameManager.score)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_settings() -> void:
	if settings_panel:
		return
	settings_panel = preload("res://src/scenes/ui/settings_panel.tscn").instantiate()
	settings_panel.visible = true
	settings_panel.get_node("VBoxContainer/CloseButton").pressed.connect(_close_settings)
	add_child(settings_panel)

func _close_settings() -> void:
	if settings_panel:
		settings_panel.queue_free()
		settings_panel = null

func _on_assist_toggle() -> void:
	GameManager.assist_mode = not GameManager.assist_mode
	_update_assist_button_text()
	if not GameManager.assist_mode:
		btn_magnet_a.modulate = GameManager.character_a.character_color
		btn_magnet_b.modulate = GameManager.character_b.character_color
		btn_swap.modulate = Color.WHITE

func _update_assist_button_text() -> void:
	assist_toggle.text = "辅助:开" if GameManager.assist_mode else "辅助:关"

func _update_assist_highlights(delta : float) -> void:
	pulse_time += delta
	var pulse := absf(sin(pulse_time * 4.0))
	var highlight_color := Color.YELLOW

	var dist := GameManager.scroll_manager.world_offset + GameManager.player_fixed_x
	for pt in GameManager.trajectory_data:
		if pt.world_x < dist:
			continue
		var screen_x := GameManager.scroll_manager.world_to_screen_x(pt.world_x)
		if screen_x > 1920:
			continue
		if screen_x < 1200:
			highlight_color = highlight_color.lerp(Color.WHITE, pulse)

			if pt.swap_trigger:
				btn_swap.modulate = highlight_color
			if pt.magnet_a_trigger:
				btn_magnet_a.modulate = highlight_color
			if pt.magnet_b_trigger:
				btn_magnet_b.modulate = highlight_color
			return
		else:
			btn_magnet_a.modulate = GameManager.character_a.character_color
			btn_magnet_b.modulate = GameManager.character_b.character_color
			btn_swap.modulate = Color.WHITE
	return
