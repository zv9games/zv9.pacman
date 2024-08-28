extends CharacterBody2D

signal online
signal pacman_ghost_collision

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING }
enum FrightStates { NORMAL, CAUGHT }

@onready var gamestate = $/root/BINARY/GAMESTATE
@onready var gameboard = $/root/BINARY/ORIGINAL/MAP/GAMEBOARD
@onready var animated_sprite = $/root/BINARY/ORIGINAL/CHARACTERS/PACMAN/AnimatedSprite2D
@onready var blinky = $/root/BINARY/ORIGINAL/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/ORIGINAL/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/ORIGINAL/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/ORIGINAL/CHARACTERS/CLYDE
@onready var scoremachine = $/root/BINARY/SCOREMACHINE
@onready var soundbank = $/root/BINARY/SOUNDBANK
@onready var zpu = $/root/BINARY/ZPU
@onready var startmenu = $/root/BINARY/STARTMENU
@onready var loading = $/root/BINARY/OPEN/LOADING
@onready var death1 = $/root/BINARY/SOUNDBANK/DEATH1
@onready var camera = $/root/BINARY/Camera2D

var start_pos = Vector2(16, 20)
var speed = 230
var desired_direction = Vector2.ZERO
var current_direction = Vector2.ZERO
var is_frozen = false

func _ready():
	pac_start_pos()
	var timer = Timer.new()
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	death1.connect("finished", Callable(self, "_on_death1_finished"))
	camera.connect("swipe_detected", Callable(self, "handle_swipe_input"))  # Connect to swipe detector

func _emit_online_signal():
	emit_signal("online", self.name)

func pac_start_pos():
	position = tile_position_to_global_position(start_pos)

func _physics_process(delta):
	if is_frozen:
		return
	handle_input()
	move_and_slide()
	update_animation()
	gameboard.check_tile()

func handle_input():
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1

	if input_vector != Vector2.ZERO:
		desired_direction = input_vector.normalized()
		if can_move_in_direction(desired_direction):
			current_direction = desired_direction
			velocity = current_direction * speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

func handle_swipe_input(direction: Vector2):
	desired_direction = direction.normalized()
	if can_move_in_direction(desired_direction):
		current_direction = desired_direction
		velocity = current_direction * speed
	else:
		velocity = Vector2.ZERO
	print("Swipe detected, direction: ", direction)

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
	is_frozen = freeze
	if is_frozen:
		animated_sprite.stop()

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tile_map_pos = gameboard.local_to_map(global_pos)
	return tile_map_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = gameboard.map_to_local(tile_pos)
	var global_pos = gameboard.to_global(local_pos)
	return global_pos

func _on_area_2d_body_entered(body):
	if body.name in ["BLINKY", "PINKY", "INKY", "CLYDE"]:
		if gamestate.get_state() in [States.SCATTER, States.CHASE]:
			gamestate.set_state(States.LOADING)
			set_freeze(true)
			blinky.set_freeze(true)
			pinky.set_freeze(true)
			scoremachine.lose_life()
			soundbank.play("DEATH1")
			animated_sprite.play("gameover")

func _on_death1_finished():
	if scoremachine.get_lives() > 0:
		pac_start_pos()
		zpu.start_game()
		gamestate.set_state(States.INITIAL)
	else:
		zpu.handle_game_over()
