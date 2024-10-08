extends Node2D

signal online

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	start_infinity()

func _emit_online_signal():
	emit_signal("online", self.name)
	
########################################################################

@onready var pacman = $/root/BINARY/GAME/CHARACTERS/PACMAN

func start_infinity():
	pass
