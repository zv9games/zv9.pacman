extends CharacterBody2D

signal online

func _ready():
	
	self.visible = false
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	startmenu.connect("start_original", Callable(self, "start_inky"))
	gamestate.connect("state_changed", Callable(self, "_on_state_changed"))
	
func _emit_online_signal():
	emit_signal("online", self.name)
	
############################################################################

const speed = 50 # Normal speed
const frightened_speed = 30
const return_speed = 200  
const DIRECTION_THRESHOLD = 0.1  

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING }
enum FrightStates { NORMAL, CAUGHT }

var tile_size = Vector2(16, 16)  # Assuming each tile is 32x32 pixels
var start_position = Vector2(15, 18)
var inky_position = start_position * tile_size
var is_frozen = false
var ghost_state = FrightStates.NORMAL
var dot_eaten_count = 0     
var current_state = null             
var scatter_index = 0
var inky_data: Dictionary = { "home_corner_loop": [Vector2(23, 20), Vector2(23, 26), Vector2(26, 22), Vector2(29, 20)] }
var score: int = 0
var last_state  # Variable to store the last state
var is_eaten = false  
var inky_initial_target: Vector2
var inky_initial_positions: Array = [Vector2(15, 15), Vector2(15, 18)]
var inky_initial_index: int = 0
var is_initialized = false

@onready var zpu = $"/root/BINARY/ZPU"
@onready var gamestate = $"/root/BINARY/ZPU/GAMESTATE"
@onready var nav_agent = $NavigationAgent2D as NavigationAgent2D
@onready var pacman = $"/root/BINARY/GAME/CHARACTERS/PACMAN"
@onready var gameboard = $"/root/BINARY/GAME/ORIGINAL/TILEMAPLAYER"
@onready var animated_sprite = $AnimatedSprite2D  
@onready var scoremachine = $/root/BINARY/ZPU/SCOREMACHINE
@onready var collision_area = $Area2D  
@onready var anisprite = $"/root/BINARY/GAME/CHARACTERS/BLINKY/AnimatedSprite2D"
@onready var soundbank = $/root/BINARY/ZPU/SOUNDBANK
@onready var area2d_collision = $/root/BINARY/GAME/CHARACTERS/INKY/Area2D/CollisionShape2D
@onready var startmenu = $/root/BINARY/MENUS/STARTMENU

func start_inky():
	pass

func _on_state_changed(new_state):
	current_state = new_state
	_handle_state_change(new_state)
	
func _handle_state_change(new_state):
	match new_state:
		States.CHASE:
			reset_ghost_state()
			_start_chase_behavior()
		States.SCATTER:
			_start_scatter_behavior()
		States.FRIGHTENED:
			if ghost_state == FrightStates.NORMAL:
				_start_normal_frightened_behavior()
			elif ghost_state == FrightStates.CAUGHT:
				_start_caught_frightened_behavior()
		States.INITIAL:
			_start_initial_behavior()
		States.LOADING:
			_start_loading_behavior()
	
func _physics_process(delta):
	match current_state:
		States.CHASE:
			_update_chase_behavior(delta)
		States.SCATTER:
			_update_scatter_behavior(delta)
		States.FRIGHTENED:
			if ghost_state == FrightStates.NORMAL:
				_update_normal_frightened_behavior(delta)
			elif ghost_state == FrightStates.CAUGHT:
				_update_caught_frightened_behavior(delta)
		States.INITIAL:
			_update_initial_behavior(delta)
		States.LOADING:
			_update_loading_behavior(delta)
	pass
func _start_chase_behavior():
	make_chase_path()

func _start_scatter_behavior():
	make_scatter_path()

func _start_normal_frightened_behavior():
	move_away_from_pacman()
	
func _start_caught_frightened_behavior():
	nav_agent.target_position = tile_position_to_global_position(Vector2(16, 15))  # Convert tile position to global position
	move_to_shed()
	
func _start_initial_behavior():
	self.visible = true
	self.position = inky_position
	inky_initial_target = tile_position_to_global_position(inky_initial_positions[inky_initial_index])
	move_inky_initial()

func _start_loading_behavior():
	pass
	
func _update_chase_behavior(delta):
	move_towards_target()

func _update_scatter_behavior(delta):
	move_towards_target()

func _update_normal_frightened_behavior(delta):
	move_away_from_pacman()
	
func _update_caught_frightened_behavior(delta):
	nav_agent.target_position = tile_position_to_global_position(Vector2(16, 15))  # Convert tile position to global position
	move_to_shed()
	
func _update_initial_behavior(delta):
		move_inky_initial()

func _update_loading_behavior(delta):
	pass
	
func move_inky_initial() -> void:
	var dir = (inky_initial_target - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if global_position.distance_to(inky_initial_target) < 1:
		inky_initial_index = (inky_initial_index + 1) % inky_initial_positions.size()
		inky_initial_target = tile_position_to_global_position(inky_initial_positions[inky_initial_index])
	animated_sprite.play("idle")
	
func make_chase_path() -> void:
	var target_pos = pacman.global_position
	var tile_size = gameboard.tile_set.tile_size
	var tile_center = Vector2(tile_size.x / 2, tile_size.y / 2)
	target_pos.x = floor(target_pos.x / tile_size.x) * tile_size.x + tile_center.x
	target_pos.y = floor(target_pos.y / tile_size.y) * tile_size.y + tile_center.y
	nav_agent.target_position = target_pos

func make_scatter_path() -> void:
	scatter_index = (scatter_index + 1) % inky_data["home_corner_loop"].size()
	var target_pos = inky_data["home_corner_loop"][scatter_index]
	var global_target_pos = tile_position_to_global_position(target_pos)
	nav_agent.target_position = global_target_pos
	
func move_towards_target() -> void:
	var next_position = nav_agent.get_next_path_position()
	if next_position != Vector2.ZERO:
		var dir = (next_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		update_animation(dir)
		if global_position.distance_to(next_position) < 1:
			update_target_position()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
	next_position = nav_agent.get_next_path_position()
	if next_position == Vector2.ZERO:
		print("Path empty, recalculating...")
		update_target_position()

func update_target_position():
	if current_state == States.SCATTER:
		scatter_index = (scatter_index + 1) % inky_data["home_corner_loop"].size()
		var target_pos = inky_data["home_corner_loop"][scatter_index]
		var global_target_pos = tile_position_to_global_position(target_pos)
		
		nav_agent.target_position = global_target_pos
	elif current_state == States.CHASE:
		make_chase_path()

func move_away_from_pacman() -> void:
	var dir = (global_position - pacman.global_position).normalized()
	var new_position = global_position + dir * frightened_speed
	if is_position_within_bounds(new_position):
		velocity = dir * frightened_speed
	else:
		print("Path blocked, trying alternate directions")
		var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		for alt_dir in directions:
			var alt_new_position = global_position + alt_dir * frightened_speed
			if is_position_within_bounds(alt_new_position):
				velocity = alt_dir * frightened_speed
				break
	move_and_slide()
	animated_sprite.play("frightened")

func move_to_shed() -> void:
	call_deferred("set_collision_disabled", true)
	var next_position = nav_agent.get_next_path_position()
	if next_position != Vector2.ZERO:
		var dir = (next_position - global_position).normalized()
		velocity = dir * return_speed
		move_and_slide()
		call_deferred("set_collision_disabled", false)
		if dir.x > 0:
			animated_sprite.play("eaten_right")
		else:
			animated_sprite.play("eaten_left")
		if global_position.distance_to(nav_agent.target_position) < 2:
			reset_to_normal_state()
			

func reset_ghost_state():
	ghost_state = FrightStates.NORMAL

func set_collision_disabled(disabled: bool):
	area2d_collision.disabled = disabled
	
func reset_to_normal_state():
	ghost_state = FrightStates.NORMAL
	current_state = States.INITIAL
	
func set_state(new_state):
	ghost_state = new_state
	if new_state == FrightStates.CAUGHT:
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)  # Disable collisions to unstick from Pacman
		move_to_shed()
		await get_tree().create_timer(1).timeout  # Add a small delay
		set_collision_layer_value(2, true)  # Re-enable collisions after delay
		set_collision_mask_value(1, true)  # Re-enable mask 1 after delay
	else:
		set_collision_layer_value(2, true)  # Default layer for normal state
		set_collision_mask_value(1, true)  # Enable mask 1
		set_collision_mask_value(4, true)  # Enable mask 4
		
func get_state() -> int:
	return ghost_state

func is_position_within_bounds(position: Vector2) -> bool:
	var tile_pos = gameboard.local_to_map(position)
	return !gameboard.is_tile_blocked(tile_pos)

func set_freeze(freeze: bool) -> void:
	is_frozen = freeze
	if is_frozen:
		anisprite.stop()  # Stop animation when frozen

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tilemap_pos = gameboard.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = gameboard.map_to_local(tile_pos)
	var global_pos = gameboard.to_global(local_pos)
	return global_pos

func update_animation(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		if direction.x > DIRECTION_THRESHOLD:
			animated_sprite.play("move_right")
		elif direction.x < -DIRECTION_THRESHOLD:
			animated_sprite.play("move_left")
	else:
		if direction.y > DIRECTION_THRESHOLD:
			animated_sprite.play("move_down")
		elif direction.y < -DIRECTION_THRESHOLD:
			animated_sprite.play("move_up")

func _on_area_2d_body_entered(body):
	if body.name == "PACMAN" and current_state == States.FRIGHTENED:
		ghost_state = FrightStates.CAUGHT  # Set local state to CAUGHT
		soundbank.play("EAT_GHOST")

		scoremachine.add_points(2000)
		last_state = current_state  # Store the current state
		nav_agent.target_position = tile_position_to_global_position(Vector2(16, 16))  # Set target to ghost shed
		
		move_to_shed()  # Start moving to the shed
		is_eaten = true  # Set is_eaten to true
