extends CharacterBody2D

enum States {
	CHASE,
	SCATTER,
	FRIGHTENED,
	INITIAL,
	PRE_GAME
}
enum FrightStates {
	NORMAL,
	CAUGHT
}

signal initialized

const speed = 70
const frightened_speed = 30
const return_speed = 100  # Speed for returning to the shed
const DIRECTION_THRESHOLD = 0.1  # Add a threshold for direction values

@onready var nav_agent = $NavigationAgent2D as NavigationAgent2D
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var chase_timer = $Chase_Timer
@onready var scatter_timer = $Scatter_Timer
@onready var tilemap = $"/root/BINARY/ORIGINAL/MAP/TILEMAP"
@onready var game_state = $"/root/BINARY/GAME_STATE"
@onready var animated_sprite = $AnimatedSprite2D  
@onready var score_machine = $/root/BINARY/SCORE_MACHINE
@onready var collision_area = $Area2D  

var ghost_state = FrightStates.NORMAL
var dot_eaten_count = 0 
var current_state         
var scatter_index = 0
var blinky_frozen: bool = true  # Blinky starts frozen

var blinky_data: Dictionary = {
	"home_corner_loop": [Vector2(23, 8), Vector2(23, 3), Vector2(29, 3), Vector2(29, 8)],}
var start_position = Vector2()
var score: int = 0
var last_state  # Variable to store the last state
var is_eaten = false  
var blinky_initial_target: Vector2
var blinky_initial_positions: Array = [Vector2(19, 15), Vector2(19, 18)]
var blinky_initial_index: int = 0
var is_initialized = false

func _ready():
	initialize()
	tilemap.connect("dot_eaten", Callable(self, "_on_dot_eaten"))
	animated_sprite.play("idle")  
	start_position = global_position  
	collision_area.monitoring = true  # Ensure monitoring is enabled
	collision_area.monitorable = true  # Ensure the area can be monitored

func _on_dot_eaten():
	score += 1
	if score >= 8:
		release_blinky()
		score = 0

func release_blinky():
	blinky_frozen = false

func initialize():
	if is_initialized:
		return
	for key in blinky_data.keys():
		for i in range(blinky_data[key].size()):
			blinky_data[key][i] = tile_position_to_global_position(blinky_data[key][i])
	game_state.connect("state_changed", Callable(self, "_on_state_changed"))
	blinky_initial_target = tile_position_to_global_position(blinky_initial_positions[blinky_initial_index])
	emit_signal("initialized", self.name)
	is_initialized = true

func ghost_position_start():
	blinky_frozen = true
	blinky_initial_index = 0
	blinky_initial_target = tile_position_to_global_position(blinky_initial_positions[blinky_initial_index])
	animated_sprite.play("idle")
	print("Blinky position start")

func reset_to_normal_state():
	ghost_state = FrightStates.NORMAL
	current_state = States.INITIAL  # Reset to initial state
	animated_sprite.play("idle")  # Play idle animation
	is_eaten = false  # Reset is_eaten to false
	blinky_initial_target = tile_position_to_global_position(blinky_initial_positions[blinky_initial_index])
	
func _on_state_changed(new_state):
	current_state = new_state
	match current_state:
		GameState.States.CHASE:
			make_chase_path()
			chase_timer.start()
			scatter_timer.stop()
		GameState.States.SCATTER:
			make_scatter_path()
			chase_timer.stop()
			scatter_timer.start()
		GameState.States.FRIGHTENED:
			chase_timer.stop()
			scatter_timer.stop()
			animated_sprite.play("frightened")  # Play frightened animation
		GameState.States.PRE_GAME:
			chase_timer.stop()
			scatter_timer.stop()

func _physics_process(_delta: float) -> void:
	if blinky_frozen:
		move_blinky_initial()
	else:
		match current_state:
			GameState.States.CHASE:
				move_towards_target()
			GameState.States.SCATTER:
				move_towards_target()
			GameState.States.FRIGHTENED:
				if ghost_state == FrightStates.NORMAL:
					move_away_from_pacman()
				elif ghost_state == FrightStates.CAUGHT:
					move_to_shed()
			GameState.States.INITIAL:
				move_blinky_initial()

func move_blinky_initial() -> void:
	var dir = (blinky_initial_target - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if global_position.distance_to(blinky_initial_target) < 1:
		blinky_initial_index = (blinky_initial_index + 1) % blinky_initial_positions.size()
		blinky_initial_target = tile_position_to_global_position(blinky_initial_positions[blinky_initial_index])
	animated_sprite.play("idle")  # Ensure idle animation is playing

func move_towards_target() -> void:
	if not blinky_frozen:
		var next_position = nav_agent.get_next_path_position()
		if next_position != Vector2.ZERO:
			var dir = (next_position - global_position).normalized()
			velocity = dir * speed
			move_and_slide()
			update_animation(dir)
			if current_state == GameState.States.SCATTER and global_position.distance_to(nav_agent.target_position) < 1:
				make_scatter_path()

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

func make_chase_path() -> void:
	var target_pos = pacman.global_position
	var tile_size = tilemap.tile_set.tile_size
	var tile_center = Vector2(tile_size.x / 2, tile_size.y / 2)
	target_pos.x = floor(target_pos.x / tile_size.x) * tile_size.x + tile_center.x
	target_pos.y = floor(target_pos.y / tile_size.y) * tile_size.y + tile_center.y
	nav_agent.target_position = target_pos

func make_scatter_path() -> void:
	scatter_index = (scatter_index + 1) % blinky_data["home_corner_loop"].size()
	var target_pos = blinky_data["home_corner_loop"][scatter_index]

	var tile_size = tilemap.tile_set.tile_size
	var tile_center = Vector2(tile_size.x / 2, tile_size.y / 2)
	target_pos.x = floor(target_pos.x / tile_size.x) * tile_size.x + tile_center.x
	target_pos.y = floor(target_pos.y / tile_size.y) * tile_size.y + tile_center.y
	nav_agent.target_position = target_pos

func _on_chase_timer_timeout():
	if current_state == GameState.States.CHASE:
		make_chase_path()
		chase_timer.start()

func _on_scatter_timer_timeout():
	if current_state == GameState.States.SCATTER:
		nav_agent.target_position = nav_agent.target_position
		scatter_timer.start()

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tilemap_pos = tilemap.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = tilemap.map_to_local(tile_pos)
	var global_pos = tilemap.to_global(local_pos)
	return global_pos

func set_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state

func move_away_from_pacman() -> void:
	var dir = (global_position - pacman.global_position).normalized()
	velocity = dir * frightened_speed
	move_and_slide()
	animated_sprite.play("frightened")  # Ensure frightened animation is playing

func _on_area_2d_body_entered(body):
	if body.name == "PACMAN" and current_state == States.FRIGHTENED:
		ghost_state = FrightStates.CAUGHT  # Set local state to CAUGHT
		
		score_machine.add_points(2000)
		last_state = current_state  # Store the current state
		nav_agent.target_position = tile_position_to_global_position(Vector2(16, 16))  # Set target to ghost shed
		
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
			
