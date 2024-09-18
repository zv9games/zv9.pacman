extends Node

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING, PAUSE }

signal online
signal state_changed(new_state)

const CHASE_DURATION = 15
const SCATTER_DURATION = 18
const FRIGHTENED_DURATION = 7
const INITIAL_DURATION = 5

var scatter_timer = Timer.new()
var chase_timer = Timer.new()
var frightened_timer = Timer.new()
var initial_timer = Timer.new()

var state_timers = {}
var current_state 

@onready var binary = $/root/BINARY
@onready var pacman = $"/root/BINARY/MODES/ORIGINAL/PACMAN"
@onready var gameboard = $"/root/BINARY/MODES/ORIGINAL/ORIGINALBOARD"
@onready var soundbank = $/root/BINARY/SOUNDBANK
@onready var blinky = $/root/BINARY/MODES/ORIGINAL/BLINKY
@onready var pinky = $/root/BINARY/MODES/ORIGINAL/PINKY
@onready var inky = $/root/BINARY/MODES/ORIGINAL/INKY
@onready var clyde = $/root/BINARY/MODES/ORIGINAL/CLYDE

func _ready():
	binary.connect("all_nodes_initialized", Callable(self, "_on_all_nodes_initialized"))
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()

func _on_all_nodes_initialized():
	initialize_timers()

func _emit_online_signal():
	emit_signal("online", self.name)

func initialize_timers():
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
		return
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
			soundbank.stop_sound_timers()
			soundbank.stop_all_sounds()
			chase_timer.start()
			gameboard.play_siren()
		States.SCATTER:
			stop_all_timers()
			soundbank.stop_sound_timers()
			soundbank.stop_all_sounds()
			scatter_timer.start()
			gameboard.play_siren()
		States.FRIGHTENED:
			stop_all_timers()
			soundbank.stop_sound_timers()
			soundbank.stop_all_sounds()
			restart_frightened_timer()
		States.INITIAL:
			stop_all_timers()
			initial_timer.start()
		States.LOADING:
			stop_all_timers()
			soundbank.stop_sound_timers()
			soundbank.stop_all_sounds()
		States.PAUSE:
			stop_all_timers()
			soundbank.stop_sound_timers()
			soundbank.stop_all_sounds()
			gameboard.reset_dots()

func stop_all_timers():
	for timer in state_timers.values():
		timer.stop()

func restart_frightened_timer():
	frightened_timer.stop()
	frightened_timer.start()
	soundbank.play("FRIGHT")

func get_state():
	return current_state
