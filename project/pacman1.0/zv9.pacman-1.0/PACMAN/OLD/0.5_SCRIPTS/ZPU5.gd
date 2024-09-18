extends Node

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }
enum FrightStates { NORMAL, CAUGHT }

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
@onready var sirentimer = $"/root/BINARY/SOUNDBANK/SIRENTIMER"

@onready var zpu5 = get_node("/root/BINARY/ZPU")
@onready var start5 = get_node("/root/BINARY/SOUNDBANK/START")
@onready var self1 = $"/root/BINARY/SOUNDBANK"

var START
var current_level = 0
var total_dots = 0
var remaining_dots = 0
var toggle_count = 0
var level_completed = false
var level_transition_in_progress = false
var pacman_start_position = Vector2()
var play_eat1 = true

func _ready():
	connect_signals()
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "go_online"))
	add_child(startup_timer)
	startup_timer.start()

func connect_signals():
	gameboard.connect("dot_eaten", Callable(self, "_on_dot_eaten"))
	gameboard.connect("big_dot_eaten", Callable(self, "_on_big_dot_eaten"))
	levelendtimer.connect("timeout", Callable(self, "_on_level_end_timer_timeout"))
	pacman.connect("pacman_ghost_collision", Callable(self, "_on_pacman_ghost_collision"))
	startmenu.connect("begin_game", Callable(self, "_on_begin_game"))
	gamestate.connect("state_changed", Callable(self, "_on_state_changed"))
	connect("level_complete", Callable(self, "_on_level_completed"))
	
func go_online():
	level_setup()
	pacman_start_position = pacman.global_position
	emit_signal("online", self.name)
	startup()
	
func startup():
	gamestate.set_state(States.PRE_GAME)  
	pacman.visible = false
	pacman.set_freeze(true)  
	blinky.visible = false  
	pinky.visible = false 
	inky.visible = false
	clyde.visible = false
	gameboard.visible = false

func _on_begin_game():
	print("Game has begun!")
	gameboard.visible = true
	pacman.visible = true  
	blinky.visible = true  
	pinky.visible = true 
	inky.visible = true
	clyde.visible = true
	gameboard.reset_dots()
	scoremachine.reset_score()
	soundbank.play("START")
	gamestate.set_state(States.INITIAL)
	
func _on_start_finished():
	pacman.set_freeze(false)
	soundbank.play("SIREN1")
	sirentimer.start(0.35)

func _on_siren1_finished():
	soundbank.play("SIREN1")
	
func _on_fright_finished():
	soundbank.play("FRIGHT")
		
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
	
func restart_game():
	soundbank.stop_all_sounds()
	reset_score()
	scoremachine.reset_lives()
	reset_characters()
	print("Game restarted!")

func reset_level():
	reset_characters()
	scoremachine.display_lives()

func reset_characters():
	pacman.global_position = pacman_start_position
	pacman.set_freeze(false)
	
	
	blinky.visible = true
	blinky.move_blinky_initial()  # Call move_blinky_initial to reset Blinky's position and behavior
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
	level_transition_in_progress = false
	level_completed = false
	reset_score()
	loading.start_loading_screen()
	startmenu.connect("start_button_pressed", Callable(self, "_on_start_button_pressed"))
	restart_game()  # Call restart_game to reset the game state

func reset_score():
	scoremachine.reset_score()

func _on_pacman_ghost_collision(ghost_state, ghost):
	if gamestate.get_state() == States.FRIGHTENED and ghost_state == FrightStates.NORMAL:
		scoremachine.add_points(200)
		ghost.set_state(FrightStates.CAUGHT)
		ghost.move_to_shed()
	elif gamestate.get_state() in [States.CHASE, States.SCATTER] and ghost_state == FrightStates.NORMAL:
		scoremachine.lose_life()
		gamestate.set_state(States.INITIAL)
		if scoremachine.lives > 0:
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
		soundbank.play("EAT1")
	else:
		soundbank.play("EAT2")
	play_eat1 = not play_eat1
	remaining_dots -= 1
	scoremachine.add_points(10)
	if remaining_dots == 0:
		on_last_dot_eaten()

func _on_big_dot_eaten():
	scoremachine.add_points(50)
	gamestate.set_state(States.FRIGHTENED)
	gamestate.restart_frightened_timer()
	
func on_last_dot_eaten():
	pacman.set_freeze(true)
	soundbank.stop_all_sounds()
	level_completed = true
	gamestate.set_state(States.INITIAL)
	toggle_count = 0
	levelendtimer.start(0.2)
	emit_signal("level_complete")

func _on_state_changed(new_state):
	match_state(new_state)

func match_state(new_state):
	match new_state:
		States.CHASE:
			soundbank.stop("FRIGHT")
		States.SCATTER:
			print("Entering SCATTER state")
		States.FRIGHTENED:
			soundbank.play("FRIGHT")
		States.INITIAL:
			print("Entering INITIAL state")
		States.PRE_GAME:
			print("Entering PRE_GAME state")

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	return gameboard.local_to_map(global_pos)

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	return gameboard.to_global(gameboard.map_to_local(tile_pos))

func on_level_completed():
	current_level += 1
	level_completed = false
	start_new_game()
	gamestate.set_state(States.INITIAL)
	pacman.set_freeze(false)
	pacman.global_position = pacman_start_position
	level_transition_in_progress = false
	soundbank.stop_all_sounds()
	soundbank.play("START")
	

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
