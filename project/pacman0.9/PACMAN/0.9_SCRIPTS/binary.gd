extends Node

signal online
signal all_nodes_initialized

@onready var nodes_to_initialize = [
	"/root/BINARY/GAMESTATE", 
	"/root/BINARY/SOUNDBANK", 
	"/root/BINARY/SCOREMACHINE",
	"/root/BINARY/STARTMENU", 
	"/root/BINARY/MODES/ORIGINAL/ORIGINALBOARD",
	"/root/BINARY/MODES/ORIGINAL/NAV_REG", 
	"/root/BINARY/MODES/ORIGINAL/BLINKY",
	"/root/BINARY/MODES/ORIGINAL/PINKY", 
	"/root/BINARY/MODES/ORIGINAL/INKY",
	"/root/BINARY/MODES/ORIGINAL/CLYDE", 
	"/root/BINARY/MODES/ORIGINAL/PACMAN",
	"/root/BINARY/ZPU", 
	"/root/BINARY/STARTMENU/LOADING",
	"/root/BINARY"
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
