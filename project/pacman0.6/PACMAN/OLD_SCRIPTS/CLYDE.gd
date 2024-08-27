extends CharacterBody2D

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }
enum FrightStates { NORMAL, CAUGHT }

signal initialized

const speed = 40
const frightened_speed = 30
const return_speed = 100  # Speed for returning to the shed
const DIRECTION_THRESHOLD = 0.1  # Add a threshold for direction values

@onready var nav_agent = $NavigationAgent2D as NavigationAgent2D
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var tilemap = $"/root/BINARY/ORIGINAL/MAP/TILEMAP"
@onready var game_state = $"/root/BINARY/GAME_STATE"
@onready var animated_sprite = $AnimatedSprite2D  
@onready var score_machine = $/root/BINARY/SCORE_MACHINE
@onready var collision_area = $Area2D  
@onready var blinky = $/"root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var anisprite = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE/AnimatedSprite2D"

var is_frozen = false
var ghost_state = FrightStates.NORMAL
var dot_eaten_count = 0 
var current_state = null         
var scatter_index = 0
var clyde_data: Dictionary = { "home_corner_loop": [Vector2(9, 20), Vector2(9, 26), Vector2(7, 22), Vector2(3, 20)], }
var start_position = Vector2()
var score: int = 0
var last_state  # Variable to store the last state
var is_eaten = false  
var clyde_initial_target: Vector2
var clyde_initial_positions: Array = [Vector2(13, 18), Vector2(13, 15)]
var clyde_initial_index: int = 0
var is_initialized = false

func _ready():
	print("ready", self)
	self.visible = false
	initialize()
	tilemap.connect("dot_eaten", Callable(self, "_on_dot_eaten"))
	game_state.connect("state_changed", Callable(self, "_on_state_changed"))
	animated_sprite.play("idle")  
	start_position = global_position  
	collision_area.monitoring = true  # Ensure monitoring is enabled
	collision_area.monitorable = true  # Ensure the area can be monitored

func initialize():
	if is_initialized:
		return
	for key in clyde_data.keys():
		for i in range(clyde_data[key].size()):
			clyde_data[key][i] = tile_position_to_global_position(clyde_data[key][i])
	clyde_initial_target = tile_position_to_global_position(clyde_initial_positions[clyde_initial_index])
	emit_signal("initialized", self.name)# Perform initialization tasks here
	is_initialized = true

	move_clyde_initial()

func _on_state_changed(new_state):
	current_state = new_state
	match new_state:
		GameState.States.CHASE:
			chase_logic()
		GameState.States.SCATTER:
			scatter_logic()
		GameState.States.FRIGHTENED:
			frightened_normal_logic()
		GameState.States.INITIAL:
			initial_logic()
		GameState.States.PRE_GAME:
			pre_game_logic()
			
func _physics_process(delta):
	match current_state:
		GameState.States.CHASE:
			chase_physics(delta)
		GameState.States.SCATTER:
			scatter_physics(delta)
		GameState.States.FRIGHTENED:
			if ghost_state == FrightStates.NORMAL:
				frightened_normal_physics(delta)
			elif ghost_state == FrightStates.CAUGHT:
				frightened_caught_physics(delta)
		GameState.States.INITIAL:
			initial_physics(delta)
		GameState.States.PRE_GAME:
			pre_game_physics(delta)

func chase_logic():
	make_chase_path()
	
func scatter_logic():
	make_scatter_path()
	
func frightened_normal_logic():
	animated_sprite.play("frightened")

func initial_logic():
	self.visible = true
	global_position = start_position
	move_clyde_initial()

func pre_game_logic():
	self.visible = false

func chase_physics(delta):
	move_towards_target()

func scatter_physics(delta):
	move_towards_target()

func frightened_normal_physics(delta):
	move_away_from_pacman()

func frightened_caught_physics(delta):
	move_to_shed()

func initial_physics(delta):
	move_clyde_initial()

func pre_game_physics(delta):
	pass

func move_clyde_initial() -> void:
	var dir = (clyde_initial_target - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if global_position.distance_to(clyde_initial_target) < 1:
		clyde_initial_index = (clyde_initial_index + 1) % clyde_initial_positions.size()
		clyde_initial_target = tile_position_to_global_position(clyde_initial_positions[clyde_initial_index])
	animated_sprite.play("idle")  # Ensure idle animation is playing

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tilemap_pos = tilemap.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = tilemap.map_to_local(tile_pos)
	var global_pos = tilemap.to_global(local_pos)
	return global_pos

func update_animation(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		if direction.x > DIRECTION_THRESHOLD:
			animated_sprite.play("right")
		elif direction.x < -DIRECTION_THRESHOLD:
			animated_sprite.play("left")
	else:
		if direction.y > DIRECTION_THRESHOLD:
			animated_sprite.play("down")
		elif direction.y < -DIRECTION_THRESHOLD:
			animated_sprite.play("up")

func move_towards_target() -> void:
	var next_position = nav_agent.get_next_path_position()
	if next_position != Vector2.ZERO:
		var dir = (next_position - global_position).normalized()
		var new_position = global_position + dir * speed * get_process_delta_time()

		# Check if the new position is blocked
		var tile_pos = tilemap.local_to_map(new_position)
		var tile_pos_i = Vector2i(floor(tile_pos.x), floor(tile_pos.y))
		if tilemap.is_tile_blocked(tile_pos_i):
			return  # Prevent movement through this tile

		velocity = dir * speed
		move_and_slide()
		update_animation(dir)
		if global_position.distance_to(next_position) < 1:
			update_target_position()

func make_chase_path() -> void:
	var target_pos = pacman.global_position
	var pacman_direction = pacman.current_direction  # Use current_direction from Pac-Man's script
	var tile_size = tilemap.tile_set.tile_size
	var tile_center = Vector2(tile_size.x / 2, tile_size.y / 2)
	target_pos.x += pacman_direction.x * tile_size.x * 4
	target_pos.y += pacman_direction.y * tile_size.y * 4
	target_pos.x = floor(target_pos.x / tile_size.x) * tile_size.x + tile_center.x
	target_pos.y = floor(target_pos.y / tile_size.y) * tile_size.y + tile_center.y
	nav_agent.target_position = target_pos

func make_scatter_path() -> void:
	scatter_index = (scatter_index + 1) % clyde_data["home_corner_loop"].size()
	var target_pos = clyde_data["home_corner_loop"][scatter_index]
	var tile_size = tilemap.tile_set.tile_size
	var tile_center = Vector2(tile_size.x / 2, tile_size.y / 2)
	target_pos.x = floor(target_pos.x / tile_size.x) * tile_size.x + tile_center.x
	target_pos.y = floor(target_pos.y / tile_size.y) * tile_size.y + tile_center.y
	nav_agent.target_position = target_pos

func move_away_from_pacman() -> void:
	var dir = (global_position - pacman.global_position).normalized()
	var new_position = global_position + dir * frightened_speed * get_process_delta_time()

	# Check if the new position is blocked
	var tile_pos = tilemap.local_to_map(new_position)
	var tile_pos_i = Vector2i(floor(tile_pos.x), floor(tile_pos.y))
	if tilemap.is_tile_blocked(tile_pos_i):
		return  # Prevent movement through this tile

	velocity = dir * frightened_speed
	move_and_slide()
	animated_sprite.play("frightened")  # Ensure frightened animation is playing

func _on_area_2d_body_entered(body):
	if body.name == "PACMAN" and current_state == States.FRIGHTENED:
		ghost_state = FrightStates.CAUGHT  # Set local state to CAUGHT
		score_machine.add_points(2000)
		last_state = current_state  # Store the current state
		nav_agent.target_position = tile_position_to_global_position(Vector2(16, 16))  # Set target to ghost shed
		set_collision_layer(0)  # Disable collision layer
		set_collision_mask(0)  # Disable collision mask
		move_to_shed()  # Start moving to the shed
		is_eaten = true  # Set is_eaten to true

func move_to_shed() -> void:
	var next_position = nav_agent.get_next_path_position()
	if next_position != Vector2.ZERO:
		var dir = (next_position - global_position).normalized()
		velocity = dir * return_speed
		move_and_slide()
		if dir.x > 0:
			animated_sprite.play("eaten_right")
		else:
			animated_sprite.play("eaten_left")
		if global_position.distance_to(nav_agent.target_position) < 1:
			reset_to_normal_state()

func reset_to_normal_state() -> void:
	ghost_state = FrightStates.NORMAL
	current_state = States.INITIAL  # Reset to initial state
	animated_sprite.play("idle")  # Play idle animation
	is_eaten = false  # Reset is_eaten to false
	set_collision_layer(8)  # Re-enable collision layer 4
	set_collision_mask(6)  # Re-enable collision mask 3
	print("Collision layer reset to: ", get_collision_layer())
	print("Collision mask reset to: ", get_collision_mask())
	clyde_initial_target = tile_position_to_global_position(clyde_initial_positions[clyde_initial_index])

func update_target_position():
	if current_state == States.SCATTER:
		scatter_index = (scatter_index + 1) % clyde_data["home_corner_loop"].size()
		var target_pos = clyde_data["home_corner_loop"][scatter_index]
		var tile_size = tilemap.tile_set.tile_size
		var tile_center = Vector2(tile_size.x / 2, tile_size.y / 2)
		target_pos.x = floor(target_pos.x / tile_size.x) * tile_size.x + tile_center.x
		target_pos.y = floor(target_pos.y / tile_size.y) * tile_size.y + tile_center.y
		nav_agent.target_position = target_pos
	elif current_state == States.CHASE:
		make_chase_path()

func set_freeze(freeze: bool) -> void:
	is_frozen = freeze
	if is_frozen:
		anisprite.stop()  # Stop animation when frozen

func get_state():
	return current_state
