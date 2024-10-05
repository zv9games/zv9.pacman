extends Node

signal online
signal game_over(final_score)

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	gametimer.connect("timeout", Callable(self, "_on_game_timer_timeout"))
	startmenu.connect("start_original", Callable(self, "_on_start_game"))
	start_scoremachine()

func _emit_online_signal():
	emit_signal("online", self.name)
	
#########################################################################

signal score_changed(new_score)
signal lives_changed(new_lives)
signal level_changed(new_level)

var elapsed_time = 0
var time_display_positions = [Vector2i(3, 0), Vector2i(4, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(9, 0), Vector2i(10, 0)]
var level_display_positions = [Vector2i(23, 1), Vector2i(24, 1), Vector2i(25, 1)]
var life_display_positions = [Vector2i(27, 30), Vector2i(28, 30), Vector2i(29, 30)]
var life_tile_coords = Vector2i(1, 3)
var empty_life_tile_coords = Vector2i(8, 10)
var score = 0
var lives = 3
var level = 1

var score_display_positions = [
	Vector2i(23, 0), Vector2i(24, 0), Vector2i(25, 0),
	Vector2i(26, 0), Vector2i(27, 0), Vector2i(28, 0),
	Vector2i(29, 0)
]

var tile_digits = {
	0: Vector2i(2, 5), 1: Vector2i(2, 6), 2: Vector2i(2, 7), 3: Vector2i(2, 8),
	4: Vector2i(1, 9), 5: Vector2i(2, 9), 6: Vector2i(1, 10), 7: Vector2i(2, 10),
	8: Vector2i(1, 11), 9: Vector2i(2, 11)
}

@onready var originalboard = $"/root/BINARY/GAME/ORIGINAL/TILEMAPLAYER"
@onready var pacman = $/root/BINARY/GAME/CHARACTERS/PACMAN
@onready var blinky = $/root/BINARY/GAME/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/GAME/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/GAME/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/GAME/CHARACTERS/CLYDE
@onready var loading = $/root/BINARY/MENUS/LOADING
@onready var zpu = $/root/BINARY/ZPU
@onready var gametimer = $/root/BINARY/ZPU/TIMERS/GAMETIMER
@onready var startmenu = $/root/BINARY/MENUS/STARTMENU

func start_scoremachine():
	update_score_display()
	update_lives_display()
	display_level_number(level)
	
func _on_start_game():
	elapsed_time = 0.0
	gametimer.start()

func _on_game_timer_timeout():
	elapsed_time += 0.1
	update_time_display()
	gametimer.start()

func update_time_display():
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	var milliseconds = int((elapsed_time - int(elapsed_time)) * 100)
	var time_str = str(minutes).pad_zeros(2) + str(seconds).pad_zeros(2) + str(milliseconds).pad_zeros(2)
	for i in range(time_display_positions.size()):
		var digit_value = int(time_str[i])
		var position_display = time_display_positions[i]
		display_time_update(digit_value, position_display)
	originalboard.update_internals()

func display_time_update(digit, position):
	var atlas_coords = tile_digits[digit]
	var position_i = Vector2i(round(position.x), round(position.y))
	originalboard.set_cell(position_i, 0, atlas_coords, 0)
	originalboard.update_internals()

func add_points(points):
	score += points
	emit_signal("score_changed", score)
	update_score_display()

func reset_score():
	score = 0
	emit_signal("score_changed", score)
	update_score_display()

func add_lives(amount):
	lives += amount
	emit_signal("lives_changed", lives)
	update_lives_display()

func reset_lives():
	lives = 3
	emit_signal("lives_changed", lives)
	update_lives_display()

func display_score_update(digit, position_score):
	var atlas_coords = tile_digits[digit]
	var position_score_i = Vector2i(round(position_score.x), round(position_score.y))
	originalboard.set_cell(position_score_i, 0, atlas_coords, 0)
	originalboard.update_internals()

func update_score_display():
	var score_str = str(score).pad_zeros(7)
	for i in range(score_display_positions.size()):
		var digit_value = int(score_str[i])
		var position_display = score_display_positions[i]
		display_score_update(digit_value, position_display)
	originalboard.update_internals()

func pad_left(value: String, length: int, pad_char: String) -> String:
	while value.length() < length:
		value = pad_char + value
	return value

func display_level_number(level: int):
	var digits = pad_left(str(level), 3, "0")
	for i in range(digits.length()):
		var digit = int(digits[i])
		var atlas_coords = tile_digits[digit]
		var tile_pos = level_display_positions[i]
		originalboard.set_cell(tile_pos, 0, atlas_coords, 0)

func display_lives():
	for i in range(3):
		var tile_pos = life_display_positions[i]
		originalboard.set_cell(tile_pos, 0, Vector2i(0, 0), -1)
	for i in range(lives):
		var tile_pos = life_display_positions[i]
		originalboard.set_cell(tile_pos, 0, life_tile_coords, 0)
	for i in range(lives, 3):
		var tile_pos = life_display_positions[i]
		originalboard.set_cell(tile_pos, 0, empty_life_tile_coords, 0)

func update_lives_display():
	display_lives()

func lose_life():
	if lives > 0:
		lives -= 1
		emit_signal("lives_changed", lives)
		update_lives_display()
		print("Life lost! Remaining lives: ", lives)
	else:
		originalboard.visible = false
		pacman.visible = false
		blinky.visible = false
		pinky.visible = false
		inky.visible = false
		clyde.visible = false
		zpu.handle_game_over()  # Call handle_game_over when all lives are lost
		
func add_level():
	level += 1
	emit_signal("level_changed", level)
	display_level_number(level)
	
func reset_level_display():
	level = 1
	emit_signal("level_changed", level)
	display_level_number(level)
	
func get_lives() -> int:
	return lives
	
func transfer_score():
	emit_signal("game_over", score)
	print("gameover signal", score)

func clear_high_score_file():
	var file_path = "user://high_scores.save"
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("user://")
		if dir:
			var err = dir.remove_absolute(file_path)
			if err == OK:
				print("High score save file cleared.")
			else:
				print("Failed to clear high score save file. Error code: ", err)
	else:
		print("High score save file does not exist.")
