extends TileMapLayer

signal online

func _ready():

	# Create a timer with a 0.5-second delay
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	start_position = tile_position_to_global_position(start)
	end_position = tile_position_to_global_position(end)
	
	
func _emit_online_signal():
	emit_signal("online", self.name)

#BREAK


const speed = 170

var end : Vector2 = Vector2(27, 12)
var start : Vector2 = Vector2(5, 12)
var start_position
var end_position

@onready var loading_pacman_scene : PackedScene = load("res://PACMAN/SCENES/pacman.tscn")
@onready var loading_blinky_scene : PackedScene = load("res://PACMAN/SCENES/blinky.tscn")
@onready var loading_pinky_scene : PackedScene = load("res://PACMAN/SCENES/pinky.tscn")
@onready var loading_inky_scene : PackedScene = load("res://PACMAN/SCENES/inky.tscn")
@onready var loading_clyde_scene : PackedScene = load("res://PACMAN/SCENES/clyde.tscn")

@onready var loading : TileMapLayer = $"/root/BINARY/LOADING"
@onready var start_menu = $"/root/BINARY/STARTMENU"  # Adjust the path to your start button
@onready var gameboard = $/root/BINARY/ORIGINAL/MAP/GAMEBOARD
@onready var characters2 = $/root/BINARY/ORIGINAL/CHARACTERS

var characters = []
var current_character_index = 0

func instance_character(scene: PackedScene, moving_to_end: bool) -> Dictionary:
	var character = scene.instantiate() as CharacterBody2D
	add_child(character)
	character.global_position = start_position if moving_to_end else end_position
	return {"instance": character, "moving_to_end": moving_to_end, "current_animation": ""}

func start_loading_screen():
	set_physics_process(true)
	var pacman = instance_character(loading_pacman_scene, true)
	var blinky = instance_character(loading_blinky_scene, true)
	var pinky = instance_character(loading_pinky_scene, true)
	var inky = instance_character(loading_inky_scene, true)
	var clyde = instance_character(loading_clyde_scene, true)
	characters = [pacman, blinky, pinky, inky, clyde]
	current_character_index = 0
	start_character_movement()

func stop_loading_screen():
	set_physics_process(false)
	for character in characters:
		character["instance"].queue_free()
	characters.clear()
	self.hide()


func start_character_movement():
	if current_character_index < characters.size():
		var character = characters[current_character_index]
		character["instance"].set_physics_process(true)
		current_character_index += 1
		var timer = Timer.new()
		timer.wait_time = .2  # Adjust the delay as needed
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "start_character_movement"))
		add_child(timer)
		timer.start()

func move_character(character, delta):
	if character["instance"].is_physics_processing():
		var target_position = end_position if character["moving_to_end"] else start_position
		var direction = (target_position - character["instance"].global_position).normalized()
		character["instance"].velocity = direction * speed
		character["instance"].move_and_slide()
		update_animation(character, direction)
		if character["instance"].global_position.distance_to(target_position) < 1:
			character["moving_to_end"] = !character["moving_to_end"]

func _physics_process(delta):
	for character in characters:
		move_character(character, delta)

func update_animation(character: Dictionary, direction: Vector2):
	var anisprite = character["instance"].get_node("AnimatedSprite2D")
	var new_animation = ""
	if direction.x > 0:
		new_animation = "move_right"
	elif direction.x < 0:
		new_animation = "move_left"
	else:
		anisprite.stop()
		return

	if new_animation != character["current_animation"]:
		character["current_animation"] = new_animation
		anisprite.play(new_animation)

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tile_map_pos = loading.local_to_map(global_pos)
	return tile_map_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = loading.map_to_local(tile_pos)
	var global_pos = loading.to_global(local_pos)
	return global_pos
