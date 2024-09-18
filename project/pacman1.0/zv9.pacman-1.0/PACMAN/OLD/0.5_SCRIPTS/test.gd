extends Node

signal all_nodes_initialized

var nodes_to_initialize = []
var initialized_nodes = []

func _ready():
	nodes_to_initialize = [
		$"/root/BINARY", $"/root/BINARY/ZPU", $"/root/BINARY/GAME_STATE", $"/root/BINARY/SOUNDBANK",
		$"/root/BINARY/START_MENU/BUTTON", $"/root/BINARY/SCORE_MACHINE", $"/root/BINARY/START_MENU",
		$"/root/BINARY/START_MENU/LOADING_SCREEN", $"/root/BINARY/ORIGINAL/MAP/GAME_BOARD",
		$"/root/BINARY/ORIGINAL/MAP/NAV_REG", $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY",
		$"/root/BINARY/ORIGINAL/CHARACTERS/PINKY", $"/root/BINARY/ORIGINAL/CHARACTERS/INKY",
		$"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE", $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
	]
	for node in nodes_to_initialize:
		node.connect("ready", self, "_on_node_ready")
	print("Initialization Manager ready")

func _on_node_ready(node):
	initialized_nodes.append(node)
	print("Node ready: ", node.name)
	if len(initialized_nodes) == len(nodes_to_initialize):
		emit_signal("all_nodes_initialized")
		print("All nodes initialized")
