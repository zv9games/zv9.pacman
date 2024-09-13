extends Node
class_name GameState

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

signal state_changed(new_state)
signal initialized

const CHASE_DURATION = 15
const SCATTER_DURATION = 18
const FRIGHTENED_DURATION = 10
const INITIAL_DURATION = 5

var scatter_timer = Timer.new()
var chase_timer = Timer.new()
var frightened_timer = Timer.new()
var initial_timer = Timer.new()

var state_timers = {}
var current_state 

@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var tile_map = $"/root/BINARY/ORIGINAL/MAP/TILEMAP"

func _ready():
	print("ready", self)
	initialize()

func initialize():
	initialize_timers()
	emit_signal("initialized", self.name)

func initialize_timers():
	# Initialize and connect timers
	_initialize_timer(chase_timer, CHASE_DURATION, "_on_Chase_timeout", States.CHASE)
	_initialize_timer(scatter_timer, SCATTER_DURATION, "_on_Scatter_timeout", States.SCATTER)
	_initialize_timer(frightened_timer, FRIGHTENED_DURATION, "_on_Frightened_timeout", States.FRIGHTENED)
	_initialize_timer(initial_timer, INITIAL_DURATION, "_on_Initial_timeout", States.INITIAL)

func _initialize_timer(timer, duration, timeout_method, state):
	timer.wait_time = duration
	if not timer.is_connected("timeout", Callable(self, timeout_method)):
		timer.connect("timeout", Callable(self, timeout_method))
	if timer.get_parent() == null:
		add_child(timer)
	state_timers[state] = timer
	

func _on_Scatter_timeout():
	set_state(States.CHASE)

func _on_Chase_timeout():
	set_state(States.SCATTER)

func _on_Frightened_timeout():
	set_state(States.CHASE)

func _on_Initial_timeout():
	set_state(States.SCATTER)

func set_state(new_state):
	if current_state == new_state:
		return  # Prevent infinite recursion
	current_state = new_state
	emit_signal("state_changed", current_state)
	print("Game state set to:", current_state)
	for ghost_instance in get_tree().get_nodes_in_group("ghosts"):
		ghost_instance.current_state = current_state
	_handle_state_change(new_state)

func _handle_state_change(new_state):
	match new_state:
		States.CHASE:
			stop_all_timers()
			
			chase_timer.start()
		States.SCATTER:
			stop_all_timers()
			
			scatter_timer.start()
		States.FRIGHTENED:
			stop_all_timers()
			
			frightened_timer.start()
		States.INITIAL:
			stop_all_timers()
			
			initial_timer.start()
		States.PRE_GAME:
			stop_all_timers()

func stop_all_timers():
	for timer in state_timers.values():
		timer.stop()
		

func restart_frightened_timer():
	frightened_timer.stop()
	frightened_timer.start()

func get_state():
	return current_state
