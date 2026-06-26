@tool
extends Node

func _ready() -> void:
	_gen_character()
	_gen_coin()
	_gen_wall()
	_gen_hazard()
	_gen_magnet_bar()
	_gen_magnet_field()
	print("All placeholder textures generated.")
	get_tree().quit()

func _save(img: Image, path: String) -> void:
	img.save_png(path)
	print("  -> " + path)

func _gen_character() -> void:
	var w := 48
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color.DODGER_BLUE)
	for x in range(w):
		for y in range(h):
			if x < 2 or x >= w - 2 or y < 2 or y >= h - 2:
				img.set_pixel(x, y, Color.BLACK)
	_save(img, "res://assets/textures/characters/character_placeholder.png")

func _gen_coin() -> void:
	var s := 16
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var h := s / 2
	var col := Color.DODGER_BLUE
	for x in range(s):
		for y in range(s):
			var ax := absf(x - h)
			var ay := absf(y - h)
			if ax + ay <= h:
				img.set_pixel(x, y, col)
	for x in range(s):
		for y in range(s):
			var ax := absf(x - h)
			var ay := absf(y - h)
			if ax + ay >= h - 1.5 and ax + ay <= h + 0.5:
				img.set_pixel(x, y, Color.WHITE)
	_save(img, "res://assets/textures/coins/coin_placeholder.png")

func _gen_wall() -> void:
	var w := 32
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.412, 0.412, 0.412, 1))
	for x in range(w):
		for y in range(h):
			if x < 2 or x >= w - 2 or y < 2 or y >= h - 2:
				img.set_pixel(x, y, Color.BLACK)
	_save(img, "res://assets/textures/obstacles/wall_unit.png")

func _gen_hazard() -> void:
	var w := 24
	var h := 24
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var hw := w / 2
	var col := Color.RED
	for y in range(h):
		var half_w := int(hw * float(y) / float(h))
		for x in range(hw - half_w, hw + half_w):
			img.set_pixel(x, y, col)
	for x in range(hw - 4, hw + 5):
		img.set_pixel(x, int(h * 0.4), Color.YELLOW)
	_save(img, "res://assets/textures/obstacles/hazard_unit.png")

func _gen_magnet_bar() -> void:
	var w := 128
	var h := 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_save(img, "res://assets/textures/magnets/magnet_bar.png")

func _gen_magnet_field() -> void:
	var w := 128
	var h := 1
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 0.5, 1))
	_save(img, "res://assets/textures/magnets/magnet_field.png")
