extends Node

signal online
signal start_button_pressed

func _ready():
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()

	# Connect to the all_nodes_initialized signal from the main script
	var main_script = get_node("/root/BINARY")
	if main_script:
		main_script.connect("all_nodes_initialized", Callable(self, "_on_all_nodes_initialized"))
	startmenu.connect("start_button_pressed", Callable(self, "_on_start_button_pressed"))

	
	
func _emit_online_signal():
	emit_signal("online", self.name)
	
#BREAK

func _on_all_nodes_initialized():
	print("All nodes have been initialized. ZPU is ready to proceed.")
	start_loading_loop()

var left_point = Vector2(6, 13)
var right_point = Vector2(26, 13)

@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var blinky = $"/root/BINARY/ORIGINAL/CHARACTERS/BLINKY"
@onready var pinky = $"/root/BINARY/ORIGINAL/CHARACTERS/PINKY"
@onready var inky = $"/root/BINARY/ORIGINAL/CHARACTERS/INKY"
@onready var clyde = $"/root/BINARY/ORIGINAL/CHARACTERS/CLYDE"
@onready var loading = $"/root/BINARY/LOADING"
@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var startmenu = $"/root/BINARY/STARTMENU"

func start_loading_loop():
	hide_main_game()
	loading.start_loading_screen()
		
func hide_main_game():
	gameboard.visible = false
	
func _on_start_button_pressed():
	startmenu.visible = false
	loading.stop_loading_screen()
	gameboard.visible = true
	print("start it")
