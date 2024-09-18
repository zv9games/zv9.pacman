extends CharacterBody2D

signal online

func _ready():

	# Create a timer with a 0.5-second delay
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()

func _emit_online_signal():
	emit_signal("online", self.name)
	
#BREAK

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

var current_state 

@onready var zpu = $"/root/BINARY/ZPU"
@onready var gamestate = $"/root/BINARY/GAMESTATE"

func _on_state_changed(new_state):
	current_state = new_state
	print("State changed to: ", current_state)
	_handle_state_change(new_state)

func _handle_state_change(new_state):
	match new_state:
		States.CHASE:
			_start_chase_behavior()
		States.SCATTER:
			_start_scatter_behavior()
		States.FRIGHTENED:
			_start_frightened_behavior()
		States.INITIAL:
			_start_initial_behavior()
		States.PRE_GAME:
			_start_pre_game_behavior()

func _physics_process(delta):
	match current_state:
		States.CHASE:
			_update_chase_behavior(delta)
		States.SCATTER:
			_update_scatter_behavior(delta)
		States.FRIGHTENED:
			_update_frightened_behavior(delta)
		States.INITIAL:
			_update_initial_behavior(delta)
		States.PRE_GAME:
			_update_pre_game_behavior(delta)

func _start_chase_behavior():
	# Implement chase behavior logic here
	print("Chase behavior started")

func _start_scatter_behavior():
	# Implement scatter behavior logic here
	print("Scatter behavior started")

func _start_frightened_behavior():
	# Implement frightened behavior logic here
	print("Frightened behavior started")

func _start_initial_behavior():
	# Implement initial behavior logic here
	print("Initial behavior started")

func _start_pre_game_behavior():
	# Implement pre-game behavior logic here
	print("Pre-game behavior started")

func _update_chase_behavior(delta):
	# Update chase behavior logic here
	pass

func _update_scatter_behavior(delta):
	# Update scatter behavior logic here
	pass

func _update_frightened_behavior(delta):
	# Update frightened behavior logic here
	pass

func _update_initial_behavior(delta):
	# Update initial behavior logic here
	pass

func _update_pre_game_behavior(delta):
	# Update pre-game behavior logic here
	pass
