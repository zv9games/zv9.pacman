extends Node

signal online
signal start_game

@onready var gamestate = $"/root/BINARY/GAMESTATE"
@onready var loading = $"/root/BINARY/STARTMENU/LOADING"
@onready var menutimer = $"/root/BINARY/STARTMENU/MENUTIMER"
@onready var zpu = $"/root/BINARY/ZPU"
@onready var binary = $"/root/BINARY"
@onready var levelend = $/root/BINARY/MODES/ORIGINAL/LEVELEND
@onready var camera = $/root/BINARY/Camera2D

var tile_letters = {
	'A': Vector2i(3, 12), 'B': Vector2i(4, 12), 'C': Vector2i(5, 12), 'D': Vector2i(6, 12),
	'E': Vector2i(7, 12), 'F': Vector2i(8, 12), 'G': Vector2i(9, 12), 'H': Vector2i(10, 12),
	'I': Vector2i(0, 13), 'J': Vector2i(1, 13), 'K': Vector2i(2, 13), 'L': Vector2i(3, 13),
	'M': Vector2i(4, 13), 'N': Vector2i(5, 13), 'O': Vector2i(6, 13), 'P': Vector2i(7, 13),
	'Q': Vector2i(8, 13), 'R': Vector2i(9, 13), 'S': Vector2i(10, 13), 'T': Vector2i(0, 14),
	'U': Vector2i(1, 14), 'V': Vector2i(2, 14), 'W': Vector2i(3, 14), 'X': Vector2i(4, 14),
	'Y': Vector2i(5, 14), 'Z': Vector2i(6, 14)
}

var tile_digits = {
	'0': Vector2i(2, 5), '1': Vector2i(2, 6), '2': Vector2i(2, 7), '3': Vector2i(2, 8),
	'4': Vector2i(1, 9), '5': Vector2i(2, 9), '6': Vector2i(1, 10), '7': Vector2i(2, 10),
	'8': Vector2i(1, 11), '9': Vector2i(2, 11)
}

var menu_texts = [
	{"text": "ORIGINAL", "start_pos": Vector2i(13, 16)},
	{"text": "EXPANSIVE", "start_pos": Vector2i(13, 18)},
	{"text": "INFINITY", "start_pos": Vector2i(13, 20)},
]

var current_text_index = 0
var current_char_index = 0
var black_tile_atlas = Vector2i(8, 10)
var selector_tile_atlas = Vector2i(8, 14)
var selector_index = 0  # Index of the current selection

func _ready():
	binary.connect("all_nodes_initialized", Callable(self, "_on_all_nodes_initialized"))
	clear_tiles()
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	levelend.visible = false
	camera.connect("swipe_detected", Callable(self, "_on_swipe_detected"))

func _on_all_nodes_initialized():
	# Start the typing effect
	menutimer.wait_time = 0.01  # Adjust the typing speed as needed
	menutimer.connect("timeout", Callable(self, "_type_next_letter"))
	menutimer.start()
	
	# Connect the input event
	set_process_input(true)

func _emit_online_signal():
	emit_signal("online", self.name)

func clear_tiles():
	if loading:
		for text_info in menu_texts:
			var start_pos = text_info["start_pos"]
			for i in range(text_info["text"].length()):
				loading.set_cell(Vector2i(start_pos + Vector2i(i, 0)), 0, black_tile_atlas)  # Set the black tile
		# Set the initial selector position
		update_selector_position()
	else:
		print("Loading node is null")

func _type_next_letter():
	if current_text_index < menu_texts.size():
		var text_info = menu_texts[current_text_index]
		var text = text_info["text"]
		var start_pos = text_info["start_pos"]
		
		if current_char_index < text.length():
			var char = text[current_char_index]
			var tile_pos = null
			if tile_letters.has(char):
				tile_pos = tile_letters[char]
			elif tile_digits.has(char):
				tile_pos = tile_digits[char]
			
			if tile_pos and loading:
				loading.set_cell(Vector2i(start_pos + Vector2i(current_char_index, 0)), 0, tile_pos)
			current_char_index += 1
		else:
			current_text_index += 1
			current_char_index = 0
		
		menutimer.start()
	else:
		menutimer.stop()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position
		if loading:
			var tile_pos = loading.local_to_map(mouse_pos)
			print("Mouse clicked at: ", tile_pos)  # Debugging print
			handle_menu_option(tile_pos)
	elif event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_UP:
				move_selector(-1)
			elif event.keycode == KEY_DOWN:
				move_selector(1)
			elif event.keycode == KEY_ENTER:
				select_option()

func move_selector(direction: int):
	if loading:
		# Clear the current selector position
		loading.set_cell(menu_texts[selector_index]["start_pos"] - Vector2i(1, 0), 0, black_tile_atlas)
		# Update the selector index
		selector_index = clamp(selector_index + direction, 0, menu_texts.size() - 1)
		# Set the new selector position
		update_selector_position()

func update_selector_position():
	if loading:
		loading.set_cell(menu_texts[selector_index]["start_pos"] - Vector2i(1, 0), 0, selector_tile_atlas)

func select_option():
	var selected_text = menu_texts[selector_index]["text"]
	match selected_text:
		"ORIGINAL":
			print("Original selected")
			emit_signal("start_game")
			hide_start_menu()
			loading.stop_game_loop()
			zpu.start_game()
			disable_swipes_and_taps()  # Disable swipes and taps
		"EXPANSIVE":
			print("Expansive selected")
			emit_signal("start_game")
			hide_start_menu()
			loading.stop_game_loop()
			zpu.start_game()
			disable_swipes_and_taps()  # Disable swipes and taps
		"INFINITY":
			print("Infinity selected")
			emit_signal("start_game")
			hide_start_menu()
			loading.stop_game_loop()
			zpu.start_game()
			disable_swipes_and_taps()  # Disable swipes and taps

func handle_menu_option(tile_pos):
	for text_info in menu_texts:
		var start_pos = text_info["start_pos"]
		var text = text_info["text"]
		for i in range(text.length()):
			if tile_pos == start_pos + Vector2i(i, 0):
				print("Option selected: ", text)  # Debugging print
				match text:
					"ORIGINAL":
						print("Original selected")
						emit_signal("start_game")
						hide_start_menu()
						loading.stop_game_loop()
						zpu.start_game()
						disable_swipes_and_taps()  # Disable swipes and taps
					"EXPANSIVE":
						print("Expansive selected")
						emit_signal("start_game")
						hide_start_menu()
						loading.stop_game_loop()
						zpu.start_game()
						disable_swipes_and_taps()  # Disable swipes and taps
					"INFINITY":
						print("Infinity selected")
						emit_signal("start_game")
						hide_start_menu()
						loading.stop_game_loop()
						zpu.start_game()
						disable_swipes_and_taps()  # Disable swipes and taps

func hide_start_menu():
	if loading:
		loading.visible = false
	set_process_input(false)

func restart():
	# Hide game elements
	levelend.visible = false
	loading.visible = true
	
	# Clear tiles and reset menu
	clear_tiles()
	current_text_index = 0
	current_char_index = 0
	selector_index = 0
	
	# Restart the typing effect
	menutimer.start()
	
	# Enable input processing
	set_process_input(true)

func _on_swipe_detected(direction: Vector2):
	if direction == Vector2.UP:
		move_selector(-1)
	elif direction == Vector2.DOWN:
		move_selector(1)
	elif direction == Vector2.RIGHT or direction == Vector2.LEFT:
		select_option()

func disable_swipes_and_taps():
	camera.disconnect("swipe_detected", Callable(self, "_on_swipe_detected"))
	set_process_input(false)
