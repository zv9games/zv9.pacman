extends TileMapLayer

signal online

const speed = 170
const stagger_delay = 0.3
const base_delay = 0.1
const pause_duration = 2

var end : Vector2 = Vector2(27, 12)
var start : Vector2 = Vector2(5, 12)
var start_position
var end_position

@onready var pacman2 = $"/root/BINARY/GAME/LOADING/LOADING_PACMAN"
@onready var blinky2 = $"/root/BINARY/GAME/LOADING/LOADING_BLINKY"
@onready var pinky2 = $"/root/BINARY/GAME/LOADING/LOADING_PINKY"
@onready var inky2 = $"/root/BINARY/GAME/LOADING/LOADING_INKY"
@onready var clyde2 = $"/root/BINARY/GAME/LOADING/LOADING_CLYDE"

@onready var loading : TileMapLayer = $"/root/BINARY/GAME/LOADING"
@onready var gameboard = $"/root/BINARY/LEVELS/ORIGINAL/MAP/GAMEBOARD"
@onready var binary = $"/root/BINARY"

var characters = []
var game_loop_active = true

func _ready():
	binary.connect("all_nodes_initialized", Callable(self, "_on_all_nodes_initialized"))
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	
func _emit_online_signal():
	emit_signal("online", self.name)
	
func _on_all_nodes_initialized():
	start_position = tile_position_to_global_position(start)
	end_position = tile_position_to_global_position(end)
	
	# Initialize characters
	characters = [pacman2, blinky2, pinky2, inky2, clyde2]
	for character in characters:
		character.visible = false
		character.position = start_position
		character.set_meta("current_animation", "")
	
	_move_characters_staggered()

func _move_characters_staggered():
	for i in range(characters.size()):
		var character = characters[i]
		var timer = Timer.new()
		timer.wait_time = base_delay + i * stagger_delay
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_start_character_movement").bind(character, true))
		add_child(timer)
		timer.start()

func _start_character_movement(character, to_end):
	if game_loop_active:
		character.visible = true
		character.position = start_position if to_end else end_position
		character.set_meta("to_end", to_end)
		character.set_meta("current_animation", "")  # Reset animation state
		update_animation(character, (end_position - start_position).normalized() if to_end else (start_position - end_position).normalized())

func _physics_process(delta):
	if game_loop_active:
		for character in characters:
			if character.visible:
				var to_end = character.get_meta("to_end")
				var target_position = end_position if to_end else start_position
				if character.position.distance_to(target_position) > 1:
					var direction = (target_position - character.position).normalized()
					character.position += direction * speed * delta
					update_animation(character, direction)
				else:
					character.visible = false
					character.position = target_position
					var timer = Timer.new()
					timer.wait_time = pause_duration
					timer.one_shot = true
					timer.connect("timeout", Callable(self, "_start_character_movement").bind(character, not to_end))
					add_child(timer)
					timer.start()
				
func update_animation(character, direction):
	var anisprite = character.get_node("AnimatedSprite2D")
	var new_animation = ""
	if direction.x > 0:
		new_animation = "move_right"
	elif direction.x < 0:
		new_animation = "move_left"
	else:
		anisprite.stop()
		return

	if new_animation != character.get_meta("current_animation"):
		character.set_meta("current_animation", new_animation)
		anisprite.play(new_animation)

func stop_game_loop():
	game_loop_active = false
	set_physics_process(false)
	for character in characters:
		character.visible = false
		character.get_node("AnimatedSprite2D").stop()
		character.set_meta("to_end", true)

	for timer in get_tree().get_nodes_in_group("timers"):
		timer.queue_free()

	for character in characters:
		character.position = start_position
		character.set_meta("to_end", true)
		character.get_node("AnimatedSprite2D").stop()
		character.visible = false

func restart_game_loop():
	stop_game_loop()
	
	gameboard.visible = false
	pacman2.visible = false
	blinky2.visible = false
	pinky2.visible = false
	inky2.visible = false
	clyde2.visible = false
	loading.visible = true
	
	for character in characters:
		character.position = start_position
		character.visible = false
		character.set_meta("to_end", true)
		character.get_node("AnimatedSprite2D").stop()  # Ensure animations are stopped
		character.set_meta("current_animation", "")  # Reset animation state
	
	var delay_timer = Timer.new()
	delay_timer.wait_time = 0.2  # 0.2 second delay
	delay_timer.one_shot = true
	delay_timer.connect("timeout", Callable(self, "_restart_after_delay"))
	add_child(delay_timer)
	delay_timer.start()


func _restart_after_delay():
	game_loop_active = true
	set_physics_process(true)
	_move_characters_staggered()

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	return loading.local_to_map(global_pos)

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	return loading.to_global(loading.map_to_local(tile_pos))
