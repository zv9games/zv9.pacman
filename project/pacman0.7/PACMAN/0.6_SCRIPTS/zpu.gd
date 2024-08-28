extends Node

signal online
signal start_button_pressed
signal freeze_pacman
signal state_changed
signal last_dot_eaten

func _ready():
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	var main_script = get_node("/root/BINARY")
	if main_script:
		main_script.connect("all_nodes_initialized", Callable(self, "_on_all_nodes_initialized"))
	startmenu.connect("start_button_pressed", Callable(self, "_on_start_button_pressed"))
	gameboard.connect("big_dot_eaten", Callable(self, "on_big_dot_eaten"))
	gameboard.connect("dot_eaten", Callable(self, "on_dot_eaten"))

func _emit_online_signal():
	emit_signal("online", self.name)

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING }
enum FrightStates { NORMAL, CAUGHT }

func _on_all_nodes_initialized():
	print("All nodes have been initialized. ZPU is ready to proceed.")
	start_loading_loop()

var left_point = Vector2(6, 13)
var right_point = Vector2(26, 13)
var current_state
var eat_sound_toggle = true

@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var loading = $"/root/BINARY/LOADING"
@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var startmenu = $"/root/BINARY/STARTMENU"
@onready var gamestate = $/root/BINARY/GAMESTATE
@onready var scoremachine = $/root/BINARY/SCOREMACHINE
@onready var soundbank = $/root/BINARY/SOUNDBANK
@onready var frighttimer = $/root/BINARY/SOUNDBANK/FRIGHTTIMER
@onready var sirentimer = $/root/BINARY/SOUNDBANK/SIRENTIMER

func set_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	gamestate.set_state(new_state)

func start_loading_loop():
	gameboard.visible = false
	loading.visible = true
	loading.start_loading_screen()

func _on_start_button_pressed():
	gameboard.visible = true
	startmenu.visible = false
	pacman.visible = true
	loading.stop_loading_screen()
	print("start it")
	
	soundbank.stop_sound_timers()
	soundbank.stop_all_sounds()
	soundbank.play("START")
	gamestate.set_state(States.INITIAL)
	pacman.set_freeze(true)
	print("frozen true")
	blinky.visible = true
	pacman._on_start_button_pressed()

func _on_last_dot_eaten():
	scoremachine.add_level()
	pacman._on_start_button_pressed()
	soundbank.stop("SIREN4")
	sirentimer.stop()
	soundbank.stop("FRIGHT")
	frighttimer.stop()
	soundbank.play("START")
	pacman.set_freeze(true)
	gamestate.set_state(States.INITIAL)
	gameboard.reset_dots()

func on_big_dot_eaten():
	gamestate.set_state(States.FRIGHTENED)
	gamestate.restart_frightened_timer()
	frighttimer.start()
	soundbank.play("FRIGHT")

func on_dot_eaten():
	if eat_sound_toggle:
		soundbank.play("EAT1")
	else:
		soundbank.play("EAT2")
	eat_sound_toggle = !eat_sound_toggle  # Toggle the flag

func _on_pacman_ghost_collision(ghost_state, ghost):
	if gamestate.get_state() == States.FRIGHTENED and ghost_state == FrightStates.NORMAL:
		scoremachine.add_points(200)
		ghost.set_state(FrightStates.CAUGHT)
		ghost.move_to_shed()
	elif gamestate.get_state() in [States.CHASE, States.SCATTER] and ghost_state == FrightStates.NORMAL:
		scoremachine.lose_life()
		gamestate.set_state(States.INITIAL)
		if scoremachine.lives > 0:
			gameboard.reset_dots()
		else:
			handle_game_over()

func handle_game_over():
	gameboard.visible = false
	startmenu.visible = true
	loading.visible = true
	scoremachine.reset_level_display()
	scoremachine.reset_score()
	scoremachine.reset_lives()
	loading.start_loading_screen()
	gamestate.set_state(States.LOADING)
