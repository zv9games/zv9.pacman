extends Node

signal online
signal start_powerups

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	binary.connect("all_nodes_initialized", Callable(self, "start_zpu"))

func _emit_online_signal():
	emit_signal("online", self.name)
	
###########################################################################


enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING, PAUSE }

@onready var binary = $/root/BINARY
@onready var startmenu = $/root/BINARY/MENUS/STARTMENU
@onready var loading = $/root/BINARY/MENUS/LOADING
@onready var scoremachine = $/root/BINARY/ZPU/SCOREMACHINE
@onready var soundbank = $/root/BINARY/ZPU/SOUNDBANK
@onready var gamestate = $/root/BINARY/ZPU/GAMESTATE
@onready var gameboard = $/root/BINARY/GAME/ORIGINAL/TILEMAPLAYER
@onready var pacman = $/root/BINARY/GAME/CHARACTERS/PACMAN
@onready var blinky = $/root/BINARY/GAME/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/GAME/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/GAME/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/GAME/CHARACTERS/CLYDE
@onready var levelend = $/root/BINARY/GAME/ORIGINAL/LEVELEND
@onready var levelendtimer = $/root/BINARY/ZPU/TIMERS/LEVELENDTIMER
@onready var resetdotstimer = $/root/BINARY/ZPU/TIMERS/RESETDOTSTIMER
@onready var powerups = $/root/BINARY/GAME/POWERUPS
@onready var powerupsstart = $/root/BINARY/ZPU/TIMERS/POWERUPSSTART
@onready var highscore = $/root/BINARY/MISC/HIGHSCORE  
@onready var intro = $/root/BINARY/MENUS/INTRO
@onready var game = $/root/BINARY/GAME
@onready var original = $/root/BINARY/GAME/ORIGINAL
@onready var expansive = $/root/BINARY/GAME/EXPANSIVE
@onready var infinity = $/root/BINARY/GAME/INFINITY
@onready var characters = $/root/BINARY/GAME/CHARACTERS


var timeout_count = 0
var dots_counted = false

func start_zpu():
	gameboard.connect("last_dot_eaten", Callable(self, "_on_last_dot_eaten"))
	soundbank.connect("start_sound_finished", Callable(self, "_on_start_sound_finished"))
	levelendtimer.connect("timeout", Callable(self, "_on_levelend_timer_timeout"))
	resetdotstimer.connect("timeout", Callable(self, "_on_resetdots_timer_timeout"))
	
func start_game():
	emit_signal("start_powerups")
	pacman.pac_start_pos()
	pacman.set_freeze(true)
	blinky.set_freeze(true)
	pinky.set_freeze(true)
	inky.set_freeze(true)
	clyde.set_freeze(true)
	highscore.visible = false
	
	gameboard.visible = true
	pacman.visible = true
	blinky.visible = true
	pinky.visible = true
	inky.visible = true
	clyde.visible = true
	if not dots_counted:
		gameboard.count_dots()
		dots_counted = true  # Set the flag to true after counting dots
	soundbank.play("START")
	gamestate.set_state(States.INITIAL)
	
			
func _on_start_sound_finished():
	print("play siren")
	soundbank.play_siren()
	pacman.set_freeze(false)
	blinky.set_freeze(false)
	pinky.set_freeze(false)
	inky.set_freeze(false)
	clyde.set_freeze(false)
	

func _on_last_dot_eaten():
	
	pacman.set_freeze(true)
	blinky.visible = false
	pinky.visible = false
	inky.visible = false
	clyde.visible = false
	gamestate.set_state(States.PAUSE)
	levelend.visible = true
	levelendtimer.start()
	scoremachine.add_level()
	pacman.visible = false
	powerups.remove_powerups()
		
func _on_resetdots_timer_timeout():
	start_game()
	resetdotstimer.stop()

func _on_levelend_timer_timeout():
	if timeout_count < 6:
		levelend.visible = not levelend.visible  # Toggle visibility
		timeout_count += 1
		levelendtimer.start()  # Restart the timer for the next blink
	else:
		levelendtimer.stop()
		levelend.visible = false
		timeout_count = 0
		gameboard.reset_dots()
		resetdotstimer.start()
		powerups.remove_powerups()
		
func handle_game_over():
	scoremachine.transfer_score()
	powerups.remove_powerups()
	loading.hide_characters()
	gameboard.reset_dots()
	scoremachine.reset_lives()
	scoremachine.reset_score()
	scoremachine.reset_level_display()
	end_screen()
	#loading.restart_game_loop()
	#startmenu.restart()
	
func end_screen():
	highscore.show_self() 
	
	levelendtimer.stop()
	resetdotstimer.stop()
	powerupsstart.stop()
	intro.visible = false
	gamestate.set_state(States.PAUSE)
	
	
