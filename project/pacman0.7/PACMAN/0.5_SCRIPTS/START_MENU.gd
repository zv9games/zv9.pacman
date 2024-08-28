extends Control

signal initialized
signal start_button_pressed

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

@onready var binary = $"/root/BINARY"
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var tilemap = $"/root/BINARY/ORIGINAL/MAP/TILEMAP"
@onready var gamestate = $"/root/BINARY/GAME_STATE"
@onready var end_game = $"/root/BINARY/END_GAME"
@onready var score_machine = $"/root/BINARY/SCORE_MACHINE"
@onready var level_end = $"/root/BINARY/ORIGINAL/MAP/LEVEL_END"
@onready var button = $"/root/BINARY/START_MENU/BUTTON"
@onready var loading = $/root/BINARY/START_MENU/LOADING_SCREEN

var current_state

func _ready():
	print("ready", self)
	initialize()
	level_end.visible = false
	await get_tree().process_frame  # Waits for one frame
	button.connect("pressed", Callable(self, "_on_button_up"))
	gamestate.connect("state_changed", Callable(self, "_on_state_changed"))
	gamestate.set_state(States.PRE_GAME)
	loading.connect("loading_ready", Callable(self, "on_loading_ready"))

func initialize():
	emit_signal("initialized", self.name)
	startup()
	
func startup():
	pacman.visible = false  
	blinky.visible = false  
	pinky.visible = false 
	inky.visible = false
	clyde.visible = false
	tilemap.visible = false 
	
func on_loading_ready():
	loading.start_loading_screen()
	print("start_loading_screen")
		
func _on_button_up():
	self.hide()  
	pacman.visible = true  
	blinky.visible = true  
	pinky.visible = true  
	inky.visible = true  
	clyde.visible = true  
	tilemap.visible = true
	binary.start_game()  
	loading.stop_loading_screen()
	emit_signal("start_button_pressed")  

func set_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	gamestate.set_state(new_state)
		
	
