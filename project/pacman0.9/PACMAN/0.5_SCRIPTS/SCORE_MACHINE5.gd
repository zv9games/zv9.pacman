extends Node

signal online

func _ready():

	# Create a timer with a 0.5-second delay
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	update_score_display()

func _emit_online_signal():
	emit_signal("online", self.name)

#BREAK

var score = 0

signal score_changed(new_score)
signal initialized  

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


func add_points(points):
	score += points
	emit_signal("score_changed", score)
	update_score_display()

func reset_score():
	score = 0
	emit_signal("score_changed", score)
	update_score_display()

func display_score_update(digit, position_score):
	var atlas_coords = tile_digits[digit]
	var position_score_i = Vector2i(round(position_score.x), round(position_score.y))
	gameboard.set_cell(0, position_score_i, 0, atlas_coords, false)
	gameboard.update_internals()

func update_score_display():
	var score_str = str(score).pad_zeros(7)
	for i in range(score_display_positions.size()):
		var digit_value = int(score_str[i])
		var position_display = score_display_positions[i]
		display_score_update(digit_value, position_display)
	gameboard.update_internals()

func display_lives():
	pass
func update_lives_display():
	pass
