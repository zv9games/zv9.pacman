extends CharacterBody2D

signal online
signal pacman_ghost_collision

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING, PAUSE }
enum FrightStates { NORMAL, CAUGHT }

@onready var gamestate = $/root/BINARY/GAMESTATE
@onready var originalboard = $/root/BINARY/MODES/ORIGINAL/ORIGINALBOARD
@onready var animated_sprite = $/root/BINARY/MODES/ORIGINAL/PACMAN/AnimatedSprite2D
@onready var blinky = $/root/BINARY/MODES/ORIGINAL/BLINKY
@onready var pinky = $/root/BINARY/MODES/ORIGINAL/PINKY
@onready var inky = $/root/BINARY/MODES/ORIGINAL/INKY
@onready var clyde = $/root/BINARY/MODES/ORIGINAL/CLYDE
@onready var scoremachine = $/root/BINARY/SCOREMACHINE
@onready var soundbank = $/root/BINARY/SOUNDBANK
@onready var zpu = $/root/BINARY/ZPU
@onready var startmenu = $/root/BINARY/STARTMENU
@onready var loading = $/root/BINARY/STARTMENU/LOADING
@onready var death1 = $/root/BINARY/SOUNDBANK/DEATH1
@onready var camera = $/root/BINARY/Camera2D
@onready var powerups = $/root/BINARY/MODES/ORIGINAL/POWERUPS

var start_pos = Vector2(16, 20)
var speed = 130
var is_frozen = false
var input_direction = Vector2.ZERO
var new_direction = Vector2.ZERO
var input_history = []

func _ready():
	startmenu.connect("start_game", Callable(self, "_on_start_game_signal"))
	self.visible = false
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	death1.connect("finished", Callable(self, "_on_death1_finished"))
	camera.connect("swipe_detected", Callable(self, "_on_swipe_detected"))

func _on_start_game_signal():
	pac_start_pos()
	self.visible = true

func _emit_online_signal():
	emit_signal("online", self.name)

func pac_start_pos():
	position = tile_position_to_global_position(start_pos)

func get_input():
	var key_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if key_input != Vector2.ZERO:
		input_direction = key_input
	if input_direction != Vector2.ZERO:
		new_direction = input_direction
	store_input(new_direction)

func store_input(direction: Vector2):
	input_history.append(direction)
	if input_history.size() > 5000:  # Limit to the last 5000 inputs
		input_history.pop_front()

func update_animation():
	if new_direction.x > 0:
		animated_sprite.play("move_right")
	elif new_direction.x < 0:
		animated_sprite.play("move_left")
	elif new_direction.y > 0:
		animated_sprite.play("move_down")
	elif new_direction.y < 0:
		animated_sprite.play("move_up")
	else:
		animated_sprite.stop()

func set_freeze(freeze: bool) -> void:
	is_frozen = freeze
	if is_frozen:
		animated_sprite.stop()

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tile_map_pos = originalboard.local_to_map(global_pos)
	return tile_map_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = originalboard.map_to_local(tile_pos)
	var global_pos = originalboard.to_global(local_pos)
	return global_pos

func _on_area_2d_body_entered(body):
	print("Body entered: ", body.name)
	if body.name in ["BLINKY", "PINKY", "INKY", "CLYDE"]:
		if gamestate.get_state() in [States.SCATTER, States.CHASE]:
			print("Pacman collided with ghost: ", body.name)
			gamestate.set_state(States.LOADING)
			set_freeze(true)
			blinky.set_freeze(true)
			pinky.set_freeze(true)
			inky.set_freeze(true)
			clyde.set_freeze(true)
			scoremachine.lose_life()
			soundbank.play("DEATH1")
			animated_sprite.play("gameover")
			powerups.visible = false
			powerups.call_deferred("_disable_collision_shape")

func _on_death1_finished():
	if scoremachine.get_lives() > 0:
		pac_start_pos()
		zpu.start_game()
	else:
		zpu.handle_game_over()

func _on_swipe_detected(direction: Vector2):
	input_direction = direction

func _physics_process(delta):
	if is_frozen:
		return
	
	get_input()
	
	velocity = new_direction * speed
	move_and_slide()
	
	update_animation()
	originalboard.check_tile()
