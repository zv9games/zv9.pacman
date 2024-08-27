extends CharacterBody2D

signal online
signal pacman_ghost_collision  # Add this signal
signal freeze_pacman

@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var collision_shape = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN/CollisionShape2D" as CollisionShape2D
@onready var anisprite = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN/AnimatedSprite2D"
@onready var ZPU = $"/root/BINARY/ZPU"
@onready var gamestate = $"/root/BINARY/GAMESTATE"
@onready var swipe_detector = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD/Camera2D"  # Add this line

const SPEED = 110

var tile_size = Vector2(16, 16)
var last_input_direction = Vector2.ZERO
var last_tile_position: Vector2i = Vector2i()
var current_direction = Vector2.ZERO
var is_frozen = false  # Flag to track if Pacman is frozen
var current_state

func _ready() -> void:
	self.visible = false
	setup_character()
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	swipe_detector.connect("swipe_detected", Callable(self, "_on_swipe_detected"))  # Connect the signal
	print("Current direction: ", last_input_direction)
	ZPU.connect("freeze_pacman", Callable(self, "set_freeze"))  # Connect ZPU signal to set_freeze function

func _emit_online_signal():
	emit_signal("online", self.name)

func setup_character():
	var pacman_tile_position = Vector2i(16, 20) # Set the initial position for Pacman
	pacman.position = gameboard.map_to_local(pacman_tile_position) # Convert tile position to world position

func get_input() -> Vector2:
	var input_direction = Vector2.ZERO
	input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	if input_direction != Vector2.ZERO:
		last_input_direction = input_direction.normalized()
	return input_direction

func update_animation(direction: Vector2) -> void:
	if direction.x > 0:
		anisprite.play("right")
	elif direction.x < 0:
		anisprite.play("left")
	elif direction.y > 0:
		anisprite.play("down")
	elif direction.y < 0:
		anisprite.play("up")
	else:
		anisprite.stop()

func _on_swipe_detected(direction: Vector2):
	print("Swipe detected: ", direction)
	last_input_direction = direction
	print("Current direction: ", last_input_direction)

func _physics_process(delta: float) -> void:
	if is_frozen:
		return  # Skip movement if frozen
	var direction = get_input()
	if direction != Vector2.ZERO:
		last_input_direction = direction

	velocity = last_input_direction * SPEED
	move_and_slide()
	if is_on_wall():
		handle_wall_collision()
	else:
		current_direction = last_input_direction
	update_animation(current_direction)
	gameboard.check_tile()

func handle_wall_collision() -> void:
	var possible_directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	possible_directions.erase(current_direction)
	for dir in possible_directions:
		if !is_direction_blocked(dir):
			current_direction = dir
			break

func is_direction_blocked(direction: Vector2) -> bool:
	var test_position = global_position + direction * tile_size
	return gameboard.get_cell_source_id(gameboard.local_to_map(test_position)) != -1

func get_tile_position() -> Vector2i:
	return gameboard.local_to_map(gameboard.to_local(global_position))

func set_freeze(freeze: bool) -> void:
	is_frozen = freeze
	if is_frozen:
		anisprite.stop()  # Stop animation when frozen

func _on_area_2d_body_entered(body):
	if body.name in ["BLINKY", "PINKY", "INKY", "CLYDE"]:  # Check if the body is one of the ghosts
		var ghost_state = body.call("get_state")  # Call the ghost's get_state method
		emit_signal("pacman_ghost_collision", ghost_state, body)  # Emit the collision signal with the ghost's state and instance
		print("Pacman collided with ghost")
