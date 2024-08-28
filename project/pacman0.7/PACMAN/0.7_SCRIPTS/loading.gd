extends TileMapLayer

signal online

const speed = 170

var end : Vector2 = Vector2(27, 12)
var start : Vector2 = Vector2(5, 12)
var start_position
var end_position

@onready var loading_pacman_scene = $"/root/BINARY/OPEN/LOADING_PACMAN"
@onready var loading_blinky_scene = $"/root/BINARY/OPEN/LOADING_BLINKY"
@onready var loading_pinky_scene = $"/root/BINARY/OPEN/LOADING_PINKY"
@onready var loading_inky_scene = $"/root/BINARY/OPEN/LOADING_INKY"
@onready var loading_clyde_scene = $"/root/BINARY/OPEN/LOADING_CLYDE"

@onready var loading : TileMapLayer = $"/root/BINARY/OPEN/LOADING"
@onready var start_menu = $"/root/BINARY/STARTMENU"
@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var characters2 = $"/root/BINARY/ORIGINAL/CHARACTERS"
@onready var blinky = $/root/BINARY/ORIGINAL/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/ORIGINAL/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/ORIGINAL/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/ORIGINAL/CHARACTERS/CLYDE
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"

var characters = []
var current_character_index = 0

func _ready():
	scene_prep()
	var timer = Timer.new()
	timer.wait_time = 0.2  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	start_position = tile_position_to_global_position(start)
	end_position = tile_position_to_global_position(end)

func scene_prep():
	loading_pacman_scene.visible = false
	loading_blinky_scene.visible = false
	loading_pinky_scene.visible = false
	loading_inky_scene.visible = false
	loading_clyde_scene.visible = false
	pacman.visible = false
	blinky.visible = false
	pinky.visible = false
	inky.visible = false
	clyde.visible = false

func _emit_online_signal():
	emit_signal("online", self.name)

func instance_character(scene, moving_to_end: bool) -> Dictionary:
	var character = scene.duplicate() as CharacterBody2D
	call_deferred("add_child", character)
	character.global_position = start_position if moving_to_end else end_position
	character.visible = false  # Start invisible
	return {"instance": character, "moving_to_end": moving_to_end, "current_animation": ""}

func stop_loading_screen():
	print("Stopping loading screen...")
	set_physics_process(false)
	for character in characters:
		character["instance"].queue_free()
	characters.clear()
	self.hide()
	print("Loading screen stopped.")

func start_loading_screen():
	loading_pacman_scene.visible = true
	loading_blinky_scene.visible = true
	loading_pinky_scene.visible = true
	loading_inky_scene.visible = true
	loading_clyde_scene.visible = true
	set_physics_process(true)
	characters = [
		instance_character(loading_pacman_scene, true),
		instance_character(loading_blinky_scene, true),
		instance_character(loading_pinky_scene, true),
		instance_character(loading_inky_scene, true),
		instance_character(loading_clyde_scene, true)
	]
	current_character_index = 0
	call_deferred("start_character_movement")
	print("Loading screen started.")
	

func restart_loading_screen():
	print("Restarting loading screen...")
	stop_loading_screen()
	call_deferred("start_loading_screen")
	print("Loading screen restarted.")

func start_character_movement():
	if current_character_index < characters.size():
		var character = characters[current_character_index]
		character["instance"].set_physics_process(true)
		current_character_index += 1
		var timer = Timer.new()
		timer.wait_time = 0.2
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "start_character_movement"))
		add_child(timer)
		timer.start()

func move_character(character, delta):
	var instance = character["instance"]
	if instance.is_physics_processing():
		var target_position = end_position if character["moving_to_end"] else start_position
		var direction = (target_position - instance.global_position).normalized()
		instance.velocity = direction * speed
		instance.move_and_slide()
		update_animation(character, direction)
		
		# Make character visible when leaving start position
		if instance.global_position.distance_to(start_position) > 1.5 and !character["moving_to_end"]:
			instance.visible = true
		
		# Make character invisible and pause when reaching end position
		if instance.global_position.distance_to(end_position) < 1.5 and character["moving_to_end"]:
			instance.visible = false
			instance.set_physics_process(false)
			var timer = Timer.new()
			timer.wait_time = 1.3  # Pause duration
			timer.one_shot = true
			timer.connect("timeout", Callable(self, "_resume_movement").bind(instance))
			add_child(timer)
			timer.start()
		
		# Make character visible when leaving end position
		if instance.global_position.distance_to(end_position) > 1.5 and character["moving_to_end"]:
			instance.visible = true
		
		# Make character invisible and pause when reaching start position
		if instance.global_position.distance_to(start_position) < 1.5 and !character["moving_to_end"]:
			instance.visible = false
			instance.set_physics_process(false)
			var timer = Timer.new()
			timer.wait_time = 1.3  # Pause duration
			timer.one_shot = true
			timer.connect("timeout", Callable(self, "_resume_movement").bind(instance))
			add_child(timer)
			timer.start()
		
		if instance.global_position.distance_to(target_position) < 1.5:
			character["moving_to_end"] = !character["moving_to_end"]

func _resume_movement(instance):
	instance.set_physics_process(true)

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
	return loading.local_to_map(global_pos)

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	return loading.to_global(loading.map_to_local(tile_pos))
