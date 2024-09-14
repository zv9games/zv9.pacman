extends Node

signal online

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING, PAUSE }

@onready var startmenu = $/root/BINARY/STARTMENU
@onready var loading = $/root/BINARY/STARTMENU/LOADING
@onready var scoremachine = $/root/BINARY/SCOREMACHINE
@onready var soundbank = $/root/BINARY/SOUNDBANK
@onready var gamestate = $/root/BINARY/GAMESTATE
@onready var gameboard = $/root/BINARY/MODES/ORIGINAL/ORIGINALBOARD
@onready var pacman = $/root/BINARY/MODES/ORIGINAL/PACMAN
@onready var blinky = $/root/BINARY/MODES/ORIGINAL/BLINKY
@onready var pinky = $/root/BINARY/MODES/ORIGINAL/PINKY
@onready var inky = $/root/BINARY/MODES/ORIGINAL/INKY
@onready var clyde = $/root/BINARY/MODES/ORIGINAL/CLYDE
@onready var levelend = $/root/BINARY/MODES/ORIGINAL/LEVELEND
@onready var levelendtimer = $/root/BINARY/ZPU/LevelEndTimer
@onready var resetdotstimer = $/root/BINARY/ZPU/ResetDotsTimer
@onready var powerups = $/root/BINARY/MODES/ORIGINAL/POWERUPS
@onready var powerupstimer = $/root/BINARY/ZPU/PowerUpsTimer 

var timeout_count = 0
var dots_counted = false

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	gameboard.connect("last_dot_eaten", Callable(self, "_on_last_dot_eaten"))
	soundbank.connect("start_sound_finished", Callable(self, "_on_start_sound_finished"))
	levelendtimer.connect("timeout", Callable(self, "_on_levelend_timer_timeout"))
	resetdotstimer.connect("timeout", Callable(self, "_on_resetdots_timer_timeout"))
	powerupstimer.connect("timeout", Callable(self, "_on_powerups_timer_timeout"))
	

func _emit_online_signal():
	emit_signal("online", self.name)
	

func start_game():
	
	pacman.pac_start_pos()
	pacman.set_freeze(true)
	blinky.set_freeze(true)
	pinky.set_freeze(true)
	inky.set_freeze(true)
	clyde.set_freeze(true)
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
	start_powerups()
	
	
	
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
	powerups.visible = false
	powerups._disable_collision_shape()
	
	
	
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
		
		
		
		
func handle_game_over():
	powerupstimer.stop()
	loading.hide_characters()
	gameboard.reset_dots()
	scoremachine.reset_lives()
	scoremachine.reset_score()
	scoremachine.reset_level_display()
	loading.restart_game_loop()
	startmenu.restart()
	
func start_powerups():
	powerupstimer.start()
	
	
func _on_powerups_timer_timeout():
	powerupstimer.stop()
	start_powerups()
	powerups.trigger_powerup()
	powerups.visible = true
