extends TileMapLayer

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING, PAUSE }

signal online
signal dot_eaten
signal big_dot_eaten
signal last_dot_eaten

@onready var zpu = $/root/BINARY/GAME/ZPU
@onready var scoremachine = $/root/BINARY/GAME/SCOREMACHINE
@onready var soundbank = $/root/BINARY/GAME/SOUNDBANK
@onready var gamestate = $/root/BINARY/GAME/GAMESTATE
@onready var frighttimer = $/root/BINARY/GAME/SOUNDBANK/FRIGHTTIMER
@onready var sirentimer = $/root/BINARY/GAME/SOUNDBANK/SIRENTIMER
@onready var pacman = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/PACMAN



var blocked_positions = [Vector2i(1, 16), Vector2i(31, 16)]
var tile_replace = {Vector2i(7, 8): true, Vector2i(8, 8): true}
var tile_toolbox = {Vector2i(7, 8): Vector2i(8, 10), Vector2i(8, 8): Vector2i(8, 10)}
var teleport_cooldown = false  # Cooldown flag for teleportation
var big_dot_positions = []
var big_dots_eaten = {}
var small_dot_positions = []
var small_dots_eaten = {}
var current_state
var original_tiles = {}
var eat_sound_toggle = true

func _ready():
	self.visible = false
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	
	connect("big_dot_eaten", Callable(self, "_on_big_dot_eaten"))
	connect("dot_eaten", Callable(self, "_on_dot_eaten"))

func _emit_online_signal():
	emit_signal("online", self.name)
	
func is_tile_blocked(tile_pos: Vector2i) -> bool:
	return blocked_positions.has(tile_pos)

func count_dots():
	big_dot_positions.clear()
	small_dot_positions.clear()
	big_dots_eaten.clear()
	small_dots_eaten.clear()
	original_tiles.clear()

	for x in range(get_used_rect().size.x):
		for y in range(get_used_rect().size.y):
			var tile_pos = Vector2i(x, y)
			var atlas_coords = get_atlas_coordinates(tile_pos)
			if atlas_coords == Vector2i(7, 8):  # Assuming (7, 8) is a small dot
				small_dot_positions.append(tile_pos)
				small_dots_eaten[tile_pos] = false
				original_tiles[tile_pos] = atlas_coords
			elif atlas_coords == Vector2i(8, 8):  # Assuming (8, 8) is a big dot
				big_dot_positions.append(tile_pos)
				big_dots_eaten[tile_pos] = false
				original_tiles[tile_pos] = atlas_coords

func reset_dots():
	for pos in small_dot_positions:
		if small_dots_eaten[pos]:
			set_cell(pos, 0, original_tiles[pos])
			small_dots_eaten[pos] = false

	for pos in big_dot_positions:
		if big_dots_eaten[pos]:
			set_cell(pos, 0, original_tiles[pos])
			big_dots_eaten[pos] = false

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
			set_cell(tile_pos_i, 0, new_atlas_coords)
			scoremachine.add_points(10)  # Directly update the score
			emit_signal("dot_eaten")  # Emit signal when a dot is eaten
			small_dots_eaten[tile_pos_i] = true
			check_last_dot_eaten()

	if big_dot_positions.has(tile_pos_i) and not big_dots_eaten[tile_pos_i]:
		big_dots_eaten[tile_pos_i] = true
		set_cell(tile_pos_i, 0, Vector2i(8, 10))  # Assuming (8, 10) is the atlas coordinates for an empty tile
		scoremachine.add_points(100)
		emit_signal("big_dot_eaten")  # Emit signal when a big dot is eaten
		check_last_dot_eaten()

func check_last_dot_eaten():
	for pos in small_dot_positions:
		if not small_dots_eaten[pos]:
			return
	for pos in big_dot_positions:
		if not big_dots_eaten[pos]:
			return
	print("last dot eaten")
	emit_signal("last_dot_eaten")  # Emit signal when the last dot is eaten
	
func get_atlas_coordinates(tile_pos: Vector2i) -> Vector2i:
	return self.get_cell_atlas_coords(tile_pos)

func get_dots_left() -> int:
	var total_dots = small_dot_positions.size() + big_dot_positions.size()
	var eaten_dots = 0
	for pos in small_dot_positions:
		if small_dots_eaten[pos]:
			eaten_dots += 1
	for pos in big_dot_positions:
		if big_dots_eaten[pos]:
			eaten_dots += 1
	var dots_left = total_dots - eaten_dots
	return dots_left

func _on_siren_timer_timeout():
	play_siren()

func play_siren():
	sirentimer.start()
	var dots_left = get_dots_left()
	if dots_left <= 30:
		soundbank.play("SIREN4")
	elif dots_left <= 100:
		soundbank.play("SIREN3")
	elif dots_left <= 170:
		soundbank.play("SIREN2")
	elif dots_left <= 255:
		soundbank.play("SIREN1")



func _on_big_dot_eaten():
	gamestate.set_state(States.FRIGHTENED)
	gamestate.restart_frightened_timer()
	frighttimer.start()
	

func _on_dot_eaten():
	if eat_sound_toggle:
		soundbank.play("EAT1")
	else:
		soundbank.play("EAT2")
	eat_sound_toggle = !eat_sound_toggle  # Toggle the flag
