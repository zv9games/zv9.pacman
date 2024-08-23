extends Node

signal online
signal all_nodes_initialized
signal begin_game

@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var nav_reg = $"/root/BINARY/ORIGINAL/MAP/NAV_REG"
@onready var gamestate = $"/root/BINARY/GAMESTATE"
@onready var loadingscreen = $"/root/BINARY/STARTMENU/LOADINGSCREEN"
@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var startmenu = $"/root/BINARY/STARTMENU"
@onready var scoremachine = $"/root/BINARY/SCOREMACHINE"
@onready var ZPU = $"/root/BINARY/ZPU"
@onready var soundbank = $"/root/BINARY/SOUNDBANK"
@onready var button = $"/root/BINARY/STARTMENU/BUTTON"

var nodes_to_initialize = [
	"/root/BINARY", "/root/BINARY/GAMESTATE",
	"/root/BINARY/SOUNDBANK", "/root/BINARY/SCOREMACHINE", "/root/BINARY/STARTMENU",
	"/root/BINARY/STARTMENU/LOADINGSCREEN", "/root/BINARY/ORIGINAL/MAP/GAMEBOARD",
	"/root/BINARY/ORIGINAL/MAP/NAV_REG", "/root/BINARY/ORIGINAL/CHARACTERS/BLINKY",
	"/root/BINARY/ORIGINAL/CHARACTERS/PINKY", "/root/BINARY/ORIGINAL/CHARACTERS/INKY",
	"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE", "/root/BINARY/ORIGINAL/CHARACTERS/PACMAN", 
	"/root/BINARY/ZPU", 
]

var initialized_nodes = {}
var nodes_connected = false

func _ready():
	call_deferred("_connect_signals")

func _connect_signals():
	for node_path in nodes_to_initialize:
		var node = get_node(node_path)
		if node:
			node.connect("online", Callable(self, "_on_node_online"))
	nodes_connected = true
	emit_signal("online", self.name)
	startmenu.connect("begin_game", Callable(self, "_on_begin_game"))

func _on_node_online(node_name):
	initialized_nodes[node_name] = true
	if initialized_nodes.size() == nodes_to_initialize.size():
		print("All nodes initialized")
		emit_signal("all_nodes_initialized")
#BREAK

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

var is_paused = false
var game_started: bool = false
var current_state

func set_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	gamestate.set_state(new_state)

func _on_begin_game():
	game_started = true
	
