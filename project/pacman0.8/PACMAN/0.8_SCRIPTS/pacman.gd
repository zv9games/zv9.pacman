extends CharacterBody2D

signal online
signal pacman_ghost_collision

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING }
enum FrightStates { NORMAL, CAUGHT }

@onready var gamestate = $/root/BINARY/GAME/GAMESTATE
@onready var gameboard = $/root/BINARY/LEVELS/ORIGINAL/MAP/GAMEBOARD
@onready var animated_sprite = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/PACMAN/AnimatedSprite2D
@onready var blinky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/CLYDE
@onready var scoremachine = $/root/BINARY/GAME/SCOREMACHINE
@onready var soundbank = $/root/BINARY/GAME/SOUNDBANK
@onready var zpu = $/root/BINARY/GAME/ZPU
@onready var startmenu = $/root/BINARY/GAME/STARTMENU
@onready var loading = $/root/BINARY/GAME/LOADING
@onready var death1 = $/root/BINARY/GAME/SOUNDBANK/DEATH1
@onready var camera = $/root/BINARY/Camera2D

var start_pos = Vector2(16, 20)
var speed = 130
var is_frozen = false
var input_direction = Vector2.ZERO
var input_history = []


func _ready():
	pac_start_pos()
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	death1.connect("finished", Callable(self, "_on_death1_finished"))

func _emit_online_signal():
	emit_signal("online", self.name)

func pac_start_pos():
	position = tile_position_to_global_position(start_pos)

func get_input():
	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	store_input(input_direction)

func store_input(direction: Vector2):
	input_history.append(direction)
	if input_history.size() > 5000:  # Limit to the last 100 inputs
		input_history.pop_front()

func update_animation():
	if input_direction.x > 0:
		animated_sprite.play("move_right")
	elif input_direction.x < 0:
		animated_sprite.play("move_left")
	elif input_direction.y > 0:
		animated_sprite.play("move_down")
	elif input_direction.y < 0:
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
	print("Body entered: ", body.name)
	if body.name in ["BLINKY", "PINKY", "INKY", "CLYDE"]:
		if gamestate.get_state() in [States.SCATTER, States.CHASE]:
			print("Pacman collided with ghost: ", body.name)
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

func _physics_process(delta):
	if is_frozen:
		return
	
	get_input()
	
	move_and_slide()
	
	update_animation()
	gameboard.check_tile()
