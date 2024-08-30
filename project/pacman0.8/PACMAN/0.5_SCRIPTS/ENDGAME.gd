extends Node
class_name Endgame

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

signal level_complete
signal game_over
signal initialized

@onready var eat1 = $/"root/BINARY/SOUNDBANK/EAT1"
@onready var tilemap = $"/root/BINARY/ORIGINAL/MAP/TILEMAP"
@onready var level_end = $"/root/BINARY/ORIGINAL/MAP/LEVEL_END"
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var score_machine = $"/root/BINARY/SCORE_MACHINE"
@onready var gamestate = $"/root/BINARY/GAME_STATE"
@onready var toggle_timer = $ToggleTimer
@onready var start_menu = $"/root/BINARY/START_MENU"
@onready var loading = $"/root/BINARY/START_MENU/LOADING_SCREEN"
@onready var game_over_timer = $"/root/BINARY/END_GAME/GameOverTimer"

var current_level = 0
var total_dots = 0
var remaining_dots = 0
var toggle_count = 0
var level_completed = false
var lives = 3
var level_transition_in_progress = false
var pacman_start_position = Vector2()

var tile_digits = {
	0: Vector2i(2, 5), 1: Vector2i(2, 6), 2: Vector2i(2, 7), 3: Vector2i(2, 8),
	4: Vector2i(1, 9), 5: Vector2i(2, 9), 6: Vector2i(1, 10), 7: Vector2i(2, 10),
	8: Vector2i(1, 11), 9: Vector2i(2, 11)
}

var level_display_positions = [Vector2i(23, 1), Vector2i(24, 1), Vector2i(25, 1)]
var life_display_positions = [Vector2i(27, 31), Vector2i(28, 31), Vector2i(29, 31)]
var life_tile_coords = Vector2i(1, 3)
var empty_life_tile_coords = Vector2i(8, 10)

func _ready():
	print("ready", self)
	tilemap.connect("dot_eaten", Callable(self, "_on_dot_eaten"))
	tilemap.connect("big_dot_eaten", Callable(self, "_on_big_dot_eaten"))
	toggle_timer.connect("timeout", Callable(self, "_on_toggle_timer_timeout"))
	pacman.connect("pacman_ghost_collision", Callable(self, "_on_pacman_ghost_collision"))
	game_over_timer.connect("timeout", Callable(self, "on_game_over_timer_timerout"))
	initialize()

func initialize():
	level_setup()
	pacman_start_position = pacman.global_position
	emit_signal("initialized", self.name)

func level_setup():
	display_level_number(current_level)
	display_lives()
	level_completed = false
	level_transition_in_progress = false
	tilemap.reset_dots()
	total_dots = count_total_dots()
	remaining_dots = total_dots

func start_new_game():
	if level_transition_in_progress:
		return
	level_transition_in_progress = true
	pacman.visible = true
	tilemap.remove_dots()
	level_setup()
	reset_characters()

func reset_characters():
	pacman.global_position = pacman_start_position
	pacman.set_freeze(false)
	blinky.global_position = blinky.start_position
	pinky.global_position = pinky.start_position
	inky.global_position = inky.start_position
	clyde.global_position = clyde.start_position
	blinky.set_freeze(false)
	pinky.set_freeze(false)
	inky.set_freeze(false)
	clyde.set_freeze(false)
	blinky.visible = true
	pinky.visible = true
	inky.visible = true
	clyde.visible = true

func _on_toggle_timer_timeout():
	
	level_end.visible = not level_end.visible
	toggle_count += 1
	if toggle_count >= 6:
		toggle_timer.stop()
		level_end.visible = false
		if level_completed:
			current_level += 1
			level_completed = false
			start_new_game()
			gamestate.set_state(States.INITIAL)
			pacman.set_freeze(false)
			pacman.global_position = pacman_start_position
			level_transition_in_progress = false
		else:
			reset_level()

func _on_pacman_ghost_collision(ghost_state, ghost):
	if ghost_state == States.FRIGHTENED:
		# Handle the case when Pacman eats a frightened ghost
		score_machine.add_points(200)  # Add points for eating a frightened ghost
		ghost._on_area_2d_body_entered(pacman)  # Trigger the ghost's own collision handling
		return  # Exit the function to avoid losing a life

	lives -= 1

	gamestate.set_state(States.INITIAL)
	if lives > 0:
		reset_level()
	else:
			handle_game_over()



func reset_level():
	reset_characters()
	display_lives()
	
func handle_game_over():
	
	gamestate.set_state(States.PRE_GAME)
	start_menu.visible = true
	pacman.visible = false
	blinky.visible = false
	pinky.visible = false
	inky.visible = false
	clyde.visible = false
	tilemap.visible = false
	loading.visible = true
	current_level = 0
	lives = 3
	level_transition_in_progress = false
	level_completed = false
	reset_score()
	loading.start_loading_screen()
	start_menu.connect("start_button_pressed", Callable(self, "_on_start_button_pressed"))

func _on_start_button_pressed():
	start_menu.visible = false
	loading.stop_loading_screen()
	reset_level()
	reset_score()
	level_setup()
	gamestate.set_state(States.INITIAL)
	
func reset_score():
	score_machine.reset_score()

func count_total_dots() -> int:
	var total_dots = 0
	var dot_atlas_coords = [Vector2i(7, 8), Vector2i(8, 8)]
	for cell in tilemap.get_used_cells(0):
		var atlas_coords = tilemap.get_cell_atlas_coords(0, cell)
		if atlas_coords in dot_atlas_coords:
			total_dots += 1
	return total_dots

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
		tilemap.set_cell(0, tile_pos, 0, atlas_coords)

func display_lives():
	for i in range(3):
		var tile_pos = life_display_positions[i]
		tilemap.set_cell(0, tile_pos, -1)
	for i in range(lives):
		var tile_pos = life_display_positions[i]
		tilemap.set_cell(0, tile_pos, 0, life_tile_coords)
	for i in range(lives, 3):
		var tile_pos = life_display_positions[i]
		tilemap.set_cell(0, tile_pos, 0, empty_life_tile_coords)

func _on_dot_eaten():
	eat1.play()
	remaining_dots -= 1
	score_machine.add_points(10)
	if remaining_dots == 0:
		level_completed = true
		gamestate.set_state(States.INITIAL)
		pacman.set_freeze(true)
		pacman.visible = false
		toggle_count = 0
		toggle_timer.start(0.2)
		emit_signal("level_complete")

func _on_big_dot_eaten():
	score_machine.add_points(50)
	gamestate.set_state(States.FRIGHTENED)
	gamestate.restart_frightened_timer()

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tilemap_pos = tilemap.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = tilemap.map_to_local(tile_pos)
	var global_pos = tilemap.to_global(local_pos)
	return global_pos
