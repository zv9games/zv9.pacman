extends CharacterBody2D

signal online

func _ready():
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	startmenu.connect("start_button_pressed", Callable(self, "_on_start_button_pressed"))

func _emit_online_signal():
	emit_signal("online", self.name)
	
#BREAK

@onready var startmenu = $/root/BINARY/STARTMENU
@onready var gameboard = $/root/BINARY/ORIGINAL/MAP/GAMEBOARD
var start_tile_pos = Vector2(16, 20) 

func _on_start_button_pressed():
	position = tile_position_to_global_position(start_tile_pos)






func global_position_to_tile_position(global_pos: Vector2) -> Vector2:
	var tile_map_pos = gameboard.local_to_map(global_pos)
	return tile_map_pos

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = gameboard.map_to_local(tile_pos)
	var global_pos = gameboard.to_global(local_pos)
	return global_pos
