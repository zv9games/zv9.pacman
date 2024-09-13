extends Control

signal online
signal start_button_pressed

@onready var button = $"/root/BINARY/STARTMENU/BUTTON"

func _ready():
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	levelend.visible = false
	await get_tree().process_frame  # Waits for one frame
	button.connect("pressed", Callable(self, "_on_button_up"))
	
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
@onready var scoremachine = $"/root/BINARY/SCOREMACHINE"
@onready var levelend = $"/root/BINARY/ORIGINAL/MAP/LEVELEND"
@onready var loading = $/root/BINARY/LOADING

var current_state
	
func _on_button_up():
	emit_signal("start_button_pressed")
	
	
func set_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	gamestate.set_state(new_state)
		
	
