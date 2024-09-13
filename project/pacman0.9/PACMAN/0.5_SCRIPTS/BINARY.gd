extends Node2D

var initialization_status: Dictionary = {}
var initialized_nodes: Array = []  # Track initialized nodes

signal scripts_ready
signal node_initialized
signal all_nodes_initialized  # New signal to indicate all nodes are initialized

var is_paused = false
var game_started: bool = false
var current_state

@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var nav_reg = $"/root/BINARY/ORIGINAL/MAP/NAV_REG"
@onready var gamestate = $"/root/BINARY/GAME_STATE"
@onready var loading_screen = $"/root/BINARY/START_MENU/LOADING_SCREEN"
@onready var tilemap = $"/root/BINARY/ORIGINAL/MAP/TILEMAP"
@onready var start_menu = $"/root/BINARY/START_MENU"
@onready var score_machine = $"/root/BINARY/SCORE_MACHINE"
@onready var endgame = $"/root/BINARY/END_GAME"

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

var start_time

func _ready():
	print("ready", self)
	loading_screen.visible = true
	gamestate.connect("state_changed", Callable(self, "_on_state_changed"))
	connect("node_initialized", Callable(self, "initialize_next_node"))
	call_deferred("initialize_next_node")
	start_time = Time.get_ticks_msec()

func initialize_next_node():
	var nodes_to_initialize = [ loading_screen, tilemap, pacman, blinky, pinky, inky, clyde, start_menu, gamestate, score_machine, endgame ]
	for node in nodes_to_initialize:
		if node not in initialized_nodes:
			initialize_node(node)
			return  # Exit the function to wait for the next signal
	print("All nodes initialized")
	emit_signal("all_nodes_initialized")  # Emit signal when all nodes are initialized
	var end_time = Time.get_ticks_msec()
	print("Initialization time:", end_time - start_time, "ms")
	print("Press Start")

func initialize_node(node):
	if node.has_method("initialize"):
		node.initialize()
	else:
		print("Node", node.name, "does not have an initialize method")
	initialized_nodes.append(node)
	emit_signal("node_initialized")

func set_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	gamestate.set_state(new_state)

func start_game():
	if not nav_reg:
		print("Navigation registry is not ready. Delaying game start.")
		return
	print("All scripts are initialized. Starting the game...")
	game_started = true
	set_state(States.INITIAL)

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tilemap_pos = tilemap.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = tilemap.map_to_local(tile_pos)
	var global_pos = tilemap.to_global(local_pos)
	return global_pos
