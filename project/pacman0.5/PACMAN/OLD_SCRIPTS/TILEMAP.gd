extends TileMap

signal dot_eaten
signal big_dot_eaten
signal initialized

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var gamestate = $"/root/BINARY/GAME_STATE"
@onready var score_manager = $"/root/BINARY/SCORE_MACHINE"

var big_dot_positions = []
var big_dots_eaten = {}
var small_dot_positions = []
var small_dots_eaten = {}
var current_state
var original_tiles = {}  # Dictionary to store the original state of the tiles
var blocked_positions = [ Vector2i(1, 16), Vector2i(31, 16) ]
var tile_replace = { Vector2i(7, 8): true, Vector2i(8, 8): true }
var tile_toolbox = { Vector2i(7, 8): Vector2i(8, 10), Vector2i(8, 8): Vector2i(8, 10) }
var teleport_cooldown = false  # Cooldown flag for teleportation

func _ready():
	print("ready", self)
	self.visible = false
	initialize()
	connect("dot_eaten", Callable(self, "_on_dot_eaten"))
	connect("big_dot_eaten", Callable(self, "_on_big_dot_eaten"))
	
func initialize():
	if not is_inside_tree():
		push_error("TileMap is not in the scene tree.")
		return
	emit_signal("initialized", self.name)
	reset_dots()

func remove_dots():
	# Clear big dots
	for pos in big_dot_positions:
		set_cell(0, pos, 0, Vector2i(0, 0))  # Replace with an empty tile or appropriate value
	big_dot_positions.clear()
	big_dots_eaten.clear()
	
	# Clear small dots
	for pos in small_dot_positions:
		set_cell(0, pos, 0, Vector2i(0, 0))  # Replace with an empty tile or appropriate value
	small_dot_positions.clear()
	small_dots_eaten.clear()
	
	# Reinitialize dots for the next level
	reset_dots()
	
func reset_dots():
	# Reset original tiles
	for tile_pos in original_tiles.keys():
		set_cell(0, tile_pos, 0, original_tiles[tile_pos])
	
	# Reset big dots
	big_dot_positions.clear()
	for x in range(get_used_rect().size.x):
		for y in range(get_used_rect().size.y):
			var tile_pos = Vector2i(x, y)
			var atlas_coords = get_atlas_coordinates(tile_pos)
			if atlas_coords == Vector2i(8, 8):  # Big dot atlas coordinates
				big_dot_positions.append(tile_pos)
				big_dots_eaten[tile_pos] = false
				set_cell(0, tile_pos, 0, atlas_coords)
	
	# Scan for small dot positions
	small_dot_positions.clear()
	for x in range(get_used_rect().size.x):
		for y in range(get_used_rect().size.y):
			var tile_pos = Vector2i(x, y)
			var atlas_coords = get_atlas_coordinates(tile_pos)
			if atlas_coords == Vector2i(7, 8):  # Small dot atlas coordinates
				small_dot_positions.append(tile_pos)
				small_dots_eaten[tile_pos] = false
				set_cell(0, tile_pos, 0, atlas_coords)

func check_tile():
	if not self:
		return

	var local_pos = to_local(pacman.global_position)
	var tile_pos = local_to_map(local_pos)
	var tile_pos_i = Vector2i(floor(tile_pos.x), floor(tile_pos.y))
	var atlas_coords = get_atlas_coordinates(tile_pos_i)

	# Check if the position is blocked
	if blocked_positions.has(tile_pos_i):
		return  # Prevent movement through this tile

	# Teleport Pacman without cooldown
	if tile_pos_i == Vector2i(2, 16):
		pacman.global_position = map_to_local(Vector2(29, 16))
	elif tile_pos_i == Vector2i(30, 16):
		pacman.global_position = map_to_local(Vector2(3, 16))

	if tile_replace.has(atlas_coords):
		if tile_toolbox.has(atlas_coords):
			var new_atlas_coords = tile_toolbox[atlas_coords]
			original_tiles[tile_pos_i] = atlas_coords  # Store the original state
			set_cell(0, tile_pos_i, 0, new_atlas_coords)
			score_manager.add_points(10)  # Directly update the score
			emit_signal("dot_eaten")  # Emit signal when a dot is eaten

	if big_dot_positions.has(tile_pos_i) and not big_dots_eaten[tile_pos_i]:
		big_dots_eaten[tile_pos_i] = true
		set_cell(0, tile_pos_i, 0, Vector2i(8, 10))  # Assuming (8, 10) is the atlas coordinates for an empty tile
		score_manager.add_points(50)  # Directly update the score
		gamestate.set_state(States.FRIGHTENED)  # Directly change the game state
		emit_signal("big_dot_eaten")  # Emit signal when a big dot is eaten


func set_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	gamestate.set_state(new_state)

func get_atlas_coordinates(tile_pos: Vector2i) -> Vector2i:
	return self.get_cell_atlas_coords(0, tile_pos)
	
func is_tile_blocked(tile_pos: Vector2i) -> bool:
	return blocked_positions.has(tile_pos)

