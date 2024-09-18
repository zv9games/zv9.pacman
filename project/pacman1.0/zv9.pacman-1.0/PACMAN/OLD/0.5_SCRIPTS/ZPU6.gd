extends Node

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

signal online                    # ALL
signal all_nodes_initialized     # BINARY
signal start_button_pressed      # LOADINGSCREEN
signal state_changed(new_state)  # GAMESTATE
signal player_select             # ZPU
signal begin_game                # STARTMENU
signal dot_eaten                 # GAMEBOARD
signal big_dot_eaten             # GAMEBOARD
signal pacman_ghost_collision    # PACMAN
signal start_new_level           # ZPU
signal game_over                 # ZPU
signal level_complete            # ZPU



@onready var level_end = $"/root/BINARY/ORIGINAL/MAP/LEVELEND"
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var scoremachine = $"/root/BINARY/SCOREMACHINE"
@onready var gamestate = $"/root/BINARY/GAMESTATE"
@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var levelendtimer = $"/root/BINARY/ZPU/LevelEndTimer"
@onready var startmenu = $"/root/BINARY/STARTMENU"
@onready var loading = $"/root/BINARY/STARTMENU/LOADINGSCREEN"






@onready var soundbank = $"/root/BINARY/SOUNDBANK"

var current_level = 0
var total_dots = 0
var remaining_dots = 0
var toggle_count = 0
var level_completed = false
var lives = 3
var level_transition_in_progress = false
var pacman_start_position = Vector2()
var play_eat1 = true
var play_siren1 = true
var sound_playing = false

func _ready():
	gameboard.connect("dot_eaten", Callable(self, "_on_dot_eaten"))
	gameboard.connect("big_dot_eaten", Callable(self, "_on_big_dot_eaten"))
	levelendtimer.connect("timeout", Callable(self, "_on_LevelEndTimer_timeout"))
	pacman.connect("pacman_ghost_collision", Callable(self, "_on_pacman_ghost_collision"))
	startmenu.connect("begin_game", Callable(self, "start_new_game"))
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "go_online"))
	add_child(startup_timer)
	startup_timer.start()
	startmenu.connect("begin_game", Callable(self, "_on_begin_game"))
	gamestate.connect("state_changed", Callable(self, "_on_state_changed"))


func go_online():
	level_setup()
	pacman_start_position = pacman.global_position
	emit_signal("online", self.name)
	
func _on_begin_game():
	print("Game has begun!")

func level_setup():
	scoremachine.display_level_number(current_level)
	scoremachine.display_lives()
	level_completed = false
	level_transition_in_progress = false
	gameboard.reset_dots()
	total_dots = gameboard.count_total_dots()
	remaining_dots = total_dots

func start_new_game():
	if level_transition_in_progress:
		return
	level_transition_in_progress = true
	pacman.visible = true
	level_setup()
	reset_characters()
	pacman.set_freeze(true)
	

func reset_level():
	reset_characters()
	scoremachine.display_lives()

func reset_characters():
	pacman.global_position = pacman_start_position
	pacman.set_freeze(false)
	blinky.global_position = blinky.start_position
	#pinky.global_position = pinky.start_position
	#inky.global_position = inky.start_position
	#clyde.global_position = clyde.start_position
	blinky.set_freeze(false)
	#pinky.set_freeze(false)
	#inky.set_freeze(false)
	#clyde.set_freeze(false)
	blinky.visible = true
	pinky.visible = true
	inky.visible = true
	clyde.visible = true
	
func handle_game_over():
	gamestate.set_state(States.PRE_GAME)
	startmenu.visible = true
	pacman.visible = false
	blinky.visible = false
	pinky.visible = false
	inky.visible = false
	clyde.visible = false
	gameboard.visible = false
	loading.visible = true
	current_level = 0
	lives = 3
	level_transition_in_progress = false
	level_completed = false
	reset_score()
	loading.start_loading_screen()
	startmenu.connect("start_button_pressed", Callable(self, "_on_start_button_pressed"))

func reset_score():
	scoremachine.reset_score()

func pad_left(value: String, length: int, pad_char: String) -> String:
	while value.length() < length:
		value = pad_char + value
	return value



func _on_pacman_ghost_collision(ghost_state, ghost):
	if ghost_state == States.FRIGHTENED:
		scoremachine.add_points(200)  # Add points for eating a frightened ghost
		ghost._on_area_2d_body_entered(pacman)  # Trigger the ghost's own collision handling
		return  # Exit the function to avoid losing a life
	lives -= 1
	gamestate.set_state(States.INITIAL)
	if lives > 0:
		reset_level()
	else:
			handle_game_over()

func _on_start_button_pressed():
	startmenu.visible = false
	loading.stop_loading_screen()
	reset_level()
	reset_score()
	level_setup()
	gamestate.set_state(States.INITIAL)
	


func _on_dot_eaten():
	if play_eat1:
		pass
	else:
		pass
	play_eat1 = not play_eat1  # Toggle the flag
	remaining_dots -= 1
	scoremachine.add_points(10)
	if remaining_dots == 0:
		on_last_dot_eaten()

func _on_big_dot_eaten():
	scoremachine.add_points(50)
	gamestate.set_state(States.FRIGHTENED)
	gamestate.restart_frightened_timer()

func on_last_dot_eaten():
	level_completed = true
	gamestate.set_state(States.INITIAL)
	pacman.set_freeze(true)
	pacman.visible = false
	toggle_count = 0
	levelendtimer.start(0.2)
	emit_signal("level_complete")
	
	print("all sounds stopped")


func _on_state_changed(new_state):
	match_state(new_state)

func match_state(new_state):
	match new_state:
		States.CHASE:
			print("Entering CHASE state")
			# Add commands for CHASE state
		States.SCATTER:
			print("Entering SCATTER state")
			# Add commands for SCATTER state
		States.FRIGHTENED:
			print("Entering FRIGHTENED state")
			
		States.INITIAL:
			print("Entering INITIAL state")
			# Add commands for INITIAL state
		States.PRE_GAME:
			print("Entering PRE_GAME state")
			# Add commands for PRE_GAME state


func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tilemap_pos = gameboard.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = gameboard.map_to_local(tile_pos)
	var global_pos = gameboard.to_global(local_pos)
	return global_pos
	


func on_level_completed():
	current_level += 1
	level_completed = false
	start_new_game()
	gamestate.set_state(States.INITIAL)
	pacman.set_freeze(false)
	pacman.global_position = pacman_start_position
	level_transition_in_progress = false

func _on_level_end_timer_timeout():
	level_end.visible = not level_end.visible
	toggle_count += 1
	if toggle_count >= 6:
		levelendtimer.stop()
		level_end.visible = false
		if level_completed:
			on_level_completed()
		else:
			reset_level()
