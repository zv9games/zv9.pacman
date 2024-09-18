extends Node2D

signal online

@export var powerup_duration: float = 10.0  
@export var powerup_types: Array = ["apple", "bell", "cherry", "grenade", "key", "pear", "spaceship", "strawberry"]

@onready var gamestate = $/root/BINARY/ZPU/GAMESTATE  
@onready var binary = $/root/BINARY
@onready var originalboard = $/root/BINARY/GAME/ORIGINAL/TILEMAPLAYER
@onready var scoremachine = $/root/BINARY/ZPU/SCOREMACHINE
@onready var collisionshape = $AnimatedSprite2D/Area2D/CollisionShape2D
@onready var soundbank = $/root/BINARY/ZPU/SOUNDBANK
@onready var zpu = $/root/BINARY/ZPU
@onready var powerupsstart = $/root/BINARY/ZPU/TIMERS/POWERUPSSTART

var powerup_timer: Timer

func _ready():
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

func start_powerups():
	self.visible = false
	powerup_timer = Timer.new()
	powerup_timer.wait_time = powerup_duration
	powerup_timer.one_shot = true
	add_child(powerup_timer)
	powerup_timer.connect("timeout", Callable(self, "_on_powerup_timeout"))
	zpu.connect("start_powerups", Callable(self, "_on_start_powerups_signal"))
	powerupsstart.connect("timeout", Callable(self, "_on_powerupsstart_timeout"))

func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	return originalboard.local_to_map(global_pos)

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	return originalboard.to_global(originalboard.map_to_local(tile_pos))

func spawn_powerup(position: Vector2, powerup_type: String):
	var powerup = $AnimatedSprite2D  
	powerup.position = position
	powerup.animation = powerup_type
	powerup.show()  
	powerup.play()

func trigger_powerup():
	set_physics_process(true)
	var random_powerup = powerup_types[randi() % powerup_types.size()]
	var tile_position = Vector2(16, 20)  
	var spawn_position = tile_position_to_global_position(tile_position)
	spawn_powerup(spawn_position, random_powerup)
	$AnimatedSprite2D.visible = true
	powerup_timer.start()

func _on_area_2d_area_entered(area):
	soundbank.play("EAT_FRUIT")
	scoremachine.add_points(1000)
	$AnimatedSprite2D.visible = false
	call_deferred("_disable_collision_shape")

func _disable_collision_shape():
	collisionshape.disabled = true

func _enable_collision_shape():
	collisionshape.disabled = false

func remove_powerups():
	self.visible = false
	call_deferred("_disable_collision_shape")
	set_physics_process(false)
	powerup_timer.stop()
	powerupsstart.stop()  
	for child in get_children():
		if child is AnimatedSprite2D:
			child.stop() 
			child.set_physics_process(false)

func _on_start_powerups_signal():
	print("powerups signal")
	powerupsstart.start()

func _on_powerupsstart_timeout():
	print("powerupsstart timeout")
	powerup_timer.start()
	self.visible = true
	call_deferred("_enable_collision_shape")
	trigger_powerup()

func _on_powerup_timeout():
	print("powerup_timer timeout")
	call_deferred("_disable_collision_shape")
	for child in get_children():
		if child is AnimatedSprite2D:
			child.hide()
	_on_start_powerups_signal()
