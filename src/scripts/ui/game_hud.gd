class_name GameHUD
extends CanvasLayer

signal magnetism_a_toggled
signal magnetism_b_toggled
signal swap_pressed

@onready var score_label : Label = %ScoreLabel
@onready var btn_magnet_a : Button = %BtnMagnetA
@onready var btn_magnet_b : Button = %BtnMagnetB
@onready var btn_swap : Button = %BtnSwap
@onready var game_over_panel : Panel = %GameOverPanel
@onready var game_over_score : Label = %GameOverScore
@onready var restart_button : Button = %RestartButton

func _ready() -> void:
	_setup_touch_buttons()
	game_over_panel.visible = false
	restart_button.pressed.connect(_on_restart_pressed)

func _process(_delta : float) -> void:
	if GameManager.state == GameManager.GameState.PLAYING:
		score_label.text = "Score: %d" % int(GameManager.score)
	elif GameManager.state == GameManager.GameState.GAME_OVER:
		if not game_over_panel.visible:
			_show_game_over()

func _setup_touch_buttons() -> void:
	btn_magnet_a.pressed.connect(func(): magnetism_a_toggled.emit())
	btn_magnet_b.pressed.connect(func(): magnetism_b_toggled.emit())
	btn_swap.pressed.connect(func(): swap_pressed.emit())

func _show_game_over() -> void:
	game_over_panel.visible = true
	game_over_score.text = "Score: %d" % int(GameManager.score)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
