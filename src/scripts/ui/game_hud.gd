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
var settings_panel : Panel

func _ready() -> void:
	_setup_touch_buttons()
	game_over_panel.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings)

func _process(_delta : float) -> void:
	if GameManager.state == GameManager.GameState.PLAYING:
		score_label.text = "Score: %d" % int(GameManager.score)
		coin_label.text = "B:%d  R:%d  ★:%d" % [GameManager.coin_blue, GameManager.coin_red, GameManager.coin_rainbow]
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
