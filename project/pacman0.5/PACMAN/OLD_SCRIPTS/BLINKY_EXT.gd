extends CharacterBody2D

var parent_node

@onready var tilemap = $"/root/BINARY/ORIGINAL/MAP/TILEMAP"
@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var nav_agent = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY/NavigationAgent2D" as NavigationAgent2D
@onready var animated_sprite = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY/AnimatedSprite2D"

var blinky_data: Dictionary = {
	"home_corner_loop": [Vector2(23, 8), Vector2(23, 3), Vector2(29, 3), Vector2(29, 8)],}
var scatter_index = 0
var blinky_initial_target: Vector2
var blinky_initial_positions: Array = [Vector2(19, 15), Vector2(19, 18)]
var blinky_initial_index: int = 0
var blinky_frozen: bool = true
var speed = 70
var frightened_speed = 30
var return_speed = 100
var DIRECTION_THRESHOLD = 0.1

func initialize_ext(parent):
	parent_node = parent
	for key in blinky_data.keys():
		for i in range(blinky_data[key].size()):
			blinky_data[key][i] = tile_position_to_global_position_ext(blinky_data[key][i])

func move_blinky_initial() -> void:
	var dir = (parent_node.blinky_initial_target - global_position).normalized()
	velocity = dir * parent_node.speed
	move_and_slide()
	if global_position.distance_to(parent_node.blinky_initial_target) < 1:
		parent_node.blinky_initial_index = (parent_node.blinky_initial_index + 1) % parent_node.blinky_initial_positions.size()
		parent_node.blinky_initial_target = tile_position_to_global_position_ext(parent_node.blinky_initial_positions[parent_node.blinky_initial_index])
	animated_sprite.play("idle")

func move_towards_target() -> void:
	if not parent_node.blinky_frozen:
		var next_position = nav_agent.get_next_path_position()
		if next_position != Vector2.ZERO:
			var dir = (next_position - global_position).normalized()
			velocity = dir * parent_node.speed
			move_and_slide()
			update_animation_ext(dir)
			if parent_node.current_state == GameState.States.SCATTER and global_position.distance_to(nav_agent.target_position) < 1:
				make_scatter_path_ext()

func update_animation_ext(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		if direction.x > DIRECTION_THRESHOLD:
			animated_sprite.play("right")
		elif direction.x < -DIRECTION_THRESHOLD:
			animated_sprite.play("left")
	else:
		if direction.y > DIRECTION_THRESHOLD:
			animated_sprite.play("down")
		elif direction.y < -DIRECTION_THRESHOLD:
			animated_sprite.play("up")

func make_chase_path_ext() -> void:
	var target_pos = pacman.global_position
	var tile_size = tilemap.tile_set.tile_size
	var tile_center = Vector2(tile_size.x / 2, tile_size.y / 2)
	target_pos.x = floor(target_pos.x / tile_size.x) * tile_size.x + tile_center.x
	target_pos.y = floor(target_pos.y / tile_size.y) * tile_size.y + tile_center.y
	nav_agent.target_position = target_pos

func make_scatter_path_ext() -> void:
	scatter_index = (scatter_index + 1) % blinky_data["home_corner_loop"].size()
	var target_pos = blinky_data["home_corner_loop"][scatter_index]

	var tile_size = tilemap.tile_set.tile_size
	var tile_center = Vector2(tile_size.x / 2, tile_size.y / 2)
	target_pos.x = floor(target_pos.x / tile_size.x) * tile_size.x + tile_center.x
	target_pos.y = floor(target_pos.y / tile_size.y) * tile_size.y + tile_center.y
	nav_agent.target_position = target_pos

func global_position_to_tile_position_ext(global_pos: Vector2) -> Vector2:
	var tilemap_pos = tilemap.local_to_map(global_pos)
	return tilemap_pos

func tile_position_to_global_position_ext(tile_pos: Vector2) -> Vector2:
	var local_pos = tilemap.map_to_local(tile_pos)
	var global_pos = tilemap.to_global(local_pos)
	return global_pos

func move_away_from_pacman() -> void:
	var dir = (global_position - pacman.global_position).normalized()
	velocity = dir * parent_node.frightened_speed
	move_and_slide()
	animated_sprite.play("frightened")

func on_area_2d_body_entered_ext(body):
	if body.name == "PACMAN" and parent_node.current_state == parent_node.States.FRIGHTENED:
		parent_node.ghost_state = parent_node.FrightStates.CAUGHT
		parent_node.score_machine.add_points(2000)
		parent_node.last_state = parent_node.current_state
		nav_agent.target_position = tile_position_to_global_position_ext(Vector2(16, 16))
		move_to_shed_ext()
		parent_node.is_eaten = true

func move_to_shed_ext() -> void:
	var next_position = nav_agent.get_next_path_position()
	if next_position != Vector2.ZERO:
		var dir = (next_position - global_position).normalized()
		velocity = dir * parent_node.return_speed
		move_and_slide()
		if dir.x > 0:
			animated_sprite.play("eaten_right")
		else:
			animated_sprite.play("eaten_left")
		if global_position.distance_to(nav_agent.target_position) < 1:
			parent_node.reset_to_normal_state()
