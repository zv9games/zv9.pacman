extends Node

signal online

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING, PAUSE }

@onready var startmenu = $/root/BINARY/GAME/STARTMENU
@onready var loading = $/root/BINARY/GAME/LOADING
@onready var scoremachine = $/root/BINARY/GAME/SCOREMACHINE
@onready var soundbank = $/root/BINARY/GAME/SOUNDBANK
@onready var gamestate = $/root/BINARY/GAME/GAMESTATE
@onready var gameboard = $/root/BINARY/LEVELS/ORIGINAL/MAP/GAMEBOARD
@onready var pacman = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/PACMAN
@onready var blinky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/CLYDE
@onready var levelend = $/root/BINARY/LEVELS/ORIGINAL/MAP/LEVELEND
@onready var levelendtimer = $/root/BINARY/GAME/ZPU/LevelEndTimer 

var timeout_count = 0

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
	soundbank.play("START")
	gamestate.set_state(States.INITIAL)
	gameboard.count_dots()
	
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
	gamestate.set_state(States.PAUSE)
	levelend.visible = true
	levelendtimer.start()
	scoremachine.add_level()

func _on_levelend_timer_timeout():
	if timeout_count < 6:
		levelend.visible = not levelend.visible  # Toggle visibility
		timeout_count += 1
		levelendtimer.start()  # Restart the timer for the next blink
	else:
		levelendtimer.stop()
		levelend.visible = false
		timeout_count = 0
		
		start_game()
		
func handle_game_over():
	gameboard.reset_dots()
	scoremachine.reset_lives()
	scoremachine.reset_score()
	loading.restart_game_loop()
	startmenu.restart()
	
