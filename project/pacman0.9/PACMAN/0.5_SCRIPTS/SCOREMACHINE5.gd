extends Node

signal online
signal score_changed(new_score)
signal lives_changed(new_lives)

var level_display_positions = [Vector2i(23, 1), Vector2i(24, 1), Vector2i(25, 1)]
var life_display_positions = [Vector2i(27, 31), Vector2i(28, 31), Vector2i(29, 31)]
var life_tile_coords = Vector2i(1, 3)
var empty_life_tile_coords = Vector2i(8, 10)
var score = 0
var lives = 3

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

@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"

func _ready():
	# Create a timer with a 0.5-second delay
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	update_score_display()
	update_lives_display()

func _emit_online_signal():
	emit_signal("online", self.name)

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
	gameboard.set_cell(position_score_i, 0, atlas_coords, 0)
	gameboard.update_internals()

func update_score_display():
	var score_str = str(score).pad_zeros(7)
	for i in range(score_display_positions.size()):
		var digit_value = int(score_str[i])
		var position_display = score_display_positions[i]
		display_score_update(digit_value, position_display)
	gameboard.update_internals()

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
		gameboard.set_cell(tile_pos, 0, atlas_coords, 0)

func display_lives():
	for i in range(3):
		var tile_pos = life_display_positions[i]
		gameboard.set_cell(tile_pos, 0, Vector2i(0, 0), -1)
	for i in range(lives):
		var tile_pos = life_display_positions[i]
		gameboard.set_cell(tile_pos, 0, life_tile_coords, 0)
	for i in range(lives, 3):
		var tile_pos = life_display_positions[i]
		gameboard.set_cell(tile_pos, 0, empty_life_tile_coords, 0)

func update_lives_display():
	display_lives()
	
func lose_life():
	if lives > 0:
		lives -= 1
		emit_signal("lives_changed", lives)
		update_lives_display()
		print("Life lost! Remaining lives: ", lives)
	else:
		print("No more lives left!")
		
