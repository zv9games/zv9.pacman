extends CharacterBody2D

signal online
signal pacman_ghost_collision
enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING }

@onready var startmenu = $/root/BINARY/STARTMENU
@onready var gameboard = $/root/BINARY/ORIGINAL/MAP/GAMEBOARD
@onready var animated_sprite = $AnimatedSprite2D
@onready var scoremachine = $/root/BINARY/SCOREMACHINE
@onready var gamestate = $/root/BINARY/GAMESTATE
@onready var blinky = $/root/BINARY/ORIGINAL/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/ORIGINAL/CHARACTERS/PINKY
@onready var zpu = $/root/BINARY/ZPU
@onready var soundbank = $/root/BINARY/SOUNDBANK
@onready var death1 = $/root/BINARY/SOUNDBANK/DEATH1
@onready var pacman = $/root/BINARY/ORIGINAL/CHARACTERS/PACMAN
@onready var camera = $/root/BINARY/ORIGINAL/MAP/GAMEBOARD/Camera2D

var start_tile_pos = Vector2(16, 20)
var speed = 120  # Adjust the speed as needed
var desired_direction = Vector2.ZERO
var is_frozen = false  # Flag to track if Pacman is frozen

func _ready():
	is_frozen = false
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	startmenu.connect("start_button_pressed", Callable(self, "_on_start_button_pressed"))
	$Area2D.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))  # Ensure the signal is connected
	death1.connect("finished", Callable(self, "_on_death1_finished"))
	
	# Check if the camera node exists before connecting the signal
	if camera:
		camera.connect("swipe_detected", Callable(self, "handle_swipe_input"))
	else:
		print("Camera node not found!")

func _emit_online_signal():
	emit_signal("online", self.name)

func _on_start_button_pressed():
	position = tile_position_to_global_position(start_tile_pos)

func _physics_process(delta):
	if is_frozen:
		return  # Skip movement if frozen
	handle_input(delta)
	move_and_slide()
	update_animation()
	gameboard.check_tile()

func handle_input(delta):
	desired_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		desired_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		desired_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		desired_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		desired_direction.y -= 1

	if desired_direction != Vector2.ZERO:
		desired_direction = desired_direction.normalized()

	# Check if Pacman can move in the desired direction
	if can_move_in_direction(desired_direction):
		velocity = desired_direction * speed
	else:
		# Continue moving in the current direction if blocked
		velocity = velocity.normalized() * speed

func handle_swipe_input(direction: Vector2):
	desired_direction = direction

func can_move_in_direction(direction: Vector2) -> bool:
	var future_position = position + direction * speed * get_physics_process_delta_time()
	var future_tile_pos = global_position_to_tile_position(future_position)
	return !gameboard.is_tile_blocked(future_tile_pos)

func update_animation():
	if velocity.x > 0:
		animated_sprite.play("move_right")
	elif velocity.x < 0:
		animated_sprite.play("move_left")
	elif velocity.y > 0:
		animated_sprite.play("move_down")
	elif velocity.y < 0:
		animated_sprite.play("move_up")
	else:
		animated_sprite.stop()

func set_freeze(freeze: bool) -> void:
	print("set_freeze called with: ", freeze)
	is_frozen = freeze
	if is_frozen:
		animated_sprite.stop()  # Stop animation when frozen

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tile_map_pos = gameboard.local_to_map(global_pos)
	return tile_map_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = gameboard.map_to_local(tile_pos)
	var global_pos = gameboard.to_global(local_pos)
	return global_pos

func _on_area_2d_body_entered(body):
	if body.name in ["BLINKY", "PINKY", "INKY", "CLYDE"]:  # Check if the body is one of the ghosts
		emit_signal("pacman_ghost_collision", body.call("get_state"), body)  # Emit the collision signal with the ghost's state and instance
		
		if gamestate.get_state() in [States.SCATTER, States.CHASE]:  # Check if the game state is scatter or chase
			gamestate.set_state(States.LOADING)
			set_freeze(true)  # Freeze Pacman
			blinky.set_freeze(true)
			pinky.set_freeze(true)
			scoremachine.lose_life()
			soundbank.play("DEATH1")
			animated_sprite.play("gameover")

func _on_death1_finished():
	if scoremachine.get_lives() > 0:
		zpu._on_start_button_pressed()
	else:
		scoremachine.reset_score()
		scoremachine.reset_lives()
		scoremachine.reset_level_display()
		zpu.start_loading_loop()
		startmenu.visible = true
