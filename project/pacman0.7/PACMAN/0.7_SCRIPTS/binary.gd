extends Node

signal online
signal all_nodes_initialized

@onready var nodes_to_initialize = [
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
	"/root/BINARY/OPEN/LOADING",
	"/root/BINARY"
]

var initialized_nodes = {}
var nodes_connected = false

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.2  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	call_deferred("_initialize_nodes")

func _emit_online_signal():
	emit_signal("online", self.name)
	

func _initialize_nodes():
	for node_path in nodes_to_initialize:
		var node = get_node(node_path)
		if node:
			call_deferred("_connect_node_signal", node)
		else:
			print("Node not found: ", node_path)
	nodes_connected = true
	emit_signal("online", self.name)
	

func _connect_node_signal(node):
	if node.has_signal("online"):
		var timer = Timer.new()
		timer.wait_time = 0.1  # Adjust the delay as needed
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_deferred_connect").bind(node))
		add_child(timer)
		timer.start()
	else:
		print("Node does not have 'online' signal: ", node.name)

func _deferred_connect(node):
	node.connect("online", Callable(self, "_on_node_online"))

func _on_node_online(node_name):
	initialized_nodes[node_name] = true
	#print("Node initialized: ", node_name)
	#print("Initialized nodes: ", initialized_nodes.size(), "/", nodes_to_initialize.size())
	if initialized_nodes.size() == nodes_to_initialize.size():
		print("All nodes initialized")
		emit_signal("all_nodes_initialized")
	else:
		#print("Pending nodes: ", _get_pending_nodes())
		pass
		
func _get_pending_nodes():
	var pending_nodes = []
	for node_path in nodes_to_initialize:
		if !initialized_nodes.has(node_path):
			pending_nodes.append(node_path)
	return pending_nodes
