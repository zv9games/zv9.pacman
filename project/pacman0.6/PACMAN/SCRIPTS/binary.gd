extends Node

signal online
signal all_nodes_initialized

@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var nav_reg = $"/root/BINARY/ORIGINAL/MAP/NAV_REG"
@onready var gamestate = $"/root/BINARY/GAMESTATE"
@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var startmenu = $"/root/BINARY/STARTMENU"
@onready var scoremachine = $"/root/BINARY/SCOREMACHINE"
@onready var ZPU = $"/root/BINARY/ZPU"
@onready var soundbank = $"/root/BINARY/SOUNDBANK"
@onready var loading = $"/root/BINARY/LOADING"

var nodes_to_initialize = [
	"/root/BINARY/LOADING", 
	"/root/BINARY/GAMESTATE", 
	"/root/BINARY/SOUNDBANK", 
	"/root/BINARY/SCOREMACHINE",
	"/root/BINARY/STARTMENU", 
	"/root/BINARY/ORIGINAL/MAP/GAMEBOARD",
	"/root/BINARY/ORIGINAL/MAP/NAV_REG", 
	"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY",
	"/root/BINARY/ORIGINAL/CHARACTERS/PINKY", 
	"/root/BINARY/ORIGINAL/CHARACTERS/INKY",
	"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE", 
	"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN",
	"/root/BINARY/ZPU", 
	"/root/BINARY"
]

var initialized_nodes = {}
var nodes_connected = false

func _ready():
	#print("binary ready")
	call_deferred("_connect_signals")

func _connect_signals():
	for node_path in nodes_to_initialize:
		var node = get_node(node_path)
		if node:
			#print("Connecting signal for: ", node_path)
			node.connect("online", Callable(self, "_on_node_online"))
		else:
			print("Node not found: ", node_path)
	nodes_connected = true
	emit_signal("online", self.name)

func _on_node_online(node_name):
	#print("Node online: ", node_name)
	initialized_nodes[node_name] = true
	#print("Initialized nodes: ", initialized_nodes.size(), "/", nodes_to_initialize.size())
	if initialized_nodes.size() == nodes_to_initialize.size():
		print("All nodes initialized")
		emit_signal("all_nodes_initialized")
