extends PopupPanel

@onready var hoverblock2 = $HOVERBLOCK2
@onready var tilemap_layer = $TileMapLayer  
@onready var zpu = $/root/BINARY/ZPU
@onready var startmenu = $/root/BINARY/MENUS/STARTMENU

var play_positions = [Vector2(15, 9), Vector2(16, 9), Vector2(17, 9), Vector2(18, 9)]
var exit_positions = [Vector2(16, 11), Vector2(17, 11), Vector2(18, 11), Vector2(19, 11)]
var current_selection = 0  # 0 for play, 1 for exit

func _ready():
	# Connect signals if needed
	# Initialize hoverblock2 position
	update_hoverblock2_position()
	
func start_popup():
	self.set_physics_process(true)

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_UP or event.keycode == KEY_DOWN:
				toggle_selection()
			elif event.keycode == KEY_ENTER:
				if current_selection == 0:
					play()
				elif current_selection == 1:
					exit_game()
	elif event is InputEventScreenTouch:
		if event.is_pressed():
			var touch_pos = event.position
			if is_touch_on_play(touch_pos):
				play()
			elif is_touch_on_exit(touch_pos):
				exit_game()

func toggle_selection():
	current_selection = 1 - current_selection  # Toggle between 0 and 1
	update_hoverblock2_position()

func update_hoverblock2_position():
	if current_selection == 0:
		hoverblock2.position = tile_position_to_global_position(play_positions[0])
	elif current_selection == 1:
		hoverblock2.position = tile_position_to_global_position(exit_positions[0])

func play():
	print("Play Again pressed.")
	hide()
	restart_game()

func exit_game():
	print("Exit pressed.")
	get_tree().quit()

func restart_game():
	self.hide()
	print("Restarting game.")
	# Add your game restart logic here
	zpu.loading.restart_game_loop()
	startmenu.restart()
	self.set_physics_process(false)

func is_touch_on_play(touch_pos):
	var global_play_pos = tile_position_to_global_position(play_positions[0])
	return touch_pos.x >= global_play_pos.x and touch_pos.x <= global_play_pos.x + 64 and touch_pos.y >= global_play_pos.y and touch_pos.y <= global_play_pos.y + 64

func is_touch_on_exit(touch_pos):
	var global_exit_pos = tile_position_to_global_position(exit_positions[0])
	return touch_pos.x >= global_exit_pos.x and touch_pos.x <= global_exit_pos.x + 64 and touch_pos.y >= global_exit_pos.y and touch_pos.y <= global_exit_pos.y + 64

func tile_position_to_global_position(tile_pos: Vector2) -> Vector2:
	var local_pos = tilemap_layer.map_to_local(tile_pos)
	var global_pos = tilemap_layer.to_global(local_pos)
	return global_pos
