extends TileMapLayer

signal online

func _ready():
	self.hide()
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	binary.connect("all_nodes_initialized", Callable(self, "start_hsboss"))
	#clear_high_score_file()

func _emit_online_signal():
	emit_signal("online", self.name)
	
########################################################################

@export var high_score_file_path = "user://high_scores.save"
@onready var binary = $/root/BINARY
@onready var hover_block = $HOVERBLOCK3
@onready var display_board = $/root/BINARY/MISC/HSBOSS
@onready var popup = $/root/BINARY/MISC/POPUP
@onready var scoremachine = $/root/BINARY/ZPU/SCOREMACHINE

var high_score_list = [
	{"score": 9999999, "initials": "ZOO"},
	{"score": 0004000, "initials": "SAM"},
	{"score": 0003500, "initials": "CAT"},
	{"score": 0003000, "initials": "DOG"},
	{"score": 0002500, "initials": "WET"},
	{"score": 0002000, "initials": "SUN"},
	{"score": 0001500, "initials": "HAT"},
	{"score": 0001000, "initials": "RUN"},
	{"score": 0000500, "initials": "MAP"}
]
var high_score_rank_tile_position = [
	{1: Vector2(10, 6)},
	{2: Vector2(10, 7)},
	{3: Vector2(10, 8)},
	{4: Vector2(10, 9)},
	{5: Vector2(10, 10)},
	{6: Vector2(10, 11)},
	{7: Vector2(10, 12)},
	{8: Vector2(10, 13)},
	{9: Vector2(10, 14)}
]

var highscore_initial_digit_tile_positions = [ 	{'initials1': [Vector2(12, 6), Vector2(13, 6), Vector2(14, 6)], 'digits1': [Vector2(16, 6), Vector2(17, 6), Vector2(18, 6), Vector2(19, 6), Vector2(20, 6), Vector2(21, 6), Vector2(22, 6)]},
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
var letter_tile_positions = { 'Q': Vector2(12, 23), 'W': Vector2(13, 23), 'E': Vector2(14, 23), 'R': Vector2(15, 23), 'T': Vector2(16, 23), 'Y': Vector2(17, 23), 'U': Vector2(18, 23), 'I': Vector2(19, 23), 'O': Vector2(20, 23), 'P': Vector2(21, 23),
	'A': Vector2(12, 24), 'S': Vector2(13, 24), 'D': Vector2(14, 24), 'F': Vector2(15, 24), 'G': Vector2(16, 24), 'H': Vector2(17, 24), 'J': Vector2(18, 24), 'K': Vector2(19, 24), 'L': Vector2(20, 24),
	'Z': Vector2(12, 25), 'X': Vector2(13, 25), 'C': Vector2(14, 25), 'V': Vector2(15, 25), 'B': Vector2(16, 25), 'N': Vector2(17, 25), 'M': Vector2(18, 25), ' ': Vector2(19, 25),
	'Backspace': Vector2(20, 25) }
	
var hoverblock_tile_positions = [
	
	Vector2(12, 23), Vector2(13, 23), Vector2(14, 23), Vector2(15, 23), Vector2(16, 23), Vector2(17, 23), Vector2(18, 23), Vector2(19, 23), Vector2(20, 23), Vector2(21, 23),  # QWERTYUIOP
	Vector2(12, 24), Vector2(13, 24), Vector2(14, 24), Vector2(15, 24), Vector2(16, 24), Vector2(17, 24), Vector2(18, 24), Vector2(19, 24), Vector2(20, 24),
	Vector2(12, 25), Vector2(13, 25), Vector2(14, 25), Vector2(15, 25), Vector2(16, 25), Vector2(17, 25), Vector2(18, 25),
	Vector2(19, 25),  # Space
	Vector2(20, 25)   # Backspace
]

var digit_atlas_positions = {
	0: Vector2i(2, 5), 1: Vector2i(2, 6), 2: Vector2i(2, 7), 3: Vector2i(2, 8),
	4: Vector2i(1, 9), 5: Vector2i(2, 9), 6: Vector2i(1, 10), 7: Vector2i(2, 10),
	8: Vector2i(1, 11), 9: Vector2i(2, 11)
}


var high_scores = []
var current_score = 0
var current_letter_index = 0
var current_initial_position = 1
var input_enabled = false
var initials = ["", "", ""]  # Array to store the initials
var initial_position1 = Vector2(15, 20)
var initial_position2 = Vector2(16, 20)
var initial_position3 = Vector2(17, 20)

func active_menu():
	input_enabled = true
	initials = ["", "", ""]  # Reset initials array
	handle_backspace()
	display_high_scores()

func start_hsboss():
	scoremachine.connect("game_over", Callable(self, "_on_game_over"))
	if not FileAccess.file_exists(high_score_file_path):
		_create_high_score_file()
	else:
		_load_high_scores()
	set_physics_process(false)
	set_process(false)
	input_enabled = false
	initials = ["", "", ""]  # Reset initials array
	display_high_scores()  # Display the high scores when the screen is activated


var last_tap_time = 0.0
var double_tap_max_time = 0.3  # Adjust as necessary
var last_swipe_time = 0.0  # Debounce mechanism for swipes
var swipe_debounce_time = 0.2  # Increase debounce time
var last_tap_pos = Vector2()  # Store the position of the last tap

func _input(event):
	if input_enabled:
		if event is InputEventKey:
			if event.pressed:
				handle_key_event(event)
		elif event is InputEventScreenTouch:
			handle_screen_touch(event)
		elif event is InputEventScreenDrag:
			handle_screen_drag(event)

func handle_key_event(event):
	if event.keycode == KEY_LEFT:
		current_letter_index = max(0, current_letter_index - 1)
	elif event.keycode == KEY_RIGHT:
		current_letter_index = min(hoverblock_tile_positions.size() - 1, current_letter_index + 1)
	elif event.keycode == KEY_UP:
		current_letter_index = max(0, current_letter_index - 10)
	elif event.keycode == KEY_DOWN:
		current_letter_index = min(hoverblock_tile_positions.size() - 1, current_letter_index + 10)
	elif event.keycode == KEY_ENTER:
		handle_enter()

	update_hover_block()

func handle_screen_touch(event):
	if event.is_pressed():
		var touch_pos = event.position
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_tap_time < double_tap_max_time and touch_pos.distance_to(last_tap_pos) < 20:
			print("Double tap registered")
			handle_enter()
		else:
			print("Single tap registered. Time:", current_time)
			last_tap_time = current_time
			last_tap_pos = touch_pos
			#current_letter_index = get_tile_index_from_position(touch_pos)

	update_hover_block()

func handle_enter():
	if hoverblock_tile_positions[current_letter_index] == Vector2(20, 25):  # Backspace tile position
		handle_backspace()
	else:
		var selected_letter = get_letter_from_index(current_letter_index)
		if selected_letter != "":
			update_initial_position(selected_letter)

func handle_screen_drag(event):
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_swipe_time > swipe_debounce_time:
		var drag_vector = event.relative
		if abs(drag_vector.x) > abs(drag_vector.y):  # Horizontal drag
			if drag_vector.x > 0:
				current_letter_index = min(hoverblock_tile_positions.size() - 1, current_letter_index + 1)
			else:
				current_letter_index = max(0, current_letter_index - 1)
		else:  # Vertical drag
			if drag_vector.y > 0:
				current_letter_index = min(hoverblock_tile_positions.size() - 1, current_letter_index + 10)
			else:
				current_letter_index = max(0, current_letter_index - 10)
		last_swipe_time = current_time
		print("Swipe registered. Time:", last_swipe_time)
		update_hover_block()












func handle_backspace():
	current_initial_position = 1
	initials = ["", "", ""]
	display_board.set_cell(Vector2i(initial_position1.x, initial_position1.y), 0, Vector2i(1, 12))  # Clear the cell
	display_board.set_cell(Vector2i(initial_position2.x, initial_position2.y), 0, Vector2i(1, 12))  # Clear the cell
	display_board.set_cell(Vector2i(initial_position3.x, initial_position3.y), 0, Vector2i(1, 12))  # Clear the cell

func array_to_string(arr: Array) -> String:
	var result = ""
	for element in arr:
		result += str(element)
	return result

func display_high_scores():
	for i in range(min(high_score_list.size(), highscore_initial_digit_tile_positions.size())):
		var highscore = high_score_list[i]
		var initials = highscore['initials']
		var score = pad_left(highscore['score'], 7, '0')
		var positions = highscore_initial_digit_tile_positions[i]

		# Display initials
		for j in range(initials.length()):
			var letter = initials[j]
			var pos = positions['initials' + str(i + 1)][j]
			var atlas_position = letter_atlas_positions[letter]
			display_board.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(atlas_position.x, atlas_position.y))

		# Display score
		for j in range(score.length()):
			var digit = int(score[j])  # Convert the digit to an integer
			var pos = positions['digits' + str(i + 1)][j]
			var atlas_position = digit_atlas_positions[digit]  # Use digit_atlas_positions dictionary
			display_board.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(atlas_position.x, atlas_position.y))


func update_initial_position(selected_letter):
	if selected_letter in letter_atlas_positions:
		var atlas_position = letter_atlas_positions[selected_letter]
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
			var initials_string = array_to_string(initials)  # Use the custom function
			var new_score = {"score": score, "initials": initials_string}
			high_score_list.append(new_score)
			print("New score added:", new_score)
			print("High score list before sorting:", high_score_list)
			
			# Sort and save high scores
			sort_high_scores_custom()
			save_high_scores()
			
			current_initial_position = 1  # Reset for next entry
			exit_highscore()
	else:
		print("Error: Selected letter not found in letter_atlas_positions")


# Custom sort function
func sort_high_scores_custom():
	for i in range(high_score_list.size() - 1):
		for j in range(i + 1, high_score_list.size()):
			if high_score_list[i]['score'] < high_score_list[j]['score']:
				var temp = high_score_list[i]
				high_score_list[i] = high_score_list[j]
				high_score_list[j] = temp
	print("Scores after custom sorting:", high_score_list)
	
	# Keep only the top 9 scores
	if high_score_list.size() > 9:
		high_score_list.resize(9)
	print("Scores after resizing:", high_score_list)

func save_high_scores():
	# Save the high scores
	var file = FileAccess.open(high_score_file_path, FileAccess.WRITE)
	file.store_var(high_score_list)
	file.close()
	print("High scores saved:", high_score_list)










func skip_game_over():
	#print("Skipping game over screen.")
	#save_high_scores()
	self.hide()

func get_letter_from_index(index):
	var letters = "QWERTYUIOPASDFGHJKLZXCVBNM "
	if index < letters.length():
		return letters[index]
	return ""

func get_tile_index_from_position(position):
	for i in range(hoverblock_tile_positions.size()):
		if hoverblock_tile_positions[i] == position:
			return i
	return -1

func get_current_score():
	return current_score



func _create_high_score_file():
	var file = FileAccess.open(high_score_file_path, FileAccess.WRITE)
	if file:
		file.store_var(high_score_list)
		file.close()
		print("High score file created at: ", high_score_file_path)
	else:
		print("Failed to create high score file.")
		
func _load_high_scores():
	var file = FileAccess.open(high_score_file_path, FileAccess.READ)
	if file:
		high_score_list = file.get_var()
		file.close()
		print("High scores loaded: ", high_score_list)
	else:
		print("Failed to load high scores.")

func pad_left(value, length, char):
	var result = str(value)
	while result.length() < length:
		result = char + result
	return result

func exit_highscore():
	self.hide()
	self.set_physics_process(false)
	popup.show()
	popup.start_popup()
func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tilemap_pos = self.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = self.map_to_local(tile_pos)
	var global_pos = self.to_global(local_pos)
	return global_pos

func clear_high_score_file():
	var file_path = "user://high_scores.save"
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("user://")
		if dir:
			var err = dir.remove(file_path)
			if err == OK:
				print("High score save file cleared.")
			else:
				print("Failed to clear high score save file. Error code: ", err)
		else:
			print("Failed to open user directory.")
	else:
		print("High score save file does not exist.")

func _on_game_over(final_score):
	current_score = final_score
	print("Game over! Final score: ", current_score)
	
func update_hover_block():
	hover_block.position = tile_position_to_global_position(hoverblock_tile_positions[current_letter_index])
		
func _process(delta):
	if input_enabled:
		update_hover_block()
