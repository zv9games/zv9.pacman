extends Node

signal online
signal state_changed

func _ready():
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()
	initialize_timers()

func _emit_online_signal():
	emit_signal("online", self.name)

#BREAK
enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING }

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
var state_names = {
	States.CHASE: "CHASE",
	States.SCATTER: "SCATTER",
	States.FRIGHTENED: "FRIGHTENED",
	States.INITIAL: "INITIAL",
	States.LOADING: "LOADING"
}

@onready var pacman = $"/root/BINARY/ORIGINAL/CHARACTERS/PACMAN"
@onready var gameboard = $"/root/BINARY/ORIGINAL/MAP/GAMEBOARD"
@onready var soundbank = $/root/BINARY/SOUNDBANK
@onready var frighttimer = $/root/BINARY/SOUNDBANK/FRIGHTTIMER
@onready var sirentimer = $/root/BINARY/SOUNDBANK/SIRENTIMER

	
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
	print("Game state set to:", state_names[current_state])
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

func stop_all_timers():
	for timer in state_timers.values():
		timer.stop()

func restart_frightened_timer():
	frightened_timer.stop()
	frightened_timer.start()

func get_state():
	return current_state
