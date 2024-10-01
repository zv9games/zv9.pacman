extends Node

signal online
signal all_nodes_initialized

@onready var nodes_to_initialize = [
	"/root/BINARY",
	"/root/BINARY/MENUS/STARTMENU",
	"/root/BINARY/ZPU", 
	"/root/BINARY/ZPU/GAMESTATE",
	"/root/BINARY/ZPU/SCOREMACHINE",
	"/root/BINARY/ZPU/SOUNDBANK", 
	"/root/BINARY/GAME/CHARACTERS",
	"/root/BINARY/GAME/POWERUPS",
	"/root/BINARY/GAME/ORIGINAL",
	"/root/BINARY/GAME/EXPANSIVE",
	"/root/BINARY/GAME/INFINITY",
	"/root/BINARY/Camera2D",
	"/root/BINARY/GAME/ORIGINAL/TILEMAPLAYER",
	"/root/BINARY/MENUS/LOADING/LO_PACMAN",
	"/root/BINARY/MENUS/LOADING/LO_BLINKY",
	"/root/BINARY/MENUS/LOADING/LO_PINKY",
	"/root/BINARY/MENUS/LOADING/LO_INKY",
	"/root/BINARY/MENUS/LOADING/LO_CLYDE",
	"/root/BINARY/MENUS/INTRO",
	"/root/BINARY/MISC/HIGHSCORE"
]

var initialized_nodes = {}
var nodes_connected = false

func _ready():
	
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	call_deferred("_initialize_nodes")

func _emit_online_signal():
	emit_signal("online", self.name)

func _initialize_nodes():
	print("Initializing nodes")
	for path in nodes_to_initialize:
		var node = get_node(path)
		if node:
			node.connect("online", Callable(self, "_on_node_online"))
		else:
			print("Node not found: " + path)

func _on_node_online(node_name):
	print("Node online: " + node_name)
	initialized_nodes[node_name] = true
	if len(initialized_nodes) == len(nodes_to_initialize):
		print("All nodes initialized")
		emit_signal("all_nodes_initialized")
