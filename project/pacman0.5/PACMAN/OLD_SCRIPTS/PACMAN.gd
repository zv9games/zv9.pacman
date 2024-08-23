extends CharacterBody2D

signal initialized
signal pacman_ghost_collision  # Add this signal

@onready var tile_map = $"/root/BINARY/ORIGINAL/MAP/TILEMAP"
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var collision_shape = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN/CollisionShape2D" as CollisionShape2D
@onready var anisprite = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN/AnimatedSprite2D"
@onready var endgame = $"/root/BINARY/END_GAME"  # Reference to the Endgame node
@onready var gamestate = $"/root/BINARY/GAME_STATE"

const SPEED = 220

var tile_size = Vector2(16, 16)
var last_input_direction = Vector2.ZERO
var last_tile_position: Vector2i = Vector2i()
var current_direction = Vector2.ZERO
var is_frozen = false  # Flag to track if Pacman is frozen
var current_state

func initialize():
	print("ready", self)
	setup_character()
	emit_signal("initialized", self.name)
	

func setup_character():
	var pacman_tile_position = Vector2i(16, 20) # Set the initial position for Pacman
	pacman.position = tile_map.map_to_local(pacman_tile_position) # Convert tile position to world position

func _ready() -> void:
	self.visible = false
	initialize()

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

func _physics_process(delta: float) -> void:
	if is_frozen:
		return  # Skip movement if frozen
	var direction = get_input()
	if direction != current_direction:
		update_animation(direction)
		current_direction = direction
	velocity = direction * SPEED
	move_and_slide()
	# Check for tile interactions after movement.
	tile_map.check_tile()

func get_tile_position() -> Vector2i:
	return tile_map.local_to_map(tile_map.to_local(global_position))

func set_freeze(freeze: bool) -> void:
	is_frozen = freeze
	if is_frozen:
		anisprite.stop()  # Stop animation when frozen

func _on_area_2d_body_entered(body):
	if body.name in ["BLINKY", "PINKY", "INKY", "CLYDE"]:  # Check if the body is one of the ghosts
		var ghost_state = body.get_state()  # Get the ghost's state
		emit_signal("pacman_ghost_collision", ghost_state, body)  # Emit the collision signal with the ghost's state and instance
		print("Pacman collided with ghost")

