extends Node2D

signal online

@export var powerup_duration: float = 10.0  # Duration of powerup effect in seconds
@export var powerup_types: Array = ["apple", "bell", "cherry", "grenade", "key", "pear", "spaceship", "strawberry"]
@onready var gamestate = $/root/BINARY/GAMESTATE  
@onready var binary = $/root/BINARY
@onready var originalboard = $/root/BINARY/MODES/ORIGINAL/ORIGINALBOARD
@onready var scoremachine = $/root/BINARY/SCOREMACHINE
@onready var collisionshape = $AnimatedSprite2D/Area2D/CollisionShape2D
@onready var soundbank = $/root/BINARY/SOUNDBANK

var powerup_timer: Timer

func _ready():
	self.visible = false
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	binary.connect("all_nodes_initialized", Callable(self, "_on_all_nodes_initialized"))

func _emit_online_signal():
	emit_signal("online", self.name)
	
func _on_all_nodes_initialized():
	start_powerups()

# Called when the node enters the scene tree for the first time
func start_powerups():
	powerup_timer = Timer.new()
	powerup_timer.wait_time = powerup_duration
	powerup_timer.one_shot = true
	add_child(powerup_timer)
	powerup_timer.connect("timeout", Callable(self, "_on_powerup_timeout"))

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tile_map_pos = originalboard.local_to_map(global_pos)
	return tile_map_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = originalboard.map_to_local(tile_pos)
	var global_pos = originalboard.to_global(local_pos)
	return global_pos

# Function to spawn a powerup
func spawn_powerup(position: Vector2, powerup_type: String):
	var powerup = $AnimatedSprite2D  # Reference the existing AnimatedSprite2D node
	powerup.position = position
	powerup.animation = powerup_type
	powerup.show()  # Ensure the powerup is visible
	powerup.play()
	powerup_timer.start()

# Function called when the powerup timer times out
func _on_powerup_timeout():
	# Logic to handle the end of the powerup effect
	print("Powerup effect ended")
	# Hide the powerup node or reset its state
	for child in get_children():
		if child is AnimatedSprite2D:
			child.hide()

# Function to trigger a powerup (you can call this from your game logic)
func trigger_powerup():
	var random_powerup = powerup_types[randi() % powerup_types.size()]
	var tile_position = Vector2(16, 20)  # Tile position (16, 20)
	var spawn_position = tile_position_to_global_position(tile_position)
	spawn_powerup(spawn_position, random_powerup)
	powerup_timer.start()  # Start the powerup timer
	$AnimatedSprite2D.visible = true
	collisionshape.disabled = false

func _on_area_2d_area_entered(area):
	scoremachine.add_points(1000)
	$AnimatedSprite2D.visible = false
	call_deferred("_disable_collision_shape")
	soundbank.play("EAT_FRUIT")
	
func _disable_collision_shape():
	collisionshape.disabled = true
