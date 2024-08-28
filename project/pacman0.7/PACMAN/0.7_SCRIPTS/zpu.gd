extends Node

signal online

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING }
enum FrightStates { NORMAL, CAUGHT }

@onready var binary = $/root/BINARY
@onready var gamestate = $/root/BINARY/GAMESTATE 
@onready var loading = $/root/BINARY/OPEN/LOADING
@onready var gameboard = $/root/BINARY/ORIGINAL/MAP/GAMEBOARD
@onready var pacman = $/root/BINARY/ORIGINAL/CHARACTERS/PACMAN
@onready var blinky = $/root/BINARY/ORIGINAL/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/ORIGINAL/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/ORIGINAL/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/ORIGINAL/CHARACTERS/CLYDE
@onready var soundbank = $/root/BINARY/SOUNDBANK
@onready var scoremachine = $/root/BINARY/SCOREMACHINE
@onready var startmenu = $/root/BINARY/STARTMENU

func _ready():
	prep_game()
	var timer = Timer.new()
	timer.wait_time = 0.2  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	binary.connect("all_nodes_initialized", Callable(self, "_on_all_nodes_initialized"))
	gameboard.connect("last_dot_eaten", Callable(self, "_on_last_dot_eaten"))

func _emit_online_signal():
	emit_signal("online", self.name)
	
func _on_all_nodes_initialized():
	loading.start_loading_screen()

func prep_game():
	gameboard.visible = false
	pacman.visible = false
	blinky.visible = false
	pinky.visible = false
	inky.visible = false
	clyde.visible = false

func reveal_gameboard():
	gameboard.visible = true
	pacman.visible = true
	blinky.visible = true
	pinky.visible = true
	inky.visible = true
	clyde.visible = true
	
func start_game():
	loading.stop_loading_screen()
	gameboard.count_dots()
	soundbank.stop_all_sounds()
	soundbank.stop_sound_timers()
	pacman.pac_start_pos()
	pacman.set_freeze(true)
	reveal_gameboard()
	soundbank.play("START")
	gamestate.set_state(States.INITIAL)
	
func _on_pacman_ghost_collision(ghost_state, ghost):
	if gamestate.get_state() == States.FRIGHTENED and ghost_state == FrightStates.NORMAL:
		scoremachine.add_points(200)
		ghost.set_state(FrightStates.CAUGHT)
		ghost.move_to_shed()
	elif gamestate.get_state() in [States.CHASE, States.SCATTER] and ghost_state == FrightStates.NORMAL:
		scoremachine.lose_life()
		gamestate.set_state(States.INITIAL)
		if scoremachine.lives <= 0:
			handle_game_over()

						
func handle_game_over():
	gameboard.visible = false
	startmenu.visible = true
	loading.visible = true
	scoremachine.reset_level_display()
	scoremachine.reset_score()
	scoremachine.reset_lives()
	loading.start_loading_screen()
	pacman.visible = false
	blinky.visible = false
	pinky.visible = false
	inky.visible = false
	clyde.visible = false
	gamestate.set_state(States.LOADING)

func _on_last_dot_eaten():
	gameboard.reset_dots()
	scoremachine.add_level()
	start_game()
