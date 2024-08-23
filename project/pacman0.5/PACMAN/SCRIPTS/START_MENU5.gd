extends Control

signal online
signal start_button_pressed
signal begin_game

func _ready():

	# Create a timer with a 0.5-second delay
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	level_end.visible = false
	await get_tree().process_frame  # Waits for one frame
	button.connect("pressed", Callable(self, "_on_button_up"))
	gamestate.connect("state_changed", Callable(self, "_on_state_changed"))
	startup()
	
	
func _emit_online_signal():
	emit_signal("online", self.name)

#BREAK

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

@onready var binary = $"/root/BINARY"
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var gamestate = $"/root/BINARY/GAMESTATE"
@onready var ZPU = $"/root/BINARY/ZPU"
@onready var score_machine = $"/root/BINARY/SCORE_MACHINE"
@onready var level_end = $"/root/BINARY/ORIGINAL/MAP/LEVEL_END"
@onready var button = $"/root/BINARY/START_MENU/BUTTON"
@onready var loading = $/root/BINARY/START_MENU/LOADING_SCREEN
@onready var START = $"/root/BINARY/SOUNDBANK/START"

var current_state

	
func startup():
	gamestate.set_state(States.PRE_GAME)  
	pacman.visible = false  
	blinky.visible = false  
	pinky.visible = false 
	inky.visible = false
	clyde.visible = false
	gameboard.visible = false 
	
func _on_button_up():
	self.hide()  
	pacman.visible = true  
	blinky.visible = true  
	pinky.visible = true  
	inky.visible = true  
	clyde.visible = true  
	gameboard.visible = true
	loading.stop_loading_screen()
	emit_signal("start_button_pressed")
	emit_signal("begin_game")



func set_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	gamestate.set_state(new_state)
		
	

