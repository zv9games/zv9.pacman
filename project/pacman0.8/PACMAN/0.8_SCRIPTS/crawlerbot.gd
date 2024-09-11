extends CharacterBody2D

signal online

@onready var gameboard = $/root/BINARY/LEVELS/ORIGINAL/MAP/GAMEBOARD
@onready var binary = $/root/BINARY
@onready var debug_layer = $/root/BINARY/LEVELS/ORIGINAL/MAP/DEBUG_LAYER  # Add a CanvasLayer for debugging

var total_tiles = 0  # Variable to count total tiles
var walkable_tiles = []  # List to store walkable tile positions
var visited_tiles = {}  # Dictionary to track visited tiles
const WALKABLE_ATLAS_COORDS = [Vector2(8, 10), Vector2(7, 8), Vector2(8, 8)]  # Define your walkable atlas coordinates

var speed = 100  # Movement speed
var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]  # Possible movement directions

# Define the boundaries
const MIN_X = 3
const MAX_X = 29
const MIN_Y = 3
const MAX_Y = 28

# Define the tile size (adjust if different)
const TILE_SIZE = 16

func _ready():
	initialize_timer()
	connect_signals()

func initialize_timer():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()

func connect_signals():
	binary.connect("all_nodes_initialized", Callable(self, "_on_all_nodes_initialized"))

func _emit_online_signal():
	emit_signal("online", self.name)
	
func _on_all_nodes_initialized():
	count_tiles()
	start_crawlerbot(Vector2(16, 20))  # Start position of the crawlerbot

func count_tiles():
	var used_rect = gameboard.get_used_rect()
	print("Used rect: ", used_rect)
	for x in range(used_rect.size.x):
		for y in range(used_rect.size.y):
			total_tiles += 1
	print("Total tiles counted: ", total_tiles)

func start_crawlerbot(start_position):
	position = start_position
	visited_tiles.clear()
	walkable_tiles.clear()
	discover_walkable_tiles(start_position)

func discover_walkable_tiles(start_position):
	var queue = [start_position]
	while queue.size() > 0:
		var current_position = queue.pop_front()
		if current_position in visited_tiles:
			continue
		visited_tiles[current_position] = true
		if is_within_boundaries(current_position):
			var atlas_coords = gameboard.get_atlas_coordinates(Vector2i(current_position.x, current_position.y))
			if atlas_coords and is_walkable(Vector2(atlas_coords)):
				walkable_tiles.append(current_position)
				for direction in directions:
					var neighbor = current_position + direction
					if neighbor not in visited_tiles:
						queue.append(neighbor)
	print("Total walkable tiles found: ", walkable_tiles.size())
	print("Walkable tile positions: ", walkable_tiles)
	highlight_walkable_tiles()

func is_walkable(atlas_coords):
	for walkable_coord in WALKABLE_ATLAS_COORDS:
		if atlas_coords == walkable_coord:
			return true
	return false

func is_within_boundaries(position):
	return position.x >= MIN_X and position.x <= MAX_X and position.y >= MIN_Y and position.y <= MAX_Y

func highlight_walkable_tiles():
	if debug_layer:
		for tile in walkable_tiles:
			var marker = ColorRect.new()
			marker.color = Color(0, 1, 0, 0.5)  # Semi-transparent green
			marker.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)  # Set the size to match the tile size
			var local_position = gameboard.map_to_local(tile)  # Convert tilemap coordinates to local coordinates
			marker.position = local_position  # Set the marker position
			debug_layer.add_child(marker)
			print("Tile: ", tile, " Local Position: ", local_position)  # Debug print
	else:
		print("Debug layer not found!")








func _physics_process(delta):
	# Movement logic can be added here if needed
	pass
