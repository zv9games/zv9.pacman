extends TileMapLayer

signal online

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	start_highscore()
		
func _emit_online_signal():
	emit_signal("online", self.name)
	
############################################################################

@export var max_high_scores = 9
@export var high_score_file_path = "user://high_scores.save"
@onready var display_board = $/root/BINARY/GAME/HIGHSCORE # Assuming you have a DisplayBoard node for displaying high scores
@onready var hover_block = $/root/BINARY/GAME/HIGHSCORE/HOVERBLOCK  # Assuming you have a Node2D or similar for the hover effect
@onready var popup = $/root/BINARY/GAME/HIGHSCORE/POPUP  # Assuming you have a Popup node for replay options
@onready var scoremachine = $/root/BINARY/ZPU/SCOREMACHINE
@onready var zpu = $/root/BINARY/ZPU
@onready var startmenu = $/root/BINARY/GAME/STARTMENU
signal text_entered


var skip_cell_positions = [
	Vector2(27, 30), Vector2(28, 30), Vector2(29, 30), Vector2(30, 30)
]
var high_scores = []
var current_score = 0
var current_letter_index = 0

var tile_digits = {
	0: Vector2i(2, 5), 1: Vector2i(2, 6), 2: Vector2i(2, 7), 3: Vector2i(2, 8),
	4: Vector2i(1, 9), 5: Vector2i(2, 9), 6: Vector2i(1, 10), 7: Vector2i(2, 10),
	8: Vector2i(1, 11), 9: Vector2i(2, 11)
}

var tile_positions = [
	Vector2(12, 23), Vector2(13, 23), Vector2(14, 23), Vector2(15, 23), Vector2(16, 23), Vector2(17, 23), Vector2(18, 23), Vector2(19, 23), Vector2(20, 23), Vector2(21, 23),  # QWERTYUIOP
	Vector2(12, 24), Vector2(13, 24), Vector2(14, 24), Vector2(15, 24), Vector2(16, 24), Vector2(17, 24), Vector2(18, 24), Vector2(19, 24), Vector2(20, 24),  # ASDFGHJKL
	Vector2(12, 25), Vector2(13, 25), Vector2(14, 25), Vector2(15, 25), Vector2(16, 25), Vector2(17, 25), Vector2(18, 25),  # ZXCVBNM
	Vector2(19, 25),  # Space
	Vector2(20, 25)   # Backspace
]

var tile_size = 16  # Set the tile size to 16
var initials = ["", "", ""]  # Array to store the initials
var initial_position1 = Vector2(15, 20)
var initial_position2 = Vector2(16, 20)
var initial_position3 = Vector2(17, 20)
var letter_positions = { 'Q': Vector2(12, 23), 'W': Vector2(13, 23), 'E': Vector2(14, 23), 'R': Vector2(15, 23), 'T': Vector2(16, 23), 'Y': Vector2(17, 23), 'U': Vector2(18, 23), 'I': Vector2(19, 23), 'O': Vector2(20, 23), 'P': Vector2(21, 23),
	'A': Vector2(12, 24), 'S': Vector2(13, 24), 'D': Vector2(14, 24), 'F': Vector2(15, 24), 'G': Vector2(16, 24), 'H': Vector2(17, 24), 'J': Vector2(18, 24), 'K': Vector2(19, 24), 'L': Vector2(20, 24),
	'Z': Vector2(12, 25), 'X': Vector2(13, 25), 'C': Vector2(14, 25), 'V': Vector2(15, 25), 'B': Vector2(16, 25), 'N': Vector2(17, 25), 'M': Vector2(18, 25), ' ': Vector2(19, 25),
	'Backspace': Vector2(20, 25) }

var highscore_positions = [ 	{'initials1': [Vector2(12, 6), Vector2(13, 6), Vector2(14, 6)], 'digits1': [Vector2(16, 6), Vector2(17, 6), Vector2(18, 6), Vector2(19, 6), Vector2(20, 6), Vector2(21, 6), Vector2(22, 6)]},
	{'initials2': [Vector2(12, 7), Vector2(13, 7), Vector2(14, 7)], 'digits2': [Vector2(16, 7), Vector2(17, 7), Vector2(18, 7), Vector2(19, 7), Vector2(20, 7), Vector2(21, 7), Vector2(22, 7)]},
	{'initials3': [Vector2(12, 8), Vector2(13, 8), Vector2(14, 8)], 'digits3': [Vector2(16, 8), Vector2(17, 8), Vector2(18, 8), Vector2(19, 8), Vector2(20, 8), Vector2(21, 8), Vector2(22, 8)]},
	{'initials4': [Vector2(12, 9), Vector2(13, 9), Vector2(14, 9)], 'digits4': [Vector2(16, 9), Vector2(17, 9), Vector2(18, 9), Vector2(19, 9), Vector2(20, 9), Vector2(21, 9), Vector2(22, 9)]},
	{'initials5': [Vector2(12, 10), Vector2(13, 10), Vector2(14, 10)], 'digits5': [Vector2(16, 10), Vector2(17, 10), Vector2(18, 10), Vector2(19, 10), Vector2(20, 10), Vector2(21, 10), Vector2(22, 10)]},
	{'initials6': [Vector2(12, 11), Vector2(13, 11), Vector2(14, 11)], 'digits6': [Vector2(16, 11), Vector2(17, 11), Vector2(18, 11), Vector2(19, 11), Vector2(20, 11), Vector2(21, 11), Vector2(22, 11)]},
	{'initials7': [Vector2(12, 12), Vector2(13, 12), Vector2(14, 12)], 'digits7': [Vector2(16, 12), Vector2(17, 12), Vector2(18, 12), Vector2(19, 12), Vector2(20, 12), Vector2(21, 12), Vector2(22, 12)]},
	{'initials8': [Vector2(12, 13), Vector2(13, 13), Vector2(14, 13)], 'digits8': [Vector2(16, 13), Vector2(17, 13), Vector2(18, 13), Vector2(19, 13), Vector2(20, 13), Vector2(21, 13), Vector2(22, 13)]},
	{'initials9': [Vector2(12, 14), Vector2(13, 14), Vector2(14, 14)], 'digits9': [Vector2(16, 14), Vector2(17, 14), Vector2(18, 14), Vector2(19, 14), Vector2(20, 14), Vector2(21, 14), Vector2(22, 14)]}
]

var letter_atlas_positions = {
	"A": Vector2(3, 12), "B": Vector2(4, 12), "C": Vector2(5, 12), "D": Vector2(6, 12), "E": Vector2(7, 12),
	"F": Vector2(8, 12), "G": Vector2(9, 12), "H": Vector2(10, 12), "I": Vector2(0, 13), "J": Vector2(1, 13),
	"K": Vector2(2, 13), "L": Vector2(3, 13), "M": Vector2(4, 13), "N": Vector2(5, 13), "O": Vector2(6, 13),
	"P": Vector2(7, 13), "Q": Vector2(8, 13), "R": Vector2(9, 13), "S": Vector2(10, 13), "T": Vector2(0, 14),
	"U": Vector2(1, 14), "V": Vector2(2, 14), "W": Vector2(3, 14), "X": Vector2(4, 14), "Y": Vector2(5, 14),
	"Z": Vector2(6, 14), ' ': Vector2(8, 10),  # Add an entry for the space character
	'Backspace': Vector2(8, 14)  # Example position for Backspace
}

var current_initial_position = 1
var input_enabled = false

func start_highscore():
	scoremachine.connect("game_over", Callable(self, "_on_game_over"))
	#clear_high_score_file()
	self.hide()
	set_physics_process(false)
	set_process(false)
	input_enabled = false
	initials = ["", "", ""]  # Reset initials array

func show_self():
	self.show()
	set_physics_process(true)
	set_process(true)
	tile_positions.append_array(skip_cell_positions)
	load_high_scores()
	display_high_scores()
	input_enabled = true
	current_letter_index = 0
	current_initial_position = 1
	hover_block.position = tile_position_to_global_position(tile_positions[current_letter_index])
	update_hover_block()

func _on_game_over(final_score):
	current_score = final_score
	print("Game over! Final score: ", current_score)

func _process(delta):
	if input_enabled:
		update_hover_block()

func _input(event):
	if input_enabled:
		if event is InputEventKey:
			if event.pressed:
				if event.keycode == KEY_LEFT:
					current_letter_index = max(0, current_letter_index - 1)
				elif event.keycode == KEY_RIGHT:
					current_letter_index = min(tile_positions.size() - 1, current_letter_index + 1)
				elif event.keycode == KEY_UP:
					current_letter_index = max(0, current_letter_index - 10)
				elif event.keycode == KEY_DOWN:
					current_letter_index = min(tile_positions.size() - 1, current_letter_index + 10)
				elif event.keycode == KEY_ENTER:
					if current_letter_index == tile_positions.size() - 1:
						emit_signal("text_entered", "Backspace")
						handle_backspace()
					elif tile_positions[current_letter_index] in skip_cell_positions:
						skip_game_over()
					else:
						var selected_letter = get_letter_from_index(current_letter_index)
						emit_signal("text_entered", selected_letter)
						update_initial_position(selected_letter)
				update_hover_block()
		elif event is InputEventScreenTouch:
			var touch_pos = event.position
			current_letter_index = get_tile_index_from_position(touch_pos)
			if event.is_pressed():
				if current_letter_index == tile_positions.size() - 1:
					emit_signal("text_entered", "Backspace")
					handle_backspace()
				elif tile_positions[current_letter_index] in skip_cell_positions:
					skip_game_over()
				else:
					var selected_letter = get_letter_from_index(current_letter_index)
					emit_signal("text_entered", selected_letter)
					update_initial_position(selected_letter)
				update_hover_block()



func update_hover_block():
	hover_block.position = tile_position_to_global_position(tile_positions[current_letter_index])

func handle_backspace():
	if current_initial_position > 1:
		current_initial_position -= 1
		var reset_position = Vector2(1, 12)
		print("Backspace pressed. Current initial position: ", current_initial_position)
		if current_initial_position == 1:
			print("Resetting initial position 1: ", initial_position1)
			display_board.set_cell(Vector2i(initial_position1.x, initial_position1.y), 0, reset_position)
		elif current_initial_position == 2:
			print("Resetting initial position 2: ", initial_position2)
			display_board.set_cell(Vector2i(initial_position2.x, initial_position2.y), 0, reset_position)
		elif current_initial_position == 3:
			print("Resetting initial position 3: ", initial_position3)
			display_board.set_cell(Vector2i(initial_position3.x, initial_position3.y), 0, reset_position)

func lock_in_letter(selected_letter):
	var atlas_position = letter_atlas_positions[selected_letter]
	print("Locking in letter: ", selected_letter, " at position: ", current_initial_position)
	if current_initial_position == 1:
		display_board.set_cell(Vector2i(initial_position1.x, initial_position1.y), 0, Vector2i(atlas_position.x, atlas_position.y))
		initial_position1 = tile_positions[current_letter_index]
		print("Updated initial_position1 to: ", initial_position1)
		current_initial_position = 2
	elif current_initial_position == 2:
		display_board.set_cell(Vector2i(initial_position2.x, initial_position2.y), 0, Vector2i(atlas_position.x, atlas_position.y))
		initial_position2 = tile_positions[current_letter_index]
		print("Updated initial_position2 to: ", initial_position2)
		current_initial_position = 3
	elif current_initial_position == 3:
		display_board.set_cell(Vector2i(initial_position3.x, initial_position3.y), 0, Vector2i(atlas_position.x, atlas_position.y))
		initial_position3 = tile_positions[current_letter_index]
		print("Updated initial_position3 to: ", initial_position3)
		# Save initials and high score
		var initials = get_initials()
		var score = get_current_score()
		high_scores.append({'initials': initials, 'score': score})
		# Sort high scores in descending order
		high_scores.sort_custom(func(a, b):
			return b['score'] - a['score']
		)
		# Display high scores
		display_high_scores()
		# Save high scores to file
		save_high_scores()

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tilemap_pos = self.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = self.map_to_local(tile_pos)
	var global_pos = self.to_global(local_pos)
	return global_pos

func get_letter_from_index(index):
	var letters = "QWERTYUIOPASDFGHJKLZXCVBNM "
	if index < letters.length():
		return letters[index]
	return ""

func get_tile_index_from_position(position):
	for i in range(tile_positions.size()):
		if tile_positions[i] == position:
			return i
	return -1

func get_initials():
	return [
		get_letter_from_index(find_tile_index(initial_position1)),
		get_letter_from_index(find_tile_index(initial_position2)),
		get_letter_from_index(find_tile_index(initial_position3))
	]

func get_current_score():
	return current_score

func display_high_scores():
	for i in range(min(high_scores.size(), highscore_positions.size())):
		var highscore = high_scores[i]
		var initials = highscore['initials']
		var score = pad_left(highscore['score'], 7, '0')
		var positions = highscore_positions[i]
		# Display initials
		for j in range(initials.size()):
			var letter = initials[j]
			var pos = positions['initials' + str(i + 1)][j]
			var atlas_position = letter_atlas_positions[letter]
			display_board.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(atlas_position.x, atlas_position.y))
		# Display score
		for j in range(score.length()):
			var digit = int(score[j])  # Convert the digit to an integer
			var pos = positions['digits' + str(i + 1)][j]
			var atlas_position = tile_digits[digit]  # Use tile_digits dictionary
			display_board.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(atlas_position.x, atlas_position.y))

func pad_left(value, length, char):
	var result = str(value)
	while result.length() < length:
		result = char + result
	return result

func find_tile_index(position):
	for i in range(tile_positions.size()):
		if tile_positions[i] == position:
			return i
	return -1

func save_high_scores():
	var file = FileAccess.open("user://high_scores.save", FileAccess.WRITE)
	file.store_var(high_scores)
	file.close()

func load_high_scores():
	if FileAccess.file_exists(high_score_file_path):
		var file = FileAccess.open(high_score_file_path, FileAccess.READ)
		if file:
			high_scores = file.get_var()
			file.close()
			print("High scores loaded: ", high_scores)
			# Sort high scores in descending order
			high_scores.sort_custom(func(a, b):
				return b['score'] - a['score']
			)
		else:
			print("Failed to open high score file.")
	else:
		print("High score file does not exist.")

		
func update_initial_position(selected_letter):
	var atlas_position = letter_atlas_positions[selected_letter]
	print("Updating initial position: ", current_initial_position, " with letter: ", selected_letter)
	if current_initial_position == 1:
		display_board.set_cell(Vector2i(initial_position1.x, initial_position1.y), 0, Vector2i(atlas_position.x, atlas_position.y))
		initials[0] = selected_letter  # Store the letter in the initials array
		current_initial_position = 2
	elif current_initial_position == 2:
		display_board.set_cell(Vector2i(initial_position2.x, initial_position2.y), 0, Vector2i(atlas_position.x, atlas_position.y))
		initials[1] = selected_letter  # Store the letter in the initials array
		current_initial_position = 3
	elif current_initial_position == 3:
		display_board.set_cell(Vector2i(initial_position3.x, initial_position3.y), 0, Vector2i(atlas_position.x, atlas_position.y))
		initials[2] = selected_letter  # Store the letter in the initials array
		# Save initials and high score
		var score = get_current_score()
		high_scores.append({'initials': initials, 'score': score})
		# Sort high scores in descending order
		high_scores.sort_custom(func(a, b):
			return b['score'] - a['score']
		)
		display_high_scores()
		save_high_scores()
		current_initial_position = 1  # Reset for next entry

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

func skip_game_over():
	print("Skipping game over screen.")
	save_high_scores()
	self.hide()
	zpu.loading.restart_game_loop()
	startmenu.restart()
